// RUN: %clang_cc1 -triple aarch64-none--elf  -emit-llvm -target-feature +morello -target-feature +c64 -target-abi purecap %s -o - | FileCheck %s

__attribute((annotate("sfoo_0"))) __attribute((annotate("sfoo_1"))) char sfoo;

// CHECK: @sfoo = addrspace(200) global i8 0, align 1
// CHECK-NEXT: @.str = private unnamed_addr addrspace(200) constant [7 x i8] c"sfoo_0\00", section "llvm.metadata"
// CHECK-NEXT: @.str.1 = private unnamed_addr addrspace(200) constant
// CHECK-NEXT: @.str.2 = private unnamed_addr addrspace(200) constant [7 x i8] c"sfoo_1\00", section "llvm.metadata"
// CHECK-NEXT: @llvm.global.annotations = appending addrspace(200) global [2 x { ptr addrspace(200), ptr addrspace(200), ptr addrspace(200), i32, ptr addrspace(200) }] [{ ptr addrspace(200), ptr addrspace(200), ptr addrspace(200), i32, ptr addrspace(200) } { ptr addrspace(200) @sfoo, ptr addrspace(200) @.str, ptr addrspace(200) @.str.1, i32 3, ptr addrspace(200) null }, { ptr addrspace(200), ptr addrspace(200), ptr addrspace(200), i32, ptr addrspace(200) } { ptr addrspace(200) @sfoo, ptr addrspace(200) @.str.2, ptr addrspace(200) @.str.1, i32 3, ptr addrspace(200) null }], section "llvm.metadata"
