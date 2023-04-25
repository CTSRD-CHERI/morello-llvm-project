// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t && %run %t |& FileCheck %s
// XFAIL: *

#include "test.h"

int global = 42;
int *const global_const_ptr = &global;

TEST_MAIN() {
  int data;
  int **write_to_const = (int **)&global_const_ptr;
  // FIXME: needs to be implemented
  // CHECK: Capability is missing required permission(s)
  // CHECK: STORE
  *write_to_const = &data;
}
