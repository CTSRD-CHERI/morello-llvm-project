; RUN: llc < %s -mtriple=arm64-linux-gnu -mattr=+morello | FileCheck %s

define i8 addrspace(200)* @test_load_acquire_fatptr(i32, i8* %addr) {
; CHECK-LABEL: test_load_acquire_fatptr:
; CHECK: ldaxr c0, [x1]

  %tmp = bitcast i8* %addr to i8 addrspace(200)**
  %val = call i8 addrspace(200)* @llvm.aarch64.cldaxr.p0p200i8(i8 addrspace(200)** elementtype(i8 addrspace(200)*) %tmp)
  ret i8 addrspace(200)* %val
}

define i8 addrspace(200)* @test_load_fatptr(i32, i8* %addr) {
; CHECK-LABEL: test_load_fatptr:
; CHECK: ldxr c0, [x1]
  %tmp = bitcast i8* %addr to i8 addrspace(200)**
  %val = call i8 addrspace(200)* @llvm.aarch64.cldxr.p0p200i8(i8 addrspace(200)** elementtype(i8 addrspace(200)*) %tmp)
  ret i8 addrspace(200)* %val
}

define i32 @test_store_release_fatptr(i32, i8 addrspace(200)* %val, i8* %addr) {
; CHECK-LABEL: test_store_release_fatptr:
; CHECK: stlxr w0, c1, [x2]
  %tmp = bitcast i8* %addr to i8 addrspace(200)**
  %res = call i32 @llvm.aarch64.cstlxr.p0p200i8(i8 addrspace(200)* %val, i8 addrspace(200)** elementtype(i8 addrspace(200)*) %tmp)
  ret i32 %res
}

define i32 @test_store_fatptr(i32, i8 addrspace(200)* %val, i8* %addr) {
; CHECK-LABEL: test_store_fatptr:
; CHECK: stxr w0, c1, [x2]
  %tmp = bitcast i8* %addr to i8 addrspace(200)**
  %res = call i32 @llvm.aarch64.cstxr.p0p200i8(i8 addrspace(200)* %val, i8 addrspace(200)** elementtype(i8 addrspace(200)*) %tmp)
  ret i32 %res
}

declare i32 @llvm.aarch64.cstlxr.p0p200i8(i8 addrspace(200)*, i8 addrspace(200)**) nounwind
declare i32 @llvm.aarch64.cstxr.p0p200i8(i8 addrspace(200)*, i8 addrspace(200)**) nounwind
declare i8 addrspace(200)* @llvm.aarch64.cldaxr.p0p200i8(i8 addrspace(200)**) nounwind
declare i8 addrspace(200)* @llvm.aarch64.cldxr.p0p200i8(i8 addrspace(200)**) nounwind
