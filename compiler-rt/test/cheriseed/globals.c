// RUN: %clang_cheriseed %s -g -O0 -o %t && %run %t
// RUN: %clang_cheriseed %s -g -O1 -o %t && %run %t
// RUN: %clang_cheriseed %s -g -O2 -o %t && %run %t
// RUN: %clang_cheriseed %s -g -O3 -o %t && %run %t
// RUN: %clang_cheriseed %s -g -Os -o %t && %run %t
// RUN: %clang_cheriseed -flegacy-pass-manager %s -g -O0 -o %t && %run %t
// RUN: %clang_cheriseed -flegacy-pass-manager %s -g -O1 -o %t && %run %t
// RUN: %clang_cheriseed -flegacy-pass-manager %s -g -O2 -o %t && %run %t
// RUN: %clang_cheriseed -flegacy-pass-manager %s -g -O3 -o %t && %run %t
// RUN: %clang_cheriseed -flegacy-pass-manager %s -g -Os -o %t && %run %t

#include "test.h"

int regular_global = 42;
int *__capability cap_to_global = &regular_global;

void count() {
  static int *__capability cap_to_count = &regular_global;
  *cap_to_count += 1;
}

TEST_MAIN() {
  TEST_ASSERT((size_t)&regular_global == __builtin_cheri_address_get(cap_to_global));
  TEST_ASSERT(*cap_to_global == 42);
  regular_global = 24;
  TEST_ASSERT(*cap_to_global == 24);
  *cap_to_global = 5;
  TEST_ASSERT(regular_global == 5);

  regular_global = 0;
  count();
  TEST_ASSERT(regular_global == 1);
  count();
  TEST_ASSERT(regular_global == 2);
  count();
  TEST_ASSERT(regular_global == 3);
}
