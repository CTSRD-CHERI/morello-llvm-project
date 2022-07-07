// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t -DLENGTH=1 -DINDEX=1 && not %run %t |& FileCheck %s
// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t -DLENGTH=1 -DINDEX=5 && not %run %t |& FileCheck %s
// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t -DLENGTH=1 -DINDEX=-1 && not %run %t |& FileCheck %s
// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t -DLENGTH=1024 -DINDEX=1024 && not %run %t |& FileCheck %s
// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t -DLENGTH=1024 -DINDEX=1034 && not %run %t |& FileCheck %s
// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t -DLENGTH=1024 -DINDEX=-1 && not %run %t |& FileCheck %s

#include "test.h"

#pragma clang diagnostic ignored "-Warray-bounds"

char global_array[LENGTH];

TEST_MAIN() {
  // CHECK: Runtime Error detected by CHERIseed
  // CHECK: Prevented out-of-bounds access with capability
  TEST_USED(global_array[INDEX]);
}
