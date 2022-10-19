// RUN: %clang_cheriseed_purecap %s -g -O0 -o %t && %run %t
// RUN: %clang_cheriseed_purecap %s -g -O1 -o %t && %run %t
// RUN: %clang_cheriseed_purecap %s -g -O2 -o %t && %run %t
// RUN: %clang_cheriseed_purecap %s -g -O3 -o %t && %run %t
// RUN: %clang_cheriseed_purecap %s -g -Os -o %t && %run %t
// RUN: %clang_cheriseed_purecap %s -g -Oz -o %t && %run %t
// RUN: %clang_cheriseed_purecap %s -g -Ofast -o %t && %run %t

#include "test.h"

// Regression test 'loop_1'
//
// Originally the loop variable '%c' got overwritten before use.
// That's because of the extra indirection. There was aliasing between '%c'
// and '%c_next', both pointed to the same capability storage location after
// the first iteration. In the following IR example, consider arriving to
// '%loop_1' from '%BB1'
//
//  %BB1:
//    br label %loop_1
//
//  %loop_1:
//    %c = phi %__cheriseed_cap_t* [ %c_next, %BB1 ], [ %c0, %BB0 ]
//    %c_next = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* %c_next_storage, %__cheriseed_cap_t* %c, i64 1)
//    ; use '%c' to store, but it is '%c_next' now.
//
//  Solution was to break this aliasing by making a copy in the predecessor
//  block:
//
//  %BB1:
//    %c_copy = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* %c_copy_storage, %__cheriseed_cap_t* %c, i64 0)
//    br label %loop_1
//
//  %loop_1:
//    %c = phi %__cheriseed_cap_t* [ %c_copy, %BB1 ], [ %c0, %BB0 ]
//    %c_next = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* %c_next_storage, %__cheriseed_cap_t* %c, i64 1)
//    ; use '%c' to store, which is not aliased by '%c_next' anymore.
//

__attribute__((weak)) void loop_1(char *c) {
  while (*c != 'c') {
    *c++ = 'x';
  }
}

TEST_MAIN() {
  char array[5];
  array[0] = 'z';
  array[1] = 'a';
  array[2] = 'b';
  array[3] = 'c';
  array[4] = 'z';
  loop_1(&array[1]);
  TEST_ASSERT(array[0] == 'z');
  TEST_ASSERT(array[1] == 'x');
  TEST_ASSERT(array[2] == 'x');
  TEST_ASSERT(array[3] == 'c');
  TEST_ASSERT(array[4] == 'z');
}
