// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t && not %run %t |& FileCheck %s

#include "test.h"

#pragma clang diagnostic ignored "-Wcheri-capability-misuse"

TEST_MAIN() {
  long not_cap = 42;
  int *ptr = (int *)not_cap;
  // CHECK: Capability is untagged at
  int x = *ptr;
}
