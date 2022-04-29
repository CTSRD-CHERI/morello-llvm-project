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

static constexpr int kExitCode = 1;

TEST(CheckDeathTest, NormalExit) { EXPECT_NORMAL_EXIT(exit(0)); }

TEST(CheckDeathTest, CapabilityAddress) {
  EXPECT_EXIT(CheckContext(nullptr).add(CapabilityAddress()),
              testing::ExitedWithCode(kExitCode),
              CHECK_ADDRESS_ERROR_MESSAGE_PATTERN);

#if defined(SANITIZER_LINUX)
  EXPECT_EXIT(CheckContext(reinterpret_cast<__cheriseed_cap_t*>(
                               __cheriseed::abi::kCapabilityMinAlignment))
                  .add(CapabilityAddress()),
              testing::ExitedWithCode(kExitCode),
              CHECK_ADDRESS_ERROR_MESSAGE_PATTERN);
#endif

#if defined(__aarch64__)
  EXPECT_EXIT(
      CheckContext(reinterpret_cast<__cheriseed_cap_t*>((uint64_t)1 << 55))
          .add(CapabilityAddress()),
      testing::ExitedWithCode(kExitCode), CHECK_ADDRESS_ERROR_MESSAGE_PATTERN);
#endif
}

TEST(CheckDeathTest, CapabilityAlignment) {
  EXPECT_EXIT(CheckContext(reinterpret_cast<__cheriseed_cap_t*>(1))
                  .add(CapabilityAlignment()),
              testing::ExitedWithCode(kExitCode),
              CHECK_ALIGNMENT_ERROR_MESSAGE_PATTERN);
}

TEST(CheckDeathTest, NotImplemented) {
  EXPECT_EXIT(CheckContext(nullptr).add(NotImplemented("")),
              testing::ExitedWithCode(kExitCode),
              CHECK_NOT_IMPLEMENTED_ERROR_MESSAGE_PATTERN);
}

TEST(CheckDeathTest, InBounds) {
  __cheriseed_cap_t cap = utils::InitCap(0, 0);
  __cheriseed_bounds_set(&cap, nullptr, 0);
  EXPECT_EXIT(CheckContext(&cap).add(InBounds(UINT64_MAX)),
              testing::ExitedWithCode(kExitCode),
              CHECK_IN_BOUNDS_ERROR_MESSAGE_PATTERN);
}

TEST(CheckDeathTest, RequiredPerms) {
  __cheriseed_cap_t cap = utils::InitCap(0, 0);
  __cheriseed_perms_and(&cap, nullptr, 0);
  EXPECT_EXIT(CheckContext(&cap).add(RequiredPerms(0xF)),
              testing::ExitedWithCode(kExitCode),
              CHECK_REQUIRED_PERMS_ERROR_MESSAGE_PATTERN);
}
