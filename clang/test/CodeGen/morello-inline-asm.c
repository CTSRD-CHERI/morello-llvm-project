// RUN: %clang_cc1 -triple aarch64-none-elf -target-feature +morello -target-feature +c64 -target-abi purecap %s -S -emit-llvm -o - 2>&1 | FileCheck %s

// CHECK-NOT: value size does not match register size specified by the constraint and modifier
// CHECK: define dso_local void @foo(ptr addrspace(200) noundef %{{.*}}) addrspace(200)
// CHECK:   call void asm sideeffect "mov c0, $0", "r"(ptr addrspace(200) %{{.*}})
void foo(char *p) {
    asm volatile ("mov c0, %0" :: "r"(p));
}
