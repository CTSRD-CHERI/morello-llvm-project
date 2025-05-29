; RUN: llc -mtriple=arm64 -mattr=+c64,+morello,+use-16-cap-regs -target-abi purecap -o - %s -verify-machineinstrs | FileCheck %s --check-prefix=PCS16
; RUN: llc -mtriple=arm64 -mattr=+c64,+morello -target-abi purecap -o - %s -verify-machineinstrs | FileCheck %s --check-prefix=PCS32

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"

@ss = local_unnamed_addr addrspace(200) global [1048577 x i32] zeroinitializer, align 4
@s3 = common local_unnamed_addr addrspace(200) global [1048577 x i32] zeroinitializer, align 4
@s4 = common local_unnamed_addr addrspace(200) global [1024 x i32] zeroinitializer, align 4

; CHECK-LABEL: fun1
define i32 @fun1() addrspace(200) {
entry:
; Allocate extra memory. CSP still needs to be 16 bytes aligned.
; PCS16:	sub csp, csp, #1024, lsl #12
; PCS16-NEXT: sub csp, csp, #4032

; PCS16: mov w[[REG:[0-9]+]], #2048
; PCS16: movk w[[REG]], #64, lsl #16
; PCS16: scbnds c{{.*}}, c{{.*}}, x[[REG]]

  %ss1 = alloca [1048577 x i32], align 4, addrspace(200)
  call void @llvm.memset.p200.i64(ptr addrspace(200) nonnull %ss1, i8 0, i64 4194308, i32 4, i1 false)
  %call = call i32 @g(ptr addrspace(200) nonnull %ss1)
  ret i32 %call
}

declare void @llvm.memset.p200.i64(ptr addrspace(200) nocapture writeonly, i8, i64, i32, i1) addrspace(200) #1

declare i32 @g(ptr addrspace(200)) local_unnamed_addr addrspace(200) #2


; CHECK-LABEL: fun2
define i32 @fun2() addrspace(200) {
entry:
; Here we need more alignment than the stack alignment.
; PCS16: alignd	csp, csp, #14
; PCS16: mov w[[REG:[0-9]+]], #33554432
; PCS16: scbnds c{{.*}}, c{{.*}}, x[[REG]]
;
; PCS32: alignd	csp, csp, #14
; PCS32: mov w[[REG:[0-9]+]], #33554432
; PCS32: scbnds c{{.*}}, c{{.*}}, x[[REG]]

  %s1 = alloca [8388608 x i32], align 4, addrspace(200)
  %call = call i32 @g(ptr addrspace(200) nonnull %s1)
  ret i32 %call
}

; The following object has a constant initializer. Align it and pad it with zeros.
; PCS16: .type ss,@object
; PCS16-NEXT: .bss
; PCS16-NEXT:    .globl ss
; PCS16-NEXT:    .p2align 11
; PCS16-NEXT: ss:
; PCS16-NEXT:    .zero 4194308
; PCS16-NEXT:    .zero 2044
; PCS16-NEXT:    .size ss, 4196352

; Pad and align this object.
; PCS16: .type s3,@object
; PCS16-NEXT: .comm s3,4196352,2048

; Small objectes don't need extra alignment or padding.
; PCS16: .type s4,@object
; PCS16-NEXT: .comm s4,4096,4

