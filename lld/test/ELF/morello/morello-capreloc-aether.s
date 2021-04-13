// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=aarch64 %s -o %t.o -mattr=+morello,+c64
// RUN: ld.lld -T %S/Inputs/morello-capreloc-aether.script %t.o -o %t
// RUN: llvm-readobj --cap-relocs %t | FileCheck %s

.data
.capinit data_begin
.8byte 0
.8byte 0
.balign 32
.capinit data_end
.8byte 0
.8byte 0

// CHECK:      CHERI __cap_relocs [
// CHECK-NEXT:   0x010060 ($d.0) Base: 0x10000 (data_begin+0) Length: 0 Perms: (RODATA)
// CHECK-NEXT:   0x010080 Base: 0x20000 (data_end+0) Length: 0 Perms: (RWDATA)
// CHECK-NEXT: ]
