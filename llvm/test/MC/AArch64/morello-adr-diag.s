// RUN: not llvm-mc -triple aarch64-none-linux-gnu -show-encoding -mattr=+morello < %s 2>&1 | FileCheck %s

// Verify that we reject the C64 Morello variants of adrp. The diagnostics are currently not
// useful here because we can match from too many different architectures.

// CHECK: invalid operand for instruction
// CHECK-NEXT: adr c0, #0
        adr c0, #0
// CHECK: invalid operand for instruction
// CHECK-NEXT: adrp c0, #0
        adrp c0, #0
// CHECK: unrecognized instruction mnemonic
// CHECK-NEXT: adrdp c0, #0
        adrdp c0, #0
