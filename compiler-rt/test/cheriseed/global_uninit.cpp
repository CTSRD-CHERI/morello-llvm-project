// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t && not %run %t |& FileCheck %s

#include "test.h"

int *global_uninit_ptr;

TEST_MAIN() {
  // CHECK: Capability is untagged at
  int read_uninitialized = *global_uninit_ptr;
}
