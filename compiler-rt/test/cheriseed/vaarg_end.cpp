// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t && not %run %t |& FileCheck %s
// RUN: %clangxx_cheriseed_purecap %s -g -O2 -o %t && not %run %t |& FileCheck %s
// RUN: %clangxx_cheriseed_purecap -flegacy-pass-manager %s -g -O0 -o %t && not %run %t |& FileCheck %s
// RUN: %clangxx_cheriseed_purecap -flegacy-pass-manager %s -g -O2 -o %t && not %run %t |& FileCheck %s

#include "test.h"

NOINLINE
void access_after_end(__builtin_va_list lst) {
  __builtin_va_end(lst);
  // TODO: This should be a tag violation
  // CHECK: Runtime Error detected by CHERIseed
  // CHECK: Capability is missing required permission(s)
  // CHECK: Missing permission(s):
  // CHECK: r [LOAD]
  TEST_USED(__builtin_va_arg(lst, int));
}

NOINLINE
void callee(int n, ...) {
  __builtin_va_list lst;
  __builtin_va_start(lst, n);
  access_after_end(lst);
}

TEST_MAIN() {
  callee(1, 2);
}
