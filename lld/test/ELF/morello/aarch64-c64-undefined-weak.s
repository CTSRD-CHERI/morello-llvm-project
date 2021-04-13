// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=aarch64-none-linux -mattr=+c64 %s -o %t.o
// RUN: ld.lld %t.o -o %t
// RUN: llvm-objdump -d --no-show-raw-insn --mattr=+morello %t | FileCheck %s

/// Check that the ARM 64-bit ABI rules for undefined weak symbols are applied.
/// Branch instructions are resolved to the next instruction. Undefined
/// Symbols in relative are resolved to the place so S - P + A = A.

 .weak target

 .text
 .global _start
_start:
/// R_MORELLO_JUMP26
 b target
/// R_MORELLO_CALL26
 bl target
/// R_MORELLO_ADR_PREL_PG_HI20
 adrp c0, target
/// R_MORELLO_LD_PREL_LO17
 ldr c8, target

// CHECK: Disassembly of section .text:
// CHECK-EMPTY:
// CHECK:         210120:       b       0x210124 <_start+0x4>
// CHECK-NEXT:    210124:       bl      0x210128 <_start+0x8>
// CHECK-NEXT:    210128:       adrp    c0, #0
// CHECK-NEXT:    21012c:       ldr     c8, #0
