; RUN: llc -mtriple=arm64 -mattr=+morello -o - %s | FileCheck %s

; CHECK-LABEL: foo:
define i8 addrspace(200)* @foo(i32 addrspace(200)* %in, i64 %addr) {
  %1 = bitcast i32 addrspace(200)* %in to i8 addrspace(200)*
  %2 = tail call i8 addrspace(200)* @llvm.cheri.cap.address.set(i8 addrspace(200)* %1, i64 %addr)
  ret i8 addrspace(200)* %2
; CHECK: scvalue c0, c0, x1
; CHECK-NEXT:   ret
}

declare i8 addrspace(200)* @llvm.cheri.cap.address.set(i8 addrspace(200)*, i64)
