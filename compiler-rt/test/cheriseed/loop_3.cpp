// RUN: %clang_cheriseed_purecap %s -g -O0 -o %t && %run %t
// RUN: %clang_cheriseed_purecap %s -g -O1 -o %t && %run %t
// RUN: %clang_cheriseed_purecap %s -g -O2 -o %t && %run %t
// RUN: %clang_cheriseed_purecap %s -g -O3 -o %t && %run %t
// RUN: %clang_cheriseed_purecap %s -g -Os -o %t && %run %t
// RUN: %clang_cheriseed_purecap %s -g -Oz -o %t && %run %t
// RUN: %clang_cheriseed_purecap %s -g -Ofast -o %t && %run %t

#include "test.h"

__attribute__((weak)) long num() { return 2; }

__attribute__((weak)) void loop_3(int *first, int *last) {
  int *a, *b;
  int n = 0;

  for (a = first + 1; a < last; ++a) {
    for (b = a - 1; n < num(); ++n) {
      do {
        *(b + 1) = *b;
      } while ((first <= --b));

      if (b < first) {
        break;
      }
    }
  }
}

TEST_MAIN() {
  int array[6];
  array[0] = 0;
  array[1] = 3;
  array[2] = 1;
  array[3] = 2;
  array[4] = 4;
  array[5] = 0;
  loop_3(&array[1], &array[4]);
  TEST_ASSERT(array[0] == 0);
  TEST_ASSERT(array[1] == 3);
  TEST_ASSERT(array[2] == 3);
  TEST_ASSERT(array[3] == 3);
  TEST_ASSERT(array[4] == 4);
  TEST_ASSERT(array[5] == 0);
}
