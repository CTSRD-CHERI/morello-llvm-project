//===-- cheriseed_atomic_tests.cpp ------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// (Smoke) Unit tests for atomic read/write of capabilities.
//
//===----------------------------------------------------------------------===//

#define CHERISEED_UNIT_TESTING

#include "cheriseed_test_utils.h"

using __cheriseed::AllowNullCap;

TEST(Atomics, ReadWrite) {
  LocalCap local_cap(UINT64_MAX, UINT64_MAX - 1);

  // Store compressed capability somewhere...
  __cheriseed_cap_t cap;
  local_cap.Store(&cap);
  // then read it back.
  LocalCap local_read_cap(&cap);

  // The values should match.
  ASSERT_EQ(local_cap.GetValue(), local_read_cap.GetValue());
  ASSERT_EQ(local_cap.GetMetadata(), local_read_cap.GetMetadata());
}

TEST(Atomics, NullptrPromotion) {
  LocalCap local_cap{AllowNullCap(nullptr)};

  ASSERT_EQ(local_cap.GetValue(), 0);
  ASSERT_EQ(local_cap.GetMetadata(), 0);
}
