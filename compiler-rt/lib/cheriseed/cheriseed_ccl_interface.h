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

#include "cheriseed_common.h"
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

// Required types
using uint8_t = __sanitizer::u8;
using uint16_t = __sanitizer::u16;
using uint32_t = __sanitizer::u32;
using uint64_t = __sanitizer::u64;
using int64_t = __sanitizer::s64;
using size_t = __sanitizer::ssize;

// cheri-compressed-cap library requires a few libc features.

// memset only sets 'struct cc128_cap', but we can't use '__builtin_memset' and
// '__sanitizer::internal_memset' has a comment which discourages use on
// performance critical paths. In addition, the latter one is always a call.
//
// Therefore we map 'memset' to '__cheriseed_memset_cc128_cap' which is a
// horribly naive implementation, but it will get optimized away by the
// compiler in release builds.
struct cc128_cap;
static void __cheriseed_memset_cc128_cap(struct cc128_cap *s, int c, size_t n) {
  char *ptr = reinterpret_cast<char *>(s);
  char *const max_ptr = ptr + n;
  const char v = static_cast<char>(c);
  while (ptr < max_ptr) *ptr++ = v;
}

#define memset __cheriseed_memset_cc128_cap

// cheri-compressed-cap library uses 'assert'.
// It is undesired to hit an assert in CCL, even if the values don't make sense.
// It can happen that an untagged capability is queried, in which case the RT
// would still need to return some value without asserting.
// This does not depend on the value of COMPILER_RT_DEBUG.
#undef assert
#define assert(__cond)
#define cheri_debug_assert(__cond) assert(__cond)

// End of libc features.

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

#undef memset
#undef cheri_debug_assert

// Redefine assert so that anyone using this header will know that it has been
// disabled.
#undef assert
#define assert assert_is_disabled_in_cheriseed_ccl_interface_h

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

#define CHECK_PERMISSION_VALUE(__perm)                                   \
  static_assert(                                                         \
      ccl::permissions::__perm == __cheriseed::abi::Permissions::__perm, \
      "Mismatching value for permission " #__perm);

FOREACH_CCL_PERMISSION(CHECK_PERMISSION_VALUE)
#undef CHECK_PERMISSION_VALUE

}  // namespace permissions

/// Interface to the cheri-compressed-cap library.
struct methods {
  /// This is necessary for macro expansion
  using cc128_length_t = external::cc128_length_t;

  /// Generates a maximum capability from a value using the CCL. The
  /// permissions of a "maximum" capability will only include the subset
  /// of CCL permissions currently supported by cheriseed.
  ///
  /// \param[out] local_cap Reference to an object that will contain the maximum
  /// capability.
  /// \param[in] value Sets the value field of the resulting capability.
  static inline void BuildMaxCap(LocalCap &local_cap, u64 value) {
    external::cc128_cap_t max_cap =
        external::cc128_make_max_perms_cap(0, value, CC128_MAX_LENGTH);
    external::cc128_update_perms(&max_cap, permissions::ALL);
    local_cap.SetValue(value);
    local_cap.SetMetadata(external::cc128_compress_mem(&max_cap));
    local_cap.SetTag();
  }

  /// Generates a maximum capability from a pointer using the CCL.
  /// The address provided will be cast to an unsigned 64 bit int
  ///
  /// \param[out] local_cap Reference to an object that will contain the maximum
  /// capability.
  /// \param[in] ptr Sets the value field of the resulting capability.
  template <typename T>
  static inline void BuildMaxCap(LocalCap &local_cap, T *ptr) {
    BuildMaxCap(local_cap, reinterpret_cast<u64>(ptr));
  }

  /// Generates a bounded capability using the CCL. The base will be the
  /// same as the input value, and the top equal to value + size.
  /// A permissions mask can optionally be provided, otherwise the perms
  /// will be set to maximum.
  ///
  /// \param[out] local_cap Reference to an object that will contain the output
  /// capability.
  /// \param[in] value Sets the value/base fields of the resulting capability.
  /// \param[in] size Sets the top field of the resulting capability.
  /// \param[in] perms Sets the permissions field of the resulting
  /// capability.
  /// \returns True if resulting bounded capability is exact, else false.
  static inline bool BuildBoundedCap(LocalCap &local_cap, u64 value, u64 size,
                                     u64 perms = permissions::ALL) {
    external::cc128_cap_t max_cap =
        external::cc128_make_max_perms_cap(value, value, value + size);
    external::cc128_update_perms(&max_cap, permissions::ALL & perms);
    local_cap.SetValue(value);
    local_cap.SetMetadata(external::cc128_compress_mem(&max_cap));
    // TODO: what should we do if not exact?
    bool is_exact = external::cc128_is_representable_cap_exact(&max_cap);
    local_cap.SetTag();
    return is_exact;
  }

  /// Generates a bounded capability from a pointer using the CCL.
  /// The address provided will be cast to an unsigned 64 bit int,
  /// and used as the cursor and the base. The size will be the size
  /// of the pointer type.
  /// A permissions mask can optionally be provided, otherwise the perms
  /// will be set to maximum.
  ///
  /// \param[out] local_cap Reference to an object that will contain the maximum
  /// capability.
  /// \param[in] ptr Used as the value field of the resulting capability.
  /// \param[in] perms Sets the permissions field of the resulting
  /// capability.
  /// \returns True if resulting bounded capability is exact, else false.
  template <typename T>
  static inline bool BuildBoundedCap(LocalCap &local_cap, T *ptr,
                                     u64 perms = permissions::ALL) {
    return BuildBoundedCap(local_cap, reinterpret_cast<u64>(ptr), sizeof(T),
                           perms);
  }

  /// Extracts the permissions bits from a compressed metadata.
  ///
  /// \param[in] local_cap The compressed capability to extract permissions
  /// from.
  /// \returns The permissions field extracted from the compressed metadata.
  static inline u64 GetPerms(const LocalCap &local_cap) {
    return external::cc128_cap_pesbt_extract_perms(local_cap.GetMetadata());
  }

  /// Queries a compressed capability for permissions bits.
  ///
  /// \param[in] local_cap The compressed capability to extract permissions
  /// from.
  /// \param[in] mask The permission bits that must be present to return true.
  /// \returns True if all permissions in mask are present in local_cap, else
  /// false.
  static inline bool HasPerms(const LocalCap &local_cap, const u64 mask) {
    return ((GetPerms(local_cap) & mask) == mask);
  }

  /// Sets the permissions field of a compressed metadata to bitwise AND with
  /// some mask.
  ///
  /// \param[in] local_cap The compressed capability whose permissions to
  /// update.
  /// \param[in] mask A mask specifying permissions to retain.
  static inline void PermsAnd(LocalCap &local_cap, const u64 mask) {
    local_cap.SetMetadata(external::cc128_cap_pesbt_deposit_perms(
        local_cap.GetMetadata(), static_cast<u32>(GetPerms(local_cap) & mask)));
  }

  /// Returns the alignment mask that should be taken into account to precisely
  /// represent a capability with bounds "length" apart.
  ///
  /// \param[in] length The desired allocation length.
  /// \returns A 64 bit mask.
  static inline u64 GetAlignmentMask(u64 length) {
    return external::cc128_get_alignment_mask(length);
  }

  /// Rounds a proposed bounds length to a rounded size that can be precisely
  /// represented.
  ///
  /// \param[in] length A proposed bounds length for a capability.
  /// \returns A rounded bounds length that can be precisely represented.
  static inline u64 GetRepresentableLength(u64 length) {
    return external::cc128_get_representable_length(length);
  }

  /// Compares two compressed capabilities for equality.
  ///
  /// \param[in] local_cap_1 First compressed capability to compare.
  /// \param[in] local_cap_2 Second compressed capability to compare.
  /// \returns Single boolean, true if exactly equal, false otherwise.
  static inline bool ExactlyEqual(const LocalCap &local_cap_1,
                                  const LocalCap &local_cap_2) {
    external::cc128_cap_t decom_cap_1;
    external::cc128_cap_t decom_cap_2;
    external::cc128_decompress_mem(local_cap_1.GetMetadata(),
                                   local_cap_1.GetValue(),
                                   local_cap_1.IsTagged(), &decom_cap_1);
    external::cc128_decompress_mem(local_cap_2.GetMetadata(),
                                   local_cap_2.GetValue(),
                                   local_cap_2.IsTagged(), &decom_cap_2);
    return external::cc128_exactly_equal(&decom_cap_1, &decom_cap_2);
  }

  /// Retrieves the length field of a compressed cap. This field is 128 bits so
  /// length64 returns min(length, UINT64_MAX).
  ///
  /// \param[in] local_cap The compressed capability to retrieve the length
  /// from.
  /// \returns 64 bit length value.
  static inline u64 GetLength(const LocalCap &local_cap) {
    external::cc128_cap_t decom;
    external::cc128_decompress_mem(local_cap.GetMetadata(),
                                   local_cap.GetValue(), local_cap.IsTagged(),
                                   &decom);
    return decom.length64();
  }

  /// Retrieves the base field of a compressed cap.
  ///
  /// \param[in] local_cap The compressed capability to retrieve the base from.
  /// \returns 64 bit base value.
  static inline u64 GetBase(const LocalCap &local_cap) {
    external::cc128_cap_t decom;
    external::cc128_decompress_mem(local_cap.GetMetadata(),
                                   local_cap.GetValue(), local_cap.IsTagged(),
                                   &decom);
    return decom.base();
  }

  /// Retrieves the calculated top value of a compressed cap.
  ///
  /// \param[in] local_cap The compressed capability to retrieve the top from.
  /// \returns 64 bit base value.
  static inline u64 GetTop(const LocalCap &local_cap) {
    external::cc128_cap_t decom;
    external::cc128_decompress_mem(local_cap.GetMetadata(),
                                   local_cap.GetValue(), local_cap.IsTagged(),
                                   &decom);
    return decom.top64();
  }

  /// Extracts the offset from a compressed metadata.
  ///
  /// \param[in] local_cap The compressed capability to retrieve the offset
  /// from.
  /// \returns The offset from the capability's base value.
  static inline u64 GetOffset(const LocalCap &local_cap) {
    external::cc128_cap_t decom;
    external::cc128_decompress_mem(local_cap.GetMetadata(),
                                   local_cap.GetValue(), local_cap.IsTagged(),
                                   &decom);
    const external::cc128_offset_t offset = decom.offset();
    // Create equivalent to offset64() which doesn't exist
    return offset > CC128_MAX_ADDR ? CC128_MAX_ADDR : (u64)offset;
  }

  /// Tests if a capability is representable with a given cursor.
  ///
  /// \param[in] local_cap The compressed capability to test.
  /// \param[in] cursor The requested new cursor to test.
  /// \returns True if the capability is representable, otherwise false.
  static inline bool IsRepresentableWithCursor(const LocalCap &local_cap,
                                               u64 cursor) {
    external::cc128_cap_t decom;
    external::cc128_decompress_mem(local_cap.GetMetadata(),
                                   local_cap.GetValue(), local_cap.IsTagged(),
                                   &decom);
    return external::cc128_is_representable_with_addr(&decom, cursor);
  }

  /// Sets the value of a capability.
  ///
  /// \param[in] local_cap The compressed capability to update.
  /// \param[in] value The requested value to set.
  static inline void SetValue(LocalCap &local_cap, u64 value) {
    if (UNLIKELY(!IsRepresentableWithCursor(local_cap, value)))
      local_cap.ClearTag();
    local_cap.SetValue(value);
  }

  /// Sets the bounds of a compressed capability.
  ///
  /// \param[in] local_cap The compressed capability to update.
  /// \param[in] base The requested base value.
  /// \param[in] top The requested top value.
  /// \param[in] needs_exact True if exact representation is requested.
  /// \param[out] is_exact Bool set true only if the output metadata has exactly
  ///             the requested bounds, otherwise false.
  /// \returns 64 bit base value.
  static inline void SetBounds(LocalCap &local_cap, u64 base, u64 top,
                               bool needs_exact, bool &is_exact) {
    external::cc128_cap_t decom;
    external::cc128_decompress_mem(local_cap.GetMetadata(),
                                   local_cap.GetValue(), local_cap.IsTagged(),
                                   &decom);
    is_exact = external::cc128_setbounds(&decom, base, top);
    if (UNLIKELY(!is_exact && needs_exact))
      local_cap.ClearTag();
    local_cap.SetMetadata(external::cc128_compress_mem(&decom));
  }

  /// Extracts the type bits from a compressed metadata.
  ///
  /// \param[in] local_cap The compressed capability to retrieve the type from.
  /// \returns The type field extracted from the compressed metadata.
  static inline u64 GetType(const LocalCap &local_cap) {
    external::cc128_cap_t decom;
    external::cc128_decompress_mem(local_cap.GetMetadata(),
                                   local_cap.GetValue(), local_cap.IsTagged(),
                                   &decom);
    return decom.type();
  }

  /// Tests if a capability is a subset of another capability.
  ///
  /// \param[in] local_cap_check the compressed capability to check.
  /// \param[in] local_cap the compressed capability to check against.
  /// \returns True if local_cap_check is a subset of local_cap, otherwise
  /// false.
  static inline bool SubsetTest(const LocalCap &local_cap_check,
                                const LocalCap &local_cap) {
    external::cc128_cap_t decom_check;
    external::cc128_cap_t decom;
    external::cc128_decompress_mem(local_cap_check.GetMetadata(),
                                   local_cap_check.GetValue(),
                                   local_cap_check.IsTagged(), &decom_check);
    external::cc128_decompress_mem(local_cap.GetMetadata(),
                                   local_cap.GetValue(), local_cap.IsTagged(),
                                   &decom);

    return (decom_check.cr_tag >= decom.cr_tag) &&
           (decom_check.base() >= decom.base()) &&
           (decom_check.top() <= decom.top()) &&
           ((decom_check.permissions() & decom.permissions()) ==
            decom_check.permissions());
  }

  /// Tests if a capability is a sealed capability.
  ///
  /// \param[in] local_cap the compressed capability to check.
  /// \returns True if local_cap is a sealed, otherwise
  /// false.
  static inline bool IsSealed(const LocalCap &local_cap) {
    external::cc128_cap_t decom;
    external::cc128_decompress_mem(local_cap.GetMetadata(),
                                   local_cap.GetValue(), local_cap.IsTagged(),
                                   &decom);
    return decom.is_sealed();
  }
};  // struct methods

}  // namespace ccl

#endif  // CHERISEED_CCL_INTERFACE_H
