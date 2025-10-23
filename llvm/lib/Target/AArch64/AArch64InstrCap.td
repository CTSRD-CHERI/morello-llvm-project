//==- AArch64InstrCap.td - Capability specific definitions -*- tablegen -*--==//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//==------------------------------------------------------------------------==//
//
// AArch64 Capability Specific Definitions.
//
//==------------------------------------------------------------------------==//

def AArch64desccall         : SDNode<"AArch64ISD::CCALL",
                                SDTypeProfile<0, -1, [SDTCisCapPtrTy<0>]>,
                                [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue,
                                 SDNPVariadic]>;

let isCall = 1, Defs = [LR], Uses = [SP] in {
  def CBranchLinkClear : Pseudo<(outs), (ins Cap:$Cn), []>;
}

let isBarrier = 1, isReturn = 1, isTerminator = 1 in {
  def CRET_ReallyLR : Pseudo<(outs), (ins),
                             [(AArch64cretglue)]>;
  def CRET_ReallyLRClear : Pseudo<(outs), (ins),
                                  [(AArch64cretglueclear)]>;
  def RET_ReallyLRClear : Pseudo<(outs), (ins),
                                 [(AArch64retglueclear)]>;
}

let isCall = 1, isTerminator = 1, isReturn = 1,
    isBarrier = 1, Uses = [SP] in {
  def CTCRETURNr : Pseudo<(outs), (ins tcCap:$dst, i32imm:$FPDiff), []>;
  def ClearCTCRETURNr : Pseudo<(outs), (ins tcCap:$dst, i32imm:$FPDiff), []>;
}

let hasSideEffects = 1 in {
  def BaseRegSetup : Pseudo<(outs), (ins Cap:$src), []>;
  def BaseRegRestore : Pseudo<(outs), (ins), []>;
}

// This models the case where DDC is assumed to be time invariant, like when we
// need to construct a capability from global variable address.
let mayLoad = 0, hasSideEffects = 0, mayStore = 0 in
def GetDDC : Pseudo<(outs Cap:$dst), (ins), []>;

let Predicates = [HasC64], isReMaterializable = 1, isCodeGenOnly = 1 in {
def CMOVaddr
    : Pseudo<(outs Cap:$dst), (ins i64imm:$hi, i64imm:$low),
             [(set Cap:$dst, (AArch64caddlow (AArch64cadrp tglobaladdr:$hi),
                                              tglobaladdr:$low))]>,
      Sched<[WriteAdrAdr]>;
def CMOVaddrJT
    : Pseudo<(outs Cap:$dst), (ins i64imm:$hi, i64imm:$low),
             [(set Cap:$dst, (AArch64caddlow (AArch64cadrp tjumptable:$hi),
                                               tjumptable:$low))]>,
      Sched<[WriteAdrAdr]>;
def CMOVaddrCP
    : Pseudo<(outs Cap:$dst), (ins i64imm:$hi, i64imm:$low),
             [(set Cap:$dst, (AArch64caddlow (AArch64cadrp tconstpool:$hi),
                                               tconstpool:$low))]>,
      Sched<[WriteAdrAdr]>;
def CMOVaddrBA
    : Pseudo<(outs Cap:$dst), (ins i64imm:$hi, i64imm:$low),
             [(set Cap:$dst, (AArch64caddlow (AArch64cadrp tblockaddress:$hi),
                                               tblockaddress:$low))]>,
      Sched<[WriteAdrAdr]>;
def CMOVaddrTLS
    : Pseudo<(outs Cap:$dst), (ins i64imm:$hi, i64imm:$low),
             [(set Cap:$dst, (AArch64caddlow (AArch64cadrp tglobaltlsaddr:$hi),
                                               tglobaltlsaddr:$low))]>,
      Sched<[WriteAdrAdr]>;
def CMOVaddrEXT
    : Pseudo<(outs Cap:$dst), (ins i64imm:$hi, i64imm:$low),
             [(set Cap:$dst, (AArch64caddlow (AArch64cadrp texternalsym:$hi),
                                               texternalsym:$low))]>,
      Sched<[WriteAdrAdr]>;

def CAdr : Pseudo<(outs Cap:$dst), (ins adrlabel:$label), []>;
def CAdrp : Pseudo<(outs Cap:$dst), (ins adrplabel:$label),
                   [(set Cap:$dst, (AArch64cadrp tglobaladdr:$label))]>;
}

let Predicates = [HasC64] in {
  def : Pat<(AArch64cadrp tjumptable:$cp), (CAdrp tjumptable:$cp)>;
  def : Pat<(AArch64cadrp tconstpool:$cp), (CAdrp tconstpool:$cp)>;
  def : Pat<(AArch64cadrp tblockaddress:$cp), (CAdrp tblockaddress:$cp)>;
  def : Pat<(AArch64cadrp tglobaltlsaddr:$cp), (CAdrp tglobaltlsaddr:$cp)>;
  def : Pat<(AArch64cadrp texternalsym:$cp), (CAdrp texternalsym:$cp)>;
}

// NB: Not adjusted for C64 - see AArch64TargetLowering::LowerBR_JT
let Size = 12, Constraints = "@earlyclobber $dst,@earlyclobber $scratch" in {
def MCJumpTableDest32 : Pseudo<(outs Cap:$dst, GPR64sp:$scratch),
                               (ins Cap:$table, GPR64:$entry, i32imm:$jti), []>,
                        Sched<[]>;
def MCJumpTableDest16 : Pseudo<(outs Cap:$dst, GPR64sp:$scratch),
                               (ins Cap:$table, GPR64:$entry, i32imm:$jti), []>,
                        Sched<[]>;
def MCJumpTableDest8 : Pseudo<(outs Cap:$dst, GPR64sp:$scratch),
                              (ins Cap:$table, GPR64:$entry, i32imm:$jti), []>,
                       Sched<[]>;
}

def ldxr_fatptr : PatFrag<(ops node:$ptr), (int_aarch64_cldxr node:$ptr), [{
  return cast<MemIntrinsicSDNode>(N)->getMemoryVT() == MVT::c128;
}]>;

def ldaxr_fatptr : PatFrag<(ops node:$ptr), (int_aarch64_cldaxr node:$ptr), [{
  return cast<MemIntrinsicSDNode>(N)->getMemoryVT() == MVT::c128;
}]>;

def stxr_fatptr : PatFrag<(ops node:$val, node:$ptr),
                     (int_aarch64_cstxr node:$val, node:$ptr), [{
  return cast<MemIntrinsicSDNode>(N)->getMemoryVT() == MVT::c128;
}]>;

def stlxr_fatptr : PatFrag<(ops node:$val, node:$ptr),
                     (int_aarch64_cstlxr node:$val, node:$ptr), [{
  return cast<MemIntrinsicSDNode>(N)->getMemoryVT() == MVT::c128;
}]>;

//===----------------------------------
// Atomic cmpxchg for -O0
//===----------------------------------

let Constraints = "@earlyclobber $Rd,@earlyclobber $scratch",
    mayLoad = 1, mayStore = 1 in {
def CMP_SWAP_CAP_8 : Pseudo<(outs GPR32:$Rd, GPR32:$scratch),
                            (ins Cap:$addr, GPR32:$desired, GPR32:$new), []>,
                     Sched<[WriteAtomic]>;

def CMP_SWAP_CAP_16 : Pseudo<(outs GPR32:$Rd, GPR32:$scratch),
                             (ins Cap:$addr, GPR32:$desired, GPR32:$new), []>,
                      Sched<[WriteAtomic]>;

def CMP_SWAP_CAP_32 : Pseudo<(outs GPR32:$Rd, GPR32:$scratch),
                             (ins Cap:$addr, GPR32:$desired, GPR32:$new), []>,
                      Sched<[WriteAtomic]>;

def CMP_SWAP_CAP_64 : Pseudo<(outs GPR64:$Rd, GPR32:$scratch),
                             (ins Cap:$addr, GPR64:$desired, GPR64:$new), []>,
                      Sched<[WriteAtomic]>;

def CMP_SWAP_FATPTR : Pseudo<(outs Cap:$Rd, GPR32:$scratch),
                             (ins GPR64:$addr, Cap:$desired, Cap:$new), []>,
                      Sched<[WriteAtomic]>;

def CMP_SWAP_CAP_FATPTR : Pseudo<(outs Cap:$Rd, GPR32:$scratch),
                                 (ins Cap:$addr, Cap:$desired, Cap:$new), []>,
                          Sched<[WriteAtomic]>;
}

let Constraints = "@earlyclobber $RdLo,@earlyclobber $RdHi,@earlyclobber $scratch",
    mayLoad = 1, mayStore = 1 in {
class cmp_swap_cap_128 : Pseudo<(outs GPR64:$RdLo, GPR64:$RdHi, GPR32common:$scratch),
                                (ins Cap:$addr, GPR64:$desiredLo, GPR64:$desiredHi,
                                     GPR64:$newLo, GPR64:$newHi), []>,
                       Sched<[WriteAtomic]>;
def CMP_SWAP_CAP_128 : cmp_swap_cap_128;
def CMP_SWAP_CAP_128_RELEASE : cmp_swap_cap_128;
def CMP_SWAP_CAP_128_ACQUIRE : cmp_swap_cap_128;
def CMP_SWAP_CAP_128_MONOTONIC : cmp_swap_cap_128;
}
