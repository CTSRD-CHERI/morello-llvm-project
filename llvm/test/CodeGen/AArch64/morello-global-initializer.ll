; RUN: llc -mtriple=arm64 -mattr=+morello -o - %s | FileCheck %s

; CHECK-LABEL: one:
; CHECK-NEXT: .chericap 1
; CHECK-NEXT: .size one, 16

@one = addrspace(200) global ptr addrspace(200) inttoptr (i64 1 to ptr addrspace(200)), align 16

