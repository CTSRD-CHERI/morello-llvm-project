// RUN: llvm-mc -triple=aarch64-none-elf -mattr=+morello,+c64  %s -filetype=obj -o - | llvm-objdump --mattr=+morello -d - -r | FileCheck %s
// RUN: llvm-mc -triple=aarch64-none-elf -mattr=+morello,+c64  -target-abi purecap %s -filetype=obj -o - | llvm-objdump -d - -r | FileCheck %s

    .globl var
    .text
// CHECK: adrp c0, 0x0 <var>
// CHECK-NEXT: R_MORELLO_TLSDESC_ADR_PAGE20 var
// CHECK: ldr c1, [c0, #0x0]
// CHECK-NEXT: R_MORELLO_TLSDESC_LD128_LO12 var
// CHECK: add c0, c0, #0x0
// CHECK-NEXT: R_AARCH64_TLSDESC_ADD_LO12 var
// CHECK: blr c1
// CHECK-NEXT: R_MORELLO_TLSDESC_CALL var
    adrp  c0, :tlsdesc:var
    ldr   c1, [c0, #:tlsdesc_lo12:var]
    add   c0, c0, #:tlsdesc_lo12:var
    .tlsdesccall var
    blr   c1

    adrp c11, :gottprel:var
    add c10, c0, #:gottprel_lo12:var
// CHECK: adrp c11, 0x0 <var>
// CHECK-NEXT: R_MORELLO_TLSIE_ADR_GOTTPREL_PAGE20 var
// CHECK: add c10, c0, #0x0
// CHECK-NEXT: R_MORELLO_TLSIE_ADD_LO12 var
