// RUN: %clang_cc1 -triple aarch64-none-elf -target-feature +c64 -target-abi purecap -mllvm -cheri-cap-table-abi=pcrel -emit-llvm -o - %s | FileCheck %s

// type_info type for 'typeid' to work.
namespace std { class type_info; }

// CHECK: [[TI_GLOBAL:@_ZTI[a-zA-Z]+]] = external addrspace(200) constant ptr addrspace(200)

void f() {
  // CHECK: store ptr addrspace(200) [[TI_GLOBAL]], ptr addrspace(200) %t, align 16
  const std::type_info& t = typeid(bool);
}
