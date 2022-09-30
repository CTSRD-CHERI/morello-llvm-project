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

// Functions required by the runtime library. It is expected that the testing
// libc has no such symbols exported.
extern "C" bool __shim_is_pure_capability() { return false; }

extern "C" bool __shim_supports_cancellation_points() { return false; }

extern "C" void* __shim_syscall(long nr, long arg1, long arg2, long arg3,
                                long arg4, long arg5, long arg6, ...) {
  return reinterpret_cast<void*>(
      syscall(nr, arg1, arg2, arg3, arg4, arg5, arg6));
}

int main(int argc, char** argv) {
  // Calling initializer routine before running tests.
  __cheriseed_static_init(0);
  __cheriseed_relocate(0, 0);

  testing::GTEST_FLAG(death_test_style) = "threadsafe";
  testing::InitGoogleTest(&argc, argv);
  // gtest captures signals, don't try to call those handlers from the runtime
  // because the libc being used for testing is not instrumented and currently
  // CHERIseed doesn't support this feature for hybrid code.
  __cheriseed_control_invoke_signal_handlers(CHERISEED_DISABLE);
  return RUN_ALL_TESTS();
}
