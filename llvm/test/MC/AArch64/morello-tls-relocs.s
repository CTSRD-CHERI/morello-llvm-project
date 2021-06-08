// RUN: llvm-mc -triple=aarch64-none-elf -mattr=+morello,+c64  %s -filetype=obj -o - | llvm-objdump --mattr=+morello -d - -r | FileCheck %s
// RUN: llvm-mc -triple=aarch64-none-elf -mattr=+morello,+c64  -target-abi purecap %s -filetype=obj -o - | llvm-objdump -d - -r | FileCheck %s

    .globl var
    .text
// CHECK: adrp c0, #0
// CHECK-NEXT: R_MORELLO_TLSDESC_ADR_PAGE20 var
// CHECK: ldr c1, [c0, #0]
// CHECK-NEXT: R_MORELLO_TLSDESC_LD128_LO12 var
// CHECK: add c0, c0, #0
// CHECK-NEXT: R_AARCH64_TLSDESC_ADD_LO12 var
// CHECK: blr c1
// CHECK-NEXT: R_MORELLO_TLSDESC_CALL var
    adrp  c0, :tlsdesc:var
    ldr   c1, [c0, #:tlsdesc_lo12:var]
    add   c0, c0, #:tlsdesc_lo12:var
    .tlsdesccall var
    blr   c1
