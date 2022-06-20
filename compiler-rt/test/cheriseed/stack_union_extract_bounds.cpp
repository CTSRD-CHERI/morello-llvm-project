// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t -cheri-bounds=subobject-safe -DLENGTH=1 -DINDEX=1 && not %run %t |& FileCheck %s
// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t -cheri-bounds=subobject-safe -DLENGTH=1 -DINDEX=5 && not %run %t |& FileCheck %s
// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t -cheri-bounds=subobject-safe -DLENGTH=1 -DINDEX=-1 && not %run %t |& FileCheck %s
// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t -cheri-bounds=subobject-safe -DLENGTH=1024 -DINDEX=1024 && not %run %t |& FileCheck %s
// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t -cheri-bounds=subobject-safe -DLENGTH=1024 -DINDEX=1034 && not %run %t |& FileCheck %s
// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t -cheri-bounds=subobject-safe -DLENGTH=1024 -DINDEX=-1 && not %run %t |& FileCheck %s
// XFAIL: *

#include "test.h"

#pragma clang diagnostic ignored "-Warray-bounds"

TEST_MAIN() {
  union {
    char str[LENGTH];
    long lng[LENGTH];
  } local;

  char *str_ptr = local.str;
  // CHECK: Prevented out-of-bounds access with capability
  // Taking the address of a union member should restrict the bounds
  TEST_USED(str_ptr[INDEX]);
}
