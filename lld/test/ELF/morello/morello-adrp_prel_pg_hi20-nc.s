// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=arm64 -mattr=+morello,+c64 %s -o %t.o
// RUN: ld.lld %t.o -o %t
// RUN: llvm-objdump --mattr=+morello -d %t | FileCheck %s

// CHECK: 0000000000210120 <foo>:
// CHECK-NEXT: adrp c25, 0xffffffff80210000 <foo+0xffffffff7ffffee0>
// CHECK-NEXT: adrp c26, 0x8020f000 <foo+0x7fffeee0>

  .text
  .global _start
  .type _start, %function
_start:
  foo = .
  adrp c25, :pg_hi21_nc:foo+0x80000000
  adrp c26, :pg_hi21_nc:foo-(0x80000000+0x1000)
