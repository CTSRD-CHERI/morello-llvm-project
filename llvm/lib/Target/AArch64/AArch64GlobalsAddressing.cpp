//===- AArch64GlobalsAddressing.cpp -----------------------------*- C++ -*-===//
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
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/IR/Module.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/Pass.h"
#include "llvm/Transforms/Utils/Local.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/InitializePasses.h"
#include "llvm/IR/Dominators.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"

#include "AArch64TargetMachine.h"

using namespace llvm;

#define DEBUG_TYPE "aarch64-sandbox-globals-addressing"

static cl::opt<bool>
MergeOpt("aarch64-sandbox-merge",
         cl::desc("Can create global addresses by setting bounds "
                  "on a larger 'merged' global"),
         cl::init(true));

static cl::opt<bool>
OptSafeAccess("aarch64-optimize-safe-accesses",
         cl::desc("Avoid bounds setting for safe accesses"),
         cl::init(true));

// This pass takes the output of the global merge pass and further simplifies
// addressing to use the merged globals. The global merge pass will merge
// the globals that are valid to merge, and replace all the old globals with
// aliases to the merged global.
// If profitable, we can:
//   (1) Get the address of the merged global from the capability table
//       using a pc-relative load.
//   (2) Use the merged global directly if we are sure there no bounds
//       issues. The address of the merged global should already be in
//       a register, which means that we get the global address computation
//       for free. This is a fairly common occurrence (most accesses).
//       This reduces the access for n globals from n x (adrp + load)
//       to one load and one adrp.
//   (3) If we are unsure about how the address of our alias is used (there
//       could be bounds issues) we can derive the address of our alias
//       from the merged global using a bounds setting instruction. This
//       usually takes 2 instructions (add + scbnds), however none of them
//       are loads.
//
// We consider using the merged global profitable if the function uses
// at least two aliases from the same merged global. If it doesn't
// we don't do anything and fall back on loading the capability to the
// alias from the capability table.

namespace
{
class AArch64SandboxGlobalAddressing : public FunctionPass {

  virtual llvm::StringRef getPassName() const override {
    return "AArch64 sandbox global addressing";
  }


public:
  static char ID;
  DominatorTree *DT;
  LoopInfo *LI;

  AArch64SandboxGlobalAddressing () :
      FunctionPass(ID) {}

  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.setPreservesCFG();
    AU.addRequired<DominatorTreeWrapperPass>();
    AU.addRequired<LoopInfoWrapperPass>();
  }

  struct GlobalUse {
    GlobalUse(Instruction &Inst, unsigned Idx, GlobalValue *GV,
              GlobalVariable *Base) :
        Inst(Inst), Idx(Idx), GV(GV), Base(Base) {}
    Instruction &Inst; // Instruction that contains this use.
    unsigned Idx;      // The index oof the use.
    GlobalValue *GV;   // What interesting global does this refer to.
    GlobalVariable *Base; // Underlying object for this global (alias).
  };

  // Map the base ('merged') global to aliases used by this function to
  // a vector containing information about their uses.
  std::map<GlobalVariable *, std::map<GlobalValue *, std::vector<GlobalUse>>> Uses;

  // The Transforms class performs the actual transformation (constructing
  // the address of the alias using a bounds setting instruction). Furthermore
  // it provides a cache for what transformations we already performed on
  // constants and where we've inserted these.
  class Transforms {
  private:
    // The set of 'interesting' globals.
    SmallSet<GlobalValue *, 10> &Globals;
    const DataLayout &DL;
    Function &F;
    Function *SetBoundsFun = nullptr;
    Instruction *IP = nullptr;
    // For each insertion point we remember the performed transformations.
    std::map<Instruction *, std::map<Value *, Value *>> Processed;

    // Lazily get the set bounds intrinsic.
    Function *getSetBoundsFun() {
      if (SetBoundsFun)
        return SetBoundsFun;
      Intrinsic::ID SetBounds = Intrinsic::cheri_cap_bounds_set;
      Type *SizeTy = Type::getIntNTy(F.getParent()->getContext(),
                                     DL.getIndexSizeInBits(200));
      SetBoundsFun = Intrinsic::getDeclaration(F.getParent(), SetBounds, SizeTy);
      return SetBoundsFun;
    }

  public:
    // Create a Transforms using the set of interesting globals and the
    // function on which we're going to run.
    Transforms(SmallSet<GlobalValue *, 10> &Globals, Function &F) :
        Globals(Globals), DL(F.getParent()->getDataLayout()), F(F) {

    }

    // Transform an interesting global and remember the transformation.
    // For a global alias this would construct the address of the alias
    // by performing a scbnds on the underlying global.
    Value *transform(GlobalValue * GV) {
      // Do nothing if we're not looking for this global.
      if (!Globals.count(GV))
        return GV;
      // See if we already processed this global.
      if (Value *Cached = get(GV))
        return Cached;
      // Construct the address of the alias using a bounds setting instruction.
      GlobalAlias *GA = dyn_cast<GlobalAlias>(GV);
      if (!GA)
        llvm_unreachable("Transforming non-aliases not implemented");

      IntegerType *SizeTy = Type::getIntNTy(F.getParent()->getContext(),
                                            DL.getIndexSizeInBits(200));
      Constant *Size = ConstantInt::get(SizeTy,
          DL.getTypeAllocSize(GA->getValueType()));

      auto *Cast = CastInst::CreatePointerCast(GA->getAliasee(),
          getSetBoundsFun()->getFunctionType()->getParamType(0));
      Cast->insertBefore(IP);

      auto *CI =  CallInst::Create(getSetBoundsFun()->getFunctionType(),
          getSetBoundsFun(), {Cast, Size}, "bounded", IP);

      Cast = CastInst::CreatePointerCast(CI, GV->getType());
      Cast->insertBefore(IP);
      Processed[IP][GV] = Cast;
      return Cast;
    }

    // Remember what transformed value we produced for some constant
    // expression.
    void setExpr(ConstantExpr *Expr, Value *Transformed) {
      Processed[IP][Expr] = Transformed;
    }

    // Set the insertion point.
    void setIP(Instruction *IP) {
      this->IP = IP;
    }

    // Get the insertion point.
    Instruction *getIP() {
      return IP;
    }

    // Get the transformed value for a certain value (or null if we haven't
    // seen this before).
    Value *get(Value *Val) {
      auto it = Processed[IP].find(Val);
      if (it != Processed[IP].end())
        return it->second;
      return nullptr;
    }
  };

  // This does the heavy lifting for replacing a constant. Recursively
  // transforms the constant, applying the transformation on each global.
  // A transformation can produce an instruction instead of a constant.
  Value* replaceConstantHelper(Value *Val, Transforms &Mappings) {
    // if this is a constant expression
    if (Value *Transformed = Mappings.get(Val))
      return Transformed;
    if (GlobalValue *GV = dyn_cast<GlobalValue>(Val))
      return Mappings.transform(GV);

    ConstantExpr *Expr = dyn_cast<ConstantExpr>(Val);
    if (!Expr)
      return Val;

    // Replace all the constant expression operands.
    bool Changed = false;
    bool NeedsInstruction = false;
    SmallVector<Value *, 4> Operands(Expr->operands());
    for (unsigned i = 0; i < Operands.size(); ++i) {
      Value *NewValue = replaceConstantHelper(Operands[i], Mappings);
      if (NewValue != Operands[i])
        Changed = true;
      if (isa<Instruction>(NewValue))
        NeedsInstruction = true;
      Operands[i] = NewValue;
    }

    // Nothing has changed, don't do anything.
    if (!Changed) {
      Mappings.setExpr(Expr, Expr);
      return Val;
    }

    // Something has changed, but none of the new operands are instructions.
    // Construct a new constant expression.
    if (!NeedsInstruction) {
      std::vector<Constant*> Ops;
      for (Value *Val : Operands)
        Ops.push_back(cast<Constant>(Val));
      Constant *NewExpr = Expr->getWithOperands(Ops);
      Mappings.setExpr(Expr, NewExpr);
      return NewExpr;
    }

    // Some of the operands are now instructions, and we need to convert
    // this to a instructon.
    Instruction *Inst = Expr->getAsInstruction();
    for (unsigned i = 0; i < Inst->getNumOperands(); ++i)
      Inst->setOperand(i, Operands[i]);
    Inst->insertBefore(Mappings.getIP());
    // Remeber Expr so that we don't process it again.
    Mappings.setExpr(Expr, Inst);
    return Inst;
  }

  Instruction *findMatInsertPtHelper(Instruction *Inst, unsigned Idx) const {
    // The simple and common case. This also includes constant expressions.
    if (!isa<PHINode>(Inst) && !Inst->isEHPad())
      return Inst;
 
    // We can't insert directly before a phi node or an eh pad. Insert before
    // the terminator of the incoming or dominating block.
    if (isa<PHINode>(Inst))
      return cast<PHINode>(Inst)->getIncomingBlock(Idx)->getTerminator();
 
    // This must be an EH pad. Iterate over immediate dominators until we find a
    // non-EH pad. We need to skip over catchswitch blocks, which are both EH pads
    // and terminators.
    auto IDom = DT->getNode(Inst->getParent())->getIDom();
    while (IDom->getBlock()->isEHPad())
      IDom = IDom->getIDom();
 
    return IDom->getBlock()->getTerminator();
  }

  /// Find the constant materialization insertion point.
  Instruction *findMatInsertPt(Instruction *Inst, unsigned Idx) {
    Inst = findMatInsertPtHelper(Inst, Idx);
    auto *L = LI->getLoopFor(Inst->getParent());
    // MachineLICM can have issues with hoisting this, so make sure we don't
    // insert in the innermost loop.
    if (!L)
      return Inst;
    // If this loop has a preheader use it.
    if (BasicBlock *BB = L->getLoopPreheader())
      return BB->getTerminator();
    return Inst;
  }

  // Transform the constant at use U.
  void replaceConstant(Use *U, Transforms &Mappings) {
    // Figure out insertion point.
    Instruction *IP = findMatInsertPt(cast<Instruction>(U->getUser()),
                                      U->getOperandNo());
    Mappings.setIP(IP);
    U->set(replaceConstantHelper(U->get(), Mappings));
  }

  // Determine if this is an interesting global use. If so, record this in our
  // analysis structure. This looks for a specific pattern (the aliasee is a
  // GEP on a global variable) which happens to be what the GlobalMerge pass
  // produces.
  bool isGlobalUse(Constant *Const, Instruction &Inst, unsigned Idx) {
    GlobalAlias *GA = dyn_cast<GlobalAlias>(Const);
    if (GA && !GA->isInterposable()) {
      // See if the aliasee is a gep on a global variable
      GEPOperator *GEP = dyn_cast<GEPOperator>(GA->getAliasee());
      if (!GEP)
        return true;
      Value *Base = GEP->getPointerOperand();
      GlobalVariable *GV = dyn_cast<GlobalVariable>(Base);
      if (!GV)
        return true;
      Uses[GV][GA].emplace_back(GlobalUse(Inst, Idx, GA, GV));
      return true;
    }
    return false;
  }

  // Explore all sub-constants to find interesting globals. Each
  // sub-constant is only visited once.
  void exploreConstant(Constant *C, Instruction &Inst, unsigned Idx) {
    SmallSet<Constant *, 10> Visiting;
    std::vector<Constant *> List;
    List.push_back(C);
    Visiting.insert(C);
    while (!List.empty()) {
      Constant *Const = List.back();
      List.pop_back();
      if (isGlobalUse(Const, Inst, Idx))
        // We've found something!
        continue;
      ConstantExpr *Expr = dyn_cast<ConstantExpr>(C);
      if (!Expr)
        continue;
      for (unsigned i = 0; i < Expr->getNumOperands(); ++i) {
        Constant *Op = Expr->getOperand(i);
        if (Visiting.count(Op))
          continue;
        Visiting.insert(Op);
        List.push_back(Op);
      }
    }
  }

  // Explore all constants used as instruction operands in F in order
  // to find uses of interesting globals (see isGlobalUse for the
  // definition of interesting). Since we're only looking at F we're
  // taking a top-down approach.
  void gatherUsedGlobals(Function &F) {
    for (BasicBlock &BB : F)
      for (Instruction &Inst: BB)
        for (unsigned i = 0; i < Inst.getNumOperands(); ++i)
          if (Constant *C = dyn_cast<Constant>(Inst.getOperand(i)))
            exploreConstant(C, Inst, i);
  }

  // Determine if this is a safe access, and if so replace it with
  // an access directly to the underlying object. This avoids doing a bounds
  // setting operation. A safe access is a load/store which we know won't fault
  // due to bounds issues (as long as the underlying object has the correct
  // bounds).
  bool replaceSafeAccess(Function &F, GlobalUse &GVUse, GlobalValue *GV,
                         GlobalVariable *Merged) {
    // Don't do anything if this optimization has been disabled.
    if (!OptSafeAccess)
      return false;

    const DataLayout &DL = F.getParent()->getDataLayout();
    LLVMContext &C = F.getParent()->getContext();
    PointerType *I8Ptr = PointerType::get(Type::getInt8Ty(C),
                                          DL.getGlobalsAddressSpace());
    // Make sure this is a load or a store and the use is our address operand.
    if (!((isa<LoadInst>(GVUse.Inst) && GVUse.Idx == 0) ||
        (isa<StoreInst>(GVUse.Inst) && GVUse.Idx == 1)))
      return false;

    // Look at how much memory we're accessing and determine if this is safe.
    int64_t Size;
    if (auto *LI = dyn_cast<LoadInst>(&GVUse.Inst))
      Size = DL.getTypeStoreSize(LI->getType());
    if (auto *SI = dyn_cast<StoreInst>(&GVUse.Inst)) 
      Size = DL.getTypeStoreSize(SI->getValueOperand()->getType());
    Value *Expr = GVUse.Inst.getOperand(GVUse.Idx);
    int64_t OffsetAccess, Offset;
    auto *BaseAccess = GetPointerBaseWithConstantOffset(Expr, OffsetAccess,
                                                        DL);
    auto *Base = GetPointerBaseWithConstantOffset(GV, Offset, DL);
    int64_t GVSize = DL.getTypeAllocSize(GV->getValueType());

    if (!(Base && BaseAccess && Base == BaseAccess && Base == Merged))
      return false;
    if (!(Offset <= OffsetAccess &&
        OffsetAccess + Size <= Offset + GVSize))
      return false;

    // The access is safe, replace the base operaand with a value constructed
    // from the underlying object.
    Constant *I8Base = ConstantExpr::getBitCast(Merged, I8Ptr);
    Constant *ConstOff = ConstantInt::get(Type::getInt64Ty(C), OffsetAccess);
    I8Base = ConstantExpr::getInBoundsGetElementPtr(Type::getInt8Ty(C),
                                                    I8Base, ConstOff);
    I8Base = ConstantExpr::getBitCast(I8Base, Expr->getType());
    LLVM_DEBUG(dbgs() << "[GA] Replacing safe access for " << GVUse.Inst
                      << " at operand " << GVUse.Idx << " with operand"
                      << *I8Base << "\n");
    GVUse.Inst.setOperand(GVUse.Idx, I8Base);
    return true;
  }

  // Look at all the global uses and replace all the safe ones with
  // accesses to the underlying object. Add unsafe accesses for the
  // next transformation in UnsafeUses.
  bool replaceSafeAccesses(Function &F, std::set<Use *> &UnsafeUses) {
    bool Replaced = false;
    // Look at all merged globals.
    for (auto it = Uses.begin(), e = Uses.end(); it != e; ++it) {
      // Look at all globals in the merged global
      GlobalVariable *Merged = it->first;
      for (auto it2 = it->second.begin(), e2 = it->second.end(); it2 != e2;
           ++it2) {
        // Look at aall the uses of this global and transform them if they
        // are safe.
        GlobalValue *GV = it2->first;
        for (auto &GVUse : it2->second) {
          if (replaceSafeAccess(F, GVUse, GV, Merged))
            continue;
          UnsafeUses.insert(&GVUse.Inst.getOperandUse(GVUse.Idx));
        }
      }
    }

    return Replaced;
  }

  // Find all global uses, populate our analysis data structure and
  // decide which globals we're going to optimize.
  void analyze(Function &F) {
    // Look at all constant used by this function and record their uses.
    gatherUsedGlobals(F);

    // The minimum number of globals used in a function to make this
    // transformation profitable is currently hard-coded to 2.
    static const int MinGlobalUses = 2;

    // Remove merged globals  which don't use at least MinGlobalUses uses.
    // This prevents the case where we're doing more work to produce the
    // global address using the merged global than just loading from the
    // capability table.
    SmallVector<GlobalVariable *, 4> ToRemove;
    for (auto it = Uses.begin(); it != Uses.end(); ++it)
      if (it->second.size() < MinGlobalUses) {
        ToRemove.push_back(it->first);
        continue;
      }

    // Erase from our analysis all globals that are not candidates.
    for (GlobalVariable *GV : ToRemove)
      Uses.erase(GV);
  }

  bool runOnFunction(Function &F) override {
    bool Modified = false;
    if (!MergeOpt)
      return false;
    DT = &getAnalysis<DominatorTreeWrapperPass>().getDomTree();
    LI = &getAnalysis<LoopInfoWrapperPass>().getLoopInfo();

    // Determine what globals we're going to optimize and where these are used.
    analyze(F);

    // Replace safe accesses and gather all unsafe uses.
    std::set<Use *> UnsafeUses;
    Modified = replaceSafeAccesses(F, UnsafeUses);

    // Gather all globals used by this function with unsafe uses and create
    // a transform object.
    SmallSet<GlobalValue *, 10> Globals;
    for (auto it = Uses.begin(); it != Uses.end(); ++it)
      for (auto it2 = it->second.begin(); it2 != it->second.end(); ++it2)
        Globals.insert(it2->first);
    Transforms Mappings(Globals, F);

    // Now replace all unsafe uses with bounds setting instructions on their
    // underlying object.
    for (Use *ExprUse : UnsafeUses)
      replaceConstant(ExprUse, Mappings);
    Modified = Modified || !UnsafeUses.empty();

    Uses.clear();
    return Modified;
  }
};

} // anonymous namespace

char AArch64SandboxGlobalAddressing::ID;
INITIALIZE_PASS_BEGIN(AArch64SandboxGlobalAddressing, "aarch64-sandbox-globals",
                      "AArch64 sandbox global addressing", false, false)
INITIALIZE_PASS_DEPENDENCY(DominatorTreeWrapperPass)
INITIALIZE_PASS_DEPENDENCY(LoopInfoWrapperPass)
INITIALIZE_PASS_END(AArch64SandboxGlobalAddressing, "aarch64-sandbox-globals",
                    "AArch64 sandbox global addressing", false, false)

namespace llvm {
FunctionPass *createAArch64SandboxGlobalAddressing() {
  return new AArch64SandboxGlobalAddressing();
}
}
