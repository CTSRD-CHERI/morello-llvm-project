// RUN: %clang     -target aarch64-unknown-linux -fsanitize=cheriseed %s -S -emit-llvm -o -
// RUN: %clang -O1 -target aarch64-unknown-linux -fsanitize=cheriseed %s -S -emit-llvm -o -
// RUN: %clang -O2 -target aarch64-unknown-linux -fsanitize=cheriseed %s -S -emit-llvm -o -
// RUN: %clang -O3 -target aarch64-unknown-linux -fsanitize=cheriseed %s -S -emit-llvm -o -

// RUN: %clang     -target aarch64-unknown-linux -fsanitize=cheriseed -mabi=purecap %s -S -emit-llvm -o -
// RUN: %clang -O1 -target aarch64-unknown-linux -fsanitize=cheriseed -mabi=purecap %s -S -emit-llvm -o -
// RUN: %clang -O2 -target aarch64-unknown-linux -fsanitize=cheriseed -mabi=purecap %s -S -emit-llvm -o -
// RUN: %clang -O3 -target aarch64-unknown-linux -fsanitize=cheriseed -mabi=purecap %s -S -emit-llvm -o -

// RUN: %clang     -target x86_64-unknown-linux -fsanitize=cheriseed %s -S -emit-llvm -o -
// RUN: %clang -O1 -target x86_64-unknown-linux -fsanitize=cheriseed %s -S -emit-llvm -o -
// RUN: %clang -O2 -target x86_64-unknown-linux -fsanitize=cheriseed %s -S -emit-llvm -o -
// RUN: %clang -O3 -target x86_64-unknown-linux -fsanitize=cheriseed %s -S -emit-llvm -o -

// RUN: %clang     -target x86_64-unknown-linux -fsanitize=cheriseed -mabi=purecap %s -S -emit-llvm -o -
// RUN: %clang -O1 -target x86_64-unknown-linux -fsanitize=cheriseed -mabi=purecap %s -S -emit-llvm -o -
// RUN: %clang -O2 -target x86_64-unknown-linux -fsanitize=cheriseed -mabi=purecap %s -S -emit-llvm -o -
// RUN: %clang -O3 -target x86_64-unknown-linux -fsanitize=cheriseed -mabi=purecap %s -S -emit-llvm -o -

// RUN: %clang     -target aarch64-unknown-linux -fsanitize=cheriseed -flegacy-pass-manager %s -S -emit-llvm -o -
// RUN: %clang -O1 -target aarch64-unknown-linux -fsanitize=cheriseed -flegacy-pass-manager %s -S -emit-llvm -o -
// RUN: %clang -O2 -target aarch64-unknown-linux -fsanitize=cheriseed -flegacy-pass-manager %s -S -emit-llvm -o -
// RUN: %clang -O3 -target aarch64-unknown-linux -fsanitize=cheriseed -flegacy-pass-manager %s -S -emit-llvm -o -

// RUN: %clang     -target aarch64-unknown-linux -fsanitize=cheriseed -flegacy-pass-manager -mabi=purecap %s -S -emit-llvm -o -
// RUN: %clang -O1 -target aarch64-unknown-linux -fsanitize=cheriseed -flegacy-pass-manager -mabi=purecap %s -S -emit-llvm -o -
// RUN: %clang -O2 -target aarch64-unknown-linux -fsanitize=cheriseed -flegacy-pass-manager -mabi=purecap %s -S -emit-llvm -o -
// RUN: %clang -O3 -target aarch64-unknown-linux -fsanitize=cheriseed -flegacy-pass-manager -mabi=purecap %s -S -emit-llvm -o -

// RUN: %clang     -target x86_64-unknown-linux -fsanitize=cheriseed -flegacy-pass-manager %s -S -emit-llvm -o -
// RUN: %clang -O1 -target x86_64-unknown-linux -fsanitize=cheriseed -flegacy-pass-manager %s -S -emit-llvm -o -
// RUN: %clang -O2 -target x86_64-unknown-linux -fsanitize=cheriseed -flegacy-pass-manager %s -S -emit-llvm -o -
// RUN: %clang -O3 -target x86_64-unknown-linux -fsanitize=cheriseed -flegacy-pass-manager %s -S -emit-llvm -o -

// RUN: %clang     -target x86_64-unknown-linux -fsanitize=cheriseed -flegacy-pass-manager -mabi=purecap %s -S -emit-llvm -o -
// RUN: %clang -O1 -target x86_64-unknown-linux -fsanitize=cheriseed -flegacy-pass-manager -mabi=purecap %s -S -emit-llvm -o -
// RUN: %clang -O2 -target x86_64-unknown-linux -fsanitize=cheriseed -flegacy-pass-manager -mabi=purecap %s -S -emit-llvm -o -
// RUN: %clang -O3 -target x86_64-unknown-linux -fsanitize=cheriseed -flegacy-pass-manager -mabi=purecap %s -S -emit-llvm -o -

int func1(int *v) { return *v; }
int func2(int *__capability v) { return *v; }
