// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64 -filetype=obj %s -o %t.o
// RUN: echo "SECTIONS { \
// RUN:       .text_low 0x2004: { *(.text.1) } \
// RUN:       .text_high 0x8002000 : { *(.text.2) } \
// RUN:       } " > %t.script
// RUN: ld.lld %t.o -o %t --script=%t.script
// RUN: llvm-objdump --no-show-raw-insn -d %t --triple=aarch64-none-elf --mattr=+c64 | FileCheck %s

/// Test that we can handle the R_MORELLO_JUMP26 and R_MORELLO_CALL26 relocations.
/// These are essentially the same as R_AARCH64_JUMP26 and R_AARCH_CALL26
/// except that the source is in C64 state. In the example both source and
/// destination are in C64 state.
 .section .text.1, "ax", %progbits
 .globl _start
 .type _start, %function
 .globl low
 .type low, %function
_start:
  b high
low: bl high2

 .section .text.2, "ax", %progbits
 .globl high
 .type high, %function
 .globl high2
 .type high2, %function
high: nop
high2: b _start
 bl low

// CHECK: Disassembly of section .text_low:
// CHECK: 0000000000002004 <_start>:
// CHECK-NEXT:        2004:        b       0x8002000 <high>
// CHECK: 0000000000002008 <low>:
// CHECK-NEXT:        2008:        bl      0x8002004 <high2>
// CHECK: Disassembly of section .text_high:
// CHECK: 0000000008002000 <high>:
// CHECK-NEXT:     8002000:        nop
// CHECK: 0000000008002004 <high2>:
// CHECK-NEXT:     8002004:        b       0x2004 <_start>
// CHECK-NEXT:     8002008:        bl      0x2008 <low>
