//===-- CheriCapToInt.h - Demote capability opss to work on integers -----===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===---------------------------------------------------------------------===//

#ifndef LLVM_TRANSFORMS_SCALAR_CHERICAPTOINT_H
#define LLVM_TRANSFORMS_SCALAR_CHERICAPTOINT_H

#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/IR/ConstantRange.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Analysis/DemandedCheriMetadata.h"

namespace llvm {

class CheriCapToIntPass : public PassInfoMixin<CheriCapToIntPass> {
public:
  PreservedAnalyses run(Function &F, FunctionAnalysisManager &AM);

  // Glue for old PM.
  bool runImpl(Function &F, DemandedCheriMetadata *DCM);
private:
  Value *convert(Value *V);
  void fixupUses(Instruction *I);
  bool transform(Function &F);
  void gatherCandidates(Function &F, DemandedCheriMetadata *DCM);
  void filterCandidates();

  // Candidates for conversion to integer instructions.
  SmallSet<Instruction *, 4> Insts;
  // Mapping from original instructions to int instructions.
  std::map<Instruction *, Value *> ToInt;
  // Mapping from original instructions to new instructions
  // derived from null (after being converted to int).
  std::map<Instruction *, Value *> ToNull;
  LLVMContext *Ctx;
  const DataLayout *DL;
};
}
#endif // LLVM_TRANSFORMS_SCALAR_CHERICAPTOINT_H
