; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-pf200:128:128:128:64-S128-A200-P200-G200"
target triple = "x86_64-unknown-linux-gnu"

%s = type { i32, void () addrspace(200)*, i8 addrspace(200)* }

; CHECK: @llvm.global_ctors = appending global [1 x { i32, void ()*, i8* }] [{ i32, void ()*, i8* } { i32 101, void ()* @bar, i8* null }]
@llvm.global_ctors = appending addrspace(200) global [1 x %s] [%s { i32 101, void () addrspace(200)* @bar, i8 addrspace(200)* null }]

; CHECK: @llvm.global_dtors = appending global [0 x { i32, void ()*, i8* }] zeroinitializer
@llvm.global_dtors = appending addrspace(200) global [0 x %s] zeroinitializer

define void @bar() {
  ret void
}
