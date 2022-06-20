// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t && %run %t |& FileCheck %s
// XFAIL: *

#include "test.h"

int global;

TEST_MAIN() {
  void (*fn_ptr)() = (void (*)()) & global;
  // FIXME: needs to be implemented
  // CHECK: Capability is missing required permission(s)
  // CHECK: EXECUTE
  (fn_ptr)();
}
