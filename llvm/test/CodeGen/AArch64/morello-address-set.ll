; RUN: llc -mtriple=arm64 -mattr=+morello -o - %s | FileCheck %s

; CHECK-LABEL: foo:
define ptr addrspace(200) @foo(ptr addrspace(200) %in, i64 %addr) {
  %1 = tail call ptr addrspace(200) @llvm.cheri.cap.address.set(ptr addrspace(200) %in, i64 %addr)
  ret ptr addrspace(200) %1
; CHECK: scvalue c0, c0, x1
; CHECK-NEXT:   ret
}

declare ptr addrspace(200) @llvm.cheri.cap.address.set(ptr addrspace(200), i64)
