// RUN: %clang_cc1 -triple aarch64-none-elf -target-feature +morello -target-feature +c64 -target-abi purecap %s -emit-llvm -o - -O1 | FileCheck %s

// CHECK: define i8 addrspace(200)* @f1
// CHECK: [[RET:%.*]] = getelementptr
// CHECK-NEXT: ret i8 addrspace(200)* [[RET]]
__uintcap_t f1(__uintcap_t a1, unsigned long long a2) {
  return a1 + a2;
}
__uintcap_t f2(__uintcap_t a1, unsigned long long a2) {
// CHECK: define i8 addrspace(200)* @f2
// CHECK: [[RET:%.*]] = getelementptr
// CHECK-NEXT: ret i8 addrspace(200)* [[RET]]
  return a2 + a1;
}
