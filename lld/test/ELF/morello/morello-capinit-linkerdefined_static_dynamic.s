// REQUIRES: aarch64
// RUN: llvm-mc -target-abi purecap --triple=aarch64-none-elf -mattr=+c64 -filetype=obj %s -o %t.o
// RUN: ld.lld --local-caprelocs=elf -fatal-warnings -v %t.o -o %t
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

 .chericap __preinit_array_start
 .chericap __preinit_array_end

 .chericap __init_array_start
 .chericap __init_array_end

 .chericap __fini_array_start
 .chericap __fini_array_end

 .chericap __start_mysection

 .chericap __stop_mysection


// CHECK:Sections [
// CHECK:    Name: mysection
// CHECK-NEXT:    Type: SHT_PROGBITS
// CHECK-NEXT:    Flags [
// CHECK-NEXT:      SHF_ALLOC
// CHECK-NEXT:    ]
// CHECK-NEXT:    Address: 0x200400
// CHECK-NEXT:    Offset: 0x400
// CHECK-NEXT:    Size: 8

// CHECK:    Name: .preinit_array
// CHECK-NEXT:    Type: SHT_PREINIT_ARRAY
// CHECK-NEXT:    Flags [
// CHECK-NEXT:      SHF_ALLOC
// CHECK-NEXT:      SHF_WRITE
// CHECK-NEXT:    ]
// CHECK-NEXT:    Address: 0x220C00
// CHECK-NEXT:    Offset: 0xC00
// CHECK-NEXT:    Size: 8

// CHECK:    Name: .init_array
// CHECK-NEXT:    Type: SHT_INIT_ARRAY
// CHECK-NEXT:    Flags [
// CHECK-NEXT:      SHF_ALLOC
// CHECK-NEXT:      SHF_WRITE
// CHECK-NEXT:    ]
// CHECK-NEXT:    Address: 0x221000
// CHECK-NEXT:    Offset: 0x1000
// CHECK-NEXT:    Size: 8

// CHECK:    Name: .fini_array
// CHECK-NEXT:    Type: SHT_FINI_ARRAY
// CHECK-NEXT:    Flags [
// CHECK-NEXT:      SHF_ALLOC
// CHECK-NEXT:      SHF_WRITE
// CHECK-NEXT:    ]
// CHECK-NEXT:    Address: 0x221400
// CHECK-NEXT:    Offset: 0x1400
// CHECK-NEXT:    Size: 8


// CHECK: Relocations [
// CHECK-NEXT:   .rela.dyn {
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x220810
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x220820
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x220830
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x220840
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x220850
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x220860
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x220870
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x220880
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:   }
// CHECK-NEXT: ]

// CHECK:  Symbols [
// CHECK:    Name: __preinit_array_start
// CHECK-NEXT:    Value: 0x220C00
// CHECK-NEXT:    Size: 8
// CHECK-NEXT:    Binding: Local
// CHECK-NEXT:    Type: None
// CHECK-NEXT:    Other [
// CHECK-NEXT:      STV_HIDDEN
// CHECK-NEXT:    ]
// CHECK-NEXT:    Section: .preinit_array

// CHECK:    Name: __preinit_array_end
// CHECK-NEXT:    Value: 0x220C08
// CHECK-NEXT:    Size: 0
// CHECK-NEXT:    Binding: Local
// CHECK-NEXT:    Type: None
// CHECK-NEXT:    Other [
// CHECK-NEXT:      STV_HIDDEN
// CHECK-NEXT:    ]
// CHECK-NEXT:    Section: .preinit_array

// CHECK:    Name: __init_array_start
// CHECK-NEXT:    Value: 0x221000
// CHECK-NEXT:    Size: 8
// CHECK-NEXT:    Binding: Local
// CHECK-NEXT:    Type: None
// CHECK-NEXT:    Other [
// CHECK-NEXT:      STV_HIDDEN
// CHECK-NEXT:    ]
// CHECK-NEXT:    Section: .init_array

// CHECK:    Name: __init_array_end
// CHECK-NEXT:    Value: 0x221008
// CHECK-NEXT:    Size: 0
// CHECK-NEXT:    Binding: Local
// CHECK-NEXT:    Type: None
// CHECK-NEXT:    Other [
// CHECK-NEXT:      STV_HIDDEN
// CHECK-NEXT:    ]
// CHECK-NEXT:    Section: .init_array

// CHECK:    Name: __fini_array_start
// CHECK-NEXT:    Value: 0x221400
// CHECK-NEXT:    Size: 8
// CHECK-NEXT:    Binding: Local
// CHECK-NEXT:    Type: None
// CHECK-NEXT:    Other [
// CHECK-NEXT:      STV_HIDDEN
// CHECK-NEXT:    ]
// CHECK-NEXT:    Section: .fini_array

// CHECK:    Name: __fini_array_end
// CHECK-NEXT:    Value: 0x221408
// CHECK-NEXT:    Size: 0
// CHECK-NEXT:    Binding: Local
// CHECK-NEXT:    Type: None
// CHECK-NEXT:    Other [
// CHECK-NEXT:      STV_HIDDEN
// CHECK-NEXT:    ]
// CHECK-NEXT:    Section: .fini_array

// CHECK:    Name: __start_mysection
// CHECK-NEXT:    Value: 0x200400
// CHECK-NEXT:    Size: 8
// CHECK-NEXT:    Binding: Global
// CHECK-NEXT:    Type: None
// CHECK-NEXT:    Other [
// CHECK-NEXT:      STV_PROTECTED
// CHECK-NEXT:    ]
// CHECK-NEXT:    Section: mysection

// CHECK:    Name: __stop_mysection
// CHECK-NEXT:    Value: 0x200408
// CHECK-NEXT:    Size: 0
// CHECK-NEXT:    Binding: Global
// CHECK-NEXT:    Type: None
// CHECK-NEXT:    Other [
// CHECK-NEXT:      STV_PROTECTED
// CHECK-NEXT:    ]
// CHECK-NEXT:    Section: mysection

// CHECK:      Hex dump of section '.data.rel.ro':
/// __preinit_array_start: address: 0x220C00, size = 8, perms = RO(0x1)
// CHECK-NEXT: 0x00220810 000c2200 00000000 08000000 00000001
/// __preinit_array_end: address: 0x220C08, size = 0, perms = RO(0x1)
// CHECK-NEXT: 0x00220820 080c2200 00000000 00000000 00000001

/// __init_array_start: address: 0x221000, size = 8, perms = RO(0x1)
// CHECK-NEXT: 0x00220830 00102200 00000000 08000000 00000001
/// __init_array_end: address: 0x221008, size = 0, perms = RO(0x1)
// CHECK-NEXT: 0x00220840 08102200 00000000 00000000 00000001

/// __fini_array_start: address: 0x221400, size = 8, perms = RO(0x1)
// CHECK-NEXT: 0x00220850 00142200 00000000 08000000 00000001
/// __fini_array_end: address: 0x221408, size = 0, perms = RO(0x1)
// CHECK-NEXT: 0x00220860 08142200 00000000 00000000 00000001

/// __start_mysection: address: 0x200400, size = 8, perms = RO(0x1)
// CHECK-NEXT: 0x00220870 00042000 00000000 08000000 00000001
/// __stop_mysection: address: 0x200408, size = 0, perms = RO(0x1)
// CHECK-NEXT: 0x00220880 08042000 00000000 00000000 00000001
