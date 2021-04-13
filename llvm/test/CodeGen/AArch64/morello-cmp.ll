; RUN: llc -mtriple=arm64 -mattr=+c64,+morello -target-abi purecap -o - %s | FileCheck %s

declare i32 @foo(...)
declare i32 @bar(...)

; CHECK-LABEL: testCmp:
define i32 @testCmp(i32 addrspace(200)* %a, i32 addrspace(200)* %b) {
entry:
  %cmp = icmp ult i32 addrspace(200)* %a, %b
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
; CHECK: cmp x0, x1
}

; CHECK-LABEL: testCsel1:
define i32 @testCsel1(i32 addrspace(200)* %a, i32 addrspace(200)* %b, i32 %c, i32 %d) {
entry:
  %cmp = icmp ult i32 addrspace(200)* %a, %b
  %cond = select i1 %cmp, i32 %c, i32 %d
  ret i32 %cond
; CHECK:	cmp x0, x1
; CHECK-NEXT:	csel	w0, w2, w3, lt
}

; CHECK-LABEL: testCsel2:
define i32 addrspace(200)* @testCsel2(i32 addrspace(200)* %a, i32 addrspace(200)* %b) {
entry:
  %cmp = icmp ult i32 addrspace(200)* %a, %b
  %cond = select i1 %cmp, i32 addrspace(200)* %a, i32 addrspace(200)* %b
  ret i32 addrspace(200)* %cond
; CHECK:	cmp x0, x1
; CHECK-NEXT:	csel	c0, c0, c1, lt
}

; CHECK-LABEL: testCsel3:
define i32 @testCsel3(i32 addrspace(200)* %a, i32 addrspace(200)* %b) {
entry:
  %cmp = icmp ult i32 addrspace(200)* %a, %b
  %conv = zext i1 %cmp to i32
  ret i32 %conv
; CHECK:	cmp x0, x1
; CHECK-NEXT:	cset	 w0, lo
}

; CHECK-LABEL: cmpToNull
define i32 @cmpToNull(i8 addrspace(200)* %a) {
entry:
  %tobool = icmp ne i8 addrspace(200)* %a, null
  %r = zext i1 %tobool to i32
  ret i32 %r
; CHECK:        cmp x0, #0
; CHECK-NEXT:	cset	 w0, ne
; CHECK-NEXT:	ret
}

@errno = common local_unnamed_addr addrspace(200) global i32 0, align 4

; CHECK-LABEL: checkcond
; CHECK:      cmp x0, x1
; CHECK-NEXT: b.hs [[LL:.*]]
; CHECK: [[LL]]
; CHECK-NEXT: mov w0, wzr
; CHECK-NEXT: ret
define i32 @checkcond(i8 addrspace(200)* readnone %ptr1, i8 addrspace(200)* readnone %ptr2) {
entry:
  %cmp = icmp ult i8 addrspace(200)* %ptr1, %ptr2
  br i1 %cmp, label %if.then, label %return

if.then:
  store i32 1, i32 addrspace(200)* @errno, align 4
  br label %return

return:
  %retval.0 = phi i32 [ -1, %if.then ], [ 0, %entry ]
  ret i32 %retval.0
}
