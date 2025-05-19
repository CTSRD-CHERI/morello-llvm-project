// REQUIRES: aarch64
// RUN: rm -rf %t && split-file %s %t && cd %t

/// Cheri specific flags are not passed to avoid valid .note.cheri sections created by llvm-mc
/// interfering with the hand-crafted invalid .note.cheri sections.
// RUN: llvm-mc --triple=aarch64-none-elf -filetype=obj invalid-header.s -o invalid-header.o
// RUN: not ld.lld invalid-header.o -o invalid-header 2>&1 | FileCheck %s --check-prefix=INVALID-HEADER
// RUN: llvm-mc --triple=aarch64-none-elf -filetype=obj invalid-data.s -o invalid-data.o
// RUN: not ld.lld invalid-data.o -o invalid-data 2>&1 | FileCheck %s --check-prefix=INVALID-DATA
// RUN: llvm-mc --triple=aarch64-none-elf -filetype=obj invalid-desc.s -o invalid-desc.o
// RUN: not ld.lld invalid-desc.o -o invalid-desc 2>&1 | FileCheck %s --check-prefix=INVALID-DESC
// RUN: llvm-mc --triple=aarch64-none-elf -filetype=obj invalid-name.s -o invalid-name.o
// RUN: not ld.lld invalid-name.o -o invalid-name 2>&1 | FileCheck %s --check-prefix=INVALID-NAME
// RUN: llvm-mc --triple=aarch64-none-elf -filetype=obj unknown-abi.s -o unknown-abi.o
// RUN: not ld.lld unknown-abi.o -o unknown-abi 2>&1 | FileCheck %s --check-prefix=UNKNOWN-ABI
// RUN: llvm-mc --triple=aarch64-none-elf -filetype=obj unknown-globals-abi.s -o unknown-globals-abi.o
// RUN: not ld.lld unknown-globals-abi.o -o unknown-globals-abi 2>&1 | FileCheck %s --check-prefix=UNKNOWN-GLOBALS-ABI
// RUN: llvm-mc --triple=aarch64-none-elf -filetype=obj unknown-tls-abi.s -o unknown-tls-abi.o
// RUN: not ld.lld unknown-tls-abi.o -o unknown-tls-abi 2>&1 | FileCheck %s --check-prefix=UNKNOWN-TLS-ABI
// RUN: llvm-mc --triple=aarch64-none-elf -filetype=obj mismatched-globals-abi-pcrel-plt-fptr.s -o mismatched-globals-abi-pcrel-plt-fptr.o
// RUN: not ld.lld mismatched-globals-abi-pcrel-plt-fptr.o -o mismatched-globals-abi-pcrel-plt-fptr 2>&1 | FileCheck %s --check-prefix=MISMATCHED-GLOBALS-ABI-PLT-FPTR
// RUN: llvm-mc --triple=aarch64-none-elf -filetype=obj mismatched-globals-abi-pcrel-fdesc.s -o mismatched-globals-abi-pcrel-fdesc.o
// RUN: not ld.lld mismatched-globals-abi-pcrel-fdesc.o -o mismatched-globals-abi-pcrel-fdesc 2>&1 | FileCheck %s --check-prefix=MISMATCHED-GLOBALS-ABI-FDESC

// INVALID-HEADER: header size too short: 0x8
// INVALID-DATA: data size too short. Expected: 0x16 Actual: 0xc
// INVALID-DESC: invalid desc size: 0x3
// INVALID-NAME: unexpected name CHERY
// UNKNOWN-ABI: error: {{.*}} unknown type: 0xff
// UNKNOWN-GLOBALS-ABI: error: {{.*}} unknown NT_CHERI_GLOBALS_ABI variant: 0x3
// UNKNOWN-TLS-ABI: error: {{.*}} unknown NT_CHERI_TLS_ABI variant: 0x2
// MISMATCHED-GLOBALS-ABI-PLT-FPTR: error: {{.*}} NT_CHERI_GLOBALS_ABI variant mismatch: CHERI_GLOBALS_ABI_PCREL vs CHERI_GLOBALS_ABI_PLT_FPTR
// MISMATCHED-GLOBALS-ABI-FDESC: error: {{.*}} NT_CHERI_GLOBALS_ABI variant mismatch: CHERI_GLOBALS_ABI_PCREL vs CHERI_GLOBALS_ABI_FDESC

//--- invalid-header.s
.section .note.cheri, "a", @note
.long 6
.long 4

//--- invalid-data.s
.section .note.cheri, "a", @note
.long 6
.long 4
/// NT_CHERI_GLOBALS_ABI (0)
.long 0

//--- invalid-desc.s
.section .note.cheri, "a", @note
.long 6
.long 3
.long 0
.asciz "CHERI"
.align 2
.long 0

//--- invalid-name.s
.section .note.cheri, "a", @note
.long 6
.long 4
/// NT_CHERI_GLOBALS_ABI (0)
.long 0
.asciz "CHERY"
.align 2
.long 0

//--- unknown-abi.s
.section .note.cheri, "a", @note
.long 6
.long 4
/// unknown ABI (0xFF)
.long 0xFF
.asciz "CHERI"
.align 2
.long 0

//--- unknown-globals-abi.s
.section .note.cheri, "a", @note
.long 6
.long 4
/// NT_CHERI_GLOBALS_ABI (0)
.long 0
.asciz "CHERI"
.align 2
/// out of range NT_CHERI_GLOBALS_ABI variant (3)
.long 3

//--- unknown-tls-abi.s
.section .note.cheri, "a", @note
.long 6
.long 4
/// NT_CHERI_TLS_ABI (1)
.long 1
.asciz "CHERI"
.align 2
/// out of range NT_CHERI_TLS_ABI variant (2)
.long 2

//--- mismatched-globals-abi-pcrel-plt-fptr.s
.section .note.cheri, "a", @note
.long 6
.long 4
/// NT_CHERI_GLOBALS_ABI (0)
.long 0
.asciz "CHERI"
.align 2
/// NT_CHERI_GLOBALS_ABI variant CHERI_GLOBALS_ABI_PCREL (0)
.long 0

.long 6
.long 4
/// NT_CHERI_GLOBALS_ABI (0)
.long 0
.asciz "CHERI"
.align 2
/// NT_CHERI_GLOBALS_ABI variant CHERI_GLOBALS_ABI_PLT_FPTR (1)
.long 1

//--- mismatched-globals-abi-pcrel-fdesc.s
.section .note.cheri, "a", @note
.long 6
.long 4
/// NT_CHERI_GLOBALS_ABI (0)
.long 0
.asciz "CHERI"
.align 2
/// NT_CHERI_GLOBALS_ABI variant CHERI_GLOBALS_ABI_PCREL (0)
.long 0

.long 6
.long 4
/// NT_CHERI_GLOBALS_ABI (0)
.long 0
.asciz "CHERI"
.align 2
/// NT_CHERI_GLOBALS_ABI variant CHERI_GLOBALS_ABI_FDESC (2)
.long 2
