// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=aarch64-none-elf -mattr=+c64,+morello %s -o %t.o
// RUN: ld.lld --morello-c64-plt -static %t.o -o %tout
// RUN: llvm-objdump -s -d --print-imm-hex --no-show-raw-insn --triple=aarch64-none-elf --mattr=+morello %tout | FileCheck %s
// RUN: llvm-readobj -r --symbols %tout | FileCheck %s --check-prefix=RELANDSYM
.text
.type foo STT_GNU_IFUNC
.globl foo
.size foo, 4
foo:
 ret

.type bar STT_GNU_IFUNC
.globl bar
.size bar, 4
bar:
 ret

.globl _start
_start:
 bl foo
 bl bar
 add x2, x2, :lo12:__rela_iplt_start
 add x2, x2, :lo12:__rela_iplt_end

// Contents of section .got.plt:
// CHECK:      2201f0 b1012100 00000000 04000000 00000004
// CHECK-NEXT: 220200 b5012100 00000000 04000000 00000004

// CHECK: 00000000002101b1 <foo>:
// CHECK-NEXT:   2101b1:        <unknown>

// CHECK: 00000000002101b5 <bar>:
// CHECK-NEXT:   2101b5:        <unknown>

// CHECK: 00000000002101b8 <_start>:
// CHECK-NEXT:   2101b8:        bl      0x2101d0
// CHECK-NEXT:   2101bc:        bl      0x2101e0
// CHECK-NEXT:   2101c0:        add     x2, x2, #0x180
// CHECK-NEXT:   2101c4:        add     x2, x2, #0x1b0

// CHECK: 00000000002101d0 <.iplt>:
// CHECK-NEXT:   2101d0:        adrp    c16, #0x10000
// CHECK-NEXT:   2101d4:        add     c16, c16, #0x1f0
// CHECK-NEXT:   2101d8:        ldr     c17, [c16, #0x0]
// CHECK-NEXT:   2101dc:        br      c17
// CHECK-NEXT:   2101e0:        adrp    c16, #0x10000
// CHECK-NEXT:   2101e4:        add     c16, c16, #0x200
// CHECK-NEXT:   2101e8:        ldr     c17, [c16, #0x0]
// CHECK-NEXT:   2101ec:        br      c17

// RELANDSYM: Relocations [
// RELANDSYM-NEXT:   Section (1) .rela.dyn {
// RELANDSYM-NEXT:     0x2201F0 R_MORELLO_IRELATIVE - 0x2101B1
// RELANDSYM-NEXT:     0x220200 R_MORELLO_IRELATIVE - 0x2101B5

// RELANDSYM:          Name: __rela_iplt_end
// RELANDSYM-NEXT:     Value: 0x2001B0
// RELANDSYM-NEXT:     Size: 0
// RELANDSYM-NEXT:     Binding: Local (0x0)
// RELANDSYM-NEXT:     Type: None (0x0)
// RELANDSYM-NEXT:     Other [ (0x2)
// RELANDSYM-NEXT:       STV_HIDDEN (0x2)
// RELANDSYM-NEXT:     ]
// RELANDSYM-NEXT:     Section: .rela.dyn (0x1)
// RELANDSYM-NEXT:   }
// RELANDSYM-NEXT:   Symbol {
// RELANDSYM-NEXT:     Name: __rela_iplt_start
// RELANDSYM-NEXT:     Value: 0x200180
// RELANDSYM-NEXT:     Size: 0
// RELANDSYM-NEXT:     Binding: Local (0x0)
// RELANDSYM-NEXT:     Type: None (0x0)
// RELANDSYM-NEXT:     Other [ (0x2)
// RELANDSYM-NEXT:       STV_HIDDEN (0x2)
// RELANDSYM-NEXT:     ]
// RELANDSYM-NEXT:     Section: .rela.dyn (0x1)
