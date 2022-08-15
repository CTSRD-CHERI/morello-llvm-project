//===-- cheriseed_api_violations.cpp ----------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// Unit tests for API violations.
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

TEST(CheckAccessDeathTest, BoundsOutside) {
  TEST_CHECK_ACCESS(EXPECT_DENIED_BOUNDS(
      __cheriseed_check_access(&cap, sizeof(uint64_t), 0)));
}

TEST(CheckAccessDeathTest, BoundsZero) {
  TEST_CHECK_ACCESS(EXPECT_DENIED_BOUNDS(__cheriseed_bounds_set(&cap, &cap, 0);
                                         __cheriseed_check_access(&cap, 1, 0)));
}

TEST(LoadCapDeathTest, NoLoadPermission) {
  __cheriseed_cap_t target, load_from, dst;
  utils::InitCap(&load_from, &target);
  __cheriseed_perms_and(&load_from, &load_from, ~ccl::permissions::LOAD);
  EXPECT_DENIED_PERMS(__cheriseed_load_cap(&load_from, &dst));
}

TEST(LoadCapDeathTest, Bounds) {
  __cheriseed_cap_t target, load_from, dst;
  utils::InitCap(&load_from, &target);
  __cheriseed_bounds_set(&load_from, &load_from, sizeof(__cheriseed_cap_t) - 1);
  EXPECT_DENIED_BOUNDS(__cheriseed_load_cap(&load_from, &dst));
}

TEST(StoreCapDeathTest, NoStorePermission) {
  u8 x;
  __cheriseed_cap_t target, store_to, src;
  utils::InitCap(&store_to, &target);
  utils::InitCap(&src, &x);
  __cheriseed_perms_and(&store_to, &store_to, ~ccl::permissions::STORE);
  EXPECT_DENIED_PERMS(__cheriseed_store_cap(&store_to, &src));
}

TEST(StoreCapDeathTest, Bounds) {
  u8 x;
  __cheriseed_cap_t target, store_to, src;
  utils::InitCap(&store_to, &target);
  utils::InitCap(&src, &x);
  __cheriseed_bounds_set(&store_to, &store_to, sizeof(__cheriseed_cap_t) - 1);
  EXPECT_DENIED_BOUNDS(__cheriseed_store_cap(&store_to, &src));
}

TEST(ClearAllDeathTest, Bounds) {
  __cheriseed_cap_t cap[20], cap_all;
  utils::InitCap(&cap_all, cap);
  __cheriseed_bounds_set(&cap_all, &cap_all, sizeof(cap));
  EXPECT_DENIED_BOUNDS(__cheriseed_clear_all_tags(&cap_all, sizeof(cap) + 1));
}
