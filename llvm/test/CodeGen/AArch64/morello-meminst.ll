; RUN: llc -mtriple=arm64 -mattr=+morello -o - %s | FileCheck %s --check-prefix=ALL --check-prefix=CFUN
; RUN: llc -mtriple=arm64 -mattr=+morello -cheri-no-cap-libfunc -o - %s | FileCheck %s --check-prefix=ALL --check-prefix=NOCFUN
; RUN: llc -mtriple=arm64 -mattr=+morello -cheri-no-pure-cap-libfunc -o - %s | FileCheck %s --check-prefix=ALL --check-prefix=CFUN

target triple = "aarch64-none--elf"

declare void @llvm.memset.p200i8.i64(i8 addrspace(200)* nocapture, i8, i64,  i1)
declare void @llvm.memcpy.p200i8.p200i8.i64(i8 addrspace(200)* nocapture, i8 addrspace(200)* nocapture readonly, i64, i1)
declare void @llvm.memmove.p200i8.p200i8.i64(i8 addrspace(200)* nocapture, i8 addrspace(200)* nocapture readonly, i64, i1)

; ALL-LABEL: testMemset
define void @testMemset(i8 addrspace(200)* %p, i64 %n) {
entry:
  tail call void @llvm.memset.p200i8.i64(i8 addrspace(200)* %p, i8 0, i64 %n, i1 0)
  ret void
; CFUN: b	memset_c
; NOCFUN-NOT:   memset_c
; NOCFUN: b	memset
}

; ALL-LABEL: testMemcpy
define void @testMemcpy(i8 addrspace(200)* %d, i8 addrspace(200)* %s, i64 %n) {
entry:
  tail call void @llvm.memcpy.p200i8.p200i8.i64(i8 addrspace(200)* %d, i8 addrspace(200)* %s, i64 %n, i1 0)
  ret void
; CFUN: b	memcpy_c
; NOCFUN-NOT:   memcpy_c
; NOCFUN: b	memcpy
}

; ALL-LABEL: testMemmove
define void @testMemmove(i8 addrspace(200)* %d, i8 addrspace(200)* %s, i64 %n) {
entry:
  tail call void @llvm.memmove.p200i8.p200i8.i64(i8 addrspace(200)* %d, i8 addrspace(200)* %s, i64 %n, i1 0)
  ret void
; CFUN: b	memmove_c
; NOCFUN-NOT:	memmove_c
; NOCFUN: b	memmove
}

attributes #0 = { "must-preserve-cheri-tags" }
