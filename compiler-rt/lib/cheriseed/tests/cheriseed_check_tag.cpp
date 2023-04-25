//===-- cheriseed_check_tag.cpp ---------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of CHERIseed Runtime Library.
//
// Test that some RT calls catch untagged capabilities.
//
//===----------------------------------------------------------------------===//

#include "cheriseed_test_utils.h"

#define TEST_UNTAGGED_CAP(__expr)                           \
  {                                                         \
    __cheriseed_cap_t cap;                                  \
    (void)cap;                                              \
    __cheriseed_cap_t untagged_cap;                         \
    __cheriseed_tag_clear(&untagged_cap, &untagged_cap);    \
    EXPECT_EXIT(__expr, ::testing::KilledBySignal(SIGSEGV), \
                CHECK_IS_TAGGED_ERROR_MESSAGE_PATTERN);     \
  }

TEST(UntaggedDeathTest, SignalHandleMode) {
  TEST_UNTAGGED_CAP(__cheriseed_set_signal_handle_mode(
      reinterpret_cast<void*>(&untagged_cap), 0));
}

TEST(UntaggedDeathTest, CheckAccess) {
  TEST_UNTAGGED_CAP(__cheriseed_check_access(&untagged_cap, 0, 0, 0));
}

TEST(UntaggedDeathTest, CmpXchgCap) {
  TEST_UNTAGGED_CAP(__cheriseed_cmpxchg_cap(&untagged_cap, nullptr, nullptr,
                                            nullptr, 0, 0, 0));
}

TEST(UntaggedDeathTest, LoadCap) {
  TEST_UNTAGGED_CAP(__cheriseed_load_cap(&untagged_cap, nullptr, 0));
}

TEST(UntaggedDeathTest, LoadCapAtomic) {
  TEST_UNTAGGED_CAP(__cheriseed_load_cap_atomic(&untagged_cap, nullptr, 0, 0));
}

TEST(UntaggedDeathTest, StoreCap) {
  TEST_UNTAGGED_CAP(__cheriseed_store_cap(&untagged_cap, nullptr, 0));
}

TEST(UntaggedDeathTest, StoreCapAtomic) {
  TEST_UNTAGGED_CAP(__cheriseed_store_cap_atomic(&untagged_cap, nullptr, 0, 0));
}

TEST(UntaggedDeathTest, ClearAllTags) {
  TEST_UNTAGGED_CAP(__cheriseed_clear_all_tags(&untagged_cap, 0));
}

TEST(UntaggedDeathTest, LockAndCopyAllTags) {
  TEST_UNTAGGED_CAP(__cheriseed_lock_and_copy_all_tags(&cap, &untagged_cap, 0));
  TEST_UNTAGGED_CAP(__cheriseed_lock_and_copy_all_tags(&untagged_cap, &cap, 0));
}

TEST(UntaggedDeathTest, CopyAllTags) {
  TEST_UNTAGGED_CAP(__cheriseed_copy_all_tags(&cap, &untagged_cap, 0));
  TEST_UNTAGGED_CAP(__cheriseed_copy_all_tags(&untagged_cap, &cap, 0));
}
