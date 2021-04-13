; RUN: llc < %s -mtriple=arm64 -mattr=+c64,+morello -target-abi purecap -aarch64-redzone | FileCheck %s

define i64 addrspace(200)* @store64(i64 addrspace(200)* %tmp, i64 %index, i64 %spacing) nounwind noinline ssp {
; CHECK-LABEL: store64:
; CHECK: str x{{[0-9+]}}, [c{{[0-9+]}}], #8
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i64, i64 addrspace(200)* %tmp, i64 1
  store i64 %spacing, i64 addrspace(200)* %tmp, align 4
  ret i64 addrspace(200)* %incdec.ptr
}

define i32 addrspace(200)* @store32(i32 addrspace(200)* %tmp, i32 %index, i32 %spacing) nounwind noinline ssp {
; CHECK-LABEL: store32:
; CHECK: str w{{[0-9+]}}, [c{{[0-9+]}}], #4
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i32, i32 addrspace(200)* %tmp, i64 1
  store i32 %spacing, i32 addrspace(200)* %tmp, align 4
  ret i32 addrspace(200)* %incdec.ptr
}

define i16 addrspace(200)* @store16(i16 addrspace(200)* nocapture %tmp, i16 %index, i16 %spacing) nounwind noinline ssp {
; CHECK-LABEL: store16:
; CHECK: strh w{{[0-9+]}}, [c{{[0-9+]}}], #2
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i16, i16 addrspace(200)* %tmp, i64 1
  store i16 %spacing, i16 addrspace(200)* %tmp, align 4
  ret i16 addrspace(200)* %incdec.ptr
}

define i8 addrspace(200)* @store8(i8 addrspace(200)* %tmp, i8 %index, i8 %spacing) nounwind noinline ssp {
; CHECK-LABEL: store8:
; CHECK: strb w{{[0-9+]}}, [c{{[0-9+]}}], #1
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i8, i8 addrspace(200)* %tmp, i64 1
  store i8 %spacing, i8 addrspace(200)* %tmp, align 4
  ret i8 addrspace(200)* %incdec.ptr
}

define i32 addrspace(200)* @truncst64to32(i32 addrspace(200)* nocapture %tmp, i32 %index, i64 %spacing) nounwind noinline ssp {
; CHECK-LABEL: truncst64to32:
; CHECK: str w{{[0-9+]}}, [c{{[0-9+]}}], #4
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i32, i32 addrspace(200)* %tmp, i64 1
  %trunc = trunc i64 %spacing to i32
  store i32 %trunc, i32 addrspace(200)* %tmp, align 4
  ret i32 addrspace(200)* %incdec.ptr
}

define i16 addrspace(200)* @truncst64to16(i16 addrspace(200)* nocapture %tmp, i16 %index, i64 %spacing) nounwind noinline ssp {
; CHECK-LABEL: truncst64to16:
; CHECK: strh w{{[0-9+]}}, [c{{[0-9+]}}], #2
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i16, i16 addrspace(200)* %tmp, i64 1
  %trunc = trunc i64 %spacing to i16
  store i16 %trunc, i16 addrspace(200)* %tmp, align 4
  ret i16 addrspace(200)* %incdec.ptr
}

define i8 addrspace(200)* @truncst64to8(i8 addrspace(200)* %tmp, i8 %index, i64 %spacing) nounwind noinline ssp {
; CHECK-LABEL: truncst64to8:
; CHECK: strb w{{[0-9+]}}, [c{{[0-9+]}}], #1
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i8, i8 addrspace(200)* %tmp, i64 1
  %trunc = trunc i64 %spacing to i8
  store i8 %trunc, i8 addrspace(200)* %tmp, align 4
  ret i8 addrspace(200)* %incdec.ptr
}


define half addrspace(200)* @storef16(half addrspace(200)* %tmp, half %index, half %spacing) nounwind {
; CHECK-LABEL: storef16:
; CHECK: str h{{[0-9+]}}, [c{{[0-9+]}}], #2
; CHECK: ret
  %incdec.ptr = getelementptr inbounds half, half addrspace(200)* %tmp, i64 1
  store half %spacing, half addrspace(200)* %tmp, align 2
  ret half addrspace(200)* %incdec.ptr
}

define float addrspace(200)* @storef32(float addrspace(200)* %tmp, float %index, float %spacing) nounwind noinline ssp {
; CHECK-LABEL: storef32:
; CHECK: str s{{[0-9+]}}, [c{{[0-9+]}}], #4
; CHECK: ret
  %incdec.ptr = getelementptr inbounds float, float addrspace(200)* %tmp, i64 1
  store float %spacing, float addrspace(200)* %tmp, align 4
  ret float addrspace(200)* %incdec.ptr
}

define double addrspace(200)* @storef64(double addrspace(200)* %tmp, double %index, double %spacing) nounwind noinline ssp {
; CHECK-LABEL: storef64:
; CHECK: str d{{[0-9+]}}, [c{{[0-9+]}}], #8
; CHECK: ret
  %incdec.ptr = getelementptr inbounds double, double addrspace(200)* %tmp, i64 1
  store double %spacing, double addrspace(200)* %tmp, align 4
  ret double addrspace(200)* %incdec.ptr
}

define i64 addrspace(200)* @pre64(i64 addrspace(200)* %tmp, i64 %index, i64 %spacing) nounwind noinline ssp {
; CHECK-LABEL: pre64:
; CHECK: str x{{[0-9+]}}, [c{{[0-9+]}}, #8]!
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i64, i64 addrspace(200)* %tmp, i64 1
  store i64 %spacing, i64 addrspace(200)* %incdec.ptr, align 4
  ret i64 addrspace(200)* %incdec.ptr
}

define i32 addrspace(200)* @pre32(i32 addrspace(200)* %tmp, i32 %index, i32 %spacing) nounwind noinline ssp {
; CHECK-LABEL: pre32:
; CHECK: str w{{[0-9+]}}, [c{{[0-9+]}}, #4]!
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i32, i32 addrspace(200)* %tmp, i64 1
  store i32 %spacing, i32 addrspace(200)* %incdec.ptr, align 4
  ret i32 addrspace(200)* %incdec.ptr
}

define i16 addrspace(200)* @pre16(i16 addrspace(200)* nocapture %tmp, i16 %index, i16 %spacing) nounwind noinline ssp {
; CHECK-LABEL: pre16:
; CHECK: strh w{{[0-9+]}}, [c{{[0-9+]}}, #2]!
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i16, i16 addrspace(200)* %tmp, i64 1
  store i16 %spacing, i16 addrspace(200)* %incdec.ptr, align 4
  ret i16 addrspace(200)* %incdec.ptr
}

define i8 addrspace(200)* @pre8(i8 addrspace(200)* %tmp, i8 %index, i8 %spacing) nounwind noinline ssp {
; CHECK-LABEL: pre8:
; CHECK: strb w{{[0-9+]}}, [c{{[0-9+]}}, #1]!
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i8, i8 addrspace(200)* %tmp, i64 1
  store i8 %spacing, i8 addrspace(200)* %incdec.ptr, align 4
  ret i8 addrspace(200)* %incdec.ptr
}

define i32 addrspace(200)* @pretruncst64to32(i32 addrspace(200)* nocapture %tmp, i32 %index, i64 %spacing) nounwind noinline ssp {
; CHECK-LABEL: pretruncst64to32:
; CHECK: str w{{[0-9+]}}, [c{{[0-9+]}}, #4]!
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i32, i32 addrspace(200)* %tmp, i64 1
  %trunc = trunc i64 %spacing to i32
  store i32 %trunc, i32 addrspace(200)* %incdec.ptr, align 4
  ret i32 addrspace(200)* %incdec.ptr
}

define i16 addrspace(200)* @pretruncst64to16(i16 addrspace(200)* nocapture %tmp, i16 %index, i64 %spacing) nounwind noinline ssp {
; CHECK-LABEL: pretruncst64to16:
; CHECK: strh w{{[0-9+]}}, [c{{[0-9+]}}, #2]!
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i16, i16 addrspace(200)* %tmp, i64 1
  %trunc = trunc i64 %spacing to i16
  store i16 %trunc, i16 addrspace(200)* %incdec.ptr, align 4
  ret i16 addrspace(200)* %incdec.ptr
}

define i8 addrspace(200)* @pretruncst64to8(i8 addrspace(200)* %tmp, i8 %index, i64 %spacing) nounwind noinline ssp {
; CHECK-LABEL: pretruncst64to8:
; CHECK: strb w{{[0-9+]}}, [c{{[0-9+]}}, #1]!
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i8, i8 addrspace(200)* %tmp, i64 1
  %trunc = trunc i64 %spacing to i8
  store i8 %trunc, i8 addrspace(200)* %incdec.ptr, align 4
  ret i8 addrspace(200)* %incdec.ptr
}

define half addrspace(200)* @pref16(half addrspace(200)* %tmp, half %index, half %spacing) nounwind {
; CHECK-LABEL: pref16:
; CHECK: str h{{[0-9+]}}, [c{{[0-9+]}}, #2]!
; CHECK: ret
  %incdec.ptr = getelementptr inbounds half, half addrspace(200)* %tmp, i64 1
  store half %spacing, half addrspace(200)* %incdec.ptr, align 2
  ret half addrspace(200)* %incdec.ptr
}

define float addrspace(200)* @pref32(float addrspace(200)* %tmp, float %index, float %spacing) nounwind noinline ssp {
; CHECK-LABEL: pref32:
; CHECK: str s{{[0-9+]}}, [c{{[0-9+]}}, #4]!
; CHECK: ret
  %incdec.ptr = getelementptr inbounds float, float addrspace(200)* %tmp, i64 1
  store float %spacing, float addrspace(200)* %incdec.ptr, align 4
  ret float addrspace(200)* %incdec.ptr
}

define double addrspace(200)* @pref64(double addrspace(200)* %tmp, double %index, double %spacing) nounwind noinline ssp {
; CHECK-LABEL: pref64:
; CHECK: str d{{[0-9+]}}, [c{{[0-9+]}}, #8]!
; CHECK: ret
  %incdec.ptr = getelementptr inbounds double, double addrspace(200)* %tmp, i64 1
  store double %spacing, double addrspace(200)* %incdec.ptr, align 4
  ret double addrspace(200)* %incdec.ptr
}

;-----
; Pre-indexed loads
;-----
define double addrspace(200)* @preidxf64(double addrspace(200)* %src, double addrspace(200)* %out) {
; CHECK-LABEL: preidxf64:
; CHECK: ldr     d0, [c0, #8]!
; CHECK: str     d0, [c1]
; CHECK: ret
  %ptr = getelementptr inbounds double, double addrspace(200)* %src, i64 1
  %tmp = load double, double addrspace(200)* %ptr, align 4
  store double %tmp, double addrspace(200)* %out, align 4
  ret double addrspace(200)* %ptr
}

define float addrspace(200)* @preidxf32(float addrspace(200)* %src, float addrspace(200)* %out) {
; CHECK-LABEL: preidxf32:
; CHECK: ldr     s0, [c0, #4]!
; CHECK: str     s0, [c1]
; CHECK: ret
  %ptr = getelementptr inbounds float, float addrspace(200)* %src, i64 1
  %tmp = load float, float addrspace(200)* %ptr, align 4
  store float %tmp, float addrspace(200)* %out, align 4
  ret float addrspace(200)* %ptr
}

define half addrspace(200)* @preidxf16(half addrspace(200)* %src, half addrspace(200)* %out) {
; CHECK-LABEL: preidxf16:
; CHECK: ldr     h0, [c0, #2]!
; CHECK: str     h0, [c1]
; CHECK: ret
  %ptr = getelementptr inbounds half, half addrspace(200)* %src, i64 1
  %tmp = load half, half addrspace(200)* %ptr, align 2
  store half %tmp, half addrspace(200)* %out, align 2
  ret half addrspace(200)* %ptr
}

define i64 addrspace(200)* @preidx64(i64 addrspace(200)* %src, i64 addrspace(200)* %out) {
; CHECK-LABEL: preidx64:
; CHECK: ldr     x[[REG:[0-9]+]], [c0, #8]!
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i64, i64 addrspace(200)* %src, i64 1
  %tmp = load i64, i64 addrspace(200)* %ptr, align 4
  store i64 %tmp, i64 addrspace(200)* %out, align 4
  ret i64 addrspace(200)* %ptr
}

define i32 addrspace(200)* @preidx32(i32 addrspace(200)* %src, i32 addrspace(200)* %out) {
; CHECK: ldr     w[[REG:[0-9]+]], [c0, #4]!
; CHECK: str     w[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i32, i32 addrspace(200)* %src, i64 1
  %tmp = load i32, i32 addrspace(200)* %ptr, align 4
  store i32 %tmp, i32 addrspace(200)* %out, align 4
  ret i32 addrspace(200)* %ptr
}

define i16 addrspace(200)* @preidx16zext32(i16 addrspace(200)* %src, i32 addrspace(200)* %out) {
; CHECK: ldrh    w[[REG:[0-9]+]], [c0, #2]!
; CHECK: str     w[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %src, i64 1
  %tmp = load i16, i16 addrspace(200)* %ptr, align 4
  %ext = zext i16 %tmp to i32
  store i32 %ext, i32 addrspace(200)* %out, align 4
  ret i16 addrspace(200)* %ptr
}

define i16 addrspace(200)* @preidx16zext64(i16 addrspace(200)* %src, i64 addrspace(200)* %out) {
; CHECK: ldrh    w[[REG:[0-9]+]], [c0, #2]!
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %src, i64 1
  %tmp = load i16, i16 addrspace(200)* %ptr, align 4
  %ext = zext i16 %tmp to i64
  store i64 %ext, i64 addrspace(200)* %out, align 4
  ret i16 addrspace(200)* %ptr
}

define i8 addrspace(200)* @preidx8zext32(i8 addrspace(200)* %src, i32 addrspace(200)* %out) {
; CHECK: ldrb    w[[REG:[0-9]+]], [c0, #1]!
; CHECK: str     w[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %src, i64 1
  %tmp = load i8, i8 addrspace(200)* %ptr, align 4
  %ext = zext i8 %tmp to i32
  store i32 %ext, i32 addrspace(200)* %out, align 4
  ret i8 addrspace(200)* %ptr
}

define i8 addrspace(200)* @preidx8zext64(i8 addrspace(200)* %src, i64 addrspace(200)* %out) {
; CHECK: ldrb    w[[REG:[0-9]+]], [c0, #1]!
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %src, i64 1
  %tmp = load i8, i8 addrspace(200)* %ptr, align 4
  %ext = zext i8 %tmp to i64
  store i64 %ext, i64 addrspace(200)* %out, align 4
  ret i8 addrspace(200)* %ptr
}

define i32 addrspace(200)* @preidx32sext64(i32 addrspace(200)* %src, i64 addrspace(200)* %out) {
; CHECK: ldrsw   x[[REG:[0-9]+]], [c0, #4]!
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i32, i32 addrspace(200)* %src, i64 1
  %tmp = load i32, i32 addrspace(200)* %ptr, align 4
  %ext = sext i32 %tmp to i64
  store i64 %ext, i64 addrspace(200)* %out, align 8
  ret i32 addrspace(200)* %ptr
}

define i16 addrspace(200)* @preidx16sext32(i16 addrspace(200)* %src, i32 addrspace(200)* %out) {
; CHECK: ldrsh   w[[REG:[0-9]+]], [c0, #2]!
; CHECK: str     w[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %src, i64 1
  %tmp = load i16, i16 addrspace(200)* %ptr, align 4
  %ext = sext i16 %tmp to i32
  store i32 %ext, i32 addrspace(200)* %out, align 4
  ret i16 addrspace(200)* %ptr
}

define i16 addrspace(200)* @preidx16sext64(i16 addrspace(200)* %src, i64 addrspace(200)* %out) {
; CHECK: ldrsh   x[[REG:[0-9]+]], [c0, #2]!
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %src, i64 1
  %tmp = load i16, i16 addrspace(200)* %ptr, align 4
  %ext = sext i16 %tmp to i64
  store i64 %ext, i64 addrspace(200)* %out, align 4
  ret i16 addrspace(200)* %ptr
}

define i8 addrspace(200)* @preidx8sext32(i8 addrspace(200)* %src, i32 addrspace(200)* %out) {
; CHECK: ldrsb   w[[REG:[0-9]+]], [c0, #1]!
; CHECK: str     w[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %src, i64 1
  %tmp = load i8, i8 addrspace(200)* %ptr, align 4
  %ext = sext i8 %tmp to i32
  store i32 %ext, i32 addrspace(200)* %out, align 4
  ret i8 addrspace(200)* %ptr
}

define i8 addrspace(200)* @preidx8sext64(i8 addrspace(200)* %src, i64 addrspace(200)* %out) {
; CHECK: ldrsb   x[[REG:[0-9]+]], [c0, #1]!
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %src, i64 1
  %tmp = load i8, i8 addrspace(200)* %ptr, align 4
  %ext = sext i8 %tmp to i64
  store i64 %ext, i64 addrspace(200)* %out, align 4
  ret i8 addrspace(200)* %ptr
}

;-----
; Post-indexed loads
;-----
define double addrspace(200)* @ldridxf64(double addrspace(200)* %src, double addrspace(200)* %out) {
; CHECK-LABEL: ldridxf64:
; CHECK: ldr     d0, [c0], #8
; CHECK: str     d0, [c1]
; CHECK: ret
  %ptr = getelementptr inbounds double, double addrspace(200)* %src, i64 1
  %tmp = load double, double addrspace(200)* %src, align 4
  store double %tmp, double addrspace(200)* %out, align 4
  ret double addrspace(200)* %ptr
}

define float addrspace(200)* @ldridxf32(float addrspace(200)* %src, float addrspace(200)* %out) {
; CHECK-LABEL: ldridxf32:
; CHECK: ldr     s0, [c0], #4
; CHECK: str     s0, [c1]
; CHECK: ret
  %ptr = getelementptr inbounds float, float addrspace(200)* %src, i64 1
  %tmp = load float, float addrspace(200)* %src, align 4
  store float %tmp, float addrspace(200)* %out, align 4
  ret float addrspace(200)* %ptr
}

define half addrspace(200)* @ldridxf16(half addrspace(200)* %src, half addrspace(200)* %out) {
; CHECK-LABEL: ldridxf16:
; CHECK: ldr     h0, [c0], #2
; CHECK: str     h0, [c1]
; CHECK: ret
  %ptr = getelementptr inbounds half, half addrspace(200)* %src, i64 1
  %tmp = load half, half addrspace(200)* %src, align 2
  store half %tmp, half addrspace(200)* %out, align 2
  ret half addrspace(200)* %ptr
}

define i64 addrspace(200)* @ldridx64(i64 addrspace(200)* %src, i64 addrspace(200)* %out) {
; CHECK-LABEL: ldridx64:
; CHECK: ldr     x[[REG:[0-9]+]], [c0], #8
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i64, i64 addrspace(200)* %src, i64 1
  %tmp = load i64, i64 addrspace(200)* %src, align 4
  store i64 %tmp, i64 addrspace(200)* %out, align 4
  ret i64 addrspace(200)* %ptr
}

define i32 addrspace(200)* @ldridx32(i32 addrspace(200)* %src, i32 addrspace(200)* %out) {
; CHECK-LABEL: ldridx32:
; CHECK: ldr     w[[REG:[0-9]+]], [c0], #4
; CHECK: str     w[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i32, i32 addrspace(200)* %src, i64 1
  %tmp = load i32, i32 addrspace(200)* %src, align 4
  store i32 %tmp, i32 addrspace(200)* %out, align 4
  ret i32 addrspace(200)* %ptr
}

define i16 addrspace(200)* @ldridx16zext32(i16 addrspace(200)* %src, i32 addrspace(200)* %out) {
; CHECK-LABEL: ldridx16zext32:
; CHECK: ldrh    w[[REG:[0-9]+]], [c0], #2
; CHECK: str     w[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %src, i64 1
  %tmp = load i16, i16 addrspace(200)* %src, align 4
  %ext = zext i16 %tmp to i32
  store i32 %ext, i32 addrspace(200)* %out, align 4
  ret i16 addrspace(200)* %ptr
}

define i16 addrspace(200)* @ldridx16zext64(i16 addrspace(200)* %src, i64 addrspace(200)* %out) {
; CHECK-LABEL: ldridx16zext64:
; CHECK: ldrh    w[[REG:[0-9]+]], [c0], #2
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %src, i64 1
  %tmp = load i16, i16 addrspace(200)* %src, align 4
  %ext = zext i16 %tmp to i64
  store i64 %ext, i64 addrspace(200)* %out, align 4
  ret i16 addrspace(200)* %ptr
}

define i8 addrspace(200)* @ldridx8zext32(i8 addrspace(200)* %src, i32 addrspace(200)* %out) {
; CHECK-LABEL: ldridx8zext32:
; CHECK: ldrb    w[[REG:[0-9]+]], [c0], #1
; CHECK: str     w[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %src, i64 1
  %tmp = load i8, i8 addrspace(200)* %src, align 4
  %ext = zext i8 %tmp to i32
  store i32 %ext, i32 addrspace(200)* %out, align 4
  ret i8 addrspace(200)* %ptr
}

define i8 addrspace(200)* @ldridx8zext64(i8 addrspace(200)* %src, i64 addrspace(200)* %out) {
; CHECK-LABEL: ldridx8zext64:
; CHECK: ldrb    w[[REG:[0-9]+]], [c0], #1
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %src, i64 1
  %tmp = load i8, i8 addrspace(200)* %src, align 4
  %ext = zext i8 %tmp to i64
  store i64 %ext, i64 addrspace(200)* %out, align 4
  ret i8 addrspace(200)* %ptr
}

define i32 addrspace(200)* @ldridx32sext64(i32 addrspace(200)* %src, i64 addrspace(200)* %out) {
; CHECK-LABEL: ldridx32sext64:
; CHECK: ldrsw   x[[REG:[0-9]+]], [c0], #4
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i32, i32 addrspace(200)* %src, i64 1
  %tmp = load i32, i32 addrspace(200)* %src, align 4
  %ext = sext i32 %tmp to i64
  store i64 %ext, i64 addrspace(200)* %out, align 8
  ret i32 addrspace(200)* %ptr
}

define i16 addrspace(200)* @ldridx16sext32(i16 addrspace(200)* %src, i32 addrspace(200)* %out) {
; CHECK-LABEL: ldridx16sext32:
; CHECK: ldrsh   w[[REG:[0-9]+]], [c0], #2
; CHECK: str     w[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %src, i64 1
  %tmp = load i16, i16 addrspace(200)* %src, align 4
  %ext = sext i16 %tmp to i32
  store i32 %ext, i32 addrspace(200)* %out, align 4
  ret i16 addrspace(200)* %ptr
}

define i16 addrspace(200)* @ldridx16sext64(i16 addrspace(200)* %src, i64 addrspace(200)* %out) {
; CHECK-LABEL: ldridx16sext64:
; CHECK: ldrsh   x[[REG:[0-9]+]], [c0], #2
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %src, i64 1
  %tmp = load i16, i16 addrspace(200)* %src, align 4
  %ext = sext i16 %tmp to i64
  store i64 %ext, i64 addrspace(200)* %out, align 4
  ret i16 addrspace(200)* %ptr
}

define i8 addrspace(200)* @ldridx8sext32(i8 addrspace(200)* %src, i32 addrspace(200)* %out) {
; CHECK-LABEL: ldridx8sext32:
; CHECK: ldrsb   w[[REG:[0-9]+]], [c0], #1
; CHECK: str     w[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %src, i64 1
  %tmp = load i8, i8 addrspace(200)* %src, align 4
  %ext = sext i8 %tmp to i32
  store i32 %ext, i32 addrspace(200)* %out, align 4
  ret i8 addrspace(200)* %ptr
}

define i8 addrspace(200)* @ldridx8sext64(i8 addrspace(200)* %src, i64 addrspace(200)* %out) {
; CHECK-LABEL: ldridx8sext64:
; CHECK: ldrsb   x[[REG:[0-9]+]], [c0], #1
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %src, i64 1
  %tmp = load i8, i8 addrspace(200)* %src, align 4
  %ext = sext i8 %tmp to i64
  store i64 %ext, i64 addrspace(200)* %out, align 4
  ret i8 addrspace(200)* %ptr
}

define i8 addrspace(200)* addrspace(200)* @ldridxcap_capbase(i8 addrspace(200)* addrspace(200)* %src, i8 addrspace(200)* addrspace(200)* %out) {
; CHECK-LABEL: ldridxcap_capbase:
; CHECK: ldr   c[[REG:[0-9]+]], [c0], #4080
; CHECK: str   c[[REG]], [c1, #0]
; CHECK: ret
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %src, i64 255
  %tmp = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %src, align 16
  store i8 addrspace(200)* %tmp, i8 addrspace(200)* addrspace(200)* %out, align 16
  ret i8 addrspace(200)* addrspace(200)* %ptr
}

define i8 addrspace(200)* addrspace(200)* @ldridxcap_capbase_not(i8 addrspace(200)* addrspace(200)* %src, i8 addrspace(200)* addrspace(200)* %out) {
; CHECK-LABEL: ldridxcap_capbase_not:
; CHECK-NOT: ldr   c[[REG:[0-9]+]], [c0],
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %src, i64 256
  %tmp = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %src, align 16
  store i8 addrspace(200)* %tmp, i8 addrspace(200)* addrspace(200)* %out, align 16
  ret i8 addrspace(200)* addrspace(200)* %ptr
}

define i8 addrspace(200)** @ldridxcap_regbase_not(i8 addrspace(200)** %src, i8 addrspace(200)** %out) {
; CHECK-LABEL: ldridxcap_regbase_not:
; CHECK-NOT: ldr   c[[REG:[0-9]+]], [x0],
; CHECK: stur   c[[REG]], [x1, #0]
; CHECK: ret
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)** %src, i64 8
  %tmp = load i8 addrspace(200)*, i8 addrspace(200)** %src, align 16
  store i8 addrspace(200)* %tmp, i8 addrspace(200)** %out, align 16
  ret i8 addrspace(200)** %ptr
}

define i64 addrspace(200)* addrspace(200)*
@store_cap(i64 addrspace(200)* addrspace(200)* %tmp, i64 %index, i64 addrspace(200)* %spacing) nounwind noinline ssp {
; CHECK-LABEL: store_cap:
; CHECK: str c{{[0-9+]}}, [c{{[0-9+]}}], #4080
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i64 addrspace(200)*, i64 addrspace(200)* addrspace(200)* %tmp, i64 255
  store i64 addrspace(200)* %spacing, i64 addrspace(200)* addrspace(200)* %tmp, align 16
  ret i64 addrspace(200)* addrspace(200)* %incdec.ptr
}

define i64 addrspace(200)* addrspace(200)*
@store_cap_not(i64 addrspace(200)* addrspace(200)* %tmp, i64 %index, i64 addrspace(200)* %spacing) nounwind noinline ssp {
; CHECK-LABEL: store_cap_not:
; CHECK-NOT: str c{{[0-9+]}}, [c{{[0-9+]}}],
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i64 addrspace(200)*, i64 addrspace(200)* addrspace(200)* %tmp, i64 256
  store i64 addrspace(200)* %spacing, i64 addrspace(200)* addrspace(200)* %tmp, align 16
  ret i64 addrspace(200)* addrspace(200)* %incdec.ptr
}

define i64 addrspace(200)**
@store_cap_reg_not(i64 addrspace(200)** %tmp, i64 %index, i64 addrspace(200)* %spacing) nounwind noinline ssp {
; CHECK-LABEL: store_cap_reg_not:
; CHECK-NOT: str c{{[0-9+]}}, [x{{[0-9+]}}],
  %incdec.ptr = getelementptr inbounds i64 addrspace(200)*, i64 addrspace(200)** %tmp, i64 8
  store i64 addrspace(200)* %spacing, i64 addrspace(200)** %tmp, align 16
  ret i64 addrspace(200)** %incdec.ptr
}

define i8 addrspace(200)* addrspace(200)* @ldrc_pre_cap(i8 addrspace(200)* addrspace(200)* %src, i8 addrspace(200)* addrspace(200)* %out) {
; CHECK-LABEL: ldrc_pre_cap:
; CHECK: ldr c2, [c0, #-64]!
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %src, i64 -4
  %tmp = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %ptr, align 16
  store i8 addrspace(200)* %tmp, i8 addrspace(200)* addrspace(200)* %out, align 16
  ret i8 addrspace(200)* addrspace(200)* %ptr
}
