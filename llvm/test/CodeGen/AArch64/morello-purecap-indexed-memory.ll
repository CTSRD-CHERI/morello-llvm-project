; RUN: llc < %s -mtriple=arm64 -mattr=+c64,+morello -target-abi purecap -aarch64-redzone | FileCheck %s

define ptr addrspace(200) @store64(ptr addrspace(200) %tmp, i64 %index, i64 %spacing) nounwind noinline ssp {
; CHECK-LABEL: store64:
; CHECK: str x{{[0-9+]}}, [c{{[0-9+]}}], #8
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i64, ptr addrspace(200) %tmp, i64 1
  store i64 %spacing, ptr addrspace(200) %tmp, align 4
  ret ptr addrspace(200) %incdec.ptr
}

define ptr addrspace(200) @store32(ptr addrspace(200) %tmp, i32 %index, i32 %spacing) nounwind noinline ssp {
; CHECK-LABEL: store32:
; CHECK: str w{{[0-9+]}}, [c{{[0-9+]}}], #4
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i32, ptr addrspace(200) %tmp, i64 1
  store i32 %spacing, ptr addrspace(200) %tmp, align 4
  ret ptr addrspace(200) %incdec.ptr
}

define ptr addrspace(200) @store16(ptr addrspace(200) nocapture %tmp, i16 %index, i16 %spacing) nounwind noinline ssp {
; CHECK-LABEL: store16:
; CHECK: strh w{{[0-9+]}}, [c{{[0-9+]}}], #2
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i16, ptr addrspace(200) %tmp, i64 1
  store i16 %spacing, ptr addrspace(200) %tmp, align 4
  ret ptr addrspace(200) %incdec.ptr
}

define ptr addrspace(200) @store8(ptr addrspace(200) %tmp, i8 %index, i8 %spacing) nounwind noinline ssp {
; CHECK-LABEL: store8:
; CHECK: strb w{{[0-9+]}}, [c{{[0-9+]}}], #1
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i8, ptr addrspace(200) %tmp, i64 1
  store i8 %spacing, ptr addrspace(200) %tmp, align 4
  ret ptr addrspace(200) %incdec.ptr
}

define ptr addrspace(200) @truncst64to32(ptr addrspace(200) nocapture %tmp, i32 %index, i64 %spacing) nounwind noinline ssp {
; CHECK-LABEL: truncst64to32:
; CHECK: str w{{[0-9+]}}, [c{{[0-9+]}}], #4
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i32, ptr addrspace(200) %tmp, i64 1
  %trunc = trunc i64 %spacing to i32
  store i32 %trunc, ptr addrspace(200) %tmp, align 4
  ret ptr addrspace(200) %incdec.ptr
}

define ptr addrspace(200) @truncst64to16(ptr addrspace(200) nocapture %tmp, i16 %index, i64 %spacing) nounwind noinline ssp {
; CHECK-LABEL: truncst64to16:
; CHECK: strh w{{[0-9+]}}, [c{{[0-9+]}}], #2
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i16, ptr addrspace(200) %tmp, i64 1
  %trunc = trunc i64 %spacing to i16
  store i16 %trunc, ptr addrspace(200) %tmp, align 4
  ret ptr addrspace(200) %incdec.ptr
}

define ptr addrspace(200) @truncst64to8(ptr addrspace(200) %tmp, i8 %index, i64 %spacing) nounwind noinline ssp {
; CHECK-LABEL: truncst64to8:
; CHECK: strb w{{[0-9+]}}, [c{{[0-9+]}}], #1
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i8, ptr addrspace(200) %tmp, i64 1
  %trunc = trunc i64 %spacing to i8
  store i8 %trunc, ptr addrspace(200) %tmp, align 4
  ret ptr addrspace(200) %incdec.ptr
}


define ptr addrspace(200) @storef16(ptr addrspace(200) %tmp, half %index, half %spacing) nounwind {
; CHECK-LABEL: storef16:
; CHECK: str h{{[0-9+]}}, [c{{[0-9+]}}], #2
; CHECK: ret
  %incdec.ptr = getelementptr inbounds half, ptr addrspace(200) %tmp, i64 1
  store half %spacing, ptr addrspace(200) %tmp, align 2
  ret ptr addrspace(200) %incdec.ptr
}

define ptr addrspace(200) @storef32(ptr addrspace(200) %tmp, float %index, float %spacing) nounwind noinline ssp {
; CHECK-LABEL: storef32:
; CHECK: str s{{[0-9+]}}, [c{{[0-9+]}}], #4
; CHECK: ret
  %incdec.ptr = getelementptr inbounds float, ptr addrspace(200) %tmp, i64 1
  store float %spacing, ptr addrspace(200) %tmp, align 4
  ret ptr addrspace(200) %incdec.ptr
}

define ptr addrspace(200) @storef64(ptr addrspace(200) %tmp, double %index, double %spacing) nounwind noinline ssp {
; CHECK-LABEL: storef64:
; CHECK: str d{{[0-9+]}}, [c{{[0-9+]}}], #8
; CHECK: ret
  %incdec.ptr = getelementptr inbounds double, ptr addrspace(200) %tmp, i64 1
  store double %spacing, ptr addrspace(200) %tmp, align 4
  ret ptr addrspace(200) %incdec.ptr
}

define ptr addrspace(200) @pre64(ptr addrspace(200) %tmp, i64 %index, i64 %spacing) nounwind noinline ssp {
; CHECK-LABEL: pre64:
; CHECK: str x{{[0-9+]}}, [c{{[0-9+]}}, #8]!
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i64, ptr addrspace(200) %tmp, i64 1
  store i64 %spacing, ptr addrspace(200) %incdec.ptr, align 4
  ret ptr addrspace(200) %incdec.ptr
}

define ptr addrspace(200) @pre32(ptr addrspace(200) %tmp, i32 %index, i32 %spacing) nounwind noinline ssp {
; CHECK-LABEL: pre32:
; CHECK: str w{{[0-9+]}}, [c{{[0-9+]}}, #4]!
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i32, ptr addrspace(200) %tmp, i64 1
  store i32 %spacing, ptr addrspace(200) %incdec.ptr, align 4
  ret ptr addrspace(200) %incdec.ptr
}

define ptr addrspace(200) @pre16(ptr addrspace(200) nocapture %tmp, i16 %index, i16 %spacing) nounwind noinline ssp {
; CHECK-LABEL: pre16:
; CHECK: strh w{{[0-9+]}}, [c{{[0-9+]}}, #2]!
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i16, ptr addrspace(200) %tmp, i64 1
  store i16 %spacing, ptr addrspace(200) %incdec.ptr, align 4
  ret ptr addrspace(200) %incdec.ptr
}

define ptr addrspace(200) @pre8(ptr addrspace(200) %tmp, i8 %index, i8 %spacing) nounwind noinline ssp {
; CHECK-LABEL: pre8:
; CHECK: strb w{{[0-9+]}}, [c{{[0-9+]}}, #1]!
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i8, ptr addrspace(200) %tmp, i64 1
  store i8 %spacing, ptr addrspace(200) %incdec.ptr, align 4
  ret ptr addrspace(200) %incdec.ptr
}

define ptr addrspace(200) @pretruncst64to32(ptr addrspace(200) nocapture %tmp, i32 %index, i64 %spacing) nounwind noinline ssp {
; CHECK-LABEL: pretruncst64to32:
; CHECK: str w{{[0-9+]}}, [c{{[0-9+]}}, #4]!
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i32, ptr addrspace(200) %tmp, i64 1
  %trunc = trunc i64 %spacing to i32
  store i32 %trunc, ptr addrspace(200) %incdec.ptr, align 4
  ret ptr addrspace(200) %incdec.ptr
}

define ptr addrspace(200) @pretruncst64to16(ptr addrspace(200) nocapture %tmp, i16 %index, i64 %spacing) nounwind noinline ssp {
; CHECK-LABEL: pretruncst64to16:
; CHECK: strh w{{[0-9+]}}, [c{{[0-9+]}}, #2]!
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i16, ptr addrspace(200) %tmp, i64 1
  %trunc = trunc i64 %spacing to i16
  store i16 %trunc, ptr addrspace(200) %incdec.ptr, align 4
  ret ptr addrspace(200) %incdec.ptr
}

define ptr addrspace(200) @pretruncst64to8(ptr addrspace(200) %tmp, i8 %index, i64 %spacing) nounwind noinline ssp {
; CHECK-LABEL: pretruncst64to8:
; CHECK: strb w{{[0-9+]}}, [c{{[0-9+]}}, #1]!
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i8, ptr addrspace(200) %tmp, i64 1
  %trunc = trunc i64 %spacing to i8
  store i8 %trunc, ptr addrspace(200) %incdec.ptr, align 4
  ret ptr addrspace(200) %incdec.ptr
}

define ptr addrspace(200) @pref16(ptr addrspace(200) %tmp, half %index, half %spacing) nounwind {
; CHECK-LABEL: pref16:
; CHECK: str h{{[0-9+]}}, [c{{[0-9+]}}, #2]!
; CHECK: ret
  %incdec.ptr = getelementptr inbounds half, ptr addrspace(200) %tmp, i64 1
  store half %spacing, ptr addrspace(200) %incdec.ptr, align 2
  ret ptr addrspace(200) %incdec.ptr
}

define ptr addrspace(200) @pref32(ptr addrspace(200) %tmp, float %index, float %spacing) nounwind noinline ssp {
; CHECK-LABEL: pref32:
; CHECK: str s{{[0-9+]}}, [c{{[0-9+]}}, #4]!
; CHECK: ret
  %incdec.ptr = getelementptr inbounds float, ptr addrspace(200) %tmp, i64 1
  store float %spacing, ptr addrspace(200) %incdec.ptr, align 4
  ret ptr addrspace(200) %incdec.ptr
}

define ptr addrspace(200) @pref64(ptr addrspace(200) %tmp, double %index, double %spacing) nounwind noinline ssp {
; CHECK-LABEL: pref64:
; CHECK: str d{{[0-9+]}}, [c{{[0-9+]}}, #8]!
; CHECK: ret
  %incdec.ptr = getelementptr inbounds double, ptr addrspace(200) %tmp, i64 1
  store double %spacing, ptr addrspace(200) %incdec.ptr, align 4
  ret ptr addrspace(200) %incdec.ptr
}

;-----
; Pre-indexed loads
;-----
define ptr addrspace(200) @preidxf64(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: preidxf64:
; CHECK: ldr     d0, [c0, #8]!
; CHECK: str     d0, [c1]
; CHECK: ret
  %ptr = getelementptr inbounds double, ptr addrspace(200) %src, i64 1
  %tmp = load double, ptr addrspace(200) %ptr, align 4
  store double %tmp, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @preidxf32(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: preidxf32:
; CHECK: ldr     s0, [c0, #4]!
; CHECK: str     s0, [c1]
; CHECK: ret
  %ptr = getelementptr inbounds float, ptr addrspace(200) %src, i64 1
  %tmp = load float, ptr addrspace(200) %ptr, align 4
  store float %tmp, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @preidxf16(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: preidxf16:
; CHECK: ldr     h0, [c0, #2]!
; CHECK: str     h0, [c1]
; CHECK: ret
  %ptr = getelementptr inbounds half, ptr addrspace(200) %src, i64 1
  %tmp = load half, ptr addrspace(200) %ptr, align 2
  store half %tmp, ptr addrspace(200) %out, align 2
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @preidx64(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: preidx64:
; CHECK: ldr     x[[REG:[0-9]+]], [c0, #8]!
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i64, ptr addrspace(200) %src, i64 1
  %tmp = load i64, ptr addrspace(200) %ptr, align 4
  store i64 %tmp, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @preidx32(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK: ldr     w[[REG:[0-9]+]], [c0, #4]!
; CHECK: str     w[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i32, ptr addrspace(200) %src, i64 1
  %tmp = load i32, ptr addrspace(200) %ptr, align 4
  store i32 %tmp, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @preidx16zext32(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK: ldrh    w[[REG:[0-9]+]], [c0, #2]!
; CHECK: str     w[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i16, ptr addrspace(200) %src, i64 1
  %tmp = load i16, ptr addrspace(200) %ptr, align 4
  %ext = zext i16 %tmp to i32
  store i32 %ext, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @preidx16zext64(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK: ldrh    w[[REG:[0-9]+]], [c0, #2]!
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i16, ptr addrspace(200) %src, i64 1
  %tmp = load i16, ptr addrspace(200) %ptr, align 4
  %ext = zext i16 %tmp to i64
  store i64 %ext, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @preidx8zext32(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK: ldrb    w[[REG:[0-9]+]], [c0, #1]!
; CHECK: str     w[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i8, ptr addrspace(200) %src, i64 1
  %tmp = load i8, ptr addrspace(200) %ptr, align 4
  %ext = zext i8 %tmp to i32
  store i32 %ext, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @preidx8zext64(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK: ldrb    w[[REG:[0-9]+]], [c0, #1]!
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i8, ptr addrspace(200) %src, i64 1
  %tmp = load i8, ptr addrspace(200) %ptr, align 4
  %ext = zext i8 %tmp to i64
  store i64 %ext, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @preidx32sext64(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK: ldrsw   x[[REG:[0-9]+]], [c0, #4]!
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i32, ptr addrspace(200) %src, i64 1
  %tmp = load i32, ptr addrspace(200) %ptr, align 4
  %ext = sext i32 %tmp to i64
  store i64 %ext, ptr addrspace(200) %out, align 8
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @preidx16sext32(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK: ldrsh   w[[REG:[0-9]+]], [c0, #2]!
; CHECK: str     w[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i16, ptr addrspace(200) %src, i64 1
  %tmp = load i16, ptr addrspace(200) %ptr, align 4
  %ext = sext i16 %tmp to i32
  store i32 %ext, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @preidx16sext64(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK: ldrsh   x[[REG:[0-9]+]], [c0, #2]!
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i16, ptr addrspace(200) %src, i64 1
  %tmp = load i16, ptr addrspace(200) %ptr, align 4
  %ext = sext i16 %tmp to i64
  store i64 %ext, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @preidx8sext32(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK: ldrsb   w[[REG:[0-9]+]], [c0, #1]!
; CHECK: str     w[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i8, ptr addrspace(200) %src, i64 1
  %tmp = load i8, ptr addrspace(200) %ptr, align 4
  %ext = sext i8 %tmp to i32
  store i32 %ext, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @preidx8sext64(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK: ldrsb   x[[REG:[0-9]+]], [c0, #1]!
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i8, ptr addrspace(200) %src, i64 1
  %tmp = load i8, ptr addrspace(200) %ptr, align 4
  %ext = sext i8 %tmp to i64
  store i64 %ext, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

;-----
; Post-indexed loads
;-----
define ptr addrspace(200) @ldridxf64(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: ldridxf64:
; CHECK: ldr     d0, [c0], #8
; CHECK: str     d0, [c1]
; CHECK: ret
  %ptr = getelementptr inbounds double, ptr addrspace(200) %src, i64 1
  %tmp = load double, ptr addrspace(200) %src, align 4
  store double %tmp, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @ldridxf32(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: ldridxf32:
; CHECK: ldr     s0, [c0], #4
; CHECK: str     s0, [c1]
; CHECK: ret
  %ptr = getelementptr inbounds float, ptr addrspace(200) %src, i64 1
  %tmp = load float, ptr addrspace(200) %src, align 4
  store float %tmp, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @ldridxf16(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: ldridxf16:
; CHECK: ldr     h0, [c0], #2
; CHECK: str     h0, [c1]
; CHECK: ret
  %ptr = getelementptr inbounds half, ptr addrspace(200) %src, i64 1
  %tmp = load half, ptr addrspace(200) %src, align 2
  store half %tmp, ptr addrspace(200) %out, align 2
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @ldridx64(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: ldridx64:
; CHECK: ldr     x[[REG:[0-9]+]], [c0], #8
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i64, ptr addrspace(200) %src, i64 1
  %tmp = load i64, ptr addrspace(200) %src, align 4
  store i64 %tmp, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @ldridx32(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: ldridx32:
; CHECK: ldr     w[[REG:[0-9]+]], [c0], #4
; CHECK: str     w[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i32, ptr addrspace(200) %src, i64 1
  %tmp = load i32, ptr addrspace(200) %src, align 4
  store i32 %tmp, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @ldridx16zext32(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: ldridx16zext32:
; CHECK: ldrh    w[[REG:[0-9]+]], [c0], #2
; CHECK: str     w[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i16, ptr addrspace(200) %src, i64 1
  %tmp = load i16, ptr addrspace(200) %src, align 4
  %ext = zext i16 %tmp to i32
  store i32 %ext, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @ldridx16zext64(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: ldridx16zext64:
; CHECK: ldrh    w[[REG:[0-9]+]], [c0], #2
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i16, ptr addrspace(200) %src, i64 1
  %tmp = load i16, ptr addrspace(200) %src, align 4
  %ext = zext i16 %tmp to i64
  store i64 %ext, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @ldridx8zext32(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: ldridx8zext32:
; CHECK: ldrb    w[[REG:[0-9]+]], [c0], #1
; CHECK: str     w[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i8, ptr addrspace(200) %src, i64 1
  %tmp = load i8, ptr addrspace(200) %src, align 4
  %ext = zext i8 %tmp to i32
  store i32 %ext, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @ldridx8zext64(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: ldridx8zext64:
; CHECK: ldrb    w[[REG:[0-9]+]], [c0], #1
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i8, ptr addrspace(200) %src, i64 1
  %tmp = load i8, ptr addrspace(200) %src, align 4
  %ext = zext i8 %tmp to i64
  store i64 %ext, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @ldridx32sext64(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: ldridx32sext64:
; CHECK: ldrsw   x[[REG:[0-9]+]], [c0], #4
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i32, ptr addrspace(200) %src, i64 1
  %tmp = load i32, ptr addrspace(200) %src, align 4
  %ext = sext i32 %tmp to i64
  store i64 %ext, ptr addrspace(200) %out, align 8
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @ldridx16sext32(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: ldridx16sext32:
; CHECK: ldrsh   w[[REG:[0-9]+]], [c0], #2
; CHECK: str     w[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i16, ptr addrspace(200) %src, i64 1
  %tmp = load i16, ptr addrspace(200) %src, align 4
  %ext = sext i16 %tmp to i32
  store i32 %ext, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @ldridx16sext64(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: ldridx16sext64:
; CHECK: ldrsh   x[[REG:[0-9]+]], [c0], #2
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i16, ptr addrspace(200) %src, i64 1
  %tmp = load i16, ptr addrspace(200) %src, align 4
  %ext = sext i16 %tmp to i64
  store i64 %ext, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @ldridx8sext32(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: ldridx8sext32:
; CHECK: ldrsb   w[[REG:[0-9]+]], [c0], #1
; CHECK: str     w[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i8, ptr addrspace(200) %src, i64 1
  %tmp = load i8, ptr addrspace(200) %src, align 4
  %ext = sext i8 %tmp to i32
  store i32 %ext, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @ldridx8sext64(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: ldridx8sext64:
; CHECK: ldrsb   x[[REG:[0-9]+]], [c0], #1
; CHECK: str     x[[REG]], [c1]
; CHECK: ret
  %ptr = getelementptr inbounds i8, ptr addrspace(200) %src, i64 1
  %tmp = load i8, ptr addrspace(200) %src, align 4
  %ext = sext i8 %tmp to i64
  store i64 %ext, ptr addrspace(200) %out, align 4
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @ldridxcap_capbase(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: ldridxcap_capbase:
; CHECK: ldr   c[[REG:[0-9]+]], [c0], #4080
; CHECK: str   c[[REG]], [c1, #0]
; CHECK: ret
  %ptr = getelementptr inbounds ptr addrspace(200), ptr addrspace(200) %src, i64 255
  %tmp = load ptr addrspace(200), ptr addrspace(200) %src, align 16
  store ptr addrspace(200) %tmp, ptr addrspace(200) %out, align 16
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @ldridxcap_capbase_not(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: ldridxcap_capbase_not:
; CHECK-NOT: ldr   c[[REG:[0-9]+]], [c0],
  %ptr = getelementptr inbounds ptr addrspace(200), ptr addrspace(200) %src, i64 256
  %tmp = load ptr addrspace(200), ptr addrspace(200) %src, align 16
  store ptr addrspace(200) %tmp, ptr addrspace(200) %out, align 16
  ret ptr addrspace(200) %ptr
}

define ptr @ldridxcap_regbase_not(ptr %src, ptr %out) {
; CHECK-LABEL: ldridxcap_regbase_not:
; CHECK-NOT: ldr   c[[REG:[0-9]+]], [x0],
; CHECK: stur   c[[REG]], [x1, #0]
; CHECK: ret
  %ptr = getelementptr inbounds ptr addrspace(200), ptr %src, i64 8
  %tmp = load ptr addrspace(200), ptr %src, align 16
  store ptr addrspace(200) %tmp, ptr %out, align 16
  ret ptr %ptr
}

define ptr addrspace(200)
@store_cap(ptr addrspace(200) %tmp, i64 %index, ptr addrspace(200) %spacing) nounwind noinline ssp {
; CHECK-LABEL: store_cap:
; CHECK: str c{{[0-9+]}}, [c{{[0-9+]}}], #4080
; CHECK: ret
  %incdec.ptr = getelementptr inbounds ptr addrspace(200), ptr addrspace(200) %tmp, i64 255
  store ptr addrspace(200) %spacing, ptr addrspace(200) %tmp, align 16
  ret ptr addrspace(200) %incdec.ptr
}

define ptr addrspace(200)
@store_cap_not(ptr addrspace(200) %tmp, i64 %index, ptr addrspace(200) %spacing) nounwind noinline ssp {
; CHECK-LABEL: store_cap_not:
; CHECK-NOT: str c{{[0-9+]}}, [c{{[0-9+]}}],
; CHECK: ret
  %incdec.ptr = getelementptr inbounds ptr addrspace(200), ptr addrspace(200) %tmp, i64 256
  store ptr addrspace(200) %spacing, ptr addrspace(200) %tmp, align 16
  ret ptr addrspace(200) %incdec.ptr
}

define ptr
@store_cap_reg_not(ptr %tmp, i64 %index, ptr addrspace(200) %spacing) nounwind noinline ssp {
; CHECK-LABEL: store_cap_reg_not:
; CHECK-NOT: str c{{[0-9+]}}, [x{{[0-9+]}}],
  %incdec.ptr = getelementptr inbounds ptr addrspace(200), ptr %tmp, i64 8
  store ptr addrspace(200) %spacing, ptr %tmp, align 16
  ret ptr %incdec.ptr
}

define ptr addrspace(200) @ldrc_pre_cap(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: ldrc_pre_cap:
; CHECK: ldr c2, [c0, #-64]!
  %ptr = getelementptr inbounds ptr addrspace(200), ptr addrspace(200) %src, i64 -4
  %tmp = load ptr addrspace(200), ptr addrspace(200) %ptr, align 16
  store ptr addrspace(200) %tmp, ptr addrspace(200) %out, align 16
  ret ptr addrspace(200) %ptr
}
