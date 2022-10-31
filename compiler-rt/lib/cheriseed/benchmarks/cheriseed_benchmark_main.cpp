//===-- cheriseed_api.cpp ---------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// Main of CHERIseed benchmarks.
//
//===----------------------------------------------------------------------===//

#define CHERISEED_BENCHMARKING

#include <unistd.h>

#include "benchmark/benchmark.h"
#include "cheriseed_test_common.h"

extern "C" bool __shim_is_pure_capability() { return false; }

extern "C" bool __shim_supports_cancellation_points() { return false; }

extern "C" void* __shim_syscall(long nr, long arg1, long arg2, long arg3,
                                long arg4, long arg5, long arg6, ...) {
  return reinterpret_cast<void*>(
      syscall(nr, arg1, arg2, arg3, arg4, arg5, arg6));
}

__attribute__((constructor)) void InitializeCHERIseedRuntime() {
  __cheriseed_static_init(0);
  __cheriseed_relocate(0, 0);
}

BENCHMARK_MAIN();
