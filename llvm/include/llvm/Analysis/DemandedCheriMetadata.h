//===- llvm/Analysis/DemandedCheriMetadata.h - Determine demanded bits ---===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===---------------------------------------------------------------------===//
//
// This pass implements a demanded bits analysis for CHERI metadata bits.
// This is similar to the existing demanded bits analysis and could be
// integrated into it at some point. We model the entire permissions using one
// bit for simplicity.
//===---------------------------------------------------------------------===//

#ifndef LLVM_ANALYSIS_DEMANDED_CHERI_METADATA_H
#define LLVM_ANALYSIS_DEMANDED_CHERI_METADATA_H

#include "llvm/ADT/APInt.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/Optional.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Pass.h"

namespace llvm {

class Function;
class Instruction;
class raw_ostream;

class DemandedCheriMetadata {
public:
  DemandedCheriMetadata(Function &F) : F(F) {}

  /// Return true iff the metadata bits from instruction I are demanded.
  ///
  /// Currently doesn't handle vector instructions
  ///
  /// Non-capability instructions don't have metadata so there is
  /// no demanded metadata.
  bool getDemandedCheriMetadata(Instruction *I);

  void print(raw_ostream &OS);

private:
  void performAnalysis();
  void propagateMetadataLiveness(const Instruction *UserI,
    const Value *Val, unsigned OperandNo,
    const bool AOut, bool &AB);

  Function &F;

  bool Analyzed = false;

  // The set of visited instructions.
  SmallPtrSet<Instruction*, 32> Visited;
  DenseMap<Instruction *, bool> AliveBits;
};

class DemandedCheriMetadataWrapperPass : public FunctionPass {
private:
  mutable Optional<DemandedCheriMetadata> DB;

public:
  static char ID; // Pass identification, replacement for typeid

  DemandedCheriMetadataWrapperPass();

  bool runOnFunction(Function &F) override;
  void getAnalysisUsage(AnalysisUsage &AU) const override;

  /// Clean up memory in between runs
  void releaseMemory() override;

  DemandedCheriMetadata &getDemandedCheriMetadata() { return *DB; }

  void print(raw_ostream &OS, const Module *M) const override;
};

/// An analysis that produces \c DemandedCheriMetadata for a function.
class DemandedCheriMetadataAnalysis : public AnalysisInfoMixin<DemandedCheriMetadataAnalysis> {
  friend AnalysisInfoMixin<DemandedCheriMetadataAnalysis>;

  static AnalysisKey Key;

public:
  /// Provide the result type for this analysis pass.
  using Result = DemandedCheriMetadata;

  /// Run the analysis pass over a function and produce demanded metadata bits
  /// information.
  DemandedCheriMetadata run(Function &F, FunctionAnalysisManager &AM);
};

/// Printer pass for DemandedCheriMetadata
class DemandedCheriMetadataPrinterPass : public PassInfoMixin<DemandedCheriMetadataPrinterPass> {
  raw_ostream &OS;

public:
  explicit DemandedCheriMetadataPrinterPass(raw_ostream &OS) : OS(OS) {}

  PreservedAnalyses run(Function &F, FunctionAnalysisManager &AM);
};

/// Create a demanded bits analysis pass.
FunctionPass *createDemandedCheriMetadataWrapperPass();

} // end namespace llvm

#endif // LLVM_ANALYSIS_DEMANDED_CHERI_METADATA_H
