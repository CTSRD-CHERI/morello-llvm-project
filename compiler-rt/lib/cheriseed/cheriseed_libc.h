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

// Some system call numbers [Linux/arch specific]
enum SyscallNumber : int {
#if defined(__aarch64__)
  IOCTL = 29,
  KILL = 129,
  RT_SIGACTION = 134,
  RT_SIGPROCMASK = 1345,
#elif defined(__x86_64__)
  IOCTL = 16,
  KILL = 62,
  RT_SIGACTION = 13,
  RT_SIGPROCMASK = 14,
#endif
};  // enum SyscallNumber

#if defined(__aarch64__) || defined(__x86_64__)
// Number of signals [Linux/arch specific]
static constexpr int NSIG = 65;
#endif

// Some signal numbers [Linux specific]
enum SignalNumber : int {
  SN_NONE = 0,
  SN_SIGTRAP = 5,
  SN_SIGBUS = 7,
  SN_SIGSEGV = 11,
};  // enum SignalNumber

// Custom siginfo passed by the runtime library.
struct SigInfo final {
  SigInfo(int signo, int code, vaddr addr);

  // Returns signo.
  int SignalNumber() const;

  // Protected: no access for non-friends, there is no error for unused private
  // field.
 protected:
  struct {
    int signo;
    int errno;
    int code;
    vaddr addr;
    short addr_lsb;
  } hybrid;
  struct {
    int signo;
    int errno;
    int code;
    __cheriseed_cap_t addr;
    short addr_lsb;
  } purecap;
};  // struct SigInfo

// This is sigset_t, used for both libc and kernel.
struct SigSet final {
  // Adds a signal to the set.
  void Add(int sig) {
    usize bit = static_cast<usize>(sig) - 1;
    mask[bit / SizeInBits()] |= static_cast<usize>(1) << (bit % SizeInBits());
  }

  // Protected: no access for non-friends, there is no error for unused private
  // field.
 protected:
  using TY = usize;

  static constexpr usize SizeInBits() { return 8 * sizeof(TY); }

  // libc might use smaller type, but that's fine.
  TY mask[128 / sizeof(TY)];
};  // struct SigSet

// The sigaction struct to set and retrieve signal actions.
struct SigAction final {
  // This is SA_NODEFER flag.
  static constexpr int kNoDefer = 0x40000000;
  // SIG_ERR
  static constexpr vaddr kSigErr = static_cast<vaddr>(-1);
  // SIG_DFL
  static constexpr vaddr kSigDfl = static_cast<vaddr>(0);
  // SIG_IGN
  static constexpr vaddr kSigIgn = static_cast<vaddr>(1);
  // Type of a signal handler.
  using HandlerType = void (*)(int, void *, void *);

  explicit SigAction();

  // Queries if an action is set for a specific signal.
  static bool GetAction(int signum, SigAction &action);

  // Returns true if handler is valid.
  bool HasHandler() const;

  // Calls the signal handler. The only real difference from real signals is
  // that the call is on the current stack. Returns the mode to handle the
  // signal.
  SignalHandleMode Invoke(SigInfo &info);

  // Protected: no access for non-friends, there is no error for unused private
  // field.
 protected:
  SignalHandleMode InvokeHybrid(SigInfo &info);
  SignalHandleMode InvokePureCap(SigInfo &info);

  struct {
    vaddr handler;
    SigSet mask;
    int flags;
    vaddr restorer;
  } hybrid;
  struct {
    __cheriseed_cap_t handler;
    SigSet mask;
    int flags;
    __cheriseed_cap_t restorer;
  } purecap;
};  // struct SigAction

// Returns the PID of the tracer process, or '0'.
pid_t GetTracerPid();

// Raises a SIGTRAP signal.
void RaiseSigTrap();

}  // namespace libc
}  // namespace __cheriseed

#endif  // CHERISEED_LIBC_H
