// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t && %run %t

#include "test.h"

#define TEST_VALID_TAG(_c) TEST_ASSERT(__builtin_cheri_tag_get(_c))
#define TEST_INVALID_TAG(_c) TEST_ASSERT(!__builtin_cheri_tag_get(_c))

int global = 42;
int *global_ptr;

TEST_MAIN() {
  TEST_INVALID_TAG(global_ptr);
  global_ptr = &global;
  TEST_VALID_TAG(global_ptr);
  int read = *global_ptr;
  TEST_VALID_TAG(global_ptr);

  global_ptr = __builtin_cheri_tag_clear(global_ptr);
  TEST_INVALID_TAG(global_ptr);

  global_ptr = &global;
  TEST_VALID_TAG(global_ptr);

  global_ptr = (int *)nullptr;
  TEST_INVALID_TAG(global_ptr);
}

#undef TEST_VALID_TAG
#undef TEST_INVALID_TAG
