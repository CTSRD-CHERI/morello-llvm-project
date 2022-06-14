; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------
; Test use of aliases in constant initializers.

; Kept before '@case.1.g2' for testing purposes.
@case.1.a1 = alias i8, i8* @case.1.g1

; Kept before '@case.1.g1' for testing purposes.
; CHECK: @__cheriseed_global_case.1.g2 = global [5 x i8*] [i8* @__cheriseed_global_case.1.g1, i8* null, i8* null, i8* null, i8* null]
@case.1.g2 = global [5 x i8*] [i8* @case.1.g1, i8* @case.1.a1, i8* @case.1.a2, i8* @case.1.a3, i8* @case.1.a3]

; CHECK: @__cheriseed_global_case.1.g1 = global i8 1
@case.1.g1 = global i8 1

; CHECK:      @"__cheriseed_inits_<stdin>" = internal global [1 x %__cheriseed_initializer_t] [
; CHECK-SAME: { i64 0, i64 0, void ()* @__cheriseed_initializer_case.1.g2 }],
; CHECK-SAME: section "__cheriseed_initializers", align 8

; CHECK: @case.1.a1 = alias i8* (), i8* ()* @case.1.g1
; CHECK: @case.1.a2 = alias i8* (), i8* ()* @case.1.g1
@case.1.a2 = alias i8, i8* @case.1.g1
; CHECK: @case.1.a3 = alias i8* (), i8* ()* @case.1.a2
@case.1.a3 = alias i8, i8* @case.1.a2

; CHECK-LABEL:  define [5 x i8*]* @case.1.g2() {
; CHECK-NEXT:    ret [5 x i8*]* @__cheriseed_global_case.1.g2
; CHECK-NEXT:  }

; CHECK-LABEL:  define internal void @__cheriseed_initializer_case.1.g2() {
; CHECK-NEXT:    %accessor.call.case.1.a1 = call i8* @case.1.a1()
; CHECK-NEXT:    store i8* %accessor.call.case.1.a1, i8** getelementptr inbounds ([5 x i8*], [5 x i8*]* @__cheriseed_global_case.1.g2, i32 0, i64 1), align 8
; CHECK-NEXT:    %accessor.call.case.1.a2 = call i8* @case.1.a2()
; CHECK-NEXT:    store i8* %accessor.call.case.1.a2, i8** getelementptr inbounds ([5 x i8*], [5 x i8*]* @__cheriseed_global_case.1.g2, i32 0, i64 2), align 8
; CHECK-NEXT:    %accessor.call.case.1.a3 = call i8* @case.1.a3()
; CHECK-NEXT:    store i8* %accessor.call.case.1.a3, i8** getelementptr inbounds ([5 x i8*], [5 x i8*]* @__cheriseed_global_case.1.g2, i32 0, i64 3), align 8
; CHECK-NEXT:    %accessor.call.case.1.a31 = call i8* @case.1.a3()
; CHECK-NEXT:    store i8* %accessor.call.case.1.a31, i8** getelementptr inbounds ([5 x i8*], [5 x i8*]* @__cheriseed_global_case.1.g2, i32 0, i64 4), align 8
; CHECK-NEXT:    ret void
; CHECK-NEXT:  }

; CHECK-LABEL:  define i8* @case.1.g1() {
; CHECK-NEXT:    ret i8* @__cheriseed_global_case.1.g1
; CHECK-NEXT:  }

; CHECK-NOT:  define void @__cheriseed_initializer_case.1.g1()


; ------------------------------------------------------------------------------
