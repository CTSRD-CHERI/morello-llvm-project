; RUN: llc -march=arm64 -mattr=+morello,+c64 -target-abi purecap -o - %s | FileCheck  %s

target datalayout = "e-m:e-i64:64-i128:128-n32:64-S128-pf200:128:128:128:64-A200-P200-G200"
target triple = "aarch64-none--elf"

$g = comdat any

@i = addrspace(200) global i32 1, align 4
@j = addrspace(200) global ptr addrspace(200) @i, align 16
@f = addrspace(200) global ptr addrspace(200) @foo, align 16
@g = addrspace(200) global ptr addrspace(200) @foo, align 16, comdat

; Function Attrs: nounwind readnone
define void @foo() addrspace(200) {
  ret void
}

; CHECK:      j:
; CHECK-NEXT: 	.chericap i
; CHECK-NEXT: 	.size	j, 16

; CHECK: f:
; CHECK-NEXT: 	.chericap foo
; CHECK-NEXT: 	.size	f, 16

; CHECK: g:
; CHECK-NEXT: 	.chericap foo
; CHECK-NEXT: 	.size	g, 16

; CHECK-NOT: __cap_relocs
