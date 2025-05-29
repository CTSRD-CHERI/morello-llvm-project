; RUN: sed 's/addrspace(P)/addrspace(0)/g' %s | llc -mtriple=arm64 -mattr=+morello -verify-machineinstrs | FileCheck %s
; RUN: sed 's/addrspace(P)/addrspace(200)/g' %s | llc -mtriple=arm64 -mattr=+morello,+c64 -target-abi purecap -verify-machineinstrs | FileCheck %s

declare i32 @foo(...)
declare i32 @bar(...)
declare ptr addrspace(200) @baz()

; CHECK-LABEL: testCBZ:
; CHECK: cbz
define i32 @testCBZ(ptr addrspace(200) %a, ptr addrspace(200) %b) {
entry:
  %cmp = icmp eq ptr addrspace(200) %a, null
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
}

; CHECK-LABEL: testCBNZ:
; CHECK: cbnz x0
define i32 @testCBNZ() {
entry:
  br label %cond.true

cond.true:
  %call = tail call ptr addrspace(200) @baz()
  %cmp = icmp ne ptr addrspace(200) %call, null
  br i1 %cmp, label %cond.true, label %cond.false

cond.false:
  ret i32 0
}
