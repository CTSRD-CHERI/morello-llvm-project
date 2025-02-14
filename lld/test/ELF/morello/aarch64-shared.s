// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64,+morello -filetype=obj %s -o %t.o
// RUN: ld.lld --shared  %t.o -o %t.so
// RUN: llvm-objdump --print-imm-hex --no-show-raw-insn -d --triple=aarch64-none-elf --mattr=+morello -s %t.so | FileCheck %s
// RUN: llvm-readobj --symbols --relocations %t.so | FileCheck %s --check-prefix=RELS --check-prefix=SYMS
/// code for a shared library, using global, hidden, local, imported, .got,
/// .got.plt and .chericap
 .text

 .global globalfunc
 .type globalfunc, %function
 .size globalfunc, 16
globalfunc:
 nop
 nop
 nop
 ret

 .global hiddenfunc
 .hidden hiddenfunc
 .type hiddenfunc, %function
 .size hiddenfunc, 16
hiddenfunc:
 nop
 nop
 nop
 ret

 .local localfunc
 .type localfunc, %function
 .size localfunc, 16
localfunc:
 nop
 nop
 nop
 ret

 .global importfunc
 .global import

 .section .text.caller, "ax", %progbits
 .global caller
 .type caller, %function
caller:
 bl globalfunc
 bl hiddenfunc
 bl localfunc
 bl importfunc
 ret

 adrp c0, :got: globalfunc
 ldr c0, [c0, :got_lo12: globalfunc]

 adrp c1, :got: hiddenfunc
 ldr c1, [c1, :got_lo12: hiddenfunc]

 adrp c2, :got: localfunc
 ldr c2, [c2, :got_lo12: localfunc]

 adrp c3, :got: importfunc
 ldr c3, [c3, :got_lo12: importfunc]

 adrp c4, :got: global
 ldr  c4, [c4, :got_lo12: global]

 adrp c5, :got: hidden
 ldr  c5, [c5, :got_lo12: hidden]

 adrp c17, :got: import
 ldr  c17, [c17, :got_lo12: import]

 .data.rel.ro
 .chericap globalfunc
// CHECK: Contents of section .data.rel.ro:
// CHECK-NEXT:  206b0 e9050100 00000000 10000000 00000004
 .chericap hiddenfunc
// CHECK-NEXT:  206c0 40020000 00000000 40070300 00000004
 .chericap localfunc
// CHECK-NEXT:  206d0 40020000 00000000 40070300 00000004
 .chericap importfunc
// CHECK-NEXT:  206e0 00000000 00000000 00000000 00000002
 .chericap global
// CHECK-NEXT:  206f0 10090300 00000000 08000000 00000002
 .chericap hidden
// CHECK-NEXT:  20700 18090300 00000000 08000000 00000002
 .chericap local
// CHECK-NEXT:  20710 20090300 00000000 08000000 00000002
 .chericap import
// CHECK-NEXT:  20720 00000000 00000000 00000000 00000002
 .chericap globalfunc + 4
// CHECK-NEXT:  20730 e9050100 00000000 10000000 00000004
 .chericap hiddenfunc + 8
// CHECK-NEXT:  20740 40020000 00000000 40070300 00000004
 .chericap localfunc + 12
// CHECK-NEXT:  20750 40020000 00000000 40070300 00000004
 .chericap importfunc + 16
// CHECK-NEXT:  20760 00000000 00000000 00000000 00000002
 .chericap global + 1
// CHECK-NEXT:  20770 10090300 00000000 08000000 00000002
 .chericap hidden + 2
// CHECK-NEXT:  20780 18090300 00000000 08000000 00000002
 .chericap local + 3
// CHECK-NEXT:  20790 20090300 00000000 08000000 00000002
 .chericap import +4
// CHECK-NEXT:  207a0 00000000 00000000 00000000 00000002

// CHECK: Contents of section .got:
/// globalfunc 0x10001 executable 10
// CHECK:       208a0 e9050100 00000000 10000000 00000004
/// hiddenfunc 0x10011 executable 10
// CHECK-NEXT:  208b0 40020000 00000000 40070300 00000004
/// importfunc 0x00000 readwrite
// CHECK-NEXT:  208c0 00000000 00000000 00000000 00000002
/// import     0x00000 readwrite
// CHECK-NEXT:  208d0 00000000 00000000 00000000 00000002
/// global     0x30000 global readwrite 8
// CHECK-NEXT:  208e0 10090300 00000000 08000000 00000002
/// hidden     0x30008 hidden readwrite 8
// CHECK-NEXT:  208f0 18090300 00000000 08000000 00000002
/// localfunc  0x10021 executable 10
// CHECK-NEXT:  20900 40020000 00000000 40070300 00000004

// CHECK: Contents of section .data:
/// global 30910, hidden 30918, local 30920
// CHECK-NEXT: 30910 01000000 00000000 02000000 00000000
// CHECK-NEXT: 30920 03000000 00000000

// CHECK: Contents of section .got.plt:
// CHECK-NEXT:  30930 00000000 00000000 00000000 00000000
// CHECK-NEXT:  30940 00000000 00000000 00000000 00000000
// CHECK-NEXT:  30950 00000000 00000000 00000000 00000000
/// Initialised to PLT[0]
// CHECK-NEXT:  30960 71060100 00000000 00000000 00000000
// CHECK-NEXT:  30970 71060100 00000000 00000000 00000000

// CHECK-LABEL: <globalfunc>:
// CHECK-NEXT: 105e8: nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        ret c30

// CHECK-LABEL: <hiddenfunc>:
// CHECK-NEXT: 105f8: nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        ret c30

// CHECK-LABEL: <localfunc>:
// CHECK-NEXT: 10608: nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        ret c30

// CHECK-LABEL: <caller>:
// CHECK-NEXT: 10618: bl  0x10690
// CHECK-NEXT:        bl  0x105f8
// CHECK-NEXT:        bl  0x10608
// CHECK-NEXT:        bl  0x106a0
// CHECK-NEXT:        ret  c30
// CHECK-NEXT:        adrp c0, 0x20000
// CHECK-NEXT:        ldr  c0, [c0, #0x8a0]
// CHECK-NEXT:        adrp c1, 0x20000
// CHECK-NEXT:        ldr  c1, [c1, #0x8b0]
// CHECK-NEXT:        adrp c2, 0x20000
// CHECK-NEXT:        ldr  c2, [c2, #0x900]
// CHECK-NEXT:        adrp c3, 0x20000
// CHECK-NEXT:        ldr  c3, [c3, #0x8c0]
// CHECK-NEXT:        adrp c4, 0x20000
// CHECK-NEXT:        ldr  c4, [c4, #0x8e0]
// CHECK-NEXT:        adrp c5, 0x20000
// CHECK-NEXT:        ldr  c5, [c5, #0x8f0]
// CHECK-NEXT:        adrp c17, 0x20000
// CHECK-NEXT:        ldr  c17, [c17, #0x8d0]

// CHECK-LABEL: <.plt>:
// CHECK-NEXT: 10670: stp  c16, c30, [csp, #-0x20]!
// CHECK-NEXT:        adrp c16, 0x30000
// CHECK-NEXT:        ldr  c17, [c16, #0x950]
// CHECK-NEXT:        add  c16, c16, #0x950
// CHECK-NEXT:        br   c17
// CHECK-NEXT:        nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        nop

// CHECK-LABEL: <globalfunc@plt>:
// CHECK-NEXT: 10690: adrp  c16, 0x30000
// CHECK-NEXT:        add  c16, c16, #0x960
// CHECK-NEXT:        ldr  c17, [c16, #0x0]
// CHECK-NEXT:        br   c17

// CHECK-LABEL: <importfunc@plt>:
// CHECK-NEXT: 106a0: adrp c16, 0x30000
// CHECK-NEXT:        add  c16, c16, #0x970
// CHECK-NEXT:        ldr  c17, [c16, #0x0]
// CHECK-NEXT:        br   c17

// RELS: Relocations [
// RELS-NEXT:   Section {{.*}} .rela.dyn {
/// .chericap hiddenfunc
// RELS-NEXT:     0x206C0 R_MORELLO_RELATIVE - 0x103B9
/// .chericap localfunc
// RELS-NEXT:     0x206D0 R_MORELLO_RELATIVE - 0x103C9
/// .chericap hidden
// RELS-NEXT:     0x20700 R_MORELLO_RELATIVE - 0x0
/// .chericap local
// RELS-NEXT:     0x20710 R_MORELLO_RELATIVE - 0x0
/// .chericap hiddenfunc + 8
// RELS-NEXT:     0x20740 R_MORELLO_RELATIVE - 0x103C1
/// .chericap localfunc + 12
// RELS-NEXT:     0x20750 R_MORELLO_RELATIVE - 0x103D5
/// .chericap hidden + 2
// RELS-NEXT:     0x20780 R_MORELLO_RELATIVE - 0x2
/// .chericap import + 4
// RELS-NEXT:     0x20790 R_MORELLO_RELATIVE - 0x3
/// .got hiddenfunc
// RELS-NEXT:     0x208B0 R_MORELLO_RELATIVE - 0x103B9
/// .got hidden
// RELS-NEXT:     0x208F0 R_MORELLO_RELATIVE - 0x0
/// .got localfunc
// RELS-NEXT:     0x20900 R_MORELLO_RELATIVE - 0x103C9
// RELS-NEXT:     0x206E0 R_MORELLO_CAPINIT importfunc 0x0
// RELS-NEXT:     0x20760 R_MORELLO_CAPINIT importfunc 0x10
// RELS-NEXT:     0x208C0 R_MORELLO_GLOB_DAT importfunc 0x0
// RELS-NEXT:     0x20720 R_MORELLO_CAPINIT import 0x0
// RELS-NEXT:     0x207A0 R_MORELLO_CAPINIT import 0x4
// RELS-NEXT:     0x208D0 R_MORELLO_GLOB_DAT import 0x0
// RELS-NEXT:     0x206B0 R_MORELLO_CAPINIT globalfunc 0x0
/// .data.rel.ro globalfunc+4
// RELS-NEXT:     0x20730 R_MORELLO_CAPINIT globalfunc 0x4
/// .got globalfunc
// RELS-NEXT:     0x208A0 R_MORELLO_GLOB_DAT globalfunc 0x0
// RELS-NEXT:     0x206F0 R_MORELLO_CAPINIT global 0x0
// RELS-NEXT:     0x20770 R_MORELLO_CAPINIT global 0x1
// RELS-NEXT:     0x208E0 R_MORELLO_GLOB_DAT global 0x0
// RELS-NEXT:   }
// RELS-NEXT:   Section {{.*}} .rela.plt {
// RELS-NEXT:     0x30960 R_MORELLO_JUMP_SLOT globalfunc 0x0
// RELS-NEXT:     0x30970 R_MORELLO_JUMP_SLOT importfunc 0x0

// SYMS: Symbols [
// SYMS:        Name: localfunc
// SYMS-NEXT:   Value: 0x10609
// SYMS:        Name: local
// SYMS-NEXT:   Value: 0x30920
// SYMS:        Name: hiddenfunc
// SYMS-NEXT:   Value: 0x105F9
// SYMS:        Name: hidden
// SYMS-NEXT:   Value: 0x30918
// SYMS:        Name: globalfunc
// SYMS-NEXT:   Value: 0x105E9
// SYMS:        Name: importfunc
// SYMS-NEXT:   Value: 0x0
// SYMS:        Name: import
// SYMS-NEXT:   Value: 0x0

 .data
 .global global
 .type global, %object
 .size global, 8
global:
 .xword 1

 .global hidden
 .hidden hidden
 .type hidden, %object
 .size hidden, 8
hidden:
 .xword 2

 .local local
 .type local ,%object
 .size local, 8
local:
 .xword 3
