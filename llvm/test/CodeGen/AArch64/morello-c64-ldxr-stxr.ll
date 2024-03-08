; RUN: llc < %s -mtriple=arm64-linux-gnu -mattr=+c64,+morello -target-abi purecap | FileCheck %s

%0 = type { i64, i64 }

define i128 @f0(i8 addrspace(200)* %p) nounwind readonly {
; CHECK-LABEL: f0:
; CHECK: ldxp {{x[0-9]+}}, {{x[0-9]+}}, [c0]
entry:
  %ldrexd = tail call %0 @llvm.aarch64.ldxp.p200i8(i8 addrspace(200)* %p)
  %0 = extractvalue %0 %ldrexd, 1
  %1 = extractvalue %0 %ldrexd, 0
  %2 = zext i64 %0 to i128
  %3 = zext i64 %1 to i128
  %shl = shl nuw i128 %2, 64
  %4 = or i128 %shl, %3
  ret i128 %4
}

define i32 @f1(i8 addrspace(200)* %ptr, i128 %val) nounwind {
; CHECK-LABEL: f1:
; CHECK: stxp {{w[0-9]+}}, {{x[0-9]+}}, {{x[0-9]+}}, [c0]
entry:
  %tmp4 = trunc i128 %val to i64
  %tmp6 = lshr i128 %val, 64
  %tmp7 = trunc i128 %tmp6 to i64
  %strexd = tail call i32 @llvm.aarch64.stxp.p200i8(i64 %tmp4, i64 %tmp7, i8 addrspace(200)* %ptr)
  ret i32 %strexd
}

declare %0 @llvm.aarch64.ldxp.p200i8(i8 addrspace(200)*) nounwind
declare i32 @llvm.aarch64.stxp.p200i8(i64, i64, i8 addrspace(200)*) nounwind

@var = addrspace(200) global i64 0, align 8

define void @test_load_i8(i8 addrspace(200)* %addr) {
; CHECK-LABEL: test_load_i8:
; CHECK: ldr c[[ADDR:[0-9]+]], [c[[ADDR]], :got_lo12:var]
; CHECK: ldxrb w[[LOADVAL:[0-9]+]], [c0]
; CHECK-NOT: uxtb
; CHECK-NOT: and
; CHECK: str x[[LOADVAL]], [c[[ADDR]]]

  %val = call i64 @llvm.aarch64.ldxr.p200i8(i8 addrspace(200)* elementtype(i8) %addr)
  %shortval = trunc i64 %val to i8
  %extval = zext i8 %shortval to i64
  store i64 %extval, i64 addrspace(200)* @var, align 8
  ret void
}

define void @test_load_i16(i16 addrspace(200)* %addr) {
; CHECK-LABEL: test_load_i16:
; CHECK: ldr c[[ADDR:[0-9]+]], [c[[ADDR]], :got_lo12:var]
; CHECK: ldxrh w[[LOADVAL:[0-9]+]], [c0]
; CHECK-NOT: uxth
; CHECK-NOT: and
; CHECK: str x[[LOADVAL]], [c[[ADDR]]]

  %val = call i64 @llvm.aarch64.ldxr.p200i16(i16 addrspace(200)* elementtype(i16) %addr)
  %shortval = trunc i64 %val to i16
  %extval = zext i16 %shortval to i64
  store i64 %extval, i64 addrspace(200)* @var, align 8
  ret void
}

define void @test_load_i32(i32 addrspace(200)* %addr) {
; CHECK-LABEL: test_load_i32:
; CHECK: ldr c[[ADDR:[0-9]+]], [c[[ADDR]], :got_lo12:var]
; CHECK: ldxr w[[LOADVAL:[0-9]+]], [c0]
; CHECK-NOT: uxtw
; CHECK-NOT: and
; CHECK: str x[[LOADVAL]], [c[[ADDR]]]

  %val = call i64 @llvm.aarch64.ldxr.p200i32(i32 addrspace(200)* elementtype(i32) %addr)
  %shortval = trunc i64 %val to i32
  %extval = zext i32 %shortval to i64
  store i64 %extval, i64 addrspace(200)* @var, align 8
  ret void
}

define void @test_load_i64(i64 addrspace(200)* %addr) {
; CHECK-LABEL: test_load_i64:
; CHECK: ldr c[[ADDR:[0-9]+]], [c[[ADDR]], :got_lo12:var]
; CHECK: ldxr x[[LOADVAL:[0-9]+]], [c0]
; CHECK: str x[[LOADVAL]], [c[[ADDR]]]

  %val = call i64 @llvm.aarch64.ldxr.p200i64(i64 addrspace(200)* elementtype(i64) %addr)
  store i64 %val, i64 addrspace(200)* @var, align 8
  ret void
}


declare i64 @llvm.aarch64.ldxr.p200i8(i8 addrspace(200)*) nounwind
declare i64 @llvm.aarch64.ldxr.p200i16(i16 addrspace(200)*) nounwind
declare i64 @llvm.aarch64.ldxr.p200i32(i32 addrspace(200)*) nounwind
declare i64 @llvm.aarch64.ldxr.p200i64(i64 addrspace(200)*) nounwind

define i32 @test_store_i8(i32, i8 %val, i8 addrspace(200)* %addr) {
; CHECK-LABEL: test_store_i8:
; CHECK-NOT: uxtb
; CHECK-NOT: and
; CHECK: stxrb w0, w1, [c2]
  %extval = zext i8 %val to i64
  %res = call i32 @llvm.aarch64.stxr.p200i8(i64 %extval, i8 addrspace(200)* elementtype(i8) %addr)
  ret i32 %res
}

define i32 @test_store_i16(i32, i16 %val, i16 addrspace(200)* %addr) {
; CHECK-LABEL: test_store_i16:
; CHECK-NOT: uxth
; CHECK-NOT: and
; CHECK: stxrh w0, w1, [c2]
  %extval = zext i16 %val to i64
  %res = call i32 @llvm.aarch64.stxr.p200i16(i64 %extval, i16 addrspace(200)* elementtype(i16) %addr)
  ret i32 %res
}

define i32 @test_store_i32(i32, i32 %val, i32 addrspace(200)* %addr) {
; CHECK-LABEL: test_store_i32:
; CHECK-NOT: uxtw
; CHECK-NOT: and
; CHECK: stxr w0, w1, [c2]
  %extval = zext i32 %val to i64
  %res = call i32 @llvm.aarch64.stxr.p200i32(i64 %extval, i32 addrspace(200)* elementtype(i32) %addr)
  ret i32 %res
}

define i32 @test_store_i64(i32, i64 %val, i64 addrspace(200)* %addr) {
; CHECK-LABEL: test_store_i64:
; CHECK: stxr w0, x1, [c2]
  %res = call i32 @llvm.aarch64.stxr.p200i64(i64 %val, i64 addrspace(200)* elementtype(i64) %addr)
  ret i32 %res
}

declare i32 @llvm.aarch64.stxr.p200i8(i64, i8 addrspace(200)*) nounwind
declare i32 @llvm.aarch64.stxr.p200i16(i64, i16 addrspace(200)*) nounwind
declare i32 @llvm.aarch64.stxr.p200i32(i64, i32 addrspace(200)*) nounwind
declare i32 @llvm.aarch64.stxr.p200i64(i64, i64 addrspace(200)*) nounwind

; CHECK: test_clear:
; CHECK: clrex
define void @test_clear() {
  call void @llvm.aarch64.clrex()
  ret void
}

declare void @llvm.aarch64.clrex() nounwind

define i128 @test_load_acquire_i128(i8 addrspace(200)* %p) nounwind readonly {
; CHECK-LABEL: test_load_acquire_i128:
; CHECK: ldaxp {{x[0-9]+}}, {{x[0-9]+}}, [c0]
entry:
  %ldrexd = tail call %0 @llvm.aarch64.ldaxp.p200i8(i8 addrspace(200)* %p)
  %0 = extractvalue %0 %ldrexd, 1
  %1 = extractvalue %0 %ldrexd, 0
  %2 = zext i64 %0 to i128
  %3 = zext i64 %1 to i128
  %shl = shl nuw i128 %2, 64
  %4 = or i128 %shl, %3
  ret i128 %4
}

define i32 @test_store_release_i128(i8 addrspace(200)* %ptr, i128 %val) nounwind {
; CHECK-LABEL: test_store_release_i128:
; CHECK: stlxp {{w[0-9]+}}, {{x[0-9]+}}, {{x[0-9]+}}, [c0]
entry:
  %tmp4 = trunc i128 %val to i64
  %tmp6 = lshr i128 %val, 64
  %tmp7 = trunc i128 %tmp6 to i64
  %strexd = tail call i32 @llvm.aarch64.stlxp.p200i8(i64 %tmp4, i64 %tmp7, i8 addrspace(200)* %ptr)
  ret i32 %strexd
}

declare %0 @llvm.aarch64.ldaxp.p200i8(i8 addrspace(200)*) nounwind
declare i32 @llvm.aarch64.stlxp.p200i8(i64, i64, i8 addrspace(200)*) nounwind

define void @test_load_acquire_i8(i8 addrspace(200)* %addr) {
; CHECK-LABEL: test_load_acquire_i8:
; CHECK: ldr c[[ADDR:[0-9]+]], [c[[ADDR]], :got_lo12:var]
; CHECK: ldaxrb w[[LOADVAL:[0-9]+]], [c0]
; CHECK-NOT: uxtb
; CHECK-NOT: and
; CHECK: str x[[LOADVAL]], [c[[ADDR]]]

  %val = call i64 @llvm.aarch64.ldaxr.p200i8(i8 addrspace(200)* elementtype(i8) %addr)
  %shortval = trunc i64 %val to i8
  %extval = zext i8 %shortval to i64
  store i64 %extval, i64 addrspace(200)* @var, align 8
  ret void
}

define void @test_load_acquire_i16(i16 addrspace(200)* %addr) {
; CHECK-LABEL: test_load_acquire_i16:
; CHECK: ldr c[[ADDR:[0-9]+]], [c[[ADDR]], :got_lo12:var]
; CHECK: ldaxrh w[[LOADVAL:[0-9]+]], [c0]
; CHECK-NOT: uxth
; CHECK-NOT: and
; CHECK: str x[[LOADVAL]], [c[[ADDR]]]

  %val = call i64 @llvm.aarch64.ldaxr.p200i16(i16 addrspace(200)* elementtype(i16) %addr)
  %shortval = trunc i64 %val to i16
  %extval = zext i16 %shortval to i64
  store i64 %extval, i64 addrspace(200)* @var, align 8
  ret void
}

define void @test_load_acquire_i32(i32 addrspace(200)* %addr) {
; CHECK-LABEL: test_load_acquire_i32:
; CHECK: ldr c[[ADDR:[0-9]+]], [c[[ADDR]], :got_lo12:var]
; CHECK: ldaxr w[[LOADVAL:[0-9]+]], [c0]
; CHECK-NOT: uxtw
; CHECK-NOT: and
; CHECK: str x[[LOADVAL]], [c[[ADDR]]]

  %val = call i64 @llvm.aarch64.ldaxr.p200i32(i32 addrspace(200)* elementtype(i32) %addr)
  %shortval = trunc i64 %val to i32
  %extval = zext i32 %shortval to i64
  store i64 %extval, i64 addrspace(200)* @var, align 8
  ret void
}

define void @test_load_acquire_i64(i64 addrspace(200)* %addr) {
; CHECK-LABEL: test_load_acquire_i64:
; CHECK: ldr c[[ADDR:[0-9]+]], [c[[ADDR]], :got_lo12:var]
; CHECK: ldaxr x[[LOADVAL:[0-9]+]], [c0]
; CHECK: str x[[LOADVAL]], [c[[ADDR]]]

  %val = call i64 @llvm.aarch64.ldaxr.p200i64(i64 addrspace(200)* elementtype(i64) %addr)
  store i64 %val, i64 addrspace(200)* @var, align 8
  ret void
}


declare i64 @llvm.aarch64.ldaxr.p200i8(i8 addrspace(200)*) nounwind
declare i64 @llvm.aarch64.ldaxr.p200i16(i16 addrspace(200)*) nounwind
declare i64 @llvm.aarch64.ldaxr.p200i32(i32 addrspace(200)*) nounwind
declare i64 @llvm.aarch64.ldaxr.p200i64(i64 addrspace(200)*) nounwind

define i32 @test_store_release_i8(i32, i8 %val, i8 addrspace(200)* %addr) {
; CHECK-LABEL: test_store_release_i8:
; CHECK-NOT: uxtb
; CHECK-NOT: and
; CHECK: stlxrb w0, w1, [c2]
  %extval = zext i8 %val to i64
  %res = call i32 @llvm.aarch64.stlxr.p200i8(i64 %extval, i8 addrspace(200)* elementtype(i8) %addr)
  ret i32 %res
}

define i32 @test_store_release_i16(i32, i16 %val, i16 addrspace(200)* %addr) {
; CHECK-LABEL: test_store_release_i16:
; CHECK-NOT: uxth
; CHECK-NOT: and
; CHECK: stlxrh w0, w1, [c2]
  %extval = zext i16 %val to i64
  %res = call i32 @llvm.aarch64.stlxr.p200i16(i64 %extval, i16 addrspace(200)* elementtype(i16) %addr)
  ret i32 %res
}

define i32 @test_store_release_i32(i32, i32 %val, i32 addrspace(200)* %addr) {
; CHECK-LABEL: test_store_release_i32:
; CHECK-NOT: uxtw
; CHECK-NOT: and
; CHECK: stlxr w0, w1, [c2]
  %extval = zext i32 %val to i64
  %res = call i32 @llvm.aarch64.stlxr.p200i32(i64 %extval, i32 addrspace(200)* elementtype(i32) %addr)
  ret i32 %res
}

; FALLBACK-NOT: remark:{{.*}}test_store_release_i64
define i32 @test_store_release_i64(i32, i64 %val, i64 addrspace(200)* %addr) {
; CHECK-LABEL: test_store_release_i64:
; CHECK: stlxr w0, x1, [c2]
  %res = call i32 @llvm.aarch64.stlxr.p200i64(i64 %val, i64 addrspace(200)* elementtype(i64) %addr)
  ret i32 %res
}

declare i32 @llvm.aarch64.stlxr.p200i8(i64, i8 addrspace(200)*) nounwind
declare i32 @llvm.aarch64.stlxr.p200i16(i64, i16 addrspace(200)*) nounwind
declare i32 @llvm.aarch64.stlxr.p200i32(i64, i32 addrspace(200)*) nounwind
declare i32 @llvm.aarch64.stlxr.p200i64(i64, i64 addrspace(200)*) nounwind

define i8 addrspace(200)* @test_load_acquire_fatptr(i32, i8 addrspace(200)* addrspace(200)* %addr) {
; CHECK-LABEL: test_load_acquire_fatptr:
; CHECK: ldaxr c0, [c1]

  %val = call i8 addrspace(200)* @llvm.aarch64.cldaxr.p200p200i8(i8 addrspace(200)* addrspace(200)* elementtype(i8 addrspace(200)*) %addr)
  ret i8 addrspace(200)* %val
}

define i8 addrspace(200)* @test_load_fatptr(i32, i8 addrspace(200)* addrspace(200)* %addr) {
; CHECK-LABEL: test_load_fatptr:
; CHECK: ldxr c0, [c1]

  %val = call i8 addrspace(200)* @llvm.aarch64.cldxr.p200p200i8(i8 addrspace(200)* addrspace(200)* elementtype(i8 addrspace(200)*) %addr)
  ret i8 addrspace(200)* %val
}

define i32 @test_store_release_fatptr(i32, i8 addrspace(200)* %val, i8 addrspace(200)* addrspace(200)* %addr) {
; CHECK-LABEL: test_store_release_fatptr:
; CHECK: stlxr w0, c1, [c2]
  %res = call i32 @llvm.aarch64.cstlxr.p200p200i8(i8 addrspace(200)* %val, i8 addrspace(200)* addrspace(200)* elementtype(i8 addrspace(200)*) %addr)
  ret i32 %res
}

define i32 @test_store_fatptr(i32, i8 addrspace(200)* %val, i8 addrspace(200)* addrspace(200)* %addr) {
; CHECK-LABEL: test_store_fatptr:
; CHECK: stxr w0, c1, [c2]
  %res = call i32 @llvm.aarch64.cstxr.p200p200i8(i8 addrspace(200)* %val, i8 addrspace(200)* addrspace(200)* elementtype(i8 addrspace(200)*) %addr)
  ret i32 %res
}

declare i32 @llvm.aarch64.cstlxr.p200p200i8(i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)*) nounwind
declare i32 @llvm.aarch64.cstxr.p200p200i8(i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)*) nounwind
declare i8 addrspace(200)* @llvm.aarch64.cldaxr.p200p200i8(i8 addrspace(200)* addrspace(200)*) nounwind
declare i8 addrspace(200)* @llvm.aarch64.cldxr.p200p200i8(i8 addrspace(200)* addrspace(200)*) nounwind
