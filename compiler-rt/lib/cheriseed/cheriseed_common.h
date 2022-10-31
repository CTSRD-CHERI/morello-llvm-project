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
#include "cheriseed_shadow_memory.h"
#include "sanitizer_common/sanitizer_atomic.h"

using __sanitizer::atomic_uint64_t;
using __sanitizer::atomic_uint8_t;
using __sanitizer::memory_order;
using __sanitizer::pid_t;
using __sanitizer::ssize;
using __sanitizer::u32;
using __sanitizer::u64;
using __sanitizer::u8;
using __sanitizer::usize;
using __sanitizer::vaddr;

namespace __cheriseed {

/// This mixin class disables copy and move constructors and assignment
/// operators.
struct DisableCopyAndMoveMixin {
  DisableCopyAndMoveMixin() {}

 private:
  DisableCopyAndMoveMixin(DisableCopyAndMoveMixin const &) = delete;
  DisableCopyAndMoveMixin &operator=(DisableCopyAndMoveMixin const &) = delete;
  DisableCopyAndMoveMixin(DisableCopyAndMoveMixin &&) = delete;
  DisableCopyAndMoveMixin &operator=(DisableCopyAndMoveMixin &&) = delete;
};  // class DisableCopyAndMoveMixin

struct __attribute__((visibility("hidden"))) Globals {
  // The size of a page in the system.
  static usize SystemPageSize;
  // CHERIseed shadow map info. Used to get shadow address of a virtual address.
  static ShadowMemory ShadowMap;
  // Prevents infinite looping on some errors.
  static __sanitizer::atomic_uint32_t IsTerminating;
};  // struct Globals

struct __attribute__((visibility("hidden"))) Options {
  // Determine if the current config requires invocation of signal handlers
  bool shouldInvokeSignalHandlers() const {
    if (LIKELY(currentEnableCHERISemantics))
      return (currentEnableSignalHandlers != 0);
    return false;
  }

  // Determine if the current config requires tag checks.
  bool shouldCheckTag() const {
    if (LIKELY(currentEnableCHERISemantics))
      return ((currentChecks & abi::Check::CHK_TAG) != 0);
    return false;
  }

  // Determine if the current config requires bounds checks.
  bool shouldCheckBounds() const {
    if (LIKELY(currentEnableCHERISemantics))
      return ((currentChecks & abi::Check::CHK_BOUNDS) != 0);
    return false;
  }

  // Determine if the current config requires alignment checks.
  bool shouldCheckAlignment() const {
    if (LIKELY(currentEnableCHERISemantics))
      return ((currentChecks & abi::Check::CHK_ALIGNMENT) != 0);
    return false;
  }

  // Returns the current config for required permission checks.
  u64 getCheckedPerms() const {
    if (LIKELY(currentEnableCHERISemantics))
      return currentChecks & abi::Check::CHK_PERMS;
    return 0;
  }

  // Enables or disables CHERI semantics.
  static atomic_uint8_t EnableCHERISemantics;
  // Enables or disables invocation of signal handlers.
  static atomic_uint8_t EnableSignalHandlers;
  // Enables or disables certain checks.
  static atomic_uint64_t Checks;
  // Records if a check was changed runtime.
  // A changed one always overrides the check request from compile-time.
  static atomic_uint64_t DefaultChecks;

 protected:
  constexpr Options()
      : currentEnableCHERISemantics(0),
        currentEnableSignalHandlers(0),
        currentChecks(0),
        defaultChecks(0) {}

  // Current setting for CHERI semantics.
  u8 currentEnableCHERISemantics;
  // Current setting for invocation of signal handlers.
  u8 currentEnableSignalHandlers;
  // Current setting for checks.
  u64 currentChecks;
  // Checks which were not modified runtime.
  u64 defaultChecks;
};  // struct Options

// All runtime configurable features are always off.
struct NoOptionsEnabled : public Options {
  constexpr NoOptionsEnabled() : Options() {}
};  // struct NoOptionsEnabled

// All runtime configurable features are always on.
struct AllOptionsEnabled : public Options {
  constexpr AllOptionsEnabled() {
    currentEnableCHERISemantics = 1;
    currentEnableSignalHandlers = 1;
    currentChecks = abi::Check::CHK_ALL;
    defaultChecks = abi::Check::CHK_ALL;
  }
};  // struct AllOptionsEnabled

// Runtime configurable features.
struct SnapshotOptions : public Options {
  SnapshotOptions() {
    currentEnableCHERISemantics = atomic_load_relaxed(&EnableCHERISemantics);
    currentEnableSignalHandlers = atomic_load_relaxed(&EnableSignalHandlers);
    currentChecks = atomic_load(&Checks, memory_order::memory_order_relaxed);
  }

  SnapshotOptions(u64 masked_checks) : SnapshotOptions() {
    // A masked check 'C' only takes precedence if it was not modified.
    // Masked? | Default? | Really masked?
    //    0    |    1     |    0
    //    1    |    1     |    1
    //    0    |    0     |    0
    //    1    |    0     |    0
    defaultChecks =
        atomic_load(&DefaultChecks, memory_order::memory_order_relaxed);
    currentChecks &= ~(masked_checks & defaultChecks);
  }
};  // struct SnapshotOptions

// The coarse internal representation of an in-memory capability.
struct __cheriseed_cap_t final : public DisableCopyAndMoveMixin {
  // Note: not all the members are initialized on purpose.
  __cheriseed_cap_t() {}

 protected:
  u64 value;     // virtual address
  u64 metadata;  // compressed metadata
} ALIGNED(abi::kCapabilityMinAlignment);

/// Definition of an aggregate returned by cmpxchg APIs.
struct __cheriseed_cmpxchg_result_t {
  __cheriseed_cap_t *cap;
  u8 result;
};  // struct __cheriseed_cmpxchg_result_t

/// Internal representation of '__cheriseed_initializers' section tuples.
struct __cheriseed_initializer_t {
  // Pointer to a capability.
  __cheriseed_cap_t *cap;
  // Address to set for the capability.
  u64 address;
  // The size of the object pointed to by the capability.
  u64 size;
  // Permissions to be cleared.
  u32 clear_perms;
  // Function which performs global initialization.
  void (*init)();
};  // struct __cheriseed_initializer_t

/// Newtype to wrap pointers which may be nullptr.
template <typename T>
struct MaybeNull {
  MaybeNull(T value) : value(value) {}
  T value;
};  // struct MaybeNull

// Possible tag states.
enum TagState : u8 {
  TS_CLEARED = 0,
  TS_TAGGED = 1,
  TS_LOCKED = 2,
};  // enum TagState

// Locks a tag with spinlock and acquire semantics.
//
// Returns the previous tag value.
static ALWAYS_INLINE TagState AcquireTag(TagState *const ptr) {
  for (;;) {
    TagState prev_tag =
        __atomic_exchange_n(ptr, TagState::TS_LOCKED, __ATOMIC_ACQUIRE);
    if (LIKELY(prev_tag != TagState::TS_LOCKED))
      return prev_tag;
  }
}

// Writes a tag with release semantics.
//
// Returns the previous tag value.
static ALWAYS_INLINE TagState ReleaseTag(TagState *ptr, TagState tag) {
  return __atomic_exchange_n(ptr, tag, __ATOMIC_RELEASE);
}

// Writes a tag with relaxed semantics..
static ALWAYS_INLINE void WriteTag(TagState *ptr, TagState tag) {
  __atomic_store_n(ptr, tag, __ATOMIC_RELAXED);
}

// Reads a tag with relaxed semantics.
static ALWAYS_INLINE TagState ReadTag(TagState *ptr) {
  return __atomic_load_n(ptr, __ATOMIC_RELAXED);
}

// Helper class to search for environment variables.
struct Environment {
  // Type for an environment variable.
  using EnvPtr = const char *;

  // Creates an Environment instance using a stack pointer.
  static Environment From(u64 sp);

  // Finds an environment variable by name.
  EnvPtr GetEnv(const char *name) const;

  // Finds an auxiliary value.
  // It is up to the user to interpret the returned value.
  u64 GetAuxv(u64 type) const;

 protected:
  // Type for the environment variable array.
  using EnvArray = const char *const *;
  // Type for the auxiliary values array.
  using AuxvArray = const u64 *;

  // Protected constructor to instantiate an Environment.
  explicit constexpr Environment(EnvArray envp, AuxvArray auxv)
      : envp_start(envp), auxv_start(auxv) {}

  // Pointer to the start of the envrionment variables.
  const EnvArray envp_start;
  // Pointer to the start of the auxiliary values.
  const AuxvArray auxv_start;
};  // struct Environment

// A dynamic way to control checks using CHERISEED_CHECKS environment variable.
void ControlChecksDynamic(const Environment &env);

}  // namespace __cheriseed

#endif  // CHERISEED_COMMON_H
