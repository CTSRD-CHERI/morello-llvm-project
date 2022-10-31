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

#include "cheriseed_common.h"

namespace __cheriseed {
namespace libc {

// Auxiliary value constants.
static constexpr u64 AT_PAGESZ = 6;

// Some system call numbers [Linux/arch specific]
enum SyscallNumber : int {
#if defined(__aarch64__)
  IOCTL = 29,
  GETPID = 172,
  KILL = 129,
  RT_SIGACTION = 134,
  RT_SIGPROCMASK = 1345,
#elif defined(__x86_64__)
  IOCTL = 16,
  GETPID = 39,
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
  SN_SIGBUS = 7,
  SN_SIGSEGV = 11,
};  // enum SignalNumber

// Custom siginfo passed by the runtime library.
struct SigInfo final {
  SigInfo(int signo, int code, vaddr addr);

  // Returns signo.
  int SignalNumber() const;

  void *operator&();

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
  // This is SA_RESTART flag.
  static constexpr int kRestart = 0x10000000;
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
  static bool GetAction(SignalNumber signo, SigAction &action);

  // Sets the handler of a signal to the default handler.
  static bool SetDefaultAction(SignalNumber signo);

  // Returns true if handler is valid.
  bool HasHandler() const;

  // Calls the signal handler. The only real difference from real signals is
  // that the call is on the current stack. Returns the mode to handle the
  // signal.
  abi::SignalHandleMode Invoke(SigInfo &info);

  // Protected: no access for non-friends, there is no error for unused private
  // field.
 protected:
  abi::SignalHandleMode InvokeHybrid(SigInfo &info);
  abi::SignalHandleMode InvokePureCap(SigInfo &info);

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

// Returns the PID of the calling process.
int GetPid();

// Raises a signal.
void Raise(int pid, SignalNumber signo);

}  // namespace libc
}  // namespace __cheriseed

#endif  // CHERISEED_LIBC_H
