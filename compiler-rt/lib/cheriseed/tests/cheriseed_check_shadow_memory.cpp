//===-- cheriseed_check_shadow_memory.cpp -----------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of CHERIseed Runtime Library.
//
// Unit test to check shadow memory functionalities.
//
//===----------------------------------------------------------------------===//

#include "cheriseed_shadow_memory.h"
#include "cheriseed_test_utils.h"

using __cheriseed::MemoryRange;
using __cheriseed::ShadowMemory;

// =============================================================================
// Test Memory Layout
// ------------------
//  Memory                [0x000000000000 - 0x0000ffffffff]
//  Shadow Mem            [0x00007e000000 - 0x00008e000000]
//    1. Shadow Low       [0x00007e000000 - 0x000085e00000]
//    2. Shadow Gap       [0x000085e00000 - 0x000086e00000]
//    3. Shadow High      [0x000086e00000 - 0x00008e000000]
// =============================================================================

#define TEST_MEM_EQ(_a, _b)                \
  {                                        \
    EXPECT_EQ(_a.GetBase(), _b.GetBase()); \
    EXPECT_EQ(_a.GetEnd(), _b.GetEnd());   \
  }

#define TEST_MAP_INIT                                                        \
  {                                                                          \
    test_map =                                                               \
        ShadowMemory(/* va_max */ (vaddr)0xffffffff,                         \
                     /* page_size */ (usize)4096, /* shadow_scale */ (u8)4); \
    test_map.SetShadowMemory(MemoryRange(0x7e000000, 0x8e000000));           \
  }

static ShadowMemory test_map;

TEST(CheckShadowMemory, Ranges) {
  TEST_MAP_INIT;
  TEST_MEM_EQ(test_map.GetShadowMemoryRange(),
              MemoryRange(0x7e000000, 0x8e000000));
  TEST_MEM_EQ(test_map.GetShadowGapRange(),
              MemoryRange(0x85e00000, 0x86e00000));
  TEST_MEM_EQ(test_map.GetShadowMemoryRangeLow(),
              MemoryRange(0x7e000000, 0x85e00000));
  TEST_MEM_EQ(test_map.GetShadowMemoryRangeHigh(),
              MemoryRange(0x86e00000, 0x8e000000));
};

TEST(CheckShadowMemory, GetShadowAddressFrom) {
  TEST_MAP_INIT;
  vaddr test_addr[] = {0x0,        0x10,       0xffffffff, 0xffffffe0,
                       0x7dffffff, 0x7e000000, 0x7e000010, 0x86dfffff,
                       0x8dffffff, 0x8e000000, 0x85e00000};
  vaddr expected_shadow_addr[] = {
      0x7e000000, 0x7e000001, 0x8dffffff, 0x8dfffffe, 0x85dfffff, 0x85e00000,
      0x85e00001, 0x866dffff, 0x86dfffff, 0x86e00000, 0x865e0000};
  for (u8 idx = 0; idx < (sizeof(test_addr) / sizeof(test_addr[0])); ++idx)
    EXPECT_EQ(test_map.GetShadowAddressFrom(test_addr[idx]),
              expected_shadow_addr[idx]);
};

TEST(CheckShadowMemory, CheckCommonValues) {
  TEST_MAP_INIT;
  EXPECT_EQ(test_map.GetAlignment(), 0x10000);
  EXPECT_EQ(test_map.GetShadowSize(), 0x10000000);
};
