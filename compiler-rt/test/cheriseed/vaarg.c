// RUN: %clang_cheriseed -mabi=purecap %s -g -O0 -o %t && %run %t
// RUN: %clang_cheriseed -mabi=purecap %s -g -O1 -o %t && %run %t
// RUN: %clang_cheriseed -mabi=purecap %s -g -O2 -o %t && %run %t
// RUN: %clang_cheriseed -mabi=purecap %s -g -O3 -o %t && %run %t
// RUN: %clang_cheriseed -mabi=purecap %s -g -Os -o %t && %run %t
// RUN: %clang_cheriseed -mabi=purecap -flegacy-pass-manager %s -g -O0 -o %t && %run %t
// RUN: %clang_cheriseed -mabi=purecap -flegacy-pass-manager %s -g -O1 -o %t && %run %t
// RUN: %clang_cheriseed -mabi=purecap -flegacy-pass-manager %s -g -O2 -o %t && %run %t
// RUN: %clang_cheriseed -mabi=purecap -flegacy-pass-manager %s -g -O3 -o %t && %run %t
// RUN: %clang_cheriseed -mabi=purecap -flegacy-pass-manager %s -g -Os -o %t && %run %t

#include "test.h"
#include <stdarg.h>

__attribute__((noinline)) long *variadic_arguments(long *result, ...) {
  va_list args;
  va_start(args, result);
  *result = 0;
  // p1
  *result += va_arg(args, long);
  // p2
  *result += *va_arg(args, long *);
  // p3
  *result += **va_arg(args, long **);
  va_end(args);
  return result;
}

int main() {
  // Parameters
  long p1 = 1;
  long *p2 = &p1;
  long **p3 = &p2;
  // Variadic call
  long result = -1;
  long *result_cap = variadic_arguments(&result, p1, p2, p3);
  // Check results
  if (result != 3)
    return 1;
  if (*result_cap != result)
    return 2;
  return 0;
}
