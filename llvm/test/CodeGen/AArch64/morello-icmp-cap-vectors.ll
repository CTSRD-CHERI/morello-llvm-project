; RUN: opt -mtriple=arm64 -mattr=+morello,+c64 -target-abi purecap -instcombine -S -o - %s | FileCheck %s

; Don't crash while trying to simplify icmps with vectors of capabilities as operands.

target datalayout = "e-m:e-i64:64-i128:128-n32:64-S128-pf200:128:128-A200-P200-G200"

; CHECK-LABEL: foo
define <2 x i32> @foo(i8 addrspace(200)* addrspace(200)* %con0,
                i8 addrspace(200)* addrspace(200)* %con1 ) addrspace(200) {
  %in0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %con0, align 16
  %in1 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %con1, align 16
  %vec0 = insertelement <2 x i8 addrspace(200)*> undef, i8 addrspace(200)* %in0, i32 0
  %vec1 = insertelement <2 x i8 addrspace(200)*> %vec0, i8 addrspace(200)* %in1, i32 1
; CHECK: icmp ne <2 x i8 addrspace(200)*> %vec1, zeroinitializer
  %cmp = icmp ne <2 x i8 addrspace(200)*> %vec1, zeroinitializer
  %ret = zext <2 x i1> %cmp to <2 x i32>
  ret <2 x i32> %ret
}
