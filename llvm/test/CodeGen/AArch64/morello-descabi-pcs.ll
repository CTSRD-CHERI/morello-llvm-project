; RUN: llc -march=aarch64 -mattr=+morello,+c64 -target-abi purecap -disable-post-ra -o - %s -cheri-cap-table-abi=fn-desc --frame-pointer=none | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none-unknown-elf"

@aa = addrspace(200) global i32 0, align 4

; CHECK-LABEL: foo:
define ptr addrspace(200) @foo(i32 %max) local_unnamed_addr addrspace(200) {
entry:
; CHECK:  mov c28, c29
; CHECK-NEXT: sub csp, csp, #208
; CHECK-NEXT: .cfi_def_cfa csp, -208
; CHECK-NEXT: str c17, [csp, #32]
; CHECK-NEXT: stp c30, c27, [csp, #48]
; CHECK-NEXT: stp c26, c25, [csp, #80]
; CHECK-NEXT: stp c24, c23, [csp, #112]
; CHECK-NEXT: stp c22, c21, [csp, #144]
; CHECK-NEXT: stp c20, c19, [csp, #176]

; CHECK:      ldp c20, c19, [csp, #176]
; CHECK-NEXT: ldp c22, c21, [csp, #144]
; CHECK-NEXT: ldp c24, c23, [csp, #112]
; CHECK-NEXT: ldp c26, c25, [csp, #80]
; CHECK-NEXT: ldp c30, c27, [csp, #48]
; CHECK-NEXT: ldr c17, [csp, #32]
; CHECK-NEXT: add csp, csp, #208
; CHECK-NEXT: ret c30

  %call = tail call i32 @bar()
  %call1 = tail call i32 @bar()
  %call2 = tail call i32 @bar()
  %call3 = tail call i32 @bar()
  %call4 = tail call i32 @bar()
  %call5 = tail call i32 @bar()
  %call6 = tail call i32 @bar()
  %call17 = tail call i32 @bar()
  %call18 = tail call i32 @bar()
  %cmp24 = icmp sgt i32 %max, 0
  br i1 %cmp24, label %for.body, label %entry.for.cond.cleanup_crit_edge

entry.for.cond.cleanup_crit_edge:
  %.pre = load i32, ptr addrspace(200) @aa, align 4
  br label %for.cond.cleanup

for.cond.cleanup:
  %0 = phi i32 [ %.pre, %entry.for.cond.cleanup_crit_edge ], [ 4, %for.body ]
  %add = add i32 %call1, %call
  %add9 = add i32 %add, %call2
  %add10 = add i32 %add9, %call3
  %add11 = add i32 %add10, %call4
  %add12 = add i32 %add11, %call5
  %add13 = add i32 %add12, %call6
  %add14 = add i32 %add13, %call17
  %add15 = add i32 %add14, %call18
  %add16 = add i32 %add15, %0
  store i32 %add16, ptr addrspace(200) @aa, align 4
  ret ptr addrspace(200) @aa

for.body:
  %i.025 = phi i32 [ %inc, %for.body ], [ 0, %entry ]
  %call7 = tail call i32 @baz()
  %call8 = tail call i32 @biz(ptr addrspace(200) nonnull @aa)
  store i32 4, ptr addrspace(200) @aa, align 4
  %inc = add nuw nsw i32 %i.025, 1
  %exitcond = icmp eq i32 %inc, %max
  br i1 %exitcond, label %for.cond.cleanup, label %for.body
}

declare i32 @bar(...) local_unnamed_addr addrspace(200)

declare i32 @baz(...) local_unnamed_addr addrspace(200)

declare i32 @biz(...) local_unnamed_addr addrspace(200)

; Indirect calls are performed using ldpblr c29
; CHECK-LABEL: indirect:
; CHECK: mov c28, c29
; CHECK: mov	c[[SAVECAP:[0-9]+]], c28
; CHECK: mov	c[[BRCAP:[0-9]+]], c0
; CHECK: ldpblr c29, [c[[BRCAP]]]
; CHECK-NEXT: mov  c28, c[[SAVECAP]]
define i32 @indirect(ptr addrspace(200) nocapture %a) local_unnamed_addr addrspace(200) {
entry:
  tail call void %a(i32 10)
  ret i32 0
}

; We cannot tail call here because we need to restore the CSR that we used to hold c28 after the call.
; CHECK-LABEL: tc_indirect:
; CHECK: mov  c28, c29
; CHECK: mov	c[[SAVECAP:[0-9]+]], c28
; CHECK: mov	c[[BRCAP:[0-9]+]], c0
; CHECK: ldpblr c29, [c[[BRCAP]]]
; CHECK-NEXT: mov  c28, c[[SAVECAP]]
define i32 @tc_indirect(ptr addrspace(200) nocapture %a) local_unnamed_addr addrspace(200) {
entry:
  %call = tail call i32 %a(i32 10)
  ret i32 %call
}

; Same for direct calls. We need to restore c20 and c19 since bat is not dso local
; and therefore we cannot tail call.
; CHECK-LABEL: tc_direct:
; CHECK: mov  c28, c29
; CHECK: mov	c[[SAVECAP:[0-9]+]], c28
; CHECK: bl bat
; CHECK-NEXT: mov  c28, c[[SAVECAP]]
define i32 @tc_direct() local_unnamed_addr addrspace(200) {
entry:
  %call = tail call i32 @bat(i32 10)
  ret i32 %call
}

declare i32 @bat(i32) local_unnamed_addr addrspace(200)

; CHECK-LABEL: should_tail:
; CHECK: mov  c28, c29
; CHECK: b local
define i32 @should_tail() local_unnamed_addr addrspace(200) {
entry:
  %call = tail call i32 @local(i32 10)
  ret i32 %call
}

declare dso_local i32 @local(i32) local_unnamed_addr addrspace(200)
