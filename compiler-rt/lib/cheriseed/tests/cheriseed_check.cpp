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
using __cheriseed::SnapshotOptions;
using utils::kExitCode;

TEST(CheckDeathTest, NormalExit) { EXPECT_NORMAL_EXIT(exit(0)); }

TEST(CheckDeathTest, CapabilityAddress) {
  const SnapshotOptions Opts;
  LocalCap local_cap(Opts);

  local_cap.SetAddress(nullptr);
  EXPECT_EXIT(CheckContext(local_cap).add(CapabilityAddress()),
              testing::ExitedWithCode(kExitCode),
              CHECK_ADDRESS_ERROR_MESSAGE_PATTERN);
#if defined(SANITIZER_LINUX)
  local_cap.SetAddress(reinterpret_cast<const __cheriseed_cap_t *>(
      __cheriseed::abi::kCapabilityMinAlignment));
  EXPECT_EXIT(CheckContext(local_cap).add(CapabilityAddress()),
              testing::ExitedWithCode(kExitCode),
              CHECK_ADDRESS_ERROR_MESSAGE_PATTERN);
#endif

#if defined(__aarch64__)
  local_cap.SetAddress(
      reinterpret_cast<const __cheriseed_cap_t *>((vaddr)1 << 55));
  EXPECT_EXIT(CheckContext(local_cap).add(CapabilityAddress()),
              testing::ExitedWithCode(kExitCode),
              CHECK_ADDRESS_ERROR_MESSAGE_PATTERN);
#endif
}

TEST(CheckDeathTest, CapabilityAlignment) {
  const SnapshotOptions Opts;
  LocalCap local_cap(Opts);
  local_cap.SetAddress(reinterpret_cast<const __cheriseed_cap_t *>(1));
  EXPECT_EXIT(CheckContext(local_cap).add(CapabilityAlignment()),
              testing::ExitedWithCode(kExitCode),
              CHECK_ALIGNMENT_ERROR_MESSAGE_PATTERN);
}

TEST(CheckDeathTest, NotImplemented) {
  const SnapshotOptions Opts;
  EXPECT_EXIT(CheckContext(LocalCap(Opts)).add(NotImplemented("")),
              testing::ExitedWithCode(kExitCode),
              CHECK_NOT_IMPLEMENTED_ERROR_MESSAGE_PATTERN);
}

TEST(CheckDeathTest, InBounds) {
  const SnapshotOptions Opts;
  __cheriseed_cap_t cap;
  __cheriseed_bounds_set(&cap, nullptr, 0);
  EXPECT_EXIT(CheckContext(LocalCap(Opts, &cap)).add(InBounds(UINT64_MAX)),
              testing::ExitedWithCode(kExitCode),
              CHECK_IN_BOUNDS_ERROR_MESSAGE_PATTERN);
}

TEST(CheckDeathTest, RequiredPerms) {
  const SnapshotOptions Opts;
  __cheriseed_cap_t cap;
  __cheriseed_perms_and(&cap, nullptr, 0);
  EXPECT_EXIT(CheckContext(LocalCap(Opts, &cap)).add(RequiredPerms(0xF)),
              testing::ExitedWithCode(kExitCode),
              CHECK_REQUIRED_PERMS_ERROR_MESSAGE_PATTERN);
}

TEST(CheckDeathTest, Tagged) {
  const SnapshotOptions Opts;
  LocalCap local_cap(Opts);
  local_cap.ClearTag();
  EXPECT_EXIT(CheckContext(local_cap).add(Tagged()),
              testing::ExitedWithCode(kExitCode),
              CHECK_IS_TAGGED_ERROR_MESSAGE_PATTERN);
}
