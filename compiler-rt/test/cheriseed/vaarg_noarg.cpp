// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t && not %run %t |& FileCheck %s
// RUN: %clangxx_cheriseed_purecap %s -g -O2 -o %t && not %run %t |& FileCheck %s
// RUN: %clangxx_cheriseed_purecap -flegacy-pass-manager %s -g -O0 -o %t && not %run %t |& FileCheck %s
// RUN: %clangxx_cheriseed_purecap -flegacy-pass-manager %s -g -O2 -o %t && not %run %t |& FileCheck %s

#include "test.h"

NOINLINE
void callee(int n, ...) {
  __builtin_va_list lst;
  __builtin_va_start(lst, n);
  // CHECK: Runtime Error detected by CHERIseed
  // CHECK: Prevented out-of-bounds access
  // CHECK: Requested range was 0x000000000000-0x000000000004
  TEST_USED(__builtin_va_arg(lst, int));
}

TEST_MAIN() {
  callee(1);
}
