// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64 -filetype=obj %s -o %t.o
// RUN: ld.lld -shared --cheri-codeptr-relocs %t.o -o %t
// RUN: llvm-readobj --relocs %t | FileCheck %s

 .text
 .type func, %function
 .size func, 4
func:
 ret

 .data
 .chericap func
 .chericap func@code

// CHECK: Relocations [
// CHECK-NEXT:   .rela.dyn {
// CHECK-NEXT:     0x303F0 R_MORELLO_FUNC_RELATIVE - 0x1
// CHECK-NEXT:     0x30400 R_MORELLO_RELATIVE - 0x1
// CHECK-NEXT:   }
// CHECK-NEXT: ]
