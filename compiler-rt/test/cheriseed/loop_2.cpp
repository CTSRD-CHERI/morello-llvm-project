// RUN: %clang_cheriseed_purecap %s -g -O0 -o %t && %run %t
// RUN: %clang_cheriseed_purecap %s -g -O1 -o %t && %run %t
// RUN: %clang_cheriseed_purecap %s -g -O2 -o %t && %run %t
// RUN: %clang_cheriseed_purecap %s -g -O3 -o %t && %run %t
// RUN: %clang_cheriseed_purecap %s -g -Os -o %t && %run %t
// RUN: %clang_cheriseed_purecap %s -g -Oz -o %t && %run %t
// RUN: %clang_cheriseed_purecap %s -g -Ofast -o %t && %run %t

#include "test.h"

__attribute__((weak)) long max() { return 3; }

__attribute__((weak)) long step() { return 1; }

__attribute__((weak)) void loop_2(char **array) {
  char **start = &array[0];
  char **next = &array[1];
  char **end = &array[max()];

  while (start < end) {
    *start = reinterpret_cast<char *>(start + 1);
    start = next;
    next += step();
  }
}

TEST_MAIN() {
  char *array[5];
  array[0] = nullptr;
  array[1] = reinterpret_cast<char *>(1);
  array[2] = reinterpret_cast<char *>(2);
  array[3] = reinterpret_cast<char *>(3);
  array[4] = nullptr;
  loop_2(&array[1]);
  TEST_ASSERT(array[0] == nullptr);
  TEST_ASSERT(array[1] == reinterpret_cast<char *>(&array[2]));
  TEST_ASSERT(array[2] == reinterpret_cast<char *>(&array[3]));
  TEST_ASSERT(array[3] == reinterpret_cast<char *>(&array[4]));
  TEST_ASSERT(array[4] == nullptr);
}
