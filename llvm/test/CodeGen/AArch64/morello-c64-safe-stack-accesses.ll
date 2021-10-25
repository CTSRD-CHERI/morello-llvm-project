; RUN: llc -march=arm64 -mattr=+c64,+morello -target-abi purecap -o - %s | FileCheck %s

target datalayout = "e-m:e-pf200:128:128-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none--elf"

; CHECK-LABEL: fun1
define void @fun1(i32 %n) addrspace(200) {
entry:
; CHECK: sub csp, csp, #1200
; CHECK: add c[[TMPADDRA:[0-9]+]], csp, #800
; CHECK: scbnds c[[ADDRA:[0-9]+]], c[[TMPADDRA:[0-9]+]], #25, lsl #4
  %a = alloca [100 x i32], align 4, addrspace(200)
  %b = alloca [200 x i32], align 4, addrspace(200)
  %0 = bitcast [100 x i32] addrspace(200)* %a to i8 addrspace(200)*
  call void @llvm.lifetime.start.p200i8(i64 400, i8 addrspace(200)* nonnull %0)
  %1 = bitcast [200 x i32] addrspace(200)* %b to i8 addrspace(200)*
  call void @llvm.lifetime.start.p200i8(i64 800, i8 addrspace(200)* nonnull %1)
  %cmp = icmp sgt i32 %n, 3
  br i1 %cmp, label %for.cond.preheader.thread, label %for.cond.preheader

for.cond.preheader.thread:
  %arraydecay = getelementptr inbounds [100 x i32], [100 x i32] addrspace(200)* %a, i64 0, i64 0
  call void @foo(i32 addrspace(200)* nonnull %arraydecay)
  br label %for.body.lr.ph

for.cond.preheader:
  %cmp112 = icmp sgt i32 %n, 0
  br i1 %cmp112, label %for.body.lr.ph, label %for.cond.cleanup

for.body.lr.ph:
  %arraydecay2 = getelementptr inbounds [100 x i32], [100 x i32] addrspace(200)* %a, i64 0, i64 0
  %arrayidx = getelementptr inbounds [100 x i32], [100 x i32] addrspace(200)* %a, i64 0, i64 99
  %arrayidx3 = getelementptr inbounds [200 x i32], [200 x i32] addrspace(200)* %b, i64 0, i64 2
  br label %for.body

; CHECK: ldr w[[VAL1:[0-9]+]], [csp, #1196]
; CHECK: ldr w[[VAL2:[0-9]+]], [csp, #8]
; CHECK: add w[[VAL1INC:[0-9]+]], w[[VAL1]], #1
; CHECK: add w[[VAL2INC:[0-9]+]], w[[VAL2]], #1
; CHECK: str w[[VAL1INC]], [csp, #1196]
; CHECK: str w[[VAL2INC]], [csp, #8]
for.body:
  %i.013 = phi i32 [ 0, %for.body.lr.ph ], [ %inc5, %for.body ]
  call void @foo(i32 addrspace(200)* nonnull %arraydecay2)
  %2 = load i32, i32 addrspace(200)* %arrayidx, align 4
  %inc = add nsw i32 %2, 1
  store i32 %inc, i32 addrspace(200)* %arrayidx, align 4
  %3 = load i32, i32 addrspace(200)* %arrayidx3, align 4
  %inc4 = add nsw i32 %3, 1
  store i32 %inc4, i32 addrspace(200)* %arrayidx3, align 4
  %inc5 = add nuw nsw i32 %i.013, 1
  %exitcond = icmp eq i32 %inc5, %n
  br i1 %exitcond, label %for.cond.cleanup, label %for.body

for.cond.cleanup:
; CHECK: mov c[[TMPADDR:[0-9]+]], csp
; CHECK: scbnds c[[ADDRB:[0-9]+]], c[[TMPADDR]], #50, lsl #4
  %add.ptr = getelementptr inbounds [100 x i32], [100 x i32] addrspace(200)* %a, i64 0, i64 2
  call void @foo(i32 addrspace(200)* %add.ptr)
  %add.ptr8 = getelementptr inbounds [200 x i32], [200 x i32] addrspace(200)* %b, i64 0, i64 1
  call void @bar(i32 addrspace(200)* %add.ptr8)
  call void @llvm.lifetime.end.p200i8(i64 800, i8 addrspace(200)* nonnull %1)
  call void @llvm.lifetime.end.p200i8(i64 400, i8 addrspace(200)* nonnull %0)
  ret void

}

; CHECK-LABEL: fun2
define i32 @fun2() addrspace(200) {
entry:
; CHECK: mov w[[SIZE:[0-9]+]], #6784
; CHECK: movk w[[SIZE]], #6, lsl #16
; CHECK: mov c[[TMPADDR:[0-9]+]], csp
; CHECK: scbnds c[[ADDR:[0-9]+]], c[[TMPADDR]], x[[SIZE]]
; CHECK: ldr w0, [csp, #8]
  %a = alloca [100000 x i32], align 4, addrspace(200)
  %0 = bitcast [100000 x i32] addrspace(200)* %a to i8 addrspace(200)*
  call void @llvm.lifetime.start.p200i8(i64 400000, i8 addrspace(200)* nonnull %0)
  %arraydecay = getelementptr inbounds [100000 x i32], [100000 x i32] addrspace(200)* %a, i64 0, i64 0
  call void @foo(i32 addrspace(200)* nonnull %arraydecay)
  %arrayidx = getelementptr inbounds [100000 x i32], [100000 x i32] addrspace(200)* %a, i64 0, i64 2
  %1 = load i32, i32 addrspace(200)* %arrayidx, align 4
  call void @llvm.lifetime.end.p200i8(i64 400000, i8 addrspace(200)* nonnull %0)
  ret i32 %1
}

declare void @llvm.lifetime.start.p200i8(i64, i8 addrspace(200)* nocapture) addrspace(200)
declare void @foo(i32 addrspace(200)*) addrspace(200)
declare void @llvm.lifetime.end.p200i8(i64, i8 addrspace(200)* nocapture) addrspace(200)
declare void @bar(i32 addrspace(200)*) addrspace(200)
