// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=aarch64-none-elf -target-abi purecap -mattr=+c64,+morello %s -o %t.o
// RUN: ld.lld %t.o -o %t
// RUN: llvm-objdump --mattr=+morello -d --print-imm-hex --no-show-raw-insn %t | FileCheck %s --check-prefix=RELAX
// RUN: ld.lld --shared %t.o -o %t.so
// RUN: llvm-objdump --mattr=+morello -d --print-imm-hex --no-show-raw-insn %t.so --section-headers | FileCheck %s --check-prefix=NORELAX
// RUN: llvm-readobj --relocs %t.so | FileCheck %s

 .text
 .global foo
 .section .tdata,"awT",%progbits
 .align 2
 .type foo, %object
 .size foo, 4
foo:
 .word 5
 .text

.text
 .global bar
 .section .tdata,"awT",%progbits
 .align 2
 .type bar, %object
 .size bar, 4
bar:
 .word 5
 .text

 .globl _start
 .type _start, %function
 .size _start, 16
_start:
 adrp c0, :gottprel:foo
 add c0, c0, #:gottprel_lo12:foo
 ldp x0, x1, [c0]

 adrp c0, :gottprel:bar
 add c0, c0, #:gottprel_lo12:bar
 ldp x0, x1, [c0]

// RELAX-LABEL: <_start>:
// RELAX-NEXT: 210280: adrp c0, 0x220000
// RELAX-NEXT: 210284: add  c0, c0, #0x2a0
// RELAX-NEXT: 210288: ldp  x0, x1, [c0]
// RELAX-NEXT: 21028c: adrp c0, 0x220000
// RELAX-NEXT: 210290: add  c0, c0, #0x2b0
// RELAX-NEXT: 210294: ldp  x0, x1, [c0]

// NORELAX-LABEL: Sections:
// NORELAX: .got 00000020 0000000000020490 DATA
// NORELAX-LABEL: <_start>:
// NORELAX-NEXT: 103c0: adrp c0, 0x20000
/// Lower part of GOT address:
// NORELAX-NEXT: 103c4: add  c0, c0, #0x490
// NORELAX-NEXT: 103c8: ldp  x0, x1, [c0]
// NORELAX-NEXT: 103cc: adrp c0, 0x20000
/// Lower part of GOT address:
// NORELAX-NEXT: 103d0: add  c0, c0, #0x4a0
// NORELAX-NEXT: 103d4: ldp  x0, x1, [c0]

// CHECK: Relocations [
// CHECK-NEXT:   Section {{.*}} .rela.dyn {
// CHECK-NEXT:     0x20490 R_MORELLO_TLS_TPREL128 foo 0x0
// CHECK-NEXT:     0x204A0 R_MORELLO_TLS_TPREL128 bar 0x0
