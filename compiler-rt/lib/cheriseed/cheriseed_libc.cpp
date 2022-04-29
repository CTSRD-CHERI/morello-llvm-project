//===-- cheriseed_libc.cpp --------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// This file implements minimal libc support for the sanitizer.
// It interfaces with the ***instrumented*** libc, therefore only a very
// limited subset of features are available.
//
//===----------------------------------------------------------------------===//

#include "cheriseed_libc.h"

#include "cheriseed_ccl_interface.h"
#include "sanitizer_common/sanitizer_common.h"
#include "sanitizer_common/sanitizer_file.h"
#include "sanitizer_common/sanitizer_linux.h"

using namespace __cheriseed;
using namespace __sanitizer;

// Declaration of instrumented libc functions the runtime uses directly.
extern "C" int isatty(int fd);
extern "C" int kill(pid_t pid, int sig);
extern "C" int sigaction(int, const __cheriseed_cap_t *, __cheriseed_cap_t *);
extern "C" int sigprocmask(int how, const __cheriseed_cap_t *set,
                           __cheriseed_cap_t *old);
extern "C" int sigaddset(__cheriseed_cap_t *, int);

bool __sanitizer::ColorizeReports() {
  if (!isatty(kStdoutFd))
    return false;

  const char *flag = common_flags()->color;
  return internal_strcmp(flag, "always") == 0 ||
         (internal_strcmp(flag, "auto") == 0);
}

namespace __cheriseed {
namespace libc {

struct ScopedOpenFd final {
  ScopedOpenFd(const char *path, FileAccessMode mode) {
    fd = OpenFile(path, mode);
  }

  ~ScopedOpenFd() {
    if (IsFdValid())
      CloseFile(fd);
  }

  operator bool() const { return IsFdValid(); }
  bool IsFdValid() const { return !internal_iserror(static_cast<uptr>(fd)); }

  usize Read(void *buffer, usize buffer_size) {
    usize bytes_read;
    return ReadFromFile(fd, buffer, buffer_size, &bytes_read) ? bytes_read : 0;
  }

 private:
  fd_t fd;
};  // struct ScopedOpenFd

struct ScopedSigProcMask final {
  ScopedSigProcMask(SigSet &set) {
    __cheriseed_cap_t cap_set;
    ccl::BuildBoundedCap(&cap_set, &set, ccl::permissions::READ_CAP_PERMS);
    ccl::BuildBoundedCap(
        &cap_old_set_, &old_set_,
        ccl::permissions::READ_CAP_PERMS | ccl::permissions::WRITE_CAP_PERMS);
    sigprocmask(kBlock, &cap_set, &cap_old_set_);
  }

  ~ScopedSigProcMask() { sigprocmask(kSetMask, &cap_old_set_, nullptr); }

  static constexpr int kBlock = 0;
  static constexpr int kSetMask = 2;

 private:
  SigSet old_set_;
  __cheriseed_cap_t cap_old_set_;
};  // struct ScopedSigProcMask

SigInfo::SigInfo(int signo, int code, vaddr addr) {
  this->signo = signo;
  this->errno = 0;
  this->code = code;
  ccl::BuildMaxCap(&this->addr, addr);
  ccl::UpdatePermsAnd(&this->addr, ccl::permissions::READ_CAP_PERMS |
                                       ccl::permissions::EXECUTE);
  this->addr_lsb = 0;
}

bool SigAction::HasHandler() const {
  const u64 required_perms = ccl::permissions::LOAD | ccl::permissions::EXECUTE;
  if ((ccl::PermsGet(&handler) & required_perms) != required_perms)
    return false;
  // TODO: tag

  switch (handler.value) {
    default:
      return true;
    case SignalHandler::kSigErr:
    case SignalHandler::kSigDfl:
    case SignalHandler::kSigIgn:
      return false;
  }
}

bool SigAction::GetAction(int signum, SigAction &action) {
  __cheriseed_cap_t cap_action;
  ccl::BuildBoundedCap(
      &cap_action, &action,
      ccl::permissions::READ_CAP_PERMS | ccl::permissions::WRITE_CAP_PERMS);
  if (0 == sigaction(signum, nullptr, &cap_action))
    return true;
  // Failed, poison the handler so that HasHandler() returns false.
  action.handler.value = SignalHandler::kSigErr;
  return false;
}

SignalHandleMode SigAction::Invoke(SigInfo &info) {
  if (!HasHandler())
    return SignalHandleMode::SHM_DEFAULT;

  __cheriseed_cap_t cap_info;
  ccl::BuildBoundedCap(
      &cap_info, &info,
      ccl::permissions::READ_CAP_PERMS | ccl::permissions::WRITE_CAP_PERMS);

  SignalHandleMode mode = SignalHandleMode::SHM_DEFAULT;
  __cheriseed_cap_t cap_mode;
  ccl::BuildBoundedCap(&cap_mode, &mode, ccl::permissions::STORE);

  // Create a new set and add the current signo if SA_NODEFER is unset.
  SigSet set = mask;
  if ((flags & kNoDefer) == 0) {
    __cheriseed_cap_t cap_set;
    ccl::BuildBoundedCap(&cap_set, &set,
                         ccl::permissions::LOAD | ccl::permissions::STORE);
    sigaddset(&cap_set, info.SignalNumber());
  }

  ScopedSigProcMask _{set};
  reinterpret_cast<SignalHandler::Type>(handler.value)(info.SignalNumber(),
                                                       &cap_info, &cap_mode);
  return mode;
}

pid_t GetTracerPid() {
  static const char TracerPid[] = "TracerPid:";

  ScopedOpenFd status{"/proc/self/status", FileAccessMode::RdOnly};
  if (!status)
    return false;

  InternalMmapVector<char> buffer{GetPageSizeCached()};
  status.Read(buffer.data(), buffer.capacity() - 1);
  const char *tracer_pid_pos = internal_strstr(buffer.data(), TracerPid);
  if (!tracer_pid_pos)
    return false;

  tracer_pid_pos += sizeof(TracerPid) - 1 /* terminating '\0' */;
  return static_cast<pid_t>(internal_atoll(tracer_pid_pos));
}

void RaiseSigTrap() { kill(0, SignalNumber::SN_SIGTRAP); }

}  // namespace libc
}  // namespace __cheriseed
