// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t -DPERM=CHERI_PERM_LOAD && not %run %t |& FileCheck --check-prefixes CHECK,LOAD %s
// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t -DPERM=CHERI_PERM_STORE && not %run %t |& FileCheck --check-prefixes CHECK,STORE %s
// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t -DPERM=CHERI_PERM_STORE_CAP && not %run %t |& FileCheck --check-prefixes CHECK,STORE-CAP %s
// RUN: %clangxx_cheriseed_purecap %s -g -O0 -o %t -DPERM=CHERI_PERM_EXECUTE && not %run %t |& FileCheck --check-prefixes CHECK,EXECUTE %s

#include "test.h"
#include <cheriintrin.h>

#pragma clang diagnostic ignored "-Wcheri-capability-misuse"

TEST_MAIN() {
  __cheriseed_control_checks(CHERISEED_DISABLE, CHERISEED_CHECK_TAG);
  union U {
    int i;
    int *c;
    void (*f)();
  } u;

  U *perms_stripped_cap = cheri_perms_and(&u, ~PERM);

  int a;

  // CHECK: Capability is missing required permission(s)
  switch (PERM) {
  default:
    break;
  case CHERI_PERM_LOAD:
    // LOAD: LOAD
    TEST_USED(perms_stripped_cap->i);
    break;
  case CHERI_PERM_STORE:
    // STORE: STORE
    perms_stripped_cap->i = 1;
    break;
  case CHERI_PERM_STORE_CAP:
    // TODO: from the Programming Guide:
    //  If the [STORE_CAP] permission is not present, *and the tag on the stored
    //  capability is valid*, then a hardware exception will be thrown.
    //
    // This should only fail if the capability is tagged.
    // STORE-CAP: STORE_CAP
    perms_stripped_cap->c = &a;
    break;
  case CHERI_PERM_EXECUTE:
    // EXECUTE: EXECUTE
    perms_stripped_cap->f();
    break;
  }
}
