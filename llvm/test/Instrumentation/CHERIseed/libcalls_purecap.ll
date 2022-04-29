; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-pf200:128:128:128:64-S128-A200-P200-G200"
target triple = "x86_64-unknown-linux-gnu"

; ------------------------------------------------------------------------------
; Check transformation of syscall

; CHECK-LABEL: @transform_syscall
define void @transform_syscall(i32 %v, i32 addrspace(200)* %c) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %4 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %5 = alloca %__cheriseed_cap_t, align 16

; Instructions related to the load below
; CHECK-NEXT:  %6 = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 4, i32 1)
; CHECK-NEXT:  %7 = inttoptr i64 %6 to i32*
; CHECK-NEXT:  %8 = load i32, i32* %7, align 4
  %1 = load i32, i32 addrspace(200)* %c, align 4

; Prepareation of arguments to syscall
; CHECK-NEXT:  %9 = sext i32 %v to i64
; CHECK-NEXT:  %10 = tail call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:     %__cheriseed_cap_t* %2, %__cheriseed_cap_t* null, i64 %9)
; CHECK-NEXT:  %11 = sext i32 %8 to i64
; CHECK-NEXT:  %12 = tail call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:     %__cheriseed_cap_t* %3, %__cheriseed_cap_t* null, i64 %11)
; CHECK-NEXT:  %13 = tail call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:     %__cheriseed_cap_t* %4, %__cheriseed_cap_t* null, i64 5)
; CHECK-NEXT:  %14 = tail call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:     %__cheriseed_cap_t* %5, %__cheriseed_cap_t* null, i64 6)

; Call syscall
; CHECK-NEXT:  %15 = tail call %__cheriseed_cap_t* (%__cheriseed_cap_t*, i64, ...) @syscall(
; CHECK-SAME:     %__cheriseed_cap_t* returned align 16 %1,
; CHECK-SAME:     i64 1,
; CHECK-SAME:     %__cheriseed_cap_t* %10,
; CHECK-SAME:     %__cheriseed_cap_t* %12,
; CHECK-SAME:     %__cheriseed_cap_t* %c,
; CHECK-SAME:     %__cheriseed_cap_t* %13,
; CHECK-SAME:     %__cheriseed_cap_t* %14,
; CHECK-SAME:     %__cheriseed_cap_t* null)
  %2 = tail call i8 addrspace(200)* (i64, ...) @syscall(
    i64 1, i32 %v, i32 %1, i32 addrspace(200)* %c, i32 5, i32 6)

; CHECK-NEXT:  ret void
  ret void
}

; CHECK: declare %__cheriseed_cap_t* @syscall(%__cheriseed_cap_t* returned align 16, i64, ...)
declare i8 addrspace(200)* @syscall(i64, ...) addrspace(200)

; ------------------------------------------------------------------------------
