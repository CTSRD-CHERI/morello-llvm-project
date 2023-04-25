// RUN: %clang_cheriseed -ffreestanding -E -dM -target x86_64-linux-gnu - < /dev/null | FileCheck -match-full-lines %s
// RUN: %clang_cheriseed_purecap -ffreestanding -E -dM -target x86_64-linux-gnu - < /dev/null | FileCheck -match-full-lines --check-prefix=CHECK-PURECAP %s
// RUN: %clang_cheriseed -ffreestanding -E -dM -target aarch64-linux-gnu - < /dev/null | FileCheck -match-full-lines %s
// RUN: %clang_cheriseed_purecap -ffreestanding -E -dM -target aarch64-linux-gnu - < /dev/null | FileCheck -match-full-lines --check-prefix=CHECK-PURECAP %s

// RUN: %clang_cheriseed -flegacy-pass-manager -ffreestanding -E -dM -target x86_64-linux-gnu - < /dev/null | FileCheck -match-full-lines %s
// RUN: %clang_cheriseed_purecap -flegacy-pass-manager -ffreestanding -E -dM -target x86_64-linux-gnu - < /dev/null | FileCheck -match-full-lines --check-prefix=CHECK-PURECAP %s
// RUN: %clang_cheriseed -flegacy-pass-manager -ffreestanding -E -dM -target aarch64-linux-gnu - < /dev/null | FileCheck -match-full-lines %s
// RUN: %clang_cheriseed_purecap -flegacy-pass-manager -ffreestanding -E -dM -target aarch64-linux-gnu - < /dev/null | FileCheck -match-full-lines --check-prefix=CHECK-PURECAP %s

// CHECK: #define __INTPTR_TYPE__ long int
// CHECK: #define __INTPTR_WIDTH__ 64
// CHECK: #define __SIZEOF_INTCAP__ 16
// CHECK: #define __SIZEOF_UINTCAP__ 16
// CHECK: #define __UINTPTR_TYPE__ long unsigned int
// CHECK: #define __UINTPTR_WIDTH__ 64

// CHECK-PURECAP: #define __INTPTR_TYPE__ __intcap
// CHECK-PURECAP: #define __INTPTR_WIDTH__ 128
// CHECK-PURECAP: #define __SIZEOF_INTCAP__ 16
// CHECK-PURECAP: #define __SIZEOF_UINTCAP__ 16
// CHECK-PURECAP: #define __UINTPTR_TYPE__ unsigned __intcap
// CHECK-PURECAP: #define __UINTPTR_WIDTH__ 128
