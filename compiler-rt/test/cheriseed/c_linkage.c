// RUN: %clang_cheriseed -fuse-ld=lld %s -o %t && %run %t
// RUN: %clang_cheriseed -flegacy-pass-manager -fuse-ld=lld %s -o %t && %run %t

#include "test.h"

int main(void) {
  return 0;
}
