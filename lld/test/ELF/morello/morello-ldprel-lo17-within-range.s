// REQUIRES: aarch64

/// Test max and min values of Immediate(IMM) does not throw out of range errors.
///   -2^20 (-1048576) <= IMM < 2^20 - 16 (1048560)

// RUN: llvm-mc -filetype=obj --triple=arm64 -mattr=+morello %s -o %t.o

// RUN: echo "SECTIONS { \
// RUN:       .data 0x10FFF0: { *(.data) } \
// RUN:       .text 0x010000: { *(.text) } \
// RUN: }" > %t.script
// RUN: ld.lld --script=%t.script %t.o -o %t_max
// RUN: llvm-objdump %t_max -d --mattr=+morello --no-show-raw-insn | FileCheck %s --check-prefix=MAX_DISASM

// RUN: echo "SECTIONS { \
// RUN:       .data 0x002000: { *(.data) } \
// RUN:       .text 0x102000: { *(.text) } \
// RUN: }" > %t.script
// RUN: ld.lld --script=%t.script %t.o -o %t_min
// RUN: llvm-objdump %t_min -d --mattr=+morello --no-show-raw-insn | FileCheck %s --check-prefix=MIN_DISASM

// MAX_DISASM:   0000000000010000 <_start>:
// MAX_DISASM-NEXT:   10000:      ldr      c8, #0xffff0

// MIN_DISASM:   0000000000102000 <_start>:
// MIN_DISASM-NEXT:   102000:      ldr      c8, #-0x100000

  .text
  .global _start
  .type _start, %function
_start:
  ldr c8,  sym_1

  .data
sym_1:
