//===-- cheriseed.cpp ------------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of CHERIseed Runtime Library.
//
// This file contains implementation of the interface. Implementations should
// not call any capability compression functions directly in the ccl::external
// namespace, but rather use the interface functions in the ccl namespace,
// to maintain a separation from the CCL library.
//
//===----------------------------------------------------------------------===//

#include "cheriseed_errors.h"
#include "cheriseed_interface_internal.h"
#include "cheriseed_shadow_memory.h"

using namespace __cheriseed;
using namespace __cheriseed::abi;
using namespace __cheriseed::error;

namespace __cheriseed {

atomic_uint8_t Options::EnableCHERISemantics{1};
atomic_uint8_t Options::EnableSignalHandlers{1};
atomic_uint64_t Options::Checks{UINT64_MAX};

// This is the default value and AT_PAGESZ can override it.
usize SystemPageSize = 4096;

// Triggers an unimplemented fault.
#undef UNIMPLEMENTED
#define UNIMPLEMENTED()                                             \
  {                                                                 \
    const NoOptionsEnabled Opts;                                    \
    CheckContext(LocalCap(Opts)).add(NotImplemented(__FUNCTION__)); \
    __sanitizer::Die();                                             \
  }

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

LocalCap::LocalCap(const Options &Opts, const __cheriseed_cap_t *ptr,
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
  CheckContext(*this).add(CapabilityAddress()).add(CapabilityAlignment());
  tag_state = AcquireTag(GetShadowAddress());
  const u64 *cap = reinterpret_cast<const u64 *>(ptr);
  SetValue(cap[0]);
  SetMetadata(cap[1]);
  ReleaseTag(GetShadowAddress(), tag_state);
}

__cheriseed_cap_t *LocalCap::Store(__cheriseed_cap_t *ptr,
                                   memory_order memory_order) const {
  LocalCap local_cap(GetOpts());
  local_cap.SetAddress(ptr);
  CheckContext(local_cap).add(CapabilityAddress()).add(CapabilityAlignment());
  AcquireTag(local_cap.GetShadowAddress());
  u64 *cap = reinterpret_cast<u64 *>(ptr);
  cap[0] = GetValue();
  cap[1] = GetMetadata();
  ReleaseTag(local_cap.GetShadowAddress(), tag_state);
  return ptr;
}

const LocalCap &LocalCap::RequireTagged() const {
  CheckContext(*this).add(Tagged());
  return *this;
}

const LocalCap &LocalCap::RequirePermissions(u64 perms) const {
  CheckContext(*this).add(RequiredPerms(perms));
  return *this;
}

const LocalCap &LocalCap::RequireBounds(u64 size) const {
  CheckContext(*this).add(InBounds(size));
  return *this;
}

// Sets a permissions bit in the ccl representation if the corresponding bit is
// set in the check_access permission mask.
static u64 CheckPermsToCCL(u32 in_perms) {
#define BIT_CONVERTER(__perm) \
  (in_perms & Permissions::__perm) ? ccl::permissions::__perm : 0

  u32 out_perms = 0;
  out_perms |= BIT_CONVERTER(LOAD);
  out_perms |= BIT_CONVERTER(STORE);
  out_perms |= BIT_CONVERTER(EXECUTE);
  out_perms |= BIT_CONVERTER(LOAD_CAP);
  out_perms |= BIT_CONVERTER(STORE_CAP);
  return out_perms;

#undef BIT_CONVERTER
}

static memory_order IRToCppOrdering(u8 ordering) {
  // Detect if the common header is changed.
  static_assert((1 << 0) == memory_order::memory_order_relaxed,
                "Unexpected value for relaxed ordering");
  static_assert((1 << 1) == memory_order::memory_order_consume,
                "Unexpected value for consume ordering");
  static_assert((1 << 2) == memory_order::memory_order_acquire,
                "Unexpected value for acquire ordering");
  static_assert((1 << 3) == memory_order::memory_order_release,
                "Unexpected value for release ordering");
  static_assert((1 << 4) == memory_order::memory_order_acq_rel,
                "Unexpected value for acq_rel ordering");
  static_assert((1 << 5) == memory_order::memory_order_seq_cst,
                "Unexpected value for seq_cst ordering");

  // We trust in the compiler to generate proper ordering values.
  return static_cast<memory_order>(1 << ordering);
}

Environment Environment::From(u64 sp) {
  // As per ABI sp points to argc.
  const u64 *ptr = reinterpret_cast<const u64 *>(sp);
  // In case sp was 0.
  if (ptr == 0)
    return Environment(nullptr, nullptr);

  // Skip 'argc'.
  ++ptr;
  // Skip 'argv' entries and the terminating NULL.
  while (*ptr++)
    ;
  // Now 'ptr' points to the first environment variable.
  EnvArray envp = reinterpret_cast<EnvArray>(ptr);

  // Skip 'envp' entries and the terminating NULL.
  while (*ptr++)
    ;
  // Now 'ptr' points to the first auxiliary value.
  AuxvArray auxv = reinterpret_cast<AuxvArray>(ptr);

  return Environment(envp, auxv);
}

Environment::EnvPtr Environment::GetEnv(const char *name) const {
  if (!envp_start || !name)
    return nullptr;

  const usize name_length = __sanitizer::internal_strlen(name);
  if (name_length == 0)
    return nullptr;

  EnvArray envp = envp_start;
  while (*envp) {
    const usize len =
        __sanitizer::Min(__sanitizer::internal_strlen(*envp), name_length);
    const int match = __sanitizer::internal_strncmp(*envp, name, len);
    if (0 == match && ('=' == (*envp)[name_length]))
      return *envp;
    ++envp;
  }

  return nullptr;
}

u64 Environment::GetAuxv(u64 type) const {
  if (!auxv_start)
    return 0;

  AuxvArray auxv = auxv_start;
  while (0 != auxv[0]) {
    if (auxv[0] == type)
      return auxv[1];
    auxv += 2;
  }

  return 0;
}

void ControlChecksDynamic(const Environment &env) {
  // Try to find CHERISEED_CHECKS environment variable.
  Environment::EnvPtr cheriseed_checks_start =
      env.GetEnv(kDynamicConfigurationEnv);
  if (!cheriseed_checks_start)
    return;

  // Skip CHERISEED_CHECKS and the '=' character.
  const char *cheriseed_checks =
      cheriseed_checks_start + sizeof(kDynamicConfigurationEnv);
  // Process the comma separated list of options.
  while (*cheriseed_checks) {
    const char *const option_start = cheriseed_checks;
    // A starting '-' marks if an option is negated.
    enum Control enabled_state = Control::CTRL_ENABLE;
    if ('-' == *cheriseed_checks) {
      enabled_state = Control::CTRL_DISABLE;
      // Skip the '-' character.
      ++cheriseed_checks;
    }

    // Find the position of the next delimiter character.
    const char *delimiter =
        __sanitizer::internal_strchrnul(cheriseed_checks, ',');
    // Calculate the length of this option.
    const usize option_length =
        static_cast<usize>(delimiter - cheriseed_checks);
    // Grab the current option.
    const char *const option = cheriseed_checks;
    // Don't process zero-length options.
    if (0 == option_length) {
      const NoOptionsEnabled Opts;
      CheckContext(LocalCap(Opts))
          .add(DynamicControlError(cheriseed_checks_start, option_start));
      break;
    }
    // Advance pointer: if there is a delimiter, skip the delimiter itself.
    cheriseed_checks = *delimiter ? ++delimiter : delimiter;

// Helper macros to make the code a bit more readable.
#define OPTION(__name) \
  (0 == __sanitizer::internal_strncmp(__name, option, option_length))

#define CONTROL_CHECK(__check) \
  __cheriseed_control_checks(enabled_state, __check);

    if OPTION ("ALL") {
      CONTROL_CHECK(Check::CHK_ALL);
    } else if OPTION ("TAG") {
      CONTROL_CHECK(Check::CHK_TAG);
    } else if OPTION ("BOUNDS") {
      CONTROL_CHECK(Check::CHK_BOUNDS);
    } else if OPTION ("PERMS") {
      CONTROL_CHECK(Check::CHK_PERMS);
    } else if OPTION ("ALIGNMENT") {
      CONTROL_CHECK(Check::CHK_ALIGNMENT);
    } else if OPTION ("LOAD") {
      CONTROL_CHECK(ccl::permissions::LOAD);
    } else if OPTION ("STORE") {
      CONTROL_CHECK(ccl::permissions::STORE);
    } else if OPTION ("LOAD_CAP") {
      CONTROL_CHECK(ccl::permissions::LOAD_CAP);
    } else if OPTION ("STORE_CAP") {
      CONTROL_CHECK(ccl::permissions::STORE_CAP);
    } else if OPTION ("EXECUTE") {
      CONTROL_CHECK(ccl::permissions::EXECUTE);
    } else {
      // Unfortunately, the current option is not recognized.
      const NoOptionsEnabled Opts;
      CheckContext(LocalCap(Opts))
          .add(DynamicControlError(cheriseed_checks_start, option_start));
      break;
    }

#undef CONTROL_CHECK
#undef OPTION
  }
}

// Helper to manage the locked state of a range of tags.
struct RangedTagOperation {
  explicit RangedTagOperation(vaddr address, usize size)
      : range(address, address + size) {
    // TODO: check that start < end
  }

  void Lock() const { ShadowMap.IterateTagRanges(range, &LockCallback); }
  void UnLock() const { ShadowMap.IterateTagRanges(range, &UnLockCallback); }
  void ClearAll() const {
    ShadowMap.IterateTagRanges(range, &ClearAllCallback);
  }
  void CopyAllTo(const MemoryRange &dest_range, const bool lock) const {
    ShadowMap.ZipTagRange(range, dest_range, &CopyAllToCallback, lock);
  }

 protected:
  // Locks tags in the range [range.GetBase(), range.GetEnd()).
  static void LockCallback(const MemoryRange &range) {
    TagState *address = reinterpret_cast<TagState *>(range.GetBase());
    const TagState *const end_address =
        reinterpret_cast<TagState *>(range.GetEnd());
    while (address != end_address) {
      AcquireTag(address++);
    }
  }

  // Unlocks previously locked tags in the range
  // [range.GetBase(), range.GetEnd()).
  static void UnLockCallback(const MemoryRange &range) {
    TagState *address = reinterpret_cast<TagState *>(range.GetBase());
    const TagState *const end_address =
        reinterpret_cast<TagState *>(range.GetEnd());
    while (address != end_address) {
      const TagState prev_tag = ReleaseTag(address, TagState::TS_CLEARED);
      if (UNLIKELY(prev_tag != TagState::TS_LOCKED)) {
        // TODO: error
      }
      ++address;
    }
  }

  // Clears tags in the range [range.GetBase(), range.GetEnd()).
  static void ClearAllCallback(const MemoryRange &range) {
    TagState *address = reinterpret_cast<TagState *>(range.GetBase());
    const TagState *const end_address =
        reinterpret_cast<TagState *>(range.GetEnd());
    while (address != end_address) {
      const usize addr = reinterpret_cast<usize>(address);
      const usize remaining = static_cast<usize>(end_address - address);
      // If it is possible, use fixed mapping to clear the tags.
      if (((addr % SystemPageSize) == 0) && (remaining > SystemPageSize)) {
        usize map_size = __sanitizer::RoundDownTo(remaining, SystemPageSize);
        FixedMapAccessible({addr, addr + map_size});
        address += map_size;
      } else {
        WriteTag(address++, TagState::TS_CLEARED);
      }
    }
  }

  // Copies tags in the range [range.GetBase(), range.GetEnd()) to
  // tag_ptr. If lock is true, lock the source tag and copy to
  // destination, else just copy.
  static void CopyAllToCallback(const MemoryRange &range_src,
                                const MemoryRange &range_dest,
                                const bool lock) {
    TagState *address = reinterpret_cast<TagState *>(range_src.GetBase());
    const TagState *const end_address =
        reinterpret_cast<TagState *>(range_src.GetEnd());
    TagState *dest_address = reinterpret_cast<TagState *>(range_dest.GetBase());
    while (address != end_address) {
      WriteTag(dest_address++, lock ? AcquireTag(address) : ReadTag(address));
      ++address;
    }
  }

  MemoryRange range;
};  // struct RangedTagOperation

}  // namespace __cheriseed

// -------------------------------------
// Mappings of CHERI intrinsics
// -------------------------------------

__cheriseed_cap_t *__cheriseed_bounded_stack_cap(
    __cheriseed_cap_t *cap_out, const __cheriseed_cap_t *cap_in, u64 ptr) {
  UNIMPLEMENTED();
}

u64 __cheriseed_address_get(const __cheriseed_cap_t *cap) {
  const SnapshotOptions Opts;
  return LocalCap(Opts, AllowNullCap(cap)).GetValue();
}

__cheriseed_cap_t *__cheriseed_address_set(__cheriseed_cap_t *cap_out,
                                           const __cheriseed_cap_t *cap_in,
                                           u64 address) {
  const SnapshotOptions Opts;
  LocalCap local_cap{Opts, AllowNullCap(cap_in)};
  ccl::methods::SetValue(local_cap, address);
  return local_cap.Store(cap_out);
}

u64 __cheriseed_base_get(const __cheriseed_cap_t *cap_in) {
  const SnapshotOptions Opts;
  return ccl::methods::GetBase(LocalCap(Opts, AllowNullCap(cap_in)));
}

__cheriseed_cap_t *__cheriseed_bounds_set(__cheriseed_cap_t *cap_out,
                                          const __cheriseed_cap_t *cap_in,
                                          u64 length) {
  const SnapshotOptions Opts;
  LocalCap local_cap{Opts, AllowNullCap(cap_in)};
  bool is_exact = false;  // Discarded, not used.
  ccl::methods::SetBounds(local_cap, local_cap.GetValue(),
                          local_cap.GetValue() + length,
                          /* needs_exact */ false, is_exact);
  // TODO: what if not exact?
  return local_cap.Store(cap_out);
}

__cheriseed_cap_t *__cheriseed_bounds_set_exact(__cheriseed_cap_t *cap_out,
                                                const __cheriseed_cap_t *cap_in,
                                                u64 length) {
  const SnapshotOptions Opts;
  LocalCap local_cap{Opts, AllowNullCap(cap_in)};
  const bool was_tagged = local_cap.IsTagged();
  bool is_exact = false;
  ccl::methods::SetBounds(local_cap, local_cap.GetValue(),
                          local_cap.GetValue() + length, /* needs_exact */ true,
                          is_exact);
  if (!is_exact && was_tagged) {
    // TODO: Optionally exit with an error if feature is enabled
  }
  return local_cap.Store(cap_out);
}

__cheriseed_cap_t *__cheriseed_build(__cheriseed_cap_t *cap_out,
                                     const __cheriseed_cap_t *cap_in,
                                     const __cheriseed_cap_t *cap_value) {
  UNIMPLEMENTED();
}

__cheriseed_cap_t *__cheriseed_conditional_seal(
    __cheriseed_cap_t *cap_out, const __cheriseed_cap_t *cap_in,
    const __cheriseed_cap_t *cap_seal) {
  UNIMPLEMENTED();
}

u64 __cheriseed_copy_from_high(const __cheriseed_cap_t *cap) {
  const SnapshotOptions Opts;
  return LocalCap(Opts, AllowNullCap(cap)).GetMetadata();
}

__cheriseed_cap_t *__cheriseed_copy_to_high(__cheriseed_cap_t *cap_out,
                                            const __cheriseed_cap_t *cap_in,
                                            u64 value) {
  const SnapshotOptions Opts;
  LocalCap local_cap{Opts, AllowNullCap(cap_in)};
  return LocalCap(Opts, local_cap.GetValue(), value).Store(cap_out);
}

u64 __cheriseed_diff(const __cheriseed_cap_t *cap_lhs,
                     const __cheriseed_cap_t *cap_rhs) {
  const SnapshotOptions Opts;
  return (LocalCap(Opts, AllowNullCap(cap_lhs)).GetValue() -
          LocalCap(Opts, AllowNullCap(cap_rhs)).GetValue());
}

u8 __cheriseed_equal_exact(const __cheriseed_cap_t *cap_lhs,
                           const __cheriseed_cap_t *cap_rhs) {
  const SnapshotOptions Opts;
  return ccl::methods::ExactlyEqual(LocalCap(Opts, AllowNullCap(cap_lhs)),
                                    LocalCap(Opts, AllowNullCap(cap_rhs)));
}

u64 __cheriseed_flags_get(const __cheriseed_cap_t *cap) { UNIMPLEMENTED(); }

__cheriseed_cap_t *__cheriseed_flags_set(__cheriseed_cap_t *cap_out,
                                         const __cheriseed_cap_t *cap_in,
                                         u64 flags) {
  UNIMPLEMENTED();
}

u64 __cheriseed_length_get(const __cheriseed_cap_t *cap_in) {
  const SnapshotOptions Opts;
  return ccl::methods::GetLength(LocalCap(Opts, AllowNullCap(cap_in)));
}

u64 __cheriseed_load_tags(const __cheriseed_cap_t *cap) { UNIMPLEMENTED(); }

u64 __cheriseed_offset_get(const __cheriseed_cap_t *cap_in) {
  const SnapshotOptions Opts;
  return ccl::methods::GetOffset(LocalCap(Opts, AllowNullCap(cap_in)));
}

__cheriseed_cap_t *__cheriseed_offset_set(__cheriseed_cap_t *cap_out,
                                          const __cheriseed_cap_t *cap_in,
                                          u64 offset) {
  const SnapshotOptions Opts;
  LocalCap local_cap{Opts, AllowNullCap(cap_in)};
  ccl::methods::SetValue(local_cap, ccl::methods::GetBase(local_cap) + offset);
  return local_cap.Store(cap_out);
}

__cheriseed_cap_t *__cheriseed_perms_and(__cheriseed_cap_t *cap_out,
                                         const __cheriseed_cap_t *cap_in,
                                         u64 mask) {
  const SnapshotOptions Opts;
  LocalCap local_cap{Opts, AllowNullCap(cap_in)};
  ccl::methods::PermsAnd(local_cap, mask);
  return local_cap.Store(cap_out);
}

void __cheriseed_perms_check(const __cheriseed_cap_t *cap, u64 mask) {
  UNIMPLEMENTED();
}

u64 __cheriseed_perms_get(const __cheriseed_cap_t *cap) {
  const SnapshotOptions Opts;
  return ccl::methods::GetPerms(LocalCap(Opts, AllowNullCap(cap)));
}

__cheriseed_cap_t *__cheriseed_seal(__cheriseed_cap_t *cap_out,
                                    const __cheriseed_cap_t *cap_in,
                                    const __cheriseed_cap_t *cap_seal) {
  UNIMPLEMENTED();
}

__cheriseed_cap_t *__cheriseed_seal_entry(__cheriseed_cap_t *cap_out,
                                          const __cheriseed_cap_t *cap_in) {
  UNIMPLEMENTED();
}
u8 __cheriseed_sealed_get(const __cheriseed_cap_t *cap) { UNIMPLEMENTED(); }

u8 __cheriseed_subset_test(const __cheriseed_cap_t *cap_tested,
                           const __cheriseed_cap_t *cap) {
  const SnapshotOptions Opts;
  return ccl::methods::SubsetTest(LocalCap(Opts, AllowNullCap(cap_tested)),
                                  LocalCap(Opts, AllowNullCap(cap)));
}

__cheriseed_cap_t *__cheriseed_tag_clear(__cheriseed_cap_t *cap_out,
                                         const __cheriseed_cap_t *cap_in) {
  const SnapshotOptions Opts;
  LocalCap local_cap{Opts, AllowNullCap(cap_in)};
  local_cap.ClearTag();
  return local_cap.Store(cap_out);
}

u8 __cheriseed_tag_get(const __cheriseed_cap_t *cap) {
  const SnapshotOptions Opts;
  return LocalCap(Opts, AllowNullCap(cap)).IsTagged() ? 1 : 0;
}

u64 __cheriseed_to_pointer(const __cheriseed_cap_t *cap) { UNIMPLEMENTED(); }

void __cheriseed_type_check(const __cheriseed_cap_t *cap1,
                            const __cheriseed_cap_t *type) {
  UNIMPLEMENTED();
}

__cheriseed_cap_t *__cheriseed_type_copy(__cheriseed_cap_t *cap_out,
                                         const __cheriseed_cap_t *cap_in,
                                         const __cheriseed_cap_t *cap_type) {
  UNIMPLEMENTED();
}

u64 __cheriseed_type_get(const __cheriseed_cap_t *cap) {
  const SnapshotOptions Opts;
  return ccl::methods::GetType(LocalCap(Opts, AllowNullCap(cap)));
}

__cheriseed_cap_t *__cheriseed_unseal(__cheriseed_cap_t *cap_out,
                                      const __cheriseed_cap_t *cap_in,
                                      const __cheriseed_cap_t *cap_unseal) {
  UNIMPLEMENTED();
}

__cheriseed_cap_t *__cheriseed_ddc_get(__cheriseed_cap_t *cap_out) {
  const SnapshotOptions Opts;
  LocalCap local_cap(Opts);
  ccl::methods::BuildMaxCap(local_cap, 0);
  return local_cap.Store(cap_out);
}

__cheriseed_cap_t *__cheriseed_pcc_get(__cheriseed_cap_t *cap_out) {
  const SnapshotOptions Opts;
  LocalCap local_cap(Opts);
  ccl::methods::BuildMaxCap(local_cap, GET_CALLER_PC());
  return local_cap.Store(cap_out);
}

u64 __cheriseed_representable_alignment_mask(u64 length) {
  return ccl::methods::GetAlignmentMask(length);
}

u64 __cheriseed_round_representable_length(u64 length) {
  return ccl::methods::GetRepresentableLength(length);
}

void __cheriseed_stack_cap_get(__cheriseed_cap_t *cap) { UNIMPLEMENTED(); }

// -------------------------------------
// Additional user-accessible APIs
// -------------------------------------

void __cheriseed_clear_all_tags(const __cheriseed_cap_t *cap, u64 size) {
  const SnapshotOptions Opts;
  u64 address =
      LocalCap(Opts, cap).RequireTagged().RequireBounds(size).GetValue();
  RangedTagOperation(address, size).ClearAll();
}

static void __cheriseed_copy_tags(const __cheriseed_cap_t *cap_to,
                                  const __cheriseed_cap_t *cap_from, u64 size,
                                  bool lock) {
  const SnapshotOptions Opts;
  u64 source_address =
      LocalCap(Opts, cap_from).RequireTagged().RequireBounds(size).GetValue();
  u64 destination_address =
      LocalCap(Opts, cap_to).RequireTagged().RequireBounds(size).GetValue();
  RangedTagOperation(source_address, size)
      .CopyAllTo(MemoryRange(destination_address, destination_address + size),
                 lock);
}

void __cheriseed_copy_all_tags(const __cheriseed_cap_t *cap_to,
                               const __cheriseed_cap_t *cap_from, u64 size) {
  __cheriseed_copy_tags(cap_to, cap_from, size, false);
}

void __cheriseed_lock_and_copy_all_tags(const __cheriseed_cap_t *cap_to,
                                        const __cheriseed_cap_t *cap_from,
                                        u64 size) {
  __cheriseed_copy_tags(cap_to, cap_from, size, true);
}

void __cheriseed_control_semantics(u8 enable) {
  atomic_store_relaxed(&Options::EnableCHERISemantics, enable);
}

void __cheriseed_control_invoke_signal_handlers(u8 enable) {
  atomic_store_relaxed(&Options::EnableSignalHandlers, enable);
}

void __cheriseed_control_checks(u8 enable, u64 checks) {
  u64 old_mask =
      atomic_load(&Options::Checks, memory_order::memory_order_acquire);
  u64 new_mask;
  do {
    new_mask = enable ? old_mask | checks : old_mask & ~checks;
  } while (!atomic_compare_exchange_strong(&Options::Checks, &old_mask,
                                           new_mask,
                                           memory_order::memory_order_acq_rel));
}

__cheriseed_cap_t *__cheriseed_strerror(__cheriseed_cap_t *result, int code) {
  const SnapshotOptions Opts;
  const char *str;
  usize length;
  switch (code) {
    default:
      static constexpr char kUnknown[] = "UNKNOWN";
      str = kUnknown;
      length = sizeof(kUnknown);
      break;
    case SignalCode::SC_SEGV_CAPTAGERR:
      static constexpr char kSegvCapTagErr[] = "SEGV_CAPTAGERR";
      str = kSegvCapTagErr;
      length = sizeof(kSegvCapTagErr);
      break;
    case SignalCode::SC_SEGV_CAPBOUNDSERR:
      static constexpr char kSegvCapBoundsErr[] = "SEGV_CAPBOUNDSERR";
      str = kSegvCapBoundsErr;
      length = sizeof(kSegvCapBoundsErr);
      break;
    case SignalCode::SC_SEGV_CAPPERMERR:
      static constexpr char kSegvCapPermErr[] = "SEGV_CAPPERMERR";
      str = kSegvCapPermErr;
      length = sizeof(kSegvCapPermErr);
      break;
  }

  LocalCap local_cap(Opts);
  ccl::methods::BuildBoundedCap(local_cap, reinterpret_cast<u64>(str), length,
                                ccl::permissions::LOAD);
  return local_cap.Store(result);
}

int __cheriseed_set_signal_handle_mode(__cheriseed_cap_t *context, int mode) {
  const SnapshotOptions Opts;
  LocalCap local_cap(Opts, context);
  local_cap.RequireTagged()
      .RequirePermissions(ccl::permissions::STORE)
      .RequireBounds(sizeof(SignalHandleMode));
  switch (mode) {
    default:
      return 1;
    case SignalHandleMode::SHM_DEFAULT:
    case SignalHandleMode::SHM_SILENT:
    case SignalHandleMode::SHM_IGNORE:
    case SignalHandleMode::SHM_WARNING:
      break;
  }

  *reinterpret_cast<SignalHandleMode *>(local_cap.GetValue()) =
      static_cast<SignalHandleMode>(mode);
  return 0;
}

// Symbols to section containing global initialization data. This works well for
// static linkage. Needs to be removed for cases to handle dynamic linkage.
extern void *__attribute__((weak)) __start___cheriseed_initializers;
extern void *__attribute__((weak)) __stop___cheriseed_initializers;

// The following needs to changed for dynamic linkage cases. The changes would
// include passing __start_* and __stop_* symbols as parameters while calling.
void __cheriseed_static_init(u64 sp) {
  Environment env = Environment::From(sp);
  // Save AT_PAGESZ
  if (u64 at_pagesz = env.GetAuxv(libc::AT_PAGESZ))
    SystemPageSize = at_pagesz;

  ShadowMemoryInit();
  // Tags are available from now.

  ControlChecksDynamic(env);

  if (!&__start___cheriseed_initializers)
    return;
  CHECK_EQ(0, ((vaddr)&__stop___cheriseed_initializers -
               (vaddr)&__start___cheriseed_initializers) %
                  sizeof(__cheriseed_initializer_t));

  __cheriseed_initializer_t *glo_init_start =
      reinterpret_cast<__cheriseed_initializer_t *>(
          &__start___cheriseed_initializers);
  __cheriseed_initializer_t *glo_init_stop =
      reinterpret_cast<__cheriseed_initializer_t *>(
          &__stop___cheriseed_initializers);

  const SnapshotOptions Opts;
  for (ssize idx = 0; idx < glo_init_stop - glo_init_start; ++idx) {
    if (!glo_init_start[idx].cap)
      continue;
    LocalCap local_cap(Opts);
    bool is_exact = ccl::methods::BuildBoundedCap(
        local_cap, glo_init_start[idx].address, glo_init_start[idx].size,
        ~CheckPermsToCCL(glo_init_start[idx].clear_perms));
    if (!is_exact) {
      // TODO: invalidate capability if not exact
    }
    local_cap.Store(glo_init_start[idx].cap);
  }

  for (ssize idx = 0; idx < glo_init_stop - glo_init_start; ++idx)
    if (glo_init_start[idx].init)
      glo_init_start[idx].init();
}

// -------------------------------------
// APIs used by the compiler
// -------------------------------------

u64 __cheriseed_check_access(const __cheriseed_cap_t *cap, u64 size,
                             u32 perms) {
  const SnapshotOptions Opts;
  u64 ccl_perms = CheckPermsToCCL(perms);
  u64 address = LocalCap(Opts, cap)
                    .RequireTagged()
                    .RequirePermissions(ccl_perms)
                    .RequireBounds(size)
                    .GetValue();
  // If there is a data store going to happen, lock all tags for that range.
  // This closes the window in which a race condition can occur between
  // writing some random data and a tagged capability.
  if (ccl_perms & ccl::permissions::STORE)
    RangedTagOperation(address, size).Lock();

  return address;
}

void __cheriseed_check_access_end(u64 address, u64 size) {
  RangedTagOperation(address, size).UnLock();
}

__cheriseed_cmpxchg_result_t __cheriseed_cmpxchg_cap(
    __cheriseed_cap_t *cap_to_cap, const __cheriseed_cap_t *cap_expected,
    const __cheriseed_cap_t *cap_desired, __cheriseed_cap_t *cap_orig,
    u8 memory_order_success, u8 memory_order_failure) {
  UNIMPLEMENTED();
}

__cheriseed_cmpxchg_result_t __cheriseed_cmpxchg_cap_hybrid(
    __cheriseed_cap_t *cap, const __cheriseed_cap_t *cap_expected,
    const __cheriseed_cap_t *cap_desired, __cheriseed_cap_t *cap_orig,
    u8 memory_order_success, u8 memory_order_failure) {
  UNIMPLEMENTED();
}

__cheriseed_cap_t *__cheriseed_copy_cap_with_offset(
    __cheriseed_cap_t *cap_out, const __cheriseed_cap_t *cap_in, u64 offset) {
  const SnapshotOptions Opts;
  LocalCap local_cap{Opts, AllowNullCap(cap_in)};
  ccl::methods::SetValue(local_cap, local_cap.GetValue() + offset);
  return local_cap.Store(cap_out);
}

__cheriseed_cap_t *__cheriseed_generic_cap_init(__cheriseed_cap_t *cap,
                                                u64 address, u64 size,
                                                u32 perms_to_clear) {
  const SnapshotOptions Opts;
  LocalCap local_cap{Opts};
  bool is_exact = ccl::methods::BuildBoundedCap(
      local_cap, address, size, ~CheckPermsToCCL(perms_to_clear));
  if (!is_exact) {
    // TODO: invalidate capability if not exact?
  }
  return local_cap.Store(cap);
}

__cheriseed_cap_t *__cheriseed_load_cap(const __cheriseed_cap_t *cap_to_cap,
                                        __cheriseed_cap_t *loaded_cap) {
  // All capability loads should be atomic, with default memory order
  return __cheriseed_load_cap_atomic(cap_to_cap, loaded_cap,
                                     kIRRelaxedOrdering);
}

__cheriseed_cap_t *__cheriseed_load_cap_atomic(
    const __cheriseed_cap_t *cap_to_cap, __cheriseed_cap_t *loaded_cap,
    u8 memory_order) {
  const SnapshotOptions Opts;
  LocalCap local_cap(Opts, cap_to_cap);
  local_cap.RequireTagged()
      .RequirePermissions(ccl::permissions::LOAD)
      .RequireBounds(sizeof(__cheriseed_cap_t));
  // Get the pointed capability.
  const __cheriseed_cap_t *deref_cap =
      reinterpret_cast<const __cheriseed_cap_t *>(local_cap.GetValue());
  LocalCap local_deref_cap{Opts, AllowNullCap(deref_cap),
                           IRToCppOrdering(memory_order)};
  // If the source capability has no LOAD_CAP permission, the tag of the loaded
  // capability is silently cleared.
  if (!ccl::methods::HasPerms(local_cap, ccl::permissions::LOAD_CAP))
    local_deref_cap.ClearTag();
  return local_deref_cap.Store(loaded_cap);
}

__cheriseed_cap_t *__cheriseed_load_cap_hybrid(const __cheriseed_cap_t *cap,
                                               __cheriseed_cap_t *loaded_cap) {
  // All capability loads should be atomic, with default memory order
  return __cheriseed_load_cap_hybrid_atomic(cap, loaded_cap,
                                            kIRRelaxedOrdering);
}

__cheriseed_cap_t *__cheriseed_load_cap_hybrid_atomic(
    const __cheriseed_cap_t *cap, __cheriseed_cap_t *loaded_cap,
    u8 memory_order) {
  const SnapshotOptions Opts;
  return LocalCap(Opts, AllowNullCap(cap), IRToCppOrdering(memory_order))
      .Store(loaded_cap);
}

__cheriseed_cap_t *__cheriseed_rmw_cap(__cheriseed_cap_t *cap_to_cap,
                                       const __cheriseed_cap_t *cap_value,
                                       __cheriseed_cap_t *cap_ret, u8 op,
                                       u8 memory_order) {
  UNIMPLEMENTED();
}

__cheriseed_cap_t *__cheriseed_rmw_cap_hybrid(
    __cheriseed_cap_t *cap, const __cheriseed_cap_t *cap_value,
    __cheriseed_cap_t *cap_ret, u8 op, u8 memory_order) {
  UNIMPLEMENTED();
}

__cheriseed_cap_t *__cheriseed_stack_cap_init(__cheriseed_cap_t *cap_out,
                                              u64 address, u64 size) {
  const SnapshotOptions Opts;
  LocalCap local_cap(Opts);
  bool is_exact = ccl::methods::BuildBoundedCap(local_cap, address, size,
                                                ~ccl::permissions::EXECUTE);
  if (!is_exact) {
    // TODO: invalidate capability if not exact?
  }
  return local_cap.Store(cap_out);
}

void __cheriseed_store_cap(__cheriseed_cap_t *cap_to_cap,
                           const __cheriseed_cap_t *cap_to_store) {
  // All capability stores should be atomic, with default memory order
  __cheriseed_store_cap_atomic(cap_to_cap, cap_to_store, kIRRelaxedOrdering);
}

void __cheriseed_store_cap_atomic(__cheriseed_cap_t *cap_to_cap,
                                  const __cheriseed_cap_t *cap_to_store,
                                  u8 memory_order) {
  const SnapshotOptions Opts;
  LocalCap local_cap(Opts, cap_to_cap);
  local_cap.RequireTagged()
      .RequirePermissions(ccl::permissions::STORE)
      .RequireBounds(sizeof(__cheriseed_cap_t));
  LocalCap local_stored_cap{Opts, AllowNullCap(cap_to_store)};
  // If the stored capability is tagged then STORE_CAP must be present.
  if (LIKELY(local_stored_cap.IsTagged()))
    local_cap.RequirePermissions(ccl::permissions::STORE_CAP);
  // Note: It is allowed to store to invalid memory.
  __cheriseed_cap_t *deref_cap =
      reinterpret_cast<__cheriseed_cap_t *>(local_cap.GetValue());
  local_stored_cap.Store(deref_cap, IRToCppOrdering(memory_order));
}

void __cheriseed_store_cap_hybrid(__cheriseed_cap_t *cap,
                                  const __cheriseed_cap_t *cap_to_store) {
  // All capability stores should be atomic, with default memory order
  __cheriseed_store_cap_hybrid_atomic(cap, cap_to_store, kIRRelaxedOrdering);
}

void __cheriseed_store_cap_hybrid_atomic(__cheriseed_cap_t *cap,
                                         const __cheriseed_cap_t *cap_to_store,
                                         u8 memory_order) {
  const SnapshotOptions Opts;
  LocalCap(Opts, AllowNullCap(cap_to_store))
      .Store(cap, IRToCppOrdering(memory_order));
}

__cheriseed_cap_t *__cheriseed_thread_pointer(__cheriseed_cap_t *cap) {
  const SnapshotOptions Opts;
  // Many compilers are unable to lower __builtin_thread_pointer()
  u64 tp;
#if defined(__aarch64__)
  __asm__("mrs %0, tpidr_el0\n\t" : "=r"(tp));
#elif defined(__x86_64__)
  __asm__("mov %%fs:0, %0\n\t" : "=r"(tp));
#else
#error "Unsupported architecture"
#endif
  LocalCap local_cap(Opts);
  ccl::methods::BuildMaxCap(local_cap, tp);
  // TODO: restrict bounds and permissions
  return local_cap.Store(cap);
}
