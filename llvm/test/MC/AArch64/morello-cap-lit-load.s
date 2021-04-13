// RUN: not llvm-mc -triple=aarch64-none-elf -mattr=+morello %s 2>&1 | FileCheck %s
// RUN: not llvm-mc -triple=aarch64-none-elf -mattr=+morello,+c64 %s 2>&1 | FileCheck %s

ldr c0, =loc
// CHECK: error: Cannot use capability for literal pool loads
