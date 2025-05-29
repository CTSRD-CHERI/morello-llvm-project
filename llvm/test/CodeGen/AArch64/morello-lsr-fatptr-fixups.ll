; RUN: opt -S -loop-reduce -target-abi purecap -march=arm64 -mattr=+c64 -o -  %s | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none--elf"

; Don't choose integer-only formulas with fat pointer fixups (in this case {0,+,4}).

; CHECK-LABEL: foo
; CHECK-NOT: inttoptr
define void @foo() addrspace(200) {
entry:
  br label %for.cond42.preheader

for.cond42.preheader:
  br label %for.body45

for.body45:
  %indvars.iv = phi i64 [ 0, %for.cond42.preheader ], [ %indvars.iv.next, %for.body45 ]
  %arrayidx66 = getelementptr inbounds float, ptr addrspace(200) null, i64 %indvars.iv
  %0 = load float, ptr addrspace(200) %arrayidx66, align 4
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br i1 undef, label %for.end, label %for.body45

for.end:
  br label %for.cond42.preheader
}
