//===-- CrashReasonTest.cpp -----------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "Plugins/Process/POSIX/CrashReason.h"

#include "lldb/Host/FileSystem.h"
#include "lldb/Host/HostInfo.h"

#include "gtest/gtest.h"

#ifndef SEGV_CAPTAGERR
#define SEGV_CAPTAGERR 10
#endif

#ifndef SEGV_CAPSEALEDERR
#define SEGV_CAPSEALEDERR 11
#endif

#ifndef SEGV_CAPBOUNDSERR
#define SEGV_CAPBOUNDSERR 12
#endif

#ifndef SEGV_CAPPERMERR
#define SEGV_CAPPERMERR 13
#endif

#ifndef SEGV_CAPACCESSERR
#define SEGV_CAPACCESSERR 14
#endif

using namespace lldb_private;

namespace {
struct CrashReasonTestInfo {
  // Test inputs (will be put in a siginfo_t).
  int si_code;

  // Test outputs.
  const char *description;
};

class CrashReasonTest : public testing::Test {
public:
  static void SetUpTestCase() {
    FileSystem::Initialize();
    HostInfo::Initialize();
  }
  static void TearDownTestCase() {
    HostInfo::Terminate();
    FileSystem::Terminate();
  }
};
} // namespace

TEST_F(CrashReasonTest, ReasonAndDescriptionForSIGSEGV) {
  const std::vector<CrashReasonTestInfo> crashReasonTestInfos = {
      {SEGV_CAPTAGERR,
       "signal SIGSEGV: capability tag fault (fault address: 0x1234)"},
      {SEGV_CAPSEALEDERR,
       "signal SIGSEGV: capability sealed fault (fault address: 0x1234)"},
      {SEGV_CAPBOUNDSERR,
       "signal SIGSEGV: upper bound violation (fault address: 0x1234, lower "
       "bound: 0x1000, upper bound: 0x1010)"},
      {SEGV_CAPPERMERR,
       "signal SIGSEGV: capability permission fault (fault address: 0x1234)"},
      {SEGV_CAPACCESSERR,
       "signal SIGSEGV: capability access fault (fault address: 0x1234)"},
  };

  for (const CrashReasonTestInfo &t : crashReasonTestInfos) {
    siginfo_t info;
    info.si_signo = SIGSEGV;
    info.si_code = t.si_code;
    info.si_addr = (void *)(uintptr_t)0x1234;
    info.si_lower = (void *)(uintptr_t)0x1000;
    info.si_upper = (void *)(uintptr_t)0x1010;
    EXPECT_EQ(t.description, GetCrashReasonString(info));
  }
}
