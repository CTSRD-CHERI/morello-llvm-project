// REQUIRES: aarch64
// RUN: llvm-mc -target-abi purecap --triple=aarch64-none-elf -mattr=+c64 -filetype=obj %s -o %t.o
// RUN: echo "SECTIONS { \
// RUN:       .note.cheri 0x200000: { \
// RUN:          *(.note.cheri); \
// RUN:       } \
// RUN:       .text 0x210000: { *(.text) } \
// RUN:       mysection : { \
// RUN:          PROVIDE_HIDDEN(__start_mysection = .); \
// RUN:          *(mysection); \
// RUN:          PROVIDE_HIDDEN(__stop_mysection = .); \
// RUN:       } \
// RUN:       .preinit_array : { \
// RUN:          PROVIDE_HIDDEN(__preinit_array_start = .); \
// RUN:          *(.preinit_array); \
// RUN:          PROVIDE_HIDDEN(__preinit_array_end = .); \
// RUN:       } \
// RUN:       .init_array : { \
// RUN:          PROVIDE_HIDDEN(__init_array_start = .); \
// RUN:          *(.init_array); \
// RUN:          PROVIDE_HIDDEN(__init_array_end = .); \
// RUN:       } \
// RUN:       .fini_array : { \
// RUN:          PROVIDE_HIDDEN(__fini_array_start = .); \
// RUN:          *(.fini_array); \
// RUN:          PROVIDE_HIDDEN(__fini_array_end = .); \
// RUN:       } \
// RUN:       .data.rel.ro : { \
// RUN:          *(.data.rel.ro); \
// RUN:       } \
// RUN:       } " > %t.script

// RUN: ld.lld -v --local-caprelocs=elf %t.o -o %t --script %t.script
// RUN: llvm-readobj --section-headers --symbols --relocs --expand-relocs -x .data.rel.ro %t | FileCheck %s

/// Using a linker script. Check that linker defined section start symbols
/// get the size of the output section, and stop/end symbols get a size of 0.

 .section .preinit_array, "a", %preinit_array
 .balign 1024
 .xword 0

 .section .init_array, "a", %init_array
 .balign 1024
 .xword 0

 .section .fini_array, "a", %fini_array
 .balign 1024
 .xword 0

 .section mysection, "a", %progbits
 .balign 1024
 .xword 0

 .text
 .balign 1024

 .globl _start
 .type _start, %function
_start: ret

 .data.rel.ro

 .capinit __preinit_array_start
 .xword 0
 .xword 0
 .capinit __preinit_array_end
 .xword 0
 .xword 0

 .capinit __init_array_start
 .xword 0
 .xword 0
 .capinit __init_array_end
 .xword 0
 .xword 0

 .capinit __fini_array_start
 .xword 0
 .xword 0
 .capinit __fini_array_end
 .xword 0
 .xword 0

 .capinit __start_mysection
 .xword 0
 .xword 0

 .capinit __stop_mysection
 .xword 0
 .xword 0

/// TODO: Check the fragments

// CHECK: Sections [
// CHECK:    Name: mysection
// CHECK-NEXT:    Type: SHT_PROGBITS (0x1)
// CHECK-NEXT:    Flags [ (0x2)
// CHECK-NEXT:      SHF_ALLOC (0x2)
// CHECK-NEXT:    ]
// CHECK-NEXT:    Address: 0x210400
// CHECK-NEXT:    Offset:
// CHECK-NEXT:    Size: 32

// CHECK:    Name: .preinit_array
// CHECK-NEXT:    Type: SHT_PREINIT_ARRAY (0x10)
// CHECK-NEXT:    Flags [ (0x3)
// CHECK-NEXT:      SHF_ALLOC (0x2)
// CHECK-NEXT:      SHF_WRITE (0x1)
// CHECK-NEXT:    ]
// CHECK-NEXT:    Address: 0x210800
// CHECK-NEXT:    Offset:
// CHECK-NEXT:    Size: 8

// CHECK:    Name: .init_array
// CHECK-NEXT:    Type: SHT_INIT_ARRAY (0xE)
// CHECK-NEXT:    Flags [ (0x3)
// CHECK-NEXT:      SHF_ALLOC (0x2)
// CHECK-NEXT:      SHF_WRITE (0x1)
// CHECK-NEXT:    ]
// CHECK-NEXT:    Address: 0x210C00
// CHECK-NEXT:    Offset:
// CHECK-NEXT:    Size: 8

// CHECK:    Name: .fini_array
// CHECK-NEXT:    Type: SHT_FINI_ARRAY (0xF)
// CHECK-NEXT:    Flags [ (0x3)
// CHECK-NEXT:      SHF_ALLOC (0x2)
// CHECK-NEXT:      SHF_WRITE (0x1)
// CHECK-NEXT:    ]
// CHECK-NEXT:    Address: 0x211000
// CHECK-NEXT:    Offset:
// CHECK-NEXT:    Size: 8


// CHECK: Relocations [
// CHECK-NEXT:   .rela.dyn {
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x211008
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x211018
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x211028
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x211038
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x211048
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x211058
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x211068
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x211078
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:   }
// CHECK-NEXT: ]

// CHECK: Symbols [
// CHECK:     Name: __preinit_array_start
// CHECK-NEXT:     Value: 0x210800
// CHECK-NEXT:     Size: 8
// CHECK-NEXT:     Binding: Local
// CHECK-NEXT:     Type: None
// CHECK-NEXT:    Other [
// CHECK-NEXT:      STV_HIDDEN
// CHECK-NEXT:    ]
// CHECK-NEXT:    Section: .preinit_array

// CHECK:     Name: __preinit_array_end
// CHECK-NEXT:     Value: 0x210808
// CHECK-NEXT:     Size: 0
// CHECK-NEXT:     Binding: Local
// CHECK-NEXT:     Type: None
// CHECK-NEXT:    Other [
// CHECK-NEXT:      STV_HIDDEN
// CHECK-NEXT:    ]
// CHECK-NEXT:    Section: .preinit_array

// CHECK:     Name: __init_array_start
// CHECK-NEXT:     Value: 0x210C00
// CHECK-NEXT:     Size: 8
// CHECK-NEXT:     Binding: Local
// CHECK-NEXT:     Type: None
// CHECK-NEXT:    Other [
// CHECK-NEXT:      STV_HIDDEN
// CHECK-NEXT:    ]
// CHECK-NEXT:    Section: .init_array

// CHECK:     Name: __init_array_end
// CHECK-NEXT:     Value: 0x210C08
// CHECK-NEXT:     Size: 0
// CHECK-NEXT:     Binding: Local
// CHECK-NEXT:     Type: None
// CHECK-NEXT:    Other [
// CHECK-NEXT:      STV_HIDDEN
// CHECK-NEXT:    ]
// CHECK-NEXT:    Section: .init_array

// CHECK:     Name: __fini_array_start
// CHECK-NEXT:     Value: 0x211000
// CHECK-NEXT:     Size: 8
// CHECK-NEXT:     Binding: Local
// CHECK-NEXT:     Type: None
// CHECK-NEXT:    Other [
// CHECK-NEXT:      STV_HIDDEN
// CHECK-NEXT:    ]
// CHECK-NEXT:    Section: .fini_array

// CHECK:     Name: __fini_array_end
// CHECK-NEXT:     Value: 0x211008
// CHECK-NEXT:     Size: 0
// CHECK-NEXT:     Binding: Local
// CHECK-NEXT:     Type: None
// CHECK-NEXT:    Other [
// CHECK-NEXT:      STV_HIDDEN
// CHECK-NEXT:    ]
// CHECK-NEXT:    Section: .fini_array

// CHECK:     Name: __start_mysection
// CHECK-NEXT:     Value: 0x210400
// CHECK-NEXT:     Size: 32
// CHECK-NEXT:     Binding: Local
// CHECK-NEXT:     Type: None
// CHECK-NEXT:    Other [
// CHECK-NEXT:      STV_HIDDEN
// CHECK-NEXT:    ]
// CHECK-NEXT:    Section: mysection

// CHECK:     Name: __stop_mysection
// CHECK-NEXT:     Value: 0x210408
// CHECK-NEXT:     Size: 0
// CHECK-NEXT:     Binding: Local
// CHECK-NEXT:     Type: None
// CHECK-NEXT:    Other [
// CHECK-NEXT:      STV_HIDDEN
// CHECK-NEXT:    ]
// CHECK-NEXT:    Section: mysection

// CHECK:      Hex dump of section '.data.rel.ro':

/// __preinit_array_start: address: 0x210800, size = 8, perms = RO(0x1)
// CHECK-NEXT: 0x00211008 00082100 00000000 08000000 00000001
/// __preinit_array_end: address: 0x210808, size = 0, perms = RO(0x1)
// CHECK-NEXT: 0x00211018 08082100 00000000 00000000 00000001

/// __init_array_start: address: 0x210800, size = 8, perms = RO(0x1)
// CHECK-NEXT: 0x00211028 000c2100 00000000 08000000 00000001
/// __init_array_end: address: 0x210C08, size = 0, perms = RO(0x1)
// CHECK-NEXT: 0x00211038 080c2100 00000000 00000000 00000001

/// __fini_array_start: address: 0x211000, size = 8, perms = RO(0x1)
// CHECK-NEXT: 0x00211048 00102100 00000000 08000000 00000001
/// __fini_array_end: address: 0x211008, size = 0, perms = RO(0x1)
// CHECK-NEXT: 0x00211058 08102100 00000000 00000000 00000001

/// __start_mysection: address: 0x210400, size = 32, perms = RO(0x1)
// CHECK-NEXT: 0x00211068 00042100 00000000 20000000 00000001
/// __stop_mysection: address: 0x210408, size = 0, perms = RO(0x1)
// CHECK-NEXT: 0x00211078 08042100 00000000 00000000 00000001
