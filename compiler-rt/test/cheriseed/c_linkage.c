// RUN: %clang_cheriseed %s -target aarch64-linux-gnu -o %t && %run %t
// XFAIL: ! aarch64
// RUN: %clang_cheriseed -flegacy-pass-manager %s -target aarch64-linux-gnu -o %t && %run %t
// XFAIL: ! aarch64
#include <sanitizer/cheriseed_interface.h>

int main() {
  return 0;
}
