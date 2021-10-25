; RUN: llc -march=arm64 -mattr=+c64,+morello -target-abi purecap -o - %s | FileCheck %s

target datalayout = "e-m:e-pf200:128:128-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none--elf"

; CHECK-LABEL: fun0
define void @fun0(i32 %n) addrspace(200) {
entry:
; Sink one scbnds in the exit block. Don't sink scbndse instructions in loops.
; CHECK: scbnds
; CHECK-LABEL: .LBB0_2
; CHECK-NOT: scbnds
; CHECK: bl bar
; CHECK: b.ne
; CHECK-LABEL: .LBB0_3
; CHECK: scbnds
  %a = alloca [300 x i32], align 4, addrspace(200)
  %b = alloca [200 x i32], align 4, addrspace(200)
  %0 = bitcast [300 x i32] addrspace(200)* %a to i8 addrspace(200)*
  call void @llvm.lifetime.start.p200i8(i64 1200, i8 addrspace(200)* nonnull %0)
  %1 = bitcast [200 x i32] addrspace(200)* %b to i8 addrspace(200)*
  call void @llvm.lifetime.start.p200i8(i64 800, i8 addrspace(200)* nonnull %1)
  %cmp4 = icmp sgt i32 %n, 0
  br i1 %cmp4, label %for.body.lr.ph, label %for.cond.cleanup

for.body.lr.ph:
  %arraydecay = getelementptr inbounds [200 x i32], [200 x i32] addrspace(200)* %b, i64 0, i64 0
  br label %for.body

for.cond.cleanup:
  %arraydecay1 = getelementptr inbounds [300 x i32], [300 x i32] addrspace(200)* %a, i64 0, i64 0
  call void @foo(i32 addrspace(200)* nonnull %arraydecay1)
  call void @llvm.lifetime.end.p200i8(i64 800, i8 addrspace(200)* nonnull %1)
  call void @llvm.lifetime.end.p200i8(i64 1200, i8 addrspace(200)* nonnull %0)
  ret void

for.body:
  %i.05 = phi i32 [ 0, %for.body.lr.ph ], [ %inc, %for.body ]
  call void @bar(i32 addrspace(200)* nonnull %arraydecay)
  %inc = add nuw nsw i32 %i.05, 1
  %exitcond = icmp eq i32 %inc, %n
  br i1 %exitcond, label %for.cond.cleanup, label %for.body
}

declare void @llvm.lifetime.start.p200i8(i64, i8 addrspace(200)* nocapture) addrspace(200)

declare void @bar(i32 addrspace(200)*) addrspace(200)

declare void @llvm.lifetime.end.p200i8(i64, i8 addrspace(200)* nocapture) addrspace(200)

declare void @foo(i32 addrspace(200)*) addrspace(200)

; CHECK-LABEL: fun1
; CHECK: scbnds
; CHECK: bl bar
; CHECK: scbnds
; CHECK: bl foo
define void @fun1(i32 %n) addrspace(200) {
entry:
  %a = alloca [300 x i32], align 4, addrspace(200)
  %b = alloca [200 x i32], align 4, addrspace(200)
  %0 = bitcast [300 x i32] addrspace(200)* %a to i8 addrspace(200)*
  call void @llvm.lifetime.start.p200i8(i64 1200, i8 addrspace(200)* nonnull %0)
  %1 = bitcast [200 x i32] addrspace(200)* %b to i8 addrspace(200)*
  call void @llvm.lifetime.start.p200i8(i64 800, i8 addrspace(200)* nonnull %1)
  %arraydecay = getelementptr inbounds [200 x i32], [200 x i32] addrspace(200)* %b, i64 0, i64 0
  call void @bar(i32 addrspace(200)* nonnull %arraydecay)
  %arraydecay1 = getelementptr inbounds [300 x i32], [300 x i32] addrspace(200)* %a, i64 0, i64 0
  call void @foo(i32 addrspace(200)* nonnull %arraydecay1)
  call void @llvm.lifetime.end.p200i8(i64 800, i8 addrspace(200)* nonnull %1)
  call void @llvm.lifetime.end.p200i8(i64 1200, i8 addrspace(200)* nonnull %0)
  ret void
}

; CHECK-LABEL: fun2
; CHECK-LABEL: .LBB2_2
; CHECK: scbnds
; CHECK: bl bar
; CHECK-LABEL: .LBB2_3
; CHECK: scbnds
; CHECK: bl foo
define void @fun2(i32 %n) addrspace(200) {
entry:
  %a = alloca [300 x i32], align 4, addrspace(200)
  %b = alloca [200 x i32], align 4, addrspace(200)
  %c = alloca [400 x i32], align 4, addrspace(200)
  %0 = bitcast [300 x i32] addrspace(200)* %a to i8 addrspace(200)*
  call void @llvm.lifetime.start.p200i8(i64 1200, i8 addrspace(200)* nonnull %0)
  %1 = bitcast [200 x i32] addrspace(200)* %b to i8 addrspace(200)*
  call void @llvm.lifetime.start.p200i8(i64 800, i8 addrspace(200)* nonnull %1)
  %2 = bitcast [400 x i32] addrspace(200)* %c to i8 addrspace(200)*
  call void @llvm.lifetime.start.p200i8(i64 1600, i8 addrspace(200)* nonnull %2)
  %cmp = icmp sgt i32 %n, 3
  br i1 %cmp, label %if.then, label %if.else

if.then:
  %arraydecay = getelementptr inbounds [200 x i32], [200 x i32] addrspace(200)* %b, i64 0, i64 0
  call void @bar(i32 addrspace(200)* nonnull %arraydecay)
  br label %if.end

if.else:
  %arraydecay1 = getelementptr inbounds [300 x i32], [300 x i32] addrspace(200)* %a, i64 0, i64 0
  call void @foo(i32 addrspace(200)* nonnull %arraydecay1)
  br label %if.end

if.end:
  %arraydecay2 = getelementptr inbounds [400 x i32], [400 x i32] addrspace(200)* %c, i64 0, i64 0
  call void @foo(i32 addrspace(200)* nonnull %arraydecay2)
  call void @llvm.lifetime.end.p200i8(i64 1600, i8 addrspace(200)* nonnull %2)
  call void @llvm.lifetime.end.p200i8(i64 800, i8 addrspace(200)* nonnull %1)
  call void @llvm.lifetime.end.p200i8(i64 1200, i8 addrspace(200)* nonnull %0)
  ret void
}

; CHECK-LABEL: test4
; CHECK: scbnds
; CHECK-LABEL: LBB3_2
; CHECK: tbnz w1, #0, .LBB3_2
define void @test4(i1 %in, i1 %in2) addrspace(200) {
entry:
  %0 = alloca i8, i64 undef, align 16, addrspace(200)
  %1 = bitcast i8 addrspace(200)* %0 to float addrspace(200)* addrspace(200)*
  br i1 %in, label %cleanup, label %for.body26.us

for.body26.us:
  %indvars.iv = phi i64 [ %indvars.iv.next, %for.body26.us ], [ 0, %entry ]
  %arrayidx28.us = getelementptr inbounds float addrspace(200)*, float addrspace(200)* addrspace(200)* %1, i64 %indvars.iv
  %2 = load float addrspace(200)*, float addrspace(200)* addrspace(200)* %arrayidx28.us, align 16
  %indvars.iv.next = add nuw nsw i64 %indvars.iv, 1
  br i1 %in2, label %for.body26.us, label %cleanup

cleanup:
  ret void
}
