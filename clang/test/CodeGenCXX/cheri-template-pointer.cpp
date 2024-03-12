// RUN: %clang_cc1 -triple cheri-unknown-freebsd -target-abi n64 %s -emit-llvm -o - | FileCheck %s

template <typename T> static inline T loadFromCap(T*  __capability address) {
  return *address;
}

// CHECK-LABEL: _Z3funU12__capabilityPi
// CHECK: call noundef signext i32 @{{.*}}loadFromCap{{.*}}(ptr addrspace(200)
int fun(int * __capability t) {
  return loadFromCap<int>(t);
}

// CHECK: loadFromCap
// CHECK: load i32, ptr addrspace(200) %0
// CHECK: ret i32
