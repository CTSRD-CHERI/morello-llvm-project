//===- cheriseed_abi_defs.h -------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// This file defines constants required in the compiler_rt to ensure consistency
// with the Transform pass. If they are modified the changes should be mirrored
// in CHERIseed.cpp.
//===----------------------------------------------------------------------===//

#ifndef CHERISEED_ABI_DEFS_H
#define CHERISEED_ABI_DEFS_H

#include "sanitizer_common/sanitizer_atomic.h"

using __sanitizer::u32;
using __sanitizer::u64;
using __sanitizer::u8;

namespace __cheriseed {
namespace abi {

// Minimum expected alignment of a capability.
static constexpr u8 kCapabilityMinAlignment = 16;

// These permissions bits are used as the arguments for the function
// __cheriseed_check_access as a platform independent representation.
enum permissions : int {
  LOAD = (1 << 0),
  STORE = (1 << 1),
  EXECUTE = (1 << 2)
};

}  // namespace abi

// Possible reasons of a capability violation.
enum SignalCode : int {
  // Attempted to dereference an untagged capability.
  SC_SEGV_CAPTAGERR = 1000,
  // Attempted an out-of-bounds access.
  SC_SEGV_CAPBOUNDSERR = 1001,
  // Attempted an access without the required permissions.
  SC_SEGV_CAPPERMERR = 1002,
  // Extension: address of a capability is likely invalid.
  SC_SEGV_MAPERR = 1,
  // Extension: alignment of a capability is invalid.
  SC_BUS_ADRALN = 1,
  // Extension: something is not implemented, this is not user-visible.
  SC_PROT_NOT_IMPLEMENTED = 9999,
};  // enum SignalCode

// Possible ways to handle a capability violation signal.
enum SignalHandleMode : int {
  // The violation is fatal and the reason is printed to stderr.
  SHM_DEFAULT = 1,
  // The violation is fatal, no details is printed to stderr.
  SHM_SILENT = 2,
  // Ignore the violation.
  SHM_IGNORE = 3,
  // The violation is not fatal, but print the reason to stderr.
  SHM_WARNING = 4,
};  // enum SignalHandleMode

// The coarse representation of an in-memory capability.
struct __cheriseed_cap_t final {
  u64 value;     // virtual address
  u64 metadata;  // compressed metadata
} __attribute__((aligned(abi::kCapabilityMinAlignment)));

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
