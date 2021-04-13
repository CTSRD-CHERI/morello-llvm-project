; RUN: opt -S -mtriple=arm64 -mattr=+c64 -target-abi purecap -instcombine < %s | FileCheck %s

target datalayout = "e-m:e-pf200:128:128-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"

define i1 @test1(i16 addrspace(200) * %x) {
  %load = load i16, i16 addrspace(200) * %x, align 4
  %trunc = trunc i16 %load to i8
  %cmp1 = icmp eq i8 %trunc, 127
  %and = and i16 %load, -256
  %cmp2 = icmp eq i16 %and, 17664
  %or = and i1 %cmp1, %cmp2
  ret i1 %or
; CHECK-LABEL: @test1(
; CHECK-NEXT: load i16
; CHECK-NEXT: icmp eq i16 %load, 17791
; CHECK-NEXT: ret i1
}

define i1 @test2(i16 addrspace(200) * %x) {
  %load = load i16, i16 addrspace(200) * %x, align 4
  %and = and i16 %load, -256
  %cmp1 = icmp eq i16 %and, 32512
  %trunc = trunc i16 %load to i8
  %cmp2 = icmp eq i8 %trunc, 69
  %or = and i1 %cmp1, %cmp2
  ret i1 %or
; CHECK-LABEL: @test2(
; CHECK-NEXT: load i16
; CHECK-NEXT: icmp eq i16 %load, 32581
; CHECK-NEXT: ret i1
}
