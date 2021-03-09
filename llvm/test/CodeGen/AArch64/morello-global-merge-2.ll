; RUN: llc %s -mtriple=aarch64-none-linux-gnu -mattr=+c64,+morello -target-abi purecap -aarch64-enable-global-merge -global-merge-on-external -o - | FileCheck %s
; RUN: llc %s -mtriple=aarch64-linux-gnuabi -mattr=+c64,+morello -target-abi purecap -aarch64-enable-global-merge -global-merge-on-external -o - | FileCheck %s

@x = dso_local addrspace(200) global i32 0, align 4
@y = dso_local addrspace(200) global i32 0, align 4
@z = dso_local addrspace(200) global i32 0, align 4

define void @f1(i32 %a1, i32 %a2) {
  store i32 %a1, i32 addrspace(200)* @x, align 4
  store i32 %a2, i32 addrspace(200)* @y, align 4
  ret void
}

define void @g1(i32 %a1, i32 %a2) {
  store i32 %a1, i32 addrspace(200)* @y, align 4
  store i32 %a2, i32 addrspace(200)* @z, align 4
  ret void
}

; CHECK:	.type	.L_MergedGlobals,@object // @_MergedGlobals
; CHECK:	.local	.L_MergedGlobals
; CHECK:	.comm	.L_MergedGlobals,12,4

; CHECK:	.globl	x
; CHECK: .set x, .L_MergedGlobals
; CHECK: .size x, 4
; CHECK:	.globl	y
; CHECK: .set y, .L_MergedGlobals+4
; CHECK: .size y, 4
; CHECK:	.globl	z
; CHECK: .set z, .L_MergedGlobals+8
; CHECK: .size z, 4
