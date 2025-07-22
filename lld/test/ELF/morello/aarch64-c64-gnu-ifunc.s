// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=aarch64-none-elf -target-abi purecap -mattr=+c64,+morello %s -o %t.o
// RUN: ld.lld  -static %t.o -o %tout
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
// CHECK:      220270 c0012000 00000000 00010200 00000004
// CHECK-NEXT: 220280 c0012000 00000000 00010200 00000004

// CHECK-LABEL: <foo>:
// CHECK-NEXT:   210239:        <unknown>

// CHECK-LABEL: <bar>:
// CHECK-NEXT:   21023d:        <unknown>

// CHECK-LABEL: <_start>:
// CHECK-NEXT:   210240:  bl      0x210250
// CHECK-NEXT:            bl      0x210260
// CHECK-NEXT:            add     x2, x2, #0x208
// CHECK-NEXT:            add     x2, x2, #0x238

// CHECK-LABEL: <.iplt>:
// CHECK-NEXT:   210250:  adrp c16, 0x220000
// CHECK-NEXT:            add  c16, c16, #0x270
// CHECK-NEXT:            ldr  c17, [c16, #0x0]
// CHECK-NEXT:            br   c17
// CHECK-NEXT:            adrp c16, 0x220000
// CHECK-NEXT:            add  c16, c16, #0x280
// CHECK-NEXT:            ldr  c17, [c16, #0x0]
// CHECK-NEXT:            br   c17

// RELANDSYM: Relocations [
// RELANDSYM-NEXT:   Section {{.*}} .rela.dyn {
// RELANDSYM-NEXT:     0x220270 R_MORELLO_IRELATIVE - 0x10079
// RELANDSYM-NEXT:     0x220280 R_MORELLO_IRELATIVE - 0x1007D

// RELANDSYM:          Name: __rela_iplt_start
// RELANDSYM-NEXT:     Value: 0x200208
// RELANDSYM-NEXT:     Size: 48
// RELANDSYM-NEXT:     Binding: Local (0x0)
// RELANDSYM-NEXT:     Type: None (0x0)
// RELANDSYM-NEXT:     Other [ (0x2)
// RELANDSYM-NEXT:       STV_HIDDEN (0x2)
// RELANDSYM-NEXT:     ]
// RELANDSYM-NEXT:     Section: .rela.dyn
// RELANDSYM-NEXT:   }
// RELANDSYM-NEXT:   Symbol {
// RELANDSYM-NEXT:     Name: __rela_iplt_end
// RELANDSYM-NEXT:     Value: 0x200238
// RELANDSYM-NEXT:     Size: 0
// RELANDSYM-NEXT:     Binding: Local (0x0)
// RELANDSYM-NEXT:     Type: None (0x0)
// RELANDSYM-NEXT:     Other [ (0x2)
// RELANDSYM-NEXT:       STV_HIDDEN (0x2)
// RELANDSYM-NEXT:     ]
// RELANDSYM-NEXT:     Section: .rela.dyn
