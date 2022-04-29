; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-pf200:128:128:128:64-S128-A200-P200-G200"
target triple = "x86_64-unknown-linux-gnu"

; ------------------------------------------------------------------------------
; __attribute__((section("SECTION")))

; CHECK:      @__cheriseed_global_global_in_section = global i8 0
; CHECK-SAME:   section "SECTION", align 8
@global_in_section = addrspace(200) global i8 0, section "SECTION", align 8
; CHECK:      @global_in_section_SECTION =
; CHECK-SAME:   constant i8* bitcast (%__cheriseed_cap_t* ()* @global_in_section to i8*),
; CHECK-SAME:   section "__cheriseed_accessor_SECTION", align 16
; CHECK:      @__cheriseed_shadow_capability_global_in_section
; CHECK-SAME:   global %__cheriseed_cap_t { i128 -1 },
; CHECK-SAME:   section "__cheriseed_shadow_capability_SECTION", align 16

; ------------------------------------------------------------------------------
; Regression test for a global case when @global_2 is resolved later and so
; it becomes a deferred value.

%struct.S = type { i8 addrspace(200)* }

; CHECK: @__cheriseed_global_global_1 = internal global [1 x %struct.S] zeroinitializer, align 16
@global_1 = internal addrspace(200) constant [1 x %struct.S] [%struct.S {
  i8 addrspace(200)* getelementptr inbounds ([0 x i8], [0 x i8] addrspace(200)* @global_2, i32 0, i32 0)
}], align 16
; CHECK:      @__cheriseed_shadow_capability_global_1 =
; CHECK-SAME:   internal global %__cheriseed_cap_t { i128 -1 }, align 16
@global_2 = external addrspace(200) constant [0 x i8], align 1

define void @global_regression() addrspace(200) {
  %1 = getelementptr inbounds [1 x %struct.S], [1 x %struct.S] addrspace(200)* @global_1, i64 0, i64 0
  ret void
}

; ------------------------------------------------------------------------------
