//===-- cheriseed_check_access.cpp ------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// Unit tests for __cheriseed_check_access
//
//===----------------------------------------------------------------------===//

#include "cheriseed_test_utils.h"

using namespace __cheriseed::abi;

// Tests of __cheriseed_check_access where the permissions are incorrect
// must assert that the function exited with the correct code and message
// to pass the test.
#define EXPECT_DENIED_PERMS(__expr)                          \
  {                                                          \
    EXPECT_EXIT(__expr, testing::KilledBySignal(SIGSEGV),    \
                CHECK_REQUIRED_PERMS_ERROR_MESSAGE_PATTERN); \
  }

#define EXPECT_DENIED_BOUNDS(__expr)                      \
  {                                                       \
    EXPECT_EXIT(__expr, testing::KilledBySignal(SIGSEGV), \
                CHECK_IN_BOUNDS_ERROR_MESSAGE_PATTERN);   \
  }

// Tests of __cheriseed_check_access where the permissions are correct must
// assert that the function did not exit to pass the test.
// Since the failure case for this test is to exit the program, each test is
// still sandboxed to prevent a failure of this test from crashing all
// subsequent tests.
// If the function completes successfully, the exit code will be 0 which is
// caught by the EXPECT_EXIT handler.
// Permissions and bounds of the capability are narrowed using CCL functions
#define EXPECT_GRANTED(__expr) \
  { EXPECT_NORMAL_EXIT(__expr; exit(0);); }

#define TEST_CHECK_ACCESS(__OUTCOME)                                           \
  {                                                                            \
    uint32_t a;                                                                \
    __cheriseed_cap_t cap;                                                     \
    utils::InitCap(&cap, &a);                                                  \
    __cheriseed_perms_and(&cap, &cap,                                          \
                          (ccl::permissions::LOAD | ccl::permissions::STORE)); \
    __cheriseed_bounds_set(&cap, &cap, sizeof(uint32_t));                      \
    __OUTCOME;                                                                 \
  }

TEST(CheckAccessDeathTest, PermsHasNone) {
  TEST_CHECK_ACCESS(EXPECT_DENIED_PERMS(
      __cheriseed_check_access(&cap, 0, Permissions::EXECUTE)));
}

TEST(CheckAccessDeathTest, PermsHasSome) {
  TEST_CHECK_ACCESS(EXPECT_DENIED_PERMS(__cheriseed_check_access(
      &cap, 0, (Permissions::LOAD | Permissions::EXECUTE))));
}

TEST(CheckAccessDeathTest, PermsHasExactly) {
  TEST_CHECK_ACCESS(EXPECT_GRANTED(__cheriseed_check_access(
      &cap, 0, (Permissions::LOAD | Permissions::STORE))));
}

TEST(CheckAccessDeathTest, PermsHasMore) {
  TEST_CHECK_ACCESS(
      EXPECT_GRANTED(__cheriseed_check_access(&cap, 0, Permissions::LOAD)));
}

TEST(CheckAccessDeathTest, BoundsOutside) {
  TEST_CHECK_ACCESS(EXPECT_DENIED_BOUNDS(
      __cheriseed_check_access(&cap, sizeof(uint64_t), 0)));
}

TEST(CheckAccessDeathTest, BoundsInside) {
  TEST_CHECK_ACCESS(
      EXPECT_GRANTED(__cheriseed_check_access(&cap, sizeof(uint16_t), 0)));
}

TEST(CheckAccessDeathTest, BoundsZero) {
  TEST_CHECK_ACCESS(EXPECT_DENIED_BOUNDS(__cheriseed_bounds_set(&cap, &cap, 0);
                                         __cheriseed_check_access(&cap, 1, 0)));
}

TEST(CheckAccessDeathTest, LoadCap) {
  __cheriseed_cap_t target, load_base, load_from, dst;

  utils::InitCap(&load_base, &target);
  utils::InitCap(&load_from, &target);

  // Check with all perms
  EXPECT_GRANTED(__cheriseed_load_cap(&load_from, &dst));
  // Check missing LOAD_CAP
  __cheriseed_perms_and(&load_from, &load_base, ~ccl::permissions::LOAD_CAP);
  EXPECT_GRANTED(__cheriseed_load_cap(&load_from, &dst));
  // Check missing LOAD
  __cheriseed_perms_and(&load_from, &load_base, ~ccl::permissions::LOAD);
  EXPECT_DENIED_PERMS(__cheriseed_load_cap(&load_from, &dst));
  // Check if bounds is enough
  __cheriseed_bounds_set(&load_from, &load_base, sizeof(__cheriseed_cap_t) - 1);
  EXPECT_DENIED_BOUNDS(__cheriseed_load_cap(&load_from, &dst));
}

TEST(CheckAccessDeathTest, StoreCap) {
  u8 x;
  __cheriseed_cap_t target, store_base, store_to, src;

  utils::InitCap(&store_base, &target);
  utils::InitCap(&store_to, &target);
  utils::InitCap(&src, &x);

  // Check with all perms
  EXPECT_GRANTED(__cheriseed_store_cap(&store_to, &src));
  // Check missing STORE
  __cheriseed_perms_and(&store_to, &store_base, ~ccl::permissions::STORE);
  EXPECT_DENIED_PERMS(__cheriseed_store_cap(&store_to, &src));
  // Check missing STORE_CAP
  __cheriseed_perms_and(&store_to, &store_base, ~ccl::permissions::STORE_CAP);
  EXPECT_DENIED_PERMS(__cheriseed_store_cap(&store_to, &src));
  // Check if bounds is enough
  __cheriseed_bounds_set(&store_to, &store_base, sizeof(__cheriseed_cap_t) - 1);
  EXPECT_DENIED_BOUNDS(__cheriseed_store_cap(&store_to, &src));
}

TEST(CheckAccessDeathTest, GenericCapInit) {
  uint16_t a;
  __cheriseed_cap_t cap;
  __cheriseed_generic_cap_init(&cap, reinterpret_cast<uint64_t>(&a), sizeof(a),
                               Permissions::EXECUTE);
  TEST_CHECK_ACCESS(
      EXPECT_GRANTED(__cheriseed_check_access(&cap, 0, Permissions::LOAD)));
  TEST_CHECK_ACCESS(EXPECT_DENIED_PERMS(
      __cheriseed_check_access(&cap, 0, Permissions::EXECUTE)));
}
