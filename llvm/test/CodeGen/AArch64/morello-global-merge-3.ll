; RUN: llc %s -mtriple=aarch64-none-linux-gnu -mattr=+c64,+morello -target-abi purecap -aarch64-enable-global-merge -global-merge-on-external -disable-post-ra -o - | FileCheck %s
; RUN: llc %s -mtriple=aarch64-linux-gnuabi -mattr=+c64,+morello -target-abi purecap -aarch64-enable-global-merge -global-merge-on-external -disable-post-ra -o - | FileCheck %s

@x = dso_local addrspace(200) global [100 x i32] zeroinitializer, align 1
@y = dso_local addrspace(200) global [100 x i32] zeroinitializer, align 1
@z = internal addrspace(200) global i32 1, align 4

; CHECK-LABEL: f1:
define void @f1(i32 %a1, i32 %a2, i32 %a3) {
; CHECK:	adrp	c3, :got:x
; CHECK:	ldr	c3, [c3, :got_lo12:x]
; CHECK:	adrp	c4, .L__cap_merged_table
; CHECK:	ldr	c4, [c4, :lo12:.L__cap_merged_table]
; CHECK:	adrp	c5, :got:y
; CHECK:	ldr	c5, [c5, :got_lo12:y]
; CHECK:	str	w0, [c3, #12]
; CHECK:	str	w1, [c5, #12]
; CHECK:	str	w2, [c4]

  %x3 = getelementptr inbounds [100 x i32], [100 x i32] addrspace(200)* @x, i32 0, i64 3
  %y3 = getelementptr inbounds [100 x i32], [100 x i32] addrspace(200)* @y, i32 0, i64 3
  store i32 %a1, i32 addrspace(200)* %x3, align 4
  store i32 %a2, i32 addrspace(200)* %y3, align 4
  store i32 %a3, i32 addrspace(200)* @z, align 4
  ret void
}

; CHECK: .type   .L_MergedGlobals,@object // @_MergedGlobals
; CHECK-LABEL: .L_MergedGlobals:
; CHECK-NEXT: 	.word	1
; CHECK-NEXT:	.zero	400
; CHECK-NEXT:	.zero	400
; CHECK-NEXT:	.size	.L_MergedGlobals, 804


; CHECK-LABEL: .L__cap_merged_table:
; CHECK-NEXT:	.chericap z
; CHECK-NEXT:	.size	.L__cap_merged_table, 16

; CHECK: .set z, .L_MergedGlobals
; CHECK-NEXT: .size	z, 4
; CHECK-NEXT: globl  x
; CHECK-NEXT: .set x, .L_MergedGlobals+4
; CHECK-NEXT: .size	x, 400
; CHECK-NEXT: globl  y
; CHECK-NEXT: .set y, .L_MergedGlobals+404
; CHECK-NEXT: .size	y, 400
