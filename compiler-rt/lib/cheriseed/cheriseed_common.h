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

#define CHERISEED_CHECK_PERMS ((1UL << 32) - 1)
#define CHERISEED_CHECK_TAG (1UL << 61)
#define CHERISEED_CHECK_BOUNDS (1UL << 62)
#define CHERISEED_CHECK_ALIGNMENT (1UL << 63)

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
using u128 = unsigned __int128;

// Forward declare CCL interface.
// This is required so that it can be made a friend and so some methods of
// LocalCap will only be accessible to that.
namespace ccl {
struct methods;
}  // namespace ccl

namespace __cheriseed {

// Runtime configurable features.
class Options {
 public:
  Options() {
    currentEnableCHERISemantics = atomic_load_relaxed(&EnableCHERISemantics);
    currentEnableSignalHandlers = atomic_load_relaxed(&EnableSignalHandlers);
    currentChecks = atomic_load(&Checks, memory_order::memory_order_acquire);
  }

  // Determine if the current config requires invocation of signal handlers
  bool shouldInvokeSignalHandlers() const {
    if (LIKELY(currentEnableCHERISemantics))
      return (currentEnableSignalHandlers != 0);
    return false;
  }

  // Determine if the current config requires tag checks.
  bool shouldCheckTag() const {
    if (LIKELY(currentEnableCHERISemantics))
      return ((currentChecks & CHERISEED_CHECK_TAG) != 0);
    return false;
  }

  // Determine if the current config requires bounds checks.
  bool shouldCheckBounds() const {
    if (LIKELY(currentEnableCHERISemantics))
      return ((currentChecks & CHERISEED_CHECK_BOUNDS) != 0);
    return false;
  }

  // Determine if the current config requires alignment checks.
  bool shouldCheckAlignment() const {
    if (LIKELY(currentEnableCHERISemantics))
      return ((currentChecks & CHERISEED_CHECK_ALIGNMENT) != 0);
    return false;
  }

  // Determine if the current config requires permission checks.
  u64 shouldCheckPerms() const {
    if (LIKELY(currentEnableCHERISemantics))
      return currentChecks & CHERISEED_CHECK_PERMS;
    return 0;
  }

  // Enables or disables CHERI semantics.
  static atomic_uint8_t EnableCHERISemantics;
  // Enables or disables invocation of signal handlers.
  static atomic_uint8_t EnableSignalHandlers;
  // Enables or disables certain checks.
  static atomic_uint64_t Checks;

  // May be useful to access in unit tests
#ifdef CHERISEED_UNIT_TESTING
  u64 GetCurrentChecks() const { return currentChecks; }
#endif

 protected:
  // Current setting for CHERI semantics.
  u8 currentEnableCHERISemantics;
  // Current setting for invocation of signal handlers.
  u8 currentEnableSignalHandlers;
  // Current setting for checks.
  u64 currentChecks;
};  // struct Options

struct DefaultOptions : public Options {
  DefaultOptions() {
    currentEnableCHERISemantics = 1;
    currentEnableSignalHandlers = 1;
    currentChecks = UINT64_MAX;
  }
};

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
};  // enum TagState

/// Class which interacts with the public (opaque) type and creates an
/// in-flight capability, which then can be modified and written to memory.
struct LocalCap final : public __cheriseed_cap_t {
  // Note: not all the members are initialized on purpose.
  explicit LocalCap(Options &Opts) : Opts(Opts) { ClearTag(); }

  // Note: not all the members are initialized on purpose.
  LocalCap(Options &Opts, u64 value, u64 metadata) : Opts(Opts) {
    SetValue(value);
    SetMetadata(metadata);
    ClearTag();
  }

  // Note: not all the members are initialized on purpose.
  LocalCap(Options &Opts, const __cheriseed_cap_t *ptr,
           memory_order memory_order = memory_order::memory_order_relaxed)
      : LocalCap(Opts, ptr, memory_order, false) {}

  // Note: not all the members are initialized on purpose.
  LocalCap(Options &Opts, AllowNullCap maybe_nullptr,
           memory_order memory_order = memory_order::memory_order_relaxed)
      : LocalCap(Opts, maybe_nullptr.value, memory_order, true) {}

  __cheriseed_cap_t *Store(
      __cheriseed_cap_t *ptr,
      memory_order memory_order = memory_order::memory_order_relaxed) const;

  const LocalCap &RequireTagged() const;
  const LocalCap &RequirePermissions(u64 perms) const;
  const LocalCap &RequireBounds(u64 size) const;

  vaddr GetAddress() const { return address; }
  u64 GetValue() const { return value; }
  u64 GetMetadata() const { return metadata; }
  bool IsTagged() const { return (tag_state == TagState::TS_TAGGED); }

  Options &GetOpts() const { return Opts; }

  void ClearTag() { tag_state = TagState::TS_CLEARED; }

#ifndef CHERISEED_UNIT_TESTING
 private:
#endif
  LocalCap(Options &Opts, const __cheriseed_cap_t *ptr,
           memory_order memory_order, bool allow_nullcap);

  void SetAddress(const __cheriseed_cap_t *ptr) {
    address = reinterpret_cast<vaddr>(ptr);
  }

  void SetValue(u64 value) { this->value = value; }
  void SetMetadata(u64 metadata) { this->metadata = metadata; }
  void SetTag() { tag_state = TagState::TS_TAGGED; }

  /// Semantic configuration options for this capability
  Options &Opts;

  /// The address this capability originates from, if any.
  vaddr address;
  /// The tagged state of this capability.
  TagState tag_state;

  // Allow access to all private methods and members for CCL interface.
  friend struct ccl::methods;
};  // struct LocalCap

// Helper class to search for environment variables.
struct Environment {
  // Type for an environment variable.
  using EnvPtr = const char *;

  // Creates an Environment instance using a stack pointer.
  static Environment From(u64 sp);

  // Finds an environment variable by name.
  EnvPtr GetEnv(const char *Name) const;

 protected:
  // Type for the environment variable array.
  using EnvArray = const char *const *;

  // Protected constructor to instantiate an Environment.
  explicit constexpr Environment(EnvArray envp) : envp_start(envp) {}

  // Pointer to the start of the envrionment variables.
  const EnvArray envp_start;
};  // struct Environment

// A dynamic way to control checks using CHERISEED_CHECKS environment variable.
void ControlChecksDynamic(const Environment &env);

}  // namespace __cheriseed

using __cheriseed::LocalCap;

#endif  // CHERISEED_COMMON_H
