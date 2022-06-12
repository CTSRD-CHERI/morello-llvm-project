//===- lib/MC/MCTargetOptions.cpp - MC Target Options ---------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "llvm/MC/MCTargetOptions.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;

static cl::opt<CheriCapabilityTableABI> CapTableABI(
    "cheri-cap-table-abi", cl::desc("ABI to use for :"),
    cl::init(CheriCapabilityTableABI::Pcrel),
    cl::values(clEnumValN(CheriCapabilityTableABI::PLT, "plt",
                          "Use PLT stubs to setup $cgp correctly"),
               clEnumValN(CheriCapabilityTableABI::Pcrel, "pcrel",
                          "Derive $cgp from $pcc in every function"),
               clEnumValN(CheriCapabilityTableABI::FunctionDescriptor,
                          "fn-desc",
                          "Use function descriptors to setup $cgp correctly")));

CheriCapabilityTableABI MCTargetOptions::cheriCapabilityTableABI() {
  return CapTableABI;
}

static cl::opt<CheriLandingPadEncoding> LandingPadEncoding(
    "cheri-landing-pad-encoding", cl::desc("encoding to use for landing pads :"),
    cl::init(CheriLandingPadEncoding::Absolute),
    cl::values(clEnumValN(CheriLandingPadEncoding::Absolute, "absolute",
                          "Landing pads are encoded as capabilities"),
               clEnumValN(CheriLandingPadEncoding::Indirect, "indirect",
                          "Landing pads are encoded as an offset to a "
                          "capability (morello)")));

CheriLandingPadEncoding MCTargetOptions::cheriLandingPadEncoding() {
  return LandingPadEncoding;
}

static cl::opt<bool> MorelloUseGDForTLS(
    "morello-tls-gd-only", cl::desc("Only use general-dynamic for TLS"),
    cl::init(false));

bool MCTargetOptions::useTLSGDForPurecap() {
  return MorelloUseGDForTLS;
}

MCTargetOptions::MCTargetOptions()
    : MCRelaxAll(false), MCNoExecStack(false), MCFatalWarnings(false),
      MCNoWarn(false), MCNoDeprecatedWarn(false), MCNoTypeCheck(false),
      MCSaveTempLabels(false), MCIncrementalLinkerCompatible(false),
      ShowMCEncoding(false), ShowMCInst(false), AsmVerbose(false),
      PreserveAsmComments(true), Dwarf64(false),
      EmitDwarfUnwind(EmitDwarfUnwindType::Default),
      MCUseDwarfDirectory(DefaultDwarfDirectory) {}

StringRef MCTargetOptions::getABIName() const {
  return ABIName;
}

StringRef MCTargetOptions::getAssemblyLanguage() const {
  return AssemblyLanguage;
}
