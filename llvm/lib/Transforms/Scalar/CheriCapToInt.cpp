//====-- CheriCapToInt.cpp - Demote capability ops to work on integers ---====//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===---------------------------------------------------------------------===//

#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/Optional.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/Analysis/DemandedCheriMetadata.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/InitializePasses.h"
#include "llvm/Pass.h"
#include "llvm/Transforms/Scalar.h"
#include "llvm/Transforms/Scalar/CheriCapToInt.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

#define DEBUG_TYPE "cheri-cap-to-int"

namespace {

class CheriCapToIntLegacyPass : public FunctionPass {

public:
  static char ID; // Pass ID, replacement for typeid

  CheriCapToIntLegacyPass()
      : FunctionPass(ID) {
    initializeCheriCapToIntLegacyPassPass(*PassRegistry::getPassRegistry());
  }

  bool runOnFunction(Function &F) override {
    if (skipFunction(F))
      return false;

    auto *DCM = &getAnalysis<DemandedCheriMetadataWrapperPass>().getDemandedCheriMetadata();
    return Impl.runImpl(F, DCM);
  }

  StringRef getPassName() const override { return "Cheri Capability to integer"; }

  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.setPreservesCFG();
    AU.addRequired<DemandedCheriMetadataWrapperPass>();
  }

private:
  CheriCapToIntPass Impl;
};

} // end anonymous namespace

char CheriCapToIntLegacyPass::ID = 0;

INITIALIZE_PASS_BEGIN(CheriCapToIntLegacyPass, DEBUG_TYPE, "Cheri Capability to integer",
                      false, false)
INITIALIZE_PASS_DEPENDENCY(DemandedCheriMetadataWrapperPass)
INITIALIZE_PASS_END(CheriCapToIntLegacyPass, DEBUG_TYPE, "Cheri Capability to integer",
                    false, false)

FunctionPass *llvm::createCheriCapToIntPass() {
  return new CheriCapToIntLegacyPass();
}

PreservedAnalyses CheriCapToIntPass::run(Function &F, FunctionAnalysisManager &AM) {
  DemandedCheriMetadata &DCM = AM.getResult<DemandedCheriMetadataAnalysis>(F);
  if (!runImpl(F, &DCM))
    return PreservedAnalyses::all();

  PreservedAnalyses PA;
  PA.preserveSet<CFGAnalyses>();
  return PA;
}

static Constant *getIntFromCapConstant(Value *V, const DataLayout &DL, LLVMContext &Ctx) {
  V = V->stripPointerCasts();
  assert(DL.isFatPointer(V->getType()) && "Expected fat pointer");
  if (!isa<Constant>(V))
    return nullptr;

  unsigned BitWidth =
      DL.getIndexSizeInBits(
          cast<PointerType>(V->getType())->getPointerAddressSpace());
  Type *IntTy = IntegerType::get(Ctx, BitWidth);

  Constant *C = cast<Constant>(V);
  if (C->isNullValue())
    return ConstantInt::get(IntTy, 0);

  if (GEPOperator *GEP = dyn_cast<GEPOperator>(V)) {
    int64_t Offset;
    auto *Base = GetPointerBaseWithConstantOffset(GEP, Offset, DL);
    if (!Base)
      return nullptr;
    Base = Base->stripPointerCasts();
    if (!cast<Constant>(Base)->isNullValue())
      return nullptr;
    return ConstantInt::get(IntTy, Offset);
  }
  return nullptr;
}

static void getRequiredOps(Instruction *I,
                           SmallVectorImpl<int> &Ops) {
  switch (I->getOpcode()) {
  case Instruction::Load:
    return;
  case Instruction::Call:
  case Instruction::Invoke: {
    const IntrinsicInst *II = cast<IntrinsicInst>(I);
    switch (II->getIntrinsicID()) {
    case Intrinsic::cheri_cap_address_set:
      return;
    case Intrinsic::cheri_cap_perms_and:
    case Intrinsic::cheri_cap_bounds_set:
    case Intrinsic::cheri_cap_bounds_set_exact:
      Ops.push_back(0);
      return;
    default: llvm_unreachable("Unexpected intrinsic");
    }
  }
  case Instruction::GetElementPtr:
    Ops.push_back(0);
    return;
  case Instruction::BitCast:
  case Instruction::Freeze:
    Ops.push_back(0);
    return;
  case Instruction::Select:
    Ops.push_back(1);
    Ops.push_back(2);
    return;
  case Instruction::PHI: {
    for (unsigned i = 0; i < I->getNumOperands(); ++i)
      Ops.push_back(i);
    return;
  }
  default:
  llvm_unreachable("Unexpected instruction");
  }
}

Value *CheriCapToIntPass::convert(Value *V) {
  if (Constant *C = dyn_cast<Constant>(V)) {
    Constant *Conv = getIntFromCapConstant(C, *DL, *Ctx);
    assert(Conv && "All constants should be null-derived");
    return Conv;
  }

  Value *Converted = nullptr;
  Instruction *I = cast<Instruction>(V);
  if (ToInt.find(I) != ToInt.end())
    // Already converted this instruction.
    return ToInt[I];
  IRBuilder<> Builder(I);
  switch (I->getOpcode()) {
  case Instruction::Load: {
    LoadInst *LI = dyn_cast<LoadInst>(I);
    Value *LoadBase = LI->getPointerOperand();
    unsigned AS = cast<PointerType>(LoadBase->getType())->getAddressSpace();
    Type *IntTy =
        IntegerType::get(*Ctx, DL->getIndexTypeSizeInBits(LI->getType()));
    Value *Base =
        CastInst::CreatePointerCast(LoadBase,
	                            PointerType::get(IntTy, AS), "", LI);
    Align NewAlign = LI->getAlign();
    if (DL->isBigEndian()) {
      assert(DL->getIndexTypeSizeInBits(LI->getType()) ==
          2 * DL->getTypeSizeInBits(LI->getType()) &&
	  "Unexpected capability format");
      Base =
          GetElementPtrInst::Create(IntTy, Base, {ConstantInt::get(IntTy, 1)},
	                            "", LI);
      NewAlign =
          std::min(Align(DL->getIndexTypeSizeInBits(LI->getType()) / 8),
	           NewAlign);
    }

    Converted = new LoadInst(
        IntTy, Base, LI->getName() + ".narrowed", LI->isVolatile(),
	NewAlign, LI->getOrdering(), LI->getSyncScopeID(), LI);
    cast<Instruction>(Converted)->copyMetadata(*LI);
    break;
  }
  case Instruction::Call:
  case Instruction::Invoke: {
    IntrinsicInst *II = cast<IntrinsicInst>(I);
    switch (II->getIntrinsicID()) {
    case Intrinsic::cheri_cap_address_set:
      Converted = II->getOperand(1);
      break;
    case Intrinsic::cheri_cap_perms_and:
    case Intrinsic::cheri_cap_bounds_set:
    case Intrinsic::cheri_cap_bounds_set_exact:
      Converted = convert(II->getOperand(0));
      break;
    default: llvm_unreachable("not implemented");
    }
    break;
  }
  case Instruction::Select: {
    Value *LHS = convert(I->getOperand(1));
    Value *RHS = convert(I->getOperand(2));
    Converted = Builder.CreateSelect(I->getOperand(0), LHS, RHS);
    break;
  }
  case Instruction::PHI: {
    PHINode *PHI = cast<PHINode>(I);
    unsigned BitWidth = DL->getIndexSizeInBits(
        cast<PointerType>(PHI->getType())->getPointerAddressSpace());
    Type *IntTy = IntegerType::get(*Ctx, BitWidth);
    PHINode *NewPHI = Builder.CreatePHI(IntTy, PHI->getNumOperands());
    // Add NewPHI to the map now to avoid seeing the node again while
    // converting the operands.
    ToInt[I] = NewPHI;
    for (unsigned i = 0; i < PHI->getNumOperands(); ++i) {
      Value *Op = PHI->getOperand(i);
      Op = PHI == Op ? NewPHI : convert(Op);
      NewPHI->addIncoming(Op, PHI->getIncomingBlock(i));
    }
    return NewPHI;
  }
  case Instruction::BitCast: {
    Converted = convert(I->getOperand(0));
    break;
  }
  case Instruction::Freeze: {
    Converted = Builder.CreateFreeze(convert(I->getOperand(0)));
    break;
  }
  case Instruction::GetElementPtr: {
    GetElementPtrInst *GEP = cast<GetElementPtrInst>(I);
    Converted = convert(GEP->getPointerOperand());

    unsigned BitWidth = DL->getIndexSizeInBits(GEP->getPointerAddressSpace());
    Type *IntTy = IntegerType::get(*Ctx, BitWidth);
    MapVector<Value *, APInt> VariableOffsets;
    APInt ConstantOffset(BitWidth, 0);
    GEP->collectOffset(*DL, BitWidth, VariableOffsets, ConstantOffset);
    for (auto Offset : VariableOffsets) {
      Value *OffsetVal = Builder.CreateSExtOrTrunc(Offset.first, IntTy);
      OffsetVal = Builder.CreateMul(OffsetVal,
          ConstantInt::get(IntTy, Offset.second.getSExtValue()));
      Converted = Builder.CreateAdd(Converted, OffsetVal);
    }
    if  (!ConstantOffset.isNullValue())
      Converted = Builder.CreateAdd(Converted,
          ConstantInt::get(IntTy, ConstantOffset.getSExtValue()));
    break;
  }
  default:
    llvm_unreachable("not implemented");
  }
  ToInt[I] = Converted;
  return Converted;
}

void CheriCapToIntPass::fixupUses(Instruction *I) {
  Value *New = ToInt[I];
  unsigned AS = cast<PointerType>(I->getType())->getAddressSpace();
  PointerType *Int8PtrTy = Type::getInt8PtrTy(*Ctx, AS);
  SmallVector<Use *, 4> Uses;
  for (Use &U : I->uses())
    Uses.push_back(&U);

  auto getAddress = [&](Value *V, IRBuilder<> &Builder) {
    Value *ToReturn = nullptr;
    Type *IntTy =
        IntegerType::get(*Ctx, DL->getIndexTypeSizeInBits(V->getType()));
    if (Constant *C = dyn_cast<Constant>(V)) {
      // Could we always do a ptrtoint in purecap?
      ToReturn = getIntFromCapConstant(C, *DL, *Ctx);
      if (ToReturn)
        return ToReturn;
    }
    if (Instruction *Inst = dyn_cast<Instruction>(V)) {
      auto CVIt = ToInt.find(Inst);
      if (CVIt != ToInt.end()) {
        ToReturn = CVIt->second;
        return ToReturn;
      }
    }

    ToReturn = Builder.CreateIntrinsic(Intrinsic::cheri_cap_address_get,
        {IntTy}, {Builder.CreateBitCast(V, Int8PtrTy)});

    return ToReturn;
  };

  std::map<BasicBlock *, Value *> CrossBlockUses;
  for (Use *U : Uses) {
    Instruction *ToUpdate = cast<Instruction>(U->getUser());
    if (Insts.find(ToUpdate) != Insts.end()) {
      // We'll erase all these instructions so there's no point in updating
      // them with anything sensible.
      U->set(UndefValue::get(I->getType()));
      continue;
    }
    Value *Null = Constant::getNullValue(Int8PtrTy);

    if (PHINode *PHI = dyn_cast<PHINode>(ToUpdate)) {
      BasicBlock *BB = PHI->getIncomingBlock(U->getOperandNo());
      auto it = CrossBlockUses.find(BB);
      Value *Derived = nullptr;
      if (it != CrossBlockUses.end())
	Derived = it->second;
      else {
        GetElementPtrInst *GEP =
            GetElementPtrInst::Create(Int8PtrTy->getElementType(), Null, {New}, "",
            BB->getTerminator());
        Derived = CastInst::CreatePointerCast(GEP, I->getType(), "",
            BB->getTerminator());
	CrossBlockUses[BB] = Derived;
      }
      U->set(Derived);
      continue;
    }
    bool Transformed = false;
    switch (ToUpdate->getOpcode()) {
    case Instruction::Call:
    case Instruction::Invoke: {
      IntrinsicInst *II = cast<IntrinsicInst>(ToUpdate);
      switch (II->getIntrinsicID()) {
        case Intrinsic::cheri_cap_address_get:
	  for (Use &DiffU: II->uses()) {
	    Instruction *DU = cast<Instruction>(DiffU.getUser());
	    auto it = ToInt.find(DU);
	    if (it != ToInt.end() && it->second == II)
	      ToInt[DU] = New;
	  }
          ToUpdate->replaceAllUsesWith(New);
          ToUpdate->eraseFromParent();
          Transformed = true;
	  break;
        case Intrinsic::cheri_cap_diff: {
          if (II->getOperand(0) == II->getOperand(1))
            // We could just return 0 here, though
            // we really should never see this.
            break;
          // Replace this with a sub.
          IRBuilder<> Builder(II);
          Value *Op1 = getAddress(II->getOperand(0), Builder);
          Value *Op2 = getAddress(II->getOperand(1), Builder);
          Value *Sub = Builder.CreateSub(Op1, Op2, II->getName());
	  for (Use &DiffU: II->uses()) {
	    Instruction *DU = cast<Instruction>(DiffU.getUser());
	    auto it = ToInt.find(DU);
	    if (it != ToInt.end() && it->second == II)
	      ToInt[DU] = Sub;
	  }
          II->replaceAllUsesWith(Sub);
          II->eraseFromParent();
          Transformed = true;
          break;
        }
        default: break;
      }
      break;
    }
    case Instruction::ICmp: {
      ICmpInst *Cmp = cast<ICmpInst>(ToUpdate);
      if (Cmp->getOperand(0) == Cmp->getOperand(1))
	break;
      IRBuilder<> Builder(Cmp);
      Value *Op1 = getAddress(Cmp->getOperand(0), Builder);
      Value *Op2 = getAddress(Cmp->getOperand(1), Builder);
      Value *IntCmp = Builder.CreateICmp(Cmp->getPredicate(), Op1, Op2, Cmp->getName());
      Cmp->replaceAllUsesWith(IntCmp);
      Cmp->eraseFromParent();
      Transformed = true;
      break;
    }
    default: break;
    }
    if (Transformed)
      continue;
    GetElementPtrInst *GEP =
        GetElementPtrInst::Create(Int8PtrTy->getElementType(), Null, {New}, "", ToUpdate);
    Value *Derived = CastInst::CreatePointerCast(GEP, I->getType(), "", ToUpdate);
    U->set(Derived);
  }
}

void CheriCapToIntPass::gatherCandidates(Function &Fn,
                                         DemandedCheriMetadata *DCM) {
  // Gather instructions which we can convert to integer variants
  for (auto &BB : Fn) {
    for (BasicBlock::iterator IT = BB.begin(); IT != BB.end(); ++IT) {
      Instruction *I = &*IT;
      if (DCM->getDemandedCheriMetadata(I) || I->getType()->isVectorTy() ||
	  !DL->isFatPointer(I->getType()))
	continue;
      if (isa<ExtractValueInst>(I))
	continue;

      if (GetElementPtrInst *GEP = dyn_cast<GetElementPtrInst>(I)) {
	// We can only transform if we can collect the offsets for the GEP.
        unsigned BitWidth =
	    DL->getIndexSizeInBits(GEP->getPointerAddressSpace());
        MapVector<Value *, APInt> VariableOffsets;
        APInt ConstantOffset(BitWidth, 0);
        if (!GEP->collectOffset(*DL, BitWidth, VariableOffsets, ConstantOffset))
	  continue;
      }

      LoadInst *LI = dyn_cast<LoadInst>(I);
      if (LI && LI->isVolatile())
	// Ignore volatile loads.
	continue;
      
      if (const IntrinsicInst *II = dyn_cast<IntrinsicInst>(I)) {
        switch (II->getIntrinsicID()) {
        default: continue;
        case Intrinsic::cheri_cap_address_set:
        case Intrinsic::cheri_cap_perms_and:
        case Intrinsic::cheri_cap_bounds_set:
        case Intrinsic::cheri_cap_bounds_set_exact:
	break;
	}
      } else if (I->getOpcode() == Instruction::Call ||
                 I->getOpcode() == Instruction::Invoke)
        // We can't do anything about these without inserting a
	// cheri_cap_address_get.
        continue;

      // Everything else is a candidate.
      Insts.insert(I);
    }
  }
}

void CheriCapToIntPass::filterCandidates() {
  // Compute the set of instructions that we want to transform. We'll
  // try to only do the tranformation if we can avoid emitting address_get
  // calls to avoid increasing register pressure.
  SmallSet<Instruction *, 4> Enqueued;
  SmallVector<Instruction *, 4> Worklist;
  for (Instruction *I : Insts) {
    Worklist.push_back(I);
    Enqueued.insert(I);
  }

  // Make sure all operands can be transformed without the need to emit
  // address_get calls. For instruction operands this means that they
  // need to be in the set of tranformable instructions. For constants
  // we want them to be null-derived capability constants which can be
  // converted to integers.
  while (!Worklist.empty()) {
    Instruction *I = Worklist.pop_back_val();
    Enqueued.erase(I);
    SmallVector<int, 4> Ops;
    getRequiredOps(I, Ops);
    bool ToErase = false;
    // Check all required (capability) operands. If we find one which
    // is not transformable we remove the current instruction from the
    // candidate set.
    for (int OpNum : Ops) {
      Value *V = I->getOperand(OpNum);
      Instruction *Dep = dyn_cast<Instruction>(V);
      if (Dep && Insts.find(Dep) != Insts.end())
        continue;
      Constant *C = dyn_cast<Constant>(V);
      if (C && getIntFromCapConstant(C, *DL, *Ctx))
        continue;
      // TODO: we should be able to handle arguments as well.
      ToErase = true;
      break;
    }

    if (!ToErase)
      continue;

    Insts.erase(I);
    // We've removed an instruction from the candidate set. All users
    // which are in the candidate set need to be removed as well.
    for (User *U : I->users()) {
      Instruction *Dep = cast<Instruction>(U);
      if (Insts.find(Dep) != Insts.end() &&
          Enqueued.find(Dep) == Enqueued.end()) {
        Enqueued.insert(Dep);
	Worklist.push_back(Dep);
      }
    }
  }
}

bool CheriCapToIntPass::transform(Function &Fn) {
  // Record insts to get their order
  SmallVector<Instruction *, 10> OrderedInsts;
  for (auto &BB : Fn)
    for (BasicBlock::iterator IT = BB.begin(); IT != BB.end(); ++IT) {
      Instruction *I = &*IT;
      if (Insts.find(I) != Insts.end())
	OrderedInsts.push_back(I);
    }

  // Create new integer instructions.
  for (Instruction *I : OrderedInsts)
    convert(I);

  // Replace all uses of the old instruction.
  for (Instruction *I : OrderedInsts)
    fixupUses(I);

  // Cleanup.
  for (Instruction *I : OrderedInsts)
    I->eraseFromParent();

  return !OrderedInsts.empty();
}

bool CheriCapToIntPass::runImpl(Function &Fn, DemandedCheriMetadata *DCM) {
  DL = &Fn.getParent()->getDataLayout();
  Insts.clear();
  ToInt.clear();
  ToNull.clear();
  Ctx = &Fn.getContext();

  gatherCandidates(Fn, DCM);
  filterCandidates();
  // Do the transformation.
  return transform(Fn);
}
