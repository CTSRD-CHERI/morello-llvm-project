; RUN: llc -o - -march=arm64 -mattr=+morello,+c64 -target-abi purecap %s | FileCheck %s
target datalayout = "e-m:e-i64:64-i128:128-n32:64-S128-pf200:128:128:128:64-A200-P200-G200"
target triple = "aarch64-none--elf"

declare ptr addrspace(200) @llvm.returnaddress.p200(i32) addrspace(200)

; CHECK-LABEL: getLinkRegister
define ptr addrspace(200) @getLinkRegister() addrspace(200) {
entry:
  %0 = tail call ptr addrspace(200) @llvm.returnaddress.p200(i32 0)
  ret ptr addrspace(200) %0
; CHECK: mov	c0, c30
}

; CHECK-LABEL: getLRFromFrameRecord
define ptr addrspace(200) @getLRFromFrameRecord() addrspace(200) {
entry:
  %0 = tail call ptr addrspace(200) @llvm.returnaddress.p200(i32 1)
  ret ptr addrspace(200) %0
; CHECK: ldr	c[[N:[0-9]+]], [c29, #0]
; CHECK: ldr	c{{[0-9]+}}, [c[[N]], #16]
}
