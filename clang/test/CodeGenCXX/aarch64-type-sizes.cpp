// RUN: %clang_cc1 -triple aarch64_be-none-linux-gnu -emit-llvm -w -o - %s \
// RUN:   | FileCheck --check-prefix=CHECK-BASE %s
// RUN: %clang_cc1 -triple aarch64_be-none-linux-gnu -target-feature +morello -emit-llvm -w -o - %s \
// RUN:   | FileCheck --check-prefix=CHECK-HYBRID %s
// RUN: %clang_cc1 -triple aarch64_be-none-linux-gnu -target-feature +c64 -target-abi purecap -mllvm -cheri-cap-table-abi=pcrel -emit-llvm -w -o - %s \
// RUN:   | FileCheck --check-prefix=CHECK-PURECAP %s

// CHECK-BASE: target datalayout = "E-m:e-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128"
// CHECK-HYBRID: target datalayout = "E-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128"
// CHECK-PURECAP: target datalayout = "E-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"

int check_pointer() {
  return sizeof(int *);
// CHECK-BASE: ret i32 8
// CHECK-HYBRID: ret i32 8
// CHECK-PURECAP: ret i32 16
}

#if defined(__CHERI__) || defined(__CHERI_HYBRID__)
int check_capability_pointer() {
  return sizeof(int *__capability);
// CHECK-HYBRID: ret i32 16
// CHECK-PURECAP: ret i32 16
}

int check_capability_reference() {
  struct A {
    int &__capability v;
  };
  return sizeof(A);
// CHECK-HYBRID: ret i32 16
// CHECK-PURECAP: ret i32 16
}

int check_capability_rvalue_reference() {
  struct A {
    int &&__capability v;
  };
  return sizeof(A);
// CHECK-HYBRID: ret i32 16
// CHECK-PURECAP: ret i32 16
}
#endif
