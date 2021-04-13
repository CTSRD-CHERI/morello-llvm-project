; RUN: llc -mtriple=arm64 -mattr=+morello -o - %s -verify-machineinstrs | FileCheck %s
; RUN: llc -mtriple=arm64 -mattr=+morello,+c64 -target-abi purecap  -o - %s -verify-machineinstrs | FileCheck %s

declare i32 @foo(...)
declare i32 @bar(...)
declare i32 addrspace(200)* @baz()

; CHECK-LABEL: testCBZ:
; CHECK: cbz
define i32 @testCBZ(i32 addrspace(200)* %a, i32 addrspace(200)* %b) {
entry:
  %cmp = icmp eq i32 addrspace(200)* %a, null
  br i1 %cmp, label %cond.true, label %cond.false

cond.true:
  %call = tail call i32 bitcast (i32 (...)* @foo to i32 ()*)()
  br label %cond.end

cond.false:
  %call1 = tail call i32 bitcast (i32 (...)* @bar to i32 ()*)()
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
  %call = tail call i32 addrspace(200)* @baz()
  %cmp = icmp ne i32 addrspace(200)* %call, null
  br i1 %cmp, label %cond.true, label %cond.false

cond.false:
  ret i32 0
}
