// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t && not %run %t |& FileCheck %s

#include "test.h"

TEST_MAIN() {
  int local = 42;
  void (*fn_ptr)() = (void (*)()) & local;
  // CHECK: Capability is missing required permission(s)
  // CHECK: EXECUTE
  (fn_ptr)();
}
