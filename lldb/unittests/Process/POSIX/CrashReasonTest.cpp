//===-- CrashReasonTest.cpp -----------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "Plugins/Process/POSIX/CrashReason.h"

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

namespace {
struct CrashReasonTestInfo {
  // Test inputs (will be put in a siginfo_t).
  int si_code;

  // Test outputs.
  const char *description;
};
} // namespace

TEST(CrashReasonTest, ReasonAndDescriptionForSIGSEGV) {
  const std::vector<CrashReasonTestInfo> crashReasonTestInfos = {
      {SEGV_CAPTAGERR, "signal SIGSEGV: capability tag fault"},
      {SEGV_CAPSEALEDERR, "signal SIGSEGV: capability sealed fault"},
      {SEGV_CAPBOUNDSERR, "signal SIGSEGV: capability bounds fault"},
      {SEGV_CAPPERMERR, "signal SIGSEGV: capability permission fault"},
      {SEGV_CAPACCESSERR, "signal SIGSEGV: capability access fault"},
  };

  for (const CrashReasonTestInfo &t : crashReasonTestInfos) {
    siginfo_t info;
    info.si_signo = SIGSEGV;
    info.si_code = t.si_code;
    EXPECT_EQ(t.description, GetCrashReasonString(info));
  }
}
