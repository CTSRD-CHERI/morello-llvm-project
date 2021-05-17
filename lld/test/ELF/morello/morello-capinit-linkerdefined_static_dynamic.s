// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64 -filetype=obj %s -o %t.o
// RUN: ld.lld --morello-static-caps=elf -fatal-warnings -v %t.o -o %t
// RUN: llvm-readobj --section-headers --symbols --relocs --expand-relocs -x .data.rel.ro %t | FileCheck %s

/// Check that linker defined section start symbols get the size of the output
/// section, and stop/end symbols get a size of 0.

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


// CHECK:Sections [
// CHECK:    Name: mysection
// CHECK-NEXT:    Type: SHT_PROGBITS
// CHECK-NEXT:    Flags [ (0x2)
// CHECK-NEXT:      SHF_ALLOC (0x2)
// CHECK-NEXT:    ]
// CHECK-NEXT:    Address: 0x200400
// CHECK-NEXT:    Offset: 0x400
// CHECK-NEXT:    Size: 8

// CHECK:    Name: .preinit_array
// CHECK-NEXT:    Type: SHT_PREINIT_ARRAY
// CHECK-NEXT:    Flags [ (0x3)
// CHECK-NEXT:      SHF_ALLOC (0x2)
// CHECK-NEXT:      SHF_WRITE (0x1)
// CHECK-NEXT:    ]
// CHECK-NEXT:    Address: 0x220C00
// CHECK-NEXT:    Offset: 0xC00
// CHECK-NEXT:    Size: 8

// CHECK:    Name: .init_array
// CHECK-NEXT:    Type: SHT_INIT_ARRAY
// CHECK-NEXT:    Flags [ (0x3)
// CHECK-NEXT:      SHF_ALLOC (0x2)
// CHECK-NEXT:      SHF_WRITE (0x1)
// CHECK-NEXT:    ]
// CHECK-NEXT:    Address: 0x221000
// CHECK-NEXT:    Offset: 0x1000
// CHECK-NEXT:    Size: 8

// CHECK:    Name: .fini_array
// CHECK-NEXT:    Type: SHT_FINI_ARRAY
// CHECK-NEXT:    Flags [ (0x3)
// CHECK-NEXT:      SHF_ALLOC (0x2)
// CHECK-NEXT:      SHF_WRITE (0x1)
// CHECK-NEXT:    ]
// CHECK-NEXT:    Address: 0x221400
// CHECK-NEXT:    Offset: 0x1400
// CHECK-NEXT:    Size: 8


// CHECK: Relocations [
// CHECK-NEXT:   .rela.dyn {
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x221408
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x221418
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x221428
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x221438
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x221448
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x221458
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x221468
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x221478
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:   }
// CHECK-NEXT: ]

// CHECK:  Symbols [
// CHECK:    Name: __fini_array_end
// CHECK-NEXT:    Value: 0x221408
// CHECK-NEXT:    Size: 0
// CHECK-NEXT:    Binding: Local
// CHECK-NEXT:    Type: None

// CHECK:    Name: __fini_array_start
// CHECK-NEXT:    Value: 0x221400
// CHECK-NEXT:    Size: 0
// CHECK-NEXT:    Binding: Local
// CHECK-NEXT:    Type: None

// CHECK:    Name: __init_array_end
// CHECK-NEXT:    Value: 0x221008
// CHECK-NEXT:    Size: 0
// CHECK-NEXT:    Binding: Local
// CHECK-NEXT:    Type: None

// CHECK:    Name: __init_array_start
// CHECK-NEXT:    Value: 0x221000
// CHECK-NEXT:    Size: 0
// CHECK-NEXT:    Binding: Local
// CHECK-NEXT:    Type: None

// CHECK:    Name: __preinit_array_end
// CHECK-NEXT:    Value: 0x220C08
// CHECK-NEXT:    Size: 0
// CHECK-NEXT:    Binding: Local
// CHECK-NEXT:    Type: None

// CHECK:    Name: __preinit_array_start
// CHECK-NEXT:    Value: 0x220C00
// CHECK-NEXT:    Size: 0
// CHECK-NEXT:    Binding: Local
// CHECK-NEXT:    Type: None

// CHECK:    Name: __start_mysection
// CHECK-NEXT:    Value: 0x200400
// CHECK-NEXT:    Size: 0
// CHECK-NEXT:    Binding: Global
// CHECK-NEXT:    Type: None

// CHECK:    Name: __stop_mysection
// CHECK-NEXT:    Value: 0x200408
// CHECK-NEXT:    Size: 0
// CHECK-NEXT:    Binding: Global
// CHECK-NEXT:    Type: None

// CHECK:      Hex dump of section '.data.rel.ro':
/// __preinit_array_start: address: 0x220C00, size = 8, perms = RO(0x1)
// CHECK-NEXT: 0x00221408 000c2200 00000000 08000000 00000001
/// __preinit_array_end: address: 0x220C08, size = 0, perms = RO(0x1)
// CHECK-NEXT: 0x00221418 080c2200 00000000 00000000 00000001

/// __init_array_start: address: 0x221000, size = 8, perms = RO(0x1)
// CHECK-NEXT: 0x00221428 00102200 00000000 08000000 00000001
/// __init_array_end: address: 0x221008, size = 0, perms = RO(0x1)
// CHECK-NEXT: 0x00221438 08102200 00000000 00000000 00000001

/// __fini_array_start: address: 0x221400, size = 8, perms = RO(0x1)
// CHECK-NEXT: 0x00221448 00142200 00000000 08000000 00000001
/// __fini_array_end: address: 0x221408, size = 0, perms = RO(0x1)
// CHECK-NEXT: 0x00221458 08142200 00000000 00000000 00000001

/// __start_mysection: address: 0x200400, size = 8, perms = RO(0x1)
// CHECK-NEXT: 0x00221468 00042000 00000000 08000000 00000001
/// __stop_mysection: address: 0x200408, size = 0, perms = RO(0x1)
// CHECK-NEXT: 0x00221478 08042000 00000000 00000000 00000001
