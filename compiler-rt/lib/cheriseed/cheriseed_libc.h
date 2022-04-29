//===-- cheriseed_libc.h ----------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// This file defines minimal libc support for the sanitizer.
//
//===----------------------------------------------------------------------===//

#ifndef CHERISEED_LIBC_H
#define CHERISEED_LIBC_H

#include "cheriseed_abi_defs.h"

using namespace __sanitizer;

namespace __cheriseed {
namespace libc {

// Some signal numbers
enum SignalNumber : int {
  SN_NONE = 0,
  SN_SIGTRAP = 5,
  SN_SIGBUS = 7,
  SN_SIGSEGV = 11,
};  // enum SignalNumber

// Custom siginfo passed by the runtime library.
struct SigInfo final {
  SigInfo(int signo, int code, vaddr addr);

  int SignalNumber() const { return signo; }

  // Protected: no access for non-friends, there is no error for unused private
  // field.
 protected:
  int signo;
  int errno;
  int code;
  __cheriseed_cap_t addr;
  short addr_lsb;
};  // struct SigInfo

struct SignalHandler final {
  // Type of an instrumented signal handler when called from the RT library.
  using Type = void (*)(int, __cheriseed_cap_t *, __cheriseed_cap_t *);
  // SIG_ERR
  static constexpr vaddr kSigErr = static_cast<vaddr>(-1);
  // SIG_DFL
  static constexpr vaddr kSigDfl = static_cast<vaddr>(0);
  // SIG_IGN
  static constexpr vaddr kSigIgn = static_cast<vaddr>(1);
};  // struct SignalHandler

// This is sigset_t, used for both libc and kernel.
struct SigSet final {
  // Protected: no access for non-friends, there is no error for unused private
  // field.
 protected:
  // libc might use smaller type, but that's fine.
  usize mask[128 / sizeof(usize)];
};  // struct SigSet

// The sigaction struct to set and retrieve signal actions.
struct SigAction final {
  static constexpr int kNoDefer = 0x40000000;

  explicit SigAction() { handler.value = SignalHandler::kSigErr; }

  static bool GetAction(int signum, SigAction &action);

  bool HasHandler() const;

  // Calls the signal handler. The only real difference from real signals is
  // that the call is on the current stack. Returns the mode to handle the
  // signal.
  SignalHandleMode Invoke(SigInfo &info);

  // Protected: no access for non-friends, there is no error for unused private
  // field.
 protected:
  // As passed to the instrumented libc.
  __cheriseed_cap_t handler;
  SigSet mask;
  int flags;
  __cheriseed_cap_t restorer;
};  // struct SigAction

// Returns the PID of the tracer process, or '0'.
pid_t GetTracerPid();

// Raises a SIGTRAP signal.
void RaiseSigTrap();

}  // namespace libc
}  // namespace __cheriseed

#endif  // CHERISEED_LIBC_H
