// RUN: %clang_cc1 -E -fsanitize=cheriseed %s -o - | FileCheck --check-prefix=CHECK-CHERISEED %s
// RUN: %clang_cc1 -E  %s -o - | FileCheck --check-prefix=CHECK-NO-CHERISEED %s

#if __has_feature(cheriseed_sanitizer)
int CHERIseedSanitizerEnabled();
#else
int CHERIseedSanitizerDisabled();
#endif

// CHECK-CHERISEED: CHERIseedSanitizerEnabled
// CHECK-NO-CHERISEED: CHERIseedSanitizerDisabled
