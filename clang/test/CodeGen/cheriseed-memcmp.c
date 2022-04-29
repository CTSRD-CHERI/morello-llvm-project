// RUN: %clang_cc1 -triple aarch64-unknown-linux -O2 -fsanitize=cheriseed -target-abi purecap -S %s -o - | FileCheck %s
// RUN: %clang_cc1 -triple x86_64-unknown-linux -O2 -fsanitize=cheriseed -target-abi purecap -S %s -o - | FileCheck %s
// RUN: %clang_cc1 -triple aarch64-unknown-linux -O2 -fsanitize=cheriseed -flegacy-pass-manager -target-abi purecap -S %s -o - | FileCheck %s
// RUN: %clang_cc1 -triple x86_64-unknown-linux -O2 -fsanitize=cheriseed -flegacy-pass-manager -target-abi purecap -S %s -o - | FileCheck %s

int memcmp(const void *s1, const void *s2, unsigned long n);

// Test that memcmp is not expanded by ExpandMemCmp pass.
// CHECK-LABEL: no_extend_memcmp:
int no_extend_memcmp(char *a, char *b) {
  // CHECK: {{[b, jmp]}} memcmp
  return memcmp(a, b, 4);
}
