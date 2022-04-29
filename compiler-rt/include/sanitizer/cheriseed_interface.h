//===-- sanitizer/cheriseed_interface.h -------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// This is the public CHERIseed interface header.
//
// APIs appear in this file in the following order:
//   1. Mappings of CHERI intrinsics
//   2. Additional user-accessible APIs
//   3. APIs used by the compiler
//
//===----------------------------------------------------------------------===//

#ifndef SANITIZER_CHERISEED_INTERFACE_H
#define SANITIZER_CHERISEED_INTERFACE_H

#include <sanitizer/common_interface_defs.h>

#ifdef __cplusplus
extern "C" {
#endif

/// \brief Definition of a capability
///
/// This structure is how CHERIseed represents a capability in memory.
typedef struct {
  /// The current value of the capability.
  uint64_t value;
  /// Compressed metadata, which includes bounds, permissions, etc.
  uint64_t metadata;
} __cheriseed_cap_t __attribute__((aligned(16)));

/// Check that other headers support SEGV_CAPTAGERR
#ifdef SEGV_CAPTAGERR
#warning "SEGV_CAPTAGERR is defined, CHERIseed is likely \
not going to deliver the expected si_code values."
#endif

/// Attempted to dereference an untagged capability.
#ifndef SEGV_CAPTAGERR
#define SEGV_CAPTAGERR ((int)1000)
#endif
/// Attempted an out-of-bounds access.
#ifndef SEGV_CAPBOUNDSERR
#define SEGV_CAPBOUNDSERR ((int)1001)
#endif
/// Attempted an access without the required permissions.
#ifndef SEGV_CAPPERMERR
#define SEGV_CAPPERMERR ((int)1002)
#endif

/// The violation is fatal and the reason is printed to stderr.
#define CHERISEED_SIGNAL_HANDLE_MODE_DEFAULT ((int)1)
/// The violation is fatal, no details is printed to stderr.
#define CHERISEED_SIGNAL_HANDLE_MODE_SILENT ((int)2)
/// Ignore the violation.
#define CHERISEED_SIGNAL_HANDLE_MODE_IGNORE ((int)3)
/// The violation is not fatal, but print the reason to stderr.
#define CHERISEED_SIGNAL_HANDLE_MODE_WARNING ((int)4)

// -------------------------------------
// Mappings of CHERI intrinsics
// -------------------------------------

/// Returns a capability derived from the input capability, with base address
/// set to the value of the input capability, and the length set to a given
/// value.
///
/// \note This is the equivalent of @c llvm.cheri.bounded.stack.cap intrinsic.
///
/// \param[out] cap_out Pointer to the output capability.
/// \param[in] cap_in Pointer to the input capability.
/// \param[in] length Length to set for the output capability.
/// \returns The first argument, \p cap_out .
__cheriseed_cap_t *
__cheriseed_bounded_stack_cap(__cheriseed_cap_t *cap_out,
                              const __cheriseed_cap_t *cap_in, uint64_t length);

/// Returns the value, or cursor, of a capability.
///
/// \note This is the equivalent of @c llvm.cheri.cap.address.get intrinsic,
/// which @c __builtin_cheri_address_get gets lowered to.
///
/// \param[in] cap Pointer to a capability.
/// \returns The value of the capability.
uint64_t __cheriseed_address_get(const __cheriseed_cap_t *cap);

/// Sets the value, or cursor, of a capability.
///
/// \note This is the equivalent of @c llvm.cheri.cap.address.set intrinsic,
/// which @c __builtin_cheri_address_set gets lowered to. Furthermore,
/// @c llvm.cheri.cap.from.pointer and
/// @c llvm.cheri.cap.from.pointer.nonnull.zero use this to implement their
/// functionality.
///
/// \param[out] cap_out Pointer to the output capability.
/// \param[in] cap_in Pointer to the input capability.
/// \param[in] address Address to set for the output capability.
/// \returns The first argument, \p cap_out .
__cheriseed_cap_t *__cheriseed_address_set(__cheriseed_cap_t *cap_out,
                                           const __cheriseed_cap_t *cap_in,
                                           uint64_t address);

/// Returns the base address of the capability.
///
/// \note This is the equivalent of @c llvm.cheri.cap.base.get intrinsic,
/// which @c __builtin_cheri_base_get gets lowered to.
///
/// \param[in] cap Pointer to a capability.
/// \returns The base address of the capability.
uint64_t __cheriseed_base_get(const __cheriseed_cap_t *cap);

/// Sets the bounds of a capability.
///
/// Please note in the presence of compressed capabilities, not all possible
/// 64-bit values of length will be representable.
///
/// \note This is the equivalent of @c llvm.cheri.cap.bounds.set intrinsic,
/// which @c __builtin_cheri_bounds_set gets lowered to.
///
/// \param[out] cap_out Pointer to the output capability.
/// \param[in] cap_in Pointer to the input capability.
/// \param[in] length Length to set for the output capability.
/// \returns The first argument, \p cap_out .
__cheriseed_cap_t *__cheriseed_bounds_set(__cheriseed_cap_t *cap_out,
                                          const __cheriseed_cap_t *cap_in,
                                          uint64_t length);

/// Precisely sets the bounds of a capability.
///
/// This sets the bounds to precisely the value provided, whether or not they
/// are representable. This in contrast to `__cheriseed_bounds_set`, which
/// asserts that the final capability is representable. If precise bounds
/// setting is not possible, either the bounds are rounded, or the
/// capability is invalidated.
///
/// Please note: in the presence of compressed capabilities, not all possible
/// 64-bit values of length will be representable
///
/// \note This is the equivalent of @c llvm.cheri.cap.bounds.set.exact
/// intrinsic, which @c __builtin_cheri_bounds_set_exact gets lowered to.
///
/// \param[out] cap_out Pointer to the output capability.
/// \param[in] cap_in Pointer to the input capability.
/// \param[in] length Length to set for the output capability.
/// \returns The first argument, \p cap_out .
__cheriseed_cap_t *__cheriseed_bounds_set_exact(__cheriseed_cap_t *cap_out,
                                                const __cheriseed_cap_t *cap_in,
                                                uint64_t length);

/// Builds a capability from an untagged and possibly sealed bit pattern.
///
/// \note This is the equivalent of @c llvm.cheri.cap.build intrinsic,
/// which @c __builtin_cheri_cap_build gets lowered to.
///
/// \param[out] cap_out Pointer to the output capability.
/// \param[in] cap_in Pointer to the input capability.
/// \param[in] cap_value Some bit pattern to interpret as a capability.
/// \returns The first argument, \p cap_out .
__cheriseed_cap_t *__cheriseed_build(__cheriseed_cap_t *cap_out,
                                     const __cheriseed_cap_t *cap_in,
                                     const __cheriseed_cap_t *cap_value);

/// Seals a capability if the sealing capability's object type allows this
/// operation.
///
/// \note This is the equivalent of @c llvm.cheri.cap.conditional.seal
/// intrinsic, which @c __builtin_cheri_conditional_seal gets lowered to.
///
/// \param[out] cap_out Pointer to the conditionally sealed capability.
/// \param[in] cap_in Pointer to the capability to seal.
/// \param[in] cap_seal Pointer to a sealing capability.
/// \returns The first argument, \p cap_out .
__cheriseed_cap_t *
__cheriseed_conditional_seal(__cheriseed_cap_t *cap_out,
                             const __cheriseed_cap_t *cap_in,
                             const __cheriseed_cap_t *cap_seal);

/// Returns the highest 64 bits of a capability.
///
/// \note
/// This is the equivalent of @c llvm.cheri.cap.copy.from.high intrinsic,
/// which @c __builtin_cheri_copy_from_high gets lowered to.
///
/// \param[in] cap Pointer to a capability.
/// \returns The highest 64 bits of the capability.
uint64_t __cheriseed_copy_from_high(const __cheriseed_cap_t *cap);

/// Sets the highest 64 bits of capability to a given value.
///
/// \note This is the equivalent of @c llvm.cheri.cap.copy.to.high intrinsic,
/// which @c __builtin_cheri_copy_to_high gets lowered to.
///
/// \param[out] cap_out Pointer to the output capability.
/// \param[in] cap_in Pointer to the input capability.
/// \param[in] value A 64-bit value to copy to the high bits.
/// \returns The first argument, \p cap_out .
__cheriseed_cap_t *__cheriseed_copy_to_high(__cheriseed_cap_t *cap_out,
                                            const __cheriseed_cap_t *cap_in,
                                            uint64_t value);
/// Returns the difference between capabilities.
///
/// \note This is the equivalent of @c llvm.cheri.cap.diff intrinsic.
///
/// \param[in] cap1 Pointer to a capability.
/// \param[in] cap2 Pointer to a capability.
/// \returns Difference between capability values.
uint64_t __cheriseed_diff(const __cheriseed_cap_t *cap_left,
                          const __cheriseed_cap_t *cap_right);

/// Checks if the the capabilities are bitwise identical.
///
/// \note This is the equivalent of @c llvm.cheri.cap.equal.exact intrinsic,
/// which @c __builtin_cheri_equal_exact gets lowered to.
///
/// \param[in] cap_left Pointer to a capability.
/// \param[in] cap_right Pointer to a capability.
/// \returns @c 1 if the two capabilities are identical, @c 0 otherwise.
uint8_t __cheriseed_equal_exact(const __cheriseed_cap_t *cap_left,
                                const __cheriseed_cap_t *cap_right);

/// Returns the flags of a capability.
///
/// \note This is the equivalent of @c llvm.cheri.cap.flags.get intrinsic,
/// which @c __builtin_cheri_flags_get gets lowered to.
///
/// \param[in] cap Pointer to the input capability.
/// \returns The flags of the capability.
uint64_t __cheriseed_flags_get(const __cheriseed_cap_t *cap);

/// Sets the flags of a capability.
///
/// \note This is the equivalent of @c llvm.cheri.cap.flags.set intrinsic,
/// which @c __builtin_cheri_flags_set gets lowered to.
///
/// \param[out] cap_out Pointer to the output capability.
/// \param[in] cap_in Pointer to the input capability.
/// \param[in] flags Flags to set for the output capability.
/// \returns The first argument, \p cap_out .
__cheriseed_cap_t *__cheriseed_flags_set(__cheriseed_cap_t *cap_out,
                                         const __cheriseed_cap_t *cap_in,
                                         uint64_t flags);

// Note: llvm.cheri.cap.from.pointer and
// llvm.cheri.cap.from.pointer.nonnull.zero are not implemented.

/// Returns the length of the segment capability references.
///
/// \note This is the equivalent of @c llvm.cheri.cap.length.get intrinsic,
/// which @c __builtin_cheri_length_get gets lowered to.
///
/// \param[in] cap Pointer to a capability.
/// \returns The 64 bit length of the segment the capability describes.
uint64_t __cheriseed_length_get(const __cheriseed_cap_t *cap);

/// Loads capability tags from memory pointed by a capability.
///
/// \note This is the equivalent of @c llvm.cheri.cap.load.tags intrinsic,
/// which @c __builtin_cheri_cap_load_tags gets lowered to.
///
/// \param[in] cap Pointer to a capability.
//// \returns Loaded capability tags.
uint64_t __cheriseed_load_tags(const __cheriseed_cap_t *cap);

/// Returns the offset of a capability.
///
/// \note This is the equivalent of @c llvm.cheri.cap.offset.get intrinsic,
/// which @c __builtin_cheri_offset_get gets lowered to.
///
/// \param[in] cap Pointer to a capability.
/// \returns The offset of the capability.
uint64_t __cheriseed_offset_get(const __cheriseed_cap_t *cap);

/// Sets the offset of a capability.
///
/// \note This is the equivalent of @c llvm.cheri.cap.offset.set intrinsic,
/// which @c __builtin_cheri_offset_set gets lowered to.
///
/// \param[out] cap_out Pointer to the output capability.
/// \param[in] cap_in Pointer to the input capability.
/// \param[in] offset The offset value to set the field to.
/// \returns The first argument, \p cap_out .
__cheriseed_cap_t *__cheriseed_offset_set(__cheriseed_cap_t *cap_out,
                                          const __cheriseed_cap_t *cap_in,
                                          uint64_t offset);

/// Retains only the selected permissions of a capability.
///
/// \note This is the equivalent of @c llvm.cheri.cap.perms.and intrinsic,
/// which @c __builtin_cheri_perms_and gets lowered to.
///
/// \param[out] cap_out Pointer to the output capability.
/// \param[in] cap_in Pointer to the input capability.
/// \param[in] mask Mask of permissions to clear.
/// \returns The first argument, \p cap_out .
__cheriseed_cap_t *__cheriseed_perms_and(__cheriseed_cap_t *cap_out,
                                         const __cheriseed_cap_t *cap_in,
                                         uint64_t mask);

/// Checks if a capability has all permissions in a given bit mask.
///
/// \note This is the equivalent of @c llvm.cheri.cap.perms.check intrinsic,
/// which @c __builtin_cheri_perms_check gets lowered to.
///
/// \param[in] cap Pointer to a capability.
/// \param mask Mask of permissions to check for.
/// \returns @c 1 if it the capability has all \p mask permissions,
/// @c 0 otherwise.
void __cheriseed_perms_check(const __cheriseed_cap_t *cap, uint64_t mask);

/// Returns the permissions of a capability.
///
/// \note This is the equivalent of @c llvm.cheri.cap.perms.get intrinsic,
/// which @c __builtin_cheri_perms_get gets lowered to.
///
/// \param[in] cap Pointer to a capability.
/// \returns The permissions of the capability.
uint64_t __cheriseed_perms_get(const __cheriseed_cap_t *cap);

/// Seal a capability with a sealing capability.
///
/// \note This is the equivalent of @c llvm.cheri.cap.seal intrinsic,
/// which @c __builtin_cheri_seal gets lowered to.
///
/// \param[out] cap_out Pointer to the output capability.
/// \param[in] cap_in Pointer to the input capability.
/// \param[in] cap_seal Pointer to a sealing capability.
/// \returns The first argument, \p cap_out .
__cheriseed_cap_t *__cheriseed_seal(__cheriseed_cap_t *cap_out,
                                    const __cheriseed_cap_t *cap_in,
                                    const __cheriseed_cap_t *cap_seal);

/// Seals a capability with an implementation defined object type.
///
/// \note This is the equivalent of @c llvm.cheri.cap.seal.entry intrinsic,
/// which @c __builtin_cheri_seal_entry gets lowered to.
///
/// \param[out] cap_out Pointer to the output capability.
/// \param[in] cap_in Pointer to the input capability.
/// \returns The first argument, \p cap_out .
__cheriseed_cap_t *__cheriseed_seal_entry(__cheriseed_cap_t *cap_out,
                                          const __cheriseed_cap_t *cap_in);

/// Returns a value indicating if a capability is sealed.
///
/// \note This is the equivalent of @c llvm.cheri.cap.sealed.get intrinsic,
/// which @c __builtin_cheri_sealed_get gets lowered to.
///
/// \param[in] cap Pointer to a capability.
/// \returns @c 1 if the capability is sealed, @c 0 otherwise.
uint8_t __cheriseed_sealed_get(const __cheriseed_cap_t *cap);

/// Checks if a capability is a subset of another capability.
///
/// \note This is the equivalent of @c llvm.cheri.cap.subset.test intrinsic,
/// which @c __builtin_cheri_subset_test gets lowered to.
///
/// \param[in] cap_tested Pointer to a capability to test.
/// \param[in] cap Pointer to a testing capability.
/// \returns @c 1 if the \p cap_tested is a subset of \p cap, @c 0 otherwise.
uint8_t __cheriseed_subset_test(const __cheriseed_cap_t *cap_tested,
                                const __cheriseed_cap_t *cap);

/// Clears the tag of a capability.
///
/// \note This is the equivalent of @c llvm.cheri.cap.tag.clear intrinsic,
/// which @c __builtin_cheri_tag_clear gets lowered to.
///
/// \param[out] cap_out Pointer to the output capability.
/// \param[in] cap_in Pointer to the input capability.
/// \returns The first argument, \p cap_out .
__cheriseed_cap_t *__cheriseed_tag_clear(__cheriseed_cap_t *cap_out,
                                         const __cheriseed_cap_t *cap_in);

/// Returns the state of the tag of a capability.
///
/// \note This is the equivalent of @c llvm.cheri.cap.tag.get intrinsic,
/// which @c __builtin_cheri_tag_get gets lowered to.
///
/// \param[in] cap Pointer to a capability.
/// \returns @c 1 if the capability is tagged, @c 0 otherwise.
uint8_t __cheriseed_tag_get(const __cheriseed_cap_t *cap);

/// Converts a capability to a relative integer pointer.
///
/// \note This is the equivalent of @c llvm.cheri.cap.to.pointer intrinsic,
/// which @c __builtin_cheri_cap_to_pointer gets lowered to.
///
/// \param[in] cap Capability to be converted.
/// \returns Relative integer pointer.
uint64_t __cheriseed_to_pointer(const __cheriseed_cap_t *cap);

/// Check the type of the capability.
///
/// \note This is the equivalent of @c llvm.cheri.cap.type.check intrinsic,
/// which @c __builtin_cheri_type_check gets lowered to.
///
/// \param[in] cap Pointer to a capability.
/// \param[in] type Capability type to compare against.
void __cheriseed_type_check(const __cheriseed_cap_t *cap,
                            const __cheriseed_cap_t *type);

/// Copies the object type of a capability to another capability.
///
/// \note This is the equivalent of @c llvm.cheri.cap.type.copy intrinsic,
/// which @c __builtin_cheri_type_copy gets lowered to.
///
/// \param[out] cap_out Pointer to the output capability with type set.
/// \param[in] cap_in Pointer to the input capability whose type to set.
/// \param[in] cap_type Pointer to a capability to copy the type from.
/// \returns The first argument, \p cap_out .
__cheriseed_cap_t *__cheriseed_type_copy(__cheriseed_cap_t *cap_out,
                                         const __cheriseed_cap_t *cap_in,
                                         const __cheriseed_cap_t *cap_type);

/// Returns the object type of a capability.
///
/// \note This is the equivalent of @c llvm.cheri.cap.type.get intrinsic,
/// which @c __builtin_cheri_type_get gets lowered to.
///
/// \param[in] cap Pointer to a capability.
/// \returns The 64-bit object type.
uint64_t __cheriseed_type_get(const __cheriseed_cap_t *cap);

/// Unseal a capability with an unsealing capability.
///
/// \note This is the equivalent of @c llvm.cheri.cap.unseal intrinsic,
/// which @c __builtin_cheri_unseal gets lowered to.
///
/// \param[out] cap_out Pointer to the output capability.
/// \param[in] cap_in Pointer to the input capability.
/// \param[in] cap_unseal Pointer to an unsealing capability.
/// \returns The first argument, \p cap_out .
__cheriseed_cap_t *__cheriseed_unseal(__cheriseed_cap_t *cap_out,
                                      const __cheriseed_cap_t *cap_in,
                                      const __cheriseed_cap_t *cap_unseal);

/// Returns the Default Data Capability (DDC).
///
/// \note This is the equivalent of @c llvm.cheri.ddc.get intrinsic,
/// which @c __builtin_cheri_global_data_get gets lowered to.
///
/// \param[out] cap_out Pointer to a capability.
/// \returns The first argument, \p cap_out .
__cheriseed_cap_t *__cheriseed_ddc_get(__cheriseed_cap_t *cap_out);

/// Returns the Program Counter Capability (PCC).
///
/// \note This is the equivalent of @c llvm.cheri.pcc.get intrinsic,
/// which @c __builtin_cheri_program_counter_get gets lowered to.
///
/// \param[out] cap_out Pointer to a capability.
/// \returns The first argument, \p cap_out .
__cheriseed_cap_t *__cheriseed_pcc_get(__cheriseed_cap_t *cap_out);

/// Returns a mask that can be used on a capability value to set representable
/// bounds.
///
/// \note This is the equivalent of @c llvm.cheri.representable.alignment.mask
/// intrinsic, which @c __builtin_cheri_representable_alignment_mask
/// gets lowered to.
///
/// \param[in] mask Mask to be rounded to a representable value.
/// \returns Representable mask.
uint64_t __cheriseed_representable_alignment_mask(uint64_t mask);

/// Round the input length to the capability precision.
///
/// \note This is the equivalent of @c llvm.cheri.round.representable.length
/// intrinsic, which @c __builtin_cheri_round_representable_length
/// gets lowered to.
///
/// \param[in] length Length to be rounded to a representable value.
/// \returns Representable length.
uint64_t __cheriseed_round_representable_length(uint64_t length);

/// Returns the Stack Capability.
///
/// \note This is the equivalent of @c llvm.cheri.stack.cap.get intrinsic,
/// which @c __builtin_cheri_stack_get gets lowered to.
///
/// \param[out] cap_out Pointer to a capability.
/// \returns The first argument, \p cap_out .
__cheriseed_cap_t *__cheriseed_stack_cap_get(__cheriseed_cap_t *cap_out);

// -------------------------------------
// Additional user-accessible APIs
// -------------------------------------

/// Enables or disables  CHERI semantics, which are disabled by default.
///
/// \param[in] enable 0: disable, otherwise enable.
void __cheriseed_enable_cheri_semantics(int enable);

/// Returns the string representation of a capability violation signal.
///
/// \param[in] code The error code to translate.
/// \returns A pointer to the string representation of the error.
const char *__cheriseed_strerror(int code);

/// Sets the way the violation is handled once the signal handler returns.
///
/// \warning This function should only be called from a signal handler and
/// only when handling a capability violation signal.
///
/// \param[inout] context The 3rd argument passed to the signal handler.
/// \param[in] mode The preferred mode of handling of the violation.
/// \returns Zero if mode was valid, otherwise non-zero.
int __cheriseed_set_signal_handle_mode(void *context, int mode);

/// Enables or disables invocation of signal handlers upon capability
/// violation.
///
/// \param[in] enable Signal handlers will not be called if enable is '0',
/// otherwise the runtime will try to call them directly.
void __cheriseed_enable_invoke_signal_handlers(int enable);

// -------------------------------------
// APIs used by the compiler
// -------------------------------------

/// Copy and offset the address of the resulting capability.
///
/// \note This API is defined exclusively by CHERIseed and does not
/// map to any CHERI intrinsics.
///
/// \param[out] cap_out Pointer to the output capability.
/// \param[in] cap_in Pointer to the input capability.
/// \param[in] offset
/// \returns The first argument, \p cap_out .
__cheriseed_cap_t *
__cheriseed_copy_cap_with_offset(__cheriseed_cap_t *cap_out,
                                 const __cheriseed_cap_t *cap_in,
                                 uint64_t offset);

/// Initialize an on stack capability with another pointer from the stack.
///
/// \note This API is defined exclusively by CHERIseed and does not
/// map to any CHERI intrinsics.
///
/// \param[in, out] cap Capability to initialize, non-null.
/// \param[in] address Address to initialize the capability with.
/// Doesn't alias \p cap.
/// \param[in] size The size of the object pointed to by the capability.
/// \returns The first argument, \p cap .
__cheriseed_cap_t *__cheriseed_stack_cap_init(__cheriseed_cap_t *cap,
                                              uint64_t address, uint64_t size);

/// Loads a capability from a memory location described by a capability.
///
/// \note This API is defined exclusively by CHERIseed and does not
/// map to any CHERI intrinsics.
///
/// \param[in] cap Pointer to a capability to load from.
/// \param[out] loaded_cap Pointer to a capability to write the loaded
/// capability to.
/// \returns The second argument, \p loaded_cap .
__cheriseed_cap_t *__cheriseed_load_cap(const __cheriseed_cap_t *cap,
                                        __cheriseed_cap_t *loaded_cap);

/// Loads a capability from a memory location described by a pointer.
///
/// \note This API is defined exclusively by CHERIseed and does not
/// map to any CHERI intrinsics.
///
/// \param[in] ptr Pointer to load from.
/// \param[out] loaded_cap Pointer to a capability to write the loaded
/// capability to.
/// \returns The second argument, \p loaded_cap .
__cheriseed_cap_t *__cheriseed_load_cap_hybrid(const __cheriseed_cap_t *ptr,
                                               __cheriseed_cap_t *loaded_cap);

/// Stores a capability to a memory location described by a capability.
///
/// \note This API is defined exclusively by CHERIseed and does not
/// map to any CHERI intrinsics.
///
/// \param[in] cap Pointer to a capability to store to.
/// \param[in] stored_cap Pointer to a capability to store \p cap to.
void __cheriseed_store_cap(__cheriseed_cap_t *cap,
                           const __cheriseed_cap_t *stored_cap);

/// Stores a capability to a memory location described by a pointer.
///
/// \note This API is defined exclusively by CHERIseed and does not
/// map to any CHERI intrinsics.
///
/// \param[in] ptr Pointer to store to.
/// \param[in] stored_cap Pointer to a capability to store \p ptr to.
void __cheriseed_store_cap_hybrid(__cheriseed_cap_t *ptr,
                                  const __cheriseed_cap_t *stored_cap);

/// Checks if an access with a capability has the correct permissions
/// and is in-bounds.
///
/// \note This API is defined exclusively by CHERIseed and does not
/// map to any CHERI intrinsics.
///
/// \param[in] cap Pointer to a capability.
/// \param[in] size The size of the access to be made.
/// \param[in] perms Requested permissions for the access.
/// \returns The value of \p cap .
uint64_t __cheriseed_check_access(const __cheriseed_cap_t *cap, uint64_t size,
                                  uint32_t perms);

/// Returns the thread pointer as a capability.
///
/// \note This API is defined exclusively by CHERIseed and does not
/// map to any CHERI intrinsics.
///
/// \param[out] cap_out Pointer to a capability.
/// \returns The first argument, \p cap .
__cheriseed_cap_t *__cheriseed_thread_pointer(__cheriseed_cap_t *cap);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // SANITIZER_CHERISEED_INTERFACE_H
