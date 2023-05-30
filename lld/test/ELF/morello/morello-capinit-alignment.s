// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64 -filetype=obj %s -o %t.o
// RUN: ld.lld %t.o -o %t
// RUN: llvm-readobj --cap-relocs --expand-relocs %t | FileCheck %s

/// Check that the capabilities are appropriately aligned for CHERI
/// concentrate. Some of the capability construction instructions will fault
/// if the base and top are not appropriately aligned.
///
/// From Morello version of the CHERI concentrate specification the alignment
/// requirements are:
/// Ie = 0 (Length < 16384) there are no alignment restrictions.
/// Ie = 1 then base and top must be 2^E+3 aligned where E is the exponent.
/// The Exponent is derived from the length using the formula:
/// E = 50 - CountLeadingZeroes(length[64:15])
 .section .rodata.1, "a", %progbits
 .balign 4
 .globl small
 .type small, %object
 .size small, 1
small:
 .space 1

 .globl no_alignment
 .type no_alignment, %object
 .size no_alignment, 16383
no_alignment:
 .space 16383

 .section .rodata.2, "a", %progbits
 .global rodata2_start
rodata2_start:
 .balign 8
 .space 4
 /// start at a 4-byte aligned offset within .rodata.2
 /// 16384 requires 8-byte aligned base and limit. This is not aligned well
 /// enough for Morello; the linker will produce a legal, if imprecise,
 /// capability that is larger than needed.
 .global cap_align_8
 .type cap_align_8, %object
 .size cap_align_8, 16384
cap_align_8:
 .space 16384
 .space 4

 /// The .init_array and .fini_array are referred to via the linker defined
 /// __init_array_start and __fini_array_end symbols
 /// as the overall size of the OutputSection is linker defined
 /// the linker will need to alter the alignment and
 /// size of the section to ensure precise capabilities.
 ///
 /// In our case .init_array will be highly aligned due to being the first
 /// non .text section.
 .section .init_array, "a", %init_array
 .space 8
 /// Expect the linker to increase the alignment to 32
 .section .fini_array, "a", %fini_array
 .space 32768

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

// FIXME: the __cap_reloc at 0x230040 should be using __fini_array_start and
// not intersect with other sections. currently this capability also covers
// the entire .init_array section. This seems to be related to setting
// isCheriABI?

// CHECK: CHERI __cap_relocs [
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x230000 ($d.4)
// CHECK-NEXT:     Base: small (0x200200)
// CHECK-NEXT:     Offset: 0
// CHECK-NEXT:     Length: 1
// CHECK-NEXT:     Permissions: (RODATA) (0x1BFBE)
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x230010
// CHECK-NEXT:     Base: no_alignment (0x200201)
// CHECK-NEXT:     Offset: 0
// CHECK-NEXT:     Length: 16383
// CHECK-NEXT:     Permissions: (RODATA) (0x1BFBE)
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x230020
// CHECK-NEXT:     Base: rodata2_start (0x204200)
// CHECK-NEXT:     Offset: 4
// CHECK-NEXT:     Length: 16392
// CHECK-NEXT:     Permissions: (RODATA) (0x1BFBE)
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x230030
// CHECK-NEXT:     Base: {{.*}} (0x2001E0)
// CHECK-NEXT:     Offset: 130592
// CHECK-NEXT:     Length: 130592
// CHECK-NEXT:     Permissions: (FUNC) (0x8000000000013DBC)
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x230040
// CHECK-NEXT:     Base: _start (0x220000)
// CHECK-NEXT:     Offset: 8
// CHECK-NEXT:     Length: 32784
// CHECK-NEXT:     Permissions: (RODATA) (0x1BFBE)
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x230050
// CHECK-NEXT:     Base: __fini_array_end (0x228008)
// CHECK-NEXT:     Offset: 0
// CHECK-NEXT:     Length: 0
// CHECK-NEXT:     Permissions: (RODATA) (0x1BFBE)
// CHECK-NEXT:   }
