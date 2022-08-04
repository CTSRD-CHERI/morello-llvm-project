// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t && %run %t

#include "test.h"

TEST_MAIN() {
  int value = 42;
  int *cap = &value;

  // Data store to the first byte of the valid capability.
  {
    int *cap_copy = cap;
    TEST_ASSERT(__builtin_cheri_tag_get(cap_copy) == 1);
    volatile char *ptr = (volatile char *)&cap_copy;
    ptr[0] = 1;
    TEST_ASSERT(__builtin_cheri_tag_get(cap_copy) == 0);
  }

  // Data store to the last byte of the valid capability.
  {
    int *cap_copy = cap;
    TEST_ASSERT(__builtin_cheri_tag_get(cap_copy) == 1);
    volatile char *ptr = (volatile char *)&cap_copy;
    ptr[15] = 1;
    TEST_ASSERT(__builtin_cheri_tag_get(cap_copy) == 0);
  }
}
