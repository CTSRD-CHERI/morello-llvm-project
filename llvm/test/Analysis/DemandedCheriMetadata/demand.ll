; REQUIRES: aarch64-registered-target
; RUN: opt %s -march=aarch64 -mattr=+morello,+c64 -target-abi purecap -disable-output -passes="print<demanded-cheri-metadata>" 2>&1 | FileCheck %s

target datalayout = "e-m:e-pf200:128:128-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"

; CHECK: Running on function: store
; CHECK-DAG: DemandedCheriMetadata: 1 for   %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %a, align 16
; CHECK-DAG: DemandedCheriMetadata: 1 for   %1 = load i8 addrspace(200)* addrspace(200)*, i8 addrspace(200)* addrspace(200)* addrspace(200)* %b, align 16
define void @store(i8 addrspace(200)* addrspace(200)* nocapture readonly %a, i8 addrspace(200)* addrspace(200)* addrspace(200)* nocapture readonly %b) local_unnamed_addr addrspace(200) {
entry:
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %a, align 16
  %1 = load i8 addrspace(200)* addrspace(200)*, i8 addrspace(200)* addrspace(200)* addrspace(200)* %b, align 16
  store i8 addrspace(200)* %0, i8 addrspace(200)* addrspace(200)* %1, align 16
  ret void
}

; CHECK: Running on function: load_ptr
; CHECK-NEXT: DemandedCheriMetadata: 1 for   %0 = load i32 addrspace(200)*, i32 addrspace(200)* addrspace(200)* %a, align 16
define i32 @load_ptr(i32 addrspace(200)* addrspace(200)* nocapture readonly %a) local_unnamed_addr addrspace(200) {
entry:
  %0 = load i32 addrspace(200)*, i32 addrspace(200)* addrspace(200)* %a, align 16
  %1 = load i32, i32 addrspace(200)* %0, align 4
  ret i32 %1
}

; CHECK: Running on function: gep
; CHECK-DAG: DemandedCheriMetadata: 1 for   %arrayidx = getelementptr inbounds i32 addrspace(200)*, i32 addrspace(200)* addrspace(200)* %a, i64 2
; CHECK-DAG: DemandedCheriMetadata: 1 for   %0 = load i32 addrspace(200)*, i32 addrspace(200)* addrspace(200)* %arrayidx, align 16
define i32 @gep(i32 addrspace(200)* addrspace(200)* nocapture readonly %a) local_unnamed_addr addrspace(200) {
entry:
  %arrayidx = getelementptr inbounds i32 addrspace(200)*, i32 addrspace(200)* addrspace(200)* %a, i64 2
  %0 = load i32 addrspace(200)*, i32 addrspace(200)* addrspace(200)* %arrayidx, align 16
  %1 = load i32, i32 addrspace(200)* %0, align 4
  ret i32 %1
}

; CHECK: Running on function: bitcast
; CHECK-DAG: DemandedCheriMetadata: 1 for   %1 = load i32 addrspace(200)*, i32 addrspace(200)* addrspace(200)* %0, align 16
; CHECK-DAG: DemandedCheriMetadata: 1 for   %0 = bitcast i8 addrspace(200)* addrspace(200)* %arrayidx to i32 addrspace(200)* addrspace(200)*
; CHECK-DAG: DemandedCheriMetadata: 1 for   %arrayidx = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %a, i64 2
define i32 @bitcast(i8 addrspace(200)* addrspace(200)* nocapture readonly %a) local_unnamed_addr addrspace(200) {
entry:
  %arrayidx = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %a, i64 2
  %0 = bitcast i8 addrspace(200)* addrspace(200)* %arrayidx to i32 addrspace(200)* addrspace(200)*
  %1 = load i32 addrspace(200)*, i32 addrspace(200)* addrspace(200)* %0, align 16
  %2 = load i32, i32 addrspace(200)* %1, align 4
  ret i32 %2
}

; CHECK: Running on function: freeze
; CHECK-DAG: DemandedCheriMetadata: 1 for   %1 = load i32 addrspace(200)*, i32 addrspace(200)* addrspace(200)* %fr, align 16
; CHECK-DAG: DemandedCheriMetadata: 1 for   %0 = bitcast i8 addrspace(200)* addrspace(200)* %arrayidx to i32 addrspace(200)* addrspace(200)*
; CHECK-DAG: DemandedCheriMetadata: 1 for   %arrayidx = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %a, i64 2
; CHECK-DAG: DemandedCheriMetadata: 1 for   %fr = freeze i32 addrspace(200)* addrspace(200)* %0
define i32 @freeze(i8 addrspace(200)* addrspace(200)* nocapture readonly %a) local_unnamed_addr addrspace(200) {
entry:
  %arrayidx = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %a, i64 2
  %0 = bitcast i8 addrspace(200)* addrspace(200)* %arrayidx to i32 addrspace(200)* addrspace(200)*
  %fr = freeze i32 addrspace(200)* addrspace(200)* %0
  %1 = load i32 addrspace(200)*, i32 addrspace(200)* addrspace(200)* %fr, align 16
  %2 = load i32, i32 addrspace(200)* %1, align 4
  ret i32 %2
}

; CHECK: Running on function: sel
; CHECK-DAG: DemandedCheriMetadata: 1 for   %b.a = select i1 %tobool.not, i8 addrspace(200)* addrspace(200)* %b, i8 addrspace(200)* addrspace(200)* %a
; CHECK-DAG: DemandedCheriMetadata: 1 for   %cond = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %b.a, align 16
define i8 addrspace(200)* @sel(i32 %q, i8 addrspace(200)* addrspace(200)* nocapture readonly %a, i8 addrspace(200)* addrspace(200)* nocapture readonly %b) local_unnamed_addr addrspace(200) {
entry:
  %tobool.not = icmp eq i32 %q, 0
  %b.a = select i1 %tobool.not, i8 addrspace(200)* addrspace(200)* %b, i8 addrspace(200)* addrspace(200)* %a
  %cond = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %b.a, align 16
  ret i8 addrspace(200)* %cond
}

; CHECK: Running on function: testphi
; CHECK-DAG: DemandedCheriMetadata: 0 for   %0 = bitcast i32 addrspace(200)* %a.addr.0 to i8 addrspace(200)*
; CHECK-DAG: DemandedCheriMetadata: 1 for   %a.addr.0 = phi i32 addrspace(200)* [ %a, %entry ], [ %add.ptr, %while.cond ]
; CHECK-DAG: DemandedCheriMetadata: 1 for   %add.ptr = getelementptr inbounds i32, i32 addrspace(200)* %a.addr.0, i64 4
define i32 addrspace(200)* @testphi(i32 addrspace(200)* %a) local_unnamed_addr addrspace(200) {
entry:
  br label %while.cond

while.cond:                                       ; preds = %while.cond, %entry
  %a.addr.0 = phi i32 addrspace(200)* [ %a, %entry ], [ %add.ptr, %while.cond ]
  %0 = bitcast i32 addrspace(200)* %a.addr.0 to i8 addrspace(200)*
  %1 = tail call i64 @llvm.cheri.cap.address.get.i64(i8 addrspace(200)* %0)
  %conv = trunc i64 %1 to i32
  %call = tail call i32 @cond(i32 %conv)
  %tobool.not = icmp eq i32 %call, 0
  %add.ptr = getelementptr inbounds i32, i32 addrspace(200)* %a.addr.0, i64 4
  br i1 %tobool.not, label %while.end, label %while.cond

while.end:                                        ; preds = %while.cond
  ret i32 addrspace(200)* %a.addr.0
}

declare i32 @cond(i32) local_unnamed_addr addrspace(200)

declare i64 @llvm.cheri.cap.address.get.i64(i8 addrspace(200)*) addrspace(200)

; CHECK: Running on function: addrset
; CHECC-DAG: DemandedCheriMetadata: 1 for   %1 = tail call i8 addrspace(200)* @llvm.cheri.cap.address.set.i64(i8 addrspace(200)* %0, i64 %val)
; CHECK-DAG: DemandedCheriMetadata: 1 for   %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %c, align 16
define i8 addrspace(200)* @addrset(i8 addrspace(200)* addrspace(200)* nocapture readonly %c, i64 %val) local_unnamed_addr addrspace(200) {
entry:
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %c, align 16
  %1 = tail call i8 addrspace(200)* @llvm.cheri.cap.address.set.i64(i8 addrspace(200)* %0, i64 %val)
  ret i8 addrspace(200)* %1
}

declare i8 addrspace(200)* @llvm.cheri.cap.address.set.i64(i8 addrspace(200)*, i64) addrspace(200)

; CHECK: Running on function: permsand
; CHECK-DAG: DemandedCheriMetadata: 1 for   %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %c, align 16
; CHECK-DAG: DemandedCheriMetadata: 1 for   %1 = tail call i8 addrspace(200)* @llvm.cheri.cap.perms.and.i64(i8 addrspace(200)* %0, i64 %val)
 define i8 addrspace(200)* @permsand(i8 addrspace(200)* addrspace(200)* nocapture readonly %c, i64 %val) local_unnamed_addr addrspace(200) {
entry:
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %c, align 16
  %1 = tail call i8 addrspace(200)* @llvm.cheri.cap.perms.and.i64(i8 addrspace(200)* %0, i64 %val)
  ret i8 addrspace(200)* %1
}

declare i8 addrspace(200)* @llvm.cheri.cap.perms.and.i64(i8 addrspace(200)*, i64) addrspace(200)

; CHECK: Running on function: boundsset
; CHECK-DAG: DemandedCheriMetadata: 1 for   %1 = tail call i8 addrspace(200)* @llvm.cheri.cap.bounds.set.i64(i8 addrspace(200)* %0, i64 %val)
; CHECK-DAG: DemandedCheriMetadata: 1 for   %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %c, align 16
define i8 addrspace(200)* @boundsset(i8 addrspace(200)* addrspace(200)* nocapture readonly %c, i64 %val) local_unnamed_addr addrspace(200) {
entry:
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %c, align 16
  %1 = tail call i8 addrspace(200)* @llvm.cheri.cap.bounds.set.i64(i8 addrspace(200)* %0, i64 %val)
  ret i8 addrspace(200)* %1
}

declare i8 addrspace(200)* @llvm.cheri.cap.bounds.set.i64(i8 addrspace(200)*, i64) addrspace(200)

; CHECK: Running on function: boundssetexact
; CHECK-DAG: DemandedCheriMetadata: 1 for   %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %c, align 16
; CHECK-DAG: DemandedCheriMetadata: 1 for   %1 = tail call i8 addrspace(200)* @llvm.cheri.cap.bounds.set.exact.i64(i8 addrspace(200)* %0, i64 %val)
define i8 addrspace(200)* @boundssetexact(i8 addrspace(200)* addrspace(200)* nocapture readonly %c, i64 %val) local_unnamed_addr addrspace(200) {
entry:
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %c, align 16
  %1 = tail call i8 addrspace(200)* @llvm.cheri.cap.bounds.set.exact.i64(i8 addrspace(200)* %0, i64 %val)
  ret i8 addrspace(200)* %1
}

declare i8 addrspace(200)* @llvm.cheri.cap.bounds.set.exact.i64(i8 addrspace(200)*, i64) addrspace(200)

; CHECK: Running on function: callf
; CHECK-DAG: DemandedCheriMetadata: 1 for   %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %c, align 16
; CHECK-DAG: DemandedCheriMetadata: 1 for   %1 = tail call i8 addrspace(200)* @foo(i8 addrspace(200)* %0)
define i8 addrspace(200)* @callf(i8 addrspace(200)* addrspace(200)* nocapture readonly %c) local_unnamed_addr addrspace(200) {
entry:
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %c, align 16
  %1 = tail call i8 addrspace(200)* @foo(i8 addrspace(200)* %0)
  ret i8 addrspace(200)* %1
}

declare i8 addrspace(200)* @foo(i8 addrspace(200)*) addrspace(200)
