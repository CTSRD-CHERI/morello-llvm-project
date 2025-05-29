; RUN: llc < %s -mtriple=arm64-linux-gnu -mattr=+morello | FileCheck %s

define ptr addrspace(200) @test_load_acquire_fatptr(i32, ptr %addr) {
; CHECK-LABEL: test_load_acquire_fatptr:
; CHECK: ldaxr c0, [x1]

  %val = call ptr addrspace(200) @llvm.aarch64.cldaxr.p0(ptr elementtype(ptr addrspace(200)) %addr)
  ret ptr addrspace(200) %val
}

define ptr addrspace(200) @test_load_fatptr(i32, ptr %addr) {
; CHECK-LABEL: test_load_fatptr:
; CHECK: ldxr c0, [x1]
  %val = call ptr addrspace(200) @llvm.aarch64.cldxr.p0(ptr elementtype(ptr addrspace(200)) %addr)
  ret ptr addrspace(200) %val
}

define i32 @test_store_release_fatptr(i32, ptr addrspace(200) %val, ptr %addr) {
; CHECK-LABEL: test_store_release_fatptr:
; CHECK: stlxr w0, c1, [x2]
  %res = call i32 @llvm.aarch64.cstlxr.p0(ptr addrspace(200) %val, ptr elementtype(ptr addrspace(200)) %addr)
  ret i32 %res
}

define i32 @test_store_fatptr(i32, ptr addrspace(200) %val, ptr %addr) {
; CHECK-LABEL: test_store_fatptr:
; CHECK: stxr w0, c1, [x2]
  %res = call i32 @llvm.aarch64.cstxr.p0(ptr addrspace(200) %val, ptr elementtype(ptr addrspace(200)) %addr)
  ret i32 %res
}

declare i32 @llvm.aarch64.cstlxr.p0(ptr addrspace(200), ptr) nounwind
declare i32 @llvm.aarch64.cstxr.p0(ptr addrspace(200), ptr) nounwind
declare ptr addrspace(200) @llvm.aarch64.cldaxr.p0(ptr) nounwind
declare ptr addrspace(200) @llvm.aarch64.cldxr.p0(ptr) nounwind
