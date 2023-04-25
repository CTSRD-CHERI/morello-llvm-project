// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap %s -g -O2 -o %t && %run %t

#include "test.h"

TEST_MAIN() {
  _Bool result;
  char a = 'a';
  char b = 'b';
  char c = 'c';
  volatile char *ptr = &a;
  volatile char *expected = &b;
  volatile char *desired = &c;

  // Will *NOT* exchange
  result = __atomic_compare_exchange_n(&ptr, &expected, desired, 0, __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST);
  TEST_ASSERT(result == 0);
  TEST_ASSERT(ptr == &a);
  TEST_ASSERT(expected == &a);
  TEST_ASSERT(desired == &c);

  // Will exchange
  result = __atomic_compare_exchange_n(&ptr, &expected, desired, 0, __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST);
  TEST_ASSERT(result == 1);
  TEST_ASSERT(ptr == &c);
  TEST_ASSERT(expected == &a);
  TEST_ASSERT(desired == &c);
}
