; RUN: llc -mtriple=arm64 -mattr=+morello %s -o - -aarch64-enable-ldst-opt=false | FileCheck %s

; CHECK-LABEL: @t0
define void @t0(i8* nocapture %dst, i8* nocapture %src) {
; CHECK: ldr [[REG:c[0-9]+]]
; CHECK: str [[REG]]
  call void @llvm.memcpy.p0i8.p0i8.i32(i8* %dst, i8* %src, i32 32, i32 16, i1 false)
  ret void
}

; CHECK-LABEL: @t1
define void @t1(i8* nocapture %dst, i8* nocapture %src) {
; CHECK: ldr [[REG:c[0-9]+]]
; CHECK: str [[REG]]
  call void @llvm.memcpy.p0i8.p0i8.i32(i8* %dst, i8* %src, i32 32, i32 32, i1 false)
  ret void
}

; CHECK-LABEL: @t2
define void @t2(i8* nocapture %dst, i8* nocapture %src) {
; CHECK-NOT: ldr {{c[0-9]+}}
; CHECK-NOT: str {{c[0-9]+}}
  call void @llvm.memcpy.p0i8.p0i8.i32(i8* %dst, i8* %src, i32 15, i32 16, i1 false)
  ret void
}

; CHECK-LABEL: @t3
define void @t3(i8* nocapture %dst, i8* nocapture %src) {
; CHECK: ldr [[REG:c[0-9]+]]
; CHECK: str [[REG]]
  call void @llvm.memcpy.p0i8.p0i8.i32(i8* %dst, i8* %src, i32 32, i32 16, i1 false) #0
  ret void
}

; CHECK-LABEL: @t4
define void @t4(i8* nocapture %dst, i8* nocapture %src) {
; CHECK: bl memcpy
  call void @llvm.memcpy.p0i8.p0i8.i32(i8* %dst, i8* %src, i32 32, i32 8, i1 false) #0
  ret void
}

; CHECK-LABEL: @t5
define void @t5(i8* nocapture %dst, i8* nocapture %src) {
; CHECK: ldr [[REG:x[0-9]+]], [x1]
; CHECK: str [[REG]], [x0]
  call void @llvm.memcpy.p0i8.p0i8.i32(i8* %dst, i8* %src, i32 8, i32 8, i1 false) #0
  ret void
}

declare void @llvm.memcpy.p0i8.p0i8.i32(i8* nocapture, i8* nocapture, i32, i32, i1) nounwind

attributes #0 = { "must-preserve-cheri-tags" }
