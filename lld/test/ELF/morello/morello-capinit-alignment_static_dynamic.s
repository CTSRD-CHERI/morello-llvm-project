// REQUIRES: aarch64
// RUN: llvm-mc -target-abi purecap --triple=aarch64-none-elf -mattr=+c64 -filetype=obj %s -o %t.o
// RUN: ld.lld --local-caprelocs=elf %t.o -o %t
// RUN: llvm-readobj --section-headers --relocs --expand-relocs --symbols -x .data.rel.ro %t | FileCheck %s

/// Check that the capabilities are appropriately aligned for CHERI
/// concentrate. Some of the capability construction instructions will fault
/// if the base and top are not appropriately aligned.
///
/// From the CHERI concentrate specification the alignment requirements are:
/// Ie = 0 (Length < 4096) there are no alignment restrictions.
/// Ie = 1 then base and top must be 2^E+3 aligned where E is the exponent.
/// The Exponent is derived from the length using the formula
/// E - CountLeadingZeroes(length[64:13])
 .section .rodata.1, "a", %progbits
 .balign 4
 .globl small
 .type small, %object
 .size small, 1
small:
 .space 1

 .globl no_alignment
 .type no_alignment, %object
 .size no_alignment, 4095
no_alignment:
 .space 4095

 .section .rodata.2, "a", %progbits
 .global rodata2_start
rodata2_start:
 .balign 8
 .space 4
 /// start at a 4-byte aligned offset within .rodata.2
 /// 4096 requires 8-byte aligned base and limit. This is not aligned well
 /// enough for CHERI concentrate, the linker will produce a legal, if imprecise
 /// capability that is larger than needed.
 .global cap_align_8
 .type cap_align_8, %object
 .size cap_align_8, 4096
cap_align_8:
 .space 4096
 .space 4

 /// The .init_array and .fini_array are referred to via the linker defined
 /// __init_array_start and __fini_array_end symbols
 /// as the overall size of the OutputSection is linker defined
 /// the linker will need to alter the alignment and
 /// size of the section to ensure precise capabilities.
 ///
 /// In our case .init_array will be highly aligned due to being the first       /// non .text section.
 .section .init_array, "a", %init_array
 .space 8
 /// Expect the linker to increase the alignment to 32
 .section .fini_array, "a", %fini_array
 .space 8192

 /// The capability covering the .text and .rodata has a size
 /// determined at link time and is highly likely to be over 4KiB
 /// for large applications the linker may need to alter the alignment
 /// and size of the section to ensure precise capabilities.
 .text
 .balign 65536
 .globl _start
 .type _start, %function
 .size _start, 4
_start:

 .data.rel.ro
 .balign 65536
 .capinit small
 .xword 0
 .xword 0

 .capinit no_alignment
 .xword 0
 .xword 0

 .capinit cap_align_8
 .xword 0
 .xword 0

 .capinit _start
 .xword 0
 .xword 0

 .capinit __fini_array_start
 .xword 0
 .xword 0

 .capinit __fini_array_end
 .xword 0
 .xword 0

// CHECK:   Name: .fini_array
// CHECK-NEXT:   Type: SHT_FINI_ARRAY
// CHECK-NEXT:   Flags [
// CHECK-NEXT:     SHF_ALLOC
// CHECK-NEXT:     SHF_WRITE
// CHECK-NEXT:   ]
// CHECK-NEXT:   Address: 0x220008
// CHECK-NEXT:   Offset: 0x10008
// CHECK-NEXT:   Size: 8192
// CHECK-NEXT:   Link: 0
// CHECK-NEXT:   Info: 0
// CHECK-NEXT:   AddressAlignment: 1
// CHECK-NEXT:   EntrySize: 0
// CHECK-NEXT: }

// CHECK: .rela.dyn {
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Offset: 0x230000
// CHECK-NEXT:     Type: R_MORELLO_RELATIVE
// CHECK-NEXT:     Symbol: - (0)
// CHECK-NEXT:     Addend: 0x0
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Offset: 0x230010
// CHECK-NEXT:     Type: R_MORELLO_RELATIVE
// CHECK-NEXT:     Symbol: - (0)
// CHECK-NEXT:     Addend: 0x0
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Offset: 0x230020
// CHECK-NEXT:     Type: R_MORELLO_RELATIVE
// CHECK-NEXT:     Symbol: - (0)
// CHECK-NEXT:     Addend: 0x0
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Offset: 0x230030
// CHECK-NEXT:     Type: R_MORELLO_RELATIVE
// CHECK-NEXT:     Symbol: - (0)
// CHECK-NEXT:     Addend: 0x1FE20
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Offset: 0x230040
// CHECK-NEXT:     Type: R_MORELLO_RELATIVE
// CHECK-NEXT:     Symbol: - (0)
// CHECK-NEXT:     Addend: 0x0
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Offset: 0x230050
// CHECK-NEXT:     Type: R_MORELLO_RELATIVE
// CHECK-NEXT:     Symbol: - (0)
// CHECK-NEXT:     Addend: 0x0
// CHECK-NEXT:   }

// CHECK:        Symbol {
// CHECK:          Name: __fini_array_start
// CHECK-NEXT:     Value: 0x220008
// CHECK-NEXT:     Size: 8192
// CHECK-NEXT:     Binding: Local
// CHECK-NEXT:     Type: None
// CHECK-NEXT:     Other [
// CHECK-NEXT:       STV_HIDDEN
// CHECK-NEXT:     ]
// CHECK-NEXT:     Section: .fini_array
// CHECK-NEXT:   }
// CHECK-NEXT:   Symbol {
// CHECK-NEXT:     Name: __fini_array_end
// CHECK-NEXT:     Value: 0x222008
// CHECK-NEXT:     Size: 0
// CHECK-NEXT:     Binding: Local
// CHECK-NEXT:     Type: None
// CHECK-NEXT:     Other [
// CHECK-NEXT:       STV_HIDDEN
// CHECK-NEXT:     ]
// CHECK-NEXT:     Section: .fini_array
// CHECK-NEXT:   }
// CHECK-NEXT:   Symbol {
// CHECK-NEXT:     Name: small
// CHECK-NEXT:     Value: 0x200290
// CHECK-NEXT:     Size: 1
// CHECK-NEXT:     Binding: Global
// CHECK-NEXT:     Type: Object
// CHECK-NEXT:     Other: 0
// CHECK-NEXT:     Section: .rodata
// CHECK-NEXT:   }
// CHECK-NEXT:   Symbol {
// CHECK-NEXT:     Name: no_alignment
// CHECK-NEXT:     Value: 0x200291
// CHECK-NEXT:     Size: 4095
// CHECK-NEXT:     Binding: Global
// CHECK-NEXT:     Type: Object
// CHECK-NEXT:     Other: 0
// CHECK-NEXT:     Section: .rodata
// CHECK-NEXT:   }
// CHECK-NEXT:   Symbol {
// CHECK-NEXT:     Name: rodata2_start
// CHECK-NEXT:     Value: 0x201290
// CHECK-NEXT:     Size: 0
// CHECK-NEXT:     Binding: Global
// CHECK-NEXT:     Type: None
// CHECK-NEXT:     Other: 0
// CHECK-NEXT:     Section: .rodata
// CHECK-NEXT:   }
// CHECK-NEXT:   Symbol {
// CHECK-NEXT:     Name: cap_align_8
// CHECK-NEXT:     Value: 0x201294
// CHECK-NEXT:     Size: 4096
// CHECK-NEXT:     Binding: Global
// CHECK-NEXT:     Type: Object
// CHECK-NEXT:     Other: 0
// CHECK-NEXT:     Section: .rodata
// CHECK-NEXT:   }
// CHECK-NEXT:   Symbol {
// CHECK-NEXT:     Name: _start
// CHECK-NEXT:     Value: 0x220000
// CHECK-NEXT:     Size: 4
// CHECK-NEXT:     Binding: Global
// CHECK-NEXT:     Type: Function
// CHECK-NEXT:     Other: 0
// CHECK-NEXT:     Section: .text
// CHECK-NEXT:   }



// CHECK: Hex dump of section '.data.rel.ro'
/// small: address: 0x200290, size = 1 (0x1), perms = RO(0x1)
// CHECK-NEXT: 0x00230000 90022000 00000000 01000000 00000001

/// no_alignment: address: 0x200291, size = 4095 (0xfff), perms = RO(0x1)
// CHECK-NEXT: 0x00230010 91022000 00000000 ff0f0000 00000001

/// cap_align_8: address: 0x201294, size = 4096 (0x1000), perms = RO(0x1)
// CHECK-NEXT: 0x00230020 94122000 00000000 00100000 00000001

/// _start: address: 0x220000, size = 4 (0x4), perms = EXEC(0x4)
// CHECK-NEXT: 0x00230030 e0012000 00000000 20fe0100 00000004

/// __fini_array_start: address: 0x220008, size = 8192 (0x2000), perms = RO(0x1)
// CHECK-NEXT: 0x00230040 08002200 00000000 00200000 00000001

/// __fini_array_end: address: 0x222008, size = 0 (0x0), perms = RO(0x1)
// CHECK-NEXT: 0x00230050 08202200 00000000 00000000 00000001
