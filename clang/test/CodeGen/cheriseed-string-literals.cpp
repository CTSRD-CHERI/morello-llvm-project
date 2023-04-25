// Regression test for string literals: they used to automatically
// get "no_sanitize" attribute.

// RUN: %clang -target x86_64-linux-gnu -O0 -c -fsanitize=cheriseed -mabi=purecap %s
// RUN: %clang -target aarch64-linux-gnu -O0 -c -fsanitize=cheriseed -mabi=purecap %s
// RUN: %clang -target x86_64-linux-gnu -O0 -c -fsanitize=cheriseed -flegacy-pass-manager -mabi=purecap %s
// RUN: %clang -target aarch64-linux-gnu -O0 -c -fsanitize=cheriseed -flegacy-pass-manager -mabi=purecap %s

static struct {
  char *s;
} foo[] = {"A"};

char *bar(int i) {
  return foo[i].s;
}
