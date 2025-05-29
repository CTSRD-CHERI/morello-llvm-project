; RUN: llc < %s -mtriple=arm64-eabi -asm-verbose=false -verify-machineinstrs -mattr=+c64,+morello -target-abi purecap | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"

@gv = common local_unnamed_addr addrspace(200) global [8 x [64 x i32]] zeroinitializer, align 4

; CHECK-LABEL: fun
define i32 @fun(i32 %x, i32 %u, i32 %v) addrspace(200) {
entry:
; CHECK: ldr w{{.*}}, [c{{.*}}, w{{.*}}, uxtw #2]
; CHECK: ldr w{{.*}}, [c{{.*}}, w{{.*}}, uxtw #2]
  %shr = lshr i32 %u, 10
  %and = and i32 %shr, 63
  %idxprom = zext i32 %and to i64
  %arrayidx = getelementptr inbounds [8 x [64 x i32]], ptr addrspace(200) @gv, i64 0, i64 2, i64 %idxprom
  %0 = load i32, ptr addrspace(200) %arrayidx, align 4
  %xor = xor i32 %0, %x
  %shr1 = lshr i32 %v, 10
  %and2 = and i32 %shr1, 63
  %idxprom3 = zext i32 %and2 to i64
  %arrayidx4 = getelementptr inbounds [8 x [64 x i32]], ptr addrspace(200) @gv, i64 0, i64 2, i64 %idxprom3
  %1 = load i32, ptr addrspace(200) %arrayidx4, align 4
  %xor5 = xor i32 %xor, %1
  ret i32 %xor5
}
