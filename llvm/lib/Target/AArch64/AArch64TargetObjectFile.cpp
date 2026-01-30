//===-- AArch64TargetObjectFile.cpp - AArch64 Object Info -----------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "AArch64TargetObjectFile.h"
#include "AArch64TargetMachine.h"
#include "MCTargetDesc/AArch64TargetStreamer.h"
#include "llvm/BinaryFormat/Dwarf.h"
#include "llvm/BinaryFormat/ELF.h"
#include "llvm/IR/Mangler.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCValue.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/MC/MCSectionELF.h"
#include "llvm/ADT/SmallSet.h"

using namespace llvm;
using namespace dwarf;

cl::opt<bool> CheriEmitCodePtrRelocs(
    "cheri-codeptr-relocs",
    cl::desc("Emit different relocations for code pointers compared to function"
             "pointers"),
    cl::init(false));

void AArch64_ELFTargetObjectFile::Initialize(MCContext &Ctx,
                                             const TargetMachine &TM) {
  TargetLoweringObjectFileELF::Initialize(Ctx, TM);
  // AARCH64 ELF ABI does not define static relocation type for TLS offset
  // within a module.  Do not generate AT_location for TLS variables.
  SupportDebugThreadLocalLocation = false;
}

TailPaddingAmount AArch64_ELFTargetObjectFile::
getTailPaddingForPreciseBounds(uint64_t Size, const TargetMachine &TM) const {
  // XXX: Other CHERI architectures only pad for purecap, not hybrid
  const auto &ATM = static_cast<const AArch64TargetMachine &>(TM);
  if (!ATM.IsMorello())
    return TailPaddingAmount::None;

  uint64_t Pad = AArch64TargetStreamer::getTargetSizeAlignReq(Size).first - Size;
  return static_cast<TailPaddingAmount>(Pad);
}

Align AArch64_ELFTargetObjectFile::
getAlignmentForPreciseBounds(uint64_t Size, const TargetMachine &TM) const {
  // XXX: Other CHERI architectures only align for purecap, not hybrid
  const auto &ATM = static_cast<const AArch64TargetMachine &>(TM);
  if (!ATM.IsMorello())
    return Align();

  unsigned LogAlign =
      AArch64TargetStreamer::getTargetSizeAlignReq(Size).second;
  if (!LogAlign)
    return Align();
  return Align(1 << LogAlign);
}

const MCExpr *AArch64_ELFTargetObjectFile::lowerCheriCodeReference(
    const MCSymbol *Sym, const MCExpr *Addend) const {
  MCSymbolRefExpr::VariantKind VK = CheriEmitCodePtrRelocs
                                        ? MCSymbolRefExpr::VK_CHERI_CODE
                                        : MCSymbolRefExpr::VK_None;
  const MCExpr *Expr = MCSymbolRefExpr::create(Sym, VK, getContext());
  if (Addend != nullptr)
    Expr = MCBinaryExpr::createAdd(Expr, Addend, getContext());
  return Expr;
}

AArch64_MachoTargetObjectFile::AArch64_MachoTargetObjectFile() {
  SupportGOTPCRelWithOffset = false;
}

const MCExpr *AArch64_MachoTargetObjectFile::getTTypeGlobalReference(
    const GlobalValue *GV, unsigned Encoding, const TargetMachine &TM,
    MachineModuleInfo *MMI, MCStreamer &Streamer) const {
  // On Darwin, we can reference dwarf symbols with foo@GOT-., which
  // is an indirect pc-relative reference. The default implementation
  // won't reference using the GOT, so we need this target-specific
  // version.
  if (Encoding & (DW_EH_PE_indirect | DW_EH_PE_pcrel)) {
    const MCSymbol *Sym = TM.getSymbol(GV);
    const MCExpr *Res =
        MCSymbolRefExpr::create(Sym, MCSymbolRefExpr::VK_GOT, getContext());
    MCSymbol *PCSym = getContext().createTempSymbol();
    Streamer.emitLabel(PCSym);
    const MCExpr *PC = MCSymbolRefExpr::create(PCSym, getContext());
    return MCBinaryExpr::createSub(Res, PC, getContext());
  }

  return TargetLoweringObjectFileMachO::getTTypeGlobalReference(
      GV, Encoding, TM, MMI, Streamer);
}

MCSymbol *AArch64_MachoTargetObjectFile::getCFIPersonalitySymbol(
    const GlobalValue *GV, const TargetMachine &TM,
    MachineModuleInfo *MMI) const {
  return TM.getSymbol(GV);
}

const MCExpr *AArch64_MachoTargetObjectFile::getIndirectSymViaGOTPCRel(
    const GlobalValue *GV, const MCSymbol *Sym, const MCValue &MV,
    int64_t Offset, MachineModuleInfo *MMI, MCStreamer &Streamer) const {
  assert((Offset+MV.getConstant() == 0) &&
         "Arch64 does not support GOT PC rel with extra offset");
  // On ARM64 Darwin, we can reference symbols with foo@GOT-., which
  // is an indirect pc-relative reference.
  const MCExpr *Res =
      MCSymbolRefExpr::create(Sym, MCSymbolRefExpr::VK_GOT, getContext());
  MCSymbol *PCSym = getContext().createTempSymbol();
  Streamer.emitLabel(PCSym);
  const MCExpr *PC = MCSymbolRefExpr::create(PCSym, getContext());
  return MCBinaryExpr::createSub(Res, PC, getContext());
}

void AArch64_MachoTargetObjectFile::getNameWithPrefix(
    SmallVectorImpl<char> &OutName, const GlobalValue *GV,
    const TargetMachine &TM) const {
  // AArch64 does not use section-relative relocations so any global symbol must
  // be accessed via at least a linker-private symbol.
  getMangler().getNameWithPrefix(OutName, GV, /* CannotUsePrivateLabel */ true);
}
