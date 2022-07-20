// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t && %run %t

#include "test.h"

#pragma clang diagnostic ignored "-Warray-bounds"

TEST_MAIN() {
  // Turn bounds checks OFF
  __cheriseed_control_checks(CHERISEED_CHECK_OFF, CHERISEED_CHECK_BOUNDS);
  int array[10];
  int *ptr = __builtin_cheri_bounds_set(array, 5 * sizeof(int));
  // Bounds checks are turned OFF, so this will not cause a capability violation
  TEST_USED(ptr[6]);
}
