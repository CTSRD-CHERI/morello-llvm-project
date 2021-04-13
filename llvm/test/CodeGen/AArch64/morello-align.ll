; RUN: llc -mtriple=arm64 -mattr=+morello,+c64 -target-abi purecap -o - %s | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"

declare i64 @llvm.cheri.cap.address.get.i64(i8 addrspace(200)*) addrspace(200)
declare void @llvm.assume(i1) addrspace(200)

; CHECK-LABEL: foo
; CHECK: alignd c0, c0, #2
define i8 addrspace(200)* @foo(i8 addrspace(200)* %a) local_unnamed_addr addrspace(200) {
entry:
  %ptraddr = tail call i64 @llvm.cheri.cap.address.get.i64(i8 addrspace(200)* %a)
  %0 = and i64 %ptraddr, 3
  %diff = sub nsw i64 0, %0
  %aligned_result = getelementptr inbounds i8, i8 addrspace(200)* %a, i64 %diff
  %ptrint = ptrtoint i8 addrspace(200)* %aligned_result to i64
  %maskedptr = and i64 %ptrint, 3
  %maskcond = icmp eq i64 %maskedptr, 0
  tail call void @llvm.assume(i1 %maskcond)
  ret i8 addrspace(200)* %aligned_result
}

; CHECK-LABEL: bar
; CHECK: alignu c0, c0, #2
define i8 addrspace(200)* @bar(i8 addrspace(200)* %a) local_unnamed_addr addrspace(200) {
entry:
  %ptraddr = tail call i64 @llvm.cheri.cap.address.get.i64(i8 addrspace(200)* %a)
  %over_boundary = add i64 %ptraddr, 3
  %aligned_intptr = and i64 %over_boundary, -4
  %diff = sub i64 %aligned_intptr, %ptraddr
  %aligned_result = getelementptr inbounds i8, i8 addrspace(200)* %a, i64 %diff
  %ptrint = ptrtoint i8 addrspace(200)* %aligned_result to i64
  %maskedptr = and i64 %ptrint, 3
  %maskcond = icmp eq i64 %maskedptr, 0
  tail call void @llvm.assume(i1 %maskcond)
  ret i8 addrspace(200)* %aligned_result
}

; CHECK-LABEL: bat
; CHECK: alignd c0, c0, #2
define i8 addrspace(200)* @bat(i8 addrspace(200)* %x) local_unnamed_addr addrspace(200) {
entry:
  %0 = tail call i64 @llvm.cheri.cap.address.get.i64(i8 addrspace(200)* %x)
  %and = and i64 %0, -4
  %1 = tail call i8 addrspace(200)* @llvm.cheri.cap.address.set.i64(i8 addrspace(200)* %x, i64 %and)
  ret i8 addrspace(200)* %1
}

declare i8 addrspace(200)* @llvm.cheri.cap.address.set.i64(i8 addrspace(200)*, i64) addrspace(200)

; CHECK-LABEL: fib
; CHECK: alignu c0, c0, #2
define i8 addrspace(200)* @fib(i8 addrspace(200)* %x) local_unnamed_addr addrspace(200) {
entry:
  %0 = getelementptr i8, i8 addrspace(200)* %x, i64 3
  %1 = tail call i64 @llvm.cheri.cap.address.get.i64(i8 addrspace(200)* %0)
  %and = and i64 %1, -4
  %2 = tail call i8 addrspace(200)* @llvm.cheri.cap.address.set.i64(i8 addrspace(200)* %x, i64 %and)
  ret i8 addrspace(200)* %2
}

; CHECK-LABEL: baz
; CHECK: alignu c0, c0, #2
define i8 addrspace(200)* @baz(i8 addrspace(200)* %x) local_unnamed_addr addrspace(200) {
entry:
  %0 = tail call i64 @llvm.cheri.cap.address.get.i64(i8 addrspace(200)* %x)
  %add = add i64 %0, 3
  %and = and i64 %add, -4
  %1 = tail call i8 addrspace(200)* @llvm.cheri.cap.address.set.i64(i8 addrspace(200)* %x, i64 %and)
  ret i8 addrspace(200)* %1
}

; Make sure that we match the correct constants with some negative tests.

; CHECK-LABEL: negative0
; CHECK-NOT: alignd
; CHECK-NOT: alignu
define i8 addrspace(200)* @negative0(i8 addrspace(200)* %a) local_unnamed_addr addrspace(200) {
entry:
  %ptraddr = tail call i64 @llvm.cheri.cap.address.get.i64(i8 addrspace(200)* %a)
  %0 = and i64 %ptraddr, 4
  %diff = sub nsw i64 0, %0
  %aligned_result = getelementptr inbounds i8, i8 addrspace(200)* %a, i64 %diff
  ret i8 addrspace(200)* %aligned_result
}

; CHECK-LABEL: negative1
; CHECK-NOT: alignd
; CHECK-NOT: alignu
define i8 addrspace(200)* @negative1(i8 addrspace(200)* %a) local_unnamed_addr addrspace(200) {
entry:
  %ptraddr = tail call i64 @llvm.cheri.cap.address.get.i64(i8 addrspace(200)* %a)
  %over_boundary = add i64 %ptraddr, 4
  %aligned_intptr = and i64 %over_boundary, -4
  %diff = sub i64 %aligned_intptr, %ptraddr
  %aligned_result = getelementptr inbounds i8, i8 addrspace(200)* %a, i64 %diff
  %ptrint = ptrtoint i8 addrspace(200)* %aligned_result to i64
  %maskedptr = and i64 %ptrint, 3
  %maskcond = icmp eq i64 %maskedptr, 0
  tail call void @llvm.assume(i1 %maskcond)
  ret i8 addrspace(200)* %aligned_result
}

; CHECK-LABEL: negative2
; CHECK-NOT: alignd
; CHECK-NOT: alignu
define i8 addrspace(200)* @negative2(i8 addrspace(200)* %a) local_unnamed_addr addrspace(200) {
entry:
  %ptraddr = tail call i64 @llvm.cheri.cap.address.get.i64(i8 addrspace(200)* %a)
  %over_boundary = add i64 %ptraddr, 3
  %aligned_intptr = and i64 %over_boundary, -5
  %diff = sub i64 %aligned_intptr, %ptraddr
  %aligned_result = getelementptr inbounds i8, i8 addrspace(200)* %a, i64 %diff
  %ptrint = ptrtoint i8 addrspace(200)* %aligned_result to i64
  %maskedptr = and i64 %ptrint, 3
  %maskcond = icmp eq i64 %maskedptr, 0
  tail call void @llvm.assume(i1 %maskcond)
  ret i8 addrspace(200)* %aligned_result
}

; CHECK-LABEL: negative3
; CHECK-NOT: alignd
; CHECK-NOT: alignu
define i8 addrspace(200)* @negative3(i8 addrspace(200)* %x) local_unnamed_addr addrspace(200) {
entry:
  %0 = tail call i64 @llvm.cheri.cap.address.get.i64(i8 addrspace(200)* %x)
  %and = and i64 %0, -5
  %1 = tail call i8 addrspace(200)* @llvm.cheri.cap.address.set.i64(i8 addrspace(200)* %x, i64 %and)
  ret i8 addrspace(200)* %1
}

; CHECK-LABEL: negative4
; CHECK-NOT: alignd
; CHECK-NOT: alignu
define i8 addrspace(200)* @negative4(i8 addrspace(200)* %x) local_unnamed_addr addrspace(200) {
entry:
  %0 = getelementptr i8, i8 addrspace(200)* %x, i64 4
  %1 = tail call i64 @llvm.cheri.cap.address.get.i64(i8 addrspace(200)* %0)
  %and = and i64 %1, -4
  %2 = tail call i8 addrspace(200)* @llvm.cheri.cap.address.set.i64(i8 addrspace(200)* %x, i64 %and)
  ret i8 addrspace(200)* %2
}

; CHECK-LABEL: negative5
; CHECK-NOT: alignd
; CHECK-NOT: alignu
define i8 addrspace(200)* @negative5(i8 addrspace(200)* %x) local_unnamed_addr addrspace(200) {
entry:
  %0 = getelementptr i8, i8 addrspace(200)* %x, i64 3
  %1 = tail call i64 @llvm.cheri.cap.address.get.i64(i8 addrspace(200)* %0)
  %and = and i64 %1, -5
  %2 = tail call i8 addrspace(200)* @llvm.cheri.cap.address.set.i64(i8 addrspace(200)* %x, i64 %and)
  ret i8 addrspace(200)* %2
}
