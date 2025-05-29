; RUN: opt < %s "-passes=print<scalar-evolution>" -disable-output 2>&1 | FileCheck %s -check-prefix=FATPTR_ENABLED
; RUN: opt < %s "-passes=print<scalar-evolution>" -scalar-evolution-fatpointer-scev-disable=true -disable-output 2>&1 | FileCheck %s -check-prefix=FATPTR_DISABLED

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200"
target triple = "arm64"

; Function Attrs: norecurse nounwind
define void @foo(ptr addrspace(200) nocapture %a, i32 %n, i32 %k) local_unnamed_addr {
; CHECK-LABLE: @foo
entry:
  %cmp5 = icmp sgt i32 %n, 0
  br i1 %cmp5, label %for.body.preheader, label %for.cond.cleanup

for.body.preheader:                               ; preds = %entry
  %0 = sext i32 %k to i64
  %wide.trip.count = zext i32 %n to i64
  br label %for.body

for.cond.cleanup:                                 ; preds = %for.body, %entry
  ret void

for.body:                                         ; preds = %for.body, %for.body.preheader
  %indvars.iv = phi i64 [ 0, %for.body.preheader ], [ %indvars.iv.next, %for.body ]
  %1 = mul nsw i64 %indvars.iv, %0
  %arrayidx = getelementptr inbounds i32, ptr addrspace(200) %a, i64 %indvars.iv
; FATPTR_ENABLED: %arrayidx = getelementptr 
; FATPTR_ENABLED-NEXT: -->  {%a,+,4}<nuw><%for.body>
; FATPTR_DISABLED: %arrayidx = getelementptr 
; FATPTR_DISABLED-NEXT: -->  %arrayidx U:
  %2 = trunc i64 %1 to i32
  store i32 %2, ptr addrspace(200) %arrayidx, align 4
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  %exitcond = icmp eq i64 %indvars.iv.next, %wide.trip.count
  br i1 %exitcond, label %for.cond.cleanup, label %for.body
}
