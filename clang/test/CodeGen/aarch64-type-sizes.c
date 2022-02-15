// RUN: %clang_cc1 -triple aarch64_be-none-linux-gnu -emit-llvm -w -o - %s \
// RUN:   | FileCheck --check-prefix=CHECK --check-prefix=CHECK-BASE %s
// RUN: %clang_cc1 -triple aarch64_be-none-linux-gnu -target-feature +morello -emit-llvm -w -o - %s \
// RUN:   | FileCheck --check-prefix=CHECK --check-prefix=CHECK-HYBRID %s
// RUN: %clang_cc1 -triple aarch64_be-none-linux-gnu -target-feature +c64 -target-abi purecap -emit-llvm -w -o - %s \
// RUN:   | FileCheck --check-prefix=CHECK --check-prefix=CHECK-PURECAP %s
// RUN: %clang_cc1 -triple aarch64_be-none-linux-gnu -target-feature +c64 -target-abi purecap -emit-llvm -w -o - -mllvm -cheri-cap-table-abi=pcrel %s \
// RUN:   | FileCheck --check-prefix=CHECK --check-prefix=CHECK-PURECAP %s
// char by definition has size 1

// CHECK-BASE: target datalayout = "E-m:e-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128"
// CHECK-HYBRID: target datalayout = "E-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128"
// CHECK-PURECAP: target datalayout = "E-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"

int check_short(void) {
  return sizeof(short);
// CHECK: ret i32 2
}

int check_int(void) {
  return sizeof(int);
// CHECK: ret i32 4
}

int check_long(void) {
// Both 4 and 8 are permitted under the PCS, Linux says 8!
  return sizeof(long);
// CHECK: ret i32 8
}

int check_longlong(void) {
  return sizeof(long long);
// CHECK: ret i32 8
}

int check_int128(void) {
  return sizeof(__int128);
// CHECK: ret i32 16
}

int check_fp16(void) {
  return sizeof(__fp16);
// CHECK: ret i32 2
}

int check_float(void) {
  return sizeof(float);
// CHECK: ret i32 4
}

int check_double(void) {
  return sizeof(double);
// CHECK: ret i32 8
}

int check_longdouble(void) {
  return sizeof(long double);
// CHECK: ret i32 16
}

int check_floatComplex(void) {
  return sizeof(float _Complex);
// CHECK: ret i32 8
}

int check_doubleComplex(void) {
  return sizeof(double _Complex);
// CHECK: ret i32 16
}

int check_longdoubleComplex(void) {
  return sizeof(long double _Complex);
// CHECK: ret i32 32
}

int check_bool(void) {
  return sizeof(_Bool);
// CHECK: ret i32 1
}

int check_wchar(void) {
// PCS allows either unsigned short or unsigned int. Linux again says "bigger!"
  return sizeof(__WCHAR_TYPE__);
// CHECK: ret i32 4
}

int check_wchar_unsigned(void) {
  return (__WCHAR_TYPE__)-1 > (__WCHAR_TYPE__)0;
// CHECK: ret i32 1
}

enum Small {
  Item
};

int foo(void) {
  return sizeof(enum Small);
// CHECK: ret i32 4
}

int check_pointer() {
  return sizeof(int *);
// CHECK-BASE: ret i32 8
// CHECK-HYBRID: ret i32 8
// CHECK-PURECAP: ret i32 16
}

#ifdef __CHERI__
int check_capability_pointer() {
  return sizeof(int *__capability);
// CHECK-HYBRID: ret i32 16
// CHECK-PURECAP: ret i32 16
}
#endif
