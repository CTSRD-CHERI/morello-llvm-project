//===- AArch64.cpp --------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "InputFiles.h"
#include "OutputSections.h"
#include "Symbols.h"
#include "SyntheticSections.h"
#include "Target.h"
#include "lld/Common/ErrorHandler.h"
#include "llvm/BinaryFormat/ELF.h"
#include "llvm/Support/Endian.h"
#include "Cheri.h"

using namespace llvm;
using namespace llvm::support::endian;
using namespace llvm::ELF;
using namespace lld;
using namespace lld::elf;

// Page(Expr) is the page address of the expression Expr, defined
// as (Expr & ~0xFFF). (This applies even if the machine page size
// supported by the platform has a different value.)
uint64_t elf::getAArch64Page(uint64_t expr) {
  return expr & ~static_cast<uint64_t>(0xFFF);
}

namespace {
class AArch64 : public TargetInfo {
public:
  AArch64();
  bool calcIsCheriAbi() const override;
  uint32_t calcEFlags() const override;
  RelExpr getRelExpr(RelType type, const Symbol &s,
                     const uint8_t *loc) const override;
  RelType getDynRel(RelType type) const override;
  int getCapabilitySize() const override { return 16; }
  int64_t getImplicitAddend(const uint8_t *buf, RelType type) const override;
  void writeGotPlt(uint8_t *buf, const Symbol &s) const override;
  void writePltHeader(uint8_t *buf) const override;
  void writeFragmentAddress(uint8_t *buf, uint64_t val) const override;
  void writeFragmentSizeAndPermissions(uint8_t *buf,
                                       uint64_t val) const override;
  void writePlt(uint8_t *buf, const Symbol &sym,
                uint64_t pltEntryAddr) const override;
  bool needsThunk(RelExpr expr, RelType type, const InputFile *file,
                  uint64_t branchAddr, const Symbol &s,
                  int64_t a) const override;
  uint32_t getThunkSectionSpacing() const override;
  bool inBranchRange(RelType type, uint64_t src, uint64_t dst) const override;
  bool usesOnlyLowPageBits(RelType type) const override;
  void relocate(uint8_t *loc, const Relocation &rel,
                uint64_t val) const override;
  RelExpr adjustTlsExpr(RelType type, RelExpr expr) const override;
  void relaxTlsGdToLe(uint8_t *loc, const Relocation &rel,
                      uint64_t val) const override;
  void relaxTlsGdToIe(uint8_t *loc, const Relocation &rel,
                      uint64_t val) const override;
  void relaxTlsIeToLe(uint8_t *loc, const Relocation &rel,
                      uint64_t val) const override;
};
} // namespace

AArch64::AArch64() {
  copyRel = R_AARCH64_COPY;
  relativeRel = R_AARCH64_RELATIVE;
  iRelativeRel = R_AARCH64_IRELATIVE;
  gotRel = R_AARCH64_GLOB_DAT;
  pltRel = R_AARCH64_JUMP_SLOT;
  symbolicRel = R_AARCH64_ABS64;
  tlsDescRel = R_AARCH64_TLSDESC;
  tlsGotRel = R_AARCH64_TLS_TPREL64;
  pltHeaderSize = 32;
  pltEntrySize = 16;
  ipltEntrySize = 16;
  defaultMaxPageSize = 65536;

  // Align to the 2 MiB page size (known as a superpage or huge page).
  // FreeBSD automatically promotes 2 MiB-aligned allocations.
  defaultImageBase = 0x200000;

  needsThunks = true;
}

bool AArch64::calcIsCheriAbi() const {
  bool isCheriAbi = config->eflags & EF_AARCH64_CHERI_PURECAP;

  if (config->isCheriAbi && !objectFiles.empty() && !isCheriAbi)
    error(toString(objectFiles.front()) +
          ": object file is non-CheriABI but emulation forces it");

  return isCheriAbi;
}

static uint32_t getEFlags(InputFile *f) {
  return cast<ObjFile<llvm::object::ELF64LE>>(f)->getObj().getHeader().e_flags;
}

uint32_t AArch64::calcEFlags() const {
  if (objectFiles.empty())
    return 0;

  uint32_t target = getEFlags(objectFiles.front());

  for (InputFile *f : objectFiles) {
    uint32_t eflags = getEFlags(f);

    if ((eflags & EF_AARCH64_CHERI_PURECAP) !=
        (target & EF_AARCH64_CHERI_PURECAP))
      error(toString(f) +
            ": cannot link object files with different "
            "EF_AARCH64_CHERI_PURECAP");
  }

  return target;
}

RelExpr AArch64::getRelExpr(RelType type, const Symbol &s,
                            const uint8_t *loc) const {
  switch (type) {
  case R_AARCH64_ABS16:
  case R_AARCH64_ABS32:
  case R_AARCH64_ABS64:
  case R_AARCH64_ADD_ABS_LO12_NC:
  case R_AARCH64_LDST128_ABS_LO12_NC:
  case R_AARCH64_LDST16_ABS_LO12_NC:
  case R_AARCH64_LDST32_ABS_LO12_NC:
  case R_AARCH64_LDST64_ABS_LO12_NC:
  case R_AARCH64_LDST8_ABS_LO12_NC:
  case R_AARCH64_MOVW_SABS_G0:
  case R_AARCH64_MOVW_SABS_G1:
  case R_AARCH64_MOVW_SABS_G2:
  case R_AARCH64_MOVW_UABS_G0:
  case R_AARCH64_MOVW_UABS_G0_NC:
  case R_AARCH64_MOVW_UABS_G1:
  case R_AARCH64_MOVW_UABS_G1_NC:
  case R_AARCH64_MOVW_UABS_G2:
  case R_AARCH64_MOVW_UABS_G2_NC:
  case R_AARCH64_MOVW_UABS_G3:
    return R_ABS;
  case R_MORELLO_MOVW_SIZE_G0:
  case R_MORELLO_MOVW_SIZE_G0_NC:
  case R_MORELLO_MOVW_SIZE_G1:
  case R_MORELLO_MOVW_SIZE_G1_NC:
  case R_MORELLO_MOVW_SIZE_G2:
  case R_MORELLO_MOVW_SIZE_G2_NC:
  case R_MORELLO_MOVW_SIZE_G3:
    return R_MORELLO_SIZE;
  case R_AARCH64_TLSDESC_ADR_PAGE21:
    return R_AARCH64_TLSDESC_PAGE;
  case R_MORELLO_TLSDESC_ADR_PAGE20:
    return R_MORELLO_TLSDESC_PAGE;
  case R_AARCH64_TLSDESC_LD64_LO12:
  case R_AARCH64_TLSDESC_ADD_LO12:
  case R_MORELLO_TLSDESC_LD128_LO12:
    return R_TLSDESC;
  case R_AARCH64_TLSDESC_CALL:
  case R_MORELLO_TLSDESC_CALL:
    return R_TLSDESC_CALL;
  case R_AARCH64_TLSLE_ADD_TPREL_HI12:
  case R_AARCH64_TLSLE_ADD_TPREL_LO12_NC:
  case R_AARCH64_TLSLE_LDST8_TPREL_LO12_NC:
  case R_AARCH64_TLSLE_LDST16_TPREL_LO12_NC:
  case R_AARCH64_TLSLE_LDST32_TPREL_LO12_NC:
  case R_AARCH64_TLSLE_LDST64_TPREL_LO12_NC:
  case R_AARCH64_TLSLE_LDST128_TPREL_LO12_NC:
  case R_AARCH64_TLSLE_MOVW_TPREL_G0:
  case R_AARCH64_TLSLE_MOVW_TPREL_G0_NC:
  case R_AARCH64_TLSLE_MOVW_TPREL_G1:
  case R_AARCH64_TLSLE_MOVW_TPREL_G1_NC:
  case R_AARCH64_TLSLE_MOVW_TPREL_G2:
    return R_TPREL;
  case R_MORELLO_CALL26:
  case R_MORELLO_JUMP26:
  case R_MORELLO_CONDBR19:
  case R_MORELLO_TSTBR14:
  case R_AARCH64_CALL26:
  case R_AARCH64_CONDBR19:
  case R_AARCH64_JUMP26:
  case R_AARCH64_TSTBR14:
  case R_AARCH64_PLT32:
  case R_MORELLO_DESC_GLOBAL_CALL26:
  case R_MORELLO_DESC_GLOBAL_JUMP26:
  case R_AARCH64_DESC_GLOBAL_CALL26:
  case R_AARCH64_DESC_GLOBAL_JUMP26:
    return R_PLT_PC;
  case R_AARCH64_PREL16:
  case R_AARCH64_PREL32:
  case R_AARCH64_PREL64:
  case R_AARCH64_ADR_PREL_LO21:
  case R_AARCH64_LD_PREL_LO19:
  case R_AARCH64_MOVW_PREL_G0:
  case R_AARCH64_MOVW_PREL_G0_NC:
  case R_AARCH64_MOVW_PREL_G1:
  case R_AARCH64_MOVW_PREL_G1_NC:
  case R_AARCH64_MOVW_PREL_G2:
  case R_AARCH64_MOVW_PREL_G2_NC:
  case R_AARCH64_MOVW_PREL_G3:
    return R_PC;
  case R_AARCH64_ADR_PREL_PG_HI21:
  case R_AARCH64_ADR_PREL_PG_HI21_NC:
  case R_MORELLO_ADR_PREL_PG_HI20:
  case R_MORELLO_ADR_PREL_PG_HI20_NC:
    return R_AARCH64_PAGE_PC;
  case R_MORELLO_DESC_ADR_PREL_PG_HI20:
    return s.isDefined() ? R_MORELLO_DESC_PAGE_PC : R_AARCH64_PAGE_PC;
  case R_AARCH64_LD64_GOT_LO12_NC:
  case R_AARCH64_TLSIE_LD64_GOTTPREL_LO12_NC:
  case R_MORELLO_LD128_GOT_LO12_NC:
  case R_MORELLO_TLSIE_ADD_LO12:
  case R_MORELLO_DESC_LD128_GOT_LO12_NC:
    return R_GOT;
  case R_AARCH64_LD64_GOTPAGE_LO15:
    return R_AARCH64_GOT_PAGE;
  case R_AARCH64_ADR_GOT_PAGE:
  case R_MORELLO_ADR_GOT_PAGE:
  case R_AARCH64_TLSIE_ADR_GOTTPREL_PAGE21:
  case R_MORELLO_TLSIE_ADR_GOTTPREL_PAGE20:
    return R_AARCH64_GOT_PAGE_PC;
  case R_MORELLO_DESC_ADR_GOT_PAGE:
    return R_MORELLO_DESC_GOT_PAGE_PC;
  case R_AARCH64_NONE:
    return R_NONE;
  case R_MORELLO_CAPINIT:
    return R_CHERI_CAPABILITY;
  case R_MORELLO_DESC_CAPINIT:
    return R_MORELLO_DESC_CAPABILITY;
  case R_MORELLO_LD_PREL_LO17:
    return R_MORELLO_VADREF;
  default:
    error(getErrorLocation(loc) + "unknown relocation (" + Twine(type) +
          ") against symbol " + toString(s));
    return R_NONE;
  }
}

RelExpr AArch64::adjustTlsExpr(RelType type, RelExpr expr) const {
  if (expr == R_RELAX_TLS_GD_TO_IE) {
    if (type == R_AARCH64_TLSDESC_ADR_PAGE21 ||
        type == R_MORELLO_TLSDESC_ADR_PAGE20)
      return R_AARCH64_RELAX_TLS_GD_TO_IE_PAGE_PC;
    return R_RELAX_TLS_GD_TO_IE_ABS;
  }
  if (expr == R_RELAX_TLS_GD_TO_LE) {
    if (type == R_MORELLO_TLSDESC_ADR_PAGE20) {
      return R_MORELLO_RELAX_TLS_GD_TO_LE_PAGE_PC;
    }
    if (type == R_MORELLO_TLSDESC_LD128_LO12) {
      return R_MORELLO_RELAX_TLS_GD_TO_LE_ADD_LO12;
    }
  }
  if (expr == R_RELAX_TLS_IE_TO_LE) {
    if (type == R_MORELLO_TLSIE_ADD_LO12) {
      return R_MORELLO_RELAX_TLS_IE_TO_LE_ADD_LO12;
    }
    if (type == R_MORELLO_TLSIE_ADR_GOTTPREL_PAGE20) {
      return R_MORELLO_RELAX_TLS_IE_TO_LE_PAGE_PC;
    }
  }
  return expr;
}

bool AArch64::usesOnlyLowPageBits(RelType type) const {
  switch (type) {
  default:
    return false;
  case R_AARCH64_ADD_ABS_LO12_NC:
  case R_AARCH64_LD64_GOT_LO12_NC:
  case R_AARCH64_LDST128_ABS_LO12_NC:
  case R_AARCH64_LDST16_ABS_LO12_NC:
  case R_AARCH64_LDST32_ABS_LO12_NC:
  case R_AARCH64_LDST64_ABS_LO12_NC:
  case R_AARCH64_LDST8_ABS_LO12_NC:
  case R_AARCH64_TLSDESC_ADD_LO12:
  case R_AARCH64_TLSDESC_LD64_LO12:
  case R_AARCH64_TLSIE_LD64_GOTTPREL_LO12_NC:
  case R_MORELLO_TLSIE_ADD_LO12:
  case R_MORELLO_LD128_GOT_LO12_NC:
  case R_MORELLO_TLSDESC_LD128_LO12:
  case R_MORELLO_DESC_LD128_GOT_LO12_NC:
    return true;
  }
}

RelType AArch64::getDynRel(RelType type) const {
  if (type == R_AARCH64_ABS64)
    return type;
  return R_AARCH64_NONE;
}

int64_t AArch64::getImplicitAddend(const uint8_t *buf, RelType type) const {
  switch (type) {
  case R_AARCH64_TLSDESC:
    return read64(buf + 8);
  case R_AARCH64_NONE:
    return 0;
  case R_AARCH64_PREL32:
    return SignExtend64<32>(read32(buf));
  case R_AARCH64_ABS64:
  case R_AARCH64_PREL64:
    return read64(buf);
  default:
    internalLinkerError(getErrorLocation(buf),
                        "cannot read addend for relocation " + toString(type));
    return 0;
  }
}

void AArch64::writeGotPlt(uint8_t *buf, const Symbol &) const {
  write64(buf, in.plt->getVA());
}

void AArch64::writePltHeader(uint8_t *buf) const {
  const uint8_t pltData[] = {
      0xf0, 0x7b, 0xbf, 0xa9, // stp    x16, x30, [sp,#-16]!
      0x10, 0x00, 0x00, 0x90, // adrp   x16, Page(&(.plt.got[2]))
      0x11, 0x02, 0x40, 0xf9, // ldr    x17, [x16, Offset(&(.plt.got[2]))]
      0x10, 0x02, 0x00, 0x91, // add    x16, x16, Offset(&(.plt.got[2]))
      0x20, 0x02, 0x1f, 0xd6, // br     x17
      0x1f, 0x20, 0x03, 0xd5, // nop
      0x1f, 0x20, 0x03, 0xd5, // nop
      0x1f, 0x20, 0x03, 0xd5  // nop
  };
  memcpy(buf, pltData, sizeof(pltData));

  uint64_t got = in.gotPlt->getVA();
  uint64_t plt = in.plt->getVA();
  relocateNoSym(buf + 4, R_AARCH64_ADR_PREL_PG_HI21,
                getAArch64Page(got + 16) - getAArch64Page(plt + 4));
  relocateNoSym(buf + 8, R_AARCH64_LDST64_ABS_LO12_NC, got + 16);
  relocateNoSym(buf + 12, R_AARCH64_ADD_ABS_LO12_NC, got + 16);
}

void AArch64::writePlt(uint8_t *buf, const Symbol &sym,
                       uint64_t pltEntryAddr) const {
  const uint8_t inst[] = {
      0x10, 0x00, 0x00, 0x90, // adrp x16, Page(&(.plt.got[n]))
      0x11, 0x02, 0x40, 0xf9, // ldr  x17, [x16, Offset(&(.plt.got[n]))]
      0x10, 0x02, 0x00, 0x91, // add  x16, x16, Offset(&(.plt.got[n]))
      0x20, 0x02, 0x1f, 0xd6  // br   x17
  };
  memcpy(buf, inst, sizeof(inst));

  uint64_t gotPltEntryAddr = sym.getGotPltVA();
  relocateNoSym(buf, R_AARCH64_ADR_PREL_PG_HI21,
                getAArch64Page(gotPltEntryAddr) - getAArch64Page(pltEntryAddr));
  relocateNoSym(buf + 4, R_AARCH64_LDST64_ABS_LO12_NC, gotPltEntryAddr);
  relocateNoSym(buf + 8, R_AARCH64_ADD_ABS_LO12_NC, gotPltEntryAddr);
}

bool AArch64::needsThunk(RelExpr expr, RelType type, const InputFile *file,
                         uint64_t branchAddr, const Symbol &s,
                         int64_t a) const {
  // If s is an undefined weak symbol and does not have a PLT entry then it will
  // be resolved as a branch to the next instruction. If it is hidden, its
  // binding has been converted to local, so we just check isUndefined() here. A
  // undefined non-weak symbol will have been errored.
  if (s.isUndefined() && !s.isInPlt())
    return false;
  // ELF for the ARM 64-bit architecture, section Call and Jump relocations
  // only permits range extension thunks for R_AARCH64_CALL26 and
  // R_AARCH64_JUMP26 relocation types.
  if (type != R_AARCH64_CALL26 && type != R_AARCH64_JUMP26 &&
      type != R_AARCH64_PLT32 &&
      type != R_MORELLO_CALL26 && type != R_MORELLO_JUMP26)
    return false;
  uint64_t dst = (expr == R_PLT_PC) ? s.getPltVA() : s.getVA(a);

  switch (type) {
  case R_AARCH64_CALL26:
  case R_AARCH64_JUMP26:
    // Source is AArch64, need to interwork if a STT_FUNC Symbol has bit 0 set
    // (C64).
    return (s.isFunc() && (dst & 1) == 1) ||
           !inBranchRange(type, branchAddr, dst);
  case R_MORELLO_CALL26:
  case R_MORELLO_JUMP26:
  case R_AARCH64_PLT32:
    // Source is C64, need to interwork if a STT_FUNC Symbol has bit 0 clear
    // (AArch64).
    return (s.isFunc() && (dst & 1) == 0) ||
           !inBranchRange(type, branchAddr, dst);
  }
  return false;
}

uint32_t AArch64::getThunkSectionSpacing() const {
  // See comment in Arch/ARM.cpp for a more detailed explanation of
  // getThunkSectionSpacing(). For AArch64 the only branches we are permitted to
  // Thunk have a range of +/- 128 MiB
  return (128 * 1024 * 1024) - 0x30000;
}

bool AArch64::inBranchRange(RelType type, uint64_t src, uint64_t dst) const {
  if (type != R_AARCH64_CALL26 && type != R_AARCH64_JUMP26 &&
      type != R_AARCH64_PLT32 &&
      type != R_MORELLO_CALL26 && type != R_MORELLO_JUMP26)
    return true;
  // The bottom bit that determines whether C64 or AArch64 is not part of range.
  dst &= ~0x1;
  // The AArch64 call and unconditional branch instructions have a range of
  // +/- 128 MiB. The PLT32 relocation supports a range up to +/- 2 GiB.
  uint64_t range =
      type == R_AARCH64_PLT32 ? (UINT64_C(1) << 31) : (128 * 1024 * 1024);
  if (dst > src) {
    // Immediate of branch is signed.
    range -= 4;
    return dst - src <= range;
  }
  return src - dst <= range;
}

static void write32Addr(uint8_t *l, uint64_t imm, uint64_t himask) {
  uint32_t immLo = (imm & 0x3) << 29;
  uint32_t immHi = (imm & himask) << 3;
  uint64_t mask = (0x3 << 29) | (himask << 3);
  write32le(l, (read32le(l) & ~mask) | immLo | immHi);
}

// Return the bits [Start, End] from Val shifted Start bits.
// For instance, getBits(0xF0, 4, 8) returns 0xF.
static uint64_t getBits(uint64_t val, int start, int end) {
  uint64_t mask = ((uint64_t)1 << (end + 1 - start)) - 1;
  return (val >> start) & mask;
}

static void or32le(uint8_t *p, int32_t v) { write32le(p, read32le(p) | v); }

// Update the immediate field in a AARCH64 ldr, str, and add instruction.
static void or32AArch64Imm(uint8_t *l, uint64_t imm) {
  or32le(l, (imm & 0xFFF) << 10);
}

// Update the immediate field in an AArch64 movk, movn or movz instruction
// for a signed relocation, and update the opcode of a movn or movz instruction
// to match the sign of the operand.
static void writeSMovWImm(uint8_t *loc, uint32_t imm) {
  uint32_t inst = read32le(loc);
  // Opcode field is bits 30, 29, with 10 = movz, 00 = movn and 11 = movk.
  if (!(inst & (1 << 29))) {
    // movn or movz.
    if (imm & 0x10000) {
      // Change opcode to movn, which takes an inverted operand.
      imm ^= 0xFFFF;
      inst &= ~(1 << 30);
    } else {
      // Change opcode to movz.
      inst |= 1 << 30;
    }
  }
  write32le(loc, inst | ((imm & 0xFFFF) << 5));
}

void AArch64::relocate(uint8_t *loc, const Relocation &rel,
                       uint64_t val) const {
  switch (rel.type) {
  case R_AARCH64_ABS16:
  case R_AARCH64_PREL16:
    checkIntUInt(loc, val, 16, rel);
    write16(loc, val);
    break;
  case R_AARCH64_ABS32:
  case R_AARCH64_PREL32:
    checkIntUInt(loc, val, 32, rel);
    write32(loc, val);
    break;
  case R_AARCH64_PLT32:
    checkInt(loc, val, 32, rel);
    write32(loc, val);
    break;
  case R_AARCH64_ABS64:
  case R_AARCH64_PREL64:
    write64(loc, val);
    break;
  case R_AARCH64_ADD_ABS_LO12_NC:
    or32AArch64Imm(loc, val);
    break;
  case R_AARCH64_ADR_GOT_PAGE:
  case R_AARCH64_ADR_PREL_PG_HI21:
  case R_AARCH64_TLSIE_ADR_GOTTPREL_PAGE21:
  case R_AARCH64_TLSDESC_ADR_PAGE21:
    checkInt(loc, val, 33, rel);
    LLVM_FALLTHROUGH;
  case R_AARCH64_ADR_PREL_PG_HI21_NC:
    write32Addr(loc, val >> 12, 0x1FFFFC);
    break;
  case R_MORELLO_ADR_GOT_PAGE:
  case R_MORELLO_ADR_PREL_PG_HI20:
  case R_MORELLO_TLSIE_ADR_GOTTPREL_PAGE20:
  case R_MORELLO_TLSDESC_ADR_PAGE20:
    // FIXME: Although the diagnostic maximum range is 0x7FFFFFFF (2147483647),
    // because the equation, Page (S + A) - Page (P), is 12-bit aligned the
    // actual maximum range is 0x7FFFF000 (2147479552).
    checkInt(loc, val, 32, rel);
    LLVM_FALLTHROUGH;
  case R_MORELLO_ADR_PREL_PG_HI20_NC:
    write32Addr(loc, val >> 12, 0xFFFFC);
    break;
  case R_AARCH64_ADR_PREL_LO21:
    checkInt(loc, val, 21, rel);
    write32Addr(loc, val, 0x1FFFFC);
    break;
  case R_MORELLO_DESC_GLOBAL_CALL26:
  case R_MORELLO_DESC_GLOBAL_JUMP26:
  case R_AARCH64_DESC_GLOBAL_CALL26:
  case R_AARCH64_DESC_GLOBAL_JUMP26:
    // if not in PLT jump over the first instruction for the desc relocations
    if (rel.sym && rel.sym->type == STT_FUNC && !rel.sym->needsPlt)
      val += 4;
    LLVM_FALLTHROUGH;
  case R_MORELLO_CALL26:
  case R_MORELLO_JUMP26:
    // If bit 0 is clear then our target is in A64 state, interworking thunks
    // are not implemented yet.
    if ((val & 0x1) == 0x0)
      // FIXME: These should be errors, work around for newlib that contains
      // fini without STT_FUNC and the low bit set.
      warn(getErrorLocation(loc) + "Interworking between C64 and A64 not "
                                   "supported yet");
    checkInt(loc, val, 28, rel);
    or32le(loc, (val & 0x0FFFFFFC) >> 2);
    break;
  case R_AARCH64_JUMP26:
    // Normally we would just write the bits of the immediate field, however
    // when patching instructions for the cpu errata fix -fix-cortex-a53-843419
    // we want to replace a non-branch instruction with a branch immediate
    // instruction. By writing all the bits of the instruction including the
    // opcode and the immediate (0 001 | 01 imm26) we can do this
    // transformation by placing a R_AARCH64_JUMP26 relocation at the offset of
    // the instruction we want to patch.
    write32le(loc, 0x14000000);
    LLVM_FALLTHROUGH;
  case R_AARCH64_CALL26:
    checkInt(loc, val, 28, rel);
    or32le(loc, (val & 0x0FFFFFFC) >> 2);
    break;
  case R_MORELLO_CONDBR19:
  case R_AARCH64_CONDBR19:
    // For now we can't reliably detect interworking on STT_NOTYPE, so just
    // clear the LSB.
    val &= ~1;
    LLVM_FALLTHROUGH;
  case R_AARCH64_LD_PREL_LO19:
    checkAlignment(loc, val, 4, rel);
    checkInt(loc, val, 21, rel);
    or32le(loc, (val & 0x1FFFFC) << 3);
    break;
  case R_MORELLO_LD_PREL_LO17:
    // FIXME: The actual maximum range is 0xFFFF0 (1048560). However the
    // diagnostic maximum range (1048575) is 15-bytes too large (unaligned
    // values). The checkAlignment catches any use.
    checkAlignment(loc, val, 16, rel);
    checkInt(loc, val, 21, rel);
    or32le(loc, (val & 0x1FFFF0) << 1);
    break;
  case R_AARCH64_LDST8_ABS_LO12_NC:
  case R_AARCH64_TLSLE_LDST8_TPREL_LO12_NC:
    or32AArch64Imm(loc, getBits(val, 0, 11));
    break;
  case R_AARCH64_LDST16_ABS_LO12_NC:
  case R_AARCH64_TLSLE_LDST16_TPREL_LO12_NC:
    checkAlignment(loc, val, 2, rel);
    or32AArch64Imm(loc, getBits(val, 1, 11));
    break;
  case R_AARCH64_LDST32_ABS_LO12_NC:
  case R_AARCH64_TLSLE_LDST32_TPREL_LO12_NC:
    checkAlignment(loc, val, 4, rel);
    or32AArch64Imm(loc, getBits(val, 2, 11));
    break;
  case R_AARCH64_LDST64_ABS_LO12_NC:
  case R_AARCH64_LD64_GOT_LO12_NC:
  case R_AARCH64_TLSIE_LD64_GOTTPREL_LO12_NC:
  case R_AARCH64_TLSLE_LDST64_TPREL_LO12_NC:
  case R_AARCH64_TLSDESC_LD64_LO12:
    checkAlignment(loc, val, 8, rel);
    or32AArch64Imm(loc, getBits(val, 3, 11));
    break;
  case R_MORELLO_TLSIE_ADD_LO12:
    checkAlignment(loc, val, 16, rel);
    or32AArch64Imm(loc, val);
    break;
  case R_AARCH64_LDST128_ABS_LO12_NC:
  case R_AARCH64_TLSLE_LDST128_TPREL_LO12_NC:
  case R_MORELLO_LD128_GOT_LO12_NC:
  case R_MORELLO_TLSDESC_LD128_LO12:
  case R_MORELLO_DESC_LD128_GOT_LO12_NC:
    checkAlignment(loc, val, 16, rel);
    or32AArch64Imm(loc, getBits(val, 4, 11));
    break;
  case R_AARCH64_LD64_GOTPAGE_LO15:
    checkAlignment(loc, val, 8, rel);
    or32AArch64Imm(loc, getBits(val, 3, 14));
    break;
  case R_MORELLO_MOVW_SIZE_G0:
  case R_AARCH64_MOVW_UABS_G0:
    checkUInt(loc, val, 16, rel);
    LLVM_FALLTHROUGH;
  case R_MORELLO_MOVW_SIZE_G0_NC:
  case R_AARCH64_MOVW_UABS_G0_NC:
    or32le(loc, (val & 0xFFFF) << 5);
    break;
  case R_MORELLO_MOVW_SIZE_G1:
  case R_AARCH64_MOVW_UABS_G1:
    checkUInt(loc, val, 32, rel);
    LLVM_FALLTHROUGH;
  case R_MORELLO_MOVW_SIZE_G1_NC:
  case R_AARCH64_MOVW_UABS_G1_NC:
    or32le(loc, (val & 0xFFFF0000) >> 11);
    break;
  case R_MORELLO_MOVW_SIZE_G2:
  case R_AARCH64_MOVW_UABS_G2:
    checkUInt(loc, val, 48, rel);
    LLVM_FALLTHROUGH;
  case R_MORELLO_MOVW_SIZE_G2_NC:
  case R_AARCH64_MOVW_UABS_G2_NC:
    or32le(loc, (val & 0xFFFF00000000) >> 27);
    break;
  case R_MORELLO_MOVW_SIZE_G3:
  case R_AARCH64_MOVW_UABS_G3:
    or32le(loc, (val & 0xFFFF000000000000) >> 43);
    break;
  case R_AARCH64_MOVW_PREL_G0:
  case R_AARCH64_MOVW_SABS_G0:
  case R_AARCH64_TLSLE_MOVW_TPREL_G0:
    checkInt(loc, val, 17, rel);
    LLVM_FALLTHROUGH;
  case R_AARCH64_MOVW_PREL_G0_NC:
  case R_AARCH64_TLSLE_MOVW_TPREL_G0_NC:
    writeSMovWImm(loc, val);
    break;
  case R_AARCH64_MOVW_PREL_G1:
  case R_AARCH64_MOVW_SABS_G1:
  case R_AARCH64_TLSLE_MOVW_TPREL_G1:
    checkInt(loc, val, 33, rel);
    LLVM_FALLTHROUGH;
  case R_AARCH64_MOVW_PREL_G1_NC:
  case R_AARCH64_TLSLE_MOVW_TPREL_G1_NC:
    writeSMovWImm(loc, val >> 16);
    break;
  case R_AARCH64_MOVW_PREL_G2:
  case R_AARCH64_MOVW_SABS_G2:
  case R_AARCH64_TLSLE_MOVW_TPREL_G2:
    checkInt(loc, val, 49, rel);
    LLVM_FALLTHROUGH;
  case R_AARCH64_MOVW_PREL_G2_NC:
    writeSMovWImm(loc, val >> 32);
    break;
  case R_AARCH64_MOVW_PREL_G3:
    writeSMovWImm(loc, val >> 48);
    break;
  case R_MORELLO_TSTBR14:
  case R_AARCH64_TSTBR14:
    checkInt(loc, val, 16, rel);
    or32le(loc, (val & 0xFFFC) << 3);
    break;
  case R_AARCH64_TLSLE_ADD_TPREL_HI12:
    checkUInt(loc, val, 24, rel);
    or32AArch64Imm(loc, val >> 12);
    break;
  case R_AARCH64_TLSLE_ADD_TPREL_LO12_NC:
  case R_AARCH64_TLSDESC_ADD_LO12:
    or32AArch64Imm(loc, val);
    break;
  case R_AARCH64_TLSDESC:
    // For R_AARCH64_TLSDESC the addend is stored in the second 64-bit word.
    write64(loc + 8, val);
    break;
  case R_MORELLO_DESC_ADR_PREL_PG_HI20:
  case R_MORELLO_DESC_ADR_GOT_PAGE:
    // Reset bit 23 (P) to convert the ADRP to ADRDP
    write32le(loc, (read32le(loc) & ~(1 << 23)));
    // Setting the immediate is same as the ADRP
    relocateNoSym(loc, R_MORELLO_ADR_PREL_PG_HI20, val);
    break;
  default:
    llvm_unreachable("unknown relocation");
  }
}

void AArch64::writeFragmentAddress(uint8_t *buf, uint64_t val) const {
  write64le(buf, val);
}

void AArch64::writeFragmentSizeAndPermissions(uint8_t *buf,
                                              uint64_t val) const {
  struct FragmentSizeAndPerms {
    uint64_t length: 56;
    uint64_t permissions: 8;
  } sizeAndPerms;
  assert(sizeof(sizeAndPerms) == 8 && "sizeAndPerms size not 8 bytes");

  sizeAndPerms.permissions = getBits(val, 0, 7);
  sizeAndPerms.length = getBits(val, 8, 63);
  memcpy(buf, &sizeAndPerms, sizeof(sizeAndPerms));
}

void AArch64::relaxTlsGdToLe(uint8_t *loc, const Relocation &rel,
                             uint64_t val) const {
  // TLSDESC Global-Dynamic relocation are in the form:
  //   adrp    x0, :tlsdesc:v             [R_AARCH64_TLSDESC_ADR_PAGE21]
  //   ldr     x1, [x0, #:tlsdesc_lo12:v  [R_AARCH64_TLSDESC_LD64_LO12]
  //   add     x0, x0, :tlsdesc_los:v     [R_AARCH64_TLSDESC_ADD_LO12]
  //   .tlsdesccall                       [R_AARCH64_TLSDESC_CALL]
  //   blr     x1
  // And it can optimized to:
  //   movz    x0, #0x0, lsl #16
  //   movk    x0, #0x10
  //   nop
  //   nop
  checkUInt(loc, val, 32, rel);

  switch (rel.type) {
  case R_AARCH64_TLSDESC_ADD_LO12:
  case R_AARCH64_TLSDESC_CALL:
    write32le(loc, 0xd503201f); // nop
    return;
  case R_AARCH64_TLSDESC_ADR_PAGE21:
    write32le(loc, 0xd2a00000 | (((val >> 16) & 0xffff) << 5)); // movz
    return;
  case R_AARCH64_TLSDESC_LD64_LO12:
    write32le(loc, 0xf2800000 | ((val & 0xffff) << 5)); // movk
    return;
  default:
    llvm_unreachable("unsupported relocation for TLS GD to LE relaxation");
  }
}

void AArch64::relaxTlsGdToIe(uint8_t *loc, const Relocation &rel,
                             uint64_t val) const {
  // TLSDESC Global-Dynamic relocation are in the form:
  //   adrp    x0, :tlsdesc:v             [R_AARCH64_TLSDESC_ADR_PAGE21]
  //   ldr     x1, [x0, #:tlsdesc_lo12:v  [R_AARCH64_TLSDESC_LD64_LO12]
  //   add     x0, x0, :tlsdesc_los:v     [R_AARCH64_TLSDESC_ADD_LO12]
  //   .tlsdesccall                       [R_AARCH64_TLSDESC_CALL]
  //   blr     x1
  // And it can optimized to:
  //   adrp    x0, :gottprel:v
  //   ldr     x0, [x0, :gottprel_lo12:v]
  //   nop
  //   nop

  switch (rel.type) {
  case R_AARCH64_TLSDESC_ADD_LO12:
  case R_AARCH64_TLSDESC_CALL:
    write32le(loc, 0xd503201f); // nop
    break;
  case R_AARCH64_TLSDESC_ADR_PAGE21:
    write32le(loc, 0x90000000); // adrp
    relocateNoSym(loc, R_AARCH64_TLSIE_ADR_GOTTPREL_PAGE21, val);
    break;
  case R_AARCH64_TLSDESC_LD64_LO12:
    write32le(loc, 0xf9400000); // ldr
    relocateNoSym(loc, R_AARCH64_TLSIE_LD64_GOTTPREL_LO12_NC, val);
    break;
  default:
    llvm_unreachable("unsupported relocation for TLS GD to IE relaxation");
  }
}

void AArch64::relaxTlsIeToLe(uint8_t *loc, const Relocation &rel,
                             uint64_t val) const {
  checkUInt(loc, val, 32, rel);

  if (rel.type == R_AARCH64_TLSIE_ADR_GOTTPREL_PAGE21) {
    // Generate MOVZ.
    uint32_t regNo = read32le(loc) & 0x1f;
    write32le(loc, (0xd2a00000 | regNo) | (((val >> 16) & 0xffff) << 5));
    return;
  }
  if (rel.type == R_AARCH64_TLSIE_LD64_GOTTPREL_LO12_NC) {
    // Generate MOVK.
    uint32_t regNo = read32le(loc) & 0x1f;
    write32le(loc, (0xf2800000 | regNo) | ((val & 0xffff) << 5));
    return;
  }
  llvm_unreachable("invalid relocation for TLS IE to LE relaxation");
}

AArch64Relaxer::AArch64Relaxer(ArrayRef<Relocation> relocs) {
  if (!config->relax || config->emachine != EM_AARCH64) {
    safeToRelaxAdrpLdr = false;
    return;
  }
  // Check if R_AARCH64_ADR_GOT_PAGE and R_AARCH64_LD64_GOT_LO12_NC
  // always appear in pairs.
  size_t i = 0;
  const size_t size = relocs.size();
  for (; i != size; ++i) {
    if (relocs[i].type == R_AARCH64_ADR_GOT_PAGE) {
      if (i + 1 < size && relocs[i + 1].type == R_AARCH64_LD64_GOT_LO12_NC) {
        ++i;
        continue;
      }
      break;
    } else if (relocs[i].type == R_AARCH64_LD64_GOT_LO12_NC) {
      break;
    }
  }
  safeToRelaxAdrpLdr = i == size;
}

bool AArch64Relaxer::tryRelaxAdrpAdd(const Relocation &adrpRel,
                                     const Relocation &addRel, uint64_t secAddr,
                                     uint8_t *buf) const {
  // When the address of sym is within the range of ADR then
  // we may relax
  // ADRP xn, sym
  // ADD  xn, xn, :lo12: sym
  // to
  // NOP
  // ADR xn, sym
  if (!config->relax || adrpRel.type != R_AARCH64_ADR_PREL_PG_HI21 ||
      addRel.type != R_AARCH64_ADD_ABS_LO12_NC)
    return false;
  // Check if the relocations apply to consecutive instructions.
  if (adrpRel.offset + 4 != addRel.offset)
    return false;
  if (adrpRel.sym != addRel.sym)
    return false;
  if (adrpRel.addend != 0 || addRel.addend != 0)
    return false;

  uint32_t adrpInstr = read32le(buf + adrpRel.offset);
  uint32_t addInstr = read32le(buf + addRel.offset);
  // Check if the first instruction is ADRP and the second instruction is ADD.
  if ((adrpInstr & 0x9f000000) != 0x90000000 ||
      (addInstr & 0xffc00000) != 0x91000000)
    return false;
  uint32_t adrpDestReg = adrpInstr & 0x1f;
  uint32_t addDestReg = addInstr & 0x1f;
  uint32_t addSrcReg = (addInstr >> 5) & 0x1f;
  if (adrpDestReg != addDestReg || adrpDestReg != addSrcReg)
    return false;

  Symbol &sym = *adrpRel.sym;
  // Check if the address difference is within 1MiB range.
  int64_t val = sym.getVA() - (secAddr + addRel.offset);
  if (val < -1024 * 1024 || val >= 1024 * 1024)
    return false;

  Relocation adrRel = {R_ABS, R_AARCH64_ADR_PREL_LO21, addRel.offset,
                       /*addend=*/0, &sym};
  // nop
  write32le(buf + adrpRel.offset, 0xd503201f);
  // adr x_<dest_reg>
  write32le(buf + adrRel.offset, 0x10000000 | adrpDestReg);
  target->relocate(buf + adrRel.offset, adrRel, val);
  return true;
}

bool AArch64Relaxer::tryRelaxAdrpLdr(const Relocation &adrpRel,
                                     const Relocation &ldrRel, uint64_t secAddr,
                                     uint8_t *buf) const {
  if (!safeToRelaxAdrpLdr)
    return false;

  // When the definition of sym is not preemptible then we may
  // be able to relax
  // ADRP xn, :got: sym
  // LDR xn, [ xn :got_lo12: sym]
  // to
  // ADRP xn, sym
  // ADD xn, xn, :lo_12: sym

  if (adrpRel.type != R_AARCH64_ADR_GOT_PAGE ||
      ldrRel.type != R_AARCH64_LD64_GOT_LO12_NC)
    return false;
  // Check if the relocations apply to consecutive instructions.
  if (adrpRel.offset + 4 != ldrRel.offset)
    return false;
  // Check if the relocations reference the same symbol and
  // skip undefined, preemptible and STT_GNU_IFUNC symbols.
  if (!adrpRel.sym || adrpRel.sym != ldrRel.sym || !adrpRel.sym->isDefined() ||
      adrpRel.sym->isPreemptible || adrpRel.sym->isGnuIFunc())
    return false;
  // Check if the addends of the both relocations are zero.
  if (adrpRel.addend != 0 || ldrRel.addend != 0)
    return false;
  uint32_t adrpInstr = read32le(buf + adrpRel.offset);
  uint32_t ldrInstr = read32le(buf + ldrRel.offset);
  // Check if the first instruction is ADRP and the second instruction is LDR.
  if ((adrpInstr & 0x9f000000) != 0x90000000 ||
      (ldrInstr & 0x3b000000) != 0x39000000)
    return false;
  // Check the value of the sf bit.
  if (!(ldrInstr >> 31))
    return false;
  uint32_t adrpDestReg = adrpInstr & 0x1f;
  uint32_t ldrDestReg = ldrInstr & 0x1f;
  uint32_t ldrSrcReg = (ldrInstr >> 5) & 0x1f;
  // Check if ADPR and LDR use the same register.
  if (adrpDestReg != ldrDestReg || adrpDestReg != ldrSrcReg)
    return false;

  Symbol &sym = *adrpRel.sym;
  // GOT references to absolute symbols can't be relaxed to use ADRP/ADD in
  // position-independent code because these instructions produce a relative
  // address.
  if (config->isPic && !cast<Defined>(sym).section)
    return false;
  // Check if the address difference is within 4GB range.
  int64_t val =
      getAArch64Page(sym.getVA()) - getAArch64Page(secAddr + adrpRel.offset);
  if (val != llvm::SignExtend64(val, 33))
    return false;

  Relocation adrpSymRel = {R_AARCH64_PAGE_PC, R_AARCH64_ADR_PREL_PG_HI21,
                           adrpRel.offset, /*addend=*/0, &sym};
  Relocation addRel = {R_ABS, R_AARCH64_ADD_ABS_LO12_NC, ldrRel.offset,
                       /*addend=*/0, &sym};

  // adrp x_<dest_reg>
  write32le(buf + adrpSymRel.offset, 0x90000000 | adrpDestReg);
  // add x_<dest reg>, x_<dest reg>
  write32le(buf + addRel.offset, 0x91000000 | adrpDestReg | (adrpDestReg << 5));

  target->relocate(buf + adrpSymRel.offset, adrpSymRel,
                   SignExtend64(getAArch64Page(sym.getVA()) -
                                    getAArch64Page(secAddr + adrpSymRel.offset),
                                64));
  target->relocate(buf + addRel.offset, addRel, SignExtend64(sym.getVA(), 64));
  tryRelaxAdrpAdd(adrpSymRel, addRel, secAddr, buf);
  return true;
}

// AArch64 may use security features in variant PLT sequences. These are:
// Pointer Authentication (PAC), introduced in armv8.3-a and Branch Target
// Indicator (BTI) introduced in armv8.5-a. The additional instructions used
// in the variant Plt sequences are encoded in the Hint space so they can be
// deployed on older architectures, which treat the instructions as a nop.
// PAC and BTI can be combined leading to the following combinations:
// writePltHeader
// writePltHeaderBti (no PAC Header needed)
// writePlt
// writePltBti (BTI only)
// writePltPac (PAC only)
// writePltBtiPac (BTI and PAC)
//
// When PAC is enabled the dynamic loader encrypts the address that it places
// in the .got.plt using the pacia1716 instruction which encrypts the value in
// x17 using the modifier in x16. The static linker places autia1716 before the
// indirect branch to x17 to authenticate the address in x17 with the modifier
// in x16. This makes it more difficult for an attacker to modify the value in
// the .got.plt.
//
// When BTI is enabled all indirect branches must land on a bti instruction.
// The static linker must place a bti instruction at the start of any PLT entry
// that may be the target of an indirect branch. As the PLT entries call the
// lazy resolver indirectly this must have a bti instruction at start. In
// general a bti instruction is not needed for a PLT entry as indirect calls
// are resolved to the function address and not the PLT entry for the function.
// There are a small number of cases where the PLT address can escape, such as
// taking the address of a function or ifunc via a non got-generating
// relocation, and a shared library refers to that symbol.
//
// We use the bti c variant of the instruction which permits indirect branches
// (br) via x16/x17 and indirect function calls (blr) via any register. The ABI
// guarantees that all indirect branches from code requiring BTI protection
// will go via x16/x17

namespace {
class AArch64BtiPac final : public AArch64 {
public:
  AArch64BtiPac();
  void writePltHeader(uint8_t *buf) const override;
  void writePlt(uint8_t *buf, const Symbol &sym,
                uint64_t pltEntryAddr) const override;

private:
  bool btiHeader; // bti instruction needed in PLT Header and Entry
  bool pacEntry;  // autia1716 instruction needed in PLT Entry
};
} // namespace

AArch64BtiPac::AArch64BtiPac() {
  btiHeader = (config->andFeatures & GNU_PROPERTY_AARCH64_FEATURE_1_BTI);
  // A BTI (Branch Target Indicator) Plt Entry is only required if the
  // address of the PLT entry can be taken by the program, which permits an
  // indirect jump to the PLT entry. This can happen when the address
  // of the PLT entry for a function is canonicalised due to the address of
  // the function in an executable being taken by a shared library, or
  // non-preemptible ifunc referenced by non-GOT-generating, non-PLT-generating
  // relocations.
  // The PAC PLT entries require dynamic loader support and this isn't known
  // from properties in the objects, so we use the command line flag.
  pacEntry = config->zPacPlt;

  if (btiHeader || pacEntry) {
    pltEntrySize = 24;
    ipltEntrySize = 24;
  }
}

void AArch64BtiPac::writePltHeader(uint8_t *buf) const {
  const uint8_t btiData[] = { 0x5f, 0x24, 0x03, 0xd5 }; // bti c
  const uint8_t pltData[] = {
      0xf0, 0x7b, 0xbf, 0xa9, // stp    x16, x30, [sp,#-16]!
      0x10, 0x00, 0x00, 0x90, // adrp   x16, Page(&(.plt.got[2]))
      0x11, 0x02, 0x40, 0xf9, // ldr    x17, [x16, Offset(&(.plt.got[2]))]
      0x10, 0x02, 0x00, 0x91, // add    x16, x16, Offset(&(.plt.got[2]))
      0x20, 0x02, 0x1f, 0xd6, // br     x17
      0x1f, 0x20, 0x03, 0xd5, // nop
      0x1f, 0x20, 0x03, 0xd5  // nop
  };
  const uint8_t nopData[] = { 0x1f, 0x20, 0x03, 0xd5 }; // nop

  uint64_t got = in.gotPlt->getVA();
  uint64_t plt = in.plt->getVA();

  if (btiHeader) {
    // PltHeader is called indirectly by plt[N]. Prefix pltData with a BTI C
    // instruction.
    memcpy(buf, btiData, sizeof(btiData));
    buf += sizeof(btiData);
    plt += sizeof(btiData);
  }
  memcpy(buf, pltData, sizeof(pltData));

  relocateNoSym(buf + 4, R_AARCH64_ADR_PREL_PG_HI21,
                getAArch64Page(got + 16) - getAArch64Page(plt + 8));
  relocateNoSym(buf + 8, R_AARCH64_LDST64_ABS_LO12_NC, got + 16);
  relocateNoSym(buf + 12, R_AARCH64_ADD_ABS_LO12_NC, got + 16);
  if (!btiHeader)
    // We didn't add the BTI c instruction so round out size with NOP.
    memcpy(buf + sizeof(pltData), nopData, sizeof(nopData));
}

void AArch64BtiPac::writePlt(uint8_t *buf, const Symbol &sym,
                             uint64_t pltEntryAddr) const {
  // The PLT entry is of the form:
  // [btiData] addrInst (pacBr | stdBr) [nopData]
  const uint8_t btiData[] = { 0x5f, 0x24, 0x03, 0xd5 }; // bti c
  const uint8_t addrInst[] = {
      0x10, 0x00, 0x00, 0x90,  // adrp x16, Page(&(.plt.got[n]))
      0x11, 0x02, 0x40, 0xf9,  // ldr  x17, [x16, Offset(&(.plt.got[n]))]
      0x10, 0x02, 0x00, 0x91   // add  x16, x16, Offset(&(.plt.got[n]))
  };
  const uint8_t pacBr[] = {
      0x9f, 0x21, 0x03, 0xd5,  // autia1716
      0x20, 0x02, 0x1f, 0xd6   // br   x17
  };
  const uint8_t stdBr[] = {
      0x20, 0x02, 0x1f, 0xd6,  // br   x17
      0x1f, 0x20, 0x03, 0xd5   // nop
  };
  const uint8_t nopData[] = { 0x1f, 0x20, 0x03, 0xd5 }; // nop

  // needsCopy indicates a non-ifunc canonical PLT entry whose address may
  // escape to shared objects. isInIplt indicates a non-preemptible ifunc. Its
  // address may escape if referenced by a direct relocation. The condition is
  // conservative.
  bool hasBti = btiHeader && (sym.needsCopy || sym.isInIplt);
  if (hasBti) {
    memcpy(buf, btiData, sizeof(btiData));
    buf += sizeof(btiData);
    pltEntryAddr += sizeof(btiData);
  }

  uint64_t gotPltEntryAddr = sym.getGotPltVA();
  memcpy(buf, addrInst, sizeof(addrInst));
  relocateNoSym(buf, R_AARCH64_ADR_PREL_PG_HI21,
                getAArch64Page(gotPltEntryAddr) - getAArch64Page(pltEntryAddr));
  relocateNoSym(buf + 4, R_AARCH64_LDST64_ABS_LO12_NC, gotPltEntryAddr);
  relocateNoSym(buf + 8, R_AARCH64_ADD_ABS_LO12_NC, gotPltEntryAddr);

  if (pacEntry)
    memcpy(buf + sizeof(addrInst), pacBr, sizeof(pacBr));
  else
    memcpy(buf + sizeof(addrInst), stdBr, sizeof(stdBr));
  if (!hasBti)
    // We didn't add the BTI c instruction so round out size with NOP.
    memcpy(buf + sizeof(addrInst) + sizeof(stdBr), nopData, sizeof(nopData));
}

namespace {
class AArch64C64 : public AArch64 {
public:
  AArch64C64();
  void writePltHeader(uint8_t *buf) const override;
  void writePlt(uint8_t *buf, const Symbol &sym,
                uint64_t pltEntryAddr) const override;
  void writeGotPlt(uint8_t *buf, const Symbol &s) const override;
  void relaxTlsGdToLe(uint8_t *loc, const Relocation &rel,
                      uint64_t val) const override;
  void relaxTlsGdToIe(uint8_t *loc, const Relocation &rel,
                      uint64_t val) const override;
  void relaxTlsIeToLe(uint8_t *loc, const Relocation &rel,
                      uint64_t val) const override;
private:
  const uint8_t *getPltBranchR17() const;
};

class AArch64C64DescABI final : public AArch64C64 {
public:
  AArch64C64DescABI();
  void writePltHeader(uint8_t *buf) const override;
  void writePlt(uint8_t *buf, const Symbol &sym,
                uint64_t pltEntryAddr) const override;
};
} // namespace

AArch64C64::AArch64C64() {
  relativeRel = R_MORELLO_RELATIVE;
  iRelativeRel = R_MORELLO_IRELATIVE;
  gotRel = R_MORELLO_GLOB_DAT;
  pltRel = R_MORELLO_JUMP_SLOT;
  tlsDescRel = R_MORELLO_TLSDESC;
  gotEntrySize = 16;
  tlsGotRel = R_MORELLO_TLS_TPREL128;
}

const uint8_t *AArch64C64::getPltBranchR17() const {
  static const uint8_t brX17[] = {
      0x20, 0x02, 0x1f, 0xd6, // br x17
  };
  static const uint8_t brC17[] = {
      0x20, 0x12, 0xc2, 0xc2, // br c17
  };

  if (config->morelloPurecapBenchmarkABI)
    return brX17;
  else
    return brC17;
}

void AArch64C64::writePltHeader(uint8_t *buf) const {
  const uint8_t *b = getPltBranchR17();
  const uint8_t pltData[] = {
      0xf0, 0x7b, 0xbf, 0x62, // stp  c16, c30, [csp, #-32]!
      0x10, 0x00, 0x80, 0x90, // adrp c16, Page(&(.plt.got[2]))
      0x11, 0x02, 0x40, 0xc2, // ldr  c17, [c16, Offset(&(.plt.got[2]))]
      0x10, 0x02, 0x00, 0x02, // add  c16, c16, Offset(&(.plt.got[2]))
      b[0], b[1], b[2], b[3], // br   [xc]17
      0x1f, 0x20, 0x03, 0xd5, // nop
      0x1f, 0x20, 0x03, 0xd5, // nop
      0x1f, 0x20, 0x03, 0xd5, // nop
  };
  memcpy(buf, pltData, sizeof(pltData));

  uint64_t got = in.gotPlt->getVA();
  uint64_t plt = in.plt->getVA();
  relocateNoSym(buf + 4, R_MORELLO_ADR_PREL_PG_HI20,
                getAArch64Page(got + 32) - getAArch64Page(plt + 4));
  relocateNoSym(buf + 8, R_AARCH64_LDST128_ABS_LO12_NC, got + 32);
  relocateNoSym(buf + 12, R_AARCH64_ADD_ABS_LO12_NC, got + 32);
}

void AArch64C64::writePlt(uint8_t *buf, const Symbol &sym,
                          uint64_t pltEntryAddr) const {
  const uint8_t *b = getPltBranchR17();
  const uint8_t pltData[] = {
      0x10, 0x00, 0x80, 0x90, // adrp c16, PLTGOT + n * 16
      0x10, 0x02, 0x00, 0x02, // add  c16, c16, Offset(&(.plt.got[n]))
      0x11, 0x02, 0x40, 0xc2, // ldr  c17, [c16]
      b[0], b[1], b[2], b[3], // br   [xc]17
  };
  memcpy(buf, pltData, sizeof(pltData));

  uint64_t gotPltEntryAddr = sym.getGotPltVA();
  relocateNoSym(buf + 0, R_MORELLO_ADR_PREL_PG_HI20,
                getAArch64Page(gotPltEntryAddr) - getAArch64Page(pltEntryAddr));
  relocateNoSym(buf + 4, R_AARCH64_ADD_ABS_LO12_NC, gotPltEntryAddr);
}

void AArch64C64::writeGotPlt(uint8_t *buf, const Symbol &) const {
  // The PLT header is C64 and we transfer control to it via an indirect jump
  // so we must set the bottom bit.
  uint64_t va = in.plt->getVA();
  if (!config->morelloPurecapBenchmarkABI)
    va |= 1;
  writeFragmentAddress(buf, va);
}

void AArch64C64::relaxTlsGdToLe(uint8_t *loc, const Relocation &rel,
                             uint64_t val) const {
  // Morello TLSDESC Global-Dynamic relocation are in the form:
  //
  //  The instruction sequence is:
  //  adrp     c0, :tlsdesc:v             [R_MORELLO_TLSDESC_ADR_PAGE20]
  //  ldr      c1, [c0, #:tlsdesc_lo12:v] [R_MORELLO_TLSDESC_LD128_LO12]
  //  add      c0, c0, #:tlsdesc_lo12:v   [R_AARCH64_TLSDESC_ADD_LO12]
  //  nop
  //    .tlsdesccall v                    [R_MORELLO_TLSDESC_CALL]
  //  blr      c1
  //
  // And it can optimized to:
  //  adrp     c0, :gottprel:v
  //  add      c0, c0, :gottprel_lo12:v
  //  ldp      x0, x1, [c0]
  //  add      c0, c2, x0
  //  scbnds   c0, c0, x1
  switch (rel.type) {
  case R_MORELLO_TLSDESC_ADR_PAGE20:
    write32le(loc, 0x90800000); // adrp c0, <dataloc>
    relocateNoSym(loc, R_MORELLO_ADR_PREL_PG_HI20, val);
    return;
  case R_MORELLO_TLSDESC_LD128_LO12:
    write32le(loc, 0x02000000); // add c0, c0, <dataloc_lo12>
    relocateNoSym(loc, R_AARCH64_ADD_ABS_LO12_NC, val);
    return;
  case R_AARCH64_TLSDESC_ADD_LO12:
    write32le(loc, 0xa9400400); // ldp x0, x1, [c0]
    return;
  case R_MORELLO_TLSDESC_CALL:
    write32le(loc-4, 0xc2a06040); // add c0, c2, x0
    write32le(loc, 0xc2c10000); // scbnds c0, c0, x1
    return;
  default:
    llvm_unreachable("unknown relocation");
  }
}

void AArch64C64::relaxTlsGdToIe(uint8_t *loc, const Relocation &rel,
                                uint64_t val) const {
  // Morello TLSDESC Global-Dynamic relocation are in the form:
  //
  //  The instruction sequence is:
  //  adrp     c0, :tlsdesc:v             [R_MORELLO_TLSDESC_ADR_PAGE20]
  //  ldr      c1, [c0, #:tlsdesc_lo12:v] [R_MORELLO_TLSDESC_LD128_LO12]
  //  add      c0, c0, #:tlsdesc_lo12:v   [R_AARCH64_TLSDESC_ADD_LO12]
  //  nop
  //    .tlsdesccall v                    [R_MORELLO_TLSDESC_CALL]
  //  blr      c1
  //
  // And it can optimized to:
  //  adrp     c0, :gottprel:v
  //  add      c0, c0, :gottprel_lo12:v
  //  ldp      x0, x1, [c0]
  //  add      c0, c2, x0
  //  scbnds   c0, c0, x1
  switch (rel.type) {
  case R_MORELLO_TLSDESC_ADR_PAGE20:
    write32le(loc, 0x90800000); // adrp c0, :gottprel:v
    relocateNoSym(loc, R_MORELLO_TLSIE_ADR_GOTTPREL_PAGE20, val);
    return;
  case R_MORELLO_TLSDESC_LD128_LO12:
    write32le(loc, 0x02000000); // add c0, c0, :gottprel_lo12:v
    relocateNoSym(loc, R_MORELLO_TLSIE_ADD_LO12, val);
    return;
  case R_AARCH64_TLSDESC_ADD_LO12:
    write32le(loc, 0xa9400400); // ldp x0, x1, [c0]
    return;
  case R_MORELLO_TLSDESC_CALL:
    write32le(loc-4, 0xc2a06040); // add c0, c2, x0
    write32le(loc, 0xc2c10000); // scbnds c0, c0, x1
    return;
  default:
    llvm_unreachable("unsupported relocation for TLS GD to IE relaxation");
  }
}

void AArch64C64::relaxTlsIeToLe(uint8_t *loc, const Relocation &rel,
                                uint64_t val) const {
  switch (rel.type) {
  case R_MORELLO_TLSIE_ADR_GOTTPREL_PAGE20:
    relocateNoSym(loc, R_MORELLO_ADR_PREL_PG_HI20,
                  getAArch64Page(val));
    return;
  case R_MORELLO_TLSIE_ADD_LO12:
    relocateNoSym(loc, R_AARCH64_ADD_ABS_LO12_NC, val);
    return;
  default:
    llvm_unreachable("unknown relocation");
  }
}

AArch64C64DescABI::AArch64C64DescABI() {
  pltRel = R_MORELLO_DESC_JUMP_SLOT;
  gotRel = R_MORELLO_DESC_GLOB_DAT;
  iRelativeRel = R_MORELLO_DESC_IRELATIVE;
}

void AArch64C64DescABI::writePltHeader(uint8_t *buf) const {
  const uint8_t pltData[] = {
      0xf0, 0x7b, 0xbf, 0x62, // stp  c16, c30, [csp, #-32]!
      0x10, 0x00, 0x80, 0x90, // adrp c16, Page(&(.plt.got[2]))
      0x11, 0x02, 0x40, 0xc2, // ldr  c29, [c16, Offset(&(.plt.got[2]))]
      0x10, 0x02, 0x00, 0x02, // add  c16, c16, Offset(&(.plt.got[2]))
      0x1d, 0x12, 0xc4, 0xc2, // ldpbr	c29, [c16]
      0x1f, 0x20, 0x03, 0xd5, // nop
      0x1f, 0x20, 0x03, 0xd5, // nop
      0x1f, 0x20, 0x03, 0xd5, // nop
  };

  memcpy(buf, pltData, sizeof(pltData));

  uint64_t got = in.gotPlt->getVA();
  relocateNoSym(buf + 4, R_MORELLO_DESC_ADR_PREL_PG_HI20,
                getAArch64Page(got + 32) - Out::descPhdr->firstSec->addr);
  relocateNoSym(buf + 8, R_AARCH64_LDST128_ABS_LO12_NC, got + 32);
  relocateNoSym(buf + 12, R_AARCH64_ADD_ABS_LO12_NC, got + 32);
}

void AArch64C64DescABI::writePlt(uint8_t *buf, const Symbol &sym,
                                 uint64_t pltEntryAddr) const {
  const uint8_t pltData[] = {
      0x10, 0x00, 0x00, 0x90, // adrdp  c16, :got:foo
      0x10, 0x02, 0x00, 0x02, // add   c16, c16, :got_lo12:foo
      0x1d, 0x02, 0x40, 0xc2, // ldr   c29, [c16]
      0xbd, 0x13, 0xc4, 0xc2, // ldpbr c29, [c29]
  };
  memcpy(buf, pltData, sizeof(pltData));

  uint64_t gotPltEntryAddr = sym.getGotPltVA();
  relocateNoSym(buf + 0, R_MORELLO_DESC_ADR_PREL_PG_HI20,
                getAArch64Page(gotPltEntryAddr) - Out::descPhdr->firstSec->addr);
  relocateNoSym(buf + 4, R_AARCH64_ADD_ABS_LO12_NC, gotPltEntryAddr);
}

static TargetInfo *getTargetInfo() {
  if (config->morelloC64Plt) {
    if (config->isCheriFnDesc) {
      static AArch64C64DescABI t;
      return &t;
    } else {
      static AArch64C64 t;
      return &t;
    }
  }
  if (config->andFeatures & (GNU_PROPERTY_AARCH64_FEATURE_1_BTI |
                             GNU_PROPERTY_AARCH64_FEATURE_1_PAC)) {
    static AArch64BtiPac t;
    return &t;
  }
  static AArch64 t;
  return &t;
}

TargetInfo *elf::getAArch64TargetInfo() { return getTargetInfo(); }
