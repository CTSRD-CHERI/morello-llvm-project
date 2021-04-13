//===- Cheri.cpp - Utility functions for handling capabilities-------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "llvm/Support/Cheri.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;

static llvm::cl::opt<bool>
NoCapLibFuncs("cheri-no-cap-libfunc", llvm::cl::init(false), llvm::cl::Hidden);

static llvm::cl::opt<bool>
NoPureCapLibFuncs("cheri-no-pure-cap-libfunc", llvm::cl::init(true),
                llvm::cl::Hidden);

namespace llvm {

bool useCHERICapLibFunc(bool PureCapABI) {
  if (NoCapLibFuncs)
    return false;
  if (PureCapABI && NoPureCapLibFuncs)
    return false;
  return true;
}

} // namespace llvm
