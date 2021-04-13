; RUN: llc -mtriple=arm64 -mattr=+morello -o - %s | FileCheck %s

; CHECK-LABEL: one
; CHECK: .xword 1
; CHECK-NEXT: .xword 0
; CHECK-NEXT: .size one, 1

@one = addrspace(200) global i8 addrspace(200)* inttoptr (i64 1 to i8 addrspace(200)*), align 16

