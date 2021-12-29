// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64,+morello -filetype=obj %S/Inputs/shlib.s -o %t.o
// RUN: ld.lld --shared --soname=t.so  %t.o -o %t.so
// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64,+morello -filetype=obj %s -o %t.o
// RUN: ld.lld %t.so %t.o -o %t
// RUN: llvm-readobj --relocations --symbols -x .got.plt %t | FileCheck %s
// RUN: ld.lld --pie %t.so %t.o -o %tpie
// RUN: llvm-readobj --relocations --symbols -x .got.plt %tpie | FileCheck %s --check-prefix=PIE

/// Test R_MORELLO_IRELATIVE points to the correct location in the .got.plt.
/// The link is repeated for -fpie.

 .text
 .global _start
 .type _start, %function
_start:
 bl func
 adrp c1, :got: from_app
 ldr  c1, [c1, :got_lo12: from_app]
 ret
 .size _start, .-_start

 .global from_app
 .type from_app, STT_GNU_IFUNC
from_app:
 ret
 .size from_app, .-from_app


// CHECK:   0x230470 R_MORELLO_IRELATIVE - 0x100E1
// CHECK:      Name: from_app
// CHECK-NEXT: Value: 0x2102E1

/// Fragment should be so that base + addend = from_app value
// CHECK: 0x00230470 00022000 00000000 80020300 00000004

// PIE:    0x30480 R_MORELLO_IRELATIVE - 0x100E1
// PIE:      Name: from_app
// PIE-NEXT: Value: 0x102E1
/// Fragment should be so that base + addend = from_app value
// PIE: 0x00030480 00020000 00000000 c0020300 00000004
