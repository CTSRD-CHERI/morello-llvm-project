// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t && not %run %t |& FileCheck %s
// XFAIL: *

#include "test.h"

TEST_MAIN() {
  int local = 42;
  int *const stack_const_ptr = &local;

  int data;
  int **write_to_const = (int **)&stack_const_ptr;
  // CHECK: Capability is missing required permission(s)
  // CHECK: STORE
  *write_to_const = &data;
}
