; RUN: llc -mtriple=aarch64-unknown-linux-android -mattr=+c64,+morello -target-abi purecap -o - %s | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"

@vone = external dso_local addrspace(200) constant float, align 4
@vzero = external dso_local addrspace(200) constant float, align 4
@pr8 = external dso_local unnamed_addr addrspace(200) constant [6 x float], align 4
@ps8 = external dso_local unnamed_addr addrspace(200) constant [5 x float], align 4
@pr5 = external dso_local unnamed_addr addrspace(200) constant [6 x float], align 4
@ps5 = external dso_local unnamed_addr addrspace(200) constant [5 x float], align 4
@pr3 = external dso_local unnamed_addr addrspace(200) constant [6 x float], align 4
@ps3 = external dso_local unnamed_addr addrspace(200) constant [5 x float], align 4
@pr2 = external dso_local unnamed_addr addrspace(200) constant [6 x float], align 4
@ps2 = external dso_local unnamed_addr addrspace(200) constant [5 x float], align 4
@qr8 = external dso_local unnamed_addr addrspace(200) constant [6 x float], align 4
@qs8 = external dso_local unnamed_addr addrspace(200) constant [6 x float], align 4
@qr5 = external dso_local unnamed_addr addrspace(200) constant [6 x float], align 4
@qs5 = external dso_local unnamed_addr addrspace(200) constant [6 x float], align 4
@qr3 = external dso_local unnamed_addr addrspace(200) constant [6 x float], align 4
@qs3 = external dso_local unnamed_addr addrspace(200) constant [6 x float], align 4
@qr2 = external dso_local unnamed_addr addrspace(200) constant [6 x float], align 4
@qs2 = external dso_local unnamed_addr addrspace(200) constant [6 x float], align 4

; Function Attrs: nounwind readnone speculatable
declare float @llvm.fabs.f32(float) addrspace(200) #1

; Function Attrs: nounwind readnone speculatable
declare float @llvm.sin.f32(float) addrspace(200) #1

; Function Attrs: nounwind readnone speculatable
declare float @llvm.cos.f32(float) addrspace(200) #1

; Function Attrs: nounwind readnone speculatable
declare float @llvm.sqrt.f32(float) addrspace(200) #1

; CHECK-LABEL: foo
; CHECK: bl	sincosf
define float @foo(float %x) local_unnamed_addr addrspace(200) #0 {
entry:
  %0 = tail call float @llvm.sin.f32(float %x)
  %1 = tail call float @llvm.cos.f32(float %x)
  %sub = fsub float -0.000000e+00, %0
  %sub11 = fsub float %sub, %1
  %mul25 = fmul float %sub11, 0x3FE20DD760000000
  %div26 = fdiv float %mul25, 0.000000e+00
  ret float %div26
}

; Function Attrs: nounwind readnone speculatable
declare float @llvm.log.f32(float) addrspace(200) #1

attributes #0 = { "use-soft-float"="false" }
attributes #1 = { nounwind readnone speculatable }
