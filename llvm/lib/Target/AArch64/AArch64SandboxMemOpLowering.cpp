//===- AArch64SandboxMemOpLowering.cpp --------------------------*- C++ -*-===//
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
#include "llvm/IR/InstVisitor.h"
#include "llvm/Support/Cheri.h"

using namespace llvm;

namespace {
class AArch64SandboxMemOpLowering
    : public FunctionPass,
      public InstVisitor<AArch64SandboxMemOpLowering> {
  Module *M;
  FunctionCallee Memset_c;
  FunctionCallee Memcpy_c;
  FunctionCallee Mempcpy_c;
  FunctionCallee Memmove_c;

  Type *CapTy;
  Type *Int32Ty;
  Type *Int64Ty;
  Type *VoidTy;
  bool Modified;

  typedef enum {
    Invalid,
    MemCpy,
    MemPCpy,
    MemMove,
    MemSet
  } MemxferTy;

  virtual llvm::StringRef getPassName() const {
    return "AArch64 sandbox memory operation lowering";
  }

public:
  static char ID;
  AArch64SandboxMemOpLowering() : FunctionPass(ID) {}

  virtual bool doInitialization(Module &Mod) {
    M = &Mod;
    LLVMContext &C = M->getContext();
    CapTy = Type::getInt8PtrTy(C, 200);
    VoidTy = Type::getVoidTy(C);
    Int32Ty = Type::getInt32Ty(C);
    Int64Ty = Type::getInt64Ty(C);
    Memset_c = nullptr;
    Memcpy_c = nullptr;
    Mempcpy_c = nullptr;
    Memmove_c = nullptr;
    return true;
  }

  Constant *getAliasee(StringRef Name) {
    GlobalAlias *GA = M->getNamedAlias(Name);
    if (!GA)
      return nullptr;
    return GA->getAliasee();
  }

  void setAliasee(Constant *Const, StringRef Name) {
    if (!Const)
      return;
    M->getNamedAlias(Name)->setAliasee(Const);
  }

  void replaceMemFun(Function &F) {
    // Replace all references to the string functions with _c the ones.
    // Don't touch any aliases that define the _c functions, as that will
    // cause us to produce invalid IR and it's not what we want to do anyway.
    FunctionCallee MemCpy = M->getFunction("memcpy");
    if (MemCpy) {
      auto *Const = getAliasee("memcpy_c");
      if (!Memcpy_c)
        Memcpy_c = M->getOrInsertFunction("memcpy_c", CapTy, CapTy,
                                          CapTy, Int64Ty);
      MemCpy.getCallee()->replaceAllUsesWith(Memcpy_c.getCallee());
      setAliasee(Const, "memcpy_c");
      Modified = true;
    }
    FunctionCallee MemPCpy = M->getFunction("mempcpy");
    if (MemPCpy) {
      auto *Const = getAliasee("mempcpy_c");
      if (!Mempcpy_c)
        Mempcpy_c = M->getOrInsertFunction("mempcpy_c", CapTy, CapTy,
                                          CapTy, Int64Ty);
      MemPCpy.getCallee()->replaceAllUsesWith(Mempcpy_c.getCallee());
      setAliasee(Const, "mempcpy_c");
      Modified = true;
    }
    FunctionCallee MemSet = M->getFunction("memset");
    if (MemSet) {
      auto *Const = getAliasee("memset_c");
      if (!Memset_c)
        Memset_c = M->getOrInsertFunction("memset_c", CapTy, CapTy, Int32Ty,
                                          Int64Ty);
      MemSet.getCallee()->replaceAllUsesWith(Memset_c.getCallee());
      setAliasee(Const, "memset_c");
      Modified = true;
    }
    FunctionCallee MemMove = M->getFunction("memmove");
    if (MemMove) {
      auto *Const = getAliasee("memmove_c");
      if (!Memmove_c)
        Memmove_c = M->getOrInsertFunction("memmove_c", CapTy, CapTy, CapTy,
                                           Int64Ty);
      MemMove.getCallee()->replaceAllUsesWith(Memmove_c.getCallee());
      setAliasee(Const, "memmove_c");
      Modified = true;
    }
  }

  virtual bool runOnFunction(Function &F) {
    // Nothing to do if we are not in sandbox mode.
    const DataLayout &DL = M->getDataLayout();
    if (DL.getAllocaAddrSpace() != 200)
      return false;

    if (!useCHERICapLibFunc(true))
      return false;

    Modified = false;
    visit(F);
    replaceMemFun(F);

    return Modified;
  }
};

} // anonymous namespace

char AArch64SandboxMemOpLowering::ID;

namespace llvm {
FunctionPass *createAArch64SandboxMemOpLowering(void) {
  return new AArch64SandboxMemOpLowering();
}
}
