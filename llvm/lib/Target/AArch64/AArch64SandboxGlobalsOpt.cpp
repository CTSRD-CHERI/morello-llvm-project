//===- AArch64SandboxGlobalsOpt.cpp - AArch64 Sandbox Globals Optimization ===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "llvm/Pass.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/IR/InstVisitor.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/ADT/APSInt.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include "AArch64TargetMachine.h"

using namespace llvm;
using namespace PatternMatch;

#define DEBUG_TYPE "aarch64-sandbox-globals-opt"

static cl::opt<bool>
OptShareGlobalCaps("aarch64-sandbox-share-global-capabilities",
         cl::desc("Allow sharing capabilities to globals between functions"),
         cl::init(true));

namespace {

class AArch64SandboxGlobalsOpt : public ModulePass {
  llvm::StringRef getPassName() const override {
    return "AArch64 sandbox globals optimization";
  }

public:
  static char ID;
  TargetMachine *TM;
  AArch64SandboxGlobalsOpt(TargetMachine *TM) : ModulePass(ID), TM(TM) {}

  struct GlobalKey {
    Comdat *ObjComdat;
    GlobalValue::LinkageTypes Linkage;
    GlobalValue::VisibilityTypes Visibility;
    std::string Suffix;
  };

  struct GlobalKeyCompare {
    bool operator()(const GlobalKey &LHS, const GlobalKey RHS) const {
      if (LHS.Linkage != RHS.Linkage)
        return LHS.Linkage < RHS.Linkage;
      if (LHS.Visibility != RHS.Visibility)
        return LHS.Visibility < RHS.Visibility;
      if (!LHS.ObjComdat || !RHS.ObjComdat)
        return (LHS.ObjComdat < RHS.ObjComdat);
      if (LHS.ObjComdat->getSelectionKind() != RHS.ObjComdat->getSelectionKind())
        return LHS.ObjComdat->getSelectionKind() < RHS.ObjComdat->getSelectionKind();
      if (LHS.Suffix != RHS.Suffix)
	return LHS.Suffix < RHS.Suffix;
      return LHS.ObjComdat->getName().compare(RHS.ObjComdat->getName()) < 0;
    }
  };

  std::map<GlobalKey, std::vector<GlobalValue*>, GlobalKeyCompare> Globals;

  bool doInitialization(Module &Mod) override {
    return true;
  }

  static bool isUsedGlobalHelper(Value *V, std::set<Value *> &Cache) {
    if (isa<Instruction>(V))
      return true;
    if (!isa<ConstantExpr>(V))
      return false;
    if (Cache.find(V) != Cache.end())
      return false;
    Cache.insert(V);
    for (User *U : V->users())
      if (isUsedGlobalHelper(U, Cache))
        return true;
    return false;
  }

  static bool isUsedGlobal(GlobalValue &GV) {
    std::set<Value *> Cache;
    for (User *U : GV.users())
      if (isUsedGlobalHelper(U, Cache))
        return true;
    return false;
  }

  void addGlobalValue(GlobalValue *GV) {
    GlobalKey Key;
    Key.Linkage = getCapLinkage(GV);
    Key.ObjComdat = GV->hasComdat() ? getCapComdat(GV) : nullptr;
    Key.Visibility = getCapVisibility(GV);
    Key.Suffix = GV->hasComdat() ? GV->getName().str() : "";
    Globals[Key].push_back(GV);
  }

  static GlobalValue::LinkageTypes getCapLinkage(GlobalValue *GV) {
    if (GV->hasComdat())
      return GlobalValue::WeakODRLinkage;
    return GlobalValue::PrivateLinkage;
  }

  static GlobalValue::VisibilityTypes getCapVisibility(GlobalValue *GV) {
    if (GV->hasComdat())
      return GlobalValue::HiddenVisibility;
    return GlobalValue::DefaultVisibility;
  }

  static Comdat *getCapComdat(GlobalValue *GV) {
    Module &M = *GV->getParent();
    std::string CName = "__cap_";
    CName = CName.append(GV->getComdat()->getName().str());
    Comdat *C = M.getOrInsertComdat(CName);
    C->setSelectionKind(GV->getComdat()->getSelectionKind());
    return C;
  }

  // Create a constant global table containing the GV addresses and add
  // metadata to the original global pointing pointing to the the
  // table, with an additional index. Codegen will then load from
  // from the capability table when producing global addresses.
  bool createGlobalAddressTable(std::vector<GlobalValue *> &GVS, GlobalKey Key) {
    if (GVS.empty() || !OptShareGlobalCaps)
      return false;

    LLVMContext &C = GVS[0]->getContext();
    auto* I8Ty = IntegerType::get(C, 8);
    // FIXME: don't hard-code 200
    PointerType* VoidPtrTy = PointerType::get(I8Ty, 200);
    SmallVector<Constant *, 10> Init;
    for (unsigned ii = 0; ii < GVS.size(); ++ii)
      Init.push_back(ConstantExpr::getPointerCast(GVS[ii], VoidPtrTy));

    auto *Const =
        ConstantArray::get(ArrayType::get(VoidPtrTy, GVS.size()), Init);

    GlobalVariable *NGV = new GlobalVariable(*GVS[0]->getParent(),
        Const->getType(), true, Key.Linkage, Const,
        Twine("__cap_merged_table") + Twine(Key.Suffix),  nullptr,
        GlobalValue::NotThreadLocal, 0);
    if (Key.ObjComdat)
      NGV->setComdat(Key.ObjComdat);
    NGV->setVisibility(Key.Visibility);
    NGV->setAlignment(MaybeAlign(16));
    NamedMDNode *NMD =
        GVS[0]->getParent()->getOrInsertNamedMetadata("llvm.captable");
    SmallVector<Metadata*, 4> Elements;
    Elements.push_back(ValueAsMetadata::get(NGV));
    for (unsigned ii = 0; ii < GVS.size(); ++ii)
      Elements.push_back(ValueAsMetadata::get(GVS[ii]));
    NMD->addOperand(MDTuple::get(C, Elements));
    return true;
  }

  bool runOnGlobal(GlobalValue &GV, Module &M) {
    if (M.begin() == M.end())
      return false;
    const Function &Fun = *M.begin();
    const AArch64Subtarget *ST =
      static_cast<const AArch64Subtarget *>(TM->getSubtargetImpl(Fun));
    if ((ST->ClassifyGlobalReference(&GV, *TM) & AArch64II::MO_GOT) != 0)
      return false;
    if (GV.getThreadLocalMode() != GlobalValue::NotThreadLocal)
      return false;

    const DataLayout &DL = M.getDataLayout();
    if (!DL.isFatPointer(GV.getType()))
      return false;

    if (!GV.getValueType()->isSized())
      return false;

    if (!isUsedGlobal(GV))
      return false;
    addGlobalValue(&GV);
    return OptShareGlobalCaps;
  }

  bool runOnModule(Module &M) override {
    // Nothing to do if we are not in sandbox mode.
    const DataLayout &DL = M.getDataLayout();
    if (DL.getAllocaAddrSpace() != 200)
      return false;

    bool Modified = false;
    for (GlobalValue &GV: M.globals()) {
      if (GlobalVariable *GVar = dyn_cast<GlobalVariable>(&GV)) {
        Modified |= runOnGlobal(*GVar, M);
        continue;
      }
    }
    for (GlobalValue &GV: M.aliases()) {
      if (GlobalAlias *GVar = dyn_cast<GlobalAlias>(&GV)) {
        Modified |= runOnGlobal(*GVar, M);
        continue;
      }
    }

    for (auto &II: Globals)
      createGlobalAddressTable(II.second, II.first);

    Globals.clear();
    return Modified;
  }

};

} // anonymous namespace

char AArch64SandboxGlobalsOpt::ID;

namespace llvm {
ModulePass *createAArch64SandboxGlobalsOpt(TargetMachine *TM) {
  return new AArch64SandboxGlobalsOpt(TM);
}
}
