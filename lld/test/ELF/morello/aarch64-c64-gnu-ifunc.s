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

.type baz STT_GNU_IFUNC
.globl baz
.size baz, 4
baz:
 ret

.globl _start
_start:
 bl foo
 bl bar
 adr c0, baz
 add x2, x2, :lo12:__rela_iplt_start
 add x2, x2, :lo12:__rela_iplt_end

// Contents of section .got.plt:
// CHECK:      2202b0 60022100 00000000 80000100 00000004
// CHECK-NEXT: 2202c0 60022100 00000000 80000100 00000004
// CHECK-NEXT: 2202d0 60022100 00000000 80000100 00000004

// CHECK-LABEL: <foo>:
// CHECK-NEXT:   210261:        <unknown>

// CHECK-LABEL: <bar>:
// CHECK-NEXT:   210265:        <unknown>

/// No label; baz is redirected to the .iplt entry
// CHECK-NEXT:   210269:        <unknown>

// CHECK-LABEL: <_start>:
// CHECK-NEXT:   21026c:  bl      0x210280
// CHECK-NEXT:            bl      0x210290
// CHECK-NEXT:            adr     c0, 0x2102a1
// CHECK-NEXT:            add     x2, x2, #0x210
// CHECK-NEXT:            add     x2, x2, #0x258

// CHECK-LABEL: <.iplt>:
// CHECK-NEXT:   210280:  adrp c16, 0x220000
// CHECK-NEXT:            add  c16, c16, #0x2b0
// CHECK-NEXT:            ldr  c17, [c16, #0x0]
// CHECK-NEXT:            br   c17
// CHECK-NEXT:            adrp c16, 0x220000
// CHECK-NEXT:            add  c16, c16, #0x2c0
// CHECK-NEXT:            ldr  c17, [c16, #0x0]
// CHECK-NEXT:            br   c17
// CHECK-LABEL: <baz>:
// CHECK-NEXT:   2102a0:  adrp c16, 0x220000
// CHECK-NEXT:            add  c16, c16, #0x2d0
// CHECK-NEXT:            ldr  c17, [c16, #0x0]
// CHECK-NEXT:            br   c17

// RELANDSYM: Relocations [
// RELANDSYM-NEXT:   Section {{.*}} .rela.dyn {
// RELANDSYM-NEXT:     0x2202B0 R_MORELLO_IRELATIVE - 0x1
// RELANDSYM-NEXT:     0x2202C0 R_MORELLO_IRELATIVE - 0x5
// RELANDSYM-NEXT:     0x2202D0 R_MORELLO_IRELATIVE - 0x9

// RELANDSYM:          Name: __rela_iplt_start
// RELANDSYM-NEXT:     Value: 0x200210
// RELANDSYM-NEXT:     Size: 72
// RELANDSYM-NEXT:     Binding: Local (0x0)
// RELANDSYM-NEXT:     Type: None (0x0)
// RELANDSYM-NEXT:     Other [ (0x2)
// RELANDSYM-NEXT:       STV_HIDDEN (0x2)
// RELANDSYM-NEXT:     ]
// RELANDSYM-NEXT:     Section: .rela.dyn
// RELANDSYM-NEXT:   }
// RELANDSYM-NEXT:   Symbol {
// RELANDSYM-NEXT:     Name: __rela_iplt_end
// RELANDSYM-NEXT:     Value: 0x200258
// RELANDSYM-NEXT:     Size: 0
// RELANDSYM-NEXT:     Binding: Local (0x0)
// RELANDSYM-NEXT:     Type: None (0x0)
// RELANDSYM-NEXT:     Other [ (0x2)
// RELANDSYM-NEXT:       STV_HIDDEN (0x2)
// RELANDSYM-NEXT:     ]
// RELANDSYM-NEXT:     Section: .rela.dyn
