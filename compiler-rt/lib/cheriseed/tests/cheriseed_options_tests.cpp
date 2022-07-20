//===-- cheriseed_options_tests.cpp -----------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// Unit tests for configuration controls
//
//===----------------------------------------------------------------------===//

#define CHERISEED_UNIT_TESTING

#include "cheriseed_common.h"
#include "cheriseed_test_utils.h"

using __cheriseed::Options;

TEST(Options, CheckAlignmentON) {
  __cheriseed_control_checks(CHERISEED_CHECK_OFF, UINT64_MAX);
  __cheriseed_control_checks(CHERISEED_CHECK_ON, CHERISEED_CHECK_ALIGNMENT);
  Options Opts;
  EXPECT_EQ(Opts.GetCurrentChecks(), CHERISEED_CHECK_ALIGNMENT);
  EXPECT_TRUE(Opts.shouldCheckAlignment());
}

TEST(Options, CheckAlignmentOFF) {
  __cheriseed_control_checks(CHERISEED_CHECK_OFF, CHERISEED_CHECK_ALIGNMENT);
  Options Opts;
  EXPECT_EQ(Opts.GetCurrentChecks(), UINT64_MAX & ~CHERISEED_CHECK_ALIGNMENT);
  EXPECT_FALSE(Opts.shouldCheckAlignment());
}

TEST(Options, CheckBoundsON) {
  __cheriseed_control_checks(CHERISEED_CHECK_OFF, UINT64_MAX);
  __cheriseed_control_checks(CHERISEED_CHECK_ON, CHERISEED_CHECK_BOUNDS);
  Options Opts;
  EXPECT_EQ(Opts.GetCurrentChecks(), CHERISEED_CHECK_BOUNDS);
  EXPECT_TRUE(Opts.shouldCheckBounds());
}

TEST(Options, CheckBoundsOFF) {
  __cheriseed_control_checks(CHERISEED_CHECK_OFF, CHERISEED_CHECK_BOUNDS);
  Options Opts;
  EXPECT_EQ(Opts.GetCurrentChecks(), UINT64_MAX & ~CHERISEED_CHECK_BOUNDS);
  EXPECT_FALSE(Opts.shouldCheckBounds());
}

TEST(Options, CheckTagON) {
  __cheriseed_control_checks(CHERISEED_CHECK_OFF, UINT64_MAX);
  __cheriseed_control_checks(CHERISEED_CHECK_ON, CHERISEED_CHECK_TAG);
  Options Opts;
  EXPECT_EQ(Opts.GetCurrentChecks(), CHERISEED_CHECK_TAG);
  EXPECT_TRUE(Opts.shouldCheckTag());
}

TEST(Options, CheckTagOFF) {
  __cheriseed_control_checks(CHERISEED_CHECK_OFF, CHERISEED_CHECK_TAG);
  Options Opts;
  EXPECT_EQ(Opts.GetCurrentChecks(), UINT64_MAX & ~CHERISEED_CHECK_TAG);
  EXPECT_FALSE(Opts.shouldCheckTag());
}

TEST(Options, CheckPermsOFF) {
  __cheriseed_control_checks(CHERISEED_CHECK_OFF, CHERISEED_CHECK_PERMS);
  Options Opts;
  EXPECT_EQ(Opts.GetCurrentChecks(), UINT64_MAX & ~CHERISEED_CHECK_PERMS);
  EXPECT_TRUE(Opts.shouldCheckPerms() == 0);
}

class CheckPermsONTestFixture : public ::testing::TestWithParam<u64> {};

TEST_P(CheckPermsONTestFixture, writeMasks) {
  __cheriseed_control_checks(CHERISEED_CHECK_OFF, UINT64_MAX);
  __cheriseed_control_checks(CHERISEED_CHECK_ON, GetParam());
  Options Opts;
  EXPECT_EQ(Opts.GetCurrentChecks(), GetParam());
  EXPECT_EQ(Opts.shouldCheckPerms(), GetParam());
}

// TODO: Extend to include all combinations of permissions
INSTANTIATE_TEST_SUITE_P(CheckPermsON, CheckPermsONTestFixture,
                         testing::Values(ccl::permissions::LOAD,
                                         ccl::permissions::STORE,
                                         ccl::permissions::EXECUTE,
                                         ccl::permissions::LOAD_CAP,
                                         ccl::permissions::STORE_CAP));
