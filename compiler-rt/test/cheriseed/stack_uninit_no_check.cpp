// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t && %run %t

#include "test.h"
#include <cheriintrin.h>

TEST_MAIN() {
  // Turn STORE checks OFF
  __cheriseed_control_checks(CHERISEED_CHECK_OFF, __CHERI_CAP_PERMISSION_PERMIT_STORE__);
  int a = 42;
  int *ptr = __builtin_cheri_perms_and(&a, ~__CHERI_CAP_PERMISSION_PERMIT_STORE__);
  // STORE checks are turned OFF, so this will not cause a capability violation
  *ptr = a - 1;
}
