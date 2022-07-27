//===-- cheriseed_check_address.cpp -----------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of CHERIseed Runtime Library.
//
// Test that the RT calls catch some usual invalid capability addresses.
//
//===----------------------------------------------------------------------===//

#include "cheriseed_test_utils.h"

#define TEST_INVALID_ADDRESS_CAP(__expr)              \
  {                                                   \
    __cheriseed_cap_t cap;                            \
    (void)cap;                                        \
    EXPECT_EXIT(__expr, testing::ExitedWithCode(1),   \
                CHECK_ADDRESS_ERROR_MESSAGE_PATTERN); \
  }

TEST(InvalidAddressDeathTest, AddressSet) {
  TEST_INVALID_ADDRESS_CAP(__cheriseed_address_set(nullptr, &cap, 0));
}

TEST(InvalidAddressDeathTest, DDCGet) {
  TEST_INVALID_ADDRESS_CAP(__cheriseed_ddc_get(nullptr));
}

TEST(InvalidAddressDeathTest, PCCGet) {
  TEST_INVALID_ADDRESS_CAP(__cheriseed_pcc_get(nullptr));
}

TEST(InvalidAddressDeathTest, PermsAnd) {
  TEST_INVALID_ADDRESS_CAP(__cheriseed_perms_and(nullptr, &cap, 0));
}

TEST(InvalidAddressDeathTest, BoundsSet) {
  TEST_INVALID_ADDRESS_CAP(__cheriseed_bounds_set(nullptr, &cap, 0));
}

TEST(InvalidAddressDeathTest, CopyToHigh) {
  TEST_INVALID_ADDRESS_CAP(__cheriseed_copy_to_high(nullptr, &cap, 0));
}

TEST(InvalidAddressDeathTest, StackCapInit) {
  TEST_INVALID_ADDRESS_CAP(__cheriseed_stack_cap_init(nullptr, 0, 0));
}

TEST(InvalidAddressDeathTest, OffsetSet) {
  TEST_INVALID_ADDRESS_CAP(__cheriseed_offset_set(nullptr, &cap, 0));
}

TEST(InvalidAddressDeathTest, ThreadPointer) {
  TEST_INVALID_ADDRESS_CAP(__cheriseed_thread_pointer(nullptr));
}

TEST(InvalidAddressDeathTest, LoadCap) {
  TEST_INVALID_ADDRESS_CAP(__cheriseed_cap_t cap_to_cap;
                           utils::InitCap(&cap_to_cap, &cap);
                           __cheriseed_load_cap(&cap_to_cap, nullptr));
}

TEST(InvalidAddressDeathTest, StoreCap) {
  TEST_INVALID_ADDRESS_CAP(
      __cheriseed_cap_t cap_to_null;
      utils::InitCap(&cap_to_null, reinterpret_cast<__cheriseed_cap_t*>(0));
      __cheriseed_store_cap(&cap_to_null, nullptr));
}

TEST(InvalidAddressDeathTest, GenericCapInit) {
  TEST_INVALID_ADDRESS_CAP(__cheriseed_generic_cap_init(nullptr, 0, 0, 0));
}
