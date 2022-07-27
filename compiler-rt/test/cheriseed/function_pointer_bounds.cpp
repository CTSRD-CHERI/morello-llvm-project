// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t && not %run %t |& FileCheck %s

#include "test.h"

void func(void) {}

typedef void (*fun_ptr)();

TEST_MAIN() {
  char *ptr = (char *)&func;
  ++ptr;
  fun_ptr fptr = (fun_ptr)ptr;
  // CHECK: Runtime Error detected by CHERIseed
  // CHECK: Prevented out-of-bounds access with capability
  fptr();
}
