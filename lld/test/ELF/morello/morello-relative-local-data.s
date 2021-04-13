// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64,+morello -filetype=obj %s -o %t.o
// RUN: ld.lld --shared --morello-c64-plt %t.o -o %t.so --fatal-warnings
// RUN: llvm-readobj --relocations %t.so | FileCheck %s --check-prefix=RELS
// RUN: llvm-objdump --no-show-raw-insn -d --triple=aarch64-none-elf --mattr=+morello -s %t.so | FileCheck %s

 .section .data.rel.ro
 .capinit local + 3
 .xword 0
 .xword 0

 .section .data
 .local local
 .type local, %object
 .size local, 32
local:
 .xword 0xD
 .xword 0xE
 .xword 0xA
 .xword 0xD
 .xword 0xB
 .xword 0xE
 .xword 0xE
 .xword 0xF

/// Check the relative relocation points to the fragment, and
/// holds the addend
// RELS: Relocations
// RELS-NEXT: .rela.dyn
// RELS-NEXT: 0x20260 R_MORELLO_RELATIVE - 0x3

/// Check the fragment at location pointed by the Relocation (0x20300)
// CHECK: Contents of section .data.rel.ro:
// CHECK: 20260 20030300 00000000 20000000 00000002

/// Check that data (DEADBEEF) starts at the location pointed by the fragment
/// 0x30320
// CHECK: Contents of section .data:
// CHECK: 30320 0d000000 00000000 0e000000 00000000
// CHECK: 30330 0a000000 00000000 0d000000 00000000
// CHECK: 30340 0b000000 00000000 0e000000 00000000
// CHECK: 30350 0e000000 00000000 0f000000 00000000
