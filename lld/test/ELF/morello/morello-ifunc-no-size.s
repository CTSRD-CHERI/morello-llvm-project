// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64,+morello -filetype=obj %s -o %t.o
// RUN: ld.lld %t.o -o %t
// RUN: llvm-readobj --relocations --symbols -x .got.plt %t | FileCheck %s

/// Check that we don't crash due to trying to read a capability fragment from
/// the synthetic IgotPltSection as a fallback for the size.

  .text
  .global _start
  .type _start, %function
_start:
  bl no_size
  ret
  .size _start, . - _start

  .type no_size, %gnu_indirect_function
no_size:
  ret

// CHECK:      0x220240 R_MORELLO_IRELATIVE - 0x10069

// CHECK:      Name: no_size
// CHECK-NEXT: Value: 0x210229

/// Fragment address (0x2001c0) + addend (0x10069) == no_size (0x210229)
// CHECK:      Hex dump of section '.got.plt':
// CHECK-NEXT: 0x00220240 c0012000 00000000 c0000200 00000004
