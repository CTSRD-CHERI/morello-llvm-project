; RUN: llc -mtriple=arm64 -mattr=+morello -o - %s | FileCheck %s

; CHECK-LABEL: testPtrToCap:
define ptr addrspace(200) @testPtrToCap(ptr %p) {
entry:
  %0 = addrspacecast ptr %p to ptr addrspace(200)
  ret ptr addrspace(200) %0
; CHECK:	mrs	c1, DDC
; CHECK-NEXT:	cvtz	c0, c1, x0
}

; CHECK-LABEL: testCapToPtr:
define ptr @testCapToPtr(ptr addrspace(200) %c) {
entry:
  %0 = addrspacecast ptr addrspace(200) %c to ptr
  ret ptr %0
; CHECK:	gcvalue	x0, c0
}

declare i64 @llvm.cheri.cap.to.pointer(ptr addrspace(200), ptr addrspace(200))
declare i64 @llvm.cheri.cap.address.get(ptr addrspace(200))

; CHECK-LABEL: testCapToPtr2:
define ptr @testCapToPtr2(ptr addrspace(200) %tab) {
entry:
  %idx = getelementptr inbounds i32, ptr addrspace(200) %tab, i64 2
  %0 = tail call i64 @llvm.cheri.cap.address.get(ptr addrspace(200) %idx)
  %1 = inttoptr i64 %0 to ptr
  ret ptr %1
; CHECK:        add     c0, c0, #8
; CHECK-NEXT:   gcvalue   x0, c0
; CHECK-NEXT:   ret
}

; CHECK-LABEL: testCapToPtr3:
define ptr @testCapToPtr3(ptr addrspace(200) %tab) {
entry:
  %idx = getelementptr inbounds i32, ptr addrspace(200) %tab, i64 2
  %0 = tail call i64 @llvm.cheri.cap.to.pointer(ptr addrspace(200) null, ptr addrspace(200) %idx)
  %1 = inttoptr i64 %0 to ptr
  ret ptr %1
; CHECK:        add     c0, c0, #8
; CHECK-NEXT:   cvt     x0, c0, czr
; CHECK-NEXT:   ret
}

; CHECK-LABEL: testCapToPtr4:
define ptr @testCapToPtr4(ptr addrspace(200) %t) {
entry:
  %0 = tail call i64 @llvm.cheri.cap.to.pointer(ptr addrspace(200) null, ptr addrspace(200) %t)
  %1 = inttoptr i64 %0 to ptr
  ret ptr %1
; CHECK:        cvt     x0, c0, czr
; CHECK-NEXT:   ret
}

; CHECK-LABEL: testNullToCap:
define ptr addrspace(200) @testNullToCap() {
entry:
  %0 = addrspacecast ptr null to ptr addrspace(200)
  ret ptr addrspace(200) %0
; CHECK:	mov     x0, xzr
; CHECK-NEXT:	ret
}
