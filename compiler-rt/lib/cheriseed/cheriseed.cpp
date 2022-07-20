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

using namespace __cheriseed;
using namespace __cheriseed::abi;
using namespace __cheriseed::error;

namespace __cheriseed {

atomic_uint8_t Options::EnableCHERISemantics{1};
atomic_uint8_t Options::EnableSignalHandlers{1};
atomic_uint64_t Options::Checks{UINT64_MAX};

// Triggers an unimplemented fault.
#undef UNIMPLEMENTED
#define UNIMPLEMENTED()                                             \
  {                                                                 \
    DefaultOptions Opts;                                            \
    CheckContext(LocalCap(Opts)).add(NotImplemented(__FUNCTION__)); \
    __sanitizer::Die();                                             \
  }

// TODO: Move this to sanitizer_atomic, but that's not so easy because of the
// many platforms.
struct atomic_uint128_t {
  typedef u128 Type;
  volatile ALIGNED(16) Type val_dont_use;
};  // struct atomic_uint128_t

// Make sure alignments match.
static_assert(alignof(atomic_uint128_t) == alignof(__cheriseed_cap_t),
              "Alignment mismatch");

LocalCap::LocalCap(Options &Opts, const __cheriseed_cap_t *ptr,
                   memory_order memory_order, bool allow_nullcap)
    : Opts(Opts) {
  if (UNLIKELY(allow_nullcap && !ptr)) {
    // The null capability has a value of 0, and 0 metadata by definition.
    SetValue(0);
    SetMetadata(0);
    return;
  }

  SetAddress(ptr);
  CheckContext(*this).add(CapabilityAddress()).add(CapabilityAlignment());
  const u128 bits = __sanitizer::atomic_load(
      reinterpret_cast<const atomic_uint128_t *>(ptr), memory_order);
  SetValue(static_cast<u64>(bits));
  SetMetadata(static_cast<u64>(bits >> 64));
}

__cheriseed_cap_t *LocalCap::Store(__cheriseed_cap_t *ptr,
                                   memory_order memory_order) const {
  LocalCap local_cap(GetOpts());
  local_cap.SetAddress(ptr);
  CheckContext(local_cap).add(CapabilityAddress()).add(CapabilityAlignment());
  atomic_uint128_t *atomic_cap =
      reinterpret_cast<atomic_uint128_t *>(local_cap.GetAddress());
  u128 bits =
      static_cast<u128>(GetMetadata()) << 64 | static_cast<u128>(GetValue());
  __sanitizer::atomic_store(atomic_cap, bits, memory_order);
  return ptr;
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

}  // namespace __cheriseed

// -------------------------------------
// Mappings of CHERI intrinsics
// -------------------------------------

__cheriseed_cap_t *__cheriseed_bounded_stack_cap(
    __cheriseed_cap_t *cap_out, const __cheriseed_cap_t *cap_in, u64 ptr) {
  UNIMPLEMENTED();
}

u64 __cheriseed_address_get(const __cheriseed_cap_t *cap) {
  Options Opts;
  return LocalCap(Opts, AllowNullCap(cap)).GetValue();
}

__cheriseed_cap_t *__cheriseed_address_set(__cheriseed_cap_t *cap_out,
                                           const __cheriseed_cap_t *cap_in,
                                           u64 address) {
  Options Opts;
  LocalCap local_cap{Opts, AllowNullCap(cap_in)};
  ccl::methods::SetValue(local_cap, address);
  return local_cap.Store(cap_out);
}

u64 __cheriseed_base_get(const __cheriseed_cap_t *cap_in) {
  Options Opts;
  return ccl::methods::GetBase(LocalCap(Opts, AllowNullCap(cap_in)));
}

__cheriseed_cap_t *__cheriseed_bounds_set(__cheriseed_cap_t *cap_out,
                                          const __cheriseed_cap_t *cap_in,
                                          u64 length) {
  Options Opts;
  LocalCap local_cap{Opts, AllowNullCap(cap_in)};
  bool is_exact = false;  // Discarded, not used.
  ccl::methods::SetBounds(local_cap, local_cap.GetValue(),
                          local_cap.GetValue() + length, is_exact);
  return local_cap.Store(cap_out);
}

__cheriseed_cap_t *__cheriseed_bounds_set_exact(__cheriseed_cap_t *cap_out,
                                                const __cheriseed_cap_t *cap_in,
                                                u64 length) {
  Options Opts;
  LocalCap local_cap{Opts, AllowNullCap(cap_in)};
  bool is_exact = false;
  ccl::methods::SetBounds(local_cap, local_cap.GetValue(),
                          local_cap.GetValue() + length, is_exact);
  // TODO:
  //  - invalidate capability.
  //  - Optionally exit with an error if feature is enabled
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
  UNIMPLEMENTED();
}

__cheriseed_cap_t *__cheriseed_copy_to_high(__cheriseed_cap_t *cap_out,
                                            const __cheriseed_cap_t *cap_in,
                                            u64 value) {
  UNIMPLEMENTED();
}

u64 __cheriseed_diff(const __cheriseed_cap_t *cap_lhs,
                     const __cheriseed_cap_t *cap_rhs) {
  Options Opts;
  return (LocalCap(Opts, AllowNullCap(cap_lhs)).GetValue() -
          LocalCap(Opts, AllowNullCap(cap_rhs)).GetValue());
}

u8 __cheriseed_equal_exact(const __cheriseed_cap_t *cap_lhs,
                           const __cheriseed_cap_t *cap_rhs) {
  Options Opts;
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
  Options Opts;
  return ccl::methods::GetLength(LocalCap(Opts, AllowNullCap(cap_in)));
}

u64 __cheriseed_load_tags(const __cheriseed_cap_t *cap) { UNIMPLEMENTED(); }

u64 __cheriseed_offset_get(const __cheriseed_cap_t *cap_in) {
  Options Opts;
  return ccl::methods::GetOffset(LocalCap(Opts, AllowNullCap(cap_in)));
}

__cheriseed_cap_t *__cheriseed_offset_set(__cheriseed_cap_t *cap_out,
                                          const __cheriseed_cap_t *cap_in,
                                          u64 offset) {
  Options Opts;
  LocalCap local_cap{Opts, AllowNullCap(cap_in)};
  ccl::methods::SetValue(local_cap, ccl::methods::GetBase(local_cap) + offset);
  return local_cap.Store(cap_out);
}

__cheriseed_cap_t *__cheriseed_perms_and(__cheriseed_cap_t *cap_out,
                                         const __cheriseed_cap_t *cap_in,
                                         u64 mask) {
  Options Opts;
  LocalCap local_cap{Opts, AllowNullCap(cap_in)};
  ccl::methods::PermsAnd(local_cap, mask);
  return local_cap.Store(cap_out);
}

void __cheriseed_perms_check(const __cheriseed_cap_t *cap, u64 mask) {
  UNIMPLEMENTED();
}

u64 __cheriseed_perms_get(const __cheriseed_cap_t *cap) {
  Options Opts;
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
  Options Opts;
  return ccl::methods::SubsetTest(LocalCap(Opts, AllowNullCap(cap_tested)),
                                  LocalCap(Opts, AllowNullCap(cap)));
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
  Options Opts;
  return ccl::methods::GetType(LocalCap(Opts, AllowNullCap(cap)));
}

__cheriseed_cap_t *__cheriseed_unseal(__cheriseed_cap_t *cap_out,
                                      const __cheriseed_cap_t *cap_in,
                                      const __cheriseed_cap_t *cap_unseal) {
  UNIMPLEMENTED();
}

__cheriseed_cap_t *__cheriseed_ddc_get(__cheriseed_cap_t *cap_out) {
  Options Opts;
  LocalCap local_cap(Opts);
  ccl::methods::BuildMaxCap(local_cap, 0);
  return local_cap.Store(cap_out);
}

__cheriseed_cap_t *__cheriseed_pcc_get(__cheriseed_cap_t *cap_out) {
  Options Opts;
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
  Options Opts;
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

int __cheriseed_set_signal_handle_mode(const __cheriseed_cap_t *context,
                                       int mode) {
  Options Opts;
  LocalCap local_cap(Opts, context);
  local_cap.RequirePermissions(ccl::permissions::STORE)
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
void __cheriseed_static_init(void) {
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

  for (ssize idx = 0; idx < glo_init_stop - glo_init_start; ++idx) {
    if (!glo_init_start[idx].cap)
      continue;
    Options Opts;
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
  Options Opts;
  return LocalCap(Opts, cap)
      .RequirePermissions(CheckPermsToCCL(perms))
      .RequireBounds(size)
      .GetValue();
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
  Options Opts;
  LocalCap local_cap{Opts, AllowNullCap(cap_in)};
  ccl::methods::SetValue(local_cap, local_cap.GetValue() + offset);
  return local_cap.Store(cap_out);
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
  Options Opts;
  LocalCap local_cap(Opts, cap_to_cap);
  local_cap.RequirePermissions(ccl::permissions::LOAD)
      .RequireBounds(sizeof(__cheriseed_cap_t));
  if (!ccl::methods::HasPerms(
          local_cap, ccl::permissions::LOAD | ccl::permissions::LOAD_CAP)) {
    // Invalidate dereferenced
  }
  __cheriseed_cap_t *deref_cap =
      reinterpret_cast<__cheriseed_cap_t *>(local_cap.GetValue());
  return LocalCap(Opts, AllowNullCap(deref_cap), IRToCppOrdering(memory_order))
      .Store(loaded_cap);
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
  Options Opts;
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
  Options Opts;
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
  Options Opts;
  LocalCap local_cap(Opts, cap_to_cap);
  local_cap
      .RequirePermissions(ccl::permissions::STORE_CAP | ccl::permissions::STORE)
      .RequireBounds(sizeof(__cheriseed_cap_t));
  __cheriseed_cap_t *deref_cap =
      reinterpret_cast<__cheriseed_cap_t *>(local_cap.GetValue());
  LocalCap(Opts, AllowNullCap(cap_to_store))
      .Store(deref_cap, IRToCppOrdering(memory_order));
}

void __cheriseed_store_cap_hybrid(__cheriseed_cap_t *cap,
                                  const __cheriseed_cap_t *cap_to_store) {
  // All capability stores should be atomic, with default memory order
  __cheriseed_store_cap_hybrid_atomic(cap, cap_to_store, kIRRelaxedOrdering);
}

void __cheriseed_store_cap_hybrid_atomic(__cheriseed_cap_t *cap,
                                         const __cheriseed_cap_t *cap_to_store,
                                         u8 memory_order) {
  Options Opts;
  LocalCap(Opts, AllowNullCap(cap_to_store))
      .Store(cap, IRToCppOrdering(memory_order));
}

__cheriseed_cap_t *__cheriseed_thread_pointer(__cheriseed_cap_t *cap) {
  Options Opts;
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
