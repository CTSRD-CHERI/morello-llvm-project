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
// CHECK-NEXT:  20700 00000000 00000000 00000000 00000000
 .chericap hiddenfunc
// CHECK-NEXT:  20710 40060100 00000000 c0030200 00000004
 .chericap localfunc
// CHECK-NEXT:  20720 40060100 00000000 c0030200 00000004
 .chericap importfunc
// CHECK-NEXT:  20730 00000000 00000000 00000000 00000000
 .chericap global
// CHECK-NEXT:  20740 00000000 00000000 00000000 00000000
 .chericap hidden
// CHECK-NEXT:  20750 68090300 00000000 08000000 00000002
 .chericap local
// CHECK-NEXT:  20760 70090300 00000000 08000000 00000002
 .chericap import
// CHECK-NEXT:  20770 00000000 00000000 00000000 00000000
 .chericap globalfunc + 4
// CHECK-NEXT:  20780 00000000 00000000 00000000 00000000
 .chericap hiddenfunc + 8
// CHECK-NEXT:  20790 40060100 00000000 c0030200 00000004
 .chericap localfunc + 12
// CHECK-NEXT:  207a0 40060100 00000000 c0030200 00000004
 .chericap importfunc + 16
// CHECK-NEXT:  207b0 00000000 00000000 00000000 00000000
 .chericap global + 1
// CHECK-NEXT:  207c0 00000000 00000000 00000000 00000000
 .chericap hidden + 2
// CHECK-NEXT:  207d0 68090300 00000000 08000000 00000002
 .chericap local + 3
// CHECK-NEXT:  207e0 70090300 00000000 08000000 00000002
 .chericap import +4
// CHECK-NEXT:  207f0 00000000 00000000 00000000 00000000

// CHECK: Contents of section .got:
/// globalfunc undef
// CHECK:       208f0 00000000 00000000 00000000 00000000
/// hiddenfunc 0x10651 executable 10
// CHECK-NEXT:  20900 40060100 00000000 c0030200 00000004
/// importfunc undef
// CHECK-NEXT:  20910 00000000 00000000 00000000 00000000
/// import     undef
// CHECK-NEXT:  20920 00000000 00000000 00000000 00000000
/// global     undef
// CHECK-NEXT:  20930 00000000 00000000 00000000 00000000
/// hidden     0x30968 hidden readwrite 8
// CHECK-NEXT:  20940 68090300 00000000 08000000 00000002
/// localfunc  0x10661 executable 10
// CHECK-NEXT:  20950 40060100 00000000 c0030200 00000004

// CHECK: Contents of section .data:
/// global 30960, hidden 30968, local 30970
// CHECK-NEXT: 30960 01000000 00000000 02000000 00000000
// CHECK-NEXT: 30970 03000000 00000000

// CHECK: Contents of section .got.plt:
// CHECK-NEXT:  30980 00000000 00000000 00000000 00000000
// CHECK-NEXT:  30990 00000000 00000000 00000000 00000000
// CHECK-NEXT:  309a0 00000000 00000000 00000000 00000000
/// Initialised to PCC fragment
// CHECK-NEXT:  309b0 40060100 00000000 c0030200 00000004
// CHECK-NEXT:  309c0 40060100 00000000 c0030200 00000004

// CHECK-LABEL: <globalfunc>:
// CHECK-NEXT: 10640: nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        ret c30

// CHECK-LABEL: <hiddenfunc>:
// CHECK-NEXT: 10650: nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        ret c30

// CHECK-LABEL: <localfunc>:
// CHECK-NEXT: 10660: nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        ret c30

// CHECK-LABEL: <caller>:
// CHECK-NEXT: 10670: bl  0x106e0
// CHECK-NEXT:        bl  0x10650
// CHECK-NEXT:        bl  0x10660
// CHECK-NEXT:        bl  0x106f0
// CHECK-NEXT:        ret  c30
// CHECK-NEXT:        adrp c0, 0x20000
// CHECK-NEXT:        ldr  c0, [c0, #0x8f0]
// CHECK-NEXT:        adrp c1, 0x20000
// CHECK-NEXT:        ldr  c1, [c1, #0x900]
// CHECK-NEXT:        adrp c2, 0x20000
// CHECK-NEXT:        ldr  c2, [c2, #0x950]
// CHECK-NEXT:        adrp c3, 0x20000
// CHECK-NEXT:        ldr  c3, [c3, #0x910]
// CHECK-NEXT:        adrp c4, 0x20000
// CHECK-NEXT:        ldr  c4, [c4, #0x930]
// CHECK-NEXT:        adrp c5, 0x20000
// CHECK-NEXT:        ldr  c5, [c5, #0x940]
// CHECK-NEXT:        adrp c17, 0x20000
// CHECK-NEXT:        ldr  c17, [c17, #0x920]

// CHECK-LABEL: <.plt>:
// CHECK-NEXT: 106c0: stp  c16, c30, [csp, #-0x20]!
// CHECK-NEXT:        adrp c16, 0x30000
// CHECK-NEXT:        ldr  c17, [c16, #0x9a0]
// CHECK-NEXT:        add  c16, c16, #0x9a0
// CHECK-NEXT:        br   c17
// CHECK-NEXT:        nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        nop

// CHECK-LABEL: <globalfunc@plt>:
// CHECK-NEXT: 106e0: adrp  c16, 0x30000
// CHECK-NEXT:        add  c16, c16, #0x9b0
// CHECK-NEXT:        ldr  c17, [c16, #0x0]
// CHECK-NEXT:        br   c17

// CHECK-LABEL: <importfunc@plt>:
// CHECK-NEXT: 106f0: adrp c16, 0x30000
// CHECK-NEXT:        add  c16, c16, #0x9c0
// CHECK-NEXT:        ldr  c17, [c16, #0x0]
// CHECK-NEXT:        br   c17

// RELS: Relocations [
// RELS-NEXT:   Section {{.*}} .rela.dyn {
/// .chericap hiddenfunc
// RELS-NEXT:     0x20710 R_MORELLO_RELATIVE - 0x11
/// .chericap localfunc
// RELS-NEXT:     0x20720 R_MORELLO_RELATIVE - 0x21
/// .chericap hidden
// RELS-NEXT:     0x20750 R_MORELLO_RELATIVE - 0x0
/// .chericap local
// RELS-NEXT:     0x20760 R_MORELLO_RELATIVE - 0x0
/// .chericap hiddenfunc + 8
// RELS-NEXT:     0x20790 R_MORELLO_RELATIVE - 0x19
/// .chericap localfunc + 12
// RELS-NEXT:     0x207A0 R_MORELLO_RELATIVE - 0x2D
/// .chericap hidden + 2
// RELS-NEXT:     0x207D0 R_MORELLO_RELATIVE - 0x2
/// .chericap import + 4
// RELS-NEXT:     0x207E0 R_MORELLO_RELATIVE - 0x3
/// .got hiddenfunc
// RELS-NEXT:     0x20900 R_MORELLO_RELATIVE - 0x11
/// .got hidden
// RELS-NEXT:     0x20940 R_MORELLO_RELATIVE - 0x0
/// .got localfunc
// RELS-NEXT:     0x20950 R_MORELLO_RELATIVE - 0x21
// RELS-NEXT:     0x20730 R_MORELLO_CAPINIT importfunc 0x0
// RELS-NEXT:     0x207B0 R_MORELLO_CAPINIT importfunc 0x10
// RELS-NEXT:     0x20910 R_MORELLO_GLOB_DAT importfunc 0x0
// RELS-NEXT:     0x20770 R_MORELLO_CAPINIT import 0x0
// RELS-NEXT:     0x207F0 R_MORELLO_CAPINIT import 0x4
// RELS-NEXT:     0x20920 R_MORELLO_GLOB_DAT import 0x0
// RELS-NEXT:     0x20700 R_MORELLO_CAPINIT globalfunc 0x0
/// .data.rel.ro globalfunc+4
// RELS-NEXT:     0x20780 R_MORELLO_CAPINIT globalfunc 0x4
/// .got globalfunc
// RELS-NEXT:     0x208F0 R_MORELLO_GLOB_DAT globalfunc 0x0
// RELS-NEXT:     0x20740 R_MORELLO_CAPINIT global 0x0
// RELS-NEXT:     0x207C0 R_MORELLO_CAPINIT global 0x1
// RELS-NEXT:     0x20930 R_MORELLO_GLOB_DAT global 0x0
// RELS-NEXT:   }
// RELS-NEXT:   Section {{.*}} .rela.plt {
// RELS-NEXT:     0x309B0 R_MORELLO_JUMP_SLOT globalfunc 0x81
// RELS-NEXT:     0x309C0 R_MORELLO_JUMP_SLOT importfunc 0x81

// SYMS: Symbols [
// SYMS:        Name: localfunc
// SYMS-NEXT:   Value: 0x10661
// SYMS:        Name: local
// SYMS-NEXT:   Value: 0x30970
// SYMS:        Name: hiddenfunc
// SYMS-NEXT:   Value: 0x10651
// SYMS:        Name: hidden
// SYMS-NEXT:   Value: 0x30968
// SYMS:        Name: globalfunc
// SYMS-NEXT:   Value: 0x10641
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
