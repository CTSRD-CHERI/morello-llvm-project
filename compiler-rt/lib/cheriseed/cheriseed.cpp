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

#include "cheriseed_ccl_interface.h"
#include "cheriseed_errors.h"
#include "cheriseed_interface_internal.h"

using namespace __sanitizer;
using namespace __cheriseed;

namespace __cheriseed {

AtomicBool Options::EnableCHERISemantics{false};
AtomicBool Options::EnableSignalHandlers{true};

}  // namespace __cheriseed

// -------------------------------------
// Runtime Error Checker functions
// -------------------------------------

#undef UNIMPLEMENTED
#define UNIMPLEMENTED()                                                    \
  {                                                                        \
    error::CheckContext(nullptr).add(error::NotImplemented(__FUNCTION__)); \
    Die();                                                                 \
  }

// Inlining is important for retrieval of the caller's address.
// This function performs mandatory checks on an input capability.
ALWAYS_INLINE
static error::CheckContext DefaultCapChecks(const __cheriseed_cap_t *cap) {
  return error::CheckContext(cap)
      .add(error::CapabilityAddress())
      .add(error::CapabilityAlignment());
}

// -------------------------------------
// Mappings of CHERI intrinsics
// -------------------------------------

ALWAYS_INLINE static __cheriseed_cap_t *__cheriseed_bounds_set_common(
    __cheriseed_cap_t *cap_out, const __cheriseed_cap_t *cap_in, u64 length,
    bool &exact_res) {
  if (!cap_in)
    ccl::UseNullCap(&cap_in);
  DefaultCapChecks(cap_in);
  *cap_out = *cap_in;
  // All fields of cap_out metadata will be the same as cap_in, except the
  // narrowed bounds
  ccl::SetBounds(cap_out, cap_in->value, cap_in->value + length, exact_res);
  return cap_out;
}

__cheriseed_cap_t *__cheriseed_bounded_stack_cap(
    __cheriseed_cap_t *cap_out, const __cheriseed_cap_t *cap_in, u64 ptr) {
  UNIMPLEMENTED();
}

u64 __cheriseed_address_get(const __cheriseed_cap_t *cap) {
  if (!cap)
    ccl::UseNullCap(&cap);
  DefaultCapChecks(cap);
  return cap->value;
}

__cheriseed_cap_t *__cheriseed_address_set(__cheriseed_cap_t *cap_out,
                                           const __cheriseed_cap_t *cap_in,
                                           u64 addr) {
  DefaultCapChecks(cap_out);
  if (!cap_in)
    ccl::UseNullCap(&cap_in);
  DefaultCapChecks(cap_in);
  // TODO:  Representability check?
  cap_out->metadata = cap_in->metadata;
  cap_out->value = addr;
  return cap_out;
}

u64 __cheriseed_base_get(const __cheriseed_cap_t *cap) {
  if (!cap)
    ccl::UseNullCap(&cap);
  DefaultCapChecks(cap);
  return ccl::GetBase(cap);
}

__cheriseed_cap_t *__cheriseed_bounds_set(__cheriseed_cap_t *cap_out,
                                          const __cheriseed_cap_t *cap_in,
                                          u64 length) {
  DefaultCapChecks(cap_out);
  // In this function the is_exact value isn't used
  bool is_exact = false;
  return __cheriseed_bounds_set_common(cap_out, cap_in, length, is_exact);
}

__cheriseed_cap_t *__cheriseed_bounds_set_exact(__cheriseed_cap_t *cap_out,
                                                const __cheriseed_cap_t *cap_in,
                                                u64 length) {
  DefaultCapChecks(cap_out);
  bool is_exact = false;
  cap_out = __cheriseed_bounds_set_common(cap_out, cap_in, length, is_exact);
  // TODO:
  //  - invalidate capability.
  //  - Optionally exit with an error if feature is enabled
  return cap_out;
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
  UNIMPLEMENTED();
}

__cheriseed_cap_t *__cheriseed_copy_to_high(__cheriseed_cap_t *cap_out,
                                            const __cheriseed_cap_t *cap_in,
                                            u64 value) {
  UNIMPLEMENTED();
}

u64 __cheriseed_diff(const __cheriseed_cap_t *cap_left,
                     const __cheriseed_cap_t *cap_right) {
  DefaultCapChecks(cap_left);
  DefaultCapChecks(cap_right);
  return (cap_left->value - cap_right->value);
}

u8 __cheriseed_equal_exact(const __cheriseed_cap_t *cap_left,
                           const __cheriseed_cap_t *cap_right) {
  if (!cap_left)
    ccl::UseNullCap(&cap_left);
  if (!cap_right)
    ccl::UseNullCap(&cap_right);
  DefaultCapChecks(cap_left);
  DefaultCapChecks(cap_right);
  return ccl::ExactlyEqual(cap_left, cap_right);
}

u64 __cheriseed_flags_get(const __cheriseed_cap_t *cap) { UNIMPLEMENTED(); }

__cheriseed_cap_t *__cheriseed_flags_set(__cheriseed_cap_t *cap_out,
                                         const __cheriseed_cap_t *cap_in,
                                         u64 flags) {
  UNIMPLEMENTED();
}

u64 __cheriseed_length_get(const __cheriseed_cap_t *cap) {
  if (!cap)
    ccl::UseNullCap(&cap);
  DefaultCapChecks(cap);
  return ccl::GetLength(cap);
}

u64 __cheriseed_load_tags(const __cheriseed_cap_t *cap) { UNIMPLEMENTED(); }

u64 __cheriseed_offset_get(const __cheriseed_cap_t *cap) {
  if (!cap)
    ccl::UseNullCap(&cap);
  DefaultCapChecks(cap);
  return ccl::GetOffset(cap);
}

__cheriseed_cap_t *__cheriseed_offset_set(__cheriseed_cap_t *cap_out,
                                          const __cheriseed_cap_t *cap_in,
                                          u64 offset) {
  DefaultCapChecks(cap_out);
  if (!cap_in)
    ccl::UseNullCap(&cap_in);
  DefaultCapChecks(cap_in);
  u64 new_cursor = ccl::GetBase(cap_in) + offset;
  if (!ccl::IsRepresentableWithCursor(cap_in, new_cursor)) {
    // TODO: Invalidate capability
  }
  cap_out->value = new_cursor;
  cap_out->metadata = cap_in->metadata;
  return cap_out;
}

__cheriseed_cap_t *__cheriseed_perms_and(__cheriseed_cap_t *cap_out,
                                         const __cheriseed_cap_t *cap_in,
                                         u64 mask) {
  DefaultCapChecks(cap_out);
  if (!cap_in)
    ccl::UseNullCap(&cap_in);
  DefaultCapChecks(cap_in);
  *cap_out = *cap_in;
  ccl::UpdatePermsAnd(cap_out, mask);
  return cap_out;
}

void __cheriseed_perms_check(const __cheriseed_cap_t *cap, u64 mask) {
  UNIMPLEMENTED();
}

u64 __cheriseed_perms_get(const __cheriseed_cap_t *cap) {
  if (!cap)
    ccl::UseNullCap(&cap);
  DefaultCapChecks(cap);
  return ccl::PermsGet(cap);
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
  UNIMPLEMENTED();
}

__cheriseed_cap_t *__cheriseed_tag_clear(__cheriseed_cap_t *cap_out,
                                         const __cheriseed_cap_t *cap_in) {
  return cap_out;
}

u8 __cheriseed_tag_get(const __cheriseed_cap_t *cap) { return 1; }

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
  DefaultCapChecks(cap);
  return ccl::GetType(cap);
}
__cheriseed_cap_t *__cheriseed_unseal(__cheriseed_cap_t *cap_out,
                                      const __cheriseed_cap_t *cap_in,
                                      const __cheriseed_cap_t *cap_unseal) {
  UNIMPLEMENTED();
}

__cheriseed_cap_t *__cheriseed_ddc_get(__cheriseed_cap_t *cap) {
  DefaultCapChecks(cap);
  ccl::BuildMaxCap(cap, 0);
  return cap;
}

__cheriseed_cap_t *__cheriseed_pcc_get(__cheriseed_cap_t *cap) {
  DefaultCapChecks(cap);
  ccl::BuildMaxCap(cap, GET_CALLER_PC());
  return cap;
}

u64 __cheriseed_representable_alignment_mask(u64 length) {
  return ccl::GetAlignmentMask(length);
}

u64 __cheriseed_round_representable_length(u64 length) {
  return ccl::GetRepresentableLength(length);
}

void __cheriseed_stack_cap_get(__cheriseed_cap_t *cap) { UNIMPLEMENTED(); }

// -------------------------------------
// Additional user-accessible APIs
// -------------------------------------

void __cheriseed_enable_cheri_semantics(int enable) {
  Options::EnableCHERISemantics = (enable != 0);
}

__cheriseed_cap_t *__cheriseed_strerror(__cheriseed_cap_t *result, int code) {
  DefaultCapChecks(result);
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
  ccl::BuildBoundedCap(result, reinterpret_cast<u64>(str), length,
                       ccl::permissions::LOAD);
  return result;
}

int __cheriseed_set_signal_handle_mode(__cheriseed_cap_t *context, int mode) {
  DefaultCapChecks(context)
      .add(error::RequiredPerms(ccl::permissions::STORE))
      .add(error::InBounds(sizeof(SignalHandleMode)));
  switch (mode) {
    default:
      return 1;
    case SignalHandleMode::SHM_DEFAULT:
    case SignalHandleMode::SHM_SILENT:
    case SignalHandleMode::SHM_IGNORE:
    case SignalHandleMode::SHM_WARNING:
      break;
  }
  *reinterpret_cast<int *>(context->value) = mode;
  return 0;
}

void __cheriseed_enable_invoke_signal_handlers(int enable) {
  Options::EnableSignalHandlers = (enable != 0);
}

// -------------------------------------
// APIs used by the compiler
// -------------------------------------

__cheriseed_cap_t *__cheriseed_copy_cap_with_offset(
    __cheriseed_cap_t *cap_out, const __cheriseed_cap_t *cap_in, u64 offset) {
  DefaultCapChecks(cap_out);
  // Might copy nullcap with offset.
  if (cap_in != nullptr) {
    DefaultCapChecks(cap_in);
    cap_out->metadata = cap_in->metadata;
    cap_out->value = cap_in->value + offset;
  } else {
    cap_out->metadata = 0;
    cap_out->value = offset;
  }
  return cap_out;
}

__cheriseed_cap_t *__cheriseed_stack_cap_init(__cheriseed_cap_t *cap, u64 addr,
                                              u64 size) {
  DefaultCapChecks(cap);
  bool is_exact =
      ccl::BuildBoundedCap(cap, addr, size, ~ccl::permissions::EXECUTE);
  if (!is_exact) {
    // TODO invalidate capability if not exact?
  }
  return cap;
}

__cheriseed_cap_t *__cheriseed_load_cap(const __cheriseed_cap_t *cap,
                                        __cheriseed_cap_t *loaded_cap) {
  DefaultCapChecks(cap)
      .add(error::RequiredPerms(ccl::permissions::LOAD))
      .add(error::InBounds(sizeof(__cheriseed_cap_t)));
  DefaultCapChecks(loaded_cap);
  const __cheriseed_cap_t *target_cap;
  if (cap->value != 0)
    target_cap = reinterpret_cast<__cheriseed_cap_t *>(cap->value);
  else
    ccl::UseNullCap(&target_cap);
  DefaultCapChecks(target_cap);
  *loaded_cap = *target_cap;
  // cap must permit Load and Load Capability, otherwise capability is silently
  // cleared
  if (!ccl::HasPerms(cap,
                     ccl::permissions::LOAD | ccl::permissions::LOAD_CAP)) {
    // Invalidate loaded_cap
  }
  return loaded_cap;
}

__cheriseed_cap_t *__cheriseed_load_cap_hybrid(const __cheriseed_cap_t *ptr,
                                               __cheriseed_cap_t *loaded_cap) {
  DefaultCapChecks(ptr);
  DefaultCapChecks(loaded_cap);
  *loaded_cap = *ptr;
  return loaded_cap;
}

void __cheriseed_store_cap(__cheriseed_cap_t *cap,
                           const __cheriseed_cap_t *stored_cap) {
  // TODO if stored_cap is valid
  DefaultCapChecks(cap)
      .add(error::RequiredPerms(ccl::permissions::STORE_CAP |
                                ccl::permissions::STORE))
      .add(error::InBounds(sizeof(__cheriseed_cap_t)));
  if (!stored_cap)
    ccl::UseNullCap(&stored_cap);
  DefaultCapChecks(stored_cap);
  __cheriseed_cap_t *target_cap =
      reinterpret_cast<__cheriseed_cap_t *>(cap->value);
  DefaultCapChecks(target_cap);
  *target_cap = *stored_cap;
}

void __cheriseed_store_cap_hybrid(__cheriseed_cap_t *ptr,
                                  const __cheriseed_cap_t *stored_cap) {
  DefaultCapChecks(ptr);
  if (!stored_cap)
    ccl::UseNullCap(&stored_cap);
  DefaultCapChecks(stored_cap);
  *ptr = *stored_cap;
}

// Set a permissions bit in the ccl representation if the corresponding bit is
// set in the check_access permissions mask
#define BIT_CONVERTER(__perm)                        \
  (in_perms & __cheriseed::abi::permissions::__perm) \
      ? ccl::permissions::__perm                     \
      : 0

static u64 CheckAccessPermsToCCL(u32 in_perms) {
  u32 out_perms = 0;
  out_perms |= BIT_CONVERTER(LOAD);
  out_perms |= BIT_CONVERTER(STORE);
  out_perms |= BIT_CONVERTER(EXECUTE);
  return out_perms;
}

#undef BIT_CONVERTER

u64 __cheriseed_check_access(const __cheriseed_cap_t *cap, u64 size,
                             u32 perms) {
  DefaultCapChecks(cap)
      .add(error::InBounds(size))
      .add(error::RequiredPerms(CheckAccessPermsToCCL(perms)));
  return cap->value;
}

__cheriseed_cap_t *__cheriseed_thread_pointer(__cheriseed_cap_t *cap) {
  DefaultCapChecks(cap);
  // Many compilers are unable to lower __builtin_thread_pointer()
  u64 tp;
#if defined(__aarch64__)
  __asm__("mrs %0, tpidr_el0\n\t" : "=r"(tp));
#elif defined(__x86_64__)
  __asm__("mov %%fs:0, %0\n\t" : "=r"(tp));
#else
#error "Unsupported architecture"
#endif
  // TODO: restrict bounds and permissions
  ccl::BuildMaxCap(cap, tp);
  return cap;
}
