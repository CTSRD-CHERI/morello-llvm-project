// RUN: %clang_cheriseed %s -g -O0 -o %t && %run %t | FileCheck %s
// RUN: %clang_cheriseed %s -g -O1 -o %t && %run %t | FileCheck %s
// RUN: %clang_cheriseed %s -g -O2 -o %t && %run %t | FileCheck %s
// RUN: %clang_cheriseed %s -g -O3 -o %t && %run %t | FileCheck %s
// RUN: %clang_cheriseed %s -g -Os -o %t && %run %t | FileCheck %s
// RUN: %clang_cheriseed -flegacy-pass-manager %s -g -O0 -o %t && %run %t | FileCheck %s
// RUN: %clang_cheriseed -flegacy-pass-manager %s -g -O1 -o %t && %run %t | FileCheck %s
// RUN: %clang_cheriseed -flegacy-pass-manager %s -g -O2 -o %t && %run %t | FileCheck %s
// RUN: %clang_cheriseed -flegacy-pass-manager %s -g -O3 -o %t && %run %t | FileCheck %s
// RUN: %clang_cheriseed -flegacy-pass-manager %s -g -Os -o %t && %run %t | FileCheck %s

#include "test.h"
#include <assert.h>
#include <cinttypes>
#include <cstddef>
#include <stdio.h>

#define CHECK_OFFSETOF(__ty, __m, __v)                      \
  {                                                         \
    const size_t offset = offsetof(__ty, __m);              \
    assert(offset == __v);                                  \
    printf("offsetof(" #__ty ", " #__m "): %zu\n", offset); \
  }

#define CHECK_ADDRESS_DIFF(__s, __m, __v)                                                               \
  {                                                                                                     \
    const intptr_t addr_diff = reinterpret_cast<intptr_t>(&__s.__m) - reinterpret_cast<intptr_t>(&__s); \
    assert(addr_diff == __v);                                                                           \
    printf("runtime offset of " #__s "." #__m ": %zu\n", addr_diff);                                    \
  }

struct S {
  int a;
  int *__capability b;
  char *__capability c;
  char d;
};

int main(void) {
  assert(sizeof(S) == 64);
  printf("sizeof(S): %d\n", 64);

  // Check and print offsets of struct members.
  CHECK_OFFSETOF(S, a, 0);
  CHECK_OFFSETOF(S, b, 16);
  CHECK_OFFSETOF(S, c, 32);
  CHECK_OFFSETOF(S, d, 48);

  S s;

  // Check and print offsets of struct members runtime.
  CHECK_ADDRESS_DIFF(s, a, 0);
  CHECK_ADDRESS_DIFF(s, b, 16);
  CHECK_ADDRESS_DIFF(s, c, 32);
  CHECK_ADDRESS_DIFF(s, d, 48);

  // Initialize structure.
  s.a = 14;
  s.b = &s.a;
  s.c = &s.d;
  s.d = '1';
  assert(s.a == 14);
  assert(*s.b == 14);
  assert(*s.c == '1');
  assert(s.d == '1');

  // Modify field through a capability.
  *s.b = 42;
  *s.c = '2';
  assert(s.a == 42);
  assert(*s.b == 42);
  assert(*s.c == '2');
  assert(s.d == '2');

  return 0;
}

// CHECK: sizeof(S): 64
// CHECK: offsetof(S, a): 0
// CHECK: offsetof(S, b): 16
// CHECK: offsetof(S, c): 32
// CHECK: offsetof(S, d): 48
// CHECK: runtime offset of s.a: 0
// CHECK: runtime offset of s.b: 16
// CHECK: runtime offset of s.c: 32
// CHECK: runtime offset of s.d: 48
