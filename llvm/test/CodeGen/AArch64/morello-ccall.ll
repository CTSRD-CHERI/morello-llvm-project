; RUN: llc -mtriple=arm64 -mattr=+morello,+c64  -target-abi purecap -o - %s | FileCheck --check-prefix=CHECK --check-prefix=C64 %s
; RUN: llc -mtriple=arm64 -mattr=+morello -o - %s | FileCheck --check-prefix=CHECK --check-prefix=A64 %s

define chericcallcc i32 @bar(i8 addrspace(200) * %ddc,  i8 addrspace(200) * %pcc, i32 %num, i32 %a, i32 %b, i32 %c) {
; CHECK-LABEL:bar:
; CHECK: add w0, w1, w0
; CHECK-DAG: mov x1, xzr
; CHECK-DAG: mov x2, xzr
; CHECK-DAG: mov x3, xzr
; CHECK-DAG: mov x4, xzr
; CHECK-DAG: mov x5, xzr
; CHECK-DAG: mov x6, xzr
; CHECK-DAG: mov x7, xzr
; CHECK-DAG: fmov d0, xzr
; CHECK-DAG: fmov d1, xzr
; CHECK-DAG: fmov d2, xzr
; CHECK-DAG: fmov d3, xzr
; CHECK-DAG: fmov d4, xzr
; CHECK-DAG: fmov d5, xzr
; CHECK-DAG: fmov d6, xzr
; CHECK-DAG: fmov d7, xzr
; CHECK-NEXT:	ret
entry:
  %add = add nsw i32 %b, %a
  ret i32 %add
}

define chericcallcc double @barf(i8 addrspace(200) * %ddc,  i8 addrspace(200) * %pcc, i32 %num, double %a, double %b, double %c) {
; CHECK-LABEL:barf:
; CHECK-DAG: mov x0, xzr
; CHECK-DAG: mov x1, xzr
; CHECK-DAG: mov x2, xzr
; CHECK-DAG: mov x3, xzr
; CHECK-DAG: mov x4, xzr
; CHECK-DAG: mov x5, xzr
; CHECK-DAG: mov x6, xzr
; CHECK-DAG: mov x7, xzr
; CHECK-DAG: fmov d1, xzr
; CHECK-DAG: fmov d2, xzr
; CHECK-DAG: fmov d3, xzr
; CHECK-DAG: fmov d4, xzr
; CHECK-DAG: fmov d5, xzr
; CHECK-DAG: fmov d6, xzr
; CHECK-DAG: fmov d7, xzr
; CHECK-NEXT:	ret
entry:
  %add = fadd double %b, %a
  %add1 = fadd double %add, %c
  ret double %add1
}

@c = external global i32, align 4
@d = external global double, align 8

define void @foo(i8 addrspace(200) * %ddc, i8 addrspace(200) * %pcc, i32 %num, i32 %a, double %b) {
; CHECK-LABEL:foo:

; C64: stp     d9, d8, [csp, #-{{[0-9]+}}]!
; C64-NEXT: str     c30, [csp, #{{[0-9]+}}]
; C64-NEXT: stp     c24, c23, [csp, #{{[0-9]+}}]
; C64-NEXT: stp     c22, c21, [csp, #{{[0-9]+}}]
; C64-NEXT: stp     c20, c19, [csp, #{{[0-9]+}}]

; A64: stp     d9, d8, [sp, #-{{[0-9]+}}]!
; A64-NEXT: str     x30, [sp, #{{[0-9]+}}]
; A64-NEXT: stp     x24, x23, [sp, #{{[0-9]+}}]
; A64-NEXT: stp     x22, x21, [sp, #{{[0-9]+}}]
; A64-NEXT: stp     x20, x19, [sp, #{{[0-9]+}}]

; CHECK-DAG:    mov x3, xzr
; CHECK-DAG:    mov x4, xzr
; CHECK-DAG:    mov x5, xzr
; CHECK-DAG:    mov x6, xzr
; CHECK-DAG:    mov x7, xzr
; CHECK-DAG:    mov x8, xzr
; CHECK-DAG:    fmov d0, xzr
; CHECK-DAG:    fmov d1, xzr
; CHECK-DAG:    fmov d2, xzr
; CHECK-DAG:    fmov d3, xzr
; CHECK-DAG:    fmov d4, xzr
; CHECK-DAG:    fmov d5, xzr
; CHECK-DAG:    fmov d6, xzr
; CHECK-DAG:    fmov d7, xzr
; CHECK-NEXT:	bl	bar

; CHECK-DAG:    mov x0, xzr
; CHECK-DAG:    mov x1, xzr
; CHECK-DAG:    mov x2, xzr
; CHECK-DAG:    mov x3, xzr
; CHECK-DAG:    mov x4, xzr
; CHECK-DAG:    mov x5, xzr
; CHECK-DAG:    mov x6, xzr
; CHECK-DAG:    mov x7, xzr
; CHECK-DAG:    mov x8, xzr
; CHECK-DAG:    fmov d3, xzr
; CHECK-DAG:    fmov d4, xzr
; CHECK-DAG:    fmov d5, xzr
; CHECK-DAG:    fmov d6, xzr
; CHECK-DAG:    fmov d7, xzr
; CHECK-NEXT:	bl	barf

; C64:      ldp     c20, c19, [csp, #{{[0-9]+}}]
; C64-NEXT: ldp     c22, c21, [csp, #{{[0-9]+}}]
; C64-NEXT: ldp     c24, c23, [csp, #{{[0-9]+}}]
; C64-NEXT: ldr     c30, [csp, #{{[0-9]+}}]
; C64-NEXT: ldp     d9, d8, [csp], #{{[0-9]+}}

; A64:      ldp     x20, x19, [sp, #{{[0-9]+}}]
; A64-NEXT: ldp     x22, x21, [sp, #{{[0-9]+}}]
; A64-NEXT: ldp     x24, x23, [sp, #{{[0-9]+}}]
; A64-NEXT: ldr     x30, [sp, #{{[0-9]+}}]
; A64-NEXT: ldp     d9, d8, [sp], #{{[0-9]+}}

entry:
  %0 = load i32, i32* @c, align 4
  %call = tail call chericcallcc i32 @bar(i8 addrspace(200) *%ddc, i8 addrspace(200) * %pcc, i32 %num, i32 %a, i32 %0, i32 1)
  %add = add nsw i32 %call, %0
  store i32 %add, i32* @c, align 4
  %1 = load double, double* @d, align 8
  %call1 = tail call chericcallcc double @barf(i8 addrspace(200) *%ddc, i8 addrspace(200) * %pcc, i32 %num, double %b, double %b, double %1)
  %add2 = fadd double %1, %call1
  store double %add2, double* @d, align 8
  ret void
}
