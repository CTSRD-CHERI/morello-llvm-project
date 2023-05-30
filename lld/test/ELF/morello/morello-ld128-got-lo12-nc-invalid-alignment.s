// REQUIRES: aarch64

// RUN: llvm-mc -filetype=obj --triple=arm64 -target-abi purecap -mattr=+c64,+morello %s -o %t.o
// RUN: not ld.lld %t.o -o /dev/null  2>&1 | FileCheck %s

// CHECK: improper alignment for relocation R_MORELLO_LD128_GOT_LO12_NC: 0x{{.*}}1 is not aligned to 16 bytes
// CHECK: improper alignment for relocation R_MORELLO_LD128_GOT_LO12_NC: 0x{{.*}}2 is not aligned to 16 bytes
// CHECK: improper alignment for relocation R_MORELLO_LD128_GOT_LO12_NC: 0x{{.*}}3 is not aligned to 16 bytes
// CHECK: improper alignment for relocation R_MORELLO_LD128_GOT_LO12_NC: 0x{{.*}}4 is not aligned to 16 bytes
// CHECK: improper alignment for relocation R_MORELLO_LD128_GOT_LO12_NC: 0x{{.*}}5 is not aligned to 16 bytes
// CHECK: improper alignment for relocation R_MORELLO_LD128_GOT_LO12_NC: 0x{{.*}}6 is not aligned to 16 bytes
// CHECK: improper alignment for relocation R_MORELLO_LD128_GOT_LO12_NC: 0x{{.*}}7 is not aligned to 16 bytes
// CHECK: improper alignment for relocation R_MORELLO_LD128_GOT_LO12_NC: 0x{{.*}}8 is not aligned to 16 bytes
// CHECK: improper alignment for relocation R_MORELLO_LD128_GOT_LO12_NC: 0x{{.*}}9 is not aligned to 16 bytes
// CHECK: improper alignment for relocation R_MORELLO_LD128_GOT_LO12_NC: 0x{{.*}}A is not aligned to 16 bytes
// CHECK: improper alignment for relocation R_MORELLO_LD128_GOT_LO12_NC: 0x{{.*}}B is not aligned to 16 bytes
// CHECK: improper alignment for relocation R_MORELLO_LD128_GOT_LO12_NC: 0x{{.*}}C is not aligned to 16 bytes
// CHECK: improper alignment for relocation R_MORELLO_LD128_GOT_LO12_NC: 0x{{.*}}D is not aligned to 16 bytes
// CHECK: improper alignment for relocation R_MORELLO_LD128_GOT_LO12_NC: 0x{{.*}}E is not aligned to 16 bytes
// CHECK: improper alignment for relocation R_MORELLO_LD128_GOT_LO12_NC: 0x{{.*}}F is not aligned to 16 bytes
// CHECK-NOT: improper alignment for relocation R_MORELLO_LD128_GOT_LO12_NC:

  .balign 16
  .text
  .global _start
  .type _start, %function
_start:
  ldr c8,  [c8,  :got_lo12:sym + 0x1]
  ldr c9,  [c9,  :got_lo12:sym + 0x2]
  ldr c10, [c10, :got_lo12:sym + 0x3]
  ldr c11, [c11, :got_lo12:sym + 0x4]
  ldr c12, [c12, :got_lo12:sym + 0x5]
  ldr c13, [c13, :got_lo12:sym + 0x6]
  ldr c14, [c14, :got_lo12:sym + 0x7]
  ldr c15, [c15, :got_lo12:sym + 0x8]
  ldr c16, [c16, :got_lo12:sym + 0x9]
  ldr c17, [c17, :got_lo12:sym + 0xA]
  ldr c18, [c18, :got_lo12:sym + 0xB]
  ldr c19, [c19, :got_lo12:sym + 0xC]
  ldr c20, [c20, :got_lo12:sym + 0xD]
  ldr c21, [c21, :got_lo12:sym + 0xE]
  ldr c22, [c22, :got_lo12:sym + 0xF]
  ldr c23, [c23, :got_lo12:sym + 0x0]

  .balign 16
  .data
  .global sym
  .size sym, 8
  .zero 1
sym:
 .xword 10
