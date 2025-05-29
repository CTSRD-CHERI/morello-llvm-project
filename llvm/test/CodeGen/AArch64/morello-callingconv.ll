; RUN: llc -mtriple=arm64 -mattr=+morello -o - %s | FileCheck %s

; CHECK-LABEL @test
define ptr addrspace(200) @test(ptr addrspace(200) nocapture readnone %foo, ptr addrspace(200) readnone %bar, i64 %baz) {
entry:
; CHECK:      mvn       [[NEG:x[0-9+]]], x2
; CHECK-NEXT: seal	[[CN:c[0-9]+]], c0, c1
; CHECK-NEXT: clrperm	c0, [[CN]], [[NEG]]
; CHECK-NEXT: ret
  %CN = call ptr addrspace(200) @llvm.cheri.cap.seal(ptr addrspace(200) %foo, ptr addrspace(200) %bar)
  %CR = call ptr addrspace(200) @llvm.cheri.cap.perms.and(ptr addrspace(200) %CN, i64 %baz)
  ret ptr addrspace(200) %CR
}

declare ptr addrspace(200) @llvm.cheri.cap.perms.and(ptr addrspace(200), i64)
declare ptr addrspace(200) @llvm.cheri.cap.seal(ptr addrspace(200), ptr addrspace(200))
