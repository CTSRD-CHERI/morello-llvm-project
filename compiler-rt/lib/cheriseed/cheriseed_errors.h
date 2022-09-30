//===-- cheriseed_errors.h --------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// This file defines the errors the sanitizer might produce runtime.
//
//===----------------------------------------------------------------------===//

#ifndef CHERISEED_ERRORS_H
#define CHERISEED_ERRORS_H

#include "cheriseed_ccl_interface.h"
#include "cheriseed_libc.h"
#include "cheriseed_shadow_memory.h"
#include "sanitizer_common/sanitizer_common.h"

namespace __cheriseed {
namespace error {

// Decorator to create brightly colored reports.
struct Decorator final {
  explicit Decorator() : colorize(__sanitizer::ColorizeReports()) {}

  const char* Reset() const { return colorize ? "\033[0m" : ""; }
  const char* Red() const { return colorize ? "\033[31m" : ""; }
  const char* Green() const { return colorize ? "\033[32m" : ""; }
  const char* Yellow() const { return colorize ? "\033[33m" : ""; }
  const char* Magenta() const { return colorize ? "\033[35m" : ""; }
  const char* Cyan() const { return colorize ? "\033[36m" : ""; }

  const bool colorize;
};  // struct Decorator

// Helper class to build messages in a nicely formatted fashion.
struct MessageBuilder final {
  explicit MessageBuilder() {}

  struct Error final {
    Error(const char* msg) : msg(msg) {}
    const char* msg;
  };

  struct Info final {
    Info(const char* msg) : msg(msg) {}
    const char* msg;
  };

  struct Permission final {
    Permission(u64 perm, bool explain) : perm(perm), explain(explain) {}
    const char* LongName() const;
    const char* ShortName() const;
    const u64 perm;
    const bool explain;
  };

  struct Attribute final {
    Attribute(const char* msg) : msg(msg) {}
    const char* msg;
  };

  struct Hex final {
    Hex(u64 value) : value(value) {}
    u64 value;
  };

  MessageBuilder& operator<<(const MessageBuilder& other);
  MessageBuilder& operator<<(const char* str);
  MessageBuilder& operator<<(const vaddr addr);
  MessageBuilder& operator<<(const u64 value);
  MessageBuilder& operator<<(const MemoryRange& range);
  MessageBuilder& operator<<(const Error error);
  MessageBuilder& operator<<(const Info info);
  MessageBuilder& operator<<(const Permission perm);
  MessageBuilder& operator<<(const Attribute attr);
  MessageBuilder& operator<<(const Hex value);
  MessageBuilder& operator<<(const ShadowMemory& helper);

  void WriteToStderr();

  Decorator D;
  __sanitizer::InternalScopedString message;
};

// Helper to perform various property checks.
struct CheckContext {
  explicit CheckContext(const LocalCap& local_cap) : local_cap(local_cap) {}

  template <typename P>
  ALWAYS_INLINE CheckContext& add(P&& property) {
    if (LIKELY(property.DoCheck(*this)))
      return *this;
    pc = GET_CALLER_PC();
    BeginTerminate(property);
    return *this;
  }

  // Returns the address of the capability itself.
  vaddr CapabilityAddress() const { return local_cap.GetAddress(); }

  // Methods to retrieve fields of the capability.
  vaddr Value() const { return local_cap.GetValue(); }
  vaddr Metadata() const { return local_cap.GetMetadata(); }
  bool IsTagged() const { return local_cap.IsTagged(); }
  vaddr Base() const { return ccl::methods::GetBase(local_cap); }
  vaddr Top() const { return ccl::methods::GetTop(local_cap); }
  u64 Perms() const { return ccl::methods::GetPerms(local_cap); }

  void PrintCapability(MessageBuilder& builder) const;
  void PrintTagAddress(MessageBuilder& builder) const;

  const Options& GetOpts() const { return local_cap.GetOpts(); }

 protected:
  template <typename P>
  NOINLINE void BeginTerminate(P& property) {
    // Make sure that recursive aborts are not allowed.
    if (UNLIKELY(atomic_fetch_add(&Globals::IsTerminating, 1,
                                  memory_order::memory_order_relaxed) > 0))
      __sanitizer::Trap();
    // Fully initialize the checker's context.
    Initialize();
    // Get reason for failure.
    MessageBuilder reason;
    property.ReportError(*this, reason);
    // Try to terminate.
    Terminate(reason, P::SignalNumber(), P::Code());
    // Not aborting in the end.
    atomic_fetch_sub(&Globals::IsTerminating, 1,
                     memory_order::memory_order_relaxed);
  }

  void Initialize();
  NOINLINE void Terminate(MessageBuilder& builder, libc::SignalNumber signo,
                          abi::SignalCode code) const;

  const LocalCap& local_cap;
  vaddr pc;
  u64 tid;
};  // struct CheckContext

// Note: not using base class and virtual functions here because those are
// not de-virtualized, even with -O3. This code is less elegant but the
// resulting code size is significantly smaller and avoids calls through
// vtables. It also does not depend on __cxa_pure_virtual, which would
// otherwise be necessary with virtual destructors.

// Checks that the pointer to a capability has a valid address.
struct CapabilityAddress final {
  ALWAYS_INLINE
  bool DoCheck(const CheckContext& ctx) const {
    const vaddr cap_addr = ctx.CapabilityAddress();
    bool failed = (cap_addr == 0);
#if defined(__aarch64__)
    failed |= (cap_addr & (static_cast<vaddr>(1) << 55)) != 0;
#endif
#if defined(SANITIZER_LINUX)
    // Check for address on the first page, which is never accessible.
    failed |= cap_addr < Globals::SystemPageSize;
#endif
    return !failed;
  }

  void ReportError(const CheckContext& ctx, MessageBuilder& builder) const;

  static constexpr abi::SignalCode Code() {
    return abi::SignalCode::SC_SEGV_MAPERR;
  }

  static constexpr libc::SignalNumber SignalNumber() {
    return libc::SignalNumber::SN_SIGSEGV;
  }
};  // struct CapabilityAddress

// Checks that a capability is sufficiently aligned.
struct CapabilityAlignment final {
  ALWAYS_INLINE
  bool DoCheck(const CheckContext& ctx) const {
    if (!ctx.GetOpts().shouldCheckAlignment())
      return true;
    return (ctx.CapabilityAddress() % abi::kCapabilityMinAlignment) == 0;
  }

  void ReportError(const CheckContext& ctx, MessageBuilder& builder) const;

  static constexpr abi::SignalCode Code() {
    return abi::SignalCode::SC_BUS_ADRALN;
  }

  static constexpr libc::SignalNumber SignalNumber() {
    return libc::SignalNumber::SN_SIGBUS;
  }
};  // struct CapabilityAlignment

// Reports that something is not implemented.
struct NotImplemented final {
  explicit NotImplemented(const char* msg) : msg(msg) {}
  bool DoCheck(const CheckContext& ctx) const { return false; }
  void ReportError(const CheckContext& ctx, MessageBuilder& builder) const;

  static constexpr abi::SignalCode Code() {
    return abi::SignalCode::SC_PROT_NOT_IMPLEMENTED;
  }

  static constexpr libc::SignalNumber SignalNumber() {
    return libc::SignalNumber::SN_NONE;
  }

  const char* msg;
};  // struct NotImplemented

// Checks that an access of a given size would not exceed the bounds of the
// capability
struct InBounds final {
  explicit InBounds(u64 size) : size(size) {}

  ALWAYS_INLINE
  bool DoCheck(const CheckContext& ctx) const {
    if (!ctx.GetOpts().shouldCheckBounds())
      return true;
    // Top (base + length) is not inclusive in acceptable range of a capability.
    // Since size is taken as-is base <= cursor <= top is correct.
    return (ctx.Base() <= ctx.Value()) && ((ctx.Value() + size) <= ctx.Top());
  }

  void ReportError(const CheckContext& ctx, MessageBuilder& builder) const;

  static constexpr abi::SignalCode Code() {
    return abi::SignalCode::SC_SEGV_CAPBOUNDSERR;
  }

  static constexpr libc::SignalNumber SignalNumber() {
    return libc::SignalNumber::SN_SIGSEGV;
  }

  const __sanitizer::u64 size;
};  // struct InBounds

// Checks that a capability has all required permissions to perform an action
// which requires at least 'perms'.
struct RequiredPerms final {
  explicit RequiredPerms(u64 perms) : perms(perms) {}

  ALWAYS_INLINE
  bool DoCheck(const CheckContext& ctx) {
    const u64 mask = ctx.GetOpts().getCheckedPerms();
    return ((ctx.Perms() & perms & mask) == (perms & mask));
  }

  void ReportError(const CheckContext& ctx, MessageBuilder& builder) const;

  static constexpr abi::SignalCode Code() {
    return abi::SignalCode::SC_SEGV_CAPPERMERR;
  }

  static constexpr libc::SignalNumber SignalNumber() {
    return libc::SignalNumber::SN_SIGSEGV;
  }

  const u64 perms;
};  // struct RequiredPerms

// Checks that a capability is tagged.
struct Tagged final {
  ALWAYS_INLINE
  bool DoCheck(const CheckContext& ctx) {
    if (!ctx.GetOpts().shouldCheckTag())
      return true;
    return ctx.IsTagged();
  }

  void ReportError(const CheckContext& ctx, MessageBuilder& builder);

  static constexpr abi::SignalCode Code() {
    return abi::SignalCode::SC_SEGV_CAPTAGERR;
  }

  static constexpr libc::SignalNumber SignalNumber() {
    return libc::SignalNumber::SN_SIGSEGV;
  }
};  // struct Tagged

// Reports a malformed CHERISEED_CHECKS environment variable.
struct DynamicControlError final {
  explicit DynamicControlError(const char* const start,
                               const char* const cursor)
      : start(start), cursor(cursor) {}
  bool DoCheck(const CheckContext& ctx) const { return false; }
  void ReportError(const CheckContext& ctx, MessageBuilder& builder) const;

  static constexpr abi::SignalCode Code() {
    return abi::SignalCode::SC_PROT_NOT_IMPLEMENTED;
  }

  static constexpr libc::SignalNumber SignalNumber() {
    return libc::SignalNumber::SN_NONE;
  }

  const char* start;
  const char* cursor;
};  // struct DynamicControlError

// Prints 'DynamicControl' help as info message.
struct DynamicControlHelpInfo final {
  bool DoCheck(const CheckContext& ctx) const { return false; }
  void ReportError(const CheckContext& ctx, MessageBuilder& builder) const;

  static constexpr abi::SignalCode Code() {
    return abi::SignalCode::SC_INFO_MESSAGE;
  }

  static constexpr libc::SignalNumber SignalNumber() {
    return libc::SignalNumber::SN_NONE;
  }
};  // struct PrettyPrintHelp

}  // namespace error
}  // namespace __cheriseed

#endif  // CHERISEED_ERRORS_H
