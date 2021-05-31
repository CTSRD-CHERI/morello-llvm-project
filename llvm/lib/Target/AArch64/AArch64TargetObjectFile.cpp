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

void AArch64_ELFTargetObjectFile::Initialize(MCContext &Ctx,
                                             const TargetMachine &TM) {
  TargetLoweringObjectFileELF::Initialize(Ctx, TM);
  // AARCH64 ELF ABI does not define static relocation type for TLS offset
  // within a module.  Do not generate AT_location for TLS variables.
  SupportDebugThreadLocalLocation = false;
}

TailPaddingAmount AArch64_ELFTargetObjectFile::
getTailPaddingForPreciseBounds(uint64_t Size, const TargetMachine &TM) const {
  uint64_t Pad = AArch64TargetStreamer::getTargetSizeAlignReq(Size).first - Size;
  return static_cast<TailPaddingAmount>(Pad);
}

Align AArch64_ELFTargetObjectFile::
getAlignmentForPreciseBounds(uint64_t Size, const TargetMachine &TM) const {
  unsigned LogAlign =
      AArch64TargetStreamer::getTargetSizeAlignReq(Size).second;
  if (!LogAlign)
    return Align();
  return Align(1 << LogAlign);
}

AArch64_MachoTargetObjectFile::AArch64_MachoTargetObjectFile() {
  SupportGOTPCRelWithOffset = false;
}

static bool
needsDescSection(const Constant *C, SmallSet<const Constant*, 10> &Processed) {
  if (Processed.find(C) != Processed.end())
    return false;
  Processed.insert(C);
  if (const GlobalVariable *GV = dyn_cast<GlobalVariable>(C)) {
    if (GV->isConstant()) {
      // External constants we might not have an initializer.
      if (!GV->hasInitializer())
        return true;
      return needsDescSection(GV->getInitializer(), Processed);
    }
  }
  if (const GlobalAlias *GA = dyn_cast<GlobalAlias>(C))
    return needsDescSection(GA->getAliasee(), Processed);
  if (isa<BlockAddress>(C))
    return false;
  if (isa<GlobalValue>(C))
    return true;

  // Handle pointer difference. Code lifted from Constant::getRelocationInfo().
  if (const ConstantExpr *CE = dyn_cast<ConstantExpr>(C)) {
    if (CE->getOpcode() == Instruction::Sub) {
      ConstantExpr *LHS = dyn_cast<ConstantExpr>(CE->getOperand(0));
      ConstantExpr *RHS = dyn_cast<ConstantExpr>(CE->getOperand(1));
      if (LHS && RHS && LHS->getOpcode() == Instruction::PtrToInt &&
          RHS->getOpcode() == Instruction::PtrToInt) {
        Constant *LHSOp0 = LHS->getOperand(0);
        Constant *RHSOp0 = RHS->getOperand(0);

        // While raw uses of blockaddress need to be relocated, differences
        // between two of them don't when they are for labels in the same
        // function.  This is a common idiom when creating a table for the
        // indirect goto extension, so we handle it efficiently here.
        if (isa<BlockAddress>(LHSOp0) && isa<BlockAddress>(RHSOp0) &&
            cast<BlockAddress>(LHSOp0)->getFunction() ==
                cast<BlockAddress>(RHSOp0)->getFunction())
          return false;

        // Relative pointers do not need to be dynamically relocated.
        if (auto *RHSGV =
                dyn_cast<GlobalValue>(RHSOp0->stripInBoundsConstantOffsets())) {
          auto *LHS = LHSOp0->stripInBoundsConstantOffsets();
          if (auto *LHSGV = dyn_cast<GlobalValue>(LHS)) {
            if (LHSGV->isDSOLocal() && RHSGV->isDSOLocal())
              return false;
          }
        }
      }
    }
  }

  for (unsigned i = 0, e = C->getNumOperands(); i != e; ++i)
    if (needsDescSection(cast<Constant>(C->getOperand(i)), Processed))
      return true;

  return false;
}

MCSection *AArch64_ELFTargetObjectFile::
SelectSectionForGlobal(
    const GlobalObject *GO, SectionKind SK, const TargetMachine &TM) const {
  bool IsDescABI =
      (MCTargetOptions::cheriCapabilityTableABI() ==
       CheriCapabilityTableABI::FunctionDescriptor);
  if (IsDescABI) {
    if (SK.isReadOnlyWithRel()) {
      if (const GlobalVariable *GV = dyn_cast<GlobalVariable>(GO)) {
        if (GV->isConstant()) {
          SmallSet<const Constant *, 10> Cache;
          if (needsDescSection(GV->getInitializer(), Cache))
            SK = SectionKind::getDescReadOnlyWithRel();
        } else
          SK = SectionKind::getDescReadOnlyWithRel();
      } else
        SK = SectionKind::getDescReadOnlyWithRel();
    }
  }
  return TargetLoweringObjectFileELF::SelectSectionForGlobal(GO, SK, TM);
}

MCSection *AArch64_ELFTargetObjectFile::getSectionForConstant(
    const DataLayout &DL, SectionKind Kind, const Constant *C,
    Align &Alignment) const {
  bool IsDescABI =
      (MCTargetOptions::cheriCapabilityTableABI() ==
       CheriCapabilityTableABI::FunctionDescriptor);
  if (Kind.isReadOnly() || Kind.isMergeableConst() || !IsDescABI)
    return TargetLoweringObjectFileELF::getSectionForConstant(DL, Kind, C,
                                                              Alignment);
  SmallSet<const Constant *, 10> Cache;
  if (needsDescSection(C, Cache)) {
    return getContext().getELFSection(".desc.data.rel.ro", ELF::SHT_PROGBITS,
                              ELF::SHF_ALLOC | ELF::SHF_WRITE);
  }
  return TargetLoweringObjectFileELF::getSectionForConstant(DL, Kind, C,
                                                            Alignment);
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
