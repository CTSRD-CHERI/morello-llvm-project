//===-- cheriseed_test_utils.h ----------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// The main header declaring utilities to help testing CHERIseed.
//
//===----------------------------------------------------------------------===//

#ifndef CHERISEED_TEST_UTILS_H
#define CHERISEED_TEST_UTILS_H

#if !defined(CHERISEED_UNIT_TESTING)
#include <sanitizer/cheriseed_interface.h>
#else
#include "cheriseed_interface_internal.h"
#endif

#include "cheriseed_ccl_interface.h"
#include "cheriseed_test_config.h"

#if !defined(CHERISEED_UNIT_TESTING)

/// Define __cheriseed_cap_t for testing purposes. It is still opaque, but
/// describes a well-sized and well-aligned type now.
struct __cheriseed_cap_t {
  __cheriseed_cap_t() {}

 protected:
  // Disallow copy
  __cheriseed_cap_t(const __cheriseed_cap_t &) = delete;
  __cheriseed_cap_t &operator=(__cheriseed_cap_t const &) = delete;

  uint8_t bits[16];
} ALIGNED(16);  // struct __cheriseed_cap_t

#endif  //  !CHERISEED_UNIT_TESTING

namespace utils {

// The error exit code.
static constexpr int kExitCode = 1;

// Constants for testing with integers of various size.
static constexpr uint8_t UINT8_TEST = (uint8_t)0xc3;
static constexpr uint16_t UINT16_TEST = (uint16_t)0xc3c3;
static constexpr uint32_t UINT32_TEST = (uint32_t)0xc3c3c3c3;
static constexpr uint64_t UINT64_TEST = (uint64_t)0xc3c3c3c3c3c3c3c3;
static constexpr __uint128_t UINT128_TEST =
    ((__uint128_t)0xc3c3c3c3c3c3c3c3 << 64) | 0xc3c3c3c3c3c3c3c3;

// Constants zeros for various integer widths.
static constexpr uint8_t UINT8_MIN = (uint8_t)0;
static constexpr uint16_t UINT16_MIN = (uint16_t)0;
static constexpr uint32_t UINT32_MIN = (uint32_t)0;
static constexpr uint64_t UINT64_MIN = (uint64_t)0;
static constexpr __uint128_t UINT128_MIN = (__uint128_t)0;

// clang-format off

#define ERROR_MESSAGE_HEADER_PATTERN                   \
  "Runtime Error detected by CHERIseed.*?\n\n"

#define ERROR_MESSAGE_RANGE_PATTERN     \
  ".*?0x[0-9a-f]+.*?-.*?0x[0-9a-f]+.*?"

#define ERROR_MESSAGE_CAPABILITY_PATTERN                     \
  "  .*?0x[0-9a-f]+.*?( \\[((.*?[rwxRWE].*?)+,)?"            \
  ERROR_MESSAGE_RANGE_PATTERN "\\])?"                        \
  "( \\((invalid|null capability|,)+\\))?\n\n"

#define ERROR_MESSAGE_TAG_ADDRESS_PATTERN   \
  "Tag address was at .*?0x[0-9a-f]+.*?"

#define ERROR_MESSAGE_DETAIL_PATTERN                   \
  "tid: .*?[0-9]+.*?\n"                                \
  "pc:  .*?0x[0-9a-f]+.*?\n"

#define CHECK_ADDRESS_ERROR_MESSAGE_PATTERN                       \
  ERROR_MESSAGE_HEADER_PATTERN                                    \
  "Capability address is likely invalid at .*?0x[0-9a-f]+.*?\n\n" \
  ERROR_MESSAGE_DETAIL_PATTERN

#define CHECK_ALIGNMENT_ERROR_MESSAGE_PATTERN        \
  ERROR_MESSAGE_HEADER_PATTERN                       \
  "Capability is unaligned at .*?0x[0-9a-f]+.*?\n\n" \
  ERROR_MESSAGE_DETAIL_PATTERN

#define CHECK_NOT_IMPLEMENTED_ERROR_MESSAGE_PATTERN \
  ERROR_MESSAGE_HEADER_PATTERN                      \
  "'.*?' is not implemented\n\n"                    \
  ERROR_MESSAGE_DETAIL_PATTERN

#define CHECK_IN_BOUNDS_ERROR_MESSAGE_PATTERN                                \
  ERROR_MESSAGE_HEADER_PATTERN                                               \
  "Prevented out-of-bounds access with capability at .*?0x[0-9a-f]+.*?:\n\n" \
  ERROR_MESSAGE_CAPABILITY_PATTERN                                           \
  "Requested range was " ERROR_MESSAGE_RANGE_PATTERN "\n\n"                  \
  ERROR_MESSAGE_TAG_ADDRESS_PATTERN                                          \
  ERROR_MESSAGE_DETAIL_PATTERN

#define CHECK_REQUIRED_PERMS_ERROR_MESSAGE_PATTERN                             \
  ERROR_MESSAGE_HEADER_PATTERN                                                 \
  "Capability is missing required permission\\(s\\) at .*?0x[0-9a-f]+.*?:\n\n" \
  ERROR_MESSAGE_CAPABILITY_PATTERN                                             \
  "Missing permission\\(s\\):"                                                 \
  "(\n  .*?[rwxRWE].*? \\[.*?[A-Z_]+.*?\\])+\n\n"                              \
  ERROR_MESSAGE_TAG_ADDRESS_PATTERN                                            \
  ERROR_MESSAGE_DETAIL_PATTERN

#define CHECK_IS_TAGGED_ERROR_MESSAGE_PATTERN       \
  ERROR_MESSAGE_HEADER_PATTERN                      \
  "Capability is untagged at .*?0x[0-9a-f]+.*?\n\n" \
  ERROR_MESSAGE_CAPABILITY_PATTERN                  \
  ERROR_MESSAGE_TAG_ADDRESS_PATTERN                 \
  ERROR_MESSAGE_DETAIL_PATTERN

#define CHECK_DYNAMIC_CONFIGURATION_ERROR_PATTERN(__pos, __value, __cursor) \
  ERROR_MESSAGE_HEADER_PATTERN                                              \
  "CHERISEED_CHECKS has an invalid option at position " #__pos ":\n\n"      \
  "  CHERISEED_CHECKS=" __value "\n"                                        \
  "                   " __cursor "\n"

// clang-format on

// Helper to test dynamic check control.
struct OnStackArgs {
  OnStackArgs(const char *env) {
    argc = 1;
    argv[0] = nullptr;
    envp[0] = env;
    envp[1] = nullptr;
  }

  u64 GetAddress() const { return reinterpret_cast<u64>(&argc); }

  int argc;
  const char *argv[1];
  const char *envp[2];
};  // struct OnStackArgs

#if !defined(CHERISEED_UNIT_TESTING)

/// Helper to create a capability on stack in the tests.
template <typename T>
static inline void InitCap(__cheriseed_cap_t *cap, T *address) {
  // Set maximum permissions metadata
  __cheriseed_ddc_get(cap);
  // Set value field
  __cheriseed_address_set(cap, cap, reinterpret_cast<uint64_t>(address));
}

/// Helper to create a capability on stack.
static inline void InitCap(__cheriseed_cap_t *cap, uint64_t value,
                           uint64_t metadata) {
  __cheriseed_address_set(cap, cap, value);
  __cheriseed_copy_to_high(cap, cap, metadata);
}

/// Checks that two capabilities have the same metadata.
static inline void MetadataEquals(const __cheriseed_cap_t *cap1,
                                  const __cheriseed_cap_t *cap2) {
  ASSERT_EQ(__cheriseed_copy_from_high(cap1), __cheriseed_copy_from_high(cap2));
}

/// Checks that a capability has some metadata.
static inline void MetadataEquals(const __cheriseed_cap_t *cap,
                                  uint64_t metadata) {
  ASSERT_EQ(__cheriseed_copy_from_high(cap), metadata);
}

/// Checks that two capabilities have different metadata.
static inline void MetadataNotEquals(const __cheriseed_cap_t *cap1,
                                     const __cheriseed_cap_t *cap2) {
  ASSERT_NE(__cheriseed_copy_from_high(cap1), __cheriseed_copy_from_high(cap2));
}

/// Checks that a capability has different metadata.
static inline void MetadataNotEquals(const __cheriseed_cap_t *cap,
                                     uint64_t metadata) {
  ASSERT_NE(__cheriseed_copy_from_high(cap), metadata);
}

/// Checks that a capability has a specific value.
static inline void ValueEquals(const __cheriseed_cap_t *cap, uint64_t value) {
  ASSERT_EQ(__cheriseed_address_get(cap), value);
}

/// Checks that a capability has a specific value.
template <typename T>
static inline void ValueEquals(const __cheriseed_cap_t *cap, T *value) {
  ASSERT_EQ(reinterpret_cast<T *>(__cheriseed_address_get(cap)), value);
}

/// Checks that a capability has any value but a specific value.
static inline void ValueNotEquals(const __cheriseed_cap_t *cap,
                                  uint64_t value) {
  ASSERT_NE(__cheriseed_address_get(cap), value);
}

/// Checks that a capability has any value but a specific value.
template <typename T>
static inline void ValueNotEquals(const __cheriseed_cap_t *cap, T *value) {
  ASSERT_NE(reinterpret_cast<T *>(__cheriseed_address_get(cap)), value);
}

#define ASSERT_CAPABILITY_METADATA_EQ(__a, __b) MetadataEquals((__a), (__b))
#define ASSERT_CAPABILITY_METADATA_NE(__a, __b) MetadataNotEquals((__a), (__b))
#define ASSERT_CAPABILITY_VALUE_EQ(__a, __b) ValueEquals((__a), (__b))
#define ASSERT_CAPABILITY_VALUE_NE(__a, __b) ValueNotEquals((__a), (__b))
#define ASSERT_TAGGED(__a) ASSERT_EQ(__cheriseed_tag_get(__a), (uint8_t)1)
#define ASSERT_UNTAGGED(__a) ASSERT_EQ(__cheriseed_tag_get(__a), (uint8_t)0)

#endif  // !CHERISEED_UNIT_TESTING
};      // namespace utils

// Handle a test exiting when we expect it not to
#define EXPECT_NORMAL_EXIT(__expr) \
  EXPECT_EXIT(__expr, ::testing::ExitedWithCode(0), "")

// Symbols required by cheriseed but which are not present in testing libc.
extern "C" bool __shim_is_pure_capability(void);
extern "C" bool __shim_supports_cancellation_points(void);
extern "C" void *__shim_syscall(long, ...);

#endif  // CHERISEED_TEST_UTILS_H
