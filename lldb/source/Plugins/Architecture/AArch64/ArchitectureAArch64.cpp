//===-- ArchitectureAArch64.cpp -------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "Plugins/Architecture/AArch64/ArchitectureAArch64.h"
#include "lldb/Core/PluginManager.h"
#include "lldb/Utility/ArchSpec.h"

using namespace lldb_private;
using namespace lldb;

LLDB_PLUGIN_DEFINE(ArchitectureAArch64)

void ArchitectureAArch64::Initialize() {
  PluginManager::RegisterPlugin(GetPluginNameStatic(),
                                "AArch64-specific algorithms",
                                &ArchitectureAArch64::Create);
}

void ArchitectureAArch64::Terminate() {
  PluginManager::UnregisterPlugin(&ArchitectureAArch64::Create);
}

std::unique_ptr<Architecture>
ArchitectureAArch64::Create(const ArchSpec &arch) {
  auto machine = arch.GetMachine();
  if (machine != llvm::Triple::aarch64 && machine != llvm::Triple::aarch64_be &&
      machine != llvm::Triple::aarch64_32) {
    return nullptr;
  }
  return std::unique_ptr<Architecture>(new ArchitectureAArch64());
}

addr_t
ArchitectureAArch64::GetCallableLoadAddress(addr_t code_addr,
                                          AddressClass addr_class) const {
  switch (addr_class) {
  case AddressClass::eData:
  case AddressClass::eDebug:
    return LLDB_INVALID_ADDRESS;
  case AddressClass::eCodeAlternateISA:
    // When we're in C64 mode, we need to set the discriminating bit.
    return code_addr | addr_t(0x1);
  default:
    break;
  }

  return code_addr;
}

addr_t ArchitectureAArch64::GetOpcodeLoadAddress(addr_t opcode_addr,
                                               AddressClass addr_class) const {
  switch (addr_class) {
  case AddressClass::eData:
  case AddressClass::eDebug:
    return LLDB_INVALID_ADDRESS;
  default:
    break;
  }

  // Make sure we clear the discriminating bit for C64 addresses. This has no
  // effect for A64 addresses. Ideally we should only be doing it for
  // AddressClass::eCodeAlternateISA, but we're not very consistent about
  // passing the correct value of addr_class.
  return opcode_addr & ~addr_t(0x1);
}
