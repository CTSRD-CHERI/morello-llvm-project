; RUN: llc -mtriple=arm64 -mattr=+morello -o - %s | FileCheck %s

; CHECK-LABEL @test
define i8 addrspace(200)* @test(i8 addrspace(200)* nocapture readnone %foo, i8 addrspace(200)* readnone %bar, i64 %baz) {
entry:
; CHECK:      seal	[[CN:c[0-9]+]], c0, c1
; CHECK-NEXT: mvn       [[NEG:x[0-9+]]], x2
; CHECK-NEXT: clrperm	c0, [[CN]], [[NEG]]
; CHECK-NEXT: ret
  %CN = call i8 addrspace(200)* @llvm.cheri.cap.seal(i8 addrspace(200)* %foo, i8 addrspace(200)* %bar)
  %CR = call i8 addrspace(200)* @llvm.cheri.cap.perms.and(i8 addrspace(200)* %CN, i64 %baz)
  ret i8 addrspace(200)* %CR
}

declare i8 addrspace(200)* @llvm.cheri.cap.perms.and(i8 addrspace(200)*, i64)
declare i8 addrspace(200)* @llvm.cheri.cap.seal(i8 addrspace(200)*, i8 addrspace(200)*)
