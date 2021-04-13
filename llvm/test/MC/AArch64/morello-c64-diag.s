// RUN: not llvm-mc -triple arm64 -mattr=+morello,+c64 -show-encoding < %s 2>&1 | FileCheck %s

        adrp c5, #-2147487744
// CHECK: expected label or encodable integer pc offset
// CHECK-NEXT: adrp c5, #-2147487744
        adrdp c5, #-1
// CHECK: expected encodable integer data offset
// CHECK-NEXT: adrdp c5, #-1

        adrdp c5, #4294967296
// CHECK: expected encodable integer data offset
// CHECK-NEXT: adrdp c5, #4294967296

        adrp x0, #0
// CHECK: invalid operand for instruction
// CHECK-NEXT: adrp x0, #0

        adr x0, #0
// CHECK: invalid operand for instruction
// CHECK-NEXT: adr x0, #0

        dc zva, x0
// CHECK: error: expected capability register
// CHECK-NEXT: dc zva, x0
