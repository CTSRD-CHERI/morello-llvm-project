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

// CHECK: Contents of section .got.plt:
// CHECK-NEXT:  20740 00000000 00000000 00000000 00000000
// CHECK-NEXT:  20750 00000000 00000000 00000000 00000000
// CHECK-NEXT:  20760 00000000 00000000 00000000 00000000
/// Initialised to PCC fragment
// CHECK-NEXT:  20770 80060100 00000000 80020200 00000004
// CHECK-NEXT:  20780 80060100 00000000 80020200 00000004

 .data.rel.ro
 .chericap globalfunc
// CHECK: Contents of section .data.rel.ro:
// CHECK-NEXT:  30790 00000000 00000000 00000000 00000000
 .chericap hiddenfunc
// CHECK-NEXT:  307a0 80060100 00000000 80020200 00000004
 .chericap localfunc
// CHECK-NEXT:  307b0 80060100 00000000 80020200 00000004
 .chericap importfunc
// CHECK-NEXT:  307c0 00000000 00000000 00000000 00000000
 .chericap global
// CHECK-NEXT:  307d0 00000000 00000000 00000000 00000000
 .chericap hidden
// CHECK-NEXT:  307e0 f8090400 00000000 08000000 00000002
 .chericap local
// CHECK-NEXT:  307f0 000a0400 00000000 08000000 00000002
 .chericap import
// CHECK-NEXT:  30800 00000000 00000000 00000000 00000000
 .chericap globalfunc + 4
// CHECK-NEXT:  30810 00000000 00000000 00000000 00000000
 .chericap hiddenfunc + 8
// CHECK-NEXT:  30820 80060100 00000000 80020200 00000004
 .chericap localfunc + 12
// CHECK-NEXT:  30830 80060100 00000000 80020200 00000004
 .chericap importfunc + 16
// CHECK-NEXT:  30840 00000000 00000000 00000000 00000000
 .chericap global + 1
// CHECK-NEXT:  30850 00000000 00000000 00000000 00000000
 .chericap hidden + 2
// CHECK-NEXT:  30860 f8090400 00000000 08000000 00000002
 .chericap local + 3
// CHECK-NEXT:  30870 000a0400 00000000 08000000 00000002
 .chericap import +4
// CHECK-NEXT:  30880 00000000 00000000 00000000 00000000

// CHECK: Contents of section .got:
/// globalfunc undef
// CHECK:       30890 00000000 00000000 00000000 00000000
/// hiddenfunc 0x10651 executable 10
// CHECK-NEXT:  308a0 80060100 00000000 80020200 00000004
/// importfunc undef
// CHECK-NEXT:  308b0 00000000 00000000 00000000 00000000
/// import     undef
// CHECK-NEXT:  308c0 00000000 00000000 00000000 00000000
/// global     undef
// CHECK-NEXT:  308d0 00000000 00000000 00000000 00000000
/// hidden     0x409f8 hidden readwrite 8
// CHECK-NEXT:  308e0 f8090400 00000000 08000000 00000002
/// localfunc  0x106a1 executable 10
// CHECK-NEXT:  308f0 80060100 00000000 80020200 00000004

// CHECK: Contents of section .data:
/// global 409f0, hidden 409f8, local 40a00
// CHECK-NEXT: 409f0 01000000 00000000 02000000 00000000
// CHECK-NEXT: 40a00 03000000 00000000

// CHECK-LABEL: <globalfunc>:
// CHECK-NEXT: 10680: nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        ret c30

// CHECK-LABEL: <hiddenfunc>:
// CHECK-NEXT: 10690: nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        ret c30

// CHECK-LABEL: <localfunc>:
// CHECK-NEXT: 106a0: nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        ret c30

// CHECK-LABEL: <caller>:
// CHECK-NEXT: 106b0: bl  0x10720
// CHECK-NEXT:        bl  0x10690
// CHECK-NEXT:        bl  0x106a0
// CHECK-NEXT:        bl  0x10730
// CHECK-NEXT:        ret  c30
// CHECK-NEXT:        adrp c0, 0x30000
// CHECK-NEXT:        ldr  c0, [c0, #0x890]
// CHECK-NEXT:        adrp c1, 0x30000
// CHECK-NEXT:        ldr  c1, [c1, #0x8a0]
// CHECK-NEXT:        adrp c2, 0x30000
// CHECK-NEXT:        ldr  c2, [c2, #0x8f0]
// CHECK-NEXT:        adrp c3, 0x30000
// CHECK-NEXT:        ldr  c3, [c3, #0x8b0]
// CHECK-NEXT:        adrp c4, 0x30000
// CHECK-NEXT:        ldr  c4, [c4, #0x8d0]
// CHECK-NEXT:        adrp c5, 0x30000
// CHECK-NEXT:        ldr  c5, [c5, #0x8e0]
// CHECK-NEXT:        adrp c17, 0x30000
// CHECK-NEXT:        ldr  c17, [c17, #0x8c0]

// CHECK-LABEL: <.plt>:
// CHECK-NEXT: 10700: stp  c16, c30, [csp, #-0x20]!
// CHECK-NEXT:        adrp c16, 0x20000
// CHECK-NEXT:        ldr  c17, [c16, #0x760]
// CHECK-NEXT:        add  c16, c16, #0x760
// CHECK-NEXT:        br   c17
// CHECK-NEXT:        nop
// CHECK-NEXT:        nop
// CHECK-NEXT:        nop

// CHECK-LABEL: <globalfunc@plt>:
// CHECK-NEXT: 10720: adrp  c16, 0x20000
// CHECK-NEXT:        add  c16, c16, #0x770
// CHECK-NEXT:        ldr  c17, [c16, #0x0]
// CHECK-NEXT:        br   c17

// CHECK-LABEL: <importfunc@plt>:
// CHECK-NEXT: 10730: adrp c16, 0x20000
// CHECK-NEXT:        add  c16, c16, #0x780
// CHECK-NEXT:        ldr  c17, [c16, #0x0]
// CHECK-NEXT:        br   c17

// RELS: Relocations [
// RELS-NEXT:   Section {{.*}} .rela.dyn {
/// .chericap hiddenfunc
// RELS-NEXT:     0x307A0 R_MORELLO_RELATIVE - 0x11
/// .chericap localfunc
// RELS-NEXT:     0x307B0 R_MORELLO_RELATIVE - 0x21
/// .chericap hidden
// RELS-NEXT:     0x307E0 R_MORELLO_RELATIVE - 0x0
/// .chericap local
// RELS-NEXT:     0x307F0 R_MORELLO_RELATIVE - 0x0
/// .chericap hiddenfunc + 8
// RELS-NEXT:     0x30820 R_MORELLO_RELATIVE - 0x19
/// .chericap localfunc + 12
// RELS-NEXT:     0x30830 R_MORELLO_RELATIVE - 0x2D
/// .chericap hidden + 2
// RELS-NEXT:     0x30860 R_MORELLO_RELATIVE - 0x2
/// .chericap import + 4
// RELS-NEXT:     0x30870 R_MORELLO_RELATIVE - 0x3
/// .got hiddenfunc
// RELS-NEXT:     0x308A0 R_MORELLO_RELATIVE - 0x11
/// .got hidden
// RELS-NEXT:     0x308E0 R_MORELLO_RELATIVE - 0x0
/// .got localfunc
// RELS-NEXT:     0x308F0 R_MORELLO_RELATIVE - 0x21
// RELS-NEXT:     0x307C0 R_MORELLO_CAPINIT importfunc 0x0
// RELS-NEXT:     0x30840 R_MORELLO_CAPINIT importfunc 0x10
// RELS-NEXT:     0x308B0 R_MORELLO_GLOB_DAT importfunc 0x0
// RELS-NEXT:     0x30800 R_MORELLO_CAPINIT import 0x0
// RELS-NEXT:     0x30880 R_MORELLO_CAPINIT import 0x4
// RELS-NEXT:     0x308C0 R_MORELLO_GLOB_DAT import 0x0
// RELS-NEXT:     0x30790 R_MORELLO_CAPINIT globalfunc 0x0
/// .data.rel.ro globalfunc+4
// RELS-NEXT:     0x30810 R_MORELLO_CAPINIT globalfunc 0x4
/// .got globalfunc
// RELS-NEXT:     0x30890 R_MORELLO_GLOB_DAT globalfunc 0x0
// RELS-NEXT:     0x307D0 R_MORELLO_CAPINIT global 0x0
// RELS-NEXT:     0x30850 R_MORELLO_CAPINIT global 0x1
// RELS-NEXT:     0x308D0 R_MORELLO_GLOB_DAT global 0x0
// RELS-NEXT:   }
// RELS-NEXT:   Section {{.*}} .rela.plt {
// RELS-NEXT:     0x20770 R_MORELLO_JUMP_SLOT globalfunc 0x81
// RELS-NEXT:     0x20780 R_MORELLO_JUMP_SLOT importfunc 0x81

// SYMS: Symbols [
// SYMS:        Name: localfunc
// SYMS-NEXT:   Value: 0x106A1
// SYMS:        Name: local
// SYMS-NEXT:   Value: 0x40A00
// SYMS:        Name: hiddenfunc
// SYMS-NEXT:   Value: 0x10691
// SYMS:        Name: hidden
// SYMS-NEXT:   Value: 0x409F8
// SYMS:        Name: globalfunc
// SYMS-NEXT:   Value: 0x10681
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
