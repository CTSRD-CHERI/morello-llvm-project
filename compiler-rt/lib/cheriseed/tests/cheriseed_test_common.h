//===-- cheriseed_test_utils.h ----------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// This header defines common types and methods shared between tests and
// benchmarks.
//
//===----------------------------------------------------------------------===//

#ifndef CHERISEED_TEST_COMMON_H
#define CHERISEED_TEST_COMMON_H

#if !defined(CHERISEED_UNIT_TESTING)
#include <sanitizer/cheriseed_interface.h>
#else
#include "sanitizer_common/sanitizer_internal_defs.h"
#endif

#if !defined(CHERISEED_UNIT_TESTING)

/// Define __cheriseed_cap_t for testing purposes. It is still opaque, but
/// describes a well-sized and well-aligned type now.
struct __cheriseed_cap_t {
  __cheriseed_cap_t() {}

 protected:
  // Disallow copy
  __cheriseed_cap_t(const __cheriseed_cap_t &) = delete;
  __cheriseed_cap_t &operator=(__cheriseed_cap_t const &) = delete;

  uint8_t bits[16];
} __attribute__((aligned(16)));  // struct __cheriseed_cap_t

namespace utils {

/// Helper to create a capability on stack in the tests.
template <typename T>
static inline void InitCap(__cheriseed_cap_t *cap, T *address) {
  // Set maximum permissions metadata
  __cheriseed_ddc_get(cap);
  // Set value field
  __cheriseed_address_set(cap, cap, reinterpret_cast<uint64_t>(address));
}

/// Helper to create a capability on stack.
static inline void InitCap(__cheriseed_cap_t *cap, uint64_t value,
                           uint64_t metadata) {
  __cheriseed_address_set(cap, cap, value);
  __cheriseed_copy_to_high(cap, cap, metadata);
}

}  // namespace utils

#endif  //  !CHERISEED_UNIT_TESTING

// Symbols required by CHERIseed, but which are not present in testing libc.
extern "C" bool __shim_is_pure_capability(void);
extern "C" bool __shim_supports_cancellation_points(void);
extern "C" void *__shim_syscall(long nr, long arg1, long arg2, long arg3,
                                long arg4, long arg5, long arg6, ...);

#endif  // CHERISEED_TEST_COMMON_H
