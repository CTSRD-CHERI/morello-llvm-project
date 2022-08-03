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
; CHECK: @case.1.g2 = global [5 x i8*] [i8* @case.1.g1, i8*  @case.1.a1, i8*  @case.1.a2, i8*  @case.1.a3, i8*  @case.1.a3]
@case.1.g2 = global [5 x i8*] [
    i8* @case.1.g1, i8* @case.1.a1, i8* @case.1.a2, i8* @case.1.a3, i8* @case.1.a3
]

; CHECK: @case.1.g1 = global i8 1
@case.1.g1 = global i8 1

; CHECK: @case.1.a1 = alias i8, i8* @case.1.g1
; CHECK: @case.1.a2 = alias i8, i8* @case.1.g1
@case.1.a2 = alias i8, i8* @case.1.g1
; CHECK: @case.1.a3 = alias i8, i8* @case.1.a2
@case.1.a3 = alias i8, i8* @case.1.a2

; ------------------------------------------------------------------------------
