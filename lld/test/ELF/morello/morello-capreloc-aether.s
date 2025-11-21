// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=aarch64 %s -o %t.o -mattr=+morello,+c64
// RUN: ld.lld -T %S/Inputs/morello-capreloc-aether.script %t.o -o %t
// RUN: llvm-readobj -s --cap-relocs %t | FileCheck %s

.data
.chericap data_begin
.balign 32
.chericap data_end

// CHECK:          Name: data_begin
// CHECK-NEXT:     Value: 0x[[#%X,DATA_BEGIN:]]
// CHECK:          Name: data_end
// CHECK-NEXT:     Value: 0x[[#%X,DATA_END:]]

// CHECK:      __cap_relocs {
// CHECK-NEXT:   0x10060 RODATA - 0x[[#DATA_BEGIN]] [0x[[#DATA_BEGIN]]-0x[[#DATA_BEGIN]]]
// CHECK-NEXT:   0x10080 DATA - 0x[[#DATA_END]] [0x[[#DATA_END]]-0x[[#DATA_END]]]
// CHECK-NEXT: }
