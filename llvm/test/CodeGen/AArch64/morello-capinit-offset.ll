; RUN: llc -march=arm64 -mattr=+c64 -target-abi purecap -o - %s | FileCheck %s

target datalayout = "e-m:e-i64:64-i128:128-n32:64-S128-pf200:128:128:128:64-A200-P200-G200"
target triple = "aarch64-none--elf"

@str = addrspace(200) global [12 x i8] c"foo bar baz\00", align 1
@ptr1 = addrspace(200) global ptr addrspace(200) getelementptr inbounds ([12 x i8], ptr addrspace(200) @str, i32 0, i64 8), align 16
@ptr2 = addrspace(200) global ptr addrspace(200) @str, align 16

; CHECK-LABEL: str
; CHECK-LABEL: ptr1
; CHECK: .chericap str+8
; CHECK-LABEL: ptr2
; CHECK: .chericap str
