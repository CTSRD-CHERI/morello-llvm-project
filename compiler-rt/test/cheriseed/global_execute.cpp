// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t && not %run %t |& FileCheck %s

#include "test.h"

int global;

TEST_MAIN() {
  void (*fn_ptr)() = (void (*)()) & global;
  // CHECK: Capability is missing required permission(s)
  // CHECK: EXECUTE
  (fn_ptr)();
}
