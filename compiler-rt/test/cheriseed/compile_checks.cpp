// RUN: %clangxx_cheriseed_purecap -DTEST_CASE=0 -fsanitize-cheriseed-checks= %s -g -O0 -o %t && not %run %t |& FileCheck --check-prefix=CHECK-TAG %s
// RUN: %clangxx_cheriseed_purecap -DTEST_CASE=0 -fsanitize-cheriseed-checks=ALL %s -g -O0 -o %t && not %run %t |& FileCheck --check-prefix=CHECK-TAG %s
// RUN: %clangxx_cheriseed_purecap -DTEST_CASE=0 -fsanitize-cheriseed-checks=TAG %s -g -O0 -o %t && not %run %t |& FileCheck --check-prefix=CHECK-TAG %s
// RUN: %clangxx_cheriseed_purecap -DTEST_CASE=1 -fsanitize-cheriseed-checks=LOAD %s -g -O0 -o %t && not %run %t |& FileCheck --check-prefixes CHECK-MISSING,LOAD %s
// RUN: %clangxx_cheriseed_purecap -DTEST_CASE=2 -fsanitize-cheriseed-checks=STORE %s -g -O0 -o %t && not %run %t |& FileCheck --check-prefixes CHECK-MISSING,STORE %s
// RUN: %clangxx_cheriseed_purecap -DTEST_CASE=3 -fsanitize-cheriseed-checks=STORE_CAP %s -g -O0 -o %t && not %run %t |& FileCheck --check-prefixes CHECK-MISSING,STORE_CAP %s
// RUN: %clangxx_cheriseed_purecap -DTEST_CASE=4 -fsanitize-cheriseed-checks=EXECUTE %s -g -O0 -o %t && not %run %t |& FileCheck --check-prefixes CHECK-MISSING,EXECUTE %s
// RUN: %clangxx_cheriseed_purecap -DTEST_CASE=5 -fsanitize-cheriseed-checks=BOUNDS %s -g -O0 -o %t && not %run %t |& FileCheck --check-prefix=CHECK-BOUNDS %s

// RUN: %clangxx_cheriseed_purecap -DTEST_CASE=0 -fsanitize-cheriseed-checks=ALL,-TAG %s -g -O0 -o %t && not %run %t |& FileCheck --check-prefix=CHECK-MISSING %s
// RUN: %clangxx_cheriseed_purecap -DTEST_CASE=1 -fsanitize-cheriseed-checks=ALL,-LOAD %s -g -O0 -o %t && not %run %t |& FileCheck --check-prefixes CHECK-TAG %s
// RUN: %clangxx_cheriseed_purecap -DTEST_CASE=2 -fsanitize-cheriseed-checks=ALL,-STORE %s -g -O0 -o %t && not %run %t |& FileCheck --check-prefixes CHECK-TAG %s
// RUN: %clangxx_cheriseed_purecap -DTEST_CASE=3 -fsanitize-cheriseed-checks=ALL,-STORE_CAP %s -g -O0 -o %t && not %run %t |& FileCheck --check-prefixes CHECK-TAG %s
// RUN: %clangxx_cheriseed_purecap -DTEST_CASE=4 -fsanitize-cheriseed-checks=ALL,-EXECUTE %s -g -O0 -o %t && not %run %t |& FileCheck --check-prefixes CHECK-TAG %s
// RUN: %clangxx_cheriseed_purecap -DTEST_CASE=5 -fsanitize-cheriseed-checks=ALL,-BOUNDS %s -g -O0 -o %t && not %run %t |& FileCheck --check-prefix=CHECK-TAG %s

// RUN: %clangxx_cheriseed_purecap -DTEST_CASE=6 -fsanitize-cheriseed-checks=help %s -g -O0 -o %t |& FileCheck --check-prefix=CHECK-COMPILE-TIME-HELP %s
// RUN: %clangxx_cheriseed_purecap -DTEST_CASE=6 -fsanitize-cheriseed-checks=HELP %s -g -O0 -o %t |& FileCheck --check-prefix=CHECK-COMPILE-TIME-HELP %s

// CHECK-COMPILE-TIME-HELP:      Usage: -fsanitize-cheriseed-checks=
// CHECK-COMPILE-TIME-HELP-NEXT:  Available options are:
// CHECK-COMPILE-TIME-HELP-NEXT:   ALL        Enable all checks
// CHECK-COMPILE-TIME-HELP-NEXT:   TAG        Enable tag checks
// CHECK-COMPILE-TIME-HELP-NEXT:   BOUNDS     Enable bounds checks
// CHECK-COMPILE-TIME-HELP-NEXT:   PERMS      Enable permission checks
// CHECK-COMPILE-TIME-HELP-NEXT:   LOAD       Enable checks for LOAD permission
// CHECK-COMPILE-TIME-HELP-NEXT:   STORE      Enable checks for STORE permission
// CHECK-COMPILE-TIME-HELP-NEXT:   LOAD_CAP   Enable checks for LOAD_CAP permission
// CHECK-COMPILE-TIME-HELP-NEXT:   STORE_CAP  Enable checks for STORE_CAP permission
// CHECK-COMPILE-TIME-HELP-NEXT:   EXECUTE    Enable checks for EXECUTE permission
// CHECK-COMPILE-TIME-HELP-NEXT:   HELP       Displays this help message and exits
// CHECK-COMPILE-TIME-HELP-NEXT:   help       Same as (HELP)
// CHECK-COMPILE-TIME-HELP-NEXT: Above options can be prefixed with '-' to disable specific checks.
// CHECK-COMPILE-TIME-HELP-NEXT: All checks are on by default.

#include "test.h"

#pragma clang diagnostic ignored "-Warray-bounds"

union {
  int *a;
  int b;
  void (*c)();
  char d[1];
} *global_ptr, global;

TEST_MAIN() {
  int local;

  // CHECK-MISSING: Capability is missing required permission(s)
  switch (TEST_CASE) {
  case 0:
    // CHECK-TAG: Capability is untagged at
  case 1:
    // LOAD: LOAD
    TEST_USED(global_ptr->b);
    break;
  case 2:
    // STORE: STORE
    global_ptr->b = 0;
    break;
  case 3:
    // STORE_CAP: STORE_CAP
    global_ptr->a = &local;
    break;
  case 4:
    // EXECUTE: EXECUTE
    global_ptr->c();
    break;
  case 5:
    // CHECK-BOUNDS: Prevented out-of-bounds access with capability
    TEST_USED(global.d[sizeof(global)]);
    break;
  case 6:
    return;
  }
  // Unreachable.
  TEST_USED(global_ptr->b);
}
