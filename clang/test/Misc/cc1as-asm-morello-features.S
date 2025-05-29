// REQUIRES: aarch64-registered-target
/// Check that we correctly make the ARMv8.2 architecture features available for -march=morello
// RUN: %clang --target=aarch64-unknown-freebsd15 -v -c -o /dev/null -march=morello -mabi=purecap %s 2>&1 | FileCheck %s
// CHECK: -target-cpu generic -target-feature +neon -target-feature +morello -target-feature +v8.2a -target-feature +c64
// RUN: not %clang -cc1as -triple aarch64c-unknown-freebsd15 -filetype asm %s -o /dev/null -target-cpu generic -target-feature +morello -target-feature +c64 -target-abi purecap 2>&1 | FileCheck %s --check-prefix=ERR-NO-ARMV82
// ERR-NO-ARMV82: error: expected writable system register or pstate
// ERR-NO-ARMV82-NEXT: msr vttbr_el2, xzr
// RUN: %clang -cc1as -triple aarch64c-unknown-freebsd15 -filetype asm %s -o /dev/null -target-cpu generic -target-feature +morello -target-feature +v8.2a -target-feature +c64 -target-abi purecap

// This was previously rejected since we weren't inferring v8.2
msr vttbr_el2, xzr
