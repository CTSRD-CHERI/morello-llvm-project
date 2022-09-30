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

// Forward declare CCL interface.
// This is required so that it can be made a friend and so some methods of
// LocalCap will only be accessible to that.
namespace ccl {
struct methods;
}  // namespace ccl

namespace __cheriseed {

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
struct __cheriseed_cap_t {
  // Note: not all the members are initialized on purpose.
  __cheriseed_cap_t() {}

 protected:
  // Do not allow copy for everyone, except for derived classes
  __cheriseed_cap_t(const __cheriseed_cap_t &) = default;
  __cheriseed_cap_t &operator=(__cheriseed_cap_t const &) = default;

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

/// Shorthand for a capability which may be null.
using AllowNullCap = MaybeNull<const __cheriseed_cap_t *>;

// Possible tag states.
enum TagState : u8 {
  TS_CLEARED = 0,
  TS_TAGGED = 1,
  TS_LOCKED = 2,
};  // enum TagState

// Locks a tag with spinlock and acquire semantics.
//
// Returns the previous tag value.
static inline TagState AcquireTag(TagState *const ptr) {
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
static inline TagState ReleaseTag(TagState *ptr, TagState tag) {
  return __atomic_exchange_n(ptr, tag, __ATOMIC_RELEASE);
}

// Writes a tag with relaxed semantics..
static inline void WriteTag(TagState *ptr, TagState tag) {
  __atomic_store_n(ptr, tag, __ATOMIC_RELAXED);
}

// Reads a tag with relaxed semantics.
static inline TagState ReadTag(TagState *ptr) {
  return __atomic_load_n(ptr, __ATOMIC_RELAXED);
}

/// Class which interacts with the public (opaque) type and creates an
/// in-flight capability, which then can be modified and written to memory.
struct LocalCap : public __cheriseed_cap_t {
  // Note: not all the members are initialized on purpose.
  explicit LocalCap(const Options &Opts) : Opts(Opts) { ClearTag(); }

  // Note: not all the members are initialized on purpose.
  LocalCap(const Options &Opts, u64 value, u64 metadata) : Opts(Opts) {
    SetValue(value);
    SetMetadata(metadata);
    ClearTag();
  }

  // Note: not all the members are initialized on purpose.
  LocalCap(const Options &Opts, const __cheriseed_cap_t *ptr,
           memory_order memory_order = memory_order::memory_order_relaxed)
      : LocalCap(Opts, ptr, memory_order, false) {}

  // Note: not all the members are initialized on purpose.
  LocalCap(const Options &Opts, AllowNullCap maybe_nullptr,
           memory_order memory_order = memory_order::memory_order_relaxed)
      : LocalCap(Opts, maybe_nullptr.value, memory_order, true) {}

  __cheriseed_cap_t *Store(
      __cheriseed_cap_t *ptr,
      memory_order memory_order = memory_order::memory_order_relaxed) const;

  void Store(LocalCap &scoped_cap) const;

  const LocalCap &RequireTagged() const;
  const LocalCap &RequirePermissions(u64 perms) const;
  const LocalCap &RequireBounds(u64 size) const;

  vaddr GetAddress() const { return address; }
  TagState *GetShadowAddress() const {
    return reinterpret_cast<TagState *>(
        Globals::ShadowMap.GetShadowAddressFrom(address));
  }
  u64 GetValue() const { return value; }
  u64 GetMetadata() const { return metadata; }
  bool IsTagged() const { return (tag_state == TagState::TS_TAGGED); }

  const Options &GetOpts() const { return Opts; }

  void ClearTag() { tag_state = TagState::TS_CLEARED; }

#ifndef CHERISEED_UNIT_TESTING
 protected:
#endif
  LocalCap(const Options &Opts, const __cheriseed_cap_t *ptr,
           memory_order memory_order, bool allow_nullcap);

  void Load() {
    const u64 *cap = reinterpret_cast<const u64 *>(GetAddress());
    SetValue(cap[0]);
    SetMetadata(cap[1]);
  }

  void SetAddress(const __cheriseed_cap_t *ptr) {
    address = reinterpret_cast<vaddr>(ptr);
  }

  void SetValue(u64 value) { this->value = value; }
  void SetMetadata(u64 metadata) { this->metadata = metadata; }
  void SetTag() { tag_state = TagState::TS_TAGGED; }

  /// Semantic configuration options for this capability
  const Options &Opts;
  /// The address this capability originates from, if any.
  vaddr address;
  /// The tagged state of this capability.
  TagState tag_state;

  // Allow access to all private methods and members for CCL interface.
  friend struct ccl::methods;
  // Allow access to all private methods and members for ScopeLockedLocalCap.
  friend struct ScopeLockedLocalCap;
};  // struct LocalCap

struct ScopeLockedLocalCap final : public LocalCap {
  ScopeLockedLocalCap(const Options &Opts, const __cheriseed_cap_t *ptr);

  __cheriseed_cap_t *Store(
      __cheriseed_cap_t *ptr,
      memory_order memory_order = memory_order::memory_order_relaxed) const;

  ~ScopeLockedLocalCap() { ReleaseTag(GetShadowAddress(), tag_state); }
};  // struct ScopeLockedLocalCap

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

using __cheriseed::LocalCap;

#endif  // CHERISEED_COMMON_H
