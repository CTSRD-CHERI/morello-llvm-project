; RUN: opt -instcombine -march=arm64 -mattr=+c64 -target-abi purecap -S -o - %s | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none--elf"

@.str = private unnamed_addr addrspace(200) constant [5 x i8] c"dsad\00", align 1

; CHECK-LABEL: fun
define void @fun(ptr addrspace(200) %tt) addrspace(200) {
entry:
; CHECK: llvm.memcpy.p200i8.p200i8.i64
  %call = call ptr addrspace(200) @strcpy(ptr addrspace(200) %tt, ptr addrspace(200) @.str)
  ret void
}

declare ptr addrspace(200) @strcpy(ptr addrspace(200), ptr addrspace(200)) addrspace(200)
