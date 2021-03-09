; RUN: llc %s -mtriple=aarch64-none-linux-gnu -aarch64-enable-global-merge -target-abi purecap -mattr=+c64,+morello -o - | FileCheck %s
; RUN: llc %s -mtriple=aarch64-none-linux-gnu -aarch64-enable-global-merge -target-abi purecap -mattr=+c64,+morello -global-merge-on-external -o - | FileCheck %s

; RUN: llc %s -mtriple=aarch64-linux-gnuabi -aarch64-enable-global-merge -target-abi purecap -mattr=+c64,+morello -o - | FileCheck %s
; RUN: llc %s -mtriple=aarch64-linux-gnuabi -aarch64-enable-global-merge -target-abi purecap -mattr=+c64,+morello -global-merge-on-external -o - | FileCheck %s

@m = internal addrspace(200) global i32 0, align 4
@n = internal addrspace(200) global i32 0, align 4

define void @f1(i32 %a1, i32 %a2) {
  store i32 %a1, i32 addrspace(200)* @m, align 4
  store i32 %a2, i32 addrspace(200)* @n, align 4
  ret void
}

; CHECK:	.type	.L_MergedGlobals,@object  // @_MergedGlobals
; CHECK:	.local	.L_MergedGlobals
; CHECK:	.comm	.L_MergedGlobals,8,4
; CHECK: .set m, .L_MergedGlobals
; CHECK: .set n, .L_MergedGlobals+4

