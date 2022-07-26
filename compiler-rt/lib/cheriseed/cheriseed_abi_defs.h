//===- cheriseed_abi_defs.h -------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// This file defines constants required in the compiler_rt to ensure consistency
// with the Transform pass. If they are modified the changes should be mirrored
// in CHERIseed.cpp.
//===----------------------------------------------------------------------===//

#ifndef CHERISEED_ABI_DEFS_H
#define CHERISEED_ABI_DEFS_H

#include "sanitizer_common/sanitizer_internal_defs.h"

namespace __cheriseed {
namespace abi {

// Minimum expected alignment of a capability.
static constexpr __sanitizer::u8 kCapabilityMinAlignment = 16;

// The value for relaxed ordering in the IR.
static constexpr __sanitizer::u8 kIRRelaxedOrdering = 0;

// The dynamic configuration value as it appears in the 'envp' array.
static constexpr char kDynamicConfigurationEnv[] = "CHERISEED_CHECKS";

// These permissions bits are used as the arguments for the function
// __cheriseed_check_access as a platform independent representation.
enum Permissions : __sanitizer::u32 {
  LOAD = (1 << 0),
  STORE = (1 << 1),
  EXECUTE = (1 << 2),
  LOAD_CAP = (1 << 3),
  STORE_CAP = (1 << 4)
};  // enum Permissions

// Possible reasons of a capability violation.
enum SignalCode : int {
  // Attempted to dereference an untagged capability.
  SC_SEGV_CAPTAGERR = 1000,
  // Attempted an out-of-bounds access.
  SC_SEGV_CAPBOUNDSERR = 1001,
  // Attempted an access without the required permissions.
  SC_SEGV_CAPPERMERR = 1002,
  // Extension: address of a capability is likely invalid.
  SC_SEGV_MAPERR = 1,
  // Extension: alignment of a capability is invalid.
  SC_BUS_ADRALN = 1,
  // Extension: something is not implemented, this is not user-visible.
  SC_PROT_NOT_IMPLEMENTED = 9999,
};  // enum SignalCode

// Possible ways to handle a capability violation signal.
enum SignalHandleMode : int {
  // The violation is fatal and the reason is printed to stderr.
  SHM_DEFAULT = 1,
  // The violation is fatal, no details is printed to stderr.
  SHM_SILENT = 2,
  // Ignore the violation.
  SHM_IGNORE = 3,
  // The violation is not fatal, but print the reason to stderr.
  SHM_WARNING = 4,
};  // enum SignalHandleMode

// Options to control whether a check is on or off.
enum CHERIseedCheck {
  /// Turn a specific CHERIseed check OFF
  CHERISEED_CHECK_OFF,
  /// Turn a specific CHERIseed check ON
  CHERISEED_CHECK_ON,
};  // enum CHERIseedCheck

}  // namespace abi
}  // namespace __cheriseed

#endif  // CHERISEED_ABI_DEFS_H
