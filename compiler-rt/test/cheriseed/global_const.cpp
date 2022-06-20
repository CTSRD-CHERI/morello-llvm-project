// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t && not %run %t |& FileCheck %s
// XFAIL: *

#include "test.h"

const int const_global = 42;

TEST_MAIN() {
  int *write_to_const = (int *)&const_global;
  // FIXME: needs to be implemented
  // CHECK: Capability is missing required permission(s)
  // CHECK: STORE
  *write_to_const = 84;
}
