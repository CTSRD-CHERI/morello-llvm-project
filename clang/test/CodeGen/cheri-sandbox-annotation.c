// XFAIL: *

// RUN: %clang -target cheri-unknown-freebsd -mabi=purecap  %s -O0 -S -emit-llvm -o - | FileCheck %s

// CHECK: private unnamed_addr addrspace(200) constant [17 x i8] c"introduced_in=23\00", section "llvm.metadata"
// CHECK: private unnamed_addr addrspace(200) constant [{{[0-9]+}} x i8] c"{{.*}}cheri-sandbox-annotation.c\00", section "llvm.metadata"
// CHECK: @llvm.global.annotations = appending addrspace(200) global [1 x { i8*, ptr addrspace(200), ptr addrspace(200), i32 }] [{ i8*, ptr addrspace(200), ptr addrspace(200), i32 } { i8* addrspacecast (ptr addrspace(200) bitcast (ptr addrspace(200) @breakme to ptr addrspace(200)) to i8*), ptr addrspace(200) getelementptr inbounds ([17 x i8], [17 x i8] addrspace(200)* @{{.*}}, i32 0, i32 0), ptr addrspace(200) getelementptr inbounds ([84 x i8], [84 x i8] addrspace(200)* @{{.*}}, i32 0, i32 0), i32 11 }], section "llvm.metadata"

#define __INTRODUCED_IN(api_level)  __attribute__((annotate("introduced_in=" #api_level)))

void breakme(void) __INTRODUCED_IN(23);

void breakme(void) {}
