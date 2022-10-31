//===- cheriseed_local_cap.h-------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// This file contains the definitions of capabilities which only exist within
// the runtime library.
//
//===----------------------------------------------------------------------===//

#ifndef CHERISEED_LOCAL_CAP_H
#define CHERISEED_LOCAL_CAP_H

#include "cheriseed_ccl_interface.h"
#include "cheriseed_common.h"

namespace __cheriseed {

// Forward declarations.
struct LocalCap;

// Shorthand for the CCL adapter.
using LocalCapAdapter = ccl::Adapter<LocalCap>;

/// Shorthand for a capability which may be null.
using AllowNullCap = MaybeNull<const __cheriseed_cap_t *>;

/// Class which interacts with the public (opaque) type and creates an
/// in-flight capability, which then can be modified and written to memory.
struct LocalCap : public DisableCopyAndMoveMixin {
  // Note: not all the members are initialized on purpose.
  ALWAYS_INLINE explicit LocalCap(const Options &Opts) : Opts(Opts) {
    ClearTag();
  }

  // Note: not all the members are initialized on purpose.
  ALWAYS_INLINE LocalCap(const Options &Opts, u64 value, u64 metadata)
      : Opts(Opts) {
    SetValue(value);
    SetMetadata(metadata);
    ClearTag();
  }

  // Note: not all the members are initialized on purpose.
  ALWAYS_INLINE LocalCap(
      const Options &Opts, const __cheriseed_cap_t *ptr,
      memory_order memory_order = memory_order::memory_order_relaxed)
      : LocalCap(Opts, ptr, memory_order, false) {}

  // Note: not all the members are initialized on purpose.
  ALWAYS_INLINE LocalCap(
      const Options &Opts, AllowNullCap maybe_nullptr,
      memory_order memory_order = memory_order::memory_order_relaxed)
      : LocalCap(Opts, maybe_nullptr.value, memory_order, true) {}

  ALWAYS_INLINE __cheriseed_cap_t *Store(
      __cheriseed_cap_t *ptr,
      memory_order memory_order = memory_order::memory_order_relaxed) const {
    LocalCap local_cap{GetOpts()};
    local_cap.SetAddress(ptr);
    local_cap.RequireValidAddress().RequireAligned();
    AcquireTag(local_cap.GetShadowAddress());
    Store(local_cap);
    ReleaseTag(local_cap.GetShadowAddress(), tag_state);
    return ptr;
  }

  ALWAYS_INLINE void Store(LocalCap &local_cap) const {
    u64 *cap = reinterpret_cast<u64 *>(local_cap.GetAddress());
    cap[0] = GetValue();
    cap[1] = GetMetadata();
    local_cap.tag_state = tag_state;
  }

  // ----------------------------------------------------------------
  // Member functions to ensure that certain properties hold.
  // ----------------------------------------------------------------

  ALWAYS_INLINE const LocalCap &RequireValidAddress() const {
    const vaddr cap_addr = GetAddress();
    bool failed = (cap_addr == 0);
#if defined(__aarch64__)
    failed |= (cap_addr & (static_cast<vaddr>(1) << 55)) != 0;
#endif
#if defined(SANITIZER_LINUX)
    // Check for address on the first page, which is never accessible.
    failed |= cap_addr < Globals::SystemPageSize;
#endif
    if (UNLIKELY(failed))
      AddressViolation();
    return *this;
  }

  ALWAYS_INLINE const LocalCap &RequireAligned() const {
    if (LIKELY(Opts.shouldCheckAlignment()))
      if (UNLIKELY((GetAddress() % abi::kCapabilityMinAlignment) != 0))
        AlignmentViolation();
    return *this;
  }

  ALWAYS_INLINE const LocalCap &RequireTagged() const {
    if (LIKELY(Opts.shouldCheckTag()))
      if (UNLIKELY(!IsTagged()))
        NotTaggedViolation();
    return *this;
  }

  ALWAYS_INLINE const LocalCap &RequirePermissions(u64 permissions) const {
    const u64 mask = Opts.getCheckedPerms();
    if (UNLIKELY(!HasPermissions(permissions & mask)))
      PermissionViolation(permissions);
    return *this;
  }

  ALWAYS_INLINE const LocalCap &RequireBounds(u64 size) const {
    if (LIKELY(Opts.shouldCheckBounds()))
      // Top (base + length) is not inclusive in acceptable range of a
      // capability. Since size is taken as-is base <= cursor <= top is correct.
      if (UNLIKELY((GetBase() > GetValue()) ||
                   ((GetValue() + size) > GetTop())))
        BoundsViolation(size);
    return *this;
  }

  // ----------------------------------------------------------------
  // Constant getters
  // ----------------------------------------------------------------

  u64 GetValue() const { return value; }

  u64 GetMetadata() const { return metadata; }

  vaddr GetAddress() const { return address; }

  bool IsTagged() const { return (tag_state == TagState::TS_TAGGED); }

  const Options &GetOpts() const { return Opts; }

  ALWAYS_INLINE TagState *GetShadowAddress() const {
    return reinterpret_cast<TagState *>(
        Globals::ShadowMap.GetShadowAddressFrom(address));
  }

  // ----------------------------------------------------------------
  // Getters which use CCL Adapter, possibly modifing the capability.
  // ----------------------------------------------------------------

  ALWAYS_INLINE vaddr GetBase() const {
    return LocalCapAdapter::GetBase(*this);
  }

  ALWAYS_INLINE vaddr GetTop() const { return LocalCapAdapter::GetTop(*this); }

  ALWAYS_INLINE vaddr GetLength() const {
    return LocalCapAdapter::GetLength(*this);
  }

  ALWAYS_INLINE vaddr GetOffset() const {
    return LocalCapAdapter::GetOffset(*this);
  }

  ALWAYS_INLINE u64 GetPermissions() const {
    return LocalCapAdapter::GetPermissions(*this);
  }

  ALWAYS_INLINE u64 GetType() const { return LocalCapAdapter::GetType(*this); };

  ALWAYS_INLINE bool IsSealed() const {
    return LocalCapAdapter::IsSealed(*this);
  }

  ALWAYS_INLINE bool HasPermissions(u64 permissions) const {
    return ((GetPermissions() & permissions) == permissions);
  }

  // ----------------------------------------------------------------
  // Setters which don't use the CCL Adapter.
  // ----------------------------------------------------------------

  void ClearTag() { tag_state = TagState::TS_CLEARED; }

  // ----------------------------------------------------------------
  // Setters which use CCL Adapter, possibly modifing the capability.
  // ----------------------------------------------------------------

  ALWAYS_INLINE void TrySetValue(u64 value) {
    LocalCapAdapter::SetValue(*this, value);
  }

  ALWAYS_INLINE bool TrySetBounds(u64 base, u64 top, bool needs_exact) {
    return LocalCapAdapter::SetBounds(*this, base, top, needs_exact);
  }

  ALWAYS_INLINE void ReducePermissions(u64 permissions) {
    LocalCapAdapter::ReducePermissions(*this, permissions);
  }

#ifndef CHERISEED_UNIT_TESTING
 protected:
#endif

  ALWAYS_INLINE LocalCap(const Options &Opts, const __cheriseed_cap_t *ptr,
                         memory_order memory_order, bool allow_nullcap)
      : Opts(Opts) {
    if (UNLIKELY(allow_nullcap && !ptr)) {
      // The null capability has a value of 0, and 0 metadata by definition.
      SetValue(0);
      SetMetadata(0);
      ClearTag();
      return;
    }

    SetAddress(ptr);
    RequireValidAddress();
    RequireAligned();
    tag_state = AcquireTag(GetShadowAddress());
    Load();
    ReleaseTag(GetShadowAddress(), tag_state);
  }

  ALWAYS_INLINE void Load() {
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

  // Handlers of different capability violations.
  void AddressViolation() const;
  void AlignmentViolation() const;
  void NotTaggedViolation() const;
  void PermissionViolation(u64 permissions) const;
  void BoundsViolation(u64 size) const;

  /// Value of the capability.
  u64 value;
  /// Compressed metadata of the capability.
  u64 metadata;
  /// Semantic configuration options for this capability
  const Options &Opts;
  /// The address this capability originates from, if any.
  vaddr address;
  /// The tagged state of this capability.
  TagState tag_state;

  // Allow access to all non-public methods and members.
  friend LocalCapAdapter;
  friend struct ScopeLockedLocalCap;
} ALIGNED(abi::kCapabilityMinAlignment);  // struct LocalCap

struct ScopeLockedLocalCap final : public LocalCap {
  ALWAYS_INLINE ScopeLockedLocalCap(const Options &Opts,
                                    const __cheriseed_cap_t *ptr)
      : LocalCap(Opts) {
    SetAddress(ptr);
    RequireValidAddress();
    RequireAligned();
    tag_state = AcquireTag(GetShadowAddress());
    Load();
  }

  ALWAYS_INLINE __cheriseed_cap_t *Store(
      __cheriseed_cap_t *ptr, bool store_untagged,
      memory_order memory_order = memory_order::memory_order_relaxed) const {
    LocalCap local_cap{GetOpts()};
    local_cap.SetAddress(ptr);
    local_cap.RequireValidAddress().RequireAligned();
    LocalCap::Store(local_cap);
    WriteTag(local_cap.GetShadowAddress(),
             UNLIKELY(store_untagged) ? TagState::TS_CLEARED : tag_state);
    return ptr;
  }

  ALWAYS_INLINE ~ScopeLockedLocalCap() {
    ReleaseTag(GetShadowAddress(), tag_state);
  }
};  // struct ScopeLockedLocalCap

}  // namespace __cheriseed

#endif  // CHERISEED_LOCAL_CAP_H
