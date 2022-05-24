//===- cheriseed_common.h----------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// This file provides common definitions required across the compiler-rt
//
//===----------------------------------------------------------------------===//

#ifndef CHERISEED_COMMON_H
#define CHERISEED_COMMON_H

#include "cheriseed_abi_defs.h"
#include "sanitizer_common/sanitizer_atomic.h"

using __sanitizer::memory_order;
using __sanitizer::pid_t;
using __sanitizer::u32;
using __sanitizer::u64;
using __sanitizer::u8;
using __sanitizer::usize;
using __sanitizer::vaddr;

namespace __cheriseed {

// The coarse representation of an in-memory capability.
struct __cheriseed_cap_t final {
  u64 value;     // virtual address
  u64 metadata;  // compressed metadata
} __attribute__((aligned(abi::kCapabilityMinAlignment)));

/// Definition of an aggregate returned by cmpxchg APIs.
struct __cheriseed_cmpxchg_result_t {
  __cheriseed_cap_t *cap;
  u8 result;
};  // struct __cheriseed_cmpxchg_result_t

// Atomic boolean
struct AtomicBool final {
  explicit constexpr AtomicBool(const bool value) : val_dont_use(value) {}
  void operator=(bool value) { __sanitizer::atomic_store_relaxed(this, value); }
  operator bool() const { return __sanitizer::atomic_load_relaxed(this); }

  using Type = u8;
  volatile Type val_dont_use;
};  // struct AtomicBool

// Runtime configurable features.
struct Options final {
  // Enables or disables CHERI semantics.
  static AtomicBool EnableCHERISemantics;
  // Enables or disables invocation of signal handlers.
  static AtomicBool EnableSignalHandlers;
};  // struct Options

}  // namespace __cheriseed

#endif
