// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap %s -g -O1 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap %s -g -O2 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap %s -g -O3 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap %s -g -Os -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap -flegacy-pass-manager %s -g -O0 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap -flegacy-pass-manager %s -g -O1 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap -flegacy-pass-manager %s -g -O2 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap -flegacy-pass-manager %s -g -O3 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap -flegacy-pass-manager %s -g -Os -o %t && %run %t

#include "test.h"

NOINLINE
long *variadic_arguments(long *result, ...) {
  __builtin_va_list args;
  __builtin_va_start(args, result);
  *result = 0;
  // p1
  *result += __builtin_va_arg(args, long);
  // p2
  *result += *__builtin_va_arg(args, long *);
  // p3
  *result += **__builtin_va_arg(args, long **);
  __builtin_va_end(args);
  return result;
}

TEST_MAIN() {
  // Parameters
  long p1 = 1;
  long *p2 = &p1;
  long **p3 = &p2;
  // Variadic call
  long result = -1;
  long *result_cap = variadic_arguments(&result, p1, p2, p3);
  // Check results
  TEST_ASSERT(result == 3);
  TEST_ASSERT(*result_cap == result);
}
