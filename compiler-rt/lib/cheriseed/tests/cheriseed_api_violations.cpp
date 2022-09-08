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
      __cheriseed_check_access(&cap, 0, Permissions::EXECUTE, 0)));
}

TEST(CheckAccessDeathTest, PermsHasSome) {
  TEST_CHECK_ACCESS(EXPECT_DENIED_PERMS(__cheriseed_check_access(
      &cap, 0, (Permissions::LOAD | Permissions::EXECUTE), 0)));
}

TEST(CheckAccessDeathTest, BoundsOutside) {
  TEST_CHECK_ACCESS(EXPECT_DENIED_BOUNDS(
      __cheriseed_check_access(&cap, sizeof(uint64_t), 0, 0)));
}

TEST(CheckAccessDeathTest, BoundsZero) {
  TEST_CHECK_ACCESS(
      EXPECT_DENIED_BOUNDS(__cheriseed_bounds_set(&cap, &cap, 0);
                           __cheriseed_check_access(&cap, 1, 0, 0)));
}

TEST(CmpXchgCapDeathTest, NoLoadPermission) {
  uint8_t a, b;
  __cheriseed_cap_t cap_to_cap, cap, exp, des, temp;

  utils::InitCap(&cap, &a);
  utils::InitCap(&exp, &a);
  utils::InitCap(&des, &b);
  utils::InitCap(&cap_to_cap, &cap);
  __cheriseed_perms_and(&cap_to_cap, &cap_to_cap, ~ccl::permissions::LOAD);
  EXPECT_DENIED_PERMS(
      __cheriseed_cmpxchg_cap(&cap_to_cap, &exp, &des, &temp, 0, 0, 0));
}

TEST(CmpXchgCapDeathTest, NoStorePermission) {
  uint8_t a, b;
  __cheriseed_cap_t cap_to_cap, cap, exp, des, temp;

  utils::InitCap(&cap, &a);
  utils::InitCap(&exp, &a);
  utils::InitCap(&des, &b);
  utils::InitCap(&cap_to_cap, &cap);
  __cheriseed_perms_and(&cap_to_cap, &cap_to_cap, ~ccl::permissions::STORE);
  EXPECT_DENIED_PERMS(
      __cheriseed_cmpxchg_cap(&cap_to_cap, &exp, &des, &temp, 0, 0, 0));
}

TEST(CmpXchgCapDeathTest, Bounds) {
  uint8_t a, b;
  __cheriseed_cap_t cap_to_cap, cap, exp, des, temp;

  utils::InitCap(&cap, &a);
  utils::InitCap(&exp, &a);
  utils::InitCap(&des, &b);
  utils::InitCap(&cap_to_cap, &cap);
  __cheriseed_bounds_set(&cap_to_cap, &cap_to_cap,
                         sizeof(__cheriseed_cap_t) - 1);
  EXPECT_DENIED_BOUNDS(
      __cheriseed_cmpxchg_cap(&cap_to_cap, &exp, &des, &temp, 0, 0, 0));
}

TEST(CmpXchgCapDeathTest, NoStoreCapPerm) {
  uint8_t a, b;
  __cheriseed_cap_t cap_to_cap, cap, exp, des, temp;

  utils::InitCap(&cap, &a);
  utils::InitCap(&exp, &a);
  utils::InitCap(&des, &b);
  utils::InitCap(&cap_to_cap, &cap);
  __cheriseed_perms_and(&cap_to_cap, &cap_to_cap, ~ccl::permissions::STORE_CAP);
  EXPECT_DENIED_PERMS(
      __cheriseed_cmpxchg_cap(&cap_to_cap, &exp, &des, &temp, 0, 0, 0));
}

TEST(LoadCapDeathTest, NoLoadPermission) {
  __cheriseed_cap_t target, load_from, dst;
  utils::InitCap(&load_from, &target);
  __cheriseed_perms_and(&load_from, &load_from, ~ccl::permissions::LOAD);
  EXPECT_DENIED_PERMS(__cheriseed_load_cap(&load_from, &dst, 0));
}

TEST(LoadCapDeathTest, Bounds) {
  __cheriseed_cap_t target, load_from, dst;
  utils::InitCap(&load_from, &target);
  __cheriseed_bounds_set(&load_from, &load_from, sizeof(__cheriseed_cap_t) - 1);
  EXPECT_DENIED_BOUNDS(__cheriseed_load_cap(&load_from, &dst, 0));
}

TEST(StoreCapDeathTest, NoStorePermission) {
  u8 x;
  __cheriseed_cap_t target, store_to, src;
  utils::InitCap(&store_to, &target);
  utils::InitCap(&src, &x);
  __cheriseed_perms_and(&store_to, &store_to, ~ccl::permissions::STORE);
  EXPECT_DENIED_PERMS(__cheriseed_store_cap(&store_to, &src, 0));
}

TEST(StoreCapDeathTest, Bounds) {
  u8 x;
  __cheriseed_cap_t target, store_to, src;
  utils::InitCap(&store_to, &target);
  utils::InitCap(&src, &x);
  __cheriseed_bounds_set(&store_to, &store_to, sizeof(__cheriseed_cap_t) - 1);
  EXPECT_DENIED_BOUNDS(__cheriseed_store_cap(&store_to, &src, 0));
}

TEST(ClearAllDeathTest, Bounds) {
  __cheriseed_cap_t cap[20], cap_all;
  utils::InitCap(&cap_all, cap);
  __cheriseed_bounds_set(&cap_all, &cap_all, sizeof(cap));
  EXPECT_DENIED_BOUNDS(__cheriseed_clear_all_tags(&cap_all, sizeof(cap) + 1));
}

TEST(LockAndCopyAllTagsDeathTest, Bounds) {
  __cheriseed_cap_t cap[20], cap_1, cap_2;
  utils::InitCap(&cap_1, cap);
  utils::InitCap(&cap_2, cap);
  __cheriseed_bounds_set(&cap_1, &cap_1, sizeof(cap));
  EXPECT_DENIED_BOUNDS(
      __cheriseed_lock_and_copy_all_tags(&cap_1, &cap_2, sizeof(cap) + 1););
  EXPECT_DENIED_BOUNDS(
      __cheriseed_lock_and_copy_all_tags(&cap_2, &cap_1, sizeof(cap) + 1););
}

TEST(CopyAllTagsDeathTest, Bounds) {
  __cheriseed_cap_t cap[20], cap_1, cap_2;
  utils::InitCap(&cap_1, cap);
  utils::InitCap(&cap_2, cap);
  __cheriseed_bounds_set(&cap_1, &cap_1, sizeof(cap));
  EXPECT_DENIED_BOUNDS(
      __cheriseed_copy_all_tags(&cap_1, &cap_2, sizeof(cap) + 1););
  EXPECT_DENIED_BOUNDS(
      __cheriseed_copy_all_tags(&cap_2, &cap_1, sizeof(cap) + 1););
}
