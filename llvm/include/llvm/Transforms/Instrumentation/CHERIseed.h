//===- Transforms/Instrumentation/CHERIseed.h -----------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines the CHERIseed module pass.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_TRANSFORMS_INSTRUMENTATION_CHERISEED_H
#define LLVM_TRANSFORMS_INSTRUMENTATION_CHERISEED_H

#include "llvm/IR/PassManager.h"
#include "llvm/Pass.h"

namespace llvm {

ModulePass *createCHERIseedSanitizerLegacyPass();

/// Module pass for CHERIseed instrumentation
///
/// This pass instruments an input IR which possibly contains capabilities.
/// The IR is transformed in a way so that addrspace(200) annotations get
/// eliminated and calls to CHERIseed's runtime are inserted to provide
/// CHERI C/C++  semantics on an architecture which does not natively
/// support such.
class CHERIseedSanitizerPass
    : public llvm::PassInfoMixin<CHERIseedSanitizerPass> {
public:
  PreservedAnalyses run(Module &M, ModuleAnalysisManager &MAM);
};

} // namespace llvm

#endif /* LLVM_TRANSFORMS_INSTRUMENTATION_CHERISEED_H */
