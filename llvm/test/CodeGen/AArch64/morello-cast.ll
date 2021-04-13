; RUN: llc -mtriple=arm64 -mattr=+morello -o - %s | FileCheck %s

; CHECK-LABEL: testPtrToCap:
define i32 addrspace(200)* @testPtrToCap(i32* %p) {
entry:
  %0 = addrspacecast i32* %p to i32 addrspace(200)*
  ret i32 addrspace(200)* %0
; CHECK:	mrs	c1, DDC
; CHECK-NEXT:	cvtz	c0, c1, x0
}

; CHECK-LABEL: testCapToPtr:
define i32* @testCapToPtr(i32 addrspace(200)* %c) {
entry:
  %0 = addrspacecast i32 addrspace(200)* %c to i32*
  ret i32* %0
; CHECK:	gcvalue	x0, c0
}

declare i64 @llvm.cheri.cap.to.pointer(i8 addrspace(200)*, i8 addrspace(200)*)
declare i64 @llvm.cheri.cap.address.get(i8 addrspace(200)*)

; CHECK-LABEL: testCapToPtr2:
define i32* @testCapToPtr2(i32 addrspace(200)* %tab) {
entry:
  %idx = getelementptr inbounds i32, i32 addrspace(200)* %tab, i64 2
  %0 = bitcast i32 addrspace(200)* %idx to i8 addrspace(200)*
  %1 = tail call i64 @llvm.cheri.cap.address.get(i8 addrspace(200)* %0)
  %2 = inttoptr i64 %1 to i32*
  ret i32* %2
; CHECK:        add     c0, c0, #8
; CHECK-NEXT:   gcvalue   x0, c0
; CHECK-NEXT:   ret
}

; CHECK-LABEL: testCapToPtr3:
define i32* @testCapToPtr3(i32 addrspace(200)* %tab) {
entry:
  %idx = getelementptr inbounds i32, i32 addrspace(200)* %tab, i64 2
  %0 = bitcast i32 addrspace(200)* %idx to i8 addrspace(200)*
  %1 = tail call i64 @llvm.cheri.cap.to.pointer(i8 addrspace(200)* null, i8 addrspace(200)* %0)
  %2 = inttoptr i64 %1 to i32*
  ret i32* %2
; CHECK:        add     c0, c0, #8
; CHECK:        mov     x1, #0
; CHECK-NEXT:   cvt     x0, c0, c1
; CHECK-NEXT:   ret
}

; CHECK-LABEL: testCapToPtr4:
define i32* @testCapToPtr4(i32 addrspace(200)* %t) {
entry:
  %0 = bitcast i32 addrspace(200)* %t to i8 addrspace(200)*
  %1 = tail call i64 @llvm.cheri.cap.to.pointer(i8 addrspace(200)* null, i8 addrspace(200)* %0)
  %2 = inttoptr i64 %1 to i32*
  ret i32* %2
; CHECK:        mov	x1, #0
; CHECK:        cvt     x0, c0, c1
; CHECK-NEXT:   ret
}

; CHECK-LABEL: testNullToCap:
define i32 addrspace(200)* @testNullToCap() {
entry:
  %0 = addrspacecast i32* null to i32 addrspace(200)*
  ret i32 addrspace(200)* %0
; CHECK:	mov     x0, #0
; CHECK-NEXT:	ret
}
