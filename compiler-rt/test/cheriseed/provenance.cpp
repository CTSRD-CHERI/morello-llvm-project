// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t && not %run %t |& FileCheck %s

#include "test.h"

#pragma clang diagnostic ignored "-Wcheri-capability-misuse"

TEST_MAIN() {
  long not_cap = 42;
  int *ptr = (int *)not_cap;
  // FIXME: we would want to check for tag later.
  // CHECK: Capability is missing required permission(s)
  // CHECK: LOAD
  int x = *ptr;
}
