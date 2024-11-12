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
/// rodata (shlib.so) undef
// CHECK-NEXT:  2203f0 00000000 00000000 00000000 00000000
/// data (shlib.so) undef
// CHECK-NEXT:  220400 00000000 00000000 00000000 00000000
/// appdata 0x230510 rw size 8
// CHECK-NEXT:  220410 10052300 00000000 08000000 00000002
/// from_app 0x2103e4 exec size 4
// CHECK-NEXT:  220420 e0032100 00000000 60000100 00000004

// CHECK-PIE: Contents of section .data.rel.ro:
/// rodata (shlib.so) undef
// CHECK-PIE-NEXT:  203f0 00000000 00000000 00000000 00000000
/// data (shlib.so) undef
// CHECK-PIE-NEXT:  20400 00000000 00000000 00000000 00000000
/// appdata 0x30520 rw size 8
// CHECK-PIE-NEXT:  20410 20050300 00000000 08000000 00000002
/// from_app 0x103e4 exec size 4
// CHECK-PIE-NEXT:  20420 e0030100 00000000 60000100 00000004

 .data
 .global appdata
 .type appdata, %object
 .size appdata, 8
appdata: .xword 8

// CHECK: Contents of section .data:
// CHECK-NEXT:  230510 08000000 00000000

// CHECK-PIE: Contents of section .data:
// CHECK-PIE-NEXT:  30520 08000000 00000000

// CHECK-LABEL: <_start>:
// CHECK-NEXT:   2103e0:        ret

// CHECK-LABEL: <from_app>:
// CHECK-NEXT:   2103e4:        ret

// CHECK-PIE-LABEL: <_start>:
// CHECK-PIE-NEXT:    103e0:            ret

// CHECK-PIE-LABEL: <from_app>:
// CHECK-PIE-NEXT:    103e4:            ret

/// Check that the dynamic table holds the correct number of RELATIVE relocs
// RELS: DynamicSection [
// RELS: 0x000000006FFFFFF9 RELACOUNT 2

// RELS: Relocations [
// RELS-NEXT:   Section {{.*}} .rela.dyn {
/// .chericap appdata
// RELS-NEXT:     0x220410 R_MORELLO_RELATIVE - 0x0
/// .chericap from_app
// RELS-NEXT:     0x220420 R_MORELLO_RELATIVE - 0x5
/// .chericap rodata
// RELS-NEXT:     0x2203F0 R_MORELLO_CAPINIT rodata 0x0
/// .chericap data
// RELS-NEXT:     0x220400 R_MORELLO_CAPINIT data 0x0
// RELS-NEXT:   }

/// Check that the dynamic table holds the correct number of RELATIVE relocs
// RELS-PIE: DynamicSection [
// RELS-PIE: 0x000000006FFFFFF9 RELACOUNT 2

// RELS-PIE: Relocations [
// RELS-PIE-NEXT:   Section {{.*}} .rela.dyn {
/// .chericap appdata
// RELS-PIE-NEXT:     0x20410 R_MORELLO_RELATIVE - 0x0
/// .chericap from_app
// RELS-PIE-NEXT:     0x20420 R_MORELLO_RELATIVE - 0x5
/// .chericap rodata
// RELS-PIE-NEXT:     0x203F0 R_MORELLO_CAPINIT rodata 0x0
/// .chericap data
// RELS-PIE-NEXT:     0x20400 R_MORELLO_CAPINIT data 0x0
// RELS-PIE-NEXT:   }
