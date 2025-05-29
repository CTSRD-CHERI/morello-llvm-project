; RUN: llc -march=arm64 -mattr=+c64,+morello -target-abi purecap  -o - %s | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none-unknown-elf"

@var = external dso_local addrspace(200) global [512 x i64], align 8

; CHECK-LABEL: foo
; CHECK: adrp {{.*}}, :got:var
; CHECK-NEXT: movi v0.2d, #0000000000000000
; CHECK-NEXT: ldr c0, [c0, :got_lo12:var]
; CHECK-NEXT: stp q0, q0, [c0]
; CHECK-NEXT: brk #0x1
define dso_local void @foo() local_unnamed_addr addrspace(200) {
entry:
  %0 = getelementptr inbounds [512 x i64], ptr addrspace(200) @var, i64 0, <4 x i64> undef
  %1 = extractelement <4 x ptr addrspace(200)> %0, i32 0
  store <4 x i64> zeroinitializer, ptr addrspace(200) %1, align 8
  call void @llvm.trap()
  unreachable
}

declare void @llvm.trap() addrspace(200)
