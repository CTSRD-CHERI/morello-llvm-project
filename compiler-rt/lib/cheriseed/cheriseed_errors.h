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

#include "cheriseed_libc.h"
#include "sanitizer_common/sanitizer_common.h"

namespace __cheriseed {
namespace error {

/// Decorator to create brightly colored reports.
struct Decorator final {
  Decorator() : colorize(__sanitizer::ColorizeReports()) {}

  const char* Reset() const { return colorize ? "\033[0m" : ""; }
  const char* Red() const { return colorize ? "\033[31m" : ""; }
  const char* Green() const { return colorize ? "\033[32m" : ""; }
  const char* Yellow() const { return colorize ? "\033[33m" : ""; }
  const char* Magenta() const { return colorize ? "\033[35m" : ""; }
  const char* Cyan() const { return colorize ? "\033[36m" : ""; }

 private:
  const bool colorize;
};  // struct Decorator

/// Helper class to build messages in a nicely formatted fashion.
struct MessageBuilder final : public DisableCopyAndMoveMixin {
  struct Error final {
    explicit Error(const char* msg) : msg(msg) {}
    const char* msg;
  };  // struct Error

  struct Info final {
    explicit Info(const char* msg) : msg(msg) {}
    const char* msg;
  };  // struct Info

  struct Permission final {
    explicit Permission(u64 perm, bool explain)
        : perm(perm), explain(explain) {}
    const char* ShortName() const;
    const char* LongName() const;
    const u64 perm;
    const bool explain;
  };  // struct Permission

  struct Attribute final {
    explicit Attribute(const char* msg) : msg(msg) {}
    const char* msg;
  };  // struct Attribute

  struct Hex final {
    explicit Hex(u64 value) : value(value) {}
    u64 value;
  };  // struct Hex

  MessageBuilder& operator<<(const MessageBuilder& other);
  MessageBuilder& operator<<(const char* str);
  MessageBuilder& operator<<(const vaddr addr);
  MessageBuilder& operator<<(const u64 value);
  MessageBuilder& operator<<(const MemoryRange& range);
  MessageBuilder& operator<<(const Hex value);
  MessageBuilder& operator<<(const Error error);
  MessageBuilder& operator<<(const Info info);
  MessageBuilder& operator<<(const Permission perm);
  MessageBuilder& operator<<(const Attribute attr);
  MessageBuilder& operator<<(const ShadowMemory& shadow_memory);

  void WriteToStderr();

 private:
  Decorator D;
  __sanitizer::InternalScopedString message;
};  // struct MessageBuilder

// It is not possible to have virtual destructors because those require
// 'operator delete(void*)', which this library should not define.
// In pratice, virtual destructors are only necessary if deletion is made
// through a base class, and there are resources which should be properly
// released. This is not the case in this library.

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnon-virtual-dtor"

// This is the base class for all formatted messages.
// Cannot use abstract base class because that would require
// '__cxa_pure_virtual'.
struct IMessageBuilder {
  virtual void Compose(MessageBuilder& message) const final;

  virtual void Separator(MessageBuilder& message) const;
  virtual void Header(MessageBuilder& message) const {}
  virtual void Message(MessageBuilder& message) const { __sanitizer::Trap(); }
  virtual void Footer(MessageBuilder& message) const {}

 protected:
  constexpr IMessageBuilder() {}
};  // struct IMessageBuilder

struct ErrorMessageBuilder : public IMessageBuilder {
 protected:
  constexpr ErrorMessageBuilder() {}

 private:
  void Separator(MessageBuilder& message) const override;
  void Header(MessageBuilder& message) const override final;
  void Footer(MessageBuilder& message) const override;
};  // struct ErrorMessageBuilder

struct InfoMessageBuilder : public IMessageBuilder {
 protected:
  constexpr InfoMessageBuilder() {}

 private:
  void Separator(MessageBuilder& message) const override;
  void Header(MessageBuilder& message) const override final;
  void Footer(MessageBuilder& message) const override;
};  // struct InfoMessageBuilder

#pragma clang diagnostic pop

/// Reports that something is not implemented.
struct NotImplementedMessageBuilder final : public ErrorMessageBuilder {
  explicit constexpr NotImplementedMessageBuilder(const char* msg) : msg(msg) {}

 private:
  void Message(MessageBuilder& message) const override;

  const char* msg;
};  // struct NotImplementedMessageBuilder

/// Reports that an error is ignored.
struct IgnoredMessageBuilder final : public IMessageBuilder {
 private:
  void Separator(MessageBuilder& message) const override;
  void Header(MessageBuilder& message) const override;
  void Message(MessageBuilder& message) const override;
  void Footer(MessageBuilder& message) const override;
};  // struct IgnoredMessageBuilder

/// Reports a malformed CHERISEED_CHECKS environment variable.
struct DynamicControlMessageBuilder final : public ErrorMessageBuilder {
  explicit constexpr DynamicControlMessageBuilder(const char* const start,
                                                  const char* const cursor)
      : start(start), cursor(cursor) {}

 private:
  void Message(MessageBuilder& message) const override;
  void Footer(MessageBuilder& message) const override;

  const char* start;
  const char* cursor;
};  // struct DynamicControlMessageBuilder

/// Prints help for CHERISEED_CHECKS environment variable as info message.
struct DynamicControlHelpMessageBuilder final : public InfoMessageBuilder {
 private:
  void Message(MessageBuilder& message) const override;
};  // struct DynamicControlHelpMessageBuilder

/// Helper template for capability violations.
template <typename T, const libc::SignalNumber SIGNO,
          const abi::SignalCode CODE>
struct CapabilityViolation {
  T& GetBuilder() { return builder; }
  bool ShouldInvokeSignalHandler() const { return invoke_signal_handler; }

  static constexpr libc::SignalNumber Signo{SIGNO};
  static constexpr abi::SignalCode Code{CODE};

 protected:
  template <typename... ParamTy>
  CapabilityViolation(const LocalCap& local_cap, ParamTy&&... params)
      : builder(local_cap, params...),
        invoke_signal_handler(
            local_cap.GetOpts().shouldInvokeSignalHandlers()) {}

 private:
  T builder;
  const bool invoke_signal_handler;
};  // struct CapabilityViolation

/// Reports that a pointer to a capability is likely invalid.
struct AddressErrorMessageBuilder final : public ErrorMessageBuilder {
  explicit constexpr AddressErrorMessageBuilder(const LocalCap& local_cap)
      : local_cap(local_cap) {}

 private:
  void Message(MessageBuilder& message) const override;

  const LocalCap& local_cap;
};  // struct AddressErrorMessageBuilder

struct AddressError final
    : public CapabilityViolation<AddressErrorMessageBuilder,
                                 libc::SignalNumber::SN_SIGSEGV,
                                 abi::SignalCode::SC_SEGV_MAPERR> {
  explicit AddressError(const LocalCap& local_cap)
      : CapabilityViolation(local_cap) {}
};  // struct AddressError

/// Reports that a pointer to a capability is unaligned.
struct AlignmentErrorMessageBuilder final : public ErrorMessageBuilder {
  explicit AlignmentErrorMessageBuilder(const LocalCap& local_cap)
      : local_cap(local_cap) {}

 private:
  void Message(MessageBuilder& message) const override;

  const LocalCap& local_cap;
};  // struct AlignmentErrorMessageBuilder

struct AlignmentError final
    : public CapabilityViolation<AlignmentErrorMessageBuilder,
                                 libc::SignalNumber::SN_SIGBUS,
                                 abi::SignalCode::SC_BUS_ADRALN> {
  explicit AlignmentError(const LocalCap& local_cap)
      : CapabilityViolation(local_cap) {}
};  // struct AlignmentError

/// Reports that a capability is untagged.
struct NotTaggedErrorMessageBuilder final : public ErrorMessageBuilder {
  explicit NotTaggedErrorMessageBuilder(const LocalCap& local_cap)
      : local_cap(local_cap) {}

 private:
  void Message(MessageBuilder& message) const override;

  const LocalCap& local_cap;
};  // struct NotTaggedErrorMessageBuilder

struct NotTaggedError final
    : public CapabilityViolation<NotTaggedErrorMessageBuilder,
                                 libc::SignalNumber::SN_SIGSEGV,
                                 abi::SignalCode::SC_SEGV_CAPTAGERR> {
  explicit NotTaggedError(const LocalCap& local_cap)
      : CapabilityViolation(local_cap) {}
};  // struct NotTaggedError

/// Reports that a capability is missing permissions for the required operation.
struct PermissionErrorMessageBuilder final : public ErrorMessageBuilder {
  explicit PermissionErrorMessageBuilder(const LocalCap& local_cap,
                                         u64 requested_permissions)
      : local_cap(local_cap), requested_permissions(requested_permissions) {}

 private:
  void Message(MessageBuilder& message) const override;

  const LocalCap& local_cap;
  const u64 requested_permissions;
};  // struct PermissionErrorMessageBuilder

struct PermissionError final
    : public CapabilityViolation<PermissionErrorMessageBuilder,
                                 libc::SignalNumber::SN_SIGSEGV,
                                 abi::SignalCode::SC_SEGV_CAPPERMERR> {
  explicit PermissionError(const LocalCap& local_cap, u64 requested_permissions)
      : CapabilityViolation(local_cap, requested_permissions) {}
};  // struct PermissionError

/// Reports that an access exceeds the bounds of a capability.
struct OutOfBoundsAccessErrorMessageBuilder final : public ErrorMessageBuilder {
  explicit OutOfBoundsAccessErrorMessageBuilder(const LocalCap& local_cap,
                                                u64 requested_size)
      : local_cap(local_cap), requested_size(requested_size) {}

 private:
  void Message(MessageBuilder& message) const override;

  const LocalCap& local_cap;
  const u64 requested_size;
};  // struct OutOfBoundsAccessErrorMessageBuilder

struct OutOfBoundsAccessError final
    : public CapabilityViolation<OutOfBoundsAccessErrorMessageBuilder,
                                 libc::SignalNumber::SN_SIGSEGV,
                                 abi::SignalCode::SC_SEGV_CAPBOUNDSERR> {
  explicit OutOfBoundsAccessError(const LocalCap& local_cap, u64 requested_size)
      : CapabilityViolation(local_cap, requested_size) {}
};  // struct OutOfBoundsAccessError

NOINLINE void Raise(IMessageBuilder& builder);
NOINLINE void RaiseSignal(IMessageBuilder& builder, bool invoke_signal_handler,
                          libc::SignalNumber signo, abi::SignalCode code);

template <typename T, typename... ParamTy>
NOINLINE void Raise(ParamTy&&... params) {
  T error(params...);
  Raise(error);
}

template <typename T, typename... ParamTy>
NOINLINE void RaiseSignal(ParamTy&&... params) {
  T error(params...);
  RaiseSignal(error.GetBuilder(), error.ShouldInvokeSignalHandler(), T::Signo,
              T::Code);
}

}  // namespace error
}  // namespace __cheriseed

#endif  // CHERISEED_ERRORS_H
