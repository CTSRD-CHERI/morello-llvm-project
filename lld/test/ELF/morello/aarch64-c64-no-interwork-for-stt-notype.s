// RUN: llvm-mc --triple=aarch64-none-elf %s -mattr=+c64 --filetype=obj -o %t.o
// RUN: ld.lld %t.o -o %t
// RUN: llvm-objdump --no-show-raw-insn -d --triple=aarch64-none-elf --mattr=+morello %t | FileCheck %s
// RUN: llvm-readobj --symbols %t | FileCheck %s --check-prefix=SYMS

/// Interworking should only be done when symbols are of type STT_FUNC. In
/// this test case we should not insert a thunk even though notype has
/// the bottom bit clear.

// SYMS:          Name: notype
// SYMS-NEXT:     Value: 0x210128
// SYMS-NEXT:     Size: 0
// SYMS-NEXT:     Binding: Global
// SYMS-NEXT:     Type: None

// CHECK: 0000000000210120 <_start>:
// CHECK-NEXT:   210120:        bl      0x210128 <notype>
// CHECK-NEXT:   210124:        b       0x210128 <notype>
// CHECK: 0000000000210128 <notype>:
// CHECK-NEXT:   210128:        ret

 .text
 .balign 4
 .global _start
 .type _start, %function
 .size _start, 8
_start:
 bl notype
 b  notype

 .global notype
notype:
 ret
