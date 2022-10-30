//===-- cheriseed_errors.cpp ------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// This file implements the errors the sanitizer might produce run-time.
//
//===----------------------------------------------------------------------===//

#include "cheriseed_errors.h"

#include "cheriseed_ccl_interface.h"

using namespace __cheriseed::abi;
using namespace __cheriseed::libc;
using namespace __sanitizer;

namespace __cheriseed {
namespace error {

// Build a separator to distinguish error messages on the console.
#define REP4(_c) _c _c _c _c
#define REP8(_c) REP4(_c) REP4(_c)
#define REP16(_c) REP8(_c) REP8(_c)
#define REP32(_c) REP16(_c) REP16(_c)
#define REP64(_c) REP32(_c) REP32(_c)
static constexpr char kErrorSeparator[] = REP64("=");

static bool PermsToString(MessageBuilder& builder, u64 mask, bool explain) {
  bool has_perms = false;
#define APPEND_NAME_IF(__name)                                        \
  {                                                                   \
    if (mask & ccl::permissions::__name) {                            \
      builder << MessageBuilder::Permission(ccl::permissions::__name, \
                                            explain);                 \
      has_perms = true;                                               \
    }                                                                 \
  }

  FOREACH_CCL_PERMISSION(APPEND_NAME_IF)
#undef APPEND_NAME_IF
  return has_perms;
}

static SignalHandleMode TryCallSignalHandler(libc::SignalNumber signo,
                                             SignalCode code, vaddr pc) {
  SigAction action;
  if (!SigAction::GetAction(signo, action))
    return SignalHandleMode::SHM_DEFAULT;

  SigInfo info{signo, code, pc};
  return action.Invoke(info);
}

// Based on
// https://github.com/CTSRD-CHERI/cheri-c-programming/wiki/Displaying-Capabilities
static void PrintCapability(const LocalCap& local_cap,
                            MessageBuilder& message) {
  if (!local_cap.IsTagged() && (local_cap.GetValue() == 0) &&
      (local_cap.GetMetadata() == 0)) {
    message << "  " << MessageBuilder::Hex(0) << " (null capability)\n\n";
    return;
  }

  message << "  " << MessageBuilder::Hex(local_cap.GetValue()) << " [";
  bool has_perms =
      PermsToString(message, local_cap.GetPermissions(), /* explain */ false);
  message << (has_perms ? "," : "")
          << MemoryRange(local_cap.GetBase(), local_cap.GetTop()) << "]";

  if (!local_cap.IsTagged())
    message << MessageBuilder::Attribute(" (invalid)");

  message << "\n\n";
}

static void PrintTagAddress(const LocalCap& local_cap,
                            MessageBuilder& message) {
  message << "Tag address was at "
          << reinterpret_cast<vaddr>(local_cap.GetShadowAddress()) << "\n\n"
          << __cheriseed::Globals::ShadowMap;
}

static void PrettyPrintHelp(MessageBuilder& message) {
  message << "Usage: CHERISEED_CHECKS=[[-]options,...]"
          << "\n";
  llvm::__cheriseed::parser::Help(message, /* flags_to_exclude */ 0);
}

/// Helper class to make sure errors do not recurse infinitely.
struct ScopedRaiseAttempt final {
  ScopedRaiseAttempt() {
    if (UNLIKELY(atomic_fetch_add(&Globals::IsTerminating, 1,
                                  memory_order::memory_order_relaxed) > 0))
      __sanitizer::Trap();
  }

  ~ScopedRaiseAttempt() {
    atomic_fetch_sub(&Globals::IsTerminating, 1,
                     memory_order::memory_order_relaxed);
  }
};  // struct ScopedRaiseAttempt

const char* MessageBuilder::Permission::LongName() const {
  switch (perm) {
    default:
      return "";
    case ccl::permissions::LOAD:
      return "LOAD";
    case ccl::permissions::LOAD_CAP:
      return "LOAD_CAP";
    case ccl::permissions::STORE:
      return "STORE";
    case ccl::permissions::STORE_CAP:
      return "STORE_CAP";
    case ccl::permissions::EXECUTE:
      return "EXECUTE";
  }
}

const char* MessageBuilder::Permission::ShortName() const {
  switch (perm) {
    default:
      return "";
    case ccl::permissions::LOAD:
      return "r";
    case ccl::permissions::LOAD_CAP:
      return "R";
    case ccl::permissions::STORE:
      return "w";
    case ccl::permissions::STORE_CAP:
      return "W";
    case ccl::permissions::EXECUTE:
      return "x";
  }
}

MessageBuilder& MessageBuilder::operator<<(const MessageBuilder& other) {
  message.append("%s", other.message.data());
  return *this;
}

MessageBuilder& MessageBuilder::operator<<(const char* str) {
  message.append("%s", str);
  return *this;
}

MessageBuilder& MessageBuilder::operator<<(const vaddr addr) {
  message.append("%s%p%s", D.Green(), addr, D.Reset());
  return *this;
}

MessageBuilder& MessageBuilder::operator<<(const u64 value) {
  message.append("%s%llu%s", D.Green(), value, D.Reset());
  return *this;
}

MessageBuilder& MessageBuilder::operator<<(const MemoryRange& range) {
  return *this << range.GetBase() << "-" << range.GetEnd();
}

MessageBuilder& MessageBuilder::operator<<(const Hex value) {
  message.append("%s0x%llx%s", D.Green(), value, D.Reset());
  return *this;
}

MessageBuilder& MessageBuilder::operator<<(const Error error) {
  message.append("%s%s%s", D.Red(), error.msg, D.Reset());
  return *this;
}

MessageBuilder& MessageBuilder::operator<<(const Info info) {
  message.append("%s%s%s", D.Yellow(), info.msg, D.Reset());
  return *this;
}

MessageBuilder& MessageBuilder::operator<<(const Permission perm) {
  if (perm.explain) {
    message.append("  %s%s%s [%s%s%s]\n", D.Magenta(), perm.ShortName(),
                   D.Reset(), D.Magenta(), perm.LongName(), D.Reset());
  } else {
    message.append("%s%s%s", D.Magenta(), perm.ShortName(), D.Reset());
  }
  return *this;
}

MessageBuilder& MessageBuilder::operator<<(const Attribute attr) {
  message.append("%s%s%s", D.Cyan(), attr.msg, D.Reset());
  return *this;
}

MessageBuilder& MessageBuilder::operator<<(const ShadowMemory& shadow_memory) {
  *this << "Shadow memory layout:\n"
        << "  low   "
        << "[" << shadow_memory.GetShadowMemoryRangeLow() << "]\n"
        << "  gap   "
        << "[" << shadow_memory.GetShadowGapRange() << "]\n"
        << "  high  "
        << "[" << shadow_memory.GetShadowMemoryRangeHigh() << "]\n";
  return *this;
}

void MessageBuilder::WriteToStderr() {
  RawWrite(message.data());
  message.clear();
}

void IMessageBuilder::Compose(MessageBuilder& message) const {
  message << "\n";
  Separator(message);
  Header(message);
  Message(message);
  Footer(message);
  Separator(message);
}

void IMessageBuilder::Separator(MessageBuilder& message) const {
  message << kErrorSeparator << "\n";
}

void ErrorMessageBuilder::Separator(MessageBuilder& message) const {
  IMessageBuilder::Separator(message);
}

void ErrorMessageBuilder::Header(MessageBuilder& message) const {
  message << MessageBuilder::Error("Runtime Error detected by CHERIseed")
          << "\n\n";
}

void ErrorMessageBuilder::Footer(MessageBuilder& message) const {
  message << "\ntid: " << GetTid() << "\n";
}

void InfoMessageBuilder::Separator(MessageBuilder& message) const {
  IMessageBuilder::Separator(message);
}

void InfoMessageBuilder::Header(MessageBuilder& message) const {
  message << MessageBuilder::Attribute("CHERIseed Info") << "\n\n";
}

void InfoMessageBuilder::Footer(MessageBuilder& message) const {}

void NotImplementedMessageBuilder::Message(MessageBuilder& message) const {
  message << "'" << msg << "' is not implemented\n";
}

void IgnoredMessageBuilder::Separator(MessageBuilder& message) const {}

void IgnoredMessageBuilder::Header(MessageBuilder& message) const {
  message << MessageBuilder::Attribute("[CHERIseed] ");
}

void IgnoredMessageBuilder::Message(MessageBuilder& message) const {
  message << "The above error is ignored, continuing execution.\n";
}

void IgnoredMessageBuilder::Footer(MessageBuilder& message) const {}

void DynamicControlMessageBuilder::Message(MessageBuilder& message) const {
  u64 pos = static_cast<u64>(cursor - start);
  message << "CHERISEED_CHECKS has an invalid option at position "
          << static_cast<u64>(pos - sizeof(kDynamicConfigurationEnv))
          << ":\n\n  " << start << "\n  ";
  while (pos > 0) {
    message << " ";
    --pos;
  }
  message << MessageBuilder::Attribute("^") << "\n\n";
  PrettyPrintHelp(message);
}

void DynamicControlMessageBuilder::Footer(MessageBuilder& message) const {}

void DynamicControlHelpMessageBuilder::Message(MessageBuilder& message) const {
  PrettyPrintHelp(message);
}

void AddressErrorMessageBuilder::Message(MessageBuilder& message) const {
  message << "Capability address is likely invalid at "
          << local_cap.GetAddress() << "\n";
}

void AlignmentErrorMessageBuilder::Message(MessageBuilder& message) const {
  message << "Capability is unaligned at " << local_cap.GetAddress() << "\n";
}

void NotTaggedErrorMessageBuilder::Message(MessageBuilder& message) const {
  message << "Capability is untagged at " << local_cap.GetAddress() << ":\n\n";
  PrintCapability(local_cap, message);
  PrintTagAddress(local_cap, message);
}

void PermissionErrorMessageBuilder::Message(MessageBuilder& message) const {
  message << "Capability is missing required permission(s) at "
          << local_cap.GetAddress() << ":\n\n";
  PrintCapability(local_cap, message);
  message << "Missing permission(s):\n";
  PermsToString(message, (requested_permissions & ~local_cap.GetPermissions()),
                /* explain */ true);
  message << "\n";
  PrintTagAddress(local_cap, message);
}

void OutOfBoundsAccessErrorMessageBuilder::Message(
    MessageBuilder& message) const {
  message << "Prevented out-of-bounds access with capability at "
          << local_cap.GetAddress() << ":\n\n";
  PrintCapability(local_cap, message);
  message << "Requested range was "
          << MemoryRange(local_cap.GetValue(),
                         local_cap.GetValue() + requested_size)
          << "\n\n";
  PrintTagAddress(local_cap, message);
}

void Raise(IMessageBuilder& builder) {
  // Make sure that recursive aborts are not allowed.
  ScopedRaiseAttempt sra;
  // Initialize sanitizer flags.
  SetCommonFlagsDefaults();
  // Compose the message by building it from bits and pieces, and  then
  // write it to standard error.
  MessageBuilder message;
  builder.Compose(message);
  message.WriteToStderr();
  // Last resort, exit with '1'.
  __sanitizer::internal__exit(1);
}

void RaiseSignal(IMessageBuilder& builder, bool invoke_signal_handler,
                 libc::SignalNumber signo, abi::SignalCode code) {
  // Make sure that recursive aborts are not allowed.
  ScopedRaiseAttempt sra;
  // Initialize sanitizer flags.
  SetCommonFlagsDefaults();

  // Try to invoke a signal handler.
  bool print_cause = true;
  bool ignore_signal = false;
  // Try to invoke a signal handler directly, if set.
  if (invoke_signal_handler) {
    switch (TryCallSignalHandler(signo, code, 0)) {
      default:
        break;
      case SignalHandleMode::SHM_SILENT:
        print_cause = false;
        ignore_signal = false;
        break;
      case SignalHandleMode::SHM_IGNORE:
        print_cause = false;
        ignore_signal = true;
        break;
      case SignalHandleMode::SHM_WARNING:
        print_cause = true;
        ignore_signal = true;
        break;
    }
  }

  if (print_cause) {
    // Compose the message by building it from bits and pieces, and  then
    // write it to standard error.
    MessageBuilder message;
    builder.Compose(message);
    if (ignore_signal)
      IgnoredMessageBuilder().Compose(message);
    message.WriteToStderr();
  }

  // Ignore the violation and continue execution.
  if (ignore_signal)
    return;

  // Try to terminate the program by raising the appropriate signal.
  SigAction::SetDefaultAction(signo);
  libc::Raise(GetPid(), signo);
  // Last resort, exit with '1'.
  __sanitizer::internal__exit(1);
}

}  // namespace error
}  // namespace __cheriseed
