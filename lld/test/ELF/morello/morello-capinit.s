// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64,+morello -filetype=obj %s -o %t.o
// RUN: ld.lld %t.o -o %t
// RUN: llvm-readobj --cap-relocs --symbols %t | FileCheck %s
// RUN: ld.lld --local-caprelocs=legacy %t.o -o %t1
// RUN: llvm-readobj --cap-relocs --symbols %t1 | FileCheck %s

/// Basics of the capinit relocation using static linking.
/// We create two capabilites via .chericap. These will produce R_MORELLO_CAPINIT
/// Relocations that the linker will use to create the __cap_relocs section.
/// We also check that the linker creates the __cap_relocs_start and
/// __cap_relocs_end symbols that a C-library can use to initialise the
/// capabilities with.

 .data
 .balign 16
 .type ptr1, %object
 .size ptr1, 16
ptr1:
 .chericap str + 8

 .type ptr2, %object
 .size ptr2, 16
ptr2:
 .chericap str

str:
 .string "Hello World"
 .size str, . - str

 .globl __cap_relocs_start
 .globl __cap_relocs_end
 .xword __cap_relocs_start
 .xword __cap_relocs_end

// CHECK:          Name: ptr1
// CHECK-NEXT:     Value: 0x[[#%X,PTR1:]]
// CHECK:          Name: str
// CHECK-NEXT:     Value: 0x[[#%X,STR:]]
// CHECK:          Name: ptr2
// CHECK-NEXT:     Value: 0x[[#%X,PTR2:]]

// CHECK:          Name: __cap_relocs_start
// CHECK-NEXT:     Value: 0x2201C8
// CHECK-NEXT:     Size: 0
// CHECK-NEXT:     Binding: Local (0x0)
// CHECK-NEXT:     Type: None (0x0)
// CHECK-NEXT:     Other [ (0x2)
// CHECK-NEXT:       STV_HIDDEN (0x2)
// CHECK-NEXT:     ]
// CHECK-NEXT:     Section: __cap_relocs
// CHECK-NEXT:   }
// CHECK-NEXT:   Symbol {
// CHECK-NEXT:     Name: __cap_relocs_end
// CHECK-NEXT:     Value: 0x220218
// CHECK-NEXT:     Size: 0
// CHECK-NEXT:     Binding: Local (0x0)
// CHECK-NEXT:     Type: None (0x0)
// CHECK-NEXT:     Other [ (0x2)
// CHECK-NEXT:       STV_HIDDEN (0x2)
// CHECK-NEXT:     ]
// CHECK-NEXT:     Section: __cap_relocs
// CHECK-NEXT:   }

// CHECK: __cap_relocs {
// CHECK-NEXT:    0x[[#PTR1]] DATA - 0x[[#STR+8]] [0x[[#STR]]-0x[[#STR+12]]]
// CHECK-NEXT:    0x[[#PTR2]] DATA - 0x[[#STR]] [0x[[#STR]]-0x[[#STR+12]]]
