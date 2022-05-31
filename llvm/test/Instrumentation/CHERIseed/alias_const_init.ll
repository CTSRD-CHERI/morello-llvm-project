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

; CHECK: @case.1.a1 = alias i8* (), i8* ()* @case.1.g1
; CHECK: @case.1.a2 = alias i8* (), i8* ()* @case.1.g1
@case.1.a2 = alias i8, i8* @case.1.g1
; CHECK: @case.1.a3 = alias i8* (), i8* ()* @case.1.a2
@case.1.a3 = alias i8, i8* @case.1.a2

; CHECK-LABEL: define [5 x i8*]* @case.1.g2()
; CHECK-NEXT:  init.check:
; CHECK-NEXT:    %0 = load i8, i8* @__cheriseed_global_case.1.g2_shadow_flag, align 1
; CHECK-NEXT:    %1 = icmp eq i8 %0, 0
; CHECK-NEXT:    br i1 %1, label %init, label %exit
; CHECK-EMPTY:
; CHECK-NEXT:  init:
; CHECK-NEXT:    store i8 1, i8* @__cheriseed_global_case.1.g2_shadow_flag, align 1
; CHECK-NEXT:    %accessor.call.case.1.a1 = call i8* @case.1.a1()
; CHECK-NEXT:    store i8* %accessor.call.case.1.a1, i8** getelementptr inbounds ([5 x i8*], [5 x i8*]* @__cheriseed_global_case.1.g2, i32 0, i64 1), align 8
; CHECK-NEXT:    %accessor.call.case.1.a2 = call i8* @case.1.a2()
; CHECK-NEXT:    store i8* %accessor.call.case.1.a2, i8** getelementptr inbounds ([5 x i8*], [5 x i8*]* @__cheriseed_global_case.1.g2, i32 0, i64 2), align 8
; CHECK-NEXT:    %accessor.call.case.1.a3 = call i8* @case.1.a3()
; CHECK-NEXT:    store i8* %accessor.call.case.1.a3, i8** getelementptr inbounds ([5 x i8*], [5 x i8*]* @__cheriseed_global_case.1.g2, i32 0, i64 3), align 8
; CHECK-NEXT:    %accessor.call.case.1.a31 = call i8* @case.1.a3()
; CHECK-NEXT:    store i8* %accessor.call.case.1.a31, i8** getelementptr inbounds ([5 x i8*], [5 x i8*]* @__cheriseed_global_case.1.g2, i32 0, i64 4), align 8
; CHECK-NEXT:    br label %exit
; CHECK-EMPTY:
; CHECK-NEXT:  exit:
; CHECK-NEXT:    ret [5 x i8*]* @__cheriseed_global_case.1.g2

; ------------------------------------------------------------------------------
