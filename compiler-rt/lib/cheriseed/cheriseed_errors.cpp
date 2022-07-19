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
static constexpr char kErrorSeparator[] = REP64("=") "\n";

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

MessageBuilder& MessageBuilder::operator<<(const MessageBuilder::Range range) {
  return *this << range.base << "-" << range.top;
}

MessageBuilder& MessageBuilder::operator<<(const MessageBuilder::Hex value) {
  message.append("%s0x%x%s", D.Green(), value, D.Reset());
  return *this;
}

MessageBuilder& MessageBuilder::operator<<(const Error error) {
  message.append("%s%s%s", D.Red(), error.msg, D.Reset());
  return *this;
}

MessageBuilder& MessageBuilder::operator<<(
    const MessageBuilder::Permission perm) {
  if (perm.explain) {
    message.append("  %s%s%s [%s%s%s]\n", D.Magenta(), perm.ShortName(),
                   D.Reset(), D.Magenta(), perm.LongName(), D.Reset());
  } else {
    message.append("%s%s%s", D.Magenta(), perm.ShortName(), D.Reset());
  }
  return *this;
}

MessageBuilder& MessageBuilder::operator<<(
    const MessageBuilder::Attribute attr) {
  message.append("%s%s%s", D.Cyan(), attr.msg, D.Reset());
  return *this;
}

void MessageBuilder::WriteToStderr() {
  RawWrite(message.data());
  message.clear();
}

// Prevents recursive terminations.
__sanitizer::atomic_uint32_t CheckContext::IsTerminating{0};

// Based on
// https://github.com/CTSRD-CHERI/cheri-c-programming/wiki/Displaying-Capabilities
void CheckContext::PrintCapability(MessageBuilder& builder) const {
  if (!IsTagged() && (Value() == 0) && (Metadata() == 0)) {
    builder << "  " << MessageBuilder::Hex(0) << " (null capability)\n\n";
    return;
  }

  builder << "  " << Value() << " [";
  bool has_perms = PermsToString(builder, Perms(), /* explain */ false);
  builder << (has_perms ? "," : "") << MessageBuilder::Range(Base(), Top())
          << "]";

  if (!IsTagged())
    builder << MessageBuilder::Attribute(" (invalid)");

  builder << "\n\n";
}

void CheckContext::Initialize() {
  SetCommonFlagsDefaults();
  tid = GetTid();
}

static SignalHandleMode TryCallSignalHandler(int signo, SignalCode code,
                                             vaddr pc) {
  if (signo == SignalNumber::SN_NONE)
    return SignalHandleMode::SHM_DEFAULT;

  SigAction action;
  if (!SigAction::GetAction(signo, action))
    return SignalHandleMode::SHM_DEFAULT;

  SigInfo info{signo, code, pc};
  return action.Invoke(info);
}

void CheckContext::Terminate(MessageBuilder& reason, int signo,
                             SignalCode code) const {
  bool print_cause = true;
  bool ignore_signal = false;
  // Try to invoke a signal handler directly, if set.
  if (GetOpts().shouldInvokeSignalHandlers()) {
    switch (TryCallSignalHandler(signo, code, pc)) {
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
  // Prepare the error message, if requested by the SignalHandleMode.
  if (print_cause) {
    MessageBuilder builder;
    builder << "\n"
            << kErrorSeparator
            << MessageBuilder::Error("Runtime Error detected by CHERIseed")
            << "\n\n"
            << reason << "\n"
            << "tid: " << tid << "\npc:  " << pc << "\n"
            << (ignore_signal
                    ? MessageBuilder::Attribute("\nViolation is ignored\n")
                    : "")
            << kErrorSeparator;
    builder.WriteToStderr();
  }
  // Ignore the violation and continue execution.
  if (ignore_signal)
    return;
  // Try to raise SIGTRAP if being debugged.
  const pid_t tracer_pid = GetTracerPid();
  if (tracer_pid != 0) {
    if (print_cause) {
      MessageBuilder builder;
      builder << "\n"
              << MessageBuilder::Attribute("[CHERIseed] ")
              << "Tracer detected with pid = " << static_cast<u64>(tracer_pid)
              << ", sending SIGTRAP.\n";
      builder.WriteToStderr();
    }
    RaiseSigTrap();
  }
  // Terminate the program.
  __sanitizer::Die();
}

void CapabilityAddress::ReportError(const CheckContext& ctx,
                                    MessageBuilder& builder) const {
  builder << "Capability address is likely invalid at "
          << ctx.CapabilityAddress() << "\n";
}

void CapabilityAlignment::ReportError(const CheckContext& ctx,
                                      MessageBuilder& builder) const {
  builder << "Capability is unaligned at " << ctx.CapabilityAddress() << "\n";
}

void NotImplemented::ReportError(const CheckContext& ctx,
                                 MessageBuilder& builder) const {
  builder << "'" << msg << "' is not implemented\n";
}

void InBounds::ReportError(const CheckContext& ctx,
                           MessageBuilder& builder) const {
  builder << "Prevented out-of-bounds access with capability at "
          << ctx.CapabilityAddress() << ":\n\n";
  ctx.PrintCapability(builder);
  builder << "Requested range was "
          << MessageBuilder::Range(ctx.Value(), ctx.Value() + size) << "\n";
}

void RequiredPerms::ReportError(const CheckContext& ctx,
                                MessageBuilder& builder) {
  builder << "Capability is missing required permission(s) at "
          << ctx.CapabilityAddress() << ":\n\n";
  ctx.PrintCapability(builder);
  builder << "Missing permission(s):\n";
  PermsToString(builder, (perms & ~ctx.Perms()), /* explain */ true);
}

void Tagged::ReportError(const CheckContext& ctx, MessageBuilder& builder) {
  builder << "Capability is untagged at " << ctx.CapabilityAddress() << ":\n\n";
  ctx.PrintCapability(builder);
}

}  // namespace error
}  // namespace __cheriseed
