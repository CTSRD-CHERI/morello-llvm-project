// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64 -filetype=obj %s -o %t.o
// RUN: ld.lld -v %t.o -o %t 2>&1 --eh-frame-hdr | FileCheck --check-prefix=WARN %s
// RUN: llvm-readobj --cap-relocs --expand-relocs %t | FileCheck %s

// WARN-NOT: warning: could not determine size of cap reloc against __eh_frame_start
// WARN-NOT: warning: could not determine size of cap reloc against __eh_frame_end
// WARN-NOT: warning: could not determine size of cap reloc against __eh_frame_hdr_start
// WARN-NOT: warning: could not determine size of cap reloc against __eh_frame_hdr_end

/// Check that linker defined section start symbols get the size of the output
/// section, and stop/end symbols get a size of 0. The end symbols should also not
/// be affected by any additional padding added to make capabilities to sections
/// representable.

 .section .eh_frame, "a", %progbits
 .rept 10000
 .long 12   // Size
 .long 0x00 // ID
 .byte 0x01 // Version.

 .byte 0x52 // Augmentation string: 'R','\0'
 .byte 0x00

 .byte 0x01

 .byte 0x01 // LEB128
 .byte 0x01 // LEB128

 .byte 0x00 // DW_EH_PE_absptr

 .byte 0xFF

 .long 12  // Size
 .long 0x14 // ID
 .quad _start + 0x100
 .endr

 .text
 .balign 1024

 .globl _start
 .type _start, %function
_start: ret

 .data.rel.ro
 .chericap __eh_frame_start
 .chericap __eh_frame_end
 .chericap __eh_frame_hdr_start
 .chericap __eh_frame_hdr_end

// FIXME: capabilities to sections should be made representable through
// padding.

// CHECK: __cap_relocs {
// CHECK-NEXT: Relocation {
// CHECK-NEXT:   Offset: 0x25B080
// CHECK-NEXT:   Type: RODATA (0x1BFBE)
// CHECK-NEXT:   Address: 0x213B74
// CHECK-NEXT:   Base: 0x213B40
// CHECK-NEXT:   Length: 160128
// CHECK-NEXT: }
// CHECK-NEXT: Relocation {
// CHECK-NEXT:   Offset: 0x25B090
// CHECK-NEXT:   Type: RODATA (0x1BFBE)
// CHECK-NEXT:   Address: 0x23AC88
// CHECK-NEXT:   Base: 0x23AC88
// CHECK-NEXT:   Length: 0
// CHECK-NEXT: }
// CHECK-NEXT: Relocation {
// CHECK-NEXT:   Offset: 0x25B0A0
// CHECK-NEXT:   Type: RODATA (0x1BFBE)
// CHECK-NEXT:   Address: 0x2002E8
// CHECK-NEXT:   Base: 0x2002E0
// CHECK-NEXT:   Length: 80032
// CHECK-NEXT: }
// CHECK-NEXT: Relocation {
// CHECK-NEXT:   Offset: 0x25B0B0
// CHECK-NEXT:   Type: RODATA (0x1BFBE)
// CHECK-NEXT:   Address: 0x213B74
// CHECK-NEXT:   Base: 0x213B74
// CHECK-NEXT:   Length: 0
// CHECK-NEXT: }
