//===- AArch64Sandbox.cpp - AArch64 Sandbox Setup ---------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "llvm/ADT/Statistic.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Analysis/ScalarEvolution.h"
#include "llvm/Analysis/ScalarEvolutionExpander.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/Pass.h"
#include "llvm/Transforms/Utils/Local.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/InitializePasses.h"

#include "llvm/IR/Dominators.h"

#include "AArch64TargetMachine.h"
#include "MCTargetDesc/AArch64TargetStreamer.h"

#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

#define DEBUG_TYPE "aarch64-sandbox"

STATISTIC(LowBounds, "Number of bounds lower or equal to threshold");
STATISTIC(HighBounds, "Number of bounds higher to threshold");
STATISTIC(VariableBounds, "Number of non-constant bounds");

static cl::opt<unsigned> LowBinThreshold(
    "set-bounds-stat-threshold", cl::Hidden,
    cl::desc("Threshold for considering a bound value in the low bin (default = 512)"),
    cl::init(512));

static cl::opt<bool> OptStackAccess(
    "opt-safe-stack-ldst", cl::Hidden,
    cl::desc("Attempt to use CSP for known safe (in bounds) stack accesses"),
    cl::init(true));

namespace
{
// FIXME: copied from Sink.cpp. We do this because we don't want to get
// merge conflicts so we can't refactor.

/// AllUsesDominatedByBlock - Return true if all uses of the specified value
/// occur in blocks dominated by the specified block.
static bool AllUsesDominatedByBlock(SmallVectorImpl<Instruction *> &Uses,
                                    BasicBlock *BB,
                                    DominatorTree &DT,
                                    Instruction *ToSink) {
  // Ignoring debug uses is necessary so debug info doesn't affect the code.
  // This may leave a referencing dbg_value in the original block, before
  // the definition of the vreg.  Dwarf generator handles this although the
  // user might not get the right info at runtime.
  for (Instruction *UseInst : Uses) {
    BasicBlock *UseBlock = UseInst->getParent();
    if (PHINode *PN = dyn_cast<PHINode>(UseInst)) {
      // PHI nodes use the operand in the predecessor block, not the block with
      // the PHI.
      for (unsigned i = 0; i < PN->getNumIncomingValues(); ++i) {
        if (PN->getIncomingValue(i) != ToSink)
          continue;
        auto *IBB = PN->getIncomingBlock(i);
        if (!DT.dominates(BB, IBB))
          return false;
      }
      continue;
    }
    // Check that it dominates.
    if (!DT.dominates(BB, UseBlock))
      return false;
  }
  return true;
}

// FIXME: copied from Sink.cpp. We do this because we don't want to get
// merge conflicts so we can't refactor.

/// IsAcceptableTarget - Return true if it is possible to sink the instruction
/// in the specified basic block.
static bool IsAcceptableTarget(SmallVectorImpl<Instruction *> &Uses,
                               BasicBlock *Entry, BasicBlock *SuccToSinkTo,
                               DominatorTree &DT, LoopInfo &LI,
                               Instruction *ToSink) {
  assert(SuccToSinkTo && "Candidate sink target is null");

  // It is not possible to sink an instruction into its own block.  This can
  // happen with loops.
  if (Entry == SuccToSinkTo)
    return false;

  // It's never legal to sink an instruction into a block which terminates in an
  // EH-pad.
  if (SuccToSinkTo->getTerminator()->isExceptionalTerminator())
    return false;

  // Don't sink instructions into a loop.
  Loop *succ = LI.getLoopFor(SuccToSinkTo);
  if (succ != nullptr)
    return false;

  // Finally, check that all the uses of the instruction are actually
  // dominated by the candidate
  return AllUsesDominatedByBlock(Uses, SuccToSinkTo, DT, ToSink);
}

class AArch64Sandbox : public FunctionPass, public InstVisitor<AArch64Sandbox> {
  SmallVector<AllocaInst *, 16> Allocas;

  virtual llvm::StringRef getPassName() const override {
    return "AArch64 sandbox setup";
  }


public:
  static char ID;
  bool Optimize;
  bool UseCSP;
  AArch64Sandbox(bool Optimize = true, bool UseCSPForSafeOps = true) :
      FunctionPass(ID), Optimize(Optimize),
      UseCSP(UseCSPForSafeOps && OptStackAccess) {}

  void visitAllocaInst(AllocaInst &AI) { Allocas.push_back(&AI); }

  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.setPreservesCFG();
    AU.addRequired<DominatorTreeWrapperPass>();
    AU.addRequired<LoopInfoWrapperPass>();
    AU.addRequired<ScalarEvolutionWrapperPass>();
    AU.addPreserved<ScalarEvolutionWrapperPass>();
  }

  // FIXME: insert the scbndse instruction an friends into the header
  //        replace the safe loads
  //        sink the scbndse and stuff that it depends on
  BasicBlock::iterator getAllocaUsers(Instruction *AI,
                                      SmallVectorImpl<Instruction *> &Users) {
    // Replace all uses of the alloca with a set bounds instruction
    // on the alloca except the paths leading to the debug and
    // lifetime markers. This allows us to sink the set bounds
    // instruction and reduce live ranges.

    // Look for the
    //       lifetime.start/end(bitcast(a)) -> duplicate bitcast
    //       lifetime.start/end(a)
    //       debug_intrinsic(bitcast(a))
    //       debug_intrinsic(a)

    SmallSet<Instruction *, 4> Ignore;
    SmallSet<Instruction *, 4> Duplicate;

    for (auto UI = AI->use_begin(); UI != AI->use_end(); ++UI) {
      Instruction *AUse = dyn_cast<Instruction>(&*UI->getUser());
      if (!AUse)
        continue;
      BitCastInst *BC = dyn_cast<BitCastInst>(AUse);
      if (isAssumeLikeIntrinsic(AUse)) {
        Ignore.insert(AUse);
        continue;
      }

      if (!BC) {
        Users.push_back(AUse);
        continue;
      }

      // Check if all at least one user is an assume like intrinisc
      // and if all uses are assume like intrinsics.
      // In case all users are, we ignore AUse. If only some of them
      // are assume like intrinsics we need to duplicate the bitcast.
      bool Total = true;
      bool Partial = false;
      for (auto *BUse : BC->users()) {
        if (!isAssumeLikeIntrinsic(cast<Instruction>(BUse)))
          Total = false;
        else
          Partial = true;
      }
      if (Total) {
        Ignore.insert(AUse);
        continue;
      }
      if (Partial) {
        Duplicate.insert(AUse);
        continue;
      }
      Users.push_back(AUse);
    }

    for (auto *Inst : Duplicate) {
      auto *New = Inst->clone();
      New->insertAfter(Inst);
      SmallVector<Instruction *, 4> DupUsers;
      for (auto UI = Inst->use_begin(); UI != Inst->use_end(); ++UI) {
        Instruction *Use = dyn_cast<Instruction>(&*UI->getUser());
        if (!Use)
          continue;
        if (isAssumeLikeIntrinsic(Use))
          continue;
        DupUsers.push_back(Use);
      }
      for (auto Use : DupUsers) {
        Use->replaceUsesOfWith(Inst, New);
      }
      Users.push_back(New);
    }

    return BasicBlock::iterator(AI->getNextNode());
  }

  struct SafeInfo {
    AllocaInst *Base;
    uint64_t Offset;
    Instruction *Use;
    SafeInfo(AllocaInst *Base, uint64_t Offset, Instruction *Use) :
        Base(Base), Offset(Offset), Use(Use) {}
  };

  typedef std::map<AllocaInst *, SmallVector<SafeInfo, 4>> AllocaInfoMap;

  void gatherConstantOffsetAccesses(Function &F, const DataLayout &DL,
                                    AllocaInfoMap &AllocaInfo) {
    // Gather accesses with an alloca base and constant offset.
    // If they are 'safe' add them to the map.
    LLVMContext &C = F.getParent()->getContext();
    for (auto I = F.begin(), E = F.end(); I != E; ++I)
      for (Instruction &Inst : *I) {
        Instruction *Addr = nullptr;
        uint64_t Size;
        if (auto *LI = dyn_cast<LoadInst>(&Inst)) {
          Addr = dyn_cast<Instruction>(LI->getPointerOperand());
          Size = DL.getTypeStoreSize(LI->getType());
        }
        if (auto *SI = dyn_cast<StoreInst>(&Inst)) {
          Addr = dyn_cast<Instruction>(SI->getPointerOperand());
          Size = DL.getTypeStoreSize(SI->getValueOperand()->getType());
        }
        if (!Addr)
          continue;
        int64_t Offset;
        auto *Base = GetPointerBaseWithConstantOffset(Addr, Offset, DL);
        auto *AllocaBase = dyn_cast_or_null<AllocaInst>(Base);
        if (!AllocaBase)
          continue;

        // If we've got a negative offset there's no point in checking the
        // array size.
        if (Offset < 0)
          continue;

        if (!AllocaBase->isStaticAlloca())
          continue;

        // Get the alloca size
        Value *ASz = AllocaBase->isArrayAllocation() ? AllocaBase->getArraySize() :
            ASz = ConstantInt::get(Type::getInt64Ty(C), 1);
        ConstantInt *CI = dyn_cast<ConstantInt>(AllocaBase->getArraySize());
        if (!CI)
          continue;
        PointerType *AllocaTy = AllocaBase->getType();
        Type *AllocationTy = AllocaTy->getElementType();
        uint64_t ElementSize = DL.getTypeAllocSize(AllocationTy);
        uint64_t TotalSize = CI->getLimitedValue() * ElementSize;

        // Check if the memory operation is safe.
        if (Offset + Size > TotalSize)
          continue;
        
        if (AllocaInfo.find(AllocaBase) == AllocaInfo.end())
          AllocaInfo[AllocaBase] = SmallVector<SafeInfo, 4>();
        AllocaInfo[AllocaBase].push_back(SafeInfo(AllocaBase, Offset, &Inst));
      }
  }

  void fixupSafeAccesses(AllocaInfoMap &AllocaInfo, AllocaInst *Alloca,
                         const DataLayout &DL, ScalarEvolution &SE,
                         SmallSetVector<Instruction *, 16> &OldAddrs) {
    if (AllocaInfo.find(Alloca) == AllocaInfo.end())
      return;
    SCEVExpander Rewriter(SE, DL, "sandbox");
    Rewriter.disableCanonicalMode();
    LLVMContext &C = Alloca->getParent()->getContext();
    Type *Int64T = Type::getInt64Ty(C);
    for (auto &Info : AllocaInfo[Alloca]) {
      Type *Ty = nullptr;
      if (auto *LI = dyn_cast<LoadInst>(Info.Use))
        Ty = LI->getPointerOperand()->getType();
      if (auto *SI = dyn_cast<StoreInst>(Info.Use))
        Ty = SI->getPointerOperand()->getType();

      // Use the SCEV expander to recreate the address.
      if (Info.Use->getParent() != Alloca->getParent())
        Rewriter.setInsertPoint(&*Info.Use->getParent()->getFirstInsertionPt());
      else
        Rewriter.setInsertPoint(Alloca->getNextNode());
      auto *Expr = SE.getAddExpr(SE.getUnknown(Alloca),
                                 SE.getConstant(Int64T, Info.Offset));
      auto *Val = Rewriter.expandCodeFor(Expr, Ty);
      // Replace the address operand of the instruction and get the old operand.
      Instruction *OldAddr;
      if (auto *LI = dyn_cast<LoadInst>(Info.Use)) {
        OldAddr = cast<Instruction>(LI->getOperand(0));
        LI->setOperand(0, Val);
      }
      if (auto *SI = dyn_cast<StoreInst>(Info.Use)) {
        OldAddr = cast<Instruction>(SI->getOperand(1));
        SI->setOperand(1, Val);
      }

      OldAddrs.insert(OldAddr);
    }
  }

  void sinkSetLen(Instruction *SetLen, DominatorTree &DT, LoopInfo &LI) {
    // We might have a bitcast on the set lenght instruction.
    // Look throuh it to get the actual intrinsic call.
    Instruction *TheSetLen = SetLen;
    if (BitCastInst *Cast = dyn_cast<BitCastInst>(SetLen))
      TheSetLen = cast<Instruction>(Cast->getOperand(0));

    // If the second operand is not a constant don't sink this.
    // The first operand is a an alloca or bitcast so we can
    // ignore it.
    if (!isa<Constant>(TheSetLen->getOperand(1)))
      return;

    SmallVector<Instruction *, 16> Users;
    for (auto UI = SetLen->use_begin(); UI != SetLen->use_end(); ++UI) {
      Instruction *Use = dyn_cast<Instruction>(&*UI->getUser());
      if (!Use)
        continue;
      Users.push_back(Use);
    }

    // Find the block to sink to. Don't sink into the block since that
    // might increase other live ranges.
    BasicBlock *SuccToSinkTo = nullptr;

    // Instructions can only be sunk if all their uses are in blocks
    // dominated by one of the successors.
    // Look at all the dominated blocks and see if we can sink it in one.
    DomTreeNode *DTN = DT.getNode(SetLen->getParent());
    for (DomTreeNode::iterator I = DTN->begin(), E = DTN->end();
        I != E && SuccToSinkTo == nullptr; ++I) {
      BasicBlock *Candidate = (*I)->getBlock();
      // A node always immediate-dominates its children on the dominator
      // tree.
      if (IsAcceptableTarget(Users, SetLen->getParent(), Candidate, DT, LI, SetLen))
        SuccToSinkTo = Candidate;
    }

    if (!SuccToSinkTo)
      return;
    if (SuccToSinkTo == SetLen->getParent())
      return;

    // Now sink the instruction.
    SetLen->moveBefore(&*SuccToSinkTo->getFirstInsertionPt());
    if (TheSetLen != SetLen)
      TheSetLen->moveBefore(&*SuccToSinkTo->getFirstInsertionPt());
  }

  bool isSmallStackFunction(const DataLayout &DL) {
    uint64_t Size = 0;

    for (AllocaInst *AI : Allocas) {
      if (!AI->isStaticAlloca())
        continue;
      LLVMContext &C = AI->getParent()->getContext();

      Value *ASz = AI->isArrayAllocation() ? AI->getArraySize() :
          ASz = ConstantInt::get(Type::getInt64Ty(C), 1);
      ConstantInt *CI = cast<ConstantInt>(AI->getArraySize());
      if (!CI)
        continue;
      PointerType *AllocaTy = AI->getType();
      Type *AllocationTy = AllocaTy->getElementType();
      uint64_t ElementSize = DL.getTypeAllocSize(AllocationTy);
      uint64_t TotalSize = CI->getLimitedValue() * ElementSize;
      Size +=TotalSize;
    }
    return Size < 4096;;
  }

  bool runOnFunction(Function &F) override {
    Module *M = F.getParent();
    const DataLayout &DL = M->getDataLayout();

    auto *DT = &getAnalysis<DominatorTreeWrapperPass>().getDomTree();
    auto &LI = getAnalysis<LoopInfoWrapperPass>().getLoopInfo();
    auto &SE = getAnalysis<ScalarEvolutionWrapperPass>().getSE();

    Allocas.clear();

    if (DL.getAllocaAddrSpace() != 200)
      return false;

    visit(F);

    bool ShouldUseCSP = UseCSP && isSmallStackFunction(DL);

    // If no Allocas, then nothing to do.
    if (Allocas.empty())
      return false;

    LLVMContext &C = M->getContext();

    Intrinsic::ID SetLengthExact = Intrinsic::cheri_cap_bounds_set_exact;
    Intrinsic::ID SetLengthInexact = Intrinsic::cheri_cap_bounds_set;
    Type *SizeTy = Type::getIntNTy(M->getContext(),
                                   DL.getIndexSizeInBits(200));
    Function *SetLenExFun = Intrinsic::getDeclaration(M, SetLengthExact, SizeTy);
    Function *SetLenInexFun = Intrinsic::getDeclaration(M, SetLengthInexact, SizeTy);

    IRBuilder<> B(C);
    AllocaInfoMap AllocaInfo;
    gatherConstantOffsetAccesses(F, DL, AllocaInfo);

    for (AllocaInst *AI : Allocas) {
      BasicBlock::iterator IP(AI);

      assert(AI->getType()->getPointerAddressSpace() == 200);
      B.SetInsertPoint(AI->getParent(), IP);
      PointerType *AllocaTy = AI->getType();
      Type *AllocationTy = AllocaTy->getElementType();
      AllocaInst *Alloca = nullptr;
      Instruction *CastAlloca;
      Function *SetLenFun;
      uint64_t ElementSize = DL.getTypeAllocSize(AllocationTy);
      Value *ASz = AI->isArrayAllocation() ? AI->getArraySize() :
          ASz = ConstantInt::get(Type::getInt64Ty(C), 1);

      if (ConstantInt *CI = dyn_cast<ConstantInt>(AI->getArraySize())) {
        uint64_t TotalSize = CI->getLimitedValue() * ElementSize;
        auto Req = AArch64TargetStreamer::getTargetSizeAlignReq(TotalSize);
        Align Alignment = Req.second ? Align(1UL << Req.second) : Align();
        TotalSize = Req.first;

        // Determine the required aligment.
        Alignment = max(Alignment, MaybeAlign(AI->getAlignment()));
        // Try to keep the element type if we don't need any padding.
        if (TotalSize != 0 && TotalSize % ElementSize == 0) {
          uint64_t NewElements = TotalSize / ElementSize;
          ASz = ConstantInt::get(Type::getInt64Ty(C), NewElements);
          Alloca = B.CreateAlloca(AllocationTy, ASz);
          Alloca->setAlignment(Alignment);
        } else {
          ElementSize = 1;
          ASz = ConstantInt::get(Type::getInt64Ty(C), TotalSize);
          Alloca = B.CreateAlloca(Type::getInt8Ty(C), ASz);
          Alloca->setAlignment(Alignment);
        }

        if (AllocaInfo.find(AI) != AllocaInfo.end()) {
          AllocaInfo[Alloca] = AllocaInfo[AI];
          AllocaInfo.erase(AI);
        }

        Value *NAlloca =
            B.CreateBitCast(Alloca,
                            AI->getType());
        AI->replaceAllUsesWith(NAlloca);
        AI->eraseFromParent();
        CastAlloca = cast<Instruction>(NAlloca);
        SetLenFun = SetLenExFun;
      } else {
        VariableBounds++;
        Alloca = AI;
        CastAlloca = AI;
        // ExpandDYNAMIC_ALLOCA will pad to stack alignment (16), round that to
        // a representable length and set bounds on the whole allocation,
        // meaning it doesn't suitably bound small allocations. Thus we need to
        // set the bounds here (and we use an inexact set bounds since that
        // automatically rounds to a representable length and we don't need to
        // use the actual length).
        SetLenFun = SetLenInexFun;
      }

      SmallVector<Instruction *, 4> Users;
      auto IT = getAllocaUsers(CastAlloca, Users);
      B.SetInsertPoint(IT->getParent(), IT);

      assert(Alloca->getType()->getPointerAddressSpace() == 200);
      Value *Size = ConstantInt::get(Type::getInt64Ty(C), ElementSize);
      Size = B.CreateMul(Size, ASz);

      if (Alloca->isStaticAlloca()) {
        auto *Const = cast<ConstantInt>(Size);
        if (Const->getLimitedValue() <= LowBinThreshold)
          LowBounds++;
        else
          HighBounds++;
      }

      Value *NAlloca = B.CreateBitCast(CastAlloca,
                               SetLenFun->getFunctionType()->getParamType(0));
      Value *SetLenInst = B.CreateCall(SetLenFun, {NAlloca, Size});
      SetLenInst = B.CreateBitCast(SetLenInst, AllocaTy);
      for (Instruction *Inst : Users)
        Inst->replaceUsesOfWith(CastAlloca, SetLenInst);

      // The set lenght instruction might be removed by the dead code
      // elimination so track it.
      WeakTrackingVH Handle(SetLenInst);

      // Try to use CSP for safe stack accesses only if we think that we will
      // manage to fold the address computation into the load/store addressing
      // mode. Otherwise we might end up increasing register pressure. Note that
      // the IR level is not the ideal place to deal with these issues.
      if (ShouldUseCSP && Optimize) {
        SmallSetVector<Instruction *, 16> OldAddrs;

        // Transform safe accesses to use the original alloca instruction.
        // This mean that we will be using CSP instead of the result from
        // the set bounds instruction, which should reduce register pressure.
        fixupSafeAccesses(AllocaInfo, Alloca, DL, SE, OldAddrs);

        // Remove dead code in order to reduce the number of users of the
        // set bounds instruction. This should allow more options for sinking.
        SmallVector<WeakTrackingVH, 16> DeadInsts;
        for (auto *V : OldAddrs)
          if (V->use_empty() && isInstructionTriviallyDead(V))
            DeadInsts.push_back(V);
        RecursivelyDeleteTriviallyDeadInstructions(DeadInsts);
      }

      // Sink the set length instruction if it wasn't removed during DCE.
      if (Handle && Optimize)
        sinkSetLen(cast<Instruction>(Handle), *DT, LI);
    }

    return true;
  }
};

} // anonymous namespace

char AArch64Sandbox::ID;
INITIALIZE_PASS_BEGIN(AArch64Sandbox, "aarch64-sandbox",
                      "AArch64 sandbox setup", false, false)
INITIALIZE_PASS_DEPENDENCY(DominatorTreeWrapperPass)
INITIALIZE_PASS_DEPENDENCY(LoopInfoWrapperPass)
INITIALIZE_PASS_DEPENDENCY(ScalarEvolutionWrapperPass)
INITIALIZE_PASS_END(AArch64Sandbox, "aarch64-sandbox",
                    "AArch64 sandbox setup", false, false)

namespace llvm {
FunctionPass *createAArch64Sandbox(bool Optimize, bool UseCSPForSafeOps) {
  return new AArch64Sandbox(Optimize, UseCSPForSafeOps);
}
}
