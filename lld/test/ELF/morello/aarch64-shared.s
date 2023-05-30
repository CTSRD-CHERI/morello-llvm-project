// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64,+morello -filetype=obj %s -o %t.o
// RUN: ld.lld --shared  %t.o -o %t.so
// RUN: llvm-objdump --print-imm-hex --no-show-raw-insn -d --triple=aarch64-none-elf --mattr=+morello -s %t.so | FileCheck %s
// RUN: llvm-readobj --symbols --relocations %t.so | FileCheck %s --check-prefix=RELS --check-prefix=SYMS
/// code for a shared library, using global, hidden, local, imported, .got,
/// .got.plt and .capinit
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
 .capinit globalfunc
 .xword 0
 .xword 0
// CHECK: Contents of section .data.rel.ro:
// CHECK-NEXT:  20690 d1050100 00000000 10000000 00000004
 .capinit hiddenfunc
 .xword 0
 .xword 0
// CHECK-NEXT:  206a0 40020000 00000000 40070300 00000004
 .capinit localfunc
 .xword 0
 .xword 0
// CHECK-NEXT:  206b0 40020000 00000000 40070300 00000004
 .capinit importfunc
 .xword 0
 .xword 0
// CHECK-NEXT:  206c0 00000000 00000000 00000000 00000002
 .capinit global
 .xword 0
 .xword 0
// CHECK-NEXT:  206d0 f0080300 00000000 08000000 00000002
 .capinit hidden
 .xword 0
 .xword 0
// CHECK-NEXT:  206e0 f8080300 00000000 08000000 00000002
 .capinit local
 .xword 0
 .xword 0
// CHECK-NEXT:  206f0 00090300 00000000 08000000 00000002
 .capinit import
 .xword 0
 .xword 0
// CHECK-NEXT:  20700 00000000 00000000 00000000 00000002
 .capinit globalfunc + 4
 .xword 0
 .xword 0
// CHECK-NEXT:  20710 d1050100 00000000 10000000 00000004
 .capinit hiddenfunc + 8
 .xword 0
 .xword 0
// CHECK-NEXT:  20720 40020000 00000000 40070300 00000004
 .capinit localfunc + 12
 .xword 0
 .xword 0
// CHECK-NEXT:  20730 40020000 00000000 40070300 00000004
 .capinit importfunc + 16
 .xword 0
 .xword 0
// CHECK-NEXT:  20740 00000000 00000000 00000000 00000002
 .capinit global + 1
 .xword 0
 .xword 0
// CHECK-NEXT:  20750 f0080300 00000000 08000000 00000002
 .capinit hidden + 2
 .xword 0
 .xword 0
// CHECK-NEXT:  20760 f8080300 00000000 08000000 00000002
 .capinit local + 3
 .xword 0
 .xword 0
// CHECK-NEXT:  20770 00090300 00000000 08000000 00000002
 .capinit import +4
 .xword 0
 .xword 0
// CHECK-NEXT:  20780 00000000 00000000 00000000 00000002

// CHECK: Contents of section .got:
/// globalfunc 0x10001 executable 10
// CHECK:       20880 d1050100 00000000 10000000 00000004
/// hiddenfunc 0x10011 executable 10
// CHECK-NEXT:  20890 40020000 00000000 40070300 00000004
/// importfunc 0x00000 readwrite
// CHECK-NEXT:  208a0 00000000 00000000 00000000 00000002
/// import     0x00000 readwrite
// CHECK-NEXT:  208b0 00000000 00000000 00000000 00000002
/// global     0x30000 global readwrite 8
// CHECK-NEXT:  208c0 f0080300 00000000 08000000 00000002
/// hidden     0x30008 hidden readwrite 8
// CHECK-NEXT:  208d0 f8080300 00000000 08000000 00000002
/// localfunc  0x10021 executable 10
// CHECK-NEXT:  208e0 40020000 00000000 40070300 00000004

// CHECK: Contents of section .data:
/// global 308f0, hidden 308f8, local 30900
// CHECK-NEXT: 308f0 01000000 00000000 02000000 00000000
// CHECK-NEXT: 30900 03000000 00000000

// CHECK: Contents of section .got.plt:
// CHECK-NEXT:  30910 00000000 00000000 00000000 00000000
// CHECK-NEXT:  30920 00000000 00000000 00000000 00000000
// CHECK-NEXT:  30930 00000000 00000000 00000000 00000000
/// Initialised to PLT[0]
// CHECK-NEXT:  30940 51060100 00000000 00000000 00000000
// CHECK-NEXT:  30950 51060100 00000000 00000000 00000000

// CHECK-LABEL: <globalfunc>:
// CHECK-NEXT: 105d0: nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        ret c30

// CHECK-LABEL: <hiddenfunc>:
// CHECK-NEXT: 105e0: nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        ret c30

// CHECK-LABEL: <localfunc>:
// CHECK-NEXT: 105f0: nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        ret c30

// CHECK-LABEL: <caller>:
// CHECK-NEXT: 10600: bl  0x10670
// CHECK-NEXT:        bl  0x105e0
// CHECK-NEXT:        bl  0x105f0
// CHECK-NEXT:        bl  0x10680
// CHECK-NEXT:        ret  c30
// CHECK-NEXT:        adrp c0, 0x20000
// CHECK-NEXT:        ldr  c0, [c0, #0x880]
// CHECK-NEXT:        adrp c1, 0x20000
// CHECK-NEXT:        ldr  c1, [c1, #0x890]
// CHECK-NEXT:        adrp c2, 0x20000
// CHECK-NEXT:        ldr  c2, [c2, #0x8e0]
// CHECK-NEXT:        adrp c3, 0x20000
// CHECK-NEXT:        ldr  c3, [c3, #0x8a0]
// CHECK-NEXT:        adrp c4, 0x20000
// CHECK-NEXT:        ldr  c4, [c4, #0x8c0]
// CHECK-NEXT:        adrp c5, 0x20000
// CHECK-NEXT:        ldr  c5, [c5, #0x8d0]
// CHECK-NEXT:        adrp c17, 0x20000
// CHECK-NEXT:        ldr  c17, [c17, #0x8b0]

// CHECK-LABEL: <.plt>:
// CHECK-NEXT: 10650: stp  c16, c30, [csp, #-0x20]!
// CHECK-NEXT:        adrp c16, 0x30000
// CHECK-NEXT:        ldr  c17, [c16, #0x930]
// CHECK-NEXT:        add  c16, c16, #0x930
// CHECK-NEXT:        br   c17
// CHECK-NEXT:        nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        adrp  c16, 0x30000
// CHECK-NEXT:        add  c16, c16, #0x940
// CHECK-NEXT:        ldr  c17, [c16, #0x0]
// CHECK-NEXT:        br   c17
// CHECK-NEXT:        adrp c16, 0x30000
// CHECK-NEXT:        add  c16, c16, #0x950
// CHECK-NEXT:        ldr  c17, [c16, #0x0]
// CHECK-NEXT:        br   c17

// RELS: Relocations [
// RELS-NEXT:   Section {{.*}} .rela.dyn {
/// .capinit hiddenfunc
// RELS-NEXT:     0x206A0 R_MORELLO_RELATIVE - 0x103A1
/// .capinit localfunc
// RELS-NEXT:     0x206B0 R_MORELLO_RELATIVE - 0x103B1
/// .capinit hidden
// RELS-NEXT:     0x206E0 R_MORELLO_RELATIVE - 0x0
/// .capinit local
// RELS-NEXT:     0x206F0 R_MORELLO_RELATIVE - 0x0
/// .capinit hiddenfunc + 8
// RELS-NEXT:     0x20720 R_MORELLO_RELATIVE - 0x103A9
/// .capinit localfunc + 12
// RELS-NEXT:     0x20730 R_MORELLO_RELATIVE - 0x103BD
/// .capinit hidden + 2
// RELS-NEXT:     0x20760 R_MORELLO_RELATIVE - 0x2
/// .capinit import + 4
// RELS-NEXT:     0x20770 R_MORELLO_RELATIVE - 0x3
/// .got hiddenfunc
// RELS-NEXT:     0x20890 R_MORELLO_RELATIVE - 0x103A1
/// .got hidden
// RELS-NEXT:     0x208D0 R_MORELLO_RELATIVE - 0x0
/// .got localfunc
// RELS-NEXT:     0x208E0 R_MORELLO_RELATIVE - 0x103B1
// RELS-NEXT:     0x206C0 R_MORELLO_CAPINIT importfunc 0x0
// RELS-NEXT:     0x20740 R_MORELLO_CAPINIT importfunc 0x10
// RELS-NEXT:     0x208A0 R_MORELLO_GLOB_DAT importfunc 0x0
// RELS-NEXT:     0x20700 R_MORELLO_CAPINIT import 0x0
// RELS-NEXT:     0x20780 R_MORELLO_CAPINIT import 0x4
// RELS-NEXT:     0x208B0 R_MORELLO_GLOB_DAT import 0x0
// RELS-NEXT:     0x20690 R_MORELLO_CAPINIT globalfunc 0x0
/// .data.rel.ro globalfunc+4
// RELS-NEXT:     0x20710 R_MORELLO_CAPINIT globalfunc 0x4
/// .got globalfunc
// RELS-NEXT:     0x20880 R_MORELLO_GLOB_DAT globalfunc 0x0
// RELS-NEXT:     0x206D0 R_MORELLO_CAPINIT global 0x0
// RELS-NEXT:     0x20750 R_MORELLO_CAPINIT global 0x1
// RELS-NEXT:     0x208C0 R_MORELLO_GLOB_DAT global 0x0
// RELS-NEXT:   }
// RELS-NEXT:   Section {{.*}} .rela.plt {
// RELS-NEXT:     0x30940 R_MORELLO_JUMP_SLOT globalfunc 0x0
// RELS-NEXT:     0x30950 R_MORELLO_JUMP_SLOT importfunc 0x0

// SYMS: Symbols [
// SYMS:        Name: localfunc
// SYMS-NEXT:   Value: 0x105F1
// SYMS:        Name: local
// SYMS-NEXT:   Value: 0x30900
// SYMS:        Name: hiddenfunc
// SYMS-NEXT:   Value: 0x105E1
// SYMS:        Name: hidden
// SYMS-NEXT:   Value: 0x308F8
// SYMS:        Name: globalfunc
// SYMS-NEXT:   Value: 0x105D1
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
