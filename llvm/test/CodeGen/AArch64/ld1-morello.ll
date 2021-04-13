; RUN: llc -mtriple=arm64 < %s -mattr=+c64,+morello -target-abi purecap -o - | FileCheck %s

; We don't yet have the NEON load/store instructions implemented in C64,
; so for now make sure we don't emit them.

; CHECK-LABEL: test_ld1
; CHECK: dup
; CHECK: dup

define void @test_ld1(i32* %ptr0, i32* %ptr1, i32* %ptr2, i32* %ptr3, <2 x i32>* %out) {
  %load0 = load i32, i32* %ptr0, align 4
  %load1 = load i32, i32* %ptr1, align 4
  %vec0_0 = insertelement <2 x i32> undef, i32 %load0, i32 0
  %vec0_1 = insertelement <2 x i32> %vec0_0, i32 %load0, i32 1

  %vec1_0 = insertelement <2 x i32> undef, i32 %load1, i32 0
  %vec1_1 = insertelement <2 x i32> %vec1_0, i32 %load1, i32 1

  %sub = sub nsw <2 x i32> %vec0_1, %vec1_1
  store <2 x i32> %sub, <2 x i32>* %out, align 16
  ret void
}
