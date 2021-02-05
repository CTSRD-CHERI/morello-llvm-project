// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64,+morello -filetype=obj %s -o %t.o
// RUN: ld.lld --morello-static-caps=elf %t.o -o %t
// RUN: llvm-readobj --section-headers --relocs --expand-relocs --symbols -x .data %t | FileCheck %s

/// Basics of the .capinit relocation using static linking.
/// We create two capabilites via .capinit. These will produce R_MORELLO_CAPINIT
/// Relocations that the linker will propogate to the "rela.dyn" section.
/// Although the symbol size is not specified in the source, the linker will
/// use until the end of the section to calculate the symbol size.
/// We also check that the linker creates the __cap_dynrelocs_start and
/// __cap_dynrelocs_end symbols that a C-library can use to initialise the
/// capabilities with.

 .data
 .balign 16
 .type ptr1, %object
 .size ptr1, 16
ptr1:
 .capinit str + 8
 .8byte 0
 .8byte 12

 .type ptr2, %object
 .size ptr2, 16
ptr2:
 .capinit str
 .8byte 0
 .8byte 12

str:
 .string "Hello World"

 .globl __cap_dynrelocs_start
 .globl __cap_dynrelocs_end
 .xword __cap_dynrelocs_start
 .xword __cap_dynrelocs_end


/// .rel.dyn section
// CHECK:        Name: .rela.dyn
// CHECK-NEXT:   Type: SHT_RELA
// CHECK-NEXT:   Flags [
// CHECK-NEXT:     SHF_ALLOC
// CHECK-NEXT:   ]
// CHECK-NEXT:   Address: 0x200158
// CHECK-NEXT:   Offset: 0x158
// CHECK-NEXT:   Size: 48
// CHECK-NEXT:   Link: 0
// CHECK-NEXT:   Info: 0
// CHECK-NEXT:   AddressAlignment: 8
// CHECK-NEXT:   EntrySize: 24
// CHECK-NEXT: }

// CHECK: Relocations [
// CHECK-NEXT:   .rela.dyn {

/// str + 8
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x220190
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x2201B8
// CHECK-NEXT:     }

/// str
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x2201A0
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x2201B0
// CHECK-NEXT:     }
// CHECK-NEXT:   }
// CHECK-NEXT: ]

// CHECK:       Symbol {
// CHECK:         Name: ptr1
// CHECK-NEXT:    Value: 0x220190
// CHECK-NEXT:    Size: 16
// CHECK-NEXT:    Binding: Local
// CHECK-NEXT:    Type: Object
// CHECK-NEXT:    Other: 0
// CHECK-NEXT:    Section: .data
// CHECK-NEXT:  }
// CHECK-NEXT:  Symbol {
// CHECK-NEXT:    Name: ptr2
// CHECK-NEXT:    Value: 0x2201A0
// CHECK-NEXT:    Size: 16
// CHECK-NEXT:    Binding: Local
// CHECK-NEXT:    Type: Object
// CHECK-NEXT:    Other: 0
// CHECK-NEXT:    Section: .data
// CHECK-NEXT:  }
// CHECK-NEXT:  Symbol {
// CHECK-NEXT:    Name: str
// CHECK-NEXT:    Value: 0x2201B0
// CHECK-NEXT:    Size: 0
// CHECK-NEXT:    Binding: Local
// CHECK-NEXT:    Type: None
// CHECK-NEXT:    Other: 0
// CHECK-NEXT:    Section: .data
// CHECK-NEXT:  }

/// __cap_dynrelocs_end = __cap_dynrelocs_start + .rela.dyn size
///                     = 0x200158 + 48
///                     = 0x200188
// CHECK-NEXT:   Symbol {
// CHECK-NEXT:     Name: __cap_dynrelocs_end
// CHECK-NEXT:     Value: 0x200188
// CHECK-NEXT:     Size: 0
// CHECK-NEXT:     Binding: Local
// CHECK-NEXT:     Type: None
// CHECK-NEXT:     Other [
// CHECK-NEXT:       STV_HIDDEN
// CHECK-NEXT:     ]
// CHECK-NEXT:     Section: .rela.dyn
// CHECK-NEXT:   }
// CHECK-NEXT:   Symbol {
// CHECK-NEXT:     Name: __cap_dynrelocs_start
// CHECK-NEXT:     Value: 0x200158
// CHECK-NEXT:     Size: 0
// CHECK-NEXT:     Binding: Local
// CHECK-NEXT:     Type: None
// CHECK-NEXT:     Other [
// CHECK-NEXT:       STV_HIDDEN
// CHECK-NEXT:     ]
// CHECK-NEXT:     Section: .rela.dyn

/// Check the fragments in .data match
// CHECK:      Hex dump of section '.data':

/// ptr1: address: 0x2201B0, size = 12 (0xC), perms = RW(0x2)
// CHECK-NEXT: 0x00220190 b0012200 00000000 0c000000 00000002

/// ptr2: address: 0x2201B0, size = 12 (0xC), perms = RW(0x2)
// CHECK-NEXT: 0x002201a0 b0012200 00000000 0c000000 00000002

/// bar: address: 0x200248, size = 8 (0x8), perms = RO(0x1)
// CHECK-NEXT: 0x002201b0 48656c6c 6f20576f 726c6400 {{.*}}   Hello World
