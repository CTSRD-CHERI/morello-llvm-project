
// Check that __attribute__((no_sanitize("cheriseed")) disables instrumentation.

// RUN: %clang_cc1 -triple aarch64-unknown-linux -disable-O0-optnone \
// RUN:   -emit-llvm -o - %s | FileCheck -check-prefix=CHECK-DISABLED %s

// RUN: %clang_cc1 -triple aarch64-unknown-linux -fsanitize=cheriseed \
// RUN:   -disable-O0-optnone -emit-llvm -o - %s | \
// RUN:   FileCheck -check-prefix=CHECK-ENABLED %s

// RUN: %clang_cc1 -triple aarch64-unknown-linux -fsanitize=cheriseed -flegacy-pass-manager \
// RUN:   -disable-O0-optnone -emit-llvm -o - %s | \
// RUN:   FileCheck -check-prefix=CHECK-ENABLED %s

int GlobalHasSanitizeCHERIseed = 1;
__attribute__((no_sanitize("cheriseed"))) int GlobalHasNoSanitizeCHERIseed = 0;

extern int ExternalGlobalHasSanitizeCHERIseed;
__attribute__((no_sanitize("cheriseed"))) extern int ExternalGlobalHasNoSanitizeCHERIseed;

int helper() {
  return ExternalGlobalHasSanitizeCHERIseed + ExternalGlobalHasNoSanitizeCHERIseed;
}

// CHECK-DISABLED: @GlobalHasSanitizeCHERIseed = global i32 1, align 4
// CHECK-DISABLED: @GlobalHasNoSanitizeCHERIseed = global i32 0, align 4
// CHECK-DISABLED: @ExternalGlobalHasSanitizeCHERIseed = external global i32, align 4
// CHECK-DISABLED: @ExternalGlobalHasNoSanitizeCHERIseed = external global i32, align 4

// CHECK-ENABLED:  @GlobalHasNoSanitizeCHERIseed = global i32 0, align 4
// CHECK-ENABLED:  @ExternalGlobalHasNoSanitizeCHERIseed = external global i32, align 4
// CHECK-ENABLED:  @GlobalHasSanitizeCHERIseed()
// CHECK-ENABLED:  @ExternalGlobalHasSanitizeCHERIseed()
