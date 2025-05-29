; RUN: llc -mtriple=arm64 -mattr=+morello,+c64 -target-abi purecap -mcpu=rainier -o - %s | FileCheck %s

; CHECK-LABEL: LoadI64WithConstantOffsetUnscaled
define i64 @LoadI64WithConstantOffsetUnscaled(ptr %foo) {
entry:
; CHECK-DAG: ldur	{{x[0-9]+}}, [x0, #8]
; CHECK-DAG: ldur	{{x[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds i64, ptr %foo, i64 1
  %0 = load i64, ptr %fptr, align 8
  %1 = load i64, ptr %foo, align 8
  %res = add i64 %0, %1
  ret i64 %res
}

; CHECK-LABEL: StoreI64WithConstantOffsetUnscaled
define void @StoreI64WithConstantOffsetUnscaled(ptr %foo, i64 %bar) {
entry:
; CHECK-DAG: stur	x1, [x0, #8]
; CHECK-DAG: stur	x1, [x0, #0]
  %fptr = getelementptr inbounds i64, ptr %foo, i64 1
  store i64 %bar, ptr %fptr, align 8
  store i64 %bar, ptr %foo, align 8
  ret void
}

; CHECK-LABEL: LoadI32WithConstantOffsetUnscaled
define i32 @LoadI32WithConstantOffsetUnscaled(ptr %foo) {
entry:
; CHECK-DAG: ldur	{{w[0-9]+}}, [x0, #4]
; CHECK-DAG: ldur	{{w[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds i32, ptr %foo, i64 1
  %0 = load i32, ptr %fptr, align 4
  %1 = load i32, ptr %foo, align 4
  %res = add i32 %0, %1
  ret i32 %res
}

; CHECK-LABEL: LoadI8SignedWithWithConstantOffsetPre
define i32 @LoadI8SignedWithWithConstantOffsetPre(ptr %a) {
entry:
   br label %loop
loop:
; CHECK: ldursb	{{w[0-9]+}}, [x0, #0]
   %a.ptr = phi ptr [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i8, ptr %a.ptr, i64 1
   %ld = load i8, ptr %a.ptr, align 1
   %cond = icmp sgt i8 %ld, -1
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI8SignedWithWithConstantOffsetWPre
define i32 @LoadI8SignedWithWithConstantOffsetWPre(ptr %a, i64 %end) {
entry:
   br label %loop
loop:
; CHECK: ldursb	{{x[0-9]+}}, [x0, #0]
   %a.ptr = phi ptr [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i8, ptr %a.ptr, i64 1
   %ld = load i8, ptr %a.ptr, align 1
   %ld.ext = sext i8 %ld to i64
   %cond = icmp sgt i64 %ld.ext, %end
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI16SignedWithWithConstantOffsetPre
define i32 @LoadI16SignedWithWithConstantOffsetPre(ptr %a) {
entry:
   br label %loop
loop:
; CHECK: ldursh   w8, [x0, #0]
   %a.ptr = phi ptr [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i16, ptr %a.ptr, i64 1
   %ld = load i16, ptr %a.ptr, align 1
   %cond = icmp sgt i16 %ld, -1
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI16SignedWithWithConstantOffsetWPre
define i32 @LoadI16SignedWithWithConstantOffsetWPre(ptr %a, i64 %end) {
entry:
   br label %loop
loop:
; CHECK: ldursh   x{{[0-9]+}}, [x0, #0]
   %a.ptr = phi ptr [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i16, ptr %a.ptr, i64 1
   %ld = load i16, ptr %a.ptr, align 1
   %ld.ext = sext i16 %ld to i64
   %cond = icmp sgt i64 %ld.ext, %end
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI32SignedWithWithConstantOffsetPre
define i32 @LoadI32SignedWithWithConstantOffsetPre(ptr %a,
                                                    i64 %end) {
entry:
   br label %loop
loop:
; CHECK: ldursw  {{x[0-9]+}}, [x0, #0]
   %a.ptr = phi ptr [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i32, ptr %a.ptr, i64 1
   %ld = load i32, ptr %a.ptr, align 1
   %ld.ext = sext i32 %ld to i64
   %cond = icmp sgt i64 %ld.ext, %end
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI8UnsignedWithWithConstantOffsetPre
define i32 @LoadI8UnsignedWithWithConstantOffsetPre(ptr %a) {
entry:
   br label %loop
loop:
; CHECK: ldurb	{{w[0-9]+}}, [x0, #0]
   %a.ptr = phi ptr [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i8, ptr %a.ptr, i64 1
   %ld = load i8, ptr %a.ptr, align 1
   %cond = icmp ugt i8 %ld, 20
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI16UnsignedWithWithConstantOffsetPre
define i32 @LoadI16UnsignedWithWithConstantOffsetPre(ptr %a) {
entry:
   br label %loop
loop:
; CHECK: ldurh   {{w[0-9]+}}, [x0, #0]
   %a.ptr = phi ptr [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i16, ptr %a.ptr, i64 1
   %ld = load i16, ptr %a.ptr, align 1
   %cond = icmp ugt i16 %ld, 20
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI32UnsignedWithWithConstantOffsetPre
define i32 @LoadI32UnsignedWithWithConstantOffsetPre(ptr %a,
                                                    i64 %end) {
entry:
   br label %loop
loop:
; CHECK: ldur  {{w[0-9]+}}, [x0, #0]
   %a.ptr = phi ptr [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i32, ptr %a.ptr, i64 1
   %ld = load i32, ptr %a.ptr, align 1
   %ld.ext = zext i32 %ld to i64
   %cond = icmp ugt i64 %ld.ext, %end
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI8SignedWithWithConstantOffsetPost
define i32 @LoadI8SignedWithWithConstantOffsetPost(ptr %a) {
entry:
   br label %loop
loop:
; CHECK: ldursb	{{w[0-9]+}}, [x{{[0-9]+}}, #0]
   %a.ptr = phi ptr [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i8, ptr %a.ptr, i64 1
   %ld = load i8, ptr %a.ptr.inc, align 1
   %cond = icmp sgt i8 %ld, -1
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI8SignedWithWithConstantOffsetWPost
define i32 @LoadI8SignedWithWithConstantOffsetWPost(ptr %a, i64 %end) {
entry:
   br label %loop
loop:
; CHECK: ldursb	{{x[0-9]+}}, [x{{[0-9]+}}, #0]
   %a.ptr = phi ptr [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i8, ptr %a.ptr, i64 1
   %ld = load i8, ptr %a.ptr.inc, align 1
   %ld.ext = sext i8 %ld to i64
   %cond = icmp sgt i64 %ld.ext, %end
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI16SignedWithWithConstantOffsetPost
define i32 @LoadI16SignedWithWithConstantOffsetPost(ptr %a) {
entry:
   br label %loop
loop:
; CHECK: ldursh   {{w[0-9]+}}, [x{{[0-9]+}}, #0]
   %a.ptr = phi ptr [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i16, ptr %a.ptr, i64 1
   %ld = load i16, ptr %a.ptr.inc, align 1
   %cond = icmp sgt i16 %ld, -1
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI16SignedWithWithConstantOffsetWPost
define i32 @LoadI16SignedWithWithConstantOffsetWPost(ptr %a, i64 %end) {
entry:
   br label %loop
loop:
; CHECK: ldursh   {{x[0-9]+}}, [x{{[0-9]+}}, #0]
   %a.ptr = phi ptr [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i16, ptr %a.ptr, i64 1
   %ld = load i16, ptr %a.ptr.inc, align 1
   %ld.ext = sext i16 %ld to i64
   %cond = icmp sgt i64 %ld.ext, %end
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}


; CHECK-LABEL: LoadI32SignedWithWithConstantOffsetPost
define i32 @LoadI32SignedWithWithConstantOffsetPost(ptr %a,
                                                    i64 %end) {
entry:
   br label %loop
loop:
; CHECK: ldursw  {{x[0-9]+}}, [x{{[0-9]+}}, #0]
   %a.ptr = phi ptr [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i32, ptr %a.ptr, i64 1
   %ld = load i32, ptr %a.ptr.inc, align 1
   %ld.ext = sext i32 %ld to i64
   %cond = icmp sgt i64 %ld.ext, %end
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI8UnsignedWithWithConstantOffsetPost
define i32 @LoadI8UnsignedWithWithConstantOffsetPost(ptr %a) {
entry:
   br label %loop
loop:
; CHECK: ldurb	{{w[0-9]+}}, [x{{[0-9]+}}, #0]
   %a.ptr = phi ptr [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i8, ptr %a.ptr, i64 1
   %ld = load i8, ptr %a.ptr.inc, align 1
   %cond = icmp ugt i8 %ld, 20
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI16UnsignedWithWithConstantOffsetPost
define i32 @LoadI16UnsignedWithWithConstantOffsetPost(ptr %a) {
entry:
   br label %loop
loop:
; CHECK: ldurh   {{w[0-9]+}}, [x{{[0-9]+}}, #0]
   %a.ptr = phi ptr [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i16, ptr %a.ptr, i64 1
   %ld = load i16, ptr %a.ptr.inc, align 1
   %cond = icmp ugt i16 %ld, 20
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: LoadI32UnsignedWithWithConstantOffsetPost
define i32 @LoadI32UnsignedWithWithConstantOffsetPost(ptr %a,
                                                    i64 %end) {
entry:
   br label %loop
loop:
; CHECK: ldur  {{w[0-9]+}}, [x{{[0-9]+}}, #0]
   %a.ptr = phi ptr [ %a.ptr.inc, %loop ], [ %a, %entry ]
   %a.ptr.inc = getelementptr inbounds i32, ptr %a.ptr, i64 1
   %ld = load i32, ptr %a.ptr.inc, align 1
   %ld.ext = zext i32 %ld to i64
   %cond = icmp ugt i64 %ld.ext, %end
   br i1 %cond, label %exit, label %loop
exit:
  ret i32 1
}

; CHECK-LABEL: StoreI32WithConstantOffsetUnscaled
define void @StoreI32WithConstantOffsetUnscaled(ptr %foo, i32 %bar) {
entry:
; CHECK-DAG: stur	w1, [x0, #4]
; CHECK-DAG: stur	w1, [x0, #0]
  %fptr = getelementptr inbounds i32, ptr %foo, i64 1
  store i32 %bar, ptr %fptr, align 8
  store i32 %bar, ptr %foo, align 8
  ret void
}

; CHECK-LABEL: LoadF128WithConstantOffsetUnscaled
define void @LoadF128WithConstantOffsetUnscaled(ptr %foo, ptr %res) {
entry:
; CHECK-DAG: ldur	{{q[0-9]+}}, [x0, #16]
; CHECK-DAG: ldur	{{q[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds fp128, ptr %foo, i64 1
  %0 = load fp128, ptr %fptr, align 16
  %1 = load fp128, ptr %foo, align 16
  store fp128 %0, ptr %res, align 16
  %res1 = getelementptr inbounds fp128, ptr %res, i64 1
  store fp128 %1, ptr %res1, align 16
  ret void
}

; CHECK-LABEL: StoreF128WithConstantOffsetUnscaled
define void @StoreF128WithConstantOffsetUnscaled(ptr %foo, fp128 %bar) {
entry:
; CHECK-DAG: stur	q0, [x0, #16]
; CHECK-DAG: stur	q0, [x0, #0]
  %fptr = getelementptr inbounds fp128, ptr %foo, i64 1
  store fp128 %bar, ptr %fptr, align 16
  store fp128 %bar, ptr %foo, align 16
  ret void
}

; CHECK-LABEL: LoadF64WithConstantOffsetUnscaled
define double @LoadF64WithConstantOffsetUnscaled(ptr %foo) {
entry:
; CHECK-DAG: ldur	{{d[0-9]+}}, [x0, #8]
; CHECK-DAG: ldur	{{d[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds double, ptr %foo, i64 1
  %0 = load double, ptr %fptr, align 8
  %1 = load double, ptr %foo, align 8
  %res = fadd double %0, %1
  ret double %res
}

; CHECK-LABEL: StoreF64WithConstantOffsetUnscaled
define void @StoreF64WithConstantOffsetUnscaled(ptr %foo, double %bar) {
entry:
; CHECK-DAG: stur	d0, [x0, #8]
; CHECK-DAG: stur	d0, [x0, #0]
  %fptr = getelementptr inbounds double, ptr %foo, i64 1
  store double %bar, ptr %fptr, align 8
  store double %bar, ptr %foo, align 8
  ret void
}

; CHECK-LABEL: LoadF32WithConstantOffsetUnscaled
define float @LoadF32WithConstantOffsetUnscaled(ptr %foo) {
entry:
; CHECK-DAG: ldur	{{s[0-9]+}}, [x0, #4]
; CHECK-DAG: ldur	{{s[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds float, ptr %foo, i64 1
  %0 = load float, ptr %fptr, align 4
  %1 = load float, ptr %foo, align 4
  %res = fadd float %0, %1
  ret float %res
}

; CHECK-LABEL: StoreF32WithConstantOffsetUnscaled
define void @StoreF32WithConstantOffsetUnscaled(ptr %foo, float %bar) {
entry:
; CHECK-DAG: stur	s0, [x0, #4]
; CHECK-DAG: stur	s0, [x0, #0]
  %fptr = getelementptr inbounds float, ptr %foo, i64 1
  store float %bar, ptr %fptr, align 4
  store float %bar, ptr %foo, align 4
  ret void
}

; CHECK-LABEL: LoadF16WithConstantOffsetUnscaled
define half @LoadF16WithConstantOffsetUnscaled(ptr %foo) {
entry:
; CHECK-DAG: ldur	{{h[0-9]+}}, [x0, #2]
; CHECK-DAG: ldur	{{h[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds half, ptr %foo, i64 1
  %0 = load half, ptr %fptr, align 2
  %1 = load half, ptr %foo, align 2
  %res = fadd half %0, %1
  ret half %res
}

; CHECK-LABEL: StoreF16WithConstantOffsetUnscaled
define void @StoreF16WithConstantOffsetUnscaled(ptr %foo, half %bar) {
entry:
; CHECK-DAG: stur	h0, [x0, #2]
; CHECK-DAG: stur	h0, [x0, #0]
  %fptr = getelementptr inbounds half, ptr %foo, i64 1
  store half %bar, ptr %fptr, align 2
  store half %bar, ptr %foo, align 2
  ret void
}

; CHECK-LABEL: LoadZExt32I16WithConstantOffsetUnscaled
define i32 @LoadZExt32I16WithConstantOffsetUnscaled(ptr %foo) {
entry:
; CHECK-DAG: ldurh	{{w[0-9]+}}, [x0, #2]
; CHECK-DAG: ldurh	{{w[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds i16, ptr %foo, i64 1
  %0 = load i16, ptr %fptr, align 8
  %1 = load i16, ptr %foo, align 8
  %2 = zext i16 %0 to i32
  %3 = zext i16 %1 to i32
  %res = add i32 %2, %3
  ret i32 %res
}

; CHECK-LABEL: LoadZExt64I1WithConstantOffsetUnscaled
define i64 @LoadZExt64I1WithConstantOffsetUnscaled(ptr %foo) {
entry:
; CHECK: ldurb	{{w[0-9]+}}, [x0, #1]
  %fptr = getelementptr inbounds i1, ptr %foo, i64 1
  %l = load i1, ptr %fptr
  %z = zext i1 %l to i64
  ret i64 %z
}

; CHECK-LABEL: LoadZExt32I1WithConstantOffsetUnscaled
define i32 @LoadZExt32I1WithConstantOffsetUnscaled(ptr %foo) {
entry:
; CHECK: ldurb	{{w[0-9]+}}, [x0, #1]
  %fptr = getelementptr inbounds i1, ptr %foo, i64 1
  %l = load i1, ptr %fptr
  %z = zext i1 %l to i32
  ret i32 %z
}

; CHECK-LABEL: LoadZExt64I8WithConstantOffsetUnscaled
define i64 @LoadZExt64I8WithConstantOffsetUnscaled(ptr %foo) {
entry:
; CHECK: ldurb	{{w[0-9]+}}, [x0, #1]
  %fptr = getelementptr inbounds i8, ptr %foo, i64 1
  %l = load i8, ptr %fptr, align 8
  %z = zext i8 %l to i64
  ret i64 %z
}

; CHECK-LABEL: LoadZExt64I16WithConstantOffsetUnscaled
define i64 @LoadZExt64I16WithConstantOffsetUnscaled(ptr %foo) {
entry:
; CHECK: ldurh	{{w[0-9]+}}, [x0, #2]
  %fptr = getelementptr inbounds i16, ptr %foo, i64 1
  %l = load i16, ptr %fptr, align 2
  %z = zext i16 %l to i64
  ret i64 %z
}

; CHECK-LABEL: LoadZExt64I32WithConstantOffsetUnscaled
define i64 @LoadZExt64I32WithConstantOffsetUnscaled(ptr %foo) {
entry:
; CHECK: ldur	{{w[0-9]+}}, [x0, #4]
  %fptr = getelementptr inbounds i32, ptr %foo, i64 1
  %l = load i32, ptr %fptr, align 8
  %z = zext i32 %l to i64
  ret i64 %z
}

; CHECK-LABEL: LoadSExt32I16WithConstantOffsetUnscaled
define i32 @LoadSExt32I16WithConstantOffsetUnscaled(ptr %foo) {
entry:
; CHECK-DAG: ldursh	{{w[0-9]+}}, [x0, #2]
; CHECK-DAG: ldursh	{{w[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds i16, ptr %foo, i64 1
  %0 = load i16, ptr %fptr, align 8
  %1 = load i16, ptr %foo, align 8
  %2 = sext i16 %0 to i32
  %3 = sext i16 %1 to i32
  %res = add i32 %2, %3
  ret i32 %res
}

; CHECK-LABEL: LoadSExt64I16WithConstantOffsetUnscaled
define i64 @LoadSExt64I16WithConstantOffsetUnscaled(ptr %foo) {
entry:
; CHECK-DAG: ldursh	{{x[0-9]+}}, [x0, #2]
; CHECK-DAG: ldursh	{{x[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds i16, ptr %foo, i64 1
  %0 = load i16, ptr %fptr, align 8
  %1 = load i16, ptr %foo, align 8
  %2 = sext i16 %0 to i64
  %3 = sext i16 %1 to i64
  %res = add i64 %2, %3
  ret i64 %res
}

; CHECK-LABEL: LoadZExt32I8WithConstantOffsetUnscaled
define i32 @LoadZExt32I8WithConstantOffsetUnscaled(ptr %foo) {
entry:
; CHECK-DAG: ldurb	{{w[0-9]+}}, [x0, #1]
; CHECK-DAG: ldurb	{{w[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds i8, ptr %foo, i64 1
  %0 = load i8, ptr %fptr, align 8
  %1 = load i8, ptr %foo, align 8
  %2 = zext i8 %0 to i32
  %3 = zext i8 %1 to i32
  %res = add i32 %2, %3
  ret i32 %res
}

; CHECK-LABEL: LoadSExt32I8WithConstantOffsetUnscaled
define i32 @LoadSExt32I8WithConstantOffsetUnscaled(ptr %foo) {
entry:
; CHECK-DAG: ldursb	{{w[0-9]+}}, [x0, #1]
; CHECK-DAG: ldursb	{{w[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds i8, ptr %foo, i64 1
  %0 = load i8, ptr %fptr, align 8
  %1 = load i8, ptr %foo, align 8
  %2 = sext i8 %0 to i32
  %3 = sext i8 %1 to i32
  %res = add i32 %2, %3
  ret i32 %res
}

; CHECK-LABEL: LoadSExt64I8WithConstantOffsetUnscaled
define i64 @LoadSExt64I8WithConstantOffsetUnscaled(ptr %foo) {
entry:
; CHECK-DAG: ldursb	{{x[0-9]+}}, [x0, #1]
; CHECK-DAG: ldursb	{{x[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds i8, ptr %foo, i64 1
  %0 = load i8, ptr %fptr, align 8
  %1 = load i8, ptr %foo, align 8
  %2 = sext i8 %0 to i64
  %3 = sext i8 %1 to i64
  %res = add i64 %2, %3
  ret i64 %res
}

; CHECK-LABEL: LoadSExt64I32WithConstantOffsetUnscaled
define i64 @LoadSExt64I32WithConstantOffsetUnscaled(ptr %foo) {
entry:
; CHECK-DAG: ldursw	{{x[0-9]+}}, [x0, #4]
; CHECK-DAG: ldursw	{{x[0-9]+}}, [x0, #0]
  %fptr = getelementptr inbounds i32, ptr %foo, i64 1
  %0 = load i32, ptr %fptr, align 8
  %1 = load i32, ptr %foo, align 8
  %2 = sext i32 %0 to i64
  %3 = sext i32 %1 to i64
  %res = add i64 %2, %3
  ret i64 %res
}

; CHECK-LABEL: StoreI16WithConstantOffsetUnscaled
define void @StoreI16WithConstantOffsetUnscaled(ptr %foo, i16 %bar) {
entry:
; CHECK-DAG: sturh	w1, [x0, #2]
; CHECK-DAG: sturh	w1, [x0, #0]
  %fptr = getelementptr inbounds i16, ptr %foo, i64 1
  store i16 %bar, ptr %fptr, align 8
  store i16 %bar, ptr %foo, align 8
  ret void
}

; CHECK-LABEL: StoreI8FromI64WithConstantOffsetUnscaled
define void @StoreI8FromI64WithConstantOffsetUnscaled(ptr %foo, ptr %bar) {
entry:
; CHECK: ldur	x[[N:[0-9]+]], [x1, #0]
; CHECK-DAG: sturb	w[[N]], [x0, #1]
; CHECK-DAG: sturb	w[[N]], [x0, #0]
  %0 = load volatile i64, ptr %bar, align 8
  %b = trunc i64 %0 to i8
  %fptr = getelementptr inbounds i8, ptr %foo, i64 1
  store i8 %b, ptr %fptr, align 8
  store i8 %b, ptr %foo, align 8
  ret void
}

; CHECK-LABEL: StoreI16FromI64WithConstantOffsetUnscaled
define void @StoreI16FromI64WithConstantOffsetUnscaled(ptr %foo, ptr %bar) {
entry:
; CHECK: ldur	x[[N:[0-9]+]], [x1, #0]
; CHECK-DAG: sturh	w[[N]], [x0, #2]
; CHECK-DAG: sturh	w[[N]], [x0, #0]
  %0 = load volatile i64, ptr %bar, align 8
  %b = trunc i64 %0 to i16
  %fptr = getelementptr inbounds i16, ptr %foo, i64 1
  store i16 %b, ptr %fptr, align 8
  store i16 %b, ptr %foo, align 8
  ret void
}

; CHECK-LABEL: StoreI32FromI64WithOffsetUnscaled
define void @StoreI32FromI64WithOffsetUnscaled(ptr %foo, i64 %v, i64 %offset) {
entry:
; CHECK: add	x{{[0-9]+}}, x0, x2, lsl #2
; CHECK-NEXT: stur w1, [x{{[0-9]+}}, #0]
  %arrayidx = getelementptr inbounds i32, ptr %foo, i64 %offset
  %0 = trunc i64 %v to i32
  store i32 %0, ptr %arrayidx, align 4
  ret void
}

; CHECK-LABEL: StoreI8WithConstantOffsetUnscaled
define void @StoreI8WithConstantOffsetUnscaled(ptr %foo, i8 %bar) {
entry:
; CHECK-DAG: sturb	w1, [x0, #1]
; CHECK-DAG: sturb	w1, [x0, #0]
  %fptr = getelementptr inbounds i8, ptr %foo, i64 1
  store i8 %bar, ptr %fptr, align 8
  store i8 %bar, ptr %foo, align 8
  ret void
}

; CHECK-LABEL: LoadStoreCapability
define void @LoadStoreCapability(ptr %foo, ptr %res) {
entry:
; CHECK-DAG: ldur	[[B:c[0-9]+]], [x0, #0]
; CHECK-DAG: ldur	[[A:c[0-9]+]], [x0, #32]
; CHECK-DAG: stur	[[B]], [x1, #16]
; CHECK-DAG: stur	[[A]], [x1, #0]
  %fptr = getelementptr inbounds ptr addrspace(200), ptr %foo, i64 2
  %cap0 = load ptr  addrspace(200), ptr %foo
  %cap1 = load ptr  addrspace(200), ptr %fptr
  %tptr = getelementptr inbounds ptr addrspace(200), ptr %res, i64 1
  store ptr addrspace(200) %cap0, ptr %tptr, align 16
  store ptr addrspace(200) %cap1, ptr %res, align 16
  ret void
}

; CHECK-LABEL: LoadAnyExt64I1
define i64 @LoadAnyExt64I1(ptr %a) {
entry:
; CHECK: ldurb	{{w[0-9]+}}, [x0, #0]
  %0 = load i1, ptr %a
  %res = sext i1 %0 to i64
  ret i64 %res
}


; CHECK-LABEL: LoadAnyext32I1
define i1 @LoadAnyext32I1(ptr %a) {
entry:
; CHECK: ldurb	{{w[0-9]+}}, [x0, #0]
  %v = load i1, ptr %a
  %conv = zext i1 %v to i32
  %add = add nuw nsw i32 %conv, 1
  %t = trunc i32 %add to i1
  ret i1 %t
}

; CHECK-LABEL: LoadAnyext32I8
define i8 @LoadAnyext32I8(ptr %a) {
entry:
; CHECK: ldurb	{{w[0-9]+}}, [x0, #0]
  %v = load i8, ptr %a
  ret i8 %v
}

; CHECK-LABEL: LoadAnyext32I16
define i16 @LoadAnyext32I16(ptr %a) {
entry:
; CHECK: ldurh	{{w[0-9]+}}, [x0, #0]
  %v = load i16, ptr %a
  ret i16 %v
}

; ------------------------------------------------------------------------------
; Tests for code that would normally generate pre/post-indexed loads and
; stores. We need to generate ldur/stur instructions for these.

declare void @use_dword(ptr, i64)

; CHECK-LABEL: LoadDWordImmPre
define void @LoadDWordImmPre(ptr %ptr) {
; CHECK: ldur x1, [x0, #8]
entry:
  %a = getelementptr inbounds i64, ptr %ptr, i64 1
  %v = load i64, ptr %a, align 8
  tail call void @use_dword(ptr %a, i64 %v)
  ret void
}

; CHECK-LABEL: LoadDWordImmPost
define void @LoadDWordImmPost(ptr %ptr) {
; CHECK: ldur x1, [x0, #0]
entry:
  %v = load i64, ptr %ptr, align 8
  %ainc = getelementptr inbounds i64, ptr %ptr, i64 1
  tail call void @use_dword(ptr %ainc, i64 %v)
  ret void
}

; CHECK-LABEL: StoreDWordImmPre
define void @StoreDWordImmPre(ptr %ptr, i64 %v) {
; CHECK: stur x1, [x0, #8]
entry:
  %a = getelementptr inbounds i64, ptr %ptr, i64 1
  store i64 %v, ptr %a, align 8
  tail call void @use_dword(ptr %a, i64 %v)
  ret void
}

; CHECK-LABEL: StoreDWordImmPost
define void @StoreDWordImmPost(ptr %ptr, i64 %v) {
; CHECK: stur x1, [x0, #0]
entry:
  store i64 %v, ptr %ptr, align 8
  %ainc = getelementptr inbounds i64, ptr %ptr, i64 1
  tail call void @use_dword(ptr %ainc, i64 %v)
  ret void
}

declare void @use_word(ptr, i32)

; CHECK-LABEL: LoadWordImmPre
define void @LoadWordImmPre(ptr %ptr) {
; CHECK: ldur w1, [x0, #4]
entry:
  %a = getelementptr inbounds i32, ptr %ptr, i64 1
  %v = load i32, ptr %a, align 4
  tail call void @use_word(ptr %a, i32 %v)
  ret void
}

; CHECK-LABEL: LoadWordImmPost
define void @LoadWordImmPost(ptr %ptr) {
; CHECK: ldur w1, [x0, #0]
entry:
  %v = load i32, ptr %ptr, align 4
  %ainc = getelementptr inbounds i32, ptr %ptr, i64 1
  tail call void @use_word(ptr %ainc, i32 %v)
  ret void
}

; CHECK-LABEL: StoreWordImmPre
define void @StoreWordImmPre(ptr %ptr, i32 %v) {
; CHECK: stur w1, [x0, #4]
entry:
  %a = getelementptr inbounds i32, ptr %ptr, i64 1
  store i32 %v, ptr %a, align 4
  tail call void @use_word(ptr %a, i32 %v)
  ret void
}

; CHECK-LABEL: StoreTruncI64ToI32ImmPre
define ptr @StoreTruncI64ToI32ImmPre(ptr %ptr, i64 %v) {
; CHECK: stur w1, [x0, #4]
entry:
  %a = getelementptr inbounds i32, ptr %ptr, i64 1
  %w = trunc i64 %v to i32
  store i32 %w, ptr %a
  ret ptr %a
}

; CHECK-LABEL: StoreWordImmPost
define void @StoreWordImmPost(ptr %ptr, i32 %v) {
; CHECK: stur w1, [x0, #0]
entry:
  store i32 %v, ptr %ptr, align 4
  %ainc = getelementptr inbounds i32, ptr %ptr, i64 1
  tail call void @use_word(ptr %ainc, i32 %v)
  ret void
}

declare void @use_halfword(ptr, i16)

; CHECK-LABEL: LoadHalfImmPre
define void @LoadHalfImmPre(ptr %ptr) {
; CHECK: ldurh w1, [x0, #2]
entry:
  %a = getelementptr inbounds i16, ptr %ptr, i64 1
  %v = load i16, ptr %a, align 2
  tail call void @use_halfword(ptr %a, i16 %v)
  ret void
}

; CHECK-LABEL: LoadHalfImmPost
define void @LoadHalfImmPost(ptr %ptr) {
; CHECK: ldurh w1, [x0, #0]
entry:
  %v = load i16, ptr %ptr, align 2
  %ainc = getelementptr inbounds i16, ptr %ptr, i64 1
  tail call void @use_halfword(ptr %ainc, i16 %v)
  ret void
}

; CHECK-LABEL: StoreHalfImmPre
define void @StoreHalfImmPre(ptr %ptr, i16 %v) {
; CHECK: sturh w1, [x0, #2]
entry:
  %a = getelementptr inbounds i16, ptr %ptr, i64 1
  store i16 %v, ptr %a, align 2
  tail call void @use_halfword(ptr %a, i16 %v)
  ret void
}

; CHECK-LABEL: StoreTruncI64ToI16ImmPre
define ptr @StoreTruncI64ToI16ImmPre(ptr %ptr, i64 %v) {
; CHECK: sturh w1, [x0, #2]
entry:
  %a = getelementptr inbounds i16, ptr %ptr, i64 1
  %h = trunc i64 %v to i16
  store i16 %h, ptr %a
  ret ptr %a
}

; CHECK-LABEL: StoreHalfImmPost
define void @StoreHalfImmPost(ptr %ptr, i16 %v) {
; CHECK: sturh w1, [x0, #0]
entry:
  store i16 %v, ptr %ptr, align 2
  %ainc = getelementptr inbounds i16, ptr %ptr, i64 1
  tail call void @use_halfword(ptr %ainc, i16 %v)
  ret void
}

declare void @use_byte(ptr, i8)

; CHECK-LABEL: LoadByteImmPre
define void @LoadByteImmPre(ptr %ptr) {
; CHECK: ldurb w1, [x0, #1]
entry:
  %a = getelementptr inbounds i8, ptr %ptr, i64 1
  %v = load i8, ptr %a
  tail call void @use_byte(ptr %a, i8 %v)
  ret void
}

; CHECK-LABEL: LoadByteImmPost
define void @LoadByteImmPost(ptr %ptr) {
; CHECK: ldurb w1, [x0, #0]
entry:
  %v = load i8, ptr %ptr
  %ainc = getelementptr inbounds i8, ptr %ptr, i64 1
  tail call void @use_byte(ptr %ainc, i8 %v)
  ret void
}

; CHECK-LABEL: StoreByteImmPre
define void @StoreByteImmPre(ptr %ptr, i8 %v) {
; CHECK: sturb w1, [x0, #1]
entry:
  %a = getelementptr inbounds i8, ptr %ptr, i64 1
  store i8 %v, ptr %a
  tail call void @use_byte(ptr %a, i8 %v)
  ret void
}

; CHECK-LABEL: StoreTruncToByteImmPre
define ptr @StoreTruncToByteImmPre(ptr %ptr, i64 %v) {
; CHECK: sturb w1, [x0, #1]
entry:
  %a = getelementptr inbounds i8, ptr %ptr, i64 1
  %b = trunc i64 %v to i8
  store i8 %b, ptr %a
  ret ptr %a
}

; CHECK-LABEL: StoreByteImmPost
define void @StoreByteImmPost(ptr %ptr, i8 %v) {
; CHECK: sturb w1, [x0, #0]
entry:
  store i8 %v, ptr %ptr
  %ainc = getelementptr inbounds i8, ptr %ptr, i64 1
  tail call void @use_byte(ptr %ainc, i8 %v)
  ret void
}

declare void @use_fpdouble(ptr, double)

; CHECK-LABEL: LoadFPDoubleImmPre
define void @LoadFPDoubleImmPre(ptr %ptr) {
; CHECK: ldur d0, [x0, #8]
entry:
  %a = getelementptr inbounds double, ptr %ptr, i64 1
  %v = load double, ptr %a, align 8
  tail call void @use_fpdouble(ptr %a, double %v)
  ret void
}

; CHECK-LABEL: LoadFPDoubleImmPost
define void @LoadFPDoubleImmPost(ptr %ptr) {
; CHECK: ldur d0, [x0, #0]
entry:
  %v = load double, ptr %ptr, align 8
  %ainc = getelementptr inbounds double, ptr %ptr, i64 1
  tail call void @use_fpdouble(ptr %ainc, double %v)
  ret void
}

; CHECK-LABEL: StoreFPDoubleImmPre
define void @StoreFPDoubleImmPre(ptr %ptr, double %v) {
; CHECK: stur d0, [x0, #8]
entry:
  %a = getelementptr inbounds double, ptr %ptr, i64 1
  store double %v, ptr %a, align 8
  tail call void @use_fpdouble(ptr %a, double %v)
  ret void
}

; CHECK-LABEL: StoreFPDoubleImmPost
define void @StoreFPDoubleImmPost(ptr %ptr, double %v) {
; CHECK: stur d0, [x0, #0]
entry:
  store double %v, ptr %ptr, align 8
  %ainc = getelementptr inbounds double, ptr %ptr, i64 1
  tail call void @use_fpdouble(ptr %ainc, double %v)
  ret void
}

declare void @use_fpfloat(ptr, float)

; CHECK-LABEL: LoadFPFloatImmPre
define void @LoadFPFloatImmPre(ptr %ptr) {
; CHECK: ldur s0, [x0, #4]
entry:
  %a = getelementptr inbounds float, ptr %ptr, i64 1
  %v = load float, ptr %a, align 4
  tail call void @use_fpfloat(ptr %a, float %v)
  ret void
}

; CHECK-LABEL: LoadFPFloatImmPost
define void @LoadFPFloatImmPost(ptr %ptr) {
; CHECK: ldur s0, [x0, #0]
entry:
  %v = load float, ptr %ptr, align 4
  %ainc = getelementptr inbounds float, ptr %ptr, i64 1
  tail call void @use_fpfloat(ptr %ainc, float %v)
  ret void
}

; CHECK-LABEL: StoreFPFloatImmPre
define void @StoreFPFloatImmPre(ptr %ptr, float %v) {
; CHECK: stur s0, [x0, #4]
entry:
  %a = getelementptr inbounds float, ptr %ptr, i64 1
  store float %v, ptr %a, align 4
  tail call void @use_fpfloat(ptr %a, float %v)
  ret void
}

; CHECK-LABEL: StoreFPFloatImmPost
define void @StoreFPFloatImmPost(ptr %ptr, float %v) {
; CHECK: stur s0, [x0, #0]
entry:
  store float %v, ptr %ptr, align 4
  %ainc = getelementptr inbounds float, ptr %ptr, i64 1
  tail call void @use_fpfloat(ptr %ainc, float %v)
  ret void
}

declare void @use_fpquad(ptr, fp128)

; CHECK-LABEL: LoadFPQuadImmPre
define void @LoadFPQuadImmPre(ptr %ptr) {
; CHECK: ldur q0, [x0, #16]
entry:
  %a = getelementptr inbounds fp128, ptr %ptr, i64 1
  %v = load fp128, ptr %a, align 16
  tail call void @use_fpquad(ptr %a, fp128 %v)
  ret void
}

; CHECK-LABEL: LoadFPQuadImmPost
define void @LoadFPQuadImmPost(ptr %ptr) {
; CHECK: ldur q0, [x0, #0]
entry:
  %v = load fp128, ptr %ptr, align 16
  %ainc = getelementptr inbounds fp128, ptr %ptr, i64 1
  tail call void @use_fpquad(ptr %ainc, fp128 %v)
  ret void
}

; CHECK-LABEL: StoreFPQuadImmPre
define void @StoreFPQuadImmPre(ptr %ptr, fp128 %v) {
; CHECK: stur q0, [x0, #16]
entry:
  %a = getelementptr inbounds fp128, ptr %ptr, i64 1
  store fp128 %v, ptr %a, align 16
  tail call void @use_fpquad(ptr %a, fp128 %v)
  ret void
}

; CHECK-LABEL: StoreFPQuadImmPost
define void @StoreFPQuadImmPost(ptr %ptr, fp128 %v) {
; CHECK: stur q0, [x0, #0]
entry:
  store fp128 %v, ptr %ptr, align 16
  %ainc = getelementptr inbounds fp128, ptr %ptr, i64 1
  tail call void @use_fpquad(ptr %ainc, fp128 %v)
  ret void
}

declare void @use_fphalf(ptr, half)

; CHECK-LABEL: LoadFPHalfImmPre
define void @LoadFPHalfImmPre(ptr %ptr) {
; CHECK: ldur h0, [x0, #2]
entry:
  %a = getelementptr inbounds half, ptr %ptr, i64 1
  %v = load half, ptr %a, align 2
  tail call void @use_fphalf(ptr %a, half %v)
  ret void
}

; CHECK-LABEL: LoadFPHalfImmPost
define void @LoadFPHalfImmPost(ptr %ptr) {
; CHECK: ldur h0, [x0, #0]
entry:
  %v = load half, ptr %ptr, align 2
  %ainc = getelementptr inbounds half, ptr %ptr, i64 1
  tail call void @use_fphalf(ptr %ainc, half %v)
  ret void
}

; CHECK-LABEL: StoreFPHalfImmPre
define void @StoreFPHalfImmPre(ptr %ptr, half %v) {
; CHECK: stur h0, [x0, #2]
entry:
  %a = getelementptr inbounds half, ptr %ptr, i64 1
  store half %v, ptr %a, align 2
  tail call void @use_fphalf(ptr %a, half %v)
  ret void
}

; CHECK-LABEL: StoreFPHalfImmPost
define void @StoreFPHalfImmPost(ptr %ptr, half %v) {
; CHECK: stur h0, [x0, #0]
entry:
  store half %v, ptr %ptr, align 2
  %ainc = getelementptr inbounds half, ptr %ptr, i64 1
  tail call void @use_fphalf(ptr %ainc, half %v)
  ret void
}

; CHECK-LABEL: Storev4i32ImmPre
define ptr @Storev4i32ImmPre(ptr %ptr, <4 x i32> %v) {
; CHECK: stur q0, [x0, #16]
entry:
  %a = getelementptr inbounds <4 x i32>, ptr %ptr, i64 1
  store <4 x i32> %v, ptr %a, align 8
  ret ptr %a
}

; CHECK-LABEL: Storev2i32ImmPre
define ptr @Storev2i32ImmPre(ptr %ptr, <2 x i32> %v) {
; CHECK: stur d0, [x0, #8]
entry:
  %a = getelementptr inbounds <2 x i32>, ptr %ptr, i64 1
  store <2 x i32> %v, ptr %a, align 8
  ret ptr %a
}

; CHECK-LABEL: Storev4i32ImmPost
define ptr @Storev4i32ImmPost(ptr %ptr, <4 x i32> %v) {
; CHECK: stur q0, [x0, #0]
entry:
  %a = getelementptr inbounds <4 x i32>, ptr %ptr, i64 1
  store <4 x i32> %v, ptr %ptr, align 8
  ret ptr %a
}

; CHECK-LABEL: Storev2i32ImmPost
define ptr @Storev2i32ImmPost(ptr %ptr, <2 x i32> %v) {
; CHECK: stur d0, [x0, #0]
entry:
  %a = getelementptr inbounds <2 x i32>, ptr %ptr, i64 1
  store <2 x i32> %v, ptr %ptr, align 8
  ret ptr %a
}

; CHECK-LABEL: LoadStore128BitsIntVectors
define void @LoadStore128BitsIntVectors(ptr %PI64, ptr %PO64,
                                        ptr %PI32, ptr %PO32,
                                        ptr %PI16, ptr %PO16,
                                        ptr %PI8,  ptr %PO8) {
; CHECK-DAG: ldur	q[[Q64:[0-9]+]], [x0, #0]
; CHECK-DAG: stur	q[[Q64]], [x1, #0]
; CHECK-DAG: ldur	q[[Q32:[0-9]+]], [x2, #0]
; CHECK-DAG: stur	q[[Q32]], [x3, #0]
; CHECK-DAG: ldur	q[[Q16:[0-9]+]], [x4, #0]
; CHECK-DAG: stur	q[[Q16]], [x5, #0]
; CHECK-DAG: ldur	q[[Q8:[0-9]+]], [x6, #0]
; CHECK-DAG: stur	q[[Q8]], [x7, #0]
entry:
  %I64 = load <2 x i64>, ptr %PI64, align 16
  store <2 x i64> %I64, ptr %PO64, align 16
  %I32 = load <4 x i32>, ptr %PI32, align 16
  store <4 x i32> %I32, ptr %PO32, align 16
  %I16 = load <8 x i16>, ptr %PI16, align 16
  store <8 x i16> %I16, ptr %PO16, align 16
  %I8 = load <16 x i8>, ptr %PI8, align 16
  store <16 x i8> %I8, ptr %PO8, align 16
  ret void
}

; CHECK-LABEL: LoadStore128BitsFpVectors
define void @LoadStore128BitsFpVectors(ptr %PID, ptr %POD,
                                       ptr %PIF, ptr %POF,
                                       ptr %PIH, ptr %POH) {
; CHECK:      ldur	q[[D:[0-9]+]], [x0, #0]
; CHECK-NEXT: stur	q[[D]], [x1, #0]
; CHECK-NEXT: ldur	q[[F:[0-9]+]], [x2, #0]
; CHECK-NEXT: stur	q[[F]], [x3, #0]
; CHECK-NEXT: ldur	q[[H:[0-9]+]], [x4, #0]
; CHECK-NEXT: stur	q[[H]], [x5, #0]
entry:
  %F64 = load <2 x double>, ptr %PID, align 16
  store <2 x double> %F64, ptr %POD, align 16
  %F32 = load <4 x float>, ptr %PIF, align 16
  store <4 x float> %F32, ptr %POF, align 16
  %F16 = load <8 x half>, ptr %PIH, align 16
  store <8 x half> %F16, ptr %POH, align 16
  ret void
}

; CHECK-LABEL: StoreTruncI64ToI8ImmPost
define ptr @StoreTruncI64ToI8ImmPost(ptr %ptr, i64 %v) {
; CHECK: sturb	w1, [x0, #0]
entry:
  %t = trunc i64 %v to i8
  store i8 %t, ptr %ptr
  %ainc = getelementptr inbounds i8, ptr %ptr, i64 1
  ret ptr %ainc
}

; CHECK-LABEL: StoreTruncI64ToI16ImmPost
define ptr @StoreTruncI64ToI16ImmPost(ptr %ptr, i64 %v) {
; CHECK: sturh	w1, [x0, #0]
entry:
  %t = trunc i64 %v to i16
  store i16 %t, ptr %ptr
  %ainc = getelementptr inbounds i16, ptr %ptr, i64 1
  ret ptr %ainc
}

; CHECK-LABEL: StoreTruncI64ToI32ImmPost
define ptr @StoreTruncI64ToI32ImmPost(ptr %ptr, i64 %v) {
; CHECK: stur	w1, [x0, #0]
entry:
  %t = trunc i64 %v to i32
  store i32 %t, ptr %ptr
  %ainc = getelementptr inbounds i32, ptr %ptr, i64 1
  ret ptr %ainc
}

; CHECK-LABEL: Load64AnyExtFromI16
define void @Load64AnyExtFromI16(ptr %p1, ptr %p2, ptr %p3) {
; CHECK: ldurh	w8, [x1, #0]
entry:
  %a = load i16, ptr %p1, align 2
  %conv = zext i16 %a to i64
  %add4 = add nuw nsw i64 %conv, 0
  %and = lshr i64 %add4, 16
  %b = load i16, ptr %p2, align 2
  %conv.1 = zext i16 %b to i64
  %add.1 = add nuw nsw i64 %conv.1, %and
  %add4.1 = add nuw nsw i64 %add.1, 0
  %conv5.1 = trunc i64 %add4.1 to i16
  store i16 %conv5.1, ptr %p3, align 2
  ret void
}

; CHECK-LABEL: Load64AnyExtFromI8
define void @Load64AnyExtFromI8(ptr %p1, ptr %p2, ptr %p3) {
; CHECK: ldurb	w8, [x1, #0]
entry:
  %a = load i8, ptr %p1
  %conv = zext i8 %a to i64
  %add4 = add nuw nsw i64 %conv, 0
  %and = lshr i64 %add4, 16
  %b = load i8, ptr %p2
  %conv.1 = zext i8 %b to i64
  %add.1 = add nuw nsw i64 %conv.1, %and
  %add4.1 = add nuw nsw i64 %add.1, 0
  %conv5.1 = trunc i64 %add4.1 to i8
  store i8 %conv5.1, ptr %p3
  ret void
}

; CHECK-LABEL: LoadStoreDoublev2i32:
; CHECK: ldur d0, [x0, #0]
; CHECK-NEXT: stur d0, [x1, #0]
; CHECK-NEXT: ret
define void @LoadStoreDoublev2i32(ptr %ptr0, ptr %ptr1) {
  %load0 = load <2 x i32>, ptr %ptr0, align 16
  store <2 x i32> %load0, ptr %ptr1, align 16
  ret void
}

; CHECK-LABEL: LoadStoreDoublev4i16:
; CHECK: ldur d0, [x0, #0]
; CHECK-NEXT: stur d0, [x1, #0]
; CHECK-NEXT: ret
define void @LoadStoreDoublev4i16(ptr %ptr0, ptr %ptr1) {
  %load0 = load <4 x i16>, ptr %ptr0, align 16
  store <4 x i16> %load0, ptr %ptr1, align 16
  ret void
}

; CHECK-LABEL: LoadStoreDoublev8i8:
; CHECK: ldur d0, [x0, #0]
; CHECK-NEXT: stur d0, [x1, #0]
; CHECK-NEXT: ret
define void @LoadStoreDoublev8i8(ptr %ptr0, ptr %ptr1) {
  %load0 = load <8 x i8>, ptr %ptr0, align 16
  store <8 x i8> %load0, ptr %ptr1, align 16
  ret void
}

; CHECK-LABEL: LoadStoreDoublev2f32:
; CHECK: ldur d0, [x0, #0]
; CHECK-NEXT: stur d0, [x1, #0]
; CHECK-NEXT: ret
define void @LoadStoreDoublev2f32(ptr %ptr0, ptr %ptr1) {
  %load0 = load <2 x float>, ptr %ptr0, align 16
  store <2 x float> %load0, ptr %ptr1, align 16
  ret void
}

; CHECK-LABEL: LoadStoreDoublev4f16:
; CHECK: ldur d0, [x0, #0]
; CHECK-NEXT: d0, [x1, #0]
; CHECK-NEXT: ret
define void @LoadStoreDoublev4f16(ptr %ptr0, ptr %ptr1) {
  %load0 = load <4 x half>, ptr %ptr0, align 16
  store <4 x half> %load0, ptr %ptr1, align 16
  ret void
}
