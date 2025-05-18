// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64,+morello -filetype=obj %s -o %t.o
// RUN: ld.lld --shared  %t.o -o %t
// RUN: llvm-objdump -s %t | FileCheck %s --check-prefix=DATA
// RUN: llvm-readobj --expand-relocs --relocations --symbols --cap-relocs %t | FileCheck %s

/// Basics of the capinit relocation using dynamic linking.
/// We create two capabilites via .chericap. These will produce R_MORELLO_CAPINIT
/// Relocations that the linker will use to create dynamic relocations for
/// the dynamic loader to create the capabilities

 .text
 .type _start, %function
 .globl _start
 .balign 4
_start:
 ret

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

 .type ptr3, %object
 .size ptr3, 16
ptr3:
 .chericap foo + 0x10

/// Check that the linker uses the remaining size of the output section (0x14)
/// when the size is not provided in the symbol table.
 .type ptr4, %object
 .size ptr4, 16
ptr4:
 .chericap unsized_str

 .local str
 .type str, %object
 .size str, 12
str:
 .string "Hello World"

 .local unsized_str
 .type unsized_str, %object
unsized_str:
 .string "Bye World"

 .globl foo
 .type foo, %object
 .size foo, 8
foo:
 .balign 8
 .8byte 0

/// Check that we write the size, permissions and address if relevant to the
/// Fragment.
// DATA: Contents of section .data:
// DATA:       30450 90040300 00000000 0c000000 00000002
// DATA-NEXT:  30460 90040300 00000000 0c000000 00000002
// DATA-NEXT:  30470 a6040300 00000000 08000000 00000002
// DATA-NEXT:  30480 9c040300 00000000 14000000 00000002
// DATA-NEXT:  30490 48656c6c 6f20576f 726c6400 42796520 Hello World.Bye
// DATA-NEXT:  304a0 576f726c 64000000 00000000 00000000 World

/// Dynamic relocations
// CHECK: Relocations [
// CHECK-NEXT:   Section {{.*}} .rela.dyn {
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x30450
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x8
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x30460
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x30480
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x30470
// CHECK-NEXT:       Type: R_MORELLO_CAPINIT
// CHECK-NEXT:       Symbol: foo (2)
// CHECK-NEXT:       Addend: 0x10
// CHECK-NEXT:     }
// CHECK-NEXT:   }
// CHECK-NEXT: ]

/// Symbols
// CHECK:   Symbol {
// CHECK:     Name: str
// CHECK-NEXT:     Value: 0x30490
// CHECK-NEXT:     Size: 12
// CHECK-NEXT:     Binding: Local
// CHECK-NEXT:     Type: Object
// CHECK-NEXT:     Other: 0
// CHECK-NEXT:     Section: .data
// CHECK-NEXT:   }

// CHECK:     Name: unsized_str
// CHECK-NEXT:     Value: 0x3049C
// CHECK-NEXT:     Size: 0
// CHECK-NEXT:     Binding: Local
// CHECK-NEXT:     Type: Object
// CHECK-NEXT:     Other: 0
// CHECK-NEXT:     Section: .data
// CHECK-NEXT:   }

// CHECK:     Name: foo
// CHECK-NEXT:     Value: 0x304A6
// CHECK-NEXT:     Size: 8
// CHECK-NEXT:     Binding: Global
// CHECK-NEXT:     Type: Object
// CHECK-NEXT:     Other: 0
// CHECK-NEXT:     Section: .data
// CHECK-NEXT:   }
// CHECK-NEXT: ]

// CHECK-NEXT: There is no __cap_relocs section in the file.
