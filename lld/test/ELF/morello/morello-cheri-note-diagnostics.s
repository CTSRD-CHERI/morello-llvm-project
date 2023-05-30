// REQUIRES: aarch64
// RUN: rm -rf %t && split-file %s %t && cd %t

// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64 -filetype=obj invalid-header.s -o invalid-header.o
// RUN: not ld.lld invalid-header.o -o invalid-header 2>&1 | FileCheck %s --check-prefix=INVALID_HEADER
// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64 -filetype=obj invalid-data.s -o invalid-data.o
// RUN: not ld.lld invalid-data.o -o invalid-data 2>&1 | FileCheck %s --check-prefix=INVALID_DATA
// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64 -filetype=obj invalid-desc.s -o invalid-desc.o
// RUN: not ld.lld invalid-desc.o -o invalid-desc 2>&1 | FileCheck %s --check-prefix=INVALID_DESC
// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64 -filetype=obj invalid-globals-abi.s -o invalid-globals-abi.o
// RUN: not ld.lld invalid-globals-abi.o -o invalid-globals-abi 2>&1 | FileCheck %s --check-prefix=INVALID_GLOBALS_ABI
// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64 -filetype=obj invalid-tls-abi.s -o invalid-tls-abi.o
// RUN: not ld.lld invalid-tls-abi.o -o invalid-tls-abi 2>&1 | FileCheck %s --check-prefix=INVALID_TLS_ABI
// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64 -filetype=obj conflicting-globals-abi.s -o conflicting-globals-abi.o
// RUN: not ld.lld conflicting-globals-abi.o -o conflicting-globals-abi 2>&1 | FileCheck %s --check-prefix=CONFLICTING_GLOBALS_ABI

// INVALID_HEADER: header size too short: 0x8
// INVALID_DATA: data size too short. Expected: 0x18 Actual: 0xc
// INVALID_DESC: invalid desc size: 0x3
// INVALID_GLOBALS_ABI: error: {{.*}} invalid NT_CHERI_GLOBALS_ABI variant: 0x3
// INVALID_TLS_ABI: error: {{.*}} invalid NT_CHERI_TLS_ABI variant: 0x1
// CONFLICTING_GLOBALS_ABI: error: {{.*}} conflicting NT_CHERI_GLOBALS_ABI variants

//--- invalid-header.s
.section .test.note.cheri, "a", @note
.long 6
.long 4

//--- invalid-data.s
.section .test.note.cheri, "a", @note
.long 6
.long 4
/// NT_CHERI_GLOBALS_ABI = 0
.long 0

//--- invalid-desc.s
.section .test.note.cheri, "a", @note
.long 6
.long 3
.long 0
.asciz "CHERI"
.align 2
.long 0

//--- invalid-globals-abi.s
.section .test.note.cheri, "a", @note
.long 6
.long 4
/// NT_CHERI_GLOBALS_ABI = 0
.long 0
.asciz "CHERI"
.align 2
/// out of range NT_CHERI_GLOBALS_ABI variant = 3
.long 3

//--- invalid-tls-abi.s
.section .test.note.cheri, "a", @note
.long 6
.long 4
/// NT_CHERI_TLS_ABI = 1
.long 1
.asciz "CHERI"
.align 2
/// out of range NT_CHERI_TLS_ABI variant = 1
.long 1

//--- conflicting-globals-abi.s
.section .test.note.cheri, "a", @note
.long 6
.long 4
/// NT_CHERI_GLOBALS_ABI = 0
.long 0
.asciz "CHERI"
.align 2
/// NT_CHERI_GLOBALS_ABI variant = 0
.long 0
.long 6
.long 4
/// NT_CHERI_GLOBALS_ABI = 0
.long 0
.asciz "CHERI"
.align 2
/// NT_CHERI_GLOBALS_ABI variant = 2
.long 2
