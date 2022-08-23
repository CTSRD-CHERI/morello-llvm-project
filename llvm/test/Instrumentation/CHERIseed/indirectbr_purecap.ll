; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-pf200:128:128:128:64-S128-A200-P200-G200"
target triple = "x86_64-unknown-linux-gnu"

; ------------------------------------------------------------------------------
; Check that indirectbr translates properly.

; CHECK-LABEL: @indirectbr
define void @indirectbr(i8 addrspace(200)* %branch) addrspace(200) {
; CHECK-NEXT:  %1 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %branch, i64 0, i32 2)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i8*
; CHECK-NEXT:  indirectbr i8* %2, [label %BB1, label %BB2]
  indirectbr i8 addrspace(200)* %branch, [label %BB1, label %BB2]

BB1:
  br label %BB2

BB2:
  ret void
}

; ------------------------------------------------------------------------------
