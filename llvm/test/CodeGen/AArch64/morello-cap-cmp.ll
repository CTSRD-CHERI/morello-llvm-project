; RUN: sed 's/addrspace(P)/addrspace(0)/g' %s | llc -mtriple=arm64 -mattr=+morello -verify-machineinstrs | FileCheck %s
; RUN: sed 's/addrspace(P)/addrspace(200)/g' %s | llc -mtriple=arm64 -mattr=+morello,+c64 -target-abi purecap -verify-machineinstrs | FileCheck %s

declare i32 @foo(...)
declare i32 @bar(...)

; CHECK-LABEL: testCmp:
define i32 @testCmp(ptr addrspace(200) %a, ptr addrspace(200) %b) {
entry:
  %cmp = icmp ult ptr addrspace(200) %a, %b
  br i1 %cmp, label %cond.true, label %cond.false

cond.true:
  %call = tail call i32 bitcast (i32 (...) addrspace(P)* @foo to i32 () addrspace(P)*)()
  br label %cond.end

cond.false:
  %call1 = tail call i32 bitcast (i32 (...) addrspace(P)* @bar to i32 () addrspace(P)*)()
  br label %cond.end

cond.end:
  %cond = phi i32 [ %call, %cond.true ], [ %call1, %cond.false ]
  ret i32 %cond
; CHECK: cmp x0, x1
}

; CHECK-LABEL: testCmpZero:
define i32 @testCmpZero(ptr addrspace(200) %a) {
entry:
  %cmp = icmp ult ptr addrspace(200) %a, null
  br i1 %cmp, label %cond.true, label %cond.false

cond.true:
  %call = tail call i32 bitcast (i32 (...) addrspace(P)* @foo to i32 () addrspace(P)*)()
  br label %cond.end

cond.false:
  %call1 = tail call i32 bitcast (i32 (...) addrspace(P)* @bar to i32 () addrspace(P)*)()
  br label %cond.end

cond.end:
  %cond = phi i32 [ %call, %cond.true ], [ %call1, %cond.false ]
  ret i32 %cond
; CHECK: cmp x0, #0
}
