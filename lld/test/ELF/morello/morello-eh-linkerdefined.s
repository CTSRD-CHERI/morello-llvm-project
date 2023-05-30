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
 .capinit __eh_frame_start
 .xword 0
 .xword 0
 .capinit __eh_frame_end
 .xword 0
 .xword 0
 .capinit __eh_frame_hdr_start
 .xword 0
 .xword 0
 .capinit __eh_frame_hdr_end
 .xword 0
 .xword 0

// FIXME: capabilities to sections should be made representable through
// padding.

// CHECK: CHERI __cap_relocs [
// CHECK-NEXT: Relocation {
// CHECK-NEXT:   Location: 0x25AC80 ($d.2)
// CHECK-NEXT:   Base: <unknown symbol> (0x213A80)
// CHECK-NEXT:   Offset: 36
// CHECK-NEXT:   Length: 160064
// CHECK-NEXT:   Permissions: (RODATA) (0x1BFBE)
// CHECK-NEXT: }
// CHECK-NEXT: Relocation {
// CHECK-NEXT:   Location: 0x25AC90
// CHECK-NEXT:   Base: __eh_frame_end (0x23ABB8)
// CHECK-NEXT:   Offset: 0
// CHECK-NEXT:   Length: 0
// CHECK-NEXT:   Permissions: (RODATA) (0x1BFBE)
// CHECK-NEXT: }
// CHECK-NEXT: Relocation {
// CHECK-NEXT:   Location: 0x25ACA0
// CHECK-NEXT:   Base: {{.*}} (0x200200)
// CHECK-NEXT:   Offset: 24
// CHECK-NEXT:   Length: 80064
// CHECK-NEXT:   Permissions: (RODATA) (0x1BFBE)
// CHECK-NEXT: }
// CHECK-NEXT: Relocation {
// CHECK-NEXT:   Location: 0x25ACB0
// CHECK-NEXT:   Base: __eh_frame_start (0x213AA4)
// CHECK-NEXT:   Offset: 0
// CHECK-NEXT:   Length: 0
// CHECK-NEXT:   Permissions: (RODATA) (0x1BFBE)
// CHECK-NEXT: }
