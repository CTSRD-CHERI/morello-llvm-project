// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=aarch64-none-elf -mattr=+morello,+c64 -target-abi purecap  %s -o %t.o
// RUN: ld.lld %t.o -shared -o %t
// RUN: llvm-objdump %t -d --mattr=+morello --no-show-raw-insn --no-leading-addr | FileCheck %s

  .section	my_section,"awx"
  .p2align	4
  .global __start
  .type __start, %function
data_cap:
  .chericap	0
__start:
  ldr	c9, data_cap
  br	c9


// CHECK: <__start>:
// CHECK-NEXT:  ldr	c9, #-0x10
// CHECK-NEXT:  br	c9
