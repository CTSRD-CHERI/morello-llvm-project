//===-- cheriseed_check_unaligned.cpp ---------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// Test that the RT calls catch unaligned capabilities.
//
//===----------------------------------------------------------------------===//

#include "cheriseed_test_utils.h"

// Helper to create an unaligned capability.
struct alignas(16) UnalignedCapability final {
  explicit UnalignedCapability() = default;

  __cheriseed_cap_t *operator&() {
    return reinterpret_cast<__cheriseed_cap_t *>(&space_[1]);
  }

 private:
  uint8_t space_[sizeof(__cheriseed_cap_t) + 1];
};  // struct UnalignedCapability

#define TEST_UNALIGNED_CAP(__expr)                      \
  {                                                     \
    __cheriseed_cap_t cap;                              \
    (void)cap;                                          \
    UnalignedCapability uacap;                          \
    (void)uacap;                                        \
    EXPECT_EXIT(__expr, testing::ExitedWithCode(1),     \
                CHECK_ALIGNMENT_ERROR_MESSAGE_PATTERN); \
  }

TEST(UnalignedDeathTest, AddressSet) {
  TEST_UNALIGNED_CAP(__cheriseed_address_set(&uacap, &cap, 0));
  TEST_UNALIGNED_CAP(__cheriseed_address_set(&cap, &uacap, 0));
}

TEST(UnalignedDeathTest, AddressGet) {
  TEST_UNALIGNED_CAP(__cheriseed_address_get(&uacap));
}

TEST(UnalignedDeathTest, DDCGet) {
  TEST_UNALIGNED_CAP(__cheriseed_ddc_get(&uacap));
}

TEST(UnalignedDeathTest, PCCGet) {
  TEST_UNALIGNED_CAP(__cheriseed_pcc_get(&uacap));
}

TEST(UnalignedDeathTest, EqualExact) {
  TEST_UNALIGNED_CAP(__cheriseed_equal_exact(&uacap, &cap));
  TEST_UNALIGNED_CAP(__cheriseed_equal_exact(&cap, &uacap));
}

TEST(UnalignedDeathTest, OffsetGet) {
  TEST_UNALIGNED_CAP(__cheriseed_offset_get(&uacap));
}

TEST(UnalignedDeathTest, PermsAnd) {
  TEST_UNALIGNED_CAP(__cheriseed_perms_and(&uacap, &cap, 0));
  TEST_UNALIGNED_CAP(__cheriseed_perms_and(&cap, &uacap, 0));
}

TEST(UnalignedDeathTest, BoundsSet) {
  TEST_UNALIGNED_CAP(__cheriseed_bounds_set(&uacap, &cap, 0));
  TEST_UNALIGNED_CAP(__cheriseed_bounds_set(&cap, &uacap, 0));
}

TEST(UnalignedDeathTest, CopyFromHigh) {
  TEST_UNALIGNED_CAP(__cheriseed_copy_from_high(&uacap));
}

TEST(UnalignedDeathTest, CopyToHigh) {
  TEST_UNALIGNED_CAP(__cheriseed_copy_to_high(&cap, &uacap, 0));
  TEST_UNALIGNED_CAP(__cheriseed_copy_to_high(&uacap, &cap, 0));
}

TEST(UnalignedDeathTest, TypeGet) {
  TEST_UNALIGNED_CAP(__cheriseed_type_get(&uacap));
}

TEST(UnalignedDeathTest, StackCapInit) {
  TEST_UNALIGNED_CAP(__cheriseed_stack_cap_init(&uacap, 0, 0));
}

TEST(UnalignedDeathTest, OffsetSet) {
  TEST_UNALIGNED_CAP(__cheriseed_offset_set(&uacap, &cap, 0));
  TEST_UNALIGNED_CAP(__cheriseed_offset_set(&cap, &uacap, 0));
}

TEST(UnalignedDeathTest, UnalignedLoad) {
  TEST_UNALIGNED_CAP(__cheriseed_cap_t load_from;
                     utils::InitCap(&load_from, &uacap);
                     __cheriseed_load_cap(&load_from, &cap));
}

TEST(UnalignedDeathTest, UnalignedStore) {
  TEST_UNALIGNED_CAP(__cheriseed_cap_t store_to;
                     utils::InitCap(&store_to, &uacap);
                     __cheriseed_store_cap(&store_to, &cap));
}

TEST(UnalignedDeathTest, Diff) {
  TEST_UNALIGNED_CAP(__cheriseed_diff(&uacap, &cap));
  TEST_UNALIGNED_CAP(__cheriseed_diff(&cap, &uacap));
}

TEST(UnalignedDeathTest, SubsetTest) {
  TEST_UNALIGNED_CAP(__cheriseed_subset_test(&uacap, &cap));
  TEST_UNALIGNED_CAP(__cheriseed_subset_test(&cap, &uacap));
}

TEST(UnalignedDeathTest, ThreadPointer) {
  TEST_UNALIGNED_CAP(__cheriseed_thread_pointer(&uacap));
}

TEST(UnalignedDeathTest, GenericCapInit) {
  TEST_UNALIGNED_CAP(__cheriseed_generic_cap_init(&uacap, 0, 0, 0));
}
