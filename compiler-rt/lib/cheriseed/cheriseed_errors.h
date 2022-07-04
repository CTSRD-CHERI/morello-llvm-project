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
#include "sanitizer_common/sanitizer_common.h"

namespace __cheriseed {
namespace error {

// Decorator to create brightly colored reports.
struct Decorator final {
  explicit Decorator() : colorize(__sanitizer::ColorizeReports()) {}

  const char* Reset() const { return colorize ? "\033[0m" : ""; }
  const char* Red() const { return colorize ? "\033[31m" : ""; }
  const char* Green() const { return colorize ? "\033[32m" : ""; }
  const char* Magenta() const { return colorize ? "\033[35m" : ""; }
  const char* Cyan() const { return colorize ? "\033[36m" : ""; }

  const bool colorize;
};  // struct Decorator

// Helper class to build messages in a nicely formatted fashion.
struct MessageBuilder final {
  explicit MessageBuilder() {}

  struct Range final {
    Range(vaddr base, vaddr top) : base(base), top(top) {}
    vaddr base;
    vaddr top;
  };

  struct Error final {
    Error(const char* msg) : msg(msg) {}
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
  MessageBuilder& operator<<(const Range range);
  MessageBuilder& operator<<(const Error error);
  MessageBuilder& operator<<(const Permission perm);
  MessageBuilder& operator<<(const Attribute attr);
  MessageBuilder& operator<<(const Hex value);

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
  bool IsTagged() const { return true; }
  vaddr Base() const { return ccl::methods::GetBase(local_cap); }
  vaddr Top() const { return ccl::methods::GetTop(local_cap); }
  u64 Perms() const { return ccl::methods::GetPerms(local_cap); }

  void PrintCapability(MessageBuilder& builder) const;

 protected:
  template <typename P>
  NOINLINE void BeginTerminate(P& property) {
    // Make sure that recursive aborts are not allowed.
    if (UNLIKELY(atomic_fetch_add(&IsTerminating, 1,
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
    atomic_fetch_sub(&IsTerminating, 1, memory_order::memory_order_relaxed);
  }

  void Initialize();
  NOINLINE void Terminate(MessageBuilder& builder, int signo,
                          abi::SignalCode code) const;

  const LocalCap& local_cap;
  vaddr pc;
  u64 tid;

  static __sanitizer::atomic_uint32_t IsTerminating;
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
    // TODO: use AT_PAGESZ
    // Ideally we would use AT_PAGESZ, but it is not available at all times.
    // 4K is a good guess, but later it would be best to really use the
    // appropriate value.
    failed |= cap_addr < 4096;
#endif
    return !failed;
  }

  void ReportError(const CheckContext& ctx, MessageBuilder& builder) const;

  static constexpr abi::SignalCode Code() {
    return abi::SignalCode::SC_SEGV_MAPERR;
  }

  static constexpr int SignalNumber() { return libc::SignalNumber::SN_SIGSEGV; }
};  // struct CapabilityAddress

// Checks that a capability is sufficiently aligned.
struct CapabilityAlignment final {
  ALWAYS_INLINE
  bool DoCheck(const CheckContext& ctx) const {
    return (ctx.CapabilityAddress() % abi::kCapabilityMinAlignment) == 0;
  }

  void ReportError(const CheckContext& ctx, MessageBuilder& builder) const;

  static constexpr abi::SignalCode Code() {
    return abi::SignalCode::SC_BUS_ADRALN;
  }

  static constexpr int SignalNumber() { return libc::SignalNumber::SN_SIGBUS; }
};  // struct CapabilityAlignment

// Reports that something is not implemented.
struct NotImplemented final {
  explicit NotImplemented(const char* msg) : msg(msg) {}
  bool DoCheck(const CheckContext& ctx) const { return false; }
  void ReportError(const CheckContext& ctx, MessageBuilder& builder) const;

  static constexpr abi::SignalCode Code() {
    return abi::SignalCode::SC_PROT_NOT_IMPLEMENTED;
  }

  static constexpr int SignalNumber() { return libc::SignalNumber::SN_NONE; }

  const char* msg;
};  // struct NotImplemented

// Checks that an access of a given size would not exceed the bounds of the
// capability
struct InBounds final {
  explicit InBounds(u64 size) : size(size) {}

  // Top (base + length) is inclusive in acceptable range of a capability
  ALWAYS_INLINE
  bool DoCheck(const CheckContext& ctx) const {
    if (!atomic_load_relaxed(&Options::EnableCHERISemantics))
      return true;
    return (ctx.Base() <= ctx.Value()) && ((ctx.Value() + size) <= ctx.Top());
  }

  void ReportError(const CheckContext& ctx, MessageBuilder& builder) const;

  static constexpr abi::SignalCode Code() {
    return abi::SignalCode::SC_SEGV_CAPBOUNDSERR;
  }

  static constexpr int SignalNumber() { return libc::SignalNumber::SN_SIGSEGV; }

  const __sanitizer::u64 size;
};  // struct InBounds

// Checks that a capability has all required permissions to perform an action
// which requires at least 'perms'.
struct RequiredPerms final {
  explicit RequiredPerms(u64 perms) : perms(perms) {}

  ALWAYS_INLINE
  bool DoCheck(const CheckContext& ctx) {
    if (!atomic_load_relaxed(&Options::EnableCHERISemantics))
      return true;
    return ((ctx.Perms() & perms) == perms);
  }

  void ReportError(const CheckContext& ctx, MessageBuilder& builder);

  static constexpr abi::SignalCode Code() {
    return abi::SignalCode::SC_SEGV_CAPPERMERR;
  }

  static constexpr int SignalNumber() { return libc::SignalNumber::SN_SIGSEGV; }

  const u64 perms;
};  // struct RequiredPerms

}  // namespace error
}  // namespace __cheriseed

#endif  // CHERISEED_ERRORS_H
