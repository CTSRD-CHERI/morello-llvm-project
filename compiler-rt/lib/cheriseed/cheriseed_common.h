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
using u128 = unsigned __int128;

// Forward declare CCL interface.
// This is required so that it can be made a friend and so some methods of
// LocalCap will only be accessible to that.
namespace ccl {
struct methods;
}  // namespace ccl

namespace __cheriseed {

// The coarse internal representation of an in-memory capability.
struct __cheriseed_cap_t {
  // Note: not all the members are initialized on purpose.
  __cheriseed_cap_t() {}

 protected:
  // Do not allow copy for everyone, except for derived classes.
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

/// Newtype to wrap pointers which may be nullptr.
template <typename T>
struct MaybeNull {
  MaybeNull(T value) : value(value) {}
  T value;
};  // struct MaybeNull

/// Shorthand for a capability which may be null.
using AllowNullCap = MaybeNull<const __cheriseed_cap_t *>;

/// Class which interacts with the public (opaque) type and creates an
/// in-flight capability, which then can be modified and written to memory.
struct LocalCap final : public __cheriseed_cap_t {
  // Note: not all the members are initialized on purpose.
  LocalCap() {}

  // Note: not all the members are initialized on purpose.
  LocalCap(u64 value, u64 metadata) {
    SetValue(value);
    SetMetadata(metadata);
  }

  LocalCap(const __cheriseed_cap_t *ptr,
           memory_order memory_order = memory_order::memory_order_relaxed)
      : LocalCap(ptr, memory_order, false) {}

  LocalCap(AllowNullCap maybe_nullptr,
           memory_order memory_order = memory_order::memory_order_relaxed)
      : LocalCap(maybe_nullptr.value, memory_order, true) {}

  __cheriseed_cap_t *Store(
      __cheriseed_cap_t *ptr,
      memory_order memory_order = memory_order::memory_order_relaxed) const;

  const LocalCap &RequirePermissions(u64 perms) const;
  const LocalCap &RequireBounds(u64 size) const;

  vaddr GetAddress() const { return address; }
  u64 GetValue() const { return value; }
  u64 GetMetadata() const { return metadata; }

#ifndef CHERISEED_UNIT_TESTING
 private:
#endif
  LocalCap(const __cheriseed_cap_t *ptr, memory_order memory_order,
           bool allow_nullcap);

  void SetAddress(const __cheriseed_cap_t *ptr) {
    address = reinterpret_cast<vaddr>(ptr);
  }

  void SetValue(u64 value) { this->value = value; }
  void SetMetadata(u64 metadata) { this->metadata = metadata; }

  /// The address this capability originates from, if any.
  vaddr address;

  // Allow access to all private methods and members for CCL interface.
  friend struct ccl::methods;
};  // struct LocalCap

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

using __cheriseed::LocalCap;

#endif  // CHERISEED_COMMON_H
