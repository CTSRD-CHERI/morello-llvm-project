// RUN: %clang -fsanitize=cheriseed %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks= %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks= -fsanitize-cheriseed-checks= %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=LOAD -fsanitize-cheriseed-checks=-LOAD %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS

// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=ALL %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=TAG %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=BOUNDS %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=PERMS %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=LOAD %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=STORE %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=LOAD_CAP %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=STORE_CAP %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=EXECUTE %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS

// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=-ALL %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=-TAG %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=-BOUNDS %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=-PERMS %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=-LOAD %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=-STORE %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=-LOAD_CAP %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=-STORE_CAP %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=-EXECUTE %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS

// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=TAG,BOUNDS %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=-TAG,BOUNDS %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=TAG,-BOUNDS %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=-TAG,-BOUNDS %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS

// CHECK-CHERISEED-CHECKS: "-mllvm" "-cheriseed-disabled-checks=
// CHECK-CHERISEED-CHECKS-SAME: "-fsanitize=cheriseed"
// CHECK-CHERISEED-CHECKS-NOT: fsanitize-cheriseed-checks=

// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=help %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS-HELP
// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=HELP %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS-HELP

// CHECK-CHERISEED-CHECKS-HELP:      Usage: -fsanitize-cheriseed-checks=
// CHECK-CHERISEED-CHECKS-HELP-NEXT:  Available options are:
// CHECK-CHERISEED-CHECKS-HELP:      Above options can be prefixed with '-' to disable specific checks.
// CHECK-CHERISEED-CHECKS-HELP-NEXT: All checks are on by default.

// RUN: %clang -fsanitize=cheriseed -fsanitize-cheriseed-checks=-,TA,-TA,FOO,-FOO,LOA,TAGx,-TAGx,helpx,HELPx,ALIGNMENT,-ALIGNMENT %s -### 2>&1 | FileCheck %s --check-prefix=CHECK-CHERISEED-CHECKS-FAILED

// CHECK-CHERISEED-CHECKS-FAILED:      invalid value '-' in '-fsanitize-cheriseed-checks=-,TA,-TA,FOO,-FOO,LOA,TAGx,-TAGx,helpx,HELPx,ALIGNMENT,-ALIGNMENT'
// CHECK-CHERISEED-CHECKS-FAILED-NEXT: invalid value 'TA' in '-fsanitize-cheriseed-checks=-,TA,-TA,FOO,-FOO,LOA,TAGx,-TAGx,helpx,HELPx,ALIGNMENT,-ALIGNMENT'; did you mean 'TAG'?
// CHECK-CHERISEED-CHECKS-FAILED-NEXT: invalid value '-TA' in '-fsanitize-cheriseed-checks=-,TA,-TA,FOO,-FOO,LOA,TAGx,-TAGx,helpx,HELPx,ALIGNMENT,-ALIGNMENT'; did you mean 'TAG'?
// CHECK-CHERISEED-CHECKS-FAILED-NEXT: invalid value 'FOO' in '-fsanitize-cheriseed-checks=-,TA,-TA,FOO,-FOO,LOA,TAGx,-TAGx,helpx,HELPx,ALIGNMENT,-ALIGNMENT'
// CHECK-CHERISEED-CHECKS-FAILED-NEXT: invalid value '-FOO' in '-fsanitize-cheriseed-checks=-,TA,-TA,FOO,-FOO,LOA,TAGx,-TAGx,helpx,HELPx,ALIGNMENT,-ALIGNMENT'
// CHECK-CHERISEED-CHECKS-FAILED-NEXT: invalid value 'LOA' in '-fsanitize-cheriseed-checks=-,TA,-TA,FOO,-FOO,LOA,TAGx,-TAGx,helpx,HELPx,ALIGNMENT,-ALIGNMENT'; did you mean 'LOAD'?
// CHECK-CHERISEED-CHECKS-FAILED-NEXT: invalid value 'TAGx' in '-fsanitize-cheriseed-checks=-,TA,-TA,FOO,-FOO,LOA,TAGx,-TAGx,helpx,HELPx,ALIGNMENT,-ALIGNMENT'; did you mean 'TAG'?
// CHECK-CHERISEED-CHECKS-FAILED-NEXT: invalid value '-TAGx' in '-fsanitize-cheriseed-checks=-,TA,-TA,FOO,-FOO,LOA,TAGx,-TAGx,helpx,HELPx,ALIGNMENT,-ALIGNMENT'; did you mean 'TAG'?
// CHECK-CHERISEED-CHECKS-FAILED-NEXT: invalid value 'helpx' in '-fsanitize-cheriseed-checks=-,TA,-TA,FOO,-FOO,LOA,TAGx,-TAGx,helpx,HELPx,ALIGNMENT,-ALIGNMENT'; did you mean 'help'?
// CHECK-CHERISEED-CHECKS-FAILED-NEXT: invalid value 'HELPx' in '-fsanitize-cheriseed-checks=-,TA,-TA,FOO,-FOO,LOA,TAGx,-TAGx,helpx,HELPx,ALIGNMENT,-ALIGNMENT'; did you mean 'HELP'?
// CHECK-CHERISEED-CHECKS-FAILED-NEXT: invalid value 'ALIGNMENT' in '-fsanitize-cheriseed-checks=-,TA,-TA,FOO,-FOO,LOA,TAGx,-TAGx,helpx,HELPx,ALIGNMENT,-ALIGNMENT'
// CHECK-CHERISEED-CHECKS-FAILED-NEXT: invalid value '-ALIGNMENT' in '-fsanitize-cheriseed-checks=-,TA,-TA,FOO,-FOO,LOA,TAGx,-TAGx,helpx,HELPx,ALIGNMENT,-ALIGNMENT'
