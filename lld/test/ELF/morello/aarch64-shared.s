// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64,+morello -filetype=obj %s -o %t.o
// RUN: ld.lld --shared --morello-c64-plt %t.o -o %t.so
// RUN: llvm-objdump --print-imm-hex --no-show-raw-insn -d --triple=aarch64-none-elf --mattr=+morello -s %t.so | FileCheck %s
// RUN: llvm-readobj --relocations %t.so | FileCheck %s --check-prefix=RELS
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
// CHECK-NEXT:  20640 79050100 00000000 10000000 00000004
 .capinit hiddenfunc
 .xword 0
 .xword 0
// CHECK-NEXT:  20650 89050100 00000000 10000000 00000004
 .capinit localfunc
 .xword 0
 .xword 0
// CHECK-NEXT:  20660 99050100 00000000 10000000 00000004
 .capinit importfunc
 .xword 0
 .xword 0
// CHECK-NEXT:  20670 00000000 00000000 00000000 00000002
 .capinit global
 .xword 0
 .xword 0
// CHECK-NEXT:  20680 a0080300 00000000 08000000 00000002
 .capinit hidden
 .xword 0
 .xword 0
// CHECK-NEXT:  20690 a8080300 00000000 08000000 00000002
 .capinit local
 .xword 0
 .xword 0
// CHECK-NEXT:  206a0 b0080300 00000000 08000000 00000002
 .capinit import
 .xword 0
 .xword 0
// CHECK-NEXT:  206b0 00000000 00000000 00000000 00000002
 .capinit globalfunc + 4
 .xword 0
 .xword 0
// CHECK-NEXT:  206c0 79050100 00000000 10000000 00000004
 .capinit hiddenfunc + 8
 .xword 0
 .xword 0
// CHECK-NEXT:  206d0 89050100 00000000 10000000 00000004
 .capinit localfunc + 12
 .xword 0
 .xword 0
// CHECK-NEXT:  206e0 99050100 00000000 10000000 00000004
 .capinit importfunc + 16
 .xword 0
 .xword 0
// CHECK-NEXT:  206f0 00000000 00000000 00000000 00000002
 .capinit global + 1
 .xword 0
 .xword 0
// CHECK-NEXT:  20700 a0080300 00000000 08000000 00000002
 .capinit hidden + 2
 .xword 0
 .xword 0
// CHECK-NEXT:  20710 a8080300 00000000 08000000 00000002
 .capinit local + 3
 .xword 0
 .xword 0
// CHECK-NEXT:  20720 b0080300 00000000 08000000 00000002
 .capinit import +4
 .xword 0
 .xword 0
// CHECK-NEXT:  20730 00000000 00000000 00000000 00000002

// CHECK: Contents of section .got:
/// globalfunc 0x10001 executable 10
// CHECK:       20830 79050100 00000000 10000000 00000004
/// hiddenfunc 0x10011 executable 10
// CHECK-NEXT:  20840 89050100 00000000 10000000 00000004
/// localfunc  0x10021 executable 10
// CHECK-NEXT:  20850 99050100 00000000 10000000 00000004
/// importfunc 0x00000 readwrite
// CHECK-NEXT:  20860 00000000 00000000 00000000 00000002
/// global     0x30000 global readwrite 8
// CHECK-NEXT:  20870 a0080300 00000000 08000000 00000002
/// hidden     0x30008 hidden readwrite 8
// CHECK-NEXT:  20880 a8080300 00000000 08000000 00000002
/// import     0x00000 readwrite
// CHECK-NEXT:  20890 00000000 00000000 00000000 00000002

// CHECK: Contents of section .data:
/// global 308a0, hidden 308a8, local 308b0
// CHECK-NEXT:  308a0 01000000 00000000 02000000 00000000
// CHECK-NEXT:  308b0 03000000 00000000

// CHECK: Contents of section .got.plt:
// CHECK-NEXT:  308c0 00000000 00000000 00000000 00000000
// CHECK-NEXT:  308d0 00000000 00000000 00000000 00000000
// CHECK-NEXT:  308e0 00000000 00000000 00000000 00000000
/// Initialised to PLT[0]
// CHECK-NEXT:  308f0 01060100 00000000 00000000 00000000
// CHECK-NEXT:  30900 01060100 00000000 00000000 00000000

// CHECK: 0000000000010578 <globalfunc>:
// CHECK-NEXT:    10578:        nop
// CHECK-NEXT:    1057c:        nop
// CHECK-NEXT:    10580:        nop
// CHECK-NEXT:    10584:        ret

// CHECK: 0000000000010588 <hiddenfunc>:
// CHECK-NEXT:    10588:        nop
// CHECK-NEXT:    1058c:        nop
// CHECK-NEXT:    10590:        nop
// CHECK-NEXT:    10594:        ret

// CHECK: 0000000000010598 <localfunc>:
// CHECK-NEXT:    10598:        nop
// CHECK-NEXT:    1059c:        nop
// CHECK-NEXT:    105a0:        nop
// CHECK-NEXT:    105a4:        ret

// CHECK: 00000000000105a8 <caller>:
// CHECK-NEXT:    105a8:        bl      0x10620 <importfunc+0x10620>
// CHECK-NEXT:    105ac:        bl      0x10588 <hiddenfunc>
// CHECK-NEXT:    105b0:        bl      0x10598 <localfunc>
// CHECK-NEXT:    105b4:        bl      0x10630 <importfunc+0x10630>
// CHECK-NEXT:    105b8:        ret
// CHECK-NEXT:    105bc:        adrp    c0, #0x10000
// CHECK-NEXT:    105c0:        ldr     c0, [c0, #0x830]
// CHECK-NEXT:    105c4:        adrp    c1, #0x10000
// CHECK-NEXT:    105c8:        ldr     c1, [c1, #0x840]
// CHECK-NEXT:    105cc:        adrp    c2, #0x10000
// CHECK-NEXT:    105d0:        ldr     c2, [c2, #0x850]
// CHECK-NEXT:    105d4:        adrp    c3, #0x10000
// CHECK-NEXT:    105d8:        ldr     c3, [c3, #0x860]
// CHECK-NEXT:    105dc:        adrp    c4, #0x10000
// CHECK-NEXT:    105e0:        ldr     c4, [c4, #0x870]
// CHECK-NEXT:    105e4:        adrp    c5, #0x10000
// CHECK-NEXT:    105e8:        ldr     c5, [c5, #0x880]
// CHECK-NEXT:    105ec:        adrp    c17, #0x10000
// CHECK-NEXT:    105f0:        ldr     c17, [c17, #0x890]

// CHECK: 0000000000010600 <.plt>:
// CHECK-NEXT:    10600:        stp     c16, c30, [csp, #-0x20]!
// CHECK-NEXT:    10604:        adrp    c16, #0x20000
// CHECK-NEXT:    10608:        ldr     c17, [c16, #0x8e0]
// CHECK-NEXT:    1060c:        add     c16, c16, #0x8e0
// CHECK-NEXT:    10610:        br      c17
// CHECK-NEXT:    10614:        nop
// CHECK-NEXT:    10618:        nop
// CHECK-NEXT:    1061c:        nop
// CHECK-NEXT:    10620:        adrp    c16, #0x20000
// CHECK-NEXT:    10624:        add     c16, c16, #0x8f0
// CHECK-NEXT:    10628:        ldr     c17, [c16, #0x0]
// CHECK-NEXT:    1062c:        br      c17
// CHECK-NEXT:    10630:        adrp    c16, #0x20000
// CHECK-NEXT:    10634:        add     c16, c16, #0x900
// CHECK-NEXT:    10638:        ldr     c17, [c16, #0x0]
// CHECK-NEXT:    1063c:        br      c17

// RELS: Relocations [
// RELS-NEXT:   Section (5) .rela.dyn {
/// .capinit hiddenfunc
// RELS-NEXT:     0x20650 R_MORELLO_RELATIVE - 0x0
/// .capinit localfunc
// RELS-NEXT:     0x20660 R_MORELLO_RELATIVE - 0x0
/// .capinit hidden
// RELS-NEXT:     0x20690 R_MORELLO_RELATIVE - 0x0
/// .capinit local
// RELS-NEXT:     0x206A0 R_MORELLO_RELATIVE - 0x0
/// .capinit hiddenfunc + 8
// RELS-NEXT:     0x206D0 R_MORELLO_RELATIVE - 0x8
/// .capinit localfunc + 12
// RELS-NEXT:     0x206E0 R_MORELLO_RELATIVE - 0xC
/// .capinit hidden + 2
// RELS-NEXT:     0x20710 R_MORELLO_RELATIVE - 0x2
/// .capinit import + 4
// RELS-NEXT:     0x20720 R_MORELLO_RELATIVE - 0x3
/// .got hiddenfunc
// RELS-NEXT:     0x20840 R_MORELLO_RELATIVE - 0x0
/// .got localfunc
// RELS-NEXT:     0x20850 R_MORELLO_RELATIVE - 0x0
/// .got hidden
// RELS-NEXT:     0x20880 R_MORELLO_RELATIVE - 0x0
// RELS-NEXT:     0x206B0 R_MORELLO_CAPINIT import 0x0
// RELS-NEXT:     0x20730 R_MORELLO_CAPINIT import 0x4
// RELS-NEXT:     0x20890 R_MORELLO_GLOB_DAT import 0x0
// RELS-NEXT:     0x20670 R_MORELLO_CAPINIT importfunc 0x0
// RELS-NEXT:     0x206F0 R_MORELLO_CAPINIT importfunc 0x10
// RELS-NEXT:     0x20860 R_MORELLO_GLOB_DAT importfunc 0x0
// RELS-NEXT:     0x20680 R_MORELLO_CAPINIT global 0x0
// RELS-NEXT:     0x20700 R_MORELLO_CAPINIT global 0x1
// RELS-NEXT:     0x20870 R_MORELLO_GLOB_DAT global 0x0
// RELS-NEXT:     0x20640 R_MORELLO_CAPINIT globalfunc 0x0
// RELS-NEXT:     0x206C0 R_MORELLO_CAPINIT globalfunc 0x4
// RELS-NEXT:     0x20830 R_MORELLO_GLOB_DAT globalfunc 0x0
// RELS-NEXT:   }
// RELS-NEXT:   Section (6) .rela.plt {
// RELS-NEXT:     0x308F0 R_MORELLO_JUMP_SLOT globalfunc 0x0
// RELS-NEXT:     0x30900 R_MORELLO_JUMP_SLOT importfunc 0x0

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
