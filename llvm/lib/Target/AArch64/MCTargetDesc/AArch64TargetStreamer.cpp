//===- AArch64TargetStreamer.cpp - AArch64TargetStreamer class ------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements the AArch64TargetStreamer class.
//
//===----------------------------------------------------------------------===//

#include "AArch64MCExpr.h"
#include "AArch64TargetStreamer.h"
#include "llvm/MC/ConstantPools.h"
#include "llvm/MC/MCSection.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/MCContext.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Cheri.h"
#include "llvm/Support/Morello.h"
#include "llvm/MC/MCSectionELF.h"
#include "llvm/BinaryFormat/ELF.h"
#include <cassert>

using namespace llvm;

//
// AArch64TargetStreamer Implemenation
//
AArch64TargetStreamer::AArch64TargetStreamer(MCStreamer &S)
    : MCTargetStreamer(S), ConstantPools(new AssemblerConstantPools()) {}

AArch64TargetStreamer::~AArch64TargetStreamer() = default;

// The constant pool handling is shared by all AArch64TargetStreamer
// implementations.
const MCExpr *AArch64TargetStreamer::addConstantPoolEntry(const MCExpr *Expr,
                                                          unsigned Size,
                                                          SMLoc Loc) {
  return ConstantPools->addEntry(Streamer, Expr, Size, Loc);
}

void AArch64TargetStreamer::emitCurrentConstantPool() {
  ConstantPools->emitForCurrentSection(Streamer);
}

// finish() - write out any non-empty assembler constant pools.
void AArch64TargetStreamer::finish() { ConstantPools->emitAll(Streamer); }

void AArch64TargetStreamer::emitInst(uint32_t Inst,
                                     const MCSubtargetInfo &STI) {
  char Buffer[4];

  // We can't just use EmitIntValue here, as that will swap the
  // endianness on big-endian systems (instructions are always
  // little-endian).
  for (unsigned I = 0; I < 4; ++I) {
    Buffer[I] = uint8_t(Inst);
    Inst >>= 8;
  }

  getStreamer().emitBytes(StringRef(Buffer, 4));
}

const std::pair<uint64_t, uint64_t>
AArch64TargetStreamer::getTargetSizeAlignReq(uint64_t Size) {
  uint64_t Align = getMorelloRequiredAlignment(Size);
  uint64_t NewSize = alignTo(Size, Align);
  if (getMorelloRequiredAlignment(NewSize) != Align)
    return getTargetSizeAlignReq(NewSize);
  return  {NewSize, Log2_64(Align)};
}

namespace llvm {

MCTargetStreamer *
createAArch64ObjectTargetStreamer(MCStreamer &S, const MCSubtargetInfo &STI) {
  const Triple &TT = STI.getTargetTriple();
  if (TT.isOSBinFormatELF())
    return new AArch64TargetELFStreamer(S, STI);
  if (TT.isOSBinFormatCOFF())
    return new AArch64TargetWinCOFFStreamer(S);
  return nullptr;
}

} // end namespace llvm
