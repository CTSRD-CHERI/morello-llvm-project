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
// Library, included in cheriseed_ccl_interface.h. These interface
// functions should be used to modify any capabilities, as nothing should be
// assumed about the representation of a compressed capability.
//
//===----------------------------------------------------------------------===//

#ifndef CHERISEED_CCL_INTERFACE_H
#define CHERISEED_CCL_INTERFACE_H

#ifndef CHERISEED_LOCAL_CAP_H
#error "CCL interface should be included via cheriseed_local_cap.h"
#endif

#include "cheriseed_abi_defs.h"

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

// Forward declarations.
struct cc128_cap;

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
using length128_t = unsigned __int128;

// cheri-compressed-cap library requires a few libc features.

// memset only sets 'struct cc128_cap', but we can't use '__builtin_memset' and
// '__sanitizer::internal_memset' has a comment which discourages use on
// performance critical paths. In addition, the latter one is always a call.
//
// Therefore we map 'memset' to '__cheriseed_memset_cc128_cap' which is a
// horribly naive implementation, but it will get optimized away by the
// compiler in release builds.
static ALWAYS_INLINE void __cheriseed_memset_cc128_cap(struct cc128_cap *s,
                                                       int c, size_t n) {
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

// Force inlining CCL functions, if requested.
#ifdef CHERISEED_CCL_CONFIG_FORCE_INLINE_ALL
static ALWAYS_INLINE void cc128_decompress_raw(uint64_t, uint64_t, bool,
                                               struct cc128_cap *);
static ALWAYS_INLINE void cc128_decompress_mem(uint64_t, uint64_t, bool,
                                               struct cc128_cap *);
static ALWAYS_INLINE uint64_t cc128_compress_raw(const struct cc128_cap *);
static ALWAYS_INLINE uint64_t cc128_compress_mem(const struct cc128_cap *);
static ALWAYS_INLINE uint64_t cc128_get_alignment_mask(uint64_t);
static ALWAYS_INLINE uint64_t cc128_get_representable_length(uint64_t);
static ALWAYS_INLINE bool cc128_is_representable_cap_exact(
    const struct cc128_cap *);
static ALWAYS_INLINE bool cc128_setbounds_impl(struct cc128_cap *, uint64_t,
                                               length128_t, uint64_t *);
#endif  // CHERISEED_CCL_CONFIG_FORCE_INLINE_ALL

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
  static constexpr __sanitizer::u64 __name = CC128_PERM_##__name;
// Compile time constants for each supported permission
FOREACH_CCL_PERMISSION(PERM_CONSTEXPR)
#undef PERM_CONSTEXP

// Compile time constant for read permission
static constexpr __sanitizer::u64 READ_CAP_PERMS = LOAD | LOAD_CAP;
// Compile time constant for write permission
static constexpr __sanitizer::u64 WRITE_CAP_PERMS = STORE | STORE_CAP;
// Compile time constant for ALL permissions representation
#define PERM_ALL_BUILDER(__name) __name |
static constexpr __sanitizer::u64 ALL =
    FOREACH_CCL_PERMISSION(PERM_ALL_BUILDER) 0;
#undef PERM_ALL_BUILDER

#define CHECK_PERMISSION_VALUE(__perm)                                   \
  static_assert(                                                         \
      ccl::permissions::__perm == __cheriseed::abi::Permissions::__perm, \
      "Mismatching value for permission " #__perm);

FOREACH_CCL_PERMISSION(CHECK_PERMISSION_VALUE)
#undef CHECK_PERMISSION_VALUE

}  // namespace permissions

/// Adapter to the cheri-compressed-cap library.
template <typename U>
struct Adapter {
  using u32 = __sanitizer::u32;
  using u64 = __sanitizer::u64;

  /// This is necessary for macro expansion
  using cc128_length_t = external::cc128_length_t;

  /// Generates a maximum capability from a value using the CCL. The
  /// permissions of a "maximum" capability will only include the subset
  /// of CCL permissions currently supported by cheriseed.
  ///
  /// \param[out] user Reference to an object that will contain the maximum
  /// capability.
  /// \param[in] value Sets the value field of the resulting capability.
  static ALWAYS_INLINE void BuildMaxCap(U &user, u64 value) {
    external::cc128_cap_t max_cap =
        external::cc128_make_max_perms_cap(0, value, CC128_MAX_LENGTH);
    external::cc128_update_perms(&max_cap, permissions::ALL);
    user.SetValue(value);
    user.SetMetadata(Compress(&max_cap));
    user.SetTag();
  }

  /// Generates a maximum capability from a pointer using the CCL.
  /// The address provided will be cast to an unsigned 64 bit int
  ///
  /// \param[out] user Reference to an object that will contain the
  /// maximum capability.
  /// \param[in] ptr Sets the value field of the resulting capability.
  template <typename T>
  static ALWAYS_INLINE void BuildMaxCap(U &user, T *ptr) {
    BuildMaxCap(user, reinterpret_cast<u64>(ptr));
  }

  /// Generates a bounded capability using the CCL. The base will be the
  /// same as the input value, and the top equal to value + size.
  /// A permissions mask can optionally be provided, otherwise the perms
  /// will be set to maximum.
  ///
  /// \param[out] user Reference to an object that will contain the output
  /// capability.
  /// \param[in] value Sets the value/base fields of the resulting capability.
  /// \param[in] size Sets the top field of the resulting capability.
  /// \param[in] perms Sets the permissions field of the resulting capability.
  ///
  /// \returns True if resulting bounded capability is exact, else false.
  static ALWAYS_INLINE bool BuildBoundedCap(U &user, u64 value, u64 size,
                                            u64 perms = permissions::ALL) {
    external::cc128_cap_t max_cap =
        external::cc128_make_max_perms_cap(value, value, value + size);
    external::cc128_update_perms(&max_cap, permissions::ALL & perms);
    user.SetValue(value);
    user.SetMetadata(Compress(&max_cap));
    // TODO: what should we do if not exact?
    bool is_exact = external::cc128_is_representable_cap_exact(&max_cap);
    user.SetTag();
    return is_exact;
  }

  /// Generates a bounded capability from a pointer using the CCL.
  /// The address provided will be cast to an unsigned 64 bit int,
  /// and used as the cursor and the base. The size will be the size
  /// of the pointer type.
  /// A permissions mask can optionally be provided, otherwise the perms
  /// will be set to maximum.
  ///
  /// \param[out] user Reference to an object that will contain the
  /// maximum capability.
  /// \param[in] ptr Used as the value field of the resulting capability.
  /// \param[in] perms Sets the permissions field of the resulting capability.
  ///
  /// \returns True if resulting bounded capability is exact, else false.
  template <typename T>
  static ALWAYS_INLINE bool BuildBoundedCap(U &user, T *ptr,
                                            u64 perms = permissions::ALL) {
    return BuildBoundedCap(user, reinterpret_cast<u64>(ptr), sizeof(T), perms);
  }

  /// Calculates the base of the encoded range in a compressed capability
  /// metadata.
  ///
  /// \param[in] user The compressed capability.
  ///
  /// \returns The 64-bit base value.
  static ALWAYS_INLINE u64 GetBase(const U &user) {
    return Decompress(user).base();
  }

  /// Calculates the top of the encoded range in a compressed capability
  /// metadata.
  ///
  /// \note This field is 128 bits so length64 returns min(top, UINT64_MAX).
  ///
  /// \param[in] user The compressed capability.
  ///
  /// \returns The 64-bit top value.
  static ALWAYS_INLINE u64 GetTop(const U &user) {
    return Decompress(user).top64();
  }

  /// Calculates the length of the range encoded in a compressed capability
  /// metadata.
  ///
  /// \note This field is 128 bits so length64 returns min(length, UINT64_MAX).
  ///
  /// \param[in] user The compressed capability.
  ///
  /// \returns The saturated 64-bit length value.
  static ALWAYS_INLINE u64 GetLength(const U &user) {
    return Decompress(user).length64();
  }

  /// Calculates the offset encoded in a compressed capability metadata.
  ///
  /// \note This field is 128 bits so length64 returns min(offset, UINT64_MAX).
  ///
  /// \param[in] user The compressed capability.
  ///
  /// \returns The saturated offset from the capability's base value.
  static ALWAYS_INLINE u64 GetOffset(const U &user) {
    const external::cc128_offset_t offset = Decompress(user).offset();
    // Create equivalent to offset64() which doesn't exist.
    return static_cast<u64>(offset > CC128_MAX_ADDR ? CC128_MAX_ADDR : offset);
  }

  /// Extracts the permissions bits encoded in a compressed capability metadata.
  ///
  /// \param[in] user The compressed capability.
  ///
  /// \returns The permissions field extracted from the compressed metadata.
  static ALWAYS_INLINE u64 GetPermissions(const U &user) {
    // It is possible to directly get the permission bits without decompression.
    return external::cc128_cap_pesbt_extract_perms(user.GetMetadata());
  }

  /// Extracts the type bits encoded in a compressed capability metadata.
  ///
  /// \param[in] user The compressed capability.
  ///
  /// \returns The type field extracted from the compressed metadata.
  static ALWAYS_INLINE u64 GetType(const U &user) {
    return Decompress(user).type();
  }

  /// Tests if a compressed capability is a sealed or not.
  ///
  /// \param[in] user The compressed capability.
  ///
  /// \returns True if the capability is sealed, otherwise false.
  static ALWAYS_INLINE bool IsSealed(const U &user) {
    return Decompress(user).is_sealed();
  }

  /// Tests if a capability is representable with a given cursor.
  ///
  /// \param[in] user The compressed capability.
  /// \param[in] cursor The requested new cursor to test.
  ///
  /// \returns True if the capability would be representable, otherwise false.
  static ALWAYS_INLINE bool IsRepresentableWithCursor(const U &user,
                                                      u64 cursor) {
    auto decom_cap = Decompress(user);
    return external::cc128_is_representable_with_addr(&decom_cap, cursor);
  }

  /// Sets the value of a capability, potentially clearing its tag.
  ///
  /// \param[in] user The compressed capability whose value to update.
  /// \param[in] value The requested value to set.
  static ALWAYS_INLINE void SetValue(U &user, u64 value) {
    if (UNLIKELY(!IsRepresentableWithCursor(user, value)))
      user.ClearTag();
    user.SetValue(value);
  }

  /// Sets the permissions field of a compressed metadata to bitwise AND with
  /// some mask.
  ///
  /// \param[in] user The compressed capability whose permissions to update.
  /// \param[in] mask A mask specifying permissions to retain.
  static ALWAYS_INLINE void ReducePermissions(U &user, u64 mask) {
    u32 permissions = static_cast<u32>(GetPermissions(user) & mask);
    // It is possible to directly set the permission bits without recompression.
    u64 metadata = external::cc128_cap_pesbt_deposit_perms(user.GetMetadata(),
                                                           permissions);
    user.SetMetadata(metadata);
  }

  /// Sets the bounds of a compressed capability, potentially clearing its tag.
  ///
  /// \param[in] user The compressed capability to update.
  /// \param[in] base The requested base value.
  /// \param[in] top The requested top value.
  /// \param[in] needs_exact True if exact representation is requested.
  ///
  /// \returns True, if the bounds are representable, otherwise false.
  static ALWAYS_INLINE bool SetBounds(U &user, u64 base, u64 top,
                                      bool needs_exact) {
    auto decom_cap = Decompress(user);
    bool is_exact = external::cc128_setbounds(&decom_cap, base, top);
    if (UNLIKELY(!is_exact && needs_exact))
      user.ClearTag();
    user.SetMetadata(Compress(&decom_cap));
    return is_exact;
  }

  /// Compares two compressed capabilities for equality.
  ///
  /// \param[in] user_lhs First compressed capability to compare.
  /// \param[in] user_rhs Second compressed capability to compare.
  ///
  /// \returns True if exactly the two capabilities are exactly equal, otherwise
  /// false.
  static ALWAYS_INLINE bool ExactlyEqual(const U &user_lhs, const U &user_rhs) {
    auto decom_cap_lhs = Decompress(user_lhs);
    auto decom_cap_rhs = Decompress(user_rhs);
    return external::cc128_exactly_equal(&decom_cap_lhs, &decom_cap_rhs);
  }

  /// Tests if a capability is a subset of another capability.
  ///
  /// \param[in] user_check the compressed capability to check.
  /// \param[in] user The compressed capability to check against.
  ///
  /// \returns True if compressed_cap_check is a subset of user,
  /// otherwise false.
  static ALWAYS_INLINE bool SubsetTest(const U &user_check, const U &user) {
    const bool tag_is_sub = (user_check.IsTagged() >= user.IsTagged());
    const bool base_is_sub = (user_check.GetBase() >= user.GetBase());
    const bool top_is_sub = (user_check.GetTop() <= user.GetTop());
    const bool perms_is_sub =
        ((user_check.GetPermissions() & user.GetPermissions()) ==
         user_check.GetPermissions());
    return (tag_is_sub && base_is_sub && top_is_sub && perms_is_sub);
  }

  /// Returns the alignment mask that should be taken into account to precisely
  /// represent a capability with bounds "length" apart.
  ///
  /// \param[in] length The desired allocation length.
  ///
  /// \returns A 64 bit mask.
  static ALWAYS_INLINE u64 GetAlignmentMask(u64 length) {
    return external::cc128_get_alignment_mask(length);
  }

  /// Rounds a proposed bounds length to a rounded size that can be precisely
  /// represented.
  ///
  /// \param[in] length A proposed bounds length for a capability.
  ///
  /// \returns A rounded bounds length that can be precisely represented.
  static ALWAYS_INLINE u64 GetRepresentableLength(u64 length) {
    return external::cc128_get_representable_length(length);
  }

 protected:
  static ALWAYS_INLINE external::cc128_cap_t Decompress(const U &user) {
    external::cc128_cap_t decom_cap;
    external::cc128_decompress_mem(user.GetMetadata(), user.GetValue(),
                                   user.IsTagged(), &decom_cap);
    return decom_cap;
  }

  static ALWAYS_INLINE u64 Compress(const external::cc128_cap_t *decom_cap) {
    return external::cc128_compress_mem(decom_cap);
  }
};  // struct Adapter

}  // namespace ccl

#endif  // CHERISEED_CCL_INTERFACE_H
