// RUN: %clang_cc1 -Wall -Werror -triple aarch64-none-elf -target-feature +c64 -target-abi purecap -disable-O0-optnone -emit-llvm -o - %s | opt -S -mem2reg | FileCheck %s

void test_eh_return_data_regno()
{
  // CHECK: store volatile i32 198
  // CHECK: store volatile i32 1
  volatile int res;
  res = __builtin_eh_return_data_regno(0);
  res = __builtin_eh_return_data_regno(1);
}
