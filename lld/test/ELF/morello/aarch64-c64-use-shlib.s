// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64,+morello -filetype=obj %S/Inputs/shlib.s -o %t1.o
// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64,+morello -filetype=obj %s -o %t2.o
// RUN: ld.lld --shared --soname=t.so  %t1.o -o %t.so
// RUN: ld.lld %t.so %t2.o -o %t
// RUN: llvm-objdump --print-imm-hex --no-show-raw-insn -s -d --triple=aarch64-none-elf --mattr=+morello %t | FileCheck %s
// RUN: llvm-readobj --relocations %t | FileCheck %s --check-prefix=RELS
// RUN: ld.lld --pie  %t.so %t2.o -o %tpie
// RUN: llvm-objdump --print-imm-hex --no-show-raw-insn -s -d --triple=aarch64-none-elf --mattr=+morello %tpie | FileCheck %s --check-prefix=CHECK-PIE
// RUN: llvm-readobj --relocations %tpie | FileCheck %s --check-prefix=RELS-PIE

/// Application using a shared library. Expect to see dynamic
/// relocations and not a __cap_relocs section. The link is repeated for -fpie
 .text
 .global _start
 .type _start, %function
 .size _start, 8
_start:
 bl func
 adrp c0, :got: rodata
 ldr  c0, [c0, :got_lo12: rodata]
 adrp c1, :got: data
 ldr  c1, [c1, :got_lo12: data]
 adrp c2, :got: appdata
 ldr  c2, [c2, :got_lo12: appdata]
 adrp c3, :got: from_app
 ldr  c3, [c3, :got_lo12: from_app]
 adrp c4, :got: func2
 ldr  c4, [c4, :got_lo12: func2]
 adrp c5, :got: _start
 ldr  c5, [c5, :got_lo12: _start]
 ret

 .global from_app
 .type from_app, %function
 .size from_app, 4
from_app:
 ret

 .global func2

 .data.rel.ro
 .chericap rodata
 .chericap data
 .chericap appdata
 .chericap from_app
 .chericap func2

// CHECK: Contents of section .data.rel.ro:
/// rodata (shlib.so) undef
// CHECK-NEXT:  220570 00000000 00000000 00000000 00000000
/// data (shlib.so) undef
// CHECK-NEXT:  220580 00000000 00000000 00000000 00000000
/// appdata 0x230730 rw size 8
// CHECK-NEXT:  220590 30072300 00000000 08000000 00000002
/// from_app 0x210538 exec size 4
// CHECK-NEXT:  2205a0 00052100 00000000 80020200 00000004
/// func2 (shlib.so) exec undef
// CHECK-NEXT:  2205b0 00000000 00000000 00000000 00000000

// CHECK-PIE: Contents of section .data.rel.ro:
/// rodata (shlib.so) undef
// CHECK-PIE-NEXT:  20570 00000000 00000000 00000000 00000000
/// data (shlib.so) undef
// CHECK-PIE-NEXT:  20580 00000000 00000000 00000000 00000000
/// appdata 0x30740 rw size 8
// CHECK-PIE-NEXT:  20590 40070300 00000000 08000000 00000002
/// from_app 0x10538 exec size 4
// CHECK-PIE-NEXT:  205a0 00050100 00000000 c0020200 00000004
/// func2 (shlib.so) exec undef
// CHECK-PIE-NEXT:  205b0 00000000 00000000 00000000 00000000

 .data
 .global appdata
 .type appdata, %object
 .size appdata, 8
appdata: .xword 8

// CHECK: Contents of section .got:
/// from_app 0x210538 exec size 4
// CHECK-NEXT:  2206d0 00052100 00000000 80020200 00000004
/// func2 (shlib.so) exec undef
// CHECK-NEXT:  2206e0 00000000 00000000 00000000 00000000
/// rodata (shlib.so) undef
// CHECK-NEXT:  2206f0 00000000 00000000 00000000 00000000
/// data (shlib.so) undef
// CHECK-NEXT:  220700 00000000 00000000 00000000 00000000
/// _start 0x210500 exec size 4
// CHECK-NEXT:  220710 00052100 00000000 80020200 00000004
/// appdata 0x230730 rw size 8
// CHECK-NEXT:  220720 30072300 00000000 08000000 00000002

// CHECK-PIE: Contents of section .got:
/// from_app 0x10538 exec size 4
// CHECK-PIE-NEXT:  206e0 00050100 00000000 c0020200 00000004
/// func2 (shlib.so) exec size 4
// CHECK-PIE-NEXT:  206f0 00000000 00000000 00000000 00000000
/// rodata (shlib.so) undef
// CHECK-PIE-NEXT:  20700 00000000 00000000 00000000 00000000
/// data (shlib.so) undef
// CHECK-PIE-NEXT:  20710 00000000 00000000 00000000 00000000
/// _start 0x10500 exec size 4
// CHECK-PIE-NEXT:  20720 00050100 00000000 c0020200 00000004
/// appdata 0x30740 rw size 8
// CHECK-PIE-NEXT:  20730 40070300 00000000 08000000 00000002

// CHECK: Contents of section .data:
// CHECK-NEXT:  230730 08000000 00000000

// CHECK-PIE: Contents of section .data:
// CHECK-PIE-NEXT:  30740 08000000 00000000

// CHECK: Contents of section .got.plt:
// CHECK-NEXT:  230740 00000000 00000000 00000000 00000000
// CHECK-NEXT:  230750 00000000 00000000 00000000 00000000
// CHECK-NEXT:  230760 00000000 00000000 00000000 00000000

/// .got.plt[3] should be initialized to a PCC fragment
// CHECK-NEXT:  230770 00052100 00000000 80020200 00000004

// CHECK-PIE: Contents of section .got.plt:
// CHECK-PIE-NEXT: 30750 00000000 00000000 00000000 00000000
// CHECK-PIE-NEXT: 30760 00000000 00000000 00000000 00000000
// CHECK-PIE-NEXT: 30770 00000000 00000000 00000000 00000000

/// .got.plt[3] should be initialized to a PCC fragment
// CHECK-PIE-NEXT: 30780 00050100 00000000 c0020200 00000004

// CHECK-LABEL: <_start>:
// CHECK-NEXT: 210500: bl   0x210560
// CHECK-NEXT:         adrp c0, 0x220000
// CHECK-NEXT:         ldr  c0, [c0, #0x6f0]
// CHECK-NEXT:         adrp c1, 0x220000
// CHECK-NEXT:         ldr  c1, [c1, #0x700]
// CHECK-NEXT:         adrp c2, 0x220000
// CHECK-NEXT:         ldr  c2, [c2, #0x720]
// CHECK-NEXT:         adrp c3, 0x220000
// CHECK-NEXT:         ldr  c3, [c3, #0x6d0]
// CHECK-NEXT:         adrp c4, 0x220000
// CHECK-NEXT:         ldr  c4, [c4, #0x6e0]
// CHECK-NEXT:         adrp c5, 0x220000
// CHECK-NEXT:         ldr  c5, [c5, #0x710]
// CHECK-NEXT:         ret  c30

// CHECK-LABEL: <from_app>:
// CHECK-NEXT:   210538:  ret c30

/// Check that the PLT header points to .got.plt[2] (0x230760)
// CHECK-LABEL: <.plt>:
// CHECK-NEXT: 210540: stp  c16, c30, [csp, #-0x20]!
// CHECK-NEXT:         adrp c16, 0x230000
// CHECK-NEXT:         ldr  c17, [c16, #0x760]
// CHECK-NEXT:         add  c16, c16, #0x760
// CHECK-NEXT:         br   c17
// CHECK-NEXT:         nop
// CHECK-NEXT:         nop
// CHECK-NEXT:         nop

/// Check that the next PLT entry (.plt[3]) points to .got.plt[3] (0x230770)
// CHECK-LABEL: <func@plt>:
// CHECK-NEXT: 210560: adrp c16, 0x230000
// CHECK-NEXT:         add  c16, c16, #0x770
// CHECK-NEXT:         ldr  c17, [c16, #0x0]
// CHECK-NEXT:         br   c17

// CHECK-PIE-LABEL: <_start>:
// CHECK-PIE-NEXT:    10500: bl  0x10560
// CHECK-PIE-NEXT:           adrp c0, 0x20000
// CHECK-PIE-NEXT:           ldr  c0, [c0, #0x700]
// CHECK-PIE-NEXT:           adrp c1, 0x20000
// CHECK-PIE-NEXT:           ldr  c1, [c1, #0x710]
// CHECK-PIE-NEXT:           adrp c2, 0x20000
// CHECK-PIE-NEXT:           ldr  c2, [c2, #0x730]
// CHECK-PIE-NEXT:           adrp c3, 0x20000
// CHECK-PIE-NEXT:           ldr  c3, [c3, #0x6e0]
// CHECK-PIE-NEXT:           adrp c4, 0x20000
// CHECK-PIE-NEXT:           ldr  c4, [c4, #0x6f0]
// CHECK-PIE-NEXT:           adrp c5, 0x20000
// CHECK-PIE-NEXT:           ldr  c5, [c5, #0x720]
// CHECK-PIE-NEXT:           ret  c30

// CHECK-PIE-LABEL: <from_app>:
// CHECK-PIE-NEXT:    10538: ret c30

/// Check that the PLT header points to .got.plt[2] (0x30770)
// CHECK-PIE-LABEL: <.plt>:
// CHECK-PIE-NEXT:    10540: stp  c16, c30, [csp, #-0x20]!
// CHECK-PIE-NEXT:           adrp c16, 0x30000
// CHECK-PIE-NEXT:           ldr  c17, [c16, #0x770]
// CHECK-PIE-NEXT:           add  c16, c16, #0x770
// CHECK-PIE-NEXT:           br   c17
// CHECK-PIE-NEXT:           nop
// CHECK-PIE-NEXT:           nop
// CHECK-PIE-NEXT:           nop

/// Check that the next PLT entry (.plt[3]) points to .got.plt[3] (0x30780)
// CHECK-PIE-LABEL: <func@plt>:
// CHECK-PIE-NEXT:    10560: adrp  c16, 0x30000
// CHECK-PIE-NEXT:           add  c16, c16, #0x780
// CHECK-PIE-NEXT:           ldr  c17, [c16, #0x0]
// CHECK-PIE-NEXT:           br  c17

// RELS: Relocations [
// RELS-NEXT:   Section {{.*}} .rela.dyn {
/// .chericap appdata
// RELS-NEXT:     0x220590 R_MORELLO_RELATIVE - 0x0
//// .chericap from_app
// RELS-NEXT:     0x2205A0 R_MORELLO_RELATIVE - 0x39
/// .got from_app
// RELS-NEXT:     0x2206D0 R_MORELLO_RELATIVE - 0x39
/// _start
// RELS-NEXT:     0x220710 R_MORELLO_RELATIVE - 0x1
// .got appdata
// RELS-NEXT:     0x220720 R_MORELLO_RELATIVE - 0x0
/// .chericap func2
// RELS-NEXT:     0x2205B0 R_MORELLO_CAPINIT func2 0x0
/// .got func2
// RELS-NEXT:     0x2206E0 R_MORELLO_GLOB_DAT func2 0x0
/// .chericap rodata
// RELS-NEXT:     0x220570 R_MORELLO_CAPINIT rodata 0x0
/// .got rodata
// RELS-NEXT:     0x2206F0 R_MORELLO_GLOB_DAT rodata 0x0
/// .chericap data
// RELS-NEXT:     0x220580 R_MORELLO_CAPINIT data 0x0
/// .got data
// RELS-NEXT:     0x220700 R_MORELLO_GLOB_DAT data 0x0
// RELS-NEXT:   }
// RELS-NEXT:   Section {{.*}} .rela.plt {
// RELS-NEXT:     0x230770 R_MORELLO_JUMP_SLOT func 0x41

// RELS-PIE: Relocations [
// RELS-PIE-NEXT:   Section {{.*}} .rela.dyn {
/// .chericap appdata
// RELS-PIE-NEXT:     0x20590 R_MORELLO_RELATIVE - 0x0
/// .chericap from_app
// RELS-PIE-NEXT:     0x205A0 R_MORELLO_RELATIVE - 0x39
/// .got from_app
// RELS-PIE-NEXT:     0x206E0 R_MORELLO_RELATIVE - 0x39
/// _start
// RELS-PIE-NEXT:     0x20720 R_MORELLO_RELATIVE - 0x1
/// .got appdata
// RELS-PIE-NEXT:     0x20730 R_MORELLO_RELATIVE - 0x0
/// .chericap func2
// RELS-PIE-NEXT:     0x205B0 R_MORELLO_CAPINIT func2 0x0
/// .got func2
// RELS-PIE-NEXT:     0x206F0 R_MORELLO_GLOB_DAT func2 0x0
/// .chericap rodata
// RELS-PIE-NEXT:     0x20570 R_MORELLO_CAPINIT rodata 0x0
/// .got rodata
// RELS-PIE-NEXT:     0x20700 R_MORELLO_GLOB_DAT rodata 0x0
/// .chericap data
// RELS-PIE-NEXT:     0x20580 R_MORELLO_CAPINIT data 0x0
/// .got data
// RELS-PIE-NEXT:     0x20710 R_MORELLO_GLOB_DAT data 0x0
// RELS-PIE-NEXT:   }
// RELS-PIE-NEXT:   Section {{.*}} .rela.plt {
// RELS-PIE-NEXT:     0x30780 R_MORELLO_JUMP_SLOT func 0x41
