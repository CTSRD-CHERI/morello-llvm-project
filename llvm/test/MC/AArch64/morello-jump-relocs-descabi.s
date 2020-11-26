// RUN: llvm-mc -triple=aarch64-none-elf -mattr=+morello -target-abi purecap -cheri-cap-table-abi=fn-desc %s -filetype=obj -o - | llvm-objdump --mattr=+morello -d - -r | FileCheck %s

.arch armv8-a+c64
.globl biz
.type biz, @function
biz:
// CHECK: bl 0x0
// CHECK-NEXT: R_MORELLO_DESC_GLOBAL_CALL26	bar
  bl bar
// CHECK: b 0x4
// CHECK-NEXT: R_MORELLO_DESC_GLOBAL_JUMP26	baz
  b baz

.arch morello
.globl bif
.type bif, @function
bif:
// CHECK: bl 0x8
// CHECK-NEXT: R_AARCH64_DESC_GLOBAL_CALL26	bar
  bl bar
// CHECK: b 0xc
// CHECK-NEXT: R_AARCH64_DESC_GLOBAL_JUMP26	baz
  b baz
