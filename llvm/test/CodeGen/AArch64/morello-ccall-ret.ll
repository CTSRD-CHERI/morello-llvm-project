target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none-linux-gnu"

; RUN: llc -march=arm64 -mattr=+morello,+c64 -target-abi purecap -o - %s | FileCheck %s

; CHECK-LABEL: foo
; CHECK: mov w0, #1
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
define chericcallcce i32 @foo() addrspace(200) {
entry:
  ret i32 1
}

%struct.cheri_object = type { ptr addrspace(200), ptr addrspace(200) }
@other = common local_unnamed_addr addrspace(200) global %struct.cheri_object zeroinitializer, align 16
@__cheri_method.cls.foo = linkonce_odr addrspace(200) global i64 0, section ".CHERI_CALLER"
@cls = common local_unnamed_addr addrspace(200) global %struct.cheri_object zeroinitializer, align 16

; CHECK-LABEL: bar
define void @bar(i32 %a, i32 %b) addrspace(200) {
entry:
; CHECK-DAG: adrp c[[ADDR:[0-9]+]], :got:__cheri_method.cls.foo
; CHECK-DAG: ldr c[[ADDR]], [c[[ADDR]], :got_lo12:__cheri_method.cls.foo]
; CHECK-DAG: ldr x11, [c[[ADDR]]]
; CHECK-DAG: ldp c9, c10
; CHECK-DAG: mov x2, xzr
; CHECK-DAG: mov x3, xzr
; CHECK-DAG: mov x4, xzr
; CHECK-DAG: mov x5, xzr
; CHECK-DAG: mov x6, xzr
; CHECK-DAG: mov x7, xzr
; CHECK-DAG: mov x8, xzr
; CHECK-DAG: fmov d0, xzr
; CHECK-DAG: fmov d1, xzr
; CHECK-DAG: fmov d2, xzr
; CHECK-DAG: fmov d3, xzr
; CHECK-DAG: fmov d4, xzr
; CHECK-DAG: fmov d5, xzr
; CHECK-DAG: fmov d6, xzr
; CHECK-DAG: fmov d7, xzr
; CHECK: bl cheri_invoke
  %0 = load i64, ptr addrspace(200) @__cheri_method.cls.foo, align 8
  %.unpack = load ptr addrspace(200), ptr addrspace(200) @other, align 16
  %1 = insertvalue [2 x ptr addrspace(200)] undef, ptr addrspace(200) %.unpack, 0
  %.unpack3 = load ptr addrspace(200), ptr addrspace(200) getelementptr inbounds (%struct.cheri_object, ptr addrspace(200) @other, i64 0, i32 1), align 16
  %2 = insertvalue [2 x ptr addrspace(200)] %1, ptr addrspace(200) %.unpack3, 1
  tail call chericcallcc void @cheri_invoke([2 x ptr addrspace(200)] %2, i64 %0, i32 %a, i32 %b)
  ret void
}

declare void @cheri_invoke([2 x ptr addrspace(200)], i64, i32, i32) addrspace(200)
