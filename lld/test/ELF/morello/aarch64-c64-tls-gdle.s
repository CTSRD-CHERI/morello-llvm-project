/// Check relaxation from Global Dynamic to Local Executable

// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=aarch64-unknown-linux %s -o %tmain.o -mattr=+c64,+morello
// RUN: llvm-mc -filetype=obj -triple=aarch64-unknown-linux %p/Inputs/aarch64-c64-tls-gdle.s -o %ttlsle.o -mattr=+c64,+morello
// RUN: ld.lld --morello-c64-plt %tmain.o %ttlsle.o -o %tout
// RUN: llvm-objdump -d --mattr=+morello --print-imm-hex --no-show-raw-insn %tout | FileCheck %s
// RUN: llvm-readobj -rS %tout | FileCheck --check-prefix=REL --check-prefix=SEC %s

  .globl _start
_start:
  nop
  adrp    c0, :tlsdesc:foo
  ldr     c1, [c0, :tlsdesc_lo12:foo]
  add     c0, c0, :tlsdesc_lo12:foo
  .tlsdesccall foo
  blr     c1

/// foo is in the same module. So no dynamic relocations needed.
// REL:      Relocations [
// REL-NEXT: ]

/// page(0x220220) - page(0x210200) = 65536
/// 0x220 = 544

// CHECK:      <_start>:
// CHECK-NEXT: 2101c8: mov	x0, #0xfe0000
// CHECK-NEXT: 2101cc: movk	x0, #0xed20
// CHECK-NEXT: 2101d0: mov	x1, #0xbe0000
// CHECK-NEXT: 2101d4: movk	x1, #0xef00
// CHECK-NEXT: 2101d8: add	c0, c2, x0, uxtx
