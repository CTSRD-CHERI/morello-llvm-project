// RUN: not llvm-mc -triple arm64 -mattr=+morello -show-encoding < %s 2>&1 | FileCheck %s

// CHECK: expected compatible register, symbol or integer in range [0, 4095]
// CHECK-NEXT:  add c3, c27, #4097
  add c3, c27, #4097

// CHECK:  expected compatible register, symbol or integer in range [0, 4095]
// CHECK-NEXT:  sub c3, c27, #4097
  sub c3, c27, #4097

  add c3, c3, w4
// CHECK: too few operands for instruction
// CHECK-NEXT:   add c3, c3, w4

  add c3, c3, x4, sxtw #2
// CHECK: expected 'sxtx' 'uxtx' or 'lsl' with optional integer in range [0, 4]
// CHECK-NEXT:  add c3, c3, x4, sxtw #2

  add c3, c3, x4, sxtx #5
// CHECK: expected 'sxtx' 'uxtx' or 'lsl' with optional integer in range [0, 4]
// CHECK-NEXT: add c3, c3, x4, sxtx #5

  ldr c3, [x7, w23]
// CHECK: expected 'uxtw' or 'sxtw' with optional shift of #0 or #4
// CHECK-NEXT: ldr c3, [x7, w23]
  ldr c3, [x7, w23, lsl]
// CHECK: expected #imm after shift specifier
// CHECK-NEXT: ldr c3, [x7, w23, lsl]
  ldr c3, [x7, w23, lsl #0]
// CHECK: expected 'uxtw' or 'sxtw' with optional shift of #0 or #4
// CHECK-NEXT: ldr c3, [x7, w23, lsl #0]
  ldr c3, [x7, x23, lsl]
// CHECK: expected #imm after shift specifier
// CHECK-NEXT: ldr c3, [x7, x23, lsl] 
  ldr c3, [x7, x23, lsl #3]
// CHECK: expected 'lsl' or 'sxtx' with optional shift of #0 or #4
// CHECK: ldr c3, [x7, x23, lsl #3]
  ldr c3, [x7, x23, sxtw]
// CHECK: expected 'lsl' or 'sxtx' with optional shift of #0 or #4
// CHECK-NEXT: ldr c3, [x7, x23, sxtw]
  ldr c3, [x7, x23, uxtw]
// CHECK: expected 'lsl' or 'sxtx' with optional shift of #0 or #4
// CHECK-NEXT: ldr c3, [x7, x23, uxtw]

  str c3, [x7, w23]
// CHECK: expected 'uxtw' or 'sxtw' with optional shift of #0 or #4
// CHECK-NEXT: str c3, [x7, w23]
  str c3, [x7, w23, lsl]
// CHECK: expected #imm after shift specifier
// CHECK-NEXT: str c3, [x7, w23, lsl]
  str c3, [x7, w23, lsl #0]
// CHECK: expected 'uxtw' or 'sxtw' with optional shift of #0 or #4
// CHECK-NEXT: str c3, [x7, w23, lsl #0]
  str c3, [x7, x23, lsl]
// CHECK: expected #imm after shift specifier
// CHECK-NEXT: str c3, [x7, x23, lsl] 
  str c3, [x7, x23, lsl #3]
// CHECK: expected 'lsl' or 'sxtx' with optional shift of #0 or #4
// CHECK: str c3, [x7, x23, lsl #3]
  str c3, [x7, x23, sxtw]
// CHECK: expected 'lsl' or 'sxtx' with optional shift of #0 or #4
// CHECK-NEXT: str c3, [x7, x23, sxtw]
  str c3, [x7, x23, uxtw]
// CHECK: expected 'lsl' or 'sxtx' with optional shift of #0 or #4
// CHECK-NEXT: str c3, [x7, x23, uxtw]

  scbnds c4, c7, #65
// CHECK: immediate must be an integer in range [0, 63] with optional shift of #0 or #4 or a multiple of 16 in range [0, 1008]
// CHECK-NEXT: scbnds c4, c7, #65
  scbnds c4, c7, #1024
// CHECK: immediate must be an integer in range [0, 63] with optional shift of #0 or #4 or a multiple of 16 in range [0, 1008]
// CHECK-NEXT: scbnds c4, c7, #1024

  cbz c0, #0
// CHECK: invalid operand for instruction
// CHECK-NEXT: cbz c0, #0
  cbnz c0, #0
// CHECK: invalid operand for instruction
// CHECK-NEXT: cbnz c0, #0

  dc zva, c0
// CHECK:  error: invalid operand for instruction
// CHECK-NEXT: dc zva, c0

  seal c1, c1, #
// CHECK:  error: Expected integer value
// CHECK-NEXT: seal c1, c1, #

  clrperm c1, c1, #
// CHECK:  error: Expected integer value
// CHECK-NEXT: clrperm c1, c1, #
