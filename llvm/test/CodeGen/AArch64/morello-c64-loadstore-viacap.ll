; RUN: llc -mtriple=arm64 -mattr=+morello,+c64 -target-abi purecap -o - %s | FileCheck %s

; CHECK-LABEL: LoadI64WithConstantOffsetUnscaled
define i64 @LoadI64WithConstantOffsetUnscaled(i64 * %foo) {
entry:
; CHECK-DAG: ldur	{{x[0-9]+}}, [x0, #8]
; CHECK-DAG: ldur	{{x[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds i64, i64 * %foo, i64 1
  %0 = load i64, i64 * %fptr, align 8
  %1 = load i64, i64 * %foo, align 8
  %res = add i64 %0, %1
  ret i64 %res
}

; CHECK-LABEL: StoreI64WithConstantOffsetUnscaled
define void @StoreI64WithConstantOffsetUnscaled(i64 * %foo, i64 %bar) {
entry:
; CHECK-DAG: stur	x1, [x0, #8]
; CHECK-DAG: stur	x1, [x0, #0]
  %fptr = getelementptr inbounds i64, i64 * %foo, i64 1
  store i64 %bar, i64 * %fptr, align 8
  store i64 %bar, i64 * %foo, align 8
  ret void
}

; CHECK-LABEL: LoadI32WithConstantOffsetUnscaled
define i32 @LoadI32WithConstantOffsetUnscaled(i32 * %foo) {
entry:
; CHECK-DAG: ldur	{{w[0-9]+}}, [x0, #4]
; CHECK-DAG: ldur	{{w[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds i32, i32 * %foo, i64 1
  %0 = load i32, i32 * %fptr, align 4
  %1 = load i32, i32 * %foo, align 4
  %res = add i32 %0, %1
  ret i32 %res
}

; CHECK-LABEL: LoadI8SignedWithWithConstantOffsetPre
define i32 @LoadI8SignedWithWithConstantOffsetPre(i8 * %a) {
entry:
   br label %loop
loop:
; CHECK: ldursb	{{w[0-9]+}}, [x0, #0]
   %a.ptr = phi i8 * [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i8, i8 * %a.ptr, i64 1
   %ld = load i8, i8 * %a.ptr, align 1
   %cond = icmp sgt i8 %ld, -1
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI8SignedWithWithConstantOffsetWPre
define i32 @LoadI8SignedWithWithConstantOffsetWPre(i8 * %a, i64 %end) {
entry:
   br label %loop
loop:
; CHECK: ldursb	{{x[0-9]+}}, [x0, #0]
   %a.ptr = phi i8 * [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i8, i8 * %a.ptr, i64 1
   %ld = load i8, i8 * %a.ptr, align 1
   %ld.ext = sext i8 %ld to i64
   %cond = icmp sgt i64 %ld.ext, %end
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI16SignedWithWithConstantOffsetPre
define i32 @LoadI16SignedWithWithConstantOffsetPre(i16 * %a) {
entry:
   br label %loop
loop:
; CHECK: ldursh   w8, [x0, #0]
   %a.ptr = phi i16 * [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i16, i16 * %a.ptr, i64 1
   %ld = load i16, i16 * %a.ptr, align 1
   %cond = icmp sgt i16 %ld, -1
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI16SignedWithWithConstantOffsetWPre
define i32 @LoadI16SignedWithWithConstantOffsetWPre(i16 * %a, i64 %end) {
entry:
   br label %loop
loop:
; CHECK: ldursh   x{{[0-9]+}}, [x0, #0]
   %a.ptr = phi i16 * [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i16, i16 * %a.ptr, i64 1
   %ld = load i16, i16 * %a.ptr, align 1
   %ld.ext = sext i16 %ld to i64
   %cond = icmp sgt i64 %ld.ext, %end
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI32SignedWithWithConstantOffsetPre
define i32 @LoadI32SignedWithWithConstantOffsetPre(i32 * %a,
                                                    i64 %end) {
entry:
   br label %loop
loop:
; CHECK: ldursw  {{x[0-9]+}}, [x0, #0]
   %a.ptr = phi i32 * [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i32, i32 * %a.ptr, i64 1
   %ld = load i32, i32 * %a.ptr, align 1
   %ld.ext = sext i32 %ld to i64
   %cond = icmp sgt i64 %ld.ext, %end
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI8UnsignedWithWithConstantOffsetPre
define i32 @LoadI8UnsignedWithWithConstantOffsetPre(i8 * %a) {
entry:
   br label %loop
loop:
; CHECK: ldurb	{{w[0-9]+}}, [x0, #0]
   %a.ptr = phi i8 * [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i8, i8 * %a.ptr, i64 1
   %ld = load i8, i8 * %a.ptr, align 1
   %cond = icmp ugt i8 %ld, 20
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI16UnsignedWithWithConstantOffsetPre
define i32 @LoadI16UnsignedWithWithConstantOffsetPre(i16 * %a) {
entry:
   br label %loop
loop:
; CHECK: ldurh   {{w[0-9]+}}, [x0, #0]
   %a.ptr = phi i16 * [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i16, i16 * %a.ptr, i64 1
   %ld = load i16, i16 * %a.ptr, align 1
   %cond = icmp ugt i16 %ld, 20
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI32UnsignedWithWithConstantOffsetPre
define i32 @LoadI32UnsignedWithWithConstantOffsetPre(i32 * %a,
                                                    i64 %end) {
entry:
   br label %loop
loop:
; CHECK: ldur  {{w[0-9]+}}, [x0, #0]
   %a.ptr = phi i32 * [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i32, i32 * %a.ptr, i64 1
   %ld = load i32, i32 * %a.ptr, align 1
   %ld.ext = zext i32 %ld to i64
   %cond = icmp ugt i64 %ld.ext, %end
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI8SignedWithWithConstantOffsetPost
define i32 @LoadI8SignedWithWithConstantOffsetPost(i8 * %a) {
entry:
   br label %loop
loop:
; CHECK: ldursb	{{w[0-9]+}}, [x{{[0-9]+}}, #0]
   %a.ptr = phi i8 * [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i8, i8 * %a.ptr, i64 1
   %ld = load i8, i8 * %a.ptr.inc, align 1
   %cond = icmp sgt i8 %ld, -1
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI8SignedWithWithConstantOffsetWPost
define i32 @LoadI8SignedWithWithConstantOffsetWPost(i8 * %a, i64 %end) {
entry:
   br label %loop
loop:
; CHECK: ldursb	{{x[0-9]+}}, [x{{[0-9]+}}, #0]
   %a.ptr = phi i8 * [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i8, i8 * %a.ptr, i64 1
   %ld = load i8, i8 * %a.ptr.inc, align 1
   %ld.ext = sext i8 %ld to i64
   %cond = icmp sgt i64 %ld.ext, %end
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI16SignedWithWithConstantOffsetPost
define i32 @LoadI16SignedWithWithConstantOffsetPost(i16 * %a) {
entry:
   br label %loop
loop:
; CHECK: ldursh   {{w[0-9]+}}, [x{{[0-9]+}}, #0]
   %a.ptr = phi i16 * [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i16, i16 * %a.ptr, i64 1
   %ld = load i16, i16 * %a.ptr.inc, align 1
   %cond = icmp sgt i16 %ld, -1
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI16SignedWithWithConstantOffsetWPost
define i32 @LoadI16SignedWithWithConstantOffsetWPost(i16 * %a, i64 %end) {
entry:
   br label %loop
loop:
; CHECK: ldursh   {{x[0-9]+}}, [x{{[0-9]+}}, #0]
   %a.ptr = phi i16 * [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i16, i16 * %a.ptr, i64 1
   %ld = load i16, i16 * %a.ptr.inc, align 1
   %ld.ext = sext i16 %ld to i64
   %cond = icmp sgt i64 %ld.ext, %end
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}


; CHECK-LABEL: LoadI32SignedWithWithConstantOffsetPost
define i32 @LoadI32SignedWithWithConstantOffsetPost(i32 * %a,
                                                    i64 %end) {
entry:
   br label %loop
loop:
; CHECK: ldursw  {{x[0-9]+}}, [x{{[0-9]+}}, #0]
   %a.ptr = phi i32 * [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i32, i32 * %a.ptr, i64 1
   %ld = load i32, i32 * %a.ptr.inc, align 1
   %ld.ext = sext i32 %ld to i64
   %cond = icmp sgt i64 %ld.ext, %end
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI8UnsignedWithWithConstantOffsetPost
define i32 @LoadI8UnsignedWithWithConstantOffsetPost(i8 * %a) {
entry:
   br label %loop
loop:
; CHECK: ldurb	{{w[0-9]+}}, [x{{[0-9]+}}, #0]
   %a.ptr = phi i8 * [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i8, i8 * %a.ptr, i64 1
   %ld = load i8, i8 * %a.ptr.inc, align 1
   %cond = icmp ugt i8 %ld, 20
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI16UnsignedWithWithConstantOffsetPost
define i32 @LoadI16UnsignedWithWithConstantOffsetPost(i16 * %a) {
entry:
   br label %loop
loop:
; CHECK: ldurh   {{w[0-9]+}}, [x{{[0-9]+}}, #0]
   %a.ptr = phi i16 * [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i16, i16 * %a.ptr, i64 1
   %ld = load i16, i16 * %a.ptr.inc, align 1
   %cond = icmp ugt i16 %ld, 20
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI32UnsignedWithWithConstantOffsetPost
define i32 @LoadI32UnsignedWithWithConstantOffsetPost(i32 * %a,
                                                    i64 %end) {
entry:
   br label %loop
loop:
; CHECK: ldur  {{w[0-9]+}}, [x{{[0-9]+}}, #0]
   %a.ptr = phi i32 * [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i32, i32 * %a.ptr, i64 1
   %ld = load i32, i32 * %a.ptr.inc, align 1
   %ld.ext = zext i32 %ld to i64
   %cond = icmp ugt i64 %ld.ext, %end
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: StoreI32WithConstantOffsetUnscaled
define void @StoreI32WithConstantOffsetUnscaled(i32 * %foo, i32 %bar) {
entry:
; CHECK-DAG: stur	w1, [x0, #4]
; CHECK-DAG: stur	w1, [x0, #0]
  %fptr = getelementptr inbounds i32, i32 * %foo, i64 1
  store i32 %bar, i32 * %fptr, align 8
  store i32 %bar, i32 * %foo, align 8
  ret void
}

; CHECK-LABEL: LoadF128WithConstantOffsetUnscaled
define void @LoadF128WithConstantOffsetUnscaled(fp128 * %foo, fp128* %res) {
entry:
; CHECK-DAG: ldur	{{q[0-9]+}}, [x0, #16]
; CHECK-DAG: ldur	{{q[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds fp128, fp128 * %foo, i64 1
  %0 = load fp128, fp128 * %fptr, align 16
  %1 = load fp128, fp128 * %foo, align 16
  store fp128 %0, fp128* %res, align 16
  %res1 = getelementptr inbounds fp128, fp128* %res, i64 1
  store fp128 %1, fp128* %res1, align 16
  ret void
}

; CHECK-LABEL: StoreF128WithConstantOffsetUnscaled
define void @StoreF128WithConstantOffsetUnscaled(fp128 * %foo, fp128 %bar) {
entry:
; CHECK-DAG: stur	q0, [x0, #16]
; CHECK-DAG: stur	q0, [x0, #0]
  %fptr = getelementptr inbounds fp128, fp128 * %foo, i64 1
  store fp128 %bar, fp128 * %fptr, align 16
  store fp128 %bar, fp128 * %foo, align 16
  ret void
}

; CHECK-LABEL: LoadF64WithConstantOffsetUnscaled
define double @LoadF64WithConstantOffsetUnscaled(double * %foo) {
entry:
; CHECK-DAG: ldur	{{d[0-9]+}}, [x0, #8]
; CHECK-DAG: ldur	{{d[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds double, double * %foo, i64 1
  %0 = load double, double * %fptr, align 8
  %1 = load double, double * %foo, align 8
  %res = fadd double %0, %1
  ret double %res
}

; CHECK-LABEL: StoreF64WithConstantOffsetUnscaled
define void @StoreF64WithConstantOffsetUnscaled(double * %foo, double %bar) {
entry:
; CHECK-DAG: stur	d0, [x0, #8]
; CHECK-DAG: stur	d0, [x0, #0]
  %fptr = getelementptr inbounds double, double * %foo, i64 1
  store double %bar, double * %fptr, align 8
  store double %bar, double * %foo, align 8
  ret void
}

; CHECK-LABEL: LoadF32WithConstantOffsetUnscaled
define float @LoadF32WithConstantOffsetUnscaled(float * %foo) {
entry:
; CHECK-DAG: ldur	{{s[0-9]+}}, [x0, #4]
; CHECK-DAG: ldur	{{s[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds float, float * %foo, i64 1
  %0 = load float, float * %fptr, align 4
  %1 = load float, float * %foo, align 4
  %res = fadd float %0, %1
  ret float %res
}

; CHECK-LABEL: StoreF32WithConstantOffsetUnscaled
define void @StoreF32WithConstantOffsetUnscaled(float * %foo, float %bar) {
entry:
; CHECK-DAG: stur	s0, [x0, #4]
; CHECK-DAG: stur	s0, [x0, #0]
  %fptr = getelementptr inbounds float, float * %foo, i64 1
  store float %bar, float * %fptr, align 4
  store float %bar, float * %foo, align 4
  ret void
}

; CHECK-LABEL: LoadF16WithConstantOffsetUnscaled
define half @LoadF16WithConstantOffsetUnscaled(half * %foo) {
entry:
; CHECK-DAG: ldur	{{h[0-9]+}}, [x0, #2]
; CHECK-DAG: ldur	{{h[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds half, half * %foo, i64 1
  %0 = load half, half * %fptr, align 2
  %1 = load half, half * %foo, align 2
  %res = fadd half %0, %1
  ret half %res
}

; CHECK-LABEL: StoreF16WithConstantOffsetUnscaled
define void @StoreF16WithConstantOffsetUnscaled(half * %foo, half %bar) {
entry:
; CHECK-DAG: stur	h0, [x0, #2]
; CHECK-DAG: stur	h0, [x0, #0]
  %fptr = getelementptr inbounds half, half * %foo, i64 1
  store half %bar, half * %fptr, align 2
  store half %bar, half * %foo, align 2
  ret void
}

; CHECK-LABEL: LoadZExt32I16WithConstantOffsetUnscaled
define i32 @LoadZExt32I16WithConstantOffsetUnscaled(i16 * %foo) {
entry:
; CHECK-DAG: ldurh	{{w[0-9]+}}, [x0, #2]
; CHECK-DAG: ldurh	{{w[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds i16, i16 * %foo, i64 1
  %0 = load i16, i16 * %fptr, align 8
  %1 = load i16, i16 * %foo, align 8
  %2 = zext i16 %0 to i32
  %3 = zext i16 %1 to i32
  %res = add i32 %2, %3
  ret i32 %res
}

; CHECK-LABEL: LoadZExt64I1WithConstantOffsetUnscaled
define i64 @LoadZExt64I1WithConstantOffsetUnscaled(i1 * %foo) {
entry:
; CHECK: ldurb	{{w[0-9]+}}, [x0, #1]
  %fptr = getelementptr inbounds i1, i1 * %foo, i64 1
  %l = load i1, i1 * %fptr
  %z = zext i1 %l to i64
  ret i64 %z
}

; CHECK-LABEL: LoadZExt32I1WithConstantOffsetUnscaled
define i32 @LoadZExt32I1WithConstantOffsetUnscaled(i1 * %foo) {
entry:
; CHECK: ldurb	{{w[0-9]+}}, [x0, #1]
  %fptr = getelementptr inbounds i1, i1 * %foo, i64 1
  %l = load i1, i1 * %fptr
  %z = zext i1 %l to i32
  ret i32 %z
}

; CHECK-LABEL: LoadZExt64I8WithConstantOffsetUnscaled
define i64 @LoadZExt64I8WithConstantOffsetUnscaled(i8 * %foo) {
entry:
; CHECK: ldurb	{{w[0-9]+}}, [x0, #1]
  %fptr = getelementptr inbounds i8, i8 * %foo, i64 1
  %l = load i8, i8 * %fptr, align 8
  %z = zext i8 %l to i64
  ret i64 %z
}

; CHECK-LABEL: LoadZExt64I16WithConstantOffsetUnscaled
define i64 @LoadZExt64I16WithConstantOffsetUnscaled(i16 * %foo) {
entry:
; CHECK: ldurh	{{w[0-9]+}}, [x0, #2]
  %fptr = getelementptr inbounds i16, i16 * %foo, i64 1
  %l = load i16, i16 * %fptr, align 2
  %z = zext i16 %l to i64
  ret i64 %z
}

; CHECK-LABEL: LoadZExt64I32WithConstantOffsetUnscaled
define i64 @LoadZExt64I32WithConstantOffsetUnscaled(i32 * %foo) {
entry:
; CHECK: ldur	{{w[0-9]+}}, [x0, #4]
  %fptr = getelementptr inbounds i32, i32 * %foo, i64 1
  %l = load i32, i32 * %fptr, align 8
  %z = zext i32 %l to i64
  ret i64 %z
}

; CHECK-LABEL: LoadSExt32I16WithConstantOffsetUnscaled
define i32 @LoadSExt32I16WithConstantOffsetUnscaled(i16 * %foo) {
entry:
; CHECK-DAG: ldursh	{{w[0-9]+}}, [x0, #2]
; CHECK-DAG: ldursh	{{w[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds i16, i16 * %foo, i64 1
  %0 = load i16, i16 * %fptr, align 8
  %1 = load i16, i16 * %foo, align 8
  %2 = sext i16 %0 to i32
  %3 = sext i16 %1 to i32
  %res = add i32 %2, %3
  ret i32 %res
}

; CHECK-LABEL: LoadSExt64I16WithConstantOffsetUnscaled
define i64 @LoadSExt64I16WithConstantOffsetUnscaled(i16 * %foo) {
entry:
; CHECK-DAG: ldursh	{{x[0-9]+}}, [x0, #2]
; CHECK-DAG: ldursh	{{x[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds i16, i16 * %foo, i64 1
  %0 = load i16, i16 * %fptr, align 8
  %1 = load i16, i16 * %foo, align 8
  %2 = sext i16 %0 to i64
  %3 = sext i16 %1 to i64
  %res = add i64 %2, %3
  ret i64 %res
}

; CHECK-LABEL: LoadZExt32I8WithConstantOffsetUnscaled
define i32 @LoadZExt32I8WithConstantOffsetUnscaled(i8 * %foo) {
entry:
; CHECK-DAG: ldurb	{{w[0-9]+}}, [x0, #1]
; CHECK-DAG: ldurb	{{w[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds i8, i8 * %foo, i64 1
  %0 = load i8, i8 * %fptr, align 8
  %1 = load i8, i8 * %foo, align 8
  %2 = zext i8 %0 to i32
  %3 = zext i8 %1 to i32
  %res = add i32 %2, %3
  ret i32 %res
}

; CHECK-LABEL: LoadSExt32I8WithConstantOffsetUnscaled
define i32 @LoadSExt32I8WithConstantOffsetUnscaled(i8 * %foo) {
entry:
; CHECK-DAG: ldursb	{{w[0-9]+}}, [x0, #1]
; CHECK-DAG: ldursb	{{w[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds i8, i8 * %foo, i64 1
  %0 = load i8, i8 * %fptr, align 8
  %1 = load i8, i8 * %foo, align 8
  %2 = sext i8 %0 to i32
  %3 = sext i8 %1 to i32
  %res = add i32 %2, %3
  ret i32 %res
}

; CHECK-LABEL: LoadSExt64I8WithConstantOffsetUnscaled
define i64 @LoadSExt64I8WithConstantOffsetUnscaled(i8 * %foo) {
entry:
; CHECK-DAG: ldursb	{{x[0-9]+}}, [x0, #1]
; CHECK-DAG: ldursb	{{x[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds i8, i8 * %foo, i64 1
  %0 = load i8, i8 * %fptr, align 8
  %1 = load i8, i8 * %foo, align 8
  %2 = sext i8 %0 to i64
  %3 = sext i8 %1 to i64
  %res = add i64 %2, %3
  ret i64 %res
}

; CHECK-LABEL: LoadSExt64I32WithConstantOffsetUnscaled
define i64 @LoadSExt64I32WithConstantOffsetUnscaled(i32 * %foo) {
entry:
; CHECK-DAG: ldursw	{{x[0-9]+}}, [x0, #4]
; CHECK-DAG: ldursw	{{x[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds i32, i32 * %foo, i64 1
  %0 = load i32, i32 * %fptr, align 8
  %1 = load i32, i32 * %foo, align 8
  %2 = sext i32 %0 to i64
  %3 = sext i32 %1 to i64
  %res = add i64 %2, %3
  ret i64 %res
}

; CHECK-LABEL: StoreI16WithConstantOffsetUnscaled
define void @StoreI16WithConstantOffsetUnscaled(i16 * %foo, i16 %bar) {
entry:
; CHECK-DAG: sturh	w1, [x0, #2]
; CHECK-DAG: sturh	w1, [x0, #0]
  %fptr = getelementptr inbounds i16, i16 * %foo, i64 1
  store i16 %bar, i16 * %fptr, align 8
  store i16 %bar, i16 * %foo, align 8
  ret void
}

; CHECK-LABEL: StoreI8FromI64WithConstantOffsetUnscaled
define void @StoreI8FromI64WithConstantOffsetUnscaled(i8 * %foo, i64* %bar) {
entry:
; CHECK: ldur	x[[N:[0-9]+]], [x1, #0]
; CHECK-DAG: sturb	w[[N]], [x0, #1]
; CHECK-DAG: sturb	w[[N]], [x0, #0]
  %0 = load volatile i64, i64* %bar, align 8
  %b = trunc i64 %0 to i8
  %fptr = getelementptr inbounds i8, i8 * %foo, i64 1
  store i8 %b, i8 * %fptr, align 8
  store i8 %b, i8 * %foo, align 8
  ret void
}

; CHECK-LABEL: StoreI16FromI64WithConstantOffsetUnscaled
define void @StoreI16FromI64WithConstantOffsetUnscaled(i16 * %foo, i64* %bar) {
entry:
; CHECK: ldur	x[[N:[0-9]+]], [x1, #0]
; CHECK-DAG: sturh	w[[N]], [x0, #2]
; CHECK-DAG: sturh	w[[N]], [x0, #0]
  %0 = load volatile i64, i64* %bar, align 8
  %b = trunc i64 %0 to i16
  %fptr = getelementptr inbounds i16, i16 * %foo, i64 1
  store i16 %b, i16 * %fptr, align 8
  store i16 %b, i16 * %foo, align 8
  ret void
}

; CHECK-LABEL: StoreI32FromI64WithOffsetUnscaled
define void @StoreI32FromI64WithOffsetUnscaled(i32 * %foo, i64 %v, i64 %offset) {
entry:
; CHECK: add	x{{[0-9]+}}, x0, x2, lsl #2
; CHECK-NEXT: stur w1, [x{{[0-9]+}}, #0]
  %arrayidx = getelementptr inbounds i32, i32 * %foo, i64 %offset
  %0 = trunc i64 %v to i32
  store i32 %0, i32 * %arrayidx, align 4
  ret void
}

; CHECK-LABEL: StoreI8WithConstantOffsetUnscaled
define void @StoreI8WithConstantOffsetUnscaled(i8 * %foo, i8 %bar) {
entry:
; CHECK-DAG: sturb	w1, [x0, #1]
; CHECK-DAG: sturb	w1, [x0, #0]
  %fptr = getelementptr inbounds i8, i8 * %foo, i64 1
  store i8 %bar, i8 * %fptr, align 8
  store i8 %bar, i8 * %foo, align 8
  ret void
}

; CHECK-LABEL: LoadStoreCapability
define void @LoadStoreCapability(i8 addrspace(200)** %foo, i8 addrspace(200)** %res) {
entry:
; CHECK-DAG: ldur	[[B:c[0-9]+]], [x0, #0]
; CHECK-DAG: ldur	[[A:c[0-9]+]], [x0, #32]
; CHECK-DAG: stur	[[B]], [x1, #16]
; CHECK-DAG: stur	[[A]], [x1, #0]
  %fptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)** %foo, i64 2
  %cap0 = load i8  addrspace(200)*, i8 addrspace(200)** %foo
  %cap1 = load i8  addrspace(200)*, i8 addrspace(200)** %fptr
  %tptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)** %res, i64 1
  store i8 addrspace(200)* %cap0, i8 addrspace(200)** %tptr, align 16
  store i8 addrspace(200)* %cap1, i8 addrspace(200)** %res, align 16
  ret void
}

; CHECK-LABEL: LoadAnyExt64I1
define i64 @LoadAnyExt64I1(i1 * %a) {
entry:
; CHECK: ldurb	{{w[0-9]+}}, [x0, #0]
  %0 = load i1, i1 * %a
  %res = sext i1 %0 to i64
  ret i64 %res
}


; CHECK-LABEL: LoadAnyext32I1
define i1 @LoadAnyext32I1(i1 * %a) {
entry:
; CHECK: ldurb	{{w[0-9]+}}, [x0, #0]
  %v = load i1, i1 * %a
  %conv = zext i1 %v to i32
  %add = add nuw nsw i32 %conv, 1
  %t = trunc i32 %add to i1
  ret i1 %t
}

; CHECK-LABEL: LoadAnyext32I8
define i8 @LoadAnyext32I8(i8 * %a) {
entry:
; CHECK: ldurb	{{w[0-9]+}}, [x0, #0]
  %v = load i8, i8 * %a
  ret i8 %v
}

; CHECK-LABEL: LoadAnyext32I16
define i16 @LoadAnyext32I16(i16 * %a) {
entry:
; CHECK: ldurh	{{w[0-9]+}}, [x0, #0]
  %v = load i16, i16 * %a
  ret i16 %v
}

; ------------------------------------------------------------------------------
; Tests for code that would normally generate pre/post-indexed loads and
; stores. We need to generate ldur/stur instructions for these.

declare void @use_dword(i64 *, i64)

; CHECK-LABEL: LoadDWordImmPre
define void @LoadDWordImmPre(i64 * %ptr) {
; CHECK: ldur x1, [x0, #8]
entry:
  %a = getelementptr inbounds i64, i64 * %ptr, i64 1
  %v = load i64, i64 * %a, align 8
  tail call void @use_dword(i64 * %a, i64 %v)
  ret void
}

; CHECK-LABEL: LoadDWordImmPost
define void @LoadDWordImmPost(i64 * %ptr) {
; CHECK: ldur x1, [x0, #0]
entry:
  %a = getelementptr inbounds i64, i64 * %ptr, i64 0
  %v = load i64, i64 * %a, align 8
  %ainc = getelementptr inbounds i64, i64 * %a, i64 1
  tail call void @use_dword(i64 * %ainc, i64 %v)
  ret void
}

; CHECK-LABEL: StoreDWordImmPre
define void @StoreDWordImmPre(i64 * %ptr, i64 %v) {
; CHECK: stur x1, [x0, #8]
entry:
  %a = getelementptr inbounds i64, i64 * %ptr, i64 1
  store i64 %v, i64 * %a, align 8
  tail call void @use_dword(i64 * %a, i64 %v)
  ret void
}

; CHECK-LABEL: StoreDWordImmPost
define void @StoreDWordImmPost(i64 * %ptr, i64 %v) {
; CHECK: stur x1, [x0, #0]
entry:
  %a = getelementptr inbounds i64, i64 * %ptr, i64 0
  store i64 %v, i64 * %a, align 8
  %ainc = getelementptr inbounds i64, i64 * %a, i64 1
  tail call void @use_dword(i64 * %ainc, i64 %v)
  ret void
}

declare void @use_word(i32 *, i32)

; CHECK-LABEL: LoadWordImmPre
define void @LoadWordImmPre(i32 * %ptr) {
; CHECK: ldur w1, [x0, #4]
entry:
  %a = getelementptr inbounds i32, i32 * %ptr, i64 1
  %v = load i32, i32 * %a, align 4
  tail call void @use_word(i32 * %a, i32 %v)
  ret void
}

; CHECK-LABEL: LoadWordImmPost
define void @LoadWordImmPost(i32 * %ptr) {
; CHECK: ldur w1, [x0, #0]
entry:
  %a = getelementptr inbounds i32, i32 * %ptr, i64 0
  %v = load i32, i32 * %a, align 4
  %ainc = getelementptr inbounds i32, i32 * %a, i64 1
  tail call void @use_word(i32 * %ainc, i32 %v)
  ret void
}

; CHECK-LABEL: StoreWordImmPre
define void @StoreWordImmPre(i32 * %ptr, i32 %v) {
; CHECK: stur w1, [x0, #4]
entry:
  %a = getelementptr inbounds i32, i32 * %ptr, i64 1
  store i32 %v, i32 * %a, align 4
  tail call void @use_word(i32 * %a, i32 %v)
  ret void
}

; CHECK-LABEL: StoreTruncI64ToI32ImmPre
define i32 * @StoreTruncI64ToI32ImmPre(i32 * %ptr, i64 %v) {
; CHECK: stur w1, [x0, #4]
entry:
  %a = getelementptr inbounds i32, i32 * %ptr, i64 1
  %w = trunc i64 %v to i32
  store i32 %w, i32 * %a
  ret i32 * %a
}

; CHECK-LABEL: StoreWordImmPost
define void @StoreWordImmPost(i32 * %ptr, i32 %v) {
; CHECK: stur w1, [x0, #0]
entry:
  %a = getelementptr inbounds i32, i32 * %ptr, i64 0
  store i32 %v, i32 * %a, align 4
  %ainc = getelementptr inbounds i32, i32 * %a, i64 1
  tail call void @use_word(i32 * %ainc, i32 %v)
  ret void
}

declare void @use_halfword(i16 *, i16)

; CHECK-LABEL: LoadHalfImmPre
define void @LoadHalfImmPre(i16 * %ptr) {
; CHECK: ldurh w1, [x0, #2]
entry:
  %a = getelementptr inbounds i16, i16 * %ptr, i64 1
  %v = load i16, i16 * %a, align 2
  tail call void @use_halfword(i16 * %a, i16 %v)
  ret void
}

; CHECK-LABEL: LoadHalfImmPost
define void @LoadHalfImmPost(i16 * %ptr) {
; CHECK: ldurh w1, [x0, #0]
entry:
  %a = getelementptr inbounds i16, i16 * %ptr, i64 0
  %v = load i16, i16 * %a, align 2
  %ainc = getelementptr inbounds i16, i16 * %a, i64 1
  tail call void @use_halfword(i16 * %ainc, i16 %v)
  ret void
}

; CHECK-LABEL: StoreHalfImmPre
define void @StoreHalfImmPre(i16 * %ptr, i16 %v) {
; CHECK: sturh w1, [x0, #2]
entry:
  %a = getelementptr inbounds i16, i16 * %ptr, i64 1
  store i16 %v, i16 * %a, align 2
  tail call void @use_halfword(i16 * %a, i16 %v)
  ret void
}

; CHECK-LABEL: StoreTruncI64ToI16ImmPre
define i16 * @StoreTruncI64ToI16ImmPre(i16 * %ptr, i64 %v) {
; CHECK: sturh w1, [x0, #2]
entry:
  %a = getelementptr inbounds i16, i16 * %ptr, i64 1
  %h = trunc i64 %v to i16
  store i16 %h, i16 * %a
  ret i16 * %a
}

; CHECK-LABEL: StoreHalfImmPost
define void @StoreHalfImmPost(i16 * %ptr, i16 %v) {
; CHECK: sturh w1, [x0, #0]
entry:
  %a = getelementptr inbounds i16, i16 * %ptr, i64 0
  store i16 %v, i16 * %a, align 2
  %ainc = getelementptr inbounds i16, i16 * %a, i64 1
  tail call void @use_halfword(i16 * %ainc, i16 %v)
  ret void
}

declare void @use_byte(i8 *, i8)

; CHECK-LABEL: LoadByteImmPre
define void @LoadByteImmPre(i8 * %ptr) {
; CHECK: ldurb w1, [x0, #1]
entry:
  %a = getelementptr inbounds i8, i8 * %ptr, i64 1
  %v = load i8, i8 * %a
  tail call void @use_byte(i8 * %a, i8 %v)
  ret void
}

; CHECK-LABEL: LoadByteImmPost
define void @LoadByteImmPost(i8 * %ptr) {
; CHECK: ldurb w1, [x0, #0]
entry:
  %a = getelementptr inbounds i8, i8 * %ptr, i64 0
  %v = load i8, i8 * %a
  %ainc = getelementptr inbounds i8, i8 * %a, i64 1
  tail call void @use_byte(i8 * %ainc, i8 %v)
  ret void
}

; CHECK-LABEL: StoreByteImmPre
define void @StoreByteImmPre(i8 * %ptr, i8 %v) {
; CHECK: sturb w1, [x0, #1]
entry:
  %a = getelementptr inbounds i8, i8 * %ptr, i64 1
  store i8 %v, i8 * %a
  tail call void @use_byte(i8 * %a, i8 %v)
  ret void
}

; CHECK-LABEL: StoreTruncToByteImmPre
define i8 * @StoreTruncToByteImmPre(i8 * %ptr, i64 %v) {
; CHECK: sturb w1, [x0, #1]
entry:
  %a = getelementptr inbounds i8, i8 * %ptr, i64 1
  %b = trunc i64 %v to i8
  store i8 %b, i8 * %a
  ret i8 * %a
}

; CHECK-LABEL: StoreByteImmPost
define void @StoreByteImmPost(i8 * %ptr, i8 %v) {
; CHECK: sturb w1, [x0, #0]
entry:
  %a = getelementptr inbounds i8, i8 * %ptr, i64 0
  store i8 %v, i8 * %a
  %ainc = getelementptr inbounds i8, i8 * %a, i64 1
  tail call void @use_byte(i8 * %ainc, i8 %v)
  ret void
}

declare void @use_fpdouble(double *, double)

; CHECK-LABEL: LoadFPDoubleImmPre
define void @LoadFPDoubleImmPre(double * %ptr) {
; CHECK: ldur d0, [x0, #8]
entry:
  %a = getelementptr inbounds double, double * %ptr, i64 1
  %v = load double, double * %a, align 8
  tail call void @use_fpdouble(double * %a, double %v)
  ret void
}

; CHECK-LABEL: LoadFPDoubleImmPost
define void @LoadFPDoubleImmPost(double * %ptr) {
; CHECK: ldur d0, [x0, #0]
entry:
  %a = getelementptr inbounds double, double * %ptr, i64 0
  %v = load double, double * %a, align 8
  %ainc = getelementptr inbounds double, double * %a, i64 1
  tail call void @use_fpdouble(double * %ainc, double %v)
  ret void
}

; CHECK-LABEL: StoreFPDoubleImmPre
define void @StoreFPDoubleImmPre(double * %ptr, double %v) {
; CHECK: stur d0, [x0, #8]
entry:
  %a = getelementptr inbounds double, double * %ptr, i64 1
  store double %v, double * %a, align 8
  tail call void @use_fpdouble(double * %a, double %v)
  ret void
}

; CHECK-LABEL: StoreFPDoubleImmPost
define void @StoreFPDoubleImmPost(double * %ptr, double %v) {
; CHECK: stur d0, [x0, #0]
entry:
  %a = getelementptr inbounds double, double * %ptr, i64 0
  store double %v, double * %a, align 8
  %ainc = getelementptr inbounds double, double * %a, i64 1
  tail call void @use_fpdouble(double * %ainc, double %v)
  ret void
}

declare void @use_fpfloat(float *, float)

; CHECK-LABEL: LoadFPFloatImmPre
define void @LoadFPFloatImmPre(float * %ptr) {
; CHECK: ldur s0, [x0, #4]
entry:
  %a = getelementptr inbounds float, float * %ptr, i64 1
  %v = load float, float * %a, align 4
  tail call void @use_fpfloat(float * %a, float %v)
  ret void
}

; CHECK-LABEL: LoadFPFloatImmPost
define void @LoadFPFloatImmPost(float * %ptr) {
; CHECK: ldur s0, [x0, #0]
entry:
  %a = getelementptr inbounds float, float * %ptr, i64 0
  %v = load float, float * %a, align 4
  %ainc = getelementptr inbounds float, float * %a, i64 1
  tail call void @use_fpfloat(float * %ainc, float %v)
  ret void
}

; CHECK-LABEL: StoreFPFloatImmPre
define void @StoreFPFloatImmPre(float * %ptr, float %v) {
; CHECK: stur s0, [x0, #4]
entry:
  %a = getelementptr inbounds float, float * %ptr, i64 1
  store float %v, float * %a, align 4
  tail call void @use_fpfloat(float * %a, float %v)
  ret void
}

; CHECK-LABEL: StoreFPFloatImmPost
define void @StoreFPFloatImmPost(float * %ptr, float %v) {
; CHECK: stur s0, [x0, #0]
entry:
  %a = getelementptr inbounds float, float * %ptr, i64 0
  store float %v, float * %a, align 4
  %ainc = getelementptr inbounds float, float * %a, i64 1
  tail call void @use_fpfloat(float * %ainc, float %v)
  ret void
}

declare void @use_fpquad(fp128 *, fp128)

; CHECK-LABEL: LoadFPQuadImmPre
define void @LoadFPQuadImmPre(fp128 * %ptr) {
; CHECK: ldur q0, [x0, #16]
entry:
  %a = getelementptr inbounds fp128, fp128 * %ptr, i64 1
  %v = load fp128, fp128 * %a, align 16
  tail call void @use_fpquad(fp128 * %a, fp128 %v)
  ret void
}

; CHECK-LABEL: LoadFPQuadImmPost
define void @LoadFPQuadImmPost(fp128 * %ptr) {
; CHECK: ldur q0, [x0, #0]
entry:
  %a = getelementptr inbounds fp128, fp128 * %ptr, i64 0
  %v = load fp128, fp128 * %a, align 16
  %ainc = getelementptr inbounds fp128, fp128 * %a, i64 1
  tail call void @use_fpquad(fp128 * %ainc, fp128 %v)
  ret void
}

; CHECK-LABEL: StoreFPQuadImmPre
define void @StoreFPQuadImmPre(fp128 * %ptr, fp128 %v) {
; CHECK: stur q0, [x0, #16]
entry:
  %a = getelementptr inbounds fp128, fp128 * %ptr, i64 1
  store fp128 %v, fp128 * %a, align 16
  tail call void @use_fpquad(fp128 * %a, fp128 %v)
  ret void
}

; CHECK-LABEL: StoreFPQuadImmPost
define void @StoreFPQuadImmPost(fp128 * %ptr, fp128 %v) {
; CHECK: stur q0, [x0, #0]
entry:
  %a = getelementptr inbounds fp128, fp128 * %ptr, i64 0
  store fp128 %v, fp128 * %a, align 16
  %ainc = getelementptr inbounds fp128, fp128 * %a, i64 1
  tail call void @use_fpquad(fp128 * %ainc, fp128 %v)
  ret void
}

declare void @use_fphalf(half *, half)

; CHECK-LABEL: LoadFPHalfImmPre
define void @LoadFPHalfImmPre(half * %ptr) {
; CHECK: ldur h0, [x0, #2]
entry:
  %a = getelementptr inbounds half, half * %ptr, i64 1
  %v = load half, half * %a, align 2
  tail call void @use_fphalf(half * %a, half %v)
  ret void
}

; CHECK-LABEL: LoadFPHalfImmPost
define void @LoadFPHalfImmPost(half * %ptr) {
; CHECK: ldur h0, [x0, #0]
entry:
  %a = getelementptr inbounds half, half * %ptr, i64 0
  %v = load half, half * %a, align 2
  %ainc = getelementptr inbounds half, half * %a, i64 1
  tail call void @use_fphalf(half * %ainc, half %v)
  ret void
}

; CHECK-LABEL: StoreFPHalfImmPre
define void @StoreFPHalfImmPre(half * %ptr, half %v) {
; CHECK: stur h0, [x0, #2]
entry:
  %a = getelementptr inbounds half, half * %ptr, i64 1
  store half %v, half * %a, align 2
  tail call void @use_fphalf(half * %a, half %v)
  ret void
}

; CHECK-LABEL: StoreFPHalfImmPost
define void @StoreFPHalfImmPost(half * %ptr, half %v) {
; CHECK: stur h0, [x0, #0]
entry:
  %a = getelementptr inbounds half, half * %ptr, i64 0
  store half %v, half * %a, align 2
  %ainc = getelementptr inbounds half, half * %a, i64 1
  tail call void @use_fphalf(half * %ainc, half %v)
  ret void
}

; CHECK-LABEL: Storev4i32ImmPre
define <4 x i32> * @Storev4i32ImmPre(<4 x i32> * %ptr, <4 x i32> %v) {
; CHECK: stur q0, [x0, #16]
entry:
  %a = getelementptr inbounds <4 x i32>, <4 x i32> * %ptr, i64 1
  store <4 x i32> %v, <4 x i32> * %a, align 8
  ret <4 x i32>  * %a
}

; CHECK-LABEL: Storev2i32ImmPre
define <2 x i32> * @Storev2i32ImmPre(<2 x i32> * %ptr, <2 x i32> %v) {
; CHECK: stur d0, [x0, #8]
entry:
  %a = getelementptr inbounds <2 x i32>, <2 x i32> * %ptr, i64 1
  store <2 x i32> %v, <2 x i32> * %a, align 8
  ret <2 x i32>  * %a
}

; CHECK-LABEL: Storev4i32ImmPost
define <4 x i32> * @Storev4i32ImmPost(<4 x i32> * %ptr, <4 x i32> %v) {
; CHECK: stur q0, [x0, #0]
entry:
  %a = getelementptr inbounds <4 x i32>, <4 x i32> * %ptr, i64 1
  store <4 x i32> %v, <4 x i32> * %ptr, align 8
  ret <4 x i32>  * %a
}

; CHECK-LABEL: Storev2i32ImmPost
define <2 x i32> * @Storev2i32ImmPost(<2 x i32> * %ptr, <2 x i32> %v) {
; CHECK: stur d0, [x0, #0]
entry:
  %a = getelementptr inbounds <2 x i32>, <2 x i32> * %ptr, i64 1
  store <2 x i32> %v, <2 x i32> * %ptr, align 8
  ret <2 x i32>  * %a
}

; CHECK-LABEL: LoadStore128BitsIntVectors
define void @LoadStore128BitsIntVectors(<2 x i64> * %PI64, <2 x i64> * %PO64,
                                        <4 x i32> * %PI32, <4 x i32> * %PO32,
                                        <8 x i16> * %PI16, <8 x i16> * %PO16,
                                        <16 x i8> * %PI8,  <16 x i8> * %PO8) {
; CHECK-DAG: ldur	q[[Q64:[0-9]+]], [x0, #0]
; CHECK-DAG: stur	q[[Q64]], [x1, #0]
; CHECK-DAG: ldur	q[[Q32:[0-9]+]], [x2, #0]
; CHECK-DAG: stur	q[[Q32]], [x3, #0]
; CHECK-DAG: ldur	q[[Q16:[0-9]+]], [x4, #0]
; CHECK-DAG: stur	q[[Q16]], [x5, #0]
; CHECK-DAG: ldur	q[[Q8:[0-9]+]], [x6, #0]
; CHECK-DAG: stur	q[[Q8]], [x7, #0]
entry:
  %I64 = load <2 x i64>, <2 x i64> * %PI64, align 16
  store <2 x i64> %I64, <2 x i64> * %PO64, align 16
  %I32 = load <4 x i32>, <4 x i32> * %PI32, align 16
  store <4 x i32> %I32, <4 x i32> * %PO32, align 16
  %I16 = load <8 x i16>, <8 x i16> * %PI16, align 16
  store <8 x i16> %I16, <8 x i16> * %PO16, align 16
  %I8 = load <16 x i8>, <16 x i8> * %PI8, align 16
  store <16 x i8> %I8, <16 x i8> * %PO8, align 16
  ret void
}

; CHECK-LABEL: LoadStore128BitsFpVectors
define void @LoadStore128BitsFpVectors(<2 x double> * %PID, <2 x double> * %POD,
                                       <4 x float> * %PIF, <4 x float> * %POF,
                                       <8 x half> * %PIH, <8 x half> * %POH) {
; CHECK:      ldur	q[[D:[0-9]+]], [x0, #0]
; CHECK-NEXT: stur	q[[D]], [x1, #0]
; CHECK-NEXT: ldur	q[[F:[0-9]+]], [x2, #0]
; CHECK-NEXT: stur	q[[F]], [x3, #0]
; CHECK-NEXT: ldur	q[[H:[0-9]+]], [x4, #0]
; CHECK-NEXT: stur	q[[H]], [x5, #0]
entry:
  %F64 = load <2 x double>, <2 x double> * %PID, align 16
  store <2 x double> %F64, <2 x double> * %POD, align 16
  %F32 = load <4 x float>, <4 x float> * %PIF, align 16
  store <4 x float> %F32, <4 x float> * %POF, align 16
  %F16 = load <8 x half>, <8 x half> * %PIH, align 16
  store <8 x half> %F16, <8 x half> * %POH, align 16
  ret void
}

; CHECK-LABEL: StoreTruncI64ToI8ImmPost
define i8 * @StoreTruncI64ToI8ImmPost(i8 * %ptr, i64 %v) {
; CHECK: sturb	w1, [x0, #0]
entry:
  %t = trunc i64 %v to i8
  %a = getelementptr inbounds i8, i8 * %ptr, i64 0
  store i8 %t, i8 * %a
  %ainc = getelementptr inbounds i8, i8 * %a, i64 1
  ret i8 * %ainc
}

; CHECK-LABEL: StoreTruncI64ToI16ImmPost
define i16 * @StoreTruncI64ToI16ImmPost(i16 * %ptr, i64 %v) {
; CHECK: sturh	w1, [x0, #0]
entry:
  %t = trunc i64 %v to i16
  %a = getelementptr inbounds i16, i16 * %ptr, i64 0
  store i16 %t, i16 * %a
  %ainc = getelementptr inbounds i16, i16 * %a, i64 1
  ret i16 * %ainc
}

; CHECK-LABEL: StoreTruncI64ToI32ImmPost
define i32 * @StoreTruncI64ToI32ImmPost(i32 * %ptr, i64 %v) {
; CHECK: stur	w1, [x0, #0]
entry:
  %t = trunc i64 %v to i32
  %a = getelementptr inbounds i32, i32 * %ptr, i64 0
  store i32 %t, i32 * %a
  %ainc = getelementptr inbounds i32, i32 * %a, i64 1
  ret i32 * %ainc
}

; CHECK-LABEL: Load64AnyExtFromI16
define void @Load64AnyExtFromI16(i16 * %p1, i16 * %p2, i16 * %p3) {
; CHECK: ldurh	w8, [x1, #0]
entry:
  %a = load i16, i16 * %p1, align 2
  %conv = zext i16 %a to i64
  %add4 = add nuw nsw i64 %conv, 0
  %and = lshr i64 %add4, 16
  %b = load i16, i16 * %p2, align 2
  %conv.1 = zext i16 %b to i64
  %add.1 = add nuw nsw i64 %conv.1, %and
  %add4.1 = add nuw nsw i64 %add.1, 0
  %conv5.1 = trunc i64 %add4.1 to i16
  store i16 %conv5.1, i16 * %p3, align 2
  ret void
}

; CHECK-LABEL: Load64AnyExtFromI8
define void @Load64AnyExtFromI8(i8 * %p1, i8 * %p2, i8 * %p3) {
; CHECK: ldurb	w8, [x1, #0]
entry:
  %a = load i8, i8 * %p1
  %conv = zext i8 %a to i64
  %add4 = add nuw nsw i64 %conv, 0
  %and = lshr i64 %add4, 16
  %b = load i8, i8 * %p2
  %conv.1 = zext i8 %b to i64
  %add.1 = add nuw nsw i64 %conv.1, %and
  %add4.1 = add nuw nsw i64 %add.1, 0
  %conv5.1 = trunc i64 %add4.1 to i8
  store i8 %conv5.1, i8 * %p3
  ret void
}

; CHECK-LABEL: LoadStoreDoublev2i32:
; CHECK: ldur d0, [x0, #0]
; CHECK-NEXT: stur d0, [x1, #0]
; CHECK-NEXT: ret
define void @LoadStoreDoublev2i32(<2 x i32> * %ptr0, <2 x i32> * %ptr1) {
  %load0 = load <2 x i32>, <2 x i32>  * %ptr0, align 16
  store <2 x i32> %load0, <2 x i32>  * %ptr1, align 16
  ret void
}

; CHECK-LABEL: LoadStoreDoublev4i16:
; CHECK: ldur d0, [x0, #0]
; CHECK-NEXT: stur d0, [x1, #0]
; CHECK-NEXT: ret
define void @LoadStoreDoublev4i16(<4 x i16> * %ptr0, <4 x i16> * %ptr1) {
  %load0 = load <4 x i16>, <4 x i16>  * %ptr0, align 16
  store <4 x i16> %load0, <4 x i16>  * %ptr1, align 16
  ret void
}

; CHECK-LABEL: LoadStoreDoublev8i8:
; CHECK: ldur d0, [x0, #0]
; CHECK-NEXT: stur d0, [x1, #0]
; CHECK-NEXT: ret
define void @LoadStoreDoublev8i8(<8 x i8> * %ptr0, <8 x i8> * %ptr1) {
  %load0 = load <8 x i8>, <8 x i8>  * %ptr0, align 16
  store <8 x i8> %load0, <8 x i8>  * %ptr1, align 16
  ret void
}

; CHECK-LABEL: LoadStoreDoublev2f32:
; CHECK: ldur d0, [x0, #0]
; CHECK-NEXT: stur d0, [x1, #0]
; CHECK-NEXT: ret
define void @LoadStoreDoublev2f32(<2 x float> * %ptr0, <2 x float> * %ptr1) {
  %load0 = load <2 x float>, <2 x float>  * %ptr0, align 16
  store <2 x float> %load0, <2 x float>  * %ptr1, align 16
  ret void
}

; CHECK-LABEL: LoadStoreDoublev4f16:
; CHECK: ldur d0, [x0, #0]
; CHECK-NEXT: d0, [x1, #0]
; CHECK-NEXT: ret
define void @LoadStoreDoublev4f16(<4 x half> * %ptr0, <4 x half> * %ptr1) {
  %load0 = load <4 x half>, <4 x half>  * %ptr0, align 16
  store <4 x half> %load0, <4 x half>  * %ptr1, align 16
  ret void
}
