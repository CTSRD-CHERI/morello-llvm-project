//===-- cheriseed_ccl_interface.h -------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// This header provides interface functions to the Capability Compression
// Library, included in cheriseed_ccl_interface.cpp. These interface
// functions should be used to modify any capabilities, as nothing should be
// assumed about the representation of a compressed capability.
//
//===----------------------------------------------------------------------===//

#ifndef CHERISEED_CCL_INTERFACE_H
#define CHERISEED_CCL_INTERFACE_H

#include "cheriseed_abi_defs.h"
#include "sanitizer_common/sanitizer_libc.h"

// The ccl namespace contains functions allowing manipulation of capabilities,
// via the Capability Compression Library header, which is included inside the
// ccl::external namespace.
//
// This setup allows our interface functions to be declared inline, while still
// easily identifying when an incorrect function has been used in the
// compiler-rt.
//
// The ccl::external namespace should not be used outside of function
// definitions in this file.
namespace ccl {
namespace external {

// Sanitizers have a very constrained environment.
// Provide some types and definitions for cheri-compressed-cap library.
#ifndef UINT64_C
#define CC_UINT64_C_DEFINED
#define UINT64_C __UINT64_C
#endif

#ifndef NULL
#define CC_NULL_DEFINED
#define NULL 0
#endif

#ifndef assert
#define CC_assert_DEFINED
#define assert DCHECK
#endif

// cheri-compressed-cap library requires a few libc features.
// Replace these with their sanitizer-equivalent ones.
#define memset __sanitizer::internal_memset
#define cheri_debug_assert assert

// Required types
using uint8_t = __sanitizer::u8;
using uint16_t = __sanitizer::u16;
using uint32_t = __sanitizer::u32;
using uint64_t = __sanitizer::u64;
using int64_t = __sanitizer::s64;
using size_t = __sanitizer::ssize;

#include "cheri_compressed_cap_128.h"

// Do not pollute the namespace where this header is included in.
#ifdef CC_UINT64_C_DEFINED
#undef CC_UINT64_C_DEFINED
#undef UINT64_C
#endif

#ifdef CC_NULL_DEFINED
#undef CC_NULL_DEFINED
#undef NULL
#endif

#ifdef CC_assert_DEFINED
#undef CC_assert_DEFINED
#undef assert
#endif

#undef memset
#undef cheri_debug_assert
}  // namespace external

// Macro for running an expression on all supported permissions
#define FOREACH_CCL_PERMISSION(V) \
  V(LOAD)                         \
  V(STORE)                        \
  V(EXECUTE)                      \
  V(LOAD_CAP)                     \
  V(STORE_CAP)

namespace permissions {
// Macro to declare a compile time constant for a permission bit
#define PERM_CONSTEXPR(__name) \
  static constexpr u64 __name = CC128_PERM_##__name;
// Compile time constants for each supported permission
FOREACH_CCL_PERMISSION(PERM_CONSTEXPR)
#undef PERM_CONSTEXP

// Compile time constant for read permission
static constexpr u64 READ_CAP_PERMS = LOAD | LOAD_CAP;
// Compile time constant for write permission
static constexpr u64 WRITE_CAP_PERMS = STORE | STORE_CAP;
// Compile time constant for ALL permissions representation
#define PERM_ALL_BUILDER(__name) __name |
static constexpr u64 ALL = FOREACH_CCL_PERMISSION(PERM_ALL_BUILDER) 0;
#undef PERM_ALL_BUILDER

}  // namespace permissions

// This is necessary for macro expansion
using cc128_length_t = external::cc128_length_t;
using compressed_cap_t = __cheriseed::__cheriseed_cap_t;

// The null capability has a value of 0, and 0 metadata by definition
static constexpr compressed_cap_t kNullCap = {0, 0};

/// Generate a maximum capability from a value using the CCL. The
/// permissions of a "maximum" capability will only include the subset
/// of CCL permissions currently supported by cheriseed.
///
/// \param[out] cap_out A pointer that will contain the max capability
/// \param[in] value Sets the value field of the resulting capability
static inline void BuildMaxCap(compressed_cap_t *cap_out, u64 value) {
  cap_out->value = value;
  external::cc128_cap_t max_cap =
      external::cc128_make_max_perms_cap(0, value, CC128_MAX_LENGTH);
  external::cc128_update_perms(&max_cap, permissions::ALL);
  cap_out->metadata = external::cc128_compress_mem(&max_cap);
}

/// Generate a maximum capability from a pointer using the CCL.
/// The address provided will be cast to an unsigned 64 bit int
///
/// \param[out] cap_out A pointer that will contain the max capability
/// \param[in] ptr Sets the value field of the resulting capability
template <typename T>
static inline void BuildMaxCap(compressed_cap_t *cap_out, T *ptr) {
  BuildMaxCap(cap_out, reinterpret_cast<u64>(ptr));
}

/// Generate a bounded capability using the CCL. The base will be the
/// same as the input value, and the top equal to value + size.
/// A permissions mask can optionally be provided, otherwise the perms
/// will be set to maximum.
///
/// \param[out] cap_out A pointer that will contain the output capability
/// \param[in] value Sets the value/base fields of the resulting capability
/// \param[in] size Sets the top field of the resulting capability
/// \param[in] perms_mask Sets the permissions field of the resulting capability
/// \returns True if resulting bounded capability is exact, else false
static inline bool BuildBoundedCap(compressed_cap_t *cap_out, u64 value,
                                   u64 size,
                                   u64 perms_mask = permissions::ALL) {
  cap_out->value = value;
  external::cc128_cap_t max_cap =
      external::cc128_make_max_perms_cap(value, value, value + size);
  external::cc128_update_perms(&max_cap, permissions::ALL & perms_mask);
  cap_out->metadata = external::cc128_compress_mem(&max_cap);
  return external::cc128_is_representable_cap_exact(&max_cap);
}

/// Generate a bounded capability from a pointer using the CCL.
/// The address provided will be cast to an unsigned 64 bit int,
/// and used as the cursor and the base. The size will be the size
/// of the pointer type.
/// A permissions mask can optionally be provided, otherwise the perms
/// will be set to maximum.
///
/// \param[out] cap_out A pointer that will contain the max capability
/// \param[in] ptr Used as the value field of the resulting capability
/// \param[in] perms_mask Sets the permissions field of the resulting capability
/// \returns True if resulting bounded capability is exact, else false
template <typename T>
static inline bool BuildBoundedCap(compressed_cap_t *cap_out, T *ptr,
                                   u64 perms_mask = permissions::ALL) {
  return BuildBoundedCap(cap_out, reinterpret_cast<u64>(ptr), sizeof(T),
                         perms_mask);
}

/// Set a capability pointer to the address of the global null capability
///
/// \param[out] cap_out Will point to the address of the Null Capability
static inline void UseNullCap(const compressed_cap_t **cap_out) {
  *cap_out = &kNullCap;
}

/// Extract the permissions bits from a compressed metadata
///
/// \param[in] c_cap The compressed capability to extract permissions from
/// \returns The permissions field extracted from the compressed metadata
static inline u64 PermsGet(const compressed_cap_t *c_cap) {
  return external::cc128_cap_pesbt_extract_perms(c_cap->metadata);
}

/// Query a compressed capability for permissions bits
///
/// \param[in] c_cap The compressed capability to extract permissions from
/// \param[in] mask The permission bits that must be present to return true
/// \returns True if all permissions in mask are present in c_cap, else false
static inline bool HasPerms(const compressed_cap_t *c_cap, const u64 mask) {
  return ((PermsGet(c_cap) & mask) == mask);
}

/// Set the permissions field of a compressed metadata to bitwise AND with some
/// mask
///
/// \param[in] c_cap The compressed capability to update with the CCL
/// \param[in] mask A mask specifying permissions to retain
static inline void UpdatePermsAnd(compressed_cap_t *c_cap, const u64 mask) {
  c_cap->metadata = external::cc128_cap_pesbt_deposit_perms(
      c_cap->metadata, static_cast<u32>(PermsGet(c_cap) & mask));
}

/// Returns the alignment mask that should be taken into account to precisely
/// represent a capability with bounds "length" apart.
///
/// \param[in] length The desired allocation length
/// \returns A 64 bit mask
static inline u64 GetAlignmentMask(u64 length) {
  return external::cc128_get_alignment_mask(length);
}

/// Rounds a proposed bounds length to a rounded size that can be precisely
/// represented,
///
/// \param[in] length A proposed bounds length for a capability
/// \returns A rounded bounds length that can be precisely represented
static inline u64 GetRepresentableLength(u64 length) {
  return external::cc128_get_representable_length(length);
}

/// Compare two compressed capabilities for equality
///
/// \param[in] c_cap1 First compressed capability
/// \param[in] c_cap2 Second compressed capability
/// \returns Single boolean, true if exactly equal, false otherwise
static inline bool ExactlyEqual(const compressed_cap_t *c_cap1,
                                const compressed_cap_t *c_cap2) {
  external::cc128_cap_t dc_cap1;
  external::cc128_cap_t dc_cap2;
  external::cc128_decompress_mem(c_cap1->metadata, c_cap1->value, true,
                                 &dc_cap1);
  external::cc128_decompress_mem(c_cap2->metadata, c_cap2->value, true,
                                 &dc_cap2);
  return external::cc128_exactly_equal(&dc_cap1, &dc_cap2);
}

/// Retrieve the length field of a compressed cap. This field is 128 bits so
/// length64 returns min(length,UINT64_MAX).
///
/// \param[in] c_cap The compressed capability to retrieve the length from
/// \returns 64 bit length value
static inline u64 GetLength(const compressed_cap_t *c_cap) {
  external::cc128_cap_t decom;
  external::cc128_decompress_mem(c_cap->metadata, c_cap->value, true, &decom);
  return decom.length64();
}

/// Retrieve the base field of a compressed cap.
///
/// \param[in] c_cap The compressed capability to retrieve the base from
/// \returns 64 bit base value
static inline u64 GetBase(const compressed_cap_t *c_cap) {
  external::cc128_cap_t decom;
  external::cc128_decompress_mem(c_cap->metadata, c_cap->value, true, &decom);
  return decom.base();
}

/// Retrieve the calculated top value of a compressed cap.
///
/// \param[in] c_cap The compressed capability to retrieve the top from
/// \returns 64 bit base value
static inline u64 GetTop(const compressed_cap_t *c_cap) {
  external::cc128_cap_t decom;
  external::cc128_decompress_mem(c_cap->metadata, c_cap->value, true, &decom);
  return decom.top64();
}

/// Extracts the offset from a compressed metadata
///
/// \param[in] c_cap The compressed capability to retrieve the offset from
/// \returns The offset from the capability's base value
static inline u64 GetOffset(const compressed_cap_t *c_cap) {
  external::cc128_cap_t decom;
  external::cc128_decompress_mem(c_cap->metadata, c_cap->value, true, &decom);
  const external::cc128_offset_t offset = decom.offset();
  // Create equivalent to offset64() which doesn't exist
  return offset > CC128_MAX_ADDR ? CC128_MAX_ADDR : (u64)offset;
}

/// Set the bounds of a compressed capability
///
/// \param[in] c_cap The compressed capability to update
/// \param[in] new_base The requested base value
/// \param[in] new_top The requested top value
/// \param[out] isExact Bool set true only if the output metadata has exactly
///             the requested bounds, otherwise false
/// \returns 64 bit base value
static inline void SetBounds(compressed_cap_t *c_cap, u64 new_base, u64 new_top,
                             bool &exact_res) {
  external::cc128_cap_t decom;
  external::cc128_decompress_mem(c_cap->metadata, c_cap->value, true, &decom);
  exact_res = external::cc128_setbounds(&decom, new_base, new_top);
  c_cap->metadata = external::cc128_compress_mem(&decom);
}

/// Extract the type bits from a compressed metadata
///
/// \param[in] c_cap The compressed capability to retrieve the type from
/// \returns The type field extracted from the compressed metadata
static inline u64 GetType(const compressed_cap_t *c_cap) {
  external::cc128_cap_t decom;
  external::cc128_decompress_mem(c_cap->metadata, c_cap->value, true, &decom);
  return decom.type();
}

/// Test if a capability is representable with a given cursor
///
/// \param[in] c_cap The compressed capability to test
/// \param[in] new_cursor The requested new cursor to test
/// \returns A boolean, true if it is representable
static inline bool IsRepresentableWithCursor(const compressed_cap_t *c_cap,
                                             u64 newCursor) {
  external::cc128_cap_t decom;
  external::cc128_decompress_mem(c_cap->metadata, c_cap->value, true, &decom);
  return external::cc128_is_representable_with_addr(&decom, newCursor);
}

/// Test if a capability is a subset of another capability.
///
/// \param[in] c_cap_check the compressed capability to check
/// \param[in] c_cap the compressed capability to check against
/// \returns A boolean, true if c_cap_check is a subset of c_cap
static inline bool SubsetTest(const compressed_cap_t *c_cap_check,
                              const compressed_cap_t *c_cap) {
  external::cc128_cap_t decom_check;
  external::cc128_cap_t decom;
  external::cc128_decompress_mem(c_cap_check->metadata, c_cap_check->value,
                                 true, &decom_check);
  external::cc128_decompress_mem(c_cap->metadata, c_cap->value, true, &decom);

  return (decom_check.base() >= decom.base()) &&
         (decom_check.top() <= decom.top()) &&
         ((decom_check.permissions() & decom.permissions()) ==
          decom_check.permissions());
  // TODO: Compare capability validity
}

}  // namespace ccl

#endif  // CHERISEED_CCL_INTERFACE_H
