// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64,+morello -filetype=obj %s -o %t.o
// RUN: echo "SECTIONS { \
// RUN:         other : { \
// RUN:           *(.data); \
// RUN:         } \
// RUN:       } " > %t.script
// RUN: ld.lld --local-caprelocs=elf %t.o -o %t --script %t.script
// RUN: llvm-readobj --relocs --symbols -x other %t | FileCheck %s

 .data
 .balign 16
hello:
 .string "Hello World"
 .size hello, . - hello

 .type ptr1, %object
 .size ptr1, 16
ptr1:
 .chericap hello + 8

 .type ptr2, %object
 .size ptr2, 16
ptr2:
 .chericap bye

bye:
 .string "Bye World"
 .size bye, . - bye

 .globl __rela_dyn_start
 .globl __rela_dyn_end
 .xword __rela_dyn_start
 .xword __rela_dyn_end

// CHECK: Relocations [
// CHECK-NEXT:   .rela.dyn {
// CHECK-NEXT:     0x40 R_MORELLO_RELATIVE - 0x8
// CHECK-NEXT:     0x50 R_MORELLO_RELATIVE - 0x0
// CHECK-NEXT:   }
// CHECK-NEXT: ]

// CHECK     :   Symbol {
// CHECK:          Name: hello
// CHECK-NEXT:     Value: 0x30
// CHECK-NEXT:     Size: 12
// CHECK-NEXT:     Binding: Local
// CHECK-NEXT:     Type: None
// CHECK-NEXT:     Other: 0
// CHECK-NEXT:     Section: other
// CHECK-NEXT:   }

// CHECK     :   Symbol {
// CHECK:          Name: ptr1
// CHECK-NEXT:     Value: 0x3C
// CHECK-NEXT:     Size: 16
// CHECK-NEXT:     Binding: Local
// CHECK-NEXT:     Type: Object
// CHECK-NEXT:     Other: 0
// CHECK-NEXT:     Section: other
// CHECK-NEXT:   }

// CHECK     :   Symbol {
// CHECK:          Name: ptr2
// CHECK-NEXT:     Value: 0x50
// CHECK-NEXT:     Size: 16
// CHECK-NEXT:     Binding: Local
// CHECK-NEXT:     Type: Object
// CHECK-NEXT:     Other: 0
// CHECK-NEXT:     Section: other
// CHECK-NEXT:   }

// CHECK     :   Symbol {
// CHECK:          Name: bye
// CHECK-NEXT:     Value: 0x60
// CHECK-NEXT:     Size: 10
// CHECK-NEXT:     Binding: Local
// CHECK-NEXT:     Type: None
// CHECK-NEXT:     Other: 0
// CHECK-NEXT:     Section: other
// CHECK-NEXT:   }

// CHECK     :   Symbol {
// CHECK:          Name: __rela_dyn_start
// CHECK-NEXT:     Value: 0x0
// CHECK-NEXT:     Size: 0
// CHECK-NEXT:     Binding: Local
// CHECK-NEXT:     Type: None
// CHECK-NEXT:     Other [
// CHECK-NEXT:       STV_HIDDEN
// CHECK-NEXT:     ]
// CHECK-NEXT:     Section: .rela.dyn
// CHECK-NEXT:   }

// CHECK     :   Symbol {
// CHECK:          Name: __rela_dyn_end
// CHECK-NEXT:     Value: 0x30
// CHECK-NEXT:     Size: 0
// CHECK-NEXT:     Binding: Local
// CHECK-NEXT:     Type: None
// CHECK-NEXT:     Other [
// CHECK-NEXT:       STV_HIDDEN
// CHECK-NEXT:     ]
// CHECK-NEXT:     Section: .rela.dyn
// CHECK-NEXT:   }

/// Check contents of section other
/// string (hello): "Hello World"
/// cap frag (ptr1): address: 0x30 ("Hello world"), size: 12(0xc), perm: RW(0x2)
/// cap frag (ptr2): address: 0x60 ("Bye world"), size: 10(0xa), perm: RW(0x2)
/// string (bye): "Bye World"

// CHECK:      Hex dump of section 'other':
// CHECK-NEXT: 0x00000030 48656c6c 6f20576f 726c6400 00000000 Hello World.....
// CHECK-NEXT: 0x00000040 30000000 00000000 0c000000 00000002 0...............
// CHECK-NEXT: 0x00000050 60000000 00000000 0a000000 00000002 `...............
// CHECK-NEXT: 0x00000060 42796520 576f726c 6400{{.*}}        Bye World.
