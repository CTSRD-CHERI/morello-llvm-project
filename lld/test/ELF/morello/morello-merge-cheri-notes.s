// REQUIRES: aarch64

// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -cheri-cap-table-abi=fn-desc -mattr=+c64 -filetype=obj %s -o %t.o
// RUN: ld.lld %t.o -o %t
// RUN: llvm-readelf --notes %t | FileCheck %s --check-prefix=NT_MERGED_NOTES

// NT_MERGED_NOTES:      Displaying notes found in: .note.cheri
// NT_MERGED_NOTES-NEXT:   Owner                Data size 	Description
// NT_MERGED_NOTES-NEXT:   CHERI                0x00000004
// NT_MERGED_NOTES-NEXT:    description data: 02 00 00 00
// NT_MERGED_NOTES-NEXT:   CHERI                0x00000004
// NT_MERGED_NOTES-NEXT:    description data: 00 00 00 00

.section .note.cheri, "a", @note

/// The Globals ABI Note
.long 6
.long 4
/// NT_CHERI_GLOBALS_ABI = 0
.long 0
.asciz "CHERI"
.align 2
/// NT_CHERI_GLOBALS_ABI variant = 2
.long 2


/// The TLS ABI Note
.long 6
.long 4
/// NT_CHERI_TLS_ABI = 1
.long 1
.asciz "CHERI"
.align 2
/// NT_CHERI_TLS_ABI variant = 0
.long 0
