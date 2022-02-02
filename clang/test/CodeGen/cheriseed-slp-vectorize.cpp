// Check that SLP vectorizer is disabled with CHERIseed.
//
// This is a workaround. SLP vectorizer might create vectors of capabilities,
// which CHERIseed cannot handle.

// RUN: %clang -target x86_64-linux-gnu -O2 -c -fsanitize=cheriseed -mabi=purecap \
// RUN:   -flegacy-pass-manager -mllvm --debug-pass=Structure %s |& FileCheck %s
// RUN: %clang -target aarch64-linux-gnu -O2 -c -fsanitize=cheriseed -mabi=purecap \
// RUN:   -flegacy-pass-manager -mllvm --debug-pass=Structure %s |& FileCheck %s

// CHECK-NOT: SLP Vectorizer

// RUN: %clang -target x86_64-linux-gnu -O2 -c -fsanitize=cheriseed -mabi=purecap %s -o -
// RUN: %clang -target aarch64-linux-gnu -O2 -c -fsanitize=cheriseed -mabi=purecap %s -o -

// In addition, the code below used to crash the compiler.
long *cmp1, *cmp2, *cmp3, *cmp4;

int no_vector_of_capabilities(long *v) {
  return v && v != cmp1 && v != cmp2 && v != cmp3 && v != cmp4;
}