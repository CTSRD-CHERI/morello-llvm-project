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

#include "cheriseed_local_cap.h"
#include "sanitizer_common/sanitizer_common.h"
#include "sanitizer_common/sanitizer_file.h"
#include "sanitizer_common/sanitizer_linux.h"

using namespace __cheriseed::abi;
using namespace __sanitizer;

// Provide own implementation for GetPageSize().
// CHERIseed caches AT_PAGESZ early during process startup. This is required
// so that there is no need to call any libc APIs, such as getauxval(AT_PAGESZ)
// or sysconf(_SC_PAGESIZE), from within the sanitizer runtime. It might just
// happen that libc is not fully initialized when a capability violation occurs.
usize __sanitizer::GetPageSize() {
  return __cheriseed::Globals::SystemPageSize;
}

// Provide own implementation for GetPageSizeCached().
// See the reasoning at GetPageSize() above.
usize __sanitizer::GetPageSizeCachedCustom() {
  return __sanitizer::GetPageSize();
}

namespace __cheriseed {
namespace libc {

using uintptr_t = __UINTPTR_TYPE__;

// Libshim symbols the RT relies on.
extern "C" bool __shim_is_pure_capability();
extern "C" bool __shim_supports_cancellation_points();
extern "C" uintptr_t __shim_syscall(uintptr_t, uintptr_t, uintptr_t, uintptr_t,
                                    uintptr_t, uintptr_t, uintptr_t, uintptr_t,
                                    uintptr_t);

// For libc all checks are performed.
static constexpr AllOptionsEnabled LibcOpts;

// Returns true if targeting pure-capability ABI, otherwise false.
static bool IsPureCapabilityABI() { return __shim_is_pure_capability(); }

// Returns true if there is support for POSIX-like cancellation points.
static bool HasCancellationPoints() {
  return __shim_supports_cancellation_points();
}

// Helper to create a bounded capability.
static void CreateBoundedCap(__cheriseed_cap_t *cap, u64 address, u64 size,
                             u64 perms) {
  LocalCap local_cap{LibcOpts};
  LocalCapAdapter::BuildBoundedCap(local_cap, address, size, perms);
  local_cap.Store(cap);
}

// Helper to create a bounded capability.
static void CreateBoundedCap(__cheriseed_cap_t *cap, void *ptr, u64 size,
                             u64 perms) {
  CreateBoundedCap(cap, reinterpret_cast<u64>(ptr), size, perms);
}

// Helper to invoke a system call.
struct SystemCall final {
  // A system call argument
  struct Argument final {
    Argument() : data(0) {}

    template <typename I>
    Argument(I v) : data(static_cast<u64>(v)) {}

    operator uintptr_t() { return static_cast<uintptr_t>(data); }

   private:
    uintptr_t data;
  };  // Argument

  // A system call argument, but a capability
  struct CapArgument final {
    uintptr_t operator&() { return reinterpret_cast<uintptr_t>(this); }
    u64 Value() { return LocalCap{LibcOpts, &data}.GetValue(); }
    __cheriseed_cap_t *Data() { return &data; }

   private:
    __cheriseed_cap_t data;
  };  // CapArgument

  SystemCall(int nr) : num_args(0) {
    if (IsPureCapabilityABI())
      BuildArg(-1UL, 0, 0);
    // This is always a non-cancellable system call.
    if (HasCancellationPoints())
      BuildArg(0, 0, 0);

    Arg(nr);
  }

  template <typename I>
  SystemCall &Arg(I arg) {
    return BuildArg(static_cast<u64>(arg), 0, 0);
  }

  template <typename P>
  SystemCall &Arg(P *arg, u64 perms = ccl::permissions::LOAD) {
    return BuildArg(reinterpret_cast<u64>(arg), sizeof(*arg), perms);
  }

  long Call() {
    // Explicitly clear unused arguments.
    while (num_args < kMaxArgs) BuildArg(0, 0, 0);

    if (!IsPureCapabilityABI())
      return static_cast<long>(__shim_syscall(args[0], args[1], args[2],
                                              args[3], args[4], args[5],
                                              args[6], args[7], args[8]));

    if (HasCancellationPoints())
      __shim_syscall(/* indirect result */ &args_cap[0], /* cp */ &args_cap[1],
                     /* nr */ args_cap[2].Value(),
                     /* arg1 */ &args_cap[3], &args_cap[4], &args_cap[5],
                     &args_cap[6], &args_cap[7], /* arg6 */ &args_cap[8]);
    else
      __shim_syscall(/* indirect result */ &args_cap[0],
                     /* nr */ args_cap[1].Value(), /* arg1 */ &args_cap[2],
                     &args_cap[3], &args_cap[4], &args_cap[5], &args_cap[6],
                     /* arg6 */ &args_cap[7], /* unused */ &args_cap[8]);

    return static_cast<long>(args_cap[0].Value());
  }

 private:
  SystemCall &BuildArg(u64 arg, u64 size, u64 perms) {
    if (UNLIKELY(num_args == kMaxArgs))
      Trap();

    if (IsPureCapabilityABI()) {
      if (size)
        CreateBoundedCap(args_cap[num_args].Data(), arg, size, perms);
      else
        LocalCap{LibcOpts, arg, 0}.Store(args_cap[num_args].Data());
    } else {
      args[num_args] = arg;
    }

    ++num_args;
    return *this;
  }

  static constexpr usize kMaxArgs = 9;

  usize num_args;
  Argument args[kMaxArgs];
  CapArgument args_cap[kMaxArgs];
};  // SystemCall

static bool IsAtty(int fd) {
  struct {
    unsigned short _[4];
  } winsize;
  static constexpr int TIOCGWINSZ = 0x5413;

  long result =
      SystemCall(SyscallNumber::IOCTL)
          .Arg(fd)
          .Arg(TIOCGWINSZ)
          .Arg(&winsize, ccl::permissions::LOAD | ccl::permissions::STORE)
          .Call();
  return (result == 0);
}

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
    SystemCall(SyscallNumber::RT_SIGPROCMASK)
        .Arg(kBlock)
        .Arg(&set, ccl::permissions::READ_CAP_PERMS)
        .Arg(&old_set_, ccl::permissions::READ_CAP_PERMS |
                            ccl::permissions::WRITE_CAP_PERMS)
        .Arg(NSIG / 8)
        .Call();
  }

  ~ScopedSigProcMask() {
    SystemCall(SyscallNumber::RT_SIGPROCMASK)
        .Arg(kSetMask)
        .Arg(&old_set_, ccl::permissions::READ_CAP_PERMS)
        .Arg(0)
        .Arg(NSIG / 8)
        .Call();
  }

 private:
  static constexpr int kBlock = 0;
  static constexpr int kSetMask = 2;

  SigSet old_set_;
};  // struct ScopedSigProcMask

SigInfo::SigInfo(int signo, int code, vaddr addr) {
  if (IsPureCapabilityABI()) {
    purecap.signo = signo;
    purecap.code = code;
    LocalCap local_cap{LibcOpts};
    LocalCapAdapter::BuildMaxCap(local_cap, addr);
    local_cap.ReducePermissions(ccl::permissions::READ_CAP_PERMS |
                                ccl::permissions::EXECUTE);
    local_cap.Store(&purecap.addr);
  } else {
    hybrid.signo = signo;
    hybrid.code = code;
    hybrid.addr = addr;
  }
}

int SigInfo::SignalNumber() const {
  return IsPureCapabilityABI() ? purecap.signo : hybrid.signo;
}

void *SigInfo::operator&() {
  return IsPureCapabilityABI() ? reinterpret_cast<void *>(&purecap)
                               : reinterpret_cast<void *>(&hybrid);
}

SigAction::SigAction() {
  __sanitizer::internal_memset(this, 0, sizeof(*this));
  if (IsPureCapabilityABI())
    LocalCap{LibcOpts, kSigErr, 0}.Store(&purecap.handler);
  else
    hybrid.handler = kSigErr;
}

bool SigAction::GetAction(SignalNumber signo, SigAction &action) {
  SystemCall sc{SyscallNumber::RT_SIGACTION};
  // signum
  sc.Arg(signo);
  // act
  sc.Arg(0);
  // oldact
  if (IsPureCapabilityABI())
    sc.Arg(&action.purecap, ccl::permissions::READ_CAP_PERMS |
                                ccl::permissions::WRITE_CAP_PERMS);
  else
    sc.Arg(&action.hybrid);
  // sigsetsize
  sc.Arg(NSIG / 8);

  long result = sc.Call();
  if (result == 0)
    return true;

  // Failed, poison the handler so that HasHandler() returns false.
  if (IsPureCapabilityABI())
    LocalCap{LibcOpts, kSigErr, 0}.Store(&action.purecap.handler);
  else
    action.hybrid.handler = kSigErr;

  return false;
}

bool SigAction::SetDefaultAction(SignalNumber signo) {
  SigAction action;

  SystemCall sc{SyscallNumber::RT_SIGACTION};
  // signum
  sc.Arg(signo);
  // act
  if (IsPureCapabilityABI()) {
    action.purecap.flags = kRestart | kNoDefer;
    LocalCap{LibcOpts, kSigDfl, 0}.Store(&action.purecap.handler);
    sc.Arg(&action.purecap, ccl::permissions::READ_CAP_PERMS);
  } else {
    action.hybrid.flags = kRestart | kNoDefer;
    action.hybrid.handler = kSigDfl;
    sc.Arg(&action.hybrid);
  }
  // oldact
  sc.Arg(0);
  // sigsetsize
  sc.Arg(NSIG / 8);

  long result = sc.Call();
  if (result == 0)
    return true;

  // Failed, poison the handler so that HasHandler() returns false.
  if (IsPureCapabilityABI())
    LocalCap{LibcOpts, kSigErr, 0}.Store(&action.purecap.handler);
  else
    action.hybrid.handler = kSigErr;

  return false;
}

bool SigAction::HasHandler() const {
  u64 handler;
  if (IsPureCapabilityABI()) {
    LocalCap local_cap{LibcOpts, &purecap.handler};
    if (!local_cap.HasPermissions(ccl::permissions::LOAD |
                                  ccl::permissions::EXECUTE))
      return false;
    // TODO: Check tag when it gets implemented.
    handler = local_cap.GetValue();
  } else {
    handler = hybrid.handler;
  }

  switch (handler) {
    default:
      return true;
    case kSigErr:
    case kSigDfl:
    case kSigIgn:
      return false;
  }
}

SignalHandleMode SigAction::Invoke(SigInfo &info) {
  if (!HasHandler())
    return SignalHandleMode::SHM_DEFAULT;
  return IsPureCapabilityABI() ? InvokePureCap(info) : InvokeHybrid(info);
}

SignalHandleMode SigAction::InvokeHybrid(SigInfo &info) {
  // Create a new set and add the current signo if SA_NODEFER is unset.
  SigSet set = hybrid.mask;
  if ((hybrid.flags & kNoDefer) == 0)
    set.Add(info.SignalNumber());

  SignalHandleMode mode = SignalHandleMode::SHM_DEFAULT;

  ScopedSigProcMask scope{set};
  reinterpret_cast<HandlerType>(hybrid.handler)(info.SignalNumber(), &info,
                                                &mode);
  return mode;
}

SignalHandleMode SigAction::InvokePureCap(SigInfo &info) {
  // Prepare 2nd argument
  __cheriseed_cap_t cap_info;
  CreateBoundedCap(
      &cap_info, &info, sizeof(info),
      ccl::permissions::READ_CAP_PERMS | ccl::permissions::WRITE_CAP_PERMS);
  // Prepare 3rd argument
  SignalHandleMode mode = SignalHandleMode::SHM_DEFAULT;
  __cheriseed_cap_t cap_mode;

  CreateBoundedCap(&cap_mode, &mode, sizeof(mode), ccl::permissions::STORE);
  // Create a new set and add the current signo if SA_NODEFER is unset.
  SigSet set = purecap.mask;
  if ((purecap.flags & kNoDefer) == 0)
    set.Add(info.SignalNumber());

  ScopedSigProcMask scope{set};

  reinterpret_cast<HandlerType>(
      LocalCap{LibcOpts, &purecap.handler}.GetValue())(info.SignalNumber(),
                                                       &cap_info, &cap_mode);
  return mode;
}

int GetPid() {
  return static_cast<int>(SystemCall(SyscallNumber::GETPID).Call());
}

void Raise(int pid, SignalNumber signo) {
  SystemCall(SyscallNumber::KILL).Arg(pid).Arg(signo).Call();
}

}  // namespace libc
}  // namespace __cheriseed

bool __sanitizer::ColorizeReports() {
  if (!__cheriseed::libc::IsAtty(kStdoutFd))
    return false;

  const char *flag = common_flags()->color;
  return internal_strcmp(flag, "always") == 0 ||
         (internal_strcmp(flag, "auto") == 0);
}
