; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-pf200:128:128:128:64-S128-A200-P200-G200"
target triple = "x86_64-unknown-linux-gnu"

; ------------------------------------------------------------------------------
; Test @llvm.global_ctors and @llvm.global_dtors

%s = type { i32, void () addrspace(200)*, i8 addrspace(200)* }

; CHECK-LABEL: @llvm.global_ctors = appending global [1 x { i32, void ()*, i8* }] [
; CHECK-SAME:    { i32, void ()*, i8* } { i32 101, void ()* @bar, i8* null }
; CHECK-SAME:  ]
@llvm.global_ctors = appending addrspace(200) global [1 x %s] [
  %s { i32 101, void () addrspace(200)* @bar, i8 addrspace(200)* null }
]

; CHECK: @llvm.global_dtors = appending global [0 x { i32, void ()*, i8* }] zeroinitializer
@llvm.global_dtors = appending addrspace(200) global [0 x %s] zeroinitializer

define void @bar() {
  ret void
}

; ------------------------------------------------------------------------------
; Test @llvm.used

@char = addrspace(200) global i8 0, align 1
@int = addrspace(200) global i32 0, align 4
@ptr = addrspace(200) global i8 addrspace(200)* null, align 8
@cap_before = addrspace(200) global i8 addrspace(200)* null, align 16

define void @func() addrspace(200) {
  ret void
}

; CHECK-LABEL: @llvm.used = appending global [7 x i8*]
@llvm.used = appending addrspace(200) global [6 x i8*] [
; CHECK-SAME:  i8* bitcast (%__cheriseed_cap_t* @char to i8*)
  i8* addrspacecast (i8 addrspace(200)* @char to i8*),
; CHECK-SAME:  i8* bitcast (%__cheriseed_cap_t* @int to i8*)
  i8* addrspacecast (i8 addrspace(200)* bitcast (
    i32 addrspace(200)* @int to i8 addrspace(200)*) to i8*),
; CHECK-SAME:  i8* bitcast (%__cheriseed_cap_t* @ptr to i8*)
  i8* addrspacecast (i8 addrspace(200)* bitcast (
    i8 addrspace(200)* addrspace(200)* @ptr to i8 addrspace(200)*) to i8*),
; CHECK-SAME:  i8* bitcast (%__cheriseed_cap_t* @cap_before to i8*)
  i8* addrspacecast (i8 addrspace(200)* bitcast (
    i8 addrspace(200)* addrspace(200)* @cap_before to i8 addrspace(200)*) to i8*),
; CHECK-SAME:  i8* bitcast (%__cheriseed_cap_t* @cap_after to i8*)
  i8* addrspacecast (i8 addrspace(200)* bitcast (
    i8 addrspace(200)* addrspace(200)* @cap_after to i8 addrspace(200)*) to i8*),
; CHECK-SAME:  i8* bitcast (void ()* @func to i8*)
  i8* addrspacecast (i8 addrspace(200)* bitcast (
    void () addrspace(200)* @func to i8 addrspace(200)*) to i8*)
; CHECK-SAME:  section "llvm.metadata"
], section "llvm.metadata"

; Put after @llvm.used on purpose.
@cap_after = addrspace(200) global i8 addrspace(200)* null, align 16
