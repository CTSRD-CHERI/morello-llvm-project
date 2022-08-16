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

static const MemoryRange *IterateTagRangesExpected;

static void IterateTagRangesCallback(const MemoryRange &range) {
  EXPECT_EQ(range.GetBase(), IterateTagRangesExpected->GetBase());
  EXPECT_EQ(range.GetEnd(), IterateTagRangesExpected->GetEnd());
  ++IterateTagRangesExpected;
}
static void ZipTagRangeCallback(const MemoryRange &src_range,
                                const MemoryRange &dst_range) {
  EXPECT_EQ(src_range.GetBase(), IterateTagRangesExpected->GetBase());
  EXPECT_EQ(src_range.GetEnd(), IterateTagRangesExpected->GetEnd());
  EXPECT_EQ(dst_range.GetBase(), IterateTagRangesExpected->GetBase());
  EXPECT_EQ(dst_range.GetEnd(), IterateTagRangesExpected->GetEnd());
  ++IterateTagRangesExpected;
}

struct TagRangesTester {
  TagRangesTester(vaddr start, vaddr end, const MemoryRange *expected_range) {
    IterateTagRangesExpected = expected_range;
    test_map.IterateTagRanges(MemoryRange(start, end),
                              &IterateTagRangesCallback);
    IterateTagRangesExpected = expected_range;
    test_map.ZipTagRange(MemoryRange(start, end), MemoryRange(start, end),
                         &ZipTagRangeCallback);
  }
};

TEST(CheckShadowMemory, IterateTagRanges) {
  TEST_MAP_INIT;
  MemoryRange ranges[2];

  // Note: end address is not inclusive.
  // Think about base + size: [base, base + size)

  ranges[0] = MemoryRange(0x7e000000, 0x7e000001);
  TagRangesTester(0, 1, ranges);
  TagRangesTester(0, 16, ranges);
  TagRangesTester(15, 16, ranges);

  ranges[0] = MemoryRange(0x7e000000, 0x7e000002);
  TagRangesTester(0, 17, ranges);
  TagRangesTester(15, 17, ranges);
  TagRangesTester(0, 31, ranges);
  TagRangesTester(15, 31, ranges);

  // Last capability before the shadow gap.
  ranges[0] = MemoryRange(0x85DFFFFF, 0x85e00000);
  TagRangesTester(0x7DFFFFF0, 0x7DFFFFFF, ranges);
  TagRangesTester(0x7DFFFFFF, 0x7DFFFFFF, ranges);
};
