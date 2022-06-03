// [1] -O0 might emit calls to non-instrumented libc functions, such as
// memcpy(). Avoid using -O0 because it will certainly crash the test.

// RUN: %clangxx_cheriseed_purecap %s -g -O1 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap %s -g -O2 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap %s -g -O3 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap %s -g -Os -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap -flegacy-pass-manager %s -g -O1 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap -flegacy-pass-manager %s -g -O2 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap -flegacy-pass-manager %s -g -O3 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap -flegacy-pass-manager %s -g -Os -o %t && %run %t

#include "test.h"

NOINLINE
void varargs_long(long *result, ...) {
  __builtin_va_list args;
  __builtin_va_start(args, result);
  *result += __builtin_va_arg(args, long);
  __builtin_va_end(args);
}

NOINLINE
void varargs_longptr(long *result, ...) {
  __builtin_va_list args;
  __builtin_va_start(args, result);
  *result += *__builtin_va_arg(args, long *);
  __builtin_va_end(args);
}

NOINLINE
void varargs_longptrptr(long *result, ...) {
  __builtin_va_list args;
  __builtin_va_start(args, result);
  *result += **__builtin_va_arg(args, long **);
  __builtin_va_end(args);
}

typedef union {
  long a;
  __int128_t b;
} U1;

NOINLINE
void varargs_U1(long *result, ...) {
  __builtin_va_list args;
  __builtin_va_start(args, result);
  U1 u1 = __builtin_va_arg(args, U1);
  *result += u1.a;
  __builtin_va_end(args);;
}

/* Fixme: The Morello toolchain doesn't currently support such types.
 *  Add back in once upstream has been patched.
typedef union {
  long a;
  __int128_t b;
  long c[5];
} U2;

NOINLINE
void varargs_U2(long *result, ...) {
  __builtin_va_list args;
  __builtin_va_start(args, result);
  U2 u2 = __builtin_va_arg(args, U2);
  *result += u2.a;
  __builtin_va_end(args);;
}
*/

NOINLINE
long *varargs_all(long *result, ...) {
  __builtin_va_list args;
  __builtin_va_start(args, result);
  // p1
  *result += __builtin_va_arg(args, long);
  // p2
  *result += *__builtin_va_arg(args, long *);
  // p3
  *result += **__builtin_va_arg(args, long **);
  // p4
  U1 u1 = __builtin_va_arg(args, U1);
  *result += u1.a;
  __builtin_va_end(args);
  return result;
}

TEST_MAIN() {
  long result = 0;
  // Variadic calls, one-by-one
  long p1 = 1;
  varargs_long(&result, p1);
  long *p2 = &p1;
  varargs_longptr(&result, p2);
  long **p3 = &p2;
  varargs_longptrptr(&result, p3);
  U1 p4 = {.a = 1};
  varargs_U1(&result, p4);
  // Variadic calls, all together
  long *result_cap = varargs_all(&result, p1, p2, p3, p4);
  // Check results
  TEST_ASSERT(result == (2 * 4));
  TEST_ASSERT(*result_cap == result);
}
