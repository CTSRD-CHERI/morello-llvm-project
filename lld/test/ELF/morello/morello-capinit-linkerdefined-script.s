// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64 -filetype=obj %s -o %t.o
// RUN: echo "SECTIONS { \
// RUN:       .text 0x210000: { *(.text) } \
// RUN:       mysection : { \
// RUN:          PROVIDE_HIDDEN(__start_mysection = .); \
// RUN:          *(mysection); \
// RUN:          PROVIDE_HIDDEN(__stop_mysection = .); \
// RUN:       } \
// RUN:       .preinit_array : { \
// RUN:          PROVIDE_HIDDEN(__preinit_array_start = .); \
// RUN:          *(.preinit_array); \
// RUN:          PROVIDE_HIDDEN(__preinit_array_end = .); \
// RUN:       } \
// RUN:       .init_array : { \
// RUN:          PROVIDE_HIDDEN(__init_array_start = .); \
// RUN:          *(.init_array); \
// RUN:          PROVIDE_HIDDEN(__init_array_end = .); \
// RUN:       } \
// RUN:       .fini_array : { \
// RUN:          PROVIDE_HIDDEN(__fini_array_start = .); \
// RUN:          *(.fini_array); \
// RUN:          PROVIDE_HIDDEN(__fini_array_end = .); \
// RUN:       } \
// RUN:       .data.rel.ro : { \
// RUN:          *(.data.rel.ro); \
// RUN:       } \
// RUN:       __cap_relocs : { \
// RUN:          *(__cap_relocs); \
// RUN:       } \
// RUN:       } " > %t.script

// RUN: ld.lld --verbose %t.o -o %t --script %t.script 2>&1 | FileCheck %s --check-prefix=LOG
// LOG: lld: Treating __start_mysection as a section start symbol
// LOG: lld: Treating __preinit_array_start as a section start symbol
// LOG: lld: Treating __init_array_start as a section start symbol
// LOG: lld: Treating __fini_array_start as a section start symbol
// RUN: llvm-readelf --cap-relocs --expand-relocs --symbols %t
// RUN: llvm-readelf --cap-relocs --expand-relocs --symbols %t | FileCheck %s

/// Using a linker script. Check that linker defined section start symbols
/// get the size of the output section, and stop/end symbols get a size of 0.

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

// CHECK:      [[#%.16x,PREINIT_START:]]  0 NOTYPE  LOCAL  HIDDEN      [[#]] __preinit_array_start
// CHECK-NEXT: [[#%.16x,PREINIT_START+8]] 0 NOTYPE  LOCAL  HIDDEN      [[#]] __preinit_array_end
// CHECK-NEXT: [[#%.16x,INIT_START:]]     0 NOTYPE  LOCAL  HIDDEN      [[#]] __init_array_start
// CHECK-NEXT: [[#%.16x,INIT_START+8]]    0 NOTYPE  LOCAL  HIDDEN      [[#]] __init_array_end
// CHECK-NEXT: [[#%.16x,FINI_START:]]     0 NOTYPE  LOCAL  HIDDEN      [[#]] __fini_array_start
// CHECK-NEXT: [[#%.16x,FINI_START+8]]    0 NOTYPE  LOCAL  HIDDEN      [[#]] __fini_array_end
// CHECK-NEXT: [[#%.16x,MY_START:]]       0 NOTYPE  LOCAL  HIDDEN      [[#]] __start_mysection
// CHECK-NEXT: [[#%.16x,MY_START+8]]      0 NOTYPE  LOCAL  HIDDEN      [[#]] __stop_mysection
// CHECK:      CHERI capability relocation section '__cap_relocs' at offset {{.+}} contains 8 entries:
// CHECK-NEXT:     Offset             Info         Type        Value
// CHECK-NEXT: 0000000000211010  000000000001bfbe RODATA  [[#PREINIT_START]] {{\[}}[[#PREINIT_START]]-[[#PREINIT_START+8]]]
// CHECK-NEXT: 0000000000211020  000000000001bfbe RODATA  [[#PREINIT_START+8]] {{\[}}[[#PREINIT_START+8]]-[[#PREINIT_START+8]]]
// CHECK-NEXT: 0000000000211030  000000000001bfbe RODATA  [[#INIT_START]] {{\[}}[[#INIT_START]]-[[#INIT_START+8]]]
// CHECK-NEXT: 0000000000211040  000000000001bfbe RODATA  [[#INIT_START+8]] {{\[}}[[#INIT_START+8]]-[[#INIT_START+8]]]
// CHECK-NEXT: 0000000000211050  000000000001bfbe RODATA  [[#FINI_START]] {{\[}}[[#FINI_START]]-[[#FINI_START+8]]]
// CHECK-NEXT: 0000000000211060  000000000001bfbe RODATA  [[#FINI_START+8]] {{\[}}[[#FINI_START+8]]-[[#FINI_START+8]]]
// CHECK-NEXT: 0000000000211070  000000000001bfbe RODATA  [[#MY_START]] {{\[}}[[#MY_START]]-[[#MY_START+8]]]
// CHECK-NEXT: 0000000000211080  000000000001bfbe RODATA  [[#MY_START+8]] {{\[}}[[#MY_START+8]]-[[#MY_START+8]]]
