// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t && not %run %t |& FileCheck %s
// XFAIL: *

#include "test.h"

TEST_MAIN() {
  const int stack_const = 42;
  int *write_to_const = (int *)&stack_const;
  // CHECK: Capability is missing required permission(s)
  // CHECK: STORE
  *write_to_const = 84;
}
