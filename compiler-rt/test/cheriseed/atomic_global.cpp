// RUN: %clangxx_cheriseed %s -g -O0 -o %t && %run %t
// RUN: %clangxx_cheriseed %s -g -O1 -o %t && %run %t
// RUN: %clangxx_cheriseed %s -g -O2 -o %t && %run %t
// RUN: %clangxx_cheriseed %s -g -O3 -o %t && %run %t
// RUN: %clangxx_cheriseed %s -g -Os -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap %s -g -O1 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap %s -g -O2 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap %s -g -O3 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap %s -g -Os -o %t && %run %t
// RUN: %clangxx_cheriseed -flegacy-pass-manager %s -g -O0 -o %t && %run %t
// RUN: %clangxx_cheriseed -flegacy-pass-manager %s -g -O1 -o %t && %run %t
// RUN: %clangxx_cheriseed -flegacy-pass-manager %s -g -O2 -o %t && %run %t
// RUN: %clangxx_cheriseed -flegacy-pass-manager %s -g -O3 -o %t && %run %t
// RUN: %clangxx_cheriseed -flegacy-pass-manager %s -g -Os -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap -flegacy-pass-manager %s -g -O0 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap -flegacy-pass-manager %s -g -O1 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap -flegacy-pass-manager %s -g -O2 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap -flegacy-pass-manager %s -g -O3 -o %t && %run %t
// RUN: %clangxx_cheriseed_purecap -flegacy-pass-manager %s -g -Os -o %t && %run %t

#include "test.h"

/* To check if the initialisation of shadow capability
 * doesn't end with infinite accessor recursive calls.
 */
struct struct_global {
    struct struct_global *__capability a;
    int b;
};

extern struct struct_global s2;

struct struct_global s1 = { &s2, 1 };
struct struct_global s2 = { &s1, 2 };

TEST_MAIN() {
    TEST_ASSERT(s1.b == 1);
    TEST_ASSERT(s1.a->b == 2);
    TEST_ASSERT(s1.a->a->b == 1);

    TEST_ASSERT(s2.b == 2);
    TEST_ASSERT(s2.a->b == 1);
    TEST_ASSERT(s2.a->a->b == 2);
}
