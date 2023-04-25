// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t -cheri-bounds=subobject-safe -DLENGTH=1 -DINDEX=1 && not %run %t |& FileCheck %s
// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t -cheri-bounds=subobject-safe -DLENGTH=1 -DINDEX=5 && not %run %t |& FileCheck %s
// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t -cheri-bounds=subobject-safe -DLENGTH=1 -DINDEX=-1 && not %run %t |& FileCheck %s
// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t -cheri-bounds=subobject-safe -DLENGTH=1024 -DINDEX=1024 && not %run %t |& FileCheck %s
// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t -cheri-bounds=subobject-safe -DLENGTH=1024 -DINDEX=1034 && not %run %t |& FileCheck %s
// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t -cheri-bounds=subobject-safe -DLENGTH=1024 -DINDEX=-1 && not %run %t |& FileCheck %s

#include "test.h"

#pragma clang diagnostic ignored "-Warray-bounds"

TEST_MAIN() {
  struct {
    int x;
    char str[LENGTH];
    int z;
  } local;
  // CHECK: Prevented out-of-bounds access with capability
  TEST_USED(local.str[INDEX]);
}
