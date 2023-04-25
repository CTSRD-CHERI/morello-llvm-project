// RUN: %clang --target=aarch64-linux-gnu -fsanitize=cheriseed -S %s -o - | FileCheck --check-prefixes=CHECK-ASM,CHECK-ASM-AARCH64 %s
// RUN: %clang --target=aarch64-linux-gnu -fsanitize=cheriseed -S -emit-llvm %s -o - | FileCheck --check-prefix=CHECK-IR %s
// RUN: %clang --target=x86_64-linux-gnu -fsanitize=cheriseed -S %s -o - | FileCheck --check-prefixes=CHECK-ASM,CHECK-ASM-X86_64 %s
// RUN: %clang --target=x86_64-linux-gnu -fsanitize=cheriseed -S -emit-llvm %s -o - | FileCheck --check-prefix=CHECK-IR %s

// RUN: %clang --target=aarch64-linux-gnu -fsanitize=cheriseed -flegacy-pass-manager -S %s -o - | FileCheck --check-prefixes=CHECK-ASM,CHECK-ASM-AARCH64 %s
// RUN: %clang --target=aarch64-linux-gnu -fsanitize=cheriseed -flegacy-pass-manager -S -emit-llvm %s -o - | FileCheck --check-prefix=CHECK-IR %s
// RUN: %clang --target=x86_64-linux-gnu -fsanitize=cheriseed -flegacy-pass-manager -S %s -o - | FileCheck --check-prefixes=CHECK-ASM,CHECK-ASM-X86_64 %s
// RUN: %clang --target=x86_64-linux-gnu -fsanitize=cheriseed -flegacy-pass-manager -S -emit-llvm %s -o - | FileCheck --check-prefix=CHECK-IR %s
struct S1 {
  char *a;
};
// CHECK-IR: %struct.S1 = type { i8* }

S1 s1{nullptr};
// CHECK-ASM-LABEL: .globl s1
// CHECK-ASM-NEXT:  .p2align 3
//                  a
// CHECK-ASM:       .zero 8
// CHECK-ASM-NEXT:  .size s1, 8

struct S2 {
  char *__capability a;
};
// CHECK-IR: %struct.S2 = type { %__cheriseed_cap_t }

S2 s2{nullptr};
// CHECK-ASM-LABEL: .globl s2
// CHECK-ASM-NEXT:  .p2align 4
//                  a
// CHECK-ASM:       .zero 16
// CHECK-ASM-NEXT:  .size s2, 16

struct S3 {
  char a;
  char *b;
  char c;
};
// CHECK-IR: %struct.S3 = type { i8, i8*, i8 }

S3 s3{1, nullptr, 2};
// CHECK-ASM-LABEL: .globl s3
// CHECK-ASM-NEXT:  .p2align 3
//                  a
// CHECK-ASM:       .byte 1
// CHECK-ASM-NEXT:  .zero 7
//                  b
// CHECK-ASM-AARCH64-NEXT: .xword 0
// CHECK-ASM-X86_64-NEXT:  .quad  0
//                  c
// CHECK-ASM-NEXT:  .byte 2
// CHECK-ASM-NEXT:  .zero 7
// CHECK-ASM-NEXT:  .size s3, 24

struct S4 {
  char a;
  char *__capability b;
  char c;
};
// TODO: Interestingly, x86_64 handles this as a non-literal struct.
// Nothing serious here, but this can't be tested.
// OFF-CHECK-IR: %struct.S4 = type { i8, %__cheriseed_cap_t, i8 }

S4 s4{1, nullptr, 2};
// CHECK-ASM-LABEL: .globl s4
// CHECK-ASM-NEXT:  .p2align 4
//                  a
// CHECK-ASM:       .byte 1
// CHECK-ASM-NEXT:  .zero 15
//                  b
// CHECK-ASM-NEXT:  .zero 16
//                  c
// CHECK-ASM-NEXT:  .byte 2
// CHECK-ASM-NEXT:  .zero 15
// CHECK-ASM-NEXT:  .size s4, 48
