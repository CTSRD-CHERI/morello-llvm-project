// RUN: %clang_cc1 -triple aarch64-unknown-linux -O0 -fsanitize=cheriseed -target-abi purecap -S -verify %s
// RUN: %clang_cc1 -triple aarch64-unknown-linux -O2 -fsanitize=cheriseed -target-abi purecap -S -verify %s
// RUN: %clang_cc1 -triple aarch64-unknown-linux -O0 -flegacy-pass-manager -fsanitize=cheriseed -target-abi purecap -S -verify %s
// RUN: %clang_cc1 -triple aarch64-unknown-linux -O2 -flegacy-pass-manager -fsanitize=cheriseed -target-abi purecap -S -verify %s

void pass() {
  int v, *p;
  __asm__("" : : "r"(v) : "memory");
  __asm__("" : : "r"(p) : "memory");
  __asm__("" : : "r"(p), "r"(p) : "memory");
}

void fail() {
  int v, *p;
  // Capability input, asm does something CHERIseed can't reason about.
  __asm__("nop" : : "r"(p) : "memory"); // expected-error{{Inline assembly with capability operand is not supported with '-fsanitize=cheriseed'.}}
  // Returns a capability which is not yet supported.
  __asm__("nop" : "+r"(v) : "r"(p) : "memory"); // expected-error{{Inline assembly with capability operand is not supported with '-fsanitize=cheriseed'.}}
  // Returns a capability which is not yet supported, even for empty asm string.
  __asm__("" : "+r"(p) : : "memory"); // expected-error{{This inline assembly is not supported with '-fsanitize=cheriseed'.}}
}
