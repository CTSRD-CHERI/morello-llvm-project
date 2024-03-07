; RUN: llc -mtriple=arm64 -mattr=+c64,+morello,+use-16-cap-regs -target-abi purecap \
; RUN:     -cheri-stack-bounds-analysis=none -o - %s | FileCheck %s

target datalayout = "e-m:e-i64:64-i128:128-n32:64-S128-pf200:128:128:128:64-A200-P200-G200"

declare void @foo() addrspace(200)
declare i32 @bar(i64 addrspace(200)*, i32 addrspace(200)*, i16 addrspace(200)*, i8 addrspace(200)*, double addrspace(200)*, float addrspace(200)*) addrspace(200)
declare i32 @baz(i64, i32, i16, i8, double, float) addrspace(200)

; CHECK-LABEL: testStackVars
define i32 @testStackVars(i32 %argc, i8 addrspace(200)* addrspace(200)* %argv) addrspace(200) {
entry:
  %long = alloca i64, align 8, addrspace(200)
  %int = alloca i32, align 4, addrspace(200)
  %short = alloca i16, align 2, addrspace(200)
  %byte = alloca i8, addrspace(200)
  %double = alloca double, align 8, addrspace(200)
  %float = alloca float, align 4, addrspace(200)
  call void @foo()
  store i64 0, i64 addrspace(200)* %long, align 8
  store i32 0, i32 addrspace(200)* %int, align 4
  store i16 0, i16 addrspace(200)* %short, align 2
  store i8 0, i8 addrspace(200)* %byte
  store double 0.0, double addrspace(200)* %double, align 8
  store float 0.0, float addrspace(200)* %float, align 4
  %rv1 = call i32 @bar(i64 addrspace(200)* %long, i32 addrspace(200)* %int, i16 addrspace(200)* %short, i8 addrspace(200)* %byte, double addrspace(200)* %double, float addrspace(200)* %float)
  %ll = load i64, i64 addrspace(200)* %long, align 8
  %li = load i32, i32 addrspace(200)* %int, align 4
  %lh = load i16, i16 addrspace(200)* %short, align 2
  %lb = load i8, i8 addrspace(200)* %byte
  %ld = load double, double addrspace(200)* %double, align 8
  %lf = load float, float addrspace(200)* %float, align 4
  %rv2 = call i32 @baz(i64 %ll, i32 %li, i16 %lh, i8 %lb, double %ld, float %lf)
  %rv = add i32 %rv1, %rv2
  ret i32 %rv

; CHECK:      sub csp, csp, #160
; CHECK-NEXT: .cfi_def_cfa csp, -160
; CHECK-NEXT: str c29, [csp, #32]
; CHECK-NEXT: stp c30, c28, [csp, #48]
; CHECK-NEXT: stp c27, c26, [csp, #80]
; CHECK-NEXT: stp c25, c24, [csp, #112]
; CHECK-NEXT: str x19, [csp, #144]

; CHECK:        bl      foo
; CHECK-NEXT:   add     c0, csp, #152
; CHECK-NEXT:   add     c1, csp, #28
; CHECK-NEXT:   scbnds  c24, c0, #8
; CHECK-NEXT:   add     c0, csp, #24
; CHECK-NEXT:   scbnds  c26, c0, #2
; CHECK-NEXT:   add     c0, csp, #20
; CHECK-NEXT:   scbnds  c27, c0, #1
; CHECK-NEXT:   add     c0, csp, #8
; CHECK-NEXT:   scbnds  c28, c0, #8
; CHECK-NEXT:   add     c0, csp, #4
; CHECK-NEXT:   scbnds  c25, c1, #4
; CHECK-NEXT:   scbnds  c29, c0, #4

; CHECK-DAG:	mov	c0, c24
; CHECK-DAG:	mov	c1, c25
; CHECK-DAG:	mov	c2, c26
; CHECK-DAG:	mov	c3, c27
; CHECK-DAG:	mov	c4, c28
; CHECK-DAG:	mov	c5, c29
; CHECK:  	str	xzr, [c24]
; CHECK-DAG:	str	wzr, [c25]
; CHECK-DAG:	strh	wzr, [c26]
; CHECK-DAG:	strb	wzr, [c27]
; CHECK-DAG:	str	xzr, [c28]
; CHECK-DAG:	str	wzr, [c29]

; CHECK:   	bl	bar
; CHECK-DAG:	ldr	x0, [c24]
; CHECK-DAG:	ldr	w1, [c25]
; CHECK-DAG:	ldr	d0, [c28]
; CHECK-DAG:	ldr	s1, [c29]
; CHECK-DAG:	ldrb	w3, [c27]
; CHECK-DAG:	ldrh	w2, [c26]

; CHECK:	bl	baz

; CHECK:      ldp c25, c24, [csp, #112]
; CHECK-NEXT: ldp c27, c26, [csp, #80]
; CHECK-NEXT: ldp c30, c28, [csp, #48]
; CHECK-NEXT: ldr c29, [csp, #32]
; CHECK-NEXT: add w0,
; CHECK-NEXT: ldr x19, [csp, #144]
; CHECK-NEXT: add csp, csp, #160
}
