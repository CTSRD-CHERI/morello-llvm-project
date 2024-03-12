// RUN: %clang_cc1 -triple cheri-unknown-freebsd -target-abi n64 -emit-llvm -o - %s | FileCheck %s

struct s1 {
  long size;
};

struct s2 : public s1 {
};

const s2* __capability c_s2;
// CHECK-LABEL: _Z4funcv
// CHECK: load ptr addrspace(200), ptr @c_s2, align 16
const long & __capability func()
{
    return c_s2->size;
}
