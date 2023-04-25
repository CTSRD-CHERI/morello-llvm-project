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

#include "cheriseed_test_utils.h"

using namespace __cheriseed::abi;

using __cheriseed::ControlChecksDynamic;
using __cheriseed::Environment;
using __cheriseed::SnapshotOptions;
using utils::OnStackArgs;

TEST(Options, CheckAlignmentON) {
  __cheriseed_control_checks(Control::CTRL_DISABLE, Check::CHK_ALL);
  __cheriseed_control_checks(Control::CTRL_ENABLE, Check::CHK_ALIGNMENT);
  const SnapshotOptions Opts;
  EXPECT_TRUE(Opts.shouldCheckAlignment());
}

TEST(Options, CheckAlignmentOFF) {
  __cheriseed_control_checks(Control::CTRL_DISABLE, Check::CHK_ALIGNMENT);
  const SnapshotOptions Opts;
  EXPECT_FALSE(Opts.shouldCheckAlignment());
}

TEST(Options, CheckBoundsON) {
  __cheriseed_control_checks(Control::CTRL_DISABLE, Check::CHK_ALL);
  __cheriseed_control_checks(Control::CTRL_ENABLE, Check::CHK_BOUNDS);
  const SnapshotOptions Opts;
  EXPECT_TRUE(Opts.shouldCheckBounds());
}

TEST(Options, CheckBoundsOFF) {
  __cheriseed_control_checks(Control::CTRL_DISABLE, Check::CHK_BOUNDS);
  const SnapshotOptions Opts;
  EXPECT_FALSE(Opts.shouldCheckBounds());
}

TEST(Options, CheckTagON) {
  __cheriseed_control_checks(Control::CTRL_DISABLE, Check::CHK_ALL);
  __cheriseed_control_checks(Control::CTRL_ENABLE, Check::CHK_TAG);
  const SnapshotOptions Opts;
  EXPECT_TRUE(Opts.shouldCheckTag());
}

TEST(Options, CheckTagOFF) {
  __cheriseed_control_checks(Control::CTRL_DISABLE, Check::CHK_TAG);
  const SnapshotOptions Opts;
  EXPECT_FALSE(Opts.shouldCheckTag());
}

TEST(Options, CheckPermsOFF) {
  __cheriseed_control_checks(Control::CTRL_DISABLE, Check::CHK_PERMS);
  const SnapshotOptions Opts;
  EXPECT_TRUE(Opts.getCheckedPerms() == 0);
}

class CheckPermsON : public ::testing::TestWithParam<uint64_t> {};

TEST_P(CheckPermsON, Permission) {
  __cheriseed_control_checks(Control::CTRL_DISABLE, Check::CHK_ALL);
  __cheriseed_control_checks(Control::CTRL_ENABLE, GetParam());
  const SnapshotOptions Opts;
  EXPECT_EQ(Opts.getCheckedPerms(), GetParam());
}

// TODO: Extend to include all combinations of permissions
INSTANTIATE_TEST_SUITE_P(Options, CheckPermsON,
                         testing::Values(ccl::permissions::LOAD,
                                         ccl::permissions::STORE,
                                         ccl::permissions::EXECUTE,
                                         ccl::permissions::LOAD_CAP,
                                         ccl::permissions::STORE_CAP));

TEST(Options, DynamicConfigurationTag) {
  EXPECT_TRUE(SnapshotOptions().shouldCheckTag());

  // Turn tag checks off.
  {
    const char *checks = "CHERISEED_CHECKS=-TAG";
    OnStackArgs args(&checks[0]);
    Environment env = Environment::From(args.GetAddress());
    ControlChecksDynamic(env);
  }
  EXPECT_FALSE(SnapshotOptions().shouldCheckTag());

  // Turn tag checks on.
  {
    const char *checks = "CHERISEED_CHECKS=TAG";
    OnStackArgs args(&checks[0]);
    Environment env = Environment::From(args.GetAddress());
    ControlChecksDynamic(env);
  }
  EXPECT_TRUE(SnapshotOptions().shouldCheckTag());
}

TEST(Options, DynamicConfigurationBounds) {
  EXPECT_TRUE(SnapshotOptions().shouldCheckBounds());

  // Turn bounds checks off.
  {
    const char *checks = "CHERISEED_CHECKS=-BOUNDS";
    OnStackArgs args(&checks[0]);
    Environment env = Environment::From(args.GetAddress());
    ControlChecksDynamic(env);
  }
  EXPECT_FALSE(SnapshotOptions().shouldCheckBounds());

  // Turn bounds checks on.
  {
    const char *checks = "CHERISEED_CHECKS=BOUNDS";
    OnStackArgs args(&checks[0]);
    Environment env = Environment::From(args.GetAddress());
    ControlChecksDynamic(env);
  }
  EXPECT_TRUE(SnapshotOptions().shouldCheckBounds());
}

TEST(Options, DynamicConfigurationPerms) {
  EXPECT_NE(SnapshotOptions().getCheckedPerms(), 0);

  // Turn bounds checks off.
  {
    const char *checks = "CHERISEED_CHECKS=-PERMS";
    OnStackArgs args(&checks[0]);
    Environment env = Environment::From(args.GetAddress());
    ControlChecksDynamic(env);
  }
  EXPECT_EQ(SnapshotOptions().getCheckedPerms(), 0);

  // Turn bounds checks on.
  {
    const char *checks = "CHERISEED_CHECKS=PERMS";
    OnStackArgs args(&checks[0]);
    Environment env = Environment::From(args.GetAddress());
    ControlChecksDynamic(env);
  }
  EXPECT_NE(SnapshotOptions().getCheckedPerms(), 0);
}

TEST(Options, DynamicConfigurationAlignment) {
  EXPECT_TRUE(SnapshotOptions().shouldCheckAlignment());

  // Turn bounds checks off.
  {
    const char *checks = "CHERISEED_CHECKS=-ALIGNMENT";
    OnStackArgs args(&checks[0]);
    Environment env = Environment::From(args.GetAddress());
    ControlChecksDynamic(env);
  }
  EXPECT_FALSE(SnapshotOptions().shouldCheckAlignment());

  // Turn bounds checks on.
  {
    const char *checks = "CHERISEED_CHECKS=ALIGNMENT";
    OnStackArgs args(&checks[0]);
    Environment env = Environment::From(args.GetAddress());
    ControlChecksDynamic(env);
  }
  EXPECT_TRUE(SnapshotOptions().shouldCheckAlignment());
}

TEST(Options, DynamicConfigurationAll) {
  EXPECT_TRUE(SnapshotOptions().shouldCheckTag());
  EXPECT_TRUE(SnapshotOptions().shouldCheckBounds());
  EXPECT_TRUE(SnapshotOptions().shouldCheckAlignment());
  EXPECT_NE(SnapshotOptions().getCheckedPerms(), 0);

  // Turn all checks off.
  {
    const char *checks = "CHERISEED_CHECKS=-ALL";
    OnStackArgs args(&checks[0]);
    Environment env = Environment::From(args.GetAddress());
    ControlChecksDynamic(env);
  }
  EXPECT_FALSE(SnapshotOptions().shouldCheckTag());
  EXPECT_FALSE(SnapshotOptions().shouldCheckBounds());
  EXPECT_FALSE(SnapshotOptions().shouldCheckAlignment());
  EXPECT_EQ(SnapshotOptions().getCheckedPerms(), 0);

  // Turn bounds checks on.
  {
    const char *checks = "CHERISEED_CHECKS=ALL";
    OnStackArgs args(&checks[0]);
    Environment env = Environment::From(args.GetAddress());
    ControlChecksDynamic(env);
  }
  EXPECT_TRUE(SnapshotOptions().shouldCheckTag());
  EXPECT_TRUE(SnapshotOptions().shouldCheckBounds());
  EXPECT_TRUE(SnapshotOptions().shouldCheckAlignment());
  EXPECT_NE(SnapshotOptions().getCheckedPerms(), 0);
}

TEST(CompileTimeOptions, CheckAlignmentOn) {
  EXPECT_TRUE(SnapshotOptions(0).shouldCheckAlignment());
  EXPECT_FALSE(SnapshotOptions(Check::CHK_ALIGNMENT).shouldCheckAlignment());
}

TEST(CompileTimeOptions, CheckAlignment_RuntimeChanged) {
  __cheriseed_control_checks(Control::CTRL_ENABLE, Check::CHK_ALIGNMENT);
  EXPECT_TRUE(SnapshotOptions(0).shouldCheckAlignment());
  EXPECT_TRUE(SnapshotOptions(Check::CHK_ALIGNMENT).shouldCheckAlignment());

  __cheriseed_control_checks(Control::CTRL_DISABLE, Check::CHK_ALIGNMENT);
  EXPECT_FALSE(SnapshotOptions(0).shouldCheckAlignment());
  EXPECT_FALSE(SnapshotOptions(Check::CHK_ALIGNMENT).shouldCheckAlignment());
}

TEST(CompileTimeOptions, CheckBounds) {
  EXPECT_TRUE(SnapshotOptions(0).shouldCheckBounds());
  EXPECT_FALSE(SnapshotOptions(Check::CHK_BOUNDS).shouldCheckBounds());
}

TEST(CompileTimeOptions, CheckBounds_RuntimeChanged) {
  __cheriseed_control_checks(Control::CTRL_ENABLE, Check::CHK_BOUNDS);
  EXPECT_TRUE(SnapshotOptions(0).shouldCheckBounds());
  EXPECT_TRUE(SnapshotOptions(Check::CHK_BOUNDS).shouldCheckBounds());

  __cheriseed_control_checks(Control::CTRL_DISABLE, Check::CHK_BOUNDS);
  EXPECT_FALSE(SnapshotOptions(0).shouldCheckBounds());
  EXPECT_FALSE(SnapshotOptions(Check::CHK_BOUNDS).shouldCheckBounds());
}

TEST(CompileTimeOptions, Tags) {
  EXPECT_TRUE(SnapshotOptions(0).shouldCheckTag());
  EXPECT_FALSE(SnapshotOptions(Check::CHK_TAG).shouldCheckTag());
}

TEST(CompileTimeOptions, Tags_RuntimeChanged) {
  __cheriseed_control_checks(Control::CTRL_ENABLE, Check::CHK_TAG);
  EXPECT_TRUE(SnapshotOptions(0).shouldCheckTag());
  EXPECT_TRUE(SnapshotOptions(Check::CHK_TAG).shouldCheckTag());

  __cheriseed_control_checks(Control::CTRL_DISABLE, Check::CHK_TAG);
  EXPECT_FALSE(SnapshotOptions(0).shouldCheckTag());
  EXPECT_FALSE(SnapshotOptions(Check::CHK_TAG).shouldCheckTag());
}

TEST(CompileTimeOptions, Permissions) {
  EXPECT_EQ(SnapshotOptions(0).getCheckedPerms(), Check::CHK_PERMS);
  EXPECT_EQ(SnapshotOptions(Check::CHK_PERMS).getCheckedPerms(), 0);
}

TEST(CompileTimeOptions, Permissions_RuntimeChanged) {
  __cheriseed_control_checks(Control::CTRL_ENABLE, Check::CHK_PERMS);
  EXPECT_EQ(SnapshotOptions(0).getCheckedPerms(), Check::CHK_PERMS);
  EXPECT_EQ(SnapshotOptions(Check::CHK_PERMS).getCheckedPerms(),
            Check::CHK_PERMS);

  __cheriseed_control_checks(Control::CTRL_DISABLE, Check::CHK_PERMS);
  EXPECT_EQ(SnapshotOptions(0).getCheckedPerms(), 0);
  EXPECT_EQ(SnapshotOptions(Check::CHK_PERMS).getCheckedPerms(), 0);
}

class PermissionTF1 : public ::testing::TestWithParam<uint64_t> {};

TEST_P(PermissionTF1, Permission) {
  EXPECT_EQ(SnapshotOptions(0).getCheckedPerms() & GetParam(), GetParam());
  EXPECT_EQ(SnapshotOptions(GetParam()).getCheckedPerms() & GetParam(), 0);
}

INSTANTIATE_TEST_SUITE_P(CompileTimeOptions, PermissionTF1,
                         testing::Values(ccl::permissions::LOAD,
                                         ccl::permissions::STORE,
                                         ccl::permissions::EXECUTE,
                                         ccl::permissions::LOAD_CAP,
                                         ccl::permissions::STORE_CAP));

class PermissionTF2 : public ::testing::TestWithParam<uint64_t> {};

TEST_P(PermissionTF2, Permission_RuntimeChanged) {
  __cheriseed_control_checks(Control::CTRL_ENABLE, GetParam());
  EXPECT_EQ(SnapshotOptions(0).getCheckedPerms() & GetParam(), GetParam());
  EXPECT_EQ(SnapshotOptions(GetParam()).getCheckedPerms() & GetParam(),
            GetParam());

  __cheriseed_control_checks(Control::CTRL_DISABLE, GetParam());
  EXPECT_EQ(SnapshotOptions(0).getCheckedPerms() & GetParam(), 0);
  EXPECT_EQ(SnapshotOptions(GetParam()).getCheckedPerms() & GetParam(), 0);
}

INSTANTIATE_TEST_SUITE_P(CompileTimeOptions, PermissionTF2,
                         testing::Values(ccl::permissions::LOAD,
                                         ccl::permissions::STORE,
                                         ccl::permissions::EXECUTE,
                                         ccl::permissions::LOAD_CAP,
                                         ccl::permissions::STORE_CAP));
