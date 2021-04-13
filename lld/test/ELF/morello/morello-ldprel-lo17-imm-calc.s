// REQUIRES: aarch64

/// Checking if Immediate(IMM) calculation is correct when
///   P modulo 16 == 0x0
///   P modulo 16 == 0x4
///   P modulo 16 == 0x8
///   P modulo 16 == 0xC
/// where P is the ldr instruction location (PC)
/// e.g.
///   P = 0x21016C
///   S = 0x220180
///   IMM = S + A - (P & ~0xF)
///       = 0x220180 - (0x21016C & ~0xF)
///       = 65568

// RUN: llvm-mc -filetype=obj -triple=aarch64-none-elf -mattr=+morello %s -o %t.o
// RUN: ld.lld %t.o -o %t
// RUN: llvm-objdump %t -d --mattr=+morello --no-show-raw-insn | FileCheck %s --check-prefix=DISASM
// RUN: llvm-readobj %t --symbols | FileCheck %s --check-prefix=SYM

// DISASM: Disassembly of section .text:
// DISASM-EMPTY:
// DISASM-NEXT:   0000000000210160 <_start>:
// FIXME: is this llvm-objdump output wrong?
// DISASM-NEXT:   210160:      ldr     c8, #65568
// DISASM-NEXT:   210164:      nop
// DISASM-NEXT:   210168:      nop
// DISASM-NEXT:   21016c:      ldr     c9, #65568
// DISASM-NEXT:   210170:      nop
// DISASM-NEXT:   210174:      ldr     c10, #65552
// DISASM-NEXT:   210178:      ldr     c11, #65552

// SYM: Name: sym (6)
// SYM-NEXT: Value: 0x220180

  .balign 16
  .text
  .global _start
  .type _start, %function
_start:
  ldr c8, sym  // P modulo 16 == 0x0
  nop
  nop
  ldr c9, sym  // P modulo 16 == 0xC
  nop
  ldr c10, sym // P modulo 16 == 0x4
  ldr c11, sym // P modulo 16 == 0x8

  .balign 16
  .data
sym:
