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

__thread volatile int tls_int = 42;
__thread volatile int *tls_cap;

TEST_MAIN() {
  TEST_ASSERT(tls_int == 42);
  TEST_ASSERT(tls_cap == nullptr);

  tls_int += 1;
  TEST_ASSERT(tls_int == 43);

  tls_cap = &tls_int;
  TEST_ASSERT(*tls_cap == 43);

  *tls_cap = 21;
  TEST_ASSERT(*tls_cap == 21);
  TEST_ASSERT(tls_int == 21);
}
