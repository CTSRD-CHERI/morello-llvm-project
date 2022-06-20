// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t && not %run %t |& FileCheck %s

#include "test.h"

TEST_MAIN() {
  int *stack_uninit_ptr;
  // CHECK: Capability is missing required permission(s)
  // CHECK: LOAD
  int read_uninitialized = *stack_uninit_ptr;
}
