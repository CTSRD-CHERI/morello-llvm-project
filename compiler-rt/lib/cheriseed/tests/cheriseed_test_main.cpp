//===-- cheriseed_test_main.cpp ---------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// Main for all CHERIseed unit tests.
//
//===----------------------------------------------------------------------===//

#include "cheriseed_test_utils.h"

int main(int argc, char **argv) {
  testing::GTEST_FLAG(death_test_style) = "threadsafe";
  testing::InitGoogleTest(&argc, argv);
  // gtest captures signals, don't try to call those handlers from the runtime
  // because the libc being used for testing is not instrumented and currently
  // CHERIseed doesn't support this feature for hybrid code.
  __cheriseed_enable_invoke_signal_handlers(0);
  // Temporary workaround: semantics are disabled by default.
  __cheriseed_enable_cheri_semantics(1);
  return RUN_ALL_TESTS();
}
