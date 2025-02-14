// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-linux-gnu -mattr=+c64 %s -filetype=obj -o %t.o
// RUN: ld.lld -r %t.o -o %t2.o
// RUN: llvm-readobj --sections --relocs %t2.o | FileCheck %s

/// Test that we do not produce a __cap_relocs section when doing a relocatable
/// link
 .data.rel.ro
 .chericap sym1

 .chericap sym2

 .data
 .global sym1
 .type sym1, %object
 .size sym1, 8
sym1:
 .xword 0
 .global sym2
 .type sym2, %object
 .size sym2, 8
sym2:
 .xword 0

// CHECK-NOT: Name: __cap_relocs

// CHECK: Relocations [
// CHECK-NEXT:   Section (3) .rela.data.rel.ro {
// CHECK-NEXT:     0x0 R_MORELLO_CAPINIT sym1 0x0
// CHECK-NEXT:     0x10 R_MORELLO_CAPINIT sym2 0x0
