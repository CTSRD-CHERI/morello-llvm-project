; RUN: opt -instcombine < %s -S -o - | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"

@a = common dso_local addrspace(200) global ptr addrspace(200) null, align 16

; CHECK-LABEL: foo
define dso_local i32 @foo() local_unnamed_addr addrspace(200) {
entry:
; CHECK: call ptr addrspace(200) @malloc
  %call = call ptr addrspace(200) @realloc(ptr addrspace(200) null, i64 0)
  store ptr addrspace(200) %call, ptr addrspace(200) @a, align 16
  ret i32 undef
}

declare ptr addrspace(200) @realloc(ptr addrspace(200), i64) addrspace(200)
