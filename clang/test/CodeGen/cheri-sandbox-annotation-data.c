// RUN: %clang_cc1 -triple aarch64-none-elf -target-feature +c64 -target-abi purecap %s -O0 -S -emit-llvm -o - | FileCheck %s

// CHECK: @some_global = addrspace(200) global ptr addrspace(200) null, align 16
// CHECK: @.str = private unnamed_addr addrspace(200) constant [17 x i8] c"introduced_in=23\00", section "llvm.metadata"
// CHECK: @llvm.global.annotations = appending addrspace(200) global [1 x { ptr addrspace(200), ptr addrspace(200), ptr addrspace(200), i32, ptr addrspace(200) }] [{ ptr addrspace(200), ptr addrspace(200), ptr addrspace(200), i32, ptr addrspace(200) }
// CHECK-SAME: { ptr addrspace(200) @some_global, ptr addrspace(200) @.str, ptr addrspace(200) @.str.1, i32 [[#@LINE+4]], ptr addrspace(200) null }], section "llvm.metadata"

#define __INTRODUCED_IN(api_level)  __attribute__((annotate("introduced_in=" #api_level)))

void *some_global __INTRODUCED_IN(23);

