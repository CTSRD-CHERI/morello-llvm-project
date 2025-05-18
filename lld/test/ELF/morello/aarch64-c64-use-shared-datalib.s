// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64,+morello -filetype=obj %S/Inputs/shared-datalib.s -o %t1.o
// RUN: ld.lld --shared --soname=t.so %t1.o -o %t.so
// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64,+morello -filetype=obj %s -o %t2.o

// RUN: ld.lld %t.so %t2.o -o %t
// RUN: llvm-objdump --print-imm-hex --no-show-raw-insn -s -d --triple=aarch64-none-elf --mattr=+morello %t | FileCheck %s
// RUN: llvm-readobj --dynamic --relocations %t | FileCheck %s --check-prefix=RELS

// RUN: ld.lld --pie %t.so %t2.o -o %tpie
// RUN: llvm-objdump --print-imm-hex --no-show-raw-insn -s -d --triple=aarch64-none-elf --mattr=+morello %tpie | FileCheck %s --check-prefix=CHECK-PIE
// RUN: llvm-readobj --dynamic --relocations %tpie | FileCheck %s --check-prefix=RELS-PIE

/// Application using a shared data only library. Expect to see dynamic
/// relocations and not a __cap_relocs section. The link is repeated for -fpie

 .text
 .global _start
 .type _start, %function
 .size _start, 8
_start:
 ret

 .global from_app
 .type from_app, %function
 .size from_app, 4
from_app:
 ret

 .data.rel.ro
 .chericap rodata
 .chericap data
 .chericap appdata
 .chericap from_app

// CHECK: Contents of section .data.rel.ro:
/// rodata (shlib.so) rw (default) size 8
// CHECK-NEXT:  2203c0 00000000 00000000 08000000 00000002
/// data (shlib.so) rw (default) size 8
// CHECK-NEXT:  2203d0 00000000 00000000 08000000 00000002
/// appdata 0x2304d0 rw size 8
// CHECK-NEXT:  2203e0 d0042300 00000000 08000000 00000002
/// from_app 21032c exec size 4
// CHECK-NEXT:  2203f0 40022000 00000000 80010100 00000004

// CHECK-PIE: Contents of section .data.rel.ro:
/// rodata (shlib.so) rw (default) size 8
// CHECK-PIE-NEXT:  203c0 00000000 00000000 08000000 00000002
/// data (shlib.so) rw (default) size 8
// CHECK-PIE-NEXT:  203d0 00000000 00000000 08000000 00000002
/// appdata 0x304e0 rw size 8
// CHECK-PIE-NEXT:  203e0 e0040300 00000000 08000000 00000002
/// from_app 1032c exec size 4
// CHECK-PIE-NEXT:  203f0 40020000 00000000 80010100 00000004

 .data
 .global appdata
 .type appdata, %object
 .size appdata, 8
appdata: .xword 8

// CHECK: Contents of section .data:
// CHECK-NEXT:  2304d0 08000000 00000000

// CHECK-PIE: Contents of section .data:
// CHECK-PIE-NEXT:  304e0 08000000 00000000

// CHECK-LABEL: <_start>:
// CHECK-NEXT:   2103b0:        ret

// CHECK-LABEL: <from_app>:
// CHECK-NEXT:   2103b4:        ret

// CHECK-PIE-LABEL: <_start>:
// CHECK-PIE-NEXT:    103b0:            ret

// CHECK-PIE-LABEL: <from_app>:
// CHECK-PIE-NEXT:    103b4:            ret

/// Check that the dynamic table holds the correct number of RELATIVE relocs
// RELS: DynamicSection [
// RELS: 0x000000006FFFFFF9 RELACOUNT 2

// RELS: Relocations [
// RELS-NEXT:   Section {{.*}} .rela.dyn {
/// .chericap appdata
// RELS-NEXT:     0x2203E0 R_MORELLO_RELATIVE - 0x0
/// .chericap from_app
// RELS-NEXT:     0x2203F0 R_MORELLO_RELATIVE - 0x10175
/// .chericap rodata
// RELS-NEXT:     0x2203C0 R_MORELLO_CAPINIT rodata 0x0
/// .chericap data
// RELS-NEXT:     0x2203D0 R_MORELLO_CAPINIT data 0x0
// RELS-NEXT:   }

/// Check that the dynamic table holds the correct number of RELATIVE relocs
// RELS-PIE: DynamicSection [
// RELS-PIE: 0x000000006FFFFFF9 RELACOUNT 2

// RELS-PIE: Relocations [
// RELS-PIE-NEXT:   Section {{.*}} .rela.dyn {
/// .chericap appdata
// RELS-PIE-NEXT:     0x203E0 R_MORELLO_RELATIVE - 0x0
/// .chericap from_app
// RELS-PIE-NEXT:     0x203F0 R_MORELLO_RELATIVE - 0x10175
/// .chericap rodata
// RELS-PIE-NEXT:     0x203C0 R_MORELLO_CAPINIT rodata 0x0
/// .chericap data
// RELS-PIE-NEXT:     0x203D0 R_MORELLO_CAPINIT data 0x0
// RELS-PIE-NEXT:   }
