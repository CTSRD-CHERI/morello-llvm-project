//===- DemandedCheriMetadata.cpp - Determine demanded bits -------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This pass implements a demanded bits analysis for CHERI metadata bits.
// This is similar to the existing demanded bits analysis and could be
// integrated into it at some point. We model the entire permissions using one
// bit for simplicity.
//===----------------------------------------------------------------------===//

#include "llvm/Analysis/DemandedCheriMetadata.h"
#include "llvm/ADT/APInt.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Operator.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Use.h"
#include "llvm/InitializePasses.h"
#include "llvm/Pass.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include <algorithm>
#include <cstdint>

using namespace llvm;

#define DEBUG_TYPE "demanded-cheri-metadata"

char DemandedCheriMetadataWrapperPass::ID = 0;

INITIALIZE_PASS_BEGIN(DemandedCheriMetadataWrapperPass, "demanded-cheri-metadata",
                      "Demanded Cheri Metadata analysis", false, false)
INITIALIZE_PASS_END(DemandedCheriMetadataWrapperPass, "demanded-cheri-metadata",
                    "Demanded Cheri Metadata analysis", false, false)

DemandedCheriMetadataWrapperPass::DemandedCheriMetadataWrapperPass() : FunctionPass(ID) {
  initializeDemandedCheriMetadataWrapperPassPass(*PassRegistry::getPassRegistry());
}

void DemandedCheriMetadataWrapperPass::getAnalysisUsage(AnalysisUsage &AU) const {
  AU.setPreservesCFG();
  AU.setPreservesAll();
}

void DemandedCheriMetadataWrapperPass::print(raw_ostream &OS, const Module *M) const {
  DB->print(OS);
}

void DemandedCheriMetadata::propagateMetadataLiveness(
    const Instruction *UserI, const Value *Val, unsigned OperandNo,
    bool AOut, bool &AB) {
  if (UserI->isDebugOrPseudoInst())
    return;
  switch (UserI->getOpcode()) {
  default:
    AB = true;
    return;
  case Instruction::Call:
  case Instruction::Invoke:
    if (const IntrinsicInst *II = dyn_cast<IntrinsicInst>(UserI)) {
      switch (II->getIntrinsicID()) {
      default:
        AB = true;
        return;
      case Intrinsic::cheri_cap_address_set:
      case Intrinsic::cheri_cap_perms_and:
      case Intrinsic::cheri_cap_bounds_set:
      case Intrinsic::cheri_cap_bounds_set_exact:
        AB = AOut;
        return;
      case Intrinsic::cheri_cap_address_get:
      case Intrinsic::cheri_cap_diff:
        return;
      }
    }
    AB = true;
    return;
  case Instruction::BitCast:
  case Instruction::Freeze:
  case Instruction::GetElementPtr:
  case Instruction::PHI:
    AB = AOut;
    break;
  case Instruction::Select:
    if (OperandNo != 0)
      AB = AOut;
    break;
  case Instruction::ICmp:
  case Instruction::Switch:
    break;
  }
}

bool DemandedCheriMetadataWrapperPass::runOnFunction(Function &F) {
  DB.emplace(F);
  return false;
}

void DemandedCheriMetadataWrapperPass::releaseMemory() {
  DB.reset();
}

static bool instrUsesMetadata(Instruction &I) {
  if (I.isDebugOrPseudoInst())
    return false;
  switch (I.getOpcode()) {
  case Instruction::ICmp:
    return false;
  case Instruction::Call:
  case Instruction::Invoke:
    if (const IntrinsicInst *II = dyn_cast<IntrinsicInst>(&I)) {
      switch (II->getIntrinsicID()) {
      case Intrinsic::cheri_cap_address_get:
      case Intrinsic::cheri_cap_diff:
        return false;
      default: break;
      }
    }
    return true;
  default: return true;
  }
}

void DemandedCheriMetadata::performAnalysis() {
  if (Analyzed)
    // Analysis already completed for this function.
    return;
  Analyzed = true;

  Visited.clear();
  AliveBits.clear();

  SmallSetVector<Instruction*, 16> Worklist;

  const DataLayout &DL = F.getParent()->getDataLayout();
  // Collect the set of "root" instructions that are known live.
  for (Instruction &I : instructions(F)) {
    LLVM_DEBUG(dbgs() << "DemandedCheriMetadata: Root: " << I << "\n");
    // For capability instructions, set up an initial empty set of alive
    // metadata and add the instruction to the work list. For other instructions
    // add their operands to the work list (for capability values operands, mark
    // metadata as live if used).
    Type *T = I.getType();
    if (DL.isFatPointer(T)) {
      if (AliveBits.try_emplace(&I, false).second)
        Worklist.insert(&I);
      continue;
    }

    // Non-capability-typed instructions...
    for (Use &OI : I.operands()) {
      if (Instruction *J = dyn_cast<Instruction>(OI)) {
        Type *T = J->getType();
        if (DL.isFatPointer(T) && instrUsesMetadata(I))
          AliveBits[J] = true;
        Worklist.insert(J);
      }
    }
  }

  // Propagate liveness backwards to operands.
  while (!Worklist.empty()) {
    Instruction *UserI = Worklist.pop_back_val();

    LLVM_DEBUG(dbgs() << "DemandedCheriMetadata: Visiting: " << *UserI);
    bool AOut = false;
    if (DL.isFatPointer(UserI->getType())) {
      AOut = AliveBits[UserI];
      LLVM_DEBUG(dbgs() << " Alive Out: " << AOut << "\n");
    }
    LLVM_DEBUG(dbgs() << "\n");

    for (Use &OI : UserI->operands()) {
      Instruction *I = dyn_cast<Instruction>(OI);
      if (!I && !isa<Argument>(OI))
        continue;

      Type *T = OI->getType();
      if (DL.isFatPointer(T)) {
        bool AB = false;
        // Bits of each operand that are used to compute alive bits of the
        // output are alive, all others are dead.
        propagateMetadataLiveness(UserI, OI, OI.getOperandNo(), AOut, AB);

        if (I) {
          // If we've added to the set of alive bits (or the operand has not
          // been previously visited), then re-queue the operand to be visited
          // again.
          auto Res = AliveBits.try_emplace(I);
          if (Res.second || (AB && AB != Res.first->second)) {
            Res.first->second = AB || Res.first->second;
            Worklist.insert(I);
          }
        }
      } else if (I && Visited.insert(I).second) {
        Worklist.insert(I);
      }
    }
  }
}

bool DemandedCheriMetadata::getDemandedCheriMetadata(Instruction *I) {
  performAnalysis();

  auto Found = AliveBits.find(I);
  if (Found != AliveBits.end())
    return Found->second;

  const DataLayout &DL = I->getModule()->getDataLayout();
  return DL.isFatPointer(I->getType());
}

void DemandedCheriMetadata::print(raw_ostream &OS) {
  auto PrintDB = [&](const Instruction *I, const bool &A, Value *V = nullptr) {
    OS << "DemandedCheriMetadata: " << A << " for ";
    if (V) {
      V->printAsOperand(OS, false);
      OS << " in ";
    }
    OS << *I << '\n';
  };

  performAnalysis();
  OS << "Running on function: " << F.getName() << "\n";
  for (auto &KV : AliveBits) {
    Instruction *I = KV.first;
    PrintDB(I, KV.second);
  }
}

FunctionPass *llvm::createDemandedCheriMetadataWrapperPass() {
  return new DemandedCheriMetadataWrapperPass();
}

AnalysisKey DemandedCheriMetadataAnalysis::Key;

DemandedCheriMetadata DemandedCheriMetadataAnalysis::run(Function &F,
                                             FunctionAnalysisManager &AM) {
  return DemandedCheriMetadata(F);
}

PreservedAnalyses DemandedCheriMetadataPrinterPass::run(Function &F,
                                               FunctionAnalysisManager &AM) {
  AM.getResult<DemandedCheriMetadataAnalysis>(F).print(OS);
  return PreservedAnalyses::all();
}
