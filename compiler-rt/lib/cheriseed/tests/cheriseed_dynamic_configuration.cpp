//===-- cheriseed_check.cpp -------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// Unit tests for various capability-related checks.
//
//===----------------------------------------------------------------------===//

#define CHERISEED_UNIT_TESTING

#include "cheriseed_errors.h"
#include "cheriseed_test_utils.h"

using namespace __cheriseed::error;
using __cheriseed::ControlChecksDynamic;
using __cheriseed::Environment;
using utils::kExitCode;
using utils::OnStackArgs;

TEST(CheckDeathTest, DynamicConfiguration1) {
  const char *checks = "CHERISEED_CHECKS=,";
  OnStackArgs args(&checks[0]);
  Environment env = Environment::From(args.GetAddress());
  EXPECT_EXIT(ControlChecksDynamic(env), testing::ExitedWithCode(kExitCode),
              CHECK_DYNAMIC_CONFIGURATION_ERROR_PATTERN(0, ",", "\\^"));
}

TEST(CheckDeathTest, DynamicConfiguration2) {
  const char *checks = "CHERISEED_CHECKS=-";
  OnStackArgs args(&checks[0]);
  Environment env = Environment::From(args.GetAddress());
  EXPECT_EXIT(ControlChecksDynamic(env), testing::ExitedWithCode(kExitCode),
              CHECK_DYNAMIC_CONFIGURATION_ERROR_PATTERN(0, "-", "\\^"));
}

TEST(CheckDeathTest, DynamicConfiguration3) {
  const char *checks = "CHERISEED_CHECKS=LOAD,,";
  OnStackArgs args(&checks[0]);
  Environment env = Environment::From(args.GetAddress());
  EXPECT_EXIT(
      ControlChecksDynamic(env), testing::ExitedWithCode(kExitCode),
      CHECK_DYNAMIC_CONFIGURATION_ERROR_PATTERN(5, "LOAD,,", "     \\^"));
}

TEST(CheckDeathTest, DynamicConfiguration4) {
  const char *checks = "CHERISEED_CHECKS=LOAD,-,";
  OnStackArgs args(&checks[0]);
  Environment env = Environment::From(args.GetAddress());
  EXPECT_EXIT(
      ControlChecksDynamic(env), testing::ExitedWithCode(kExitCode),
      CHECK_DYNAMIC_CONFIGURATION_ERROR_PATTERN(5, "LOAD,-,", "     \\^"));
}

TEST(CheckDeathTest, DynamicConfiguration5) {
  const char *checks = "CHERISEED_CHECKS=LOAD,FOO";
  OnStackArgs args(&checks[0]);
  Environment env = Environment::From(args.GetAddress());
  EXPECT_EXIT(
      ControlChecksDynamic(env), testing::ExitedWithCode(kExitCode),
      CHECK_DYNAMIC_CONFIGURATION_ERROR_PATTERN(5, "LOAD,FOO", "     \\^"));
}

TEST(CheckDeathTest, DynamicConfiguration6) {
  const char *checks = "CHERISEED_CHECKS=LOAD,-FOO";
  OnStackArgs args(&checks[0]);
  Environment env = Environment::From(args.GetAddress());
  EXPECT_EXIT(
      ControlChecksDynamic(env), testing::ExitedWithCode(kExitCode),
      CHECK_DYNAMIC_CONFIGURATION_ERROR_PATTERN(5, "LOAD,-FOO", "     \\^"));
}
