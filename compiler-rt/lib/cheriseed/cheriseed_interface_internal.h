//===-- cheriseed_interface_internal.h --------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// This is the private CHERIseed interface header.
//
//===----------------------------------------------------------------------===//

#ifndef CHERISEED_INTERFACE_INTERNAL_H
#define CHERISEED_INTERFACE_INTERNAL_H

#include "cheriseed_common.h"

using __cheriseed::__cheriseed_cap_t;
using __cheriseed::__cheriseed_cmpxchg_result_t;

extern "C" {

// -------------------------------------
// Mappings of CHERI intrinsics
// -------------------------------------

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_bounded_stack_cap(
    __cheriseed_cap_t *cap_out, const __cheriseed_cap_t *cap_in, u64 ptr);

SANITIZER_INTERFACE_ATTRIBUTE
u64 __cheriseed_address_get(const __cheriseed_cap_t *cap);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_address_set(__cheriseed_cap_t *cap_out,
                                           const __cheriseed_cap_t *cap_in,
                                           u64 address);
SANITIZER_INTERFACE_ATTRIBUTE
u64 __cheriseed_base_get(const __cheriseed_cap_t *cap);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_bounds_set(__cheriseed_cap_t *cap_out,
                                          const __cheriseed_cap_t *cap_in,
                                          u64 length);
SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_bounds_set_exact(__cheriseed_cap_t *cap_out,
                                                const __cheriseed_cap_t *cap_in,
                                                u64 length);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_build(__cheriseed_cap_t *cap_out,
                                     const __cheriseed_cap_t *cap_in,
                                     const __cheriseed_cap_t *cap_value);
SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_conditional_seal(
    __cheriseed_cap_t *cap_out, const __cheriseed_cap_t *cap_in,
    const __cheriseed_cap_t *cap_seal);

SANITIZER_INTERFACE_ATTRIBUTE
u64 __cheriseed_copy_from_high(const __cheriseed_cap_t *cap);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_copy_to_high(__cheriseed_cap_t *cap_out,
                                            const __cheriseed_cap_t *cap_in,
                                            u64 value);
SANITIZER_INTERFACE_ATTRIBUTE
u64 __cheriseed_diff(const __cheriseed_cap_t *cap_left,
                     const __cheriseed_cap_t *cap2);

SANITIZER_INTERFACE_ATTRIBUTE
u8 __cheriseed_equal_exact(const __cheriseed_cap_t *cap_left,
                           const __cheriseed_cap_t *cap2);

SANITIZER_INTERFACE_ATTRIBUTE
u64 __cheriseed_flags_get(const __cheriseed_cap_t *cap);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_flags_set(__cheriseed_cap_t *cap_out,
                                         const __cheriseed_cap_t *cap_in,
                                         u64 flags);

SANITIZER_INTERFACE_ATTRIBUTE
u64 __cheriseed_length_get(const __cheriseed_cap_t *cap);

SANITIZER_INTERFACE_ATTRIBUTE
u64 __cheriseed_load_tags(const __cheriseed_cap_t *cap);

SANITIZER_INTERFACE_ATTRIBUTE
u64 __cheriseed_offset_get(const __cheriseed_cap_t *cap);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_offset_set(__cheriseed_cap_t *cap_out,
                                          const __cheriseed_cap_t *cap_in,
                                          u64 offset);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_perms_and(__cheriseed_cap_t *cap_out,
                                         const __cheriseed_cap_t *cap_in,
                                         u64 mask);
SANITIZER_INTERFACE_ATTRIBUTE
void __cheriseed_perms_check(const __cheriseed_cap_t *cap, u64 mask);

SANITIZER_INTERFACE_ATTRIBUTE
u64 __cheriseed_perms_get(const __cheriseed_cap_t *cap);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_seal(__cheriseed_cap_t *cap_out,
                                    const __cheriseed_cap_t *cap_in,
                                    const __cheriseed_cap_t *cap_seal);
SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_seal_entry(__cheriseed_cap_t *cap_out,
                                          const __cheriseed_cap_t *cap_in);

SANITIZER_INTERFACE_ATTRIBUTE
u8 __cheriseed_sealed_get(const __cheriseed_cap_t *cap);

SANITIZER_INTERFACE_ATTRIBUTE
u8 __cheriseed_subset_test(const __cheriseed_cap_t *cap_tested,
                           const __cheriseed_cap_t *cap);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_tag_clear(__cheriseed_cap_t *cap_out,
                                         const __cheriseed_cap_t *cap_in);

SANITIZER_INTERFACE_ATTRIBUTE
u8 __cheriseed_tag_get(const __cheriseed_cap_t *cap);

SANITIZER_INTERFACE_ATTRIBUTE
u64 __cheriseed_to_pointer(const __cheriseed_cap_t *cap);

SANITIZER_INTERFACE_ATTRIBUTE
void __cheriseed_type_check(const __cheriseed_cap_t *cap1,
                            const __cheriseed_cap_t *type);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_type_copy(__cheriseed_cap_t *cap_out,
                                         const __cheriseed_cap_t *cap_in,
                                         const __cheriseed_cap_t *cap_type);

SANITIZER_INTERFACE_ATTRIBUTE
u64 __cheriseed_type_get(const __cheriseed_cap_t *cap);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_unseal(__cheriseed_cap_t *cap_out,
                                      const __cheriseed_cap_t *cap_in,
                                      const __cheriseed_cap_t *cap_unseal);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_ddc_get(__cheriseed_cap_t *cap);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_pcc_get(__cheriseed_cap_t *cap);

SANITIZER_INTERFACE_ATTRIBUTE
u64 __cheriseed_representable_alignment_mask(u64 length);

SANITIZER_INTERFACE_ATTRIBUTE
u64 __cheriseed_round_representable_length(u64 length);

SANITIZER_INTERFACE_ATTRIBUTE
void __cheriseed_stack_cap_get(__cheriseed_cap_t *cap);

// -------------------------------------
// Additional user-accessible APIs
// -------------------------------------

SANITIZER_INTERFACE_ATTRIBUTE
void __cheriseed_clear_all_tags(const __cheriseed_cap_t *cap, u64 size);

SANITIZER_INTERFACE_ATTRIBUTE
void __cheriseed_copy_all_tags(const __cheriseed_cap_t *cap_to,
                               const __cheriseed_cap_t *cap_from, u64 size);

SANITIZER_INTERFACE_ATTRIBUTE
void __cheriseed_lock_and_copy_all_tags(const __cheriseed_cap_t *cap_to,
                                        const __cheriseed_cap_t *cap_from,
                                        u64 size);

SANITIZER_INTERFACE_ATTRIBUTE
void __cheriseed_control_semantics(u8 enable);

SANITIZER_INTERFACE_ATTRIBUTE
void __cheriseed_control_invoke_signal_handlers(u8 enable);

SANITIZER_INTERFACE_ATTRIBUTE
void __cheriseed_control_checks(u8 enable, u64 checks);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_strerror(__cheriseed_cap_t *result, int code);

SANITIZER_INTERFACE_ATTRIBUTE
int __cheriseed_set_signal_handle_mode(__cheriseed_cap_t *context, int mode);

SANITIZER_INTERFACE_ATTRIBUTE
void __cheriseed_static_init(u64 sp);

SANITIZER_INTERFACE_ATTRIBUTE
void __cheriseed_relocate(u64 init_start, u64 init_stop);

// -------------------------------------
// APIs used by the compiler
// -------------------------------------

SANITIZER_INTERFACE_ATTRIBUTE
u64 __cheriseed_check_access(const __cheriseed_cap_t *cap, u64 size, u32 perms,
                             u64 masked_checks);

SANITIZER_INTERFACE_ATTRIBUTE
void __cheriseed_check_access_end(u64 address, u64 size);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cmpxchg_result_t __cheriseed_cmpxchg_cap(
    __cheriseed_cap_t *cap_to_cap, const __cheriseed_cap_t *cap_expected,
    const __cheriseed_cap_t *cap_desired, __cheriseed_cap_t *cap_orig,
    u8 memory_order_success, u8 memory_order_failure, u64 masked_checks);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cmpxchg_result_t __cheriseed_cmpxchg_cap_hybrid(
    __cheriseed_cap_t *cap, const __cheriseed_cap_t *cap_expected,
    const __cheriseed_cap_t *cap_desired, __cheriseed_cap_t *cap_orig,
    u8 memory_order_success, u8 memory_order_failure);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_copy_cap_with_offset(
    __cheriseed_cap_t *cap_out, const __cheriseed_cap_t *cap_in, u64 offset);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_generic_cap_init(__cheriseed_cap_t *cap,
                                                u64 address, u64 size,
                                                u32 perms_to_clear);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_load_cap(const __cheriseed_cap_t *cap_to_cap,
                                        __cheriseed_cap_t *loaded_cap,
                                        u64 masked_checks);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_load_cap_atomic(
    const __cheriseed_cap_t *cap_to_cap, __cheriseed_cap_t *loaded_cap,
    u8 memory_order, u64 masked_checks);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_load_cap_hybrid(const __cheriseed_cap_t *cap,
                                               __cheriseed_cap_t *loaded_cap);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_load_cap_hybrid_atomic(
    const __cheriseed_cap_t *cap, __cheriseed_cap_t *loaded_cap,
    u8 memory_order);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_rmw_cap(__cheriseed_cap_t *cap_to_cap,
                                       const __cheriseed_cap_t *cap_value,
                                       __cheriseed_cap_t *cap_ret, u8 op,
                                       u8 memory_order, u64 masked_checks);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_rmw_cap_hybrid(
    __cheriseed_cap_t *cap, const __cheriseed_cap_t *cap_value,
    __cheriseed_cap_t *cap_ret, u8 op, u8 memory_order);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_stack_cap_init(__cheriseed_cap_t *cap,
                                              u64 address, u64 size);

SANITIZER_INTERFACE_ATTRIBUTE
void __cheriseed_store_cap(__cheriseed_cap_t *cap_to_cap,
                           const __cheriseed_cap_t *cap_to_store,
                           u64 masked_checks);

SANITIZER_INTERFACE_ATTRIBUTE
void __cheriseed_store_cap_atomic(__cheriseed_cap_t *cap_to_cap,
                                  const __cheriseed_cap_t *cap_to_store,
                                  u8 memory_order, u64 masked_checks);

SANITIZER_INTERFACE_ATTRIBUTE
void __cheriseed_store_cap_hybrid(__cheriseed_cap_t *cap,
                                  const __cheriseed_cap_t *cap_to_store);

SANITIZER_INTERFACE_ATTRIBUTE
void __cheriseed_store_cap_hybrid_atomic(__cheriseed_cap_t *cap,
                                         const __cheriseed_cap_t *cap_to_store,
                                         u8 memory_order);

SANITIZER_INTERFACE_ATTRIBUTE
__cheriseed_cap_t *__cheriseed_thread_pointer(__cheriseed_cap_t *cap);

}  // extern "C"

#endif  // CHERISEED_INTERFACE_INTERNAL_H
