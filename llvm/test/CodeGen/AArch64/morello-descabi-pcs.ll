; RUN: llc -march=aarch64 -mattr=+morello,+c64 -target-abi purecap -disable-post-ra -o - %s -cheri-cap-table-abi=fn-desc | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none-unknown-elf"

@aa = addrspace(200) global i32 0, align 4

; CHECK-NOT: c28

; CHECK-LABEL: foo:
define i8 addrspace(200)* @foo(i32 %max) local_unnamed_addr addrspace(200) {
entry:
; CHECK:	sub	csp, csp, #192
; CHECK-NEXT:	str	c17, [csp, #16]
; CHECK-NEXT:	stp	c30, c27, [csp, #32]
; CHECK-NEXT:	stp	c26, c25, [csp, #64]
; CHECK-NEXT:	stp	c24, c23, [csp, #96]
; CHECK-NEXT:	stp	c22, c21, [csp, #128]
; CHECK-NEXT:	stp	c20, c19, [csp, #160]

; CHECK:	ldp	c22, c21, [csp, #128]
; CHECK-NEXT:	ldp	c24, c23, [csp, #96]
; CHECK-NEXT:	ldp	c26, c25, [csp, #64]
; CHECK-NEXT:	ldp	c30, c27, [csp, #32]
; CHECK-NEXT:	ldr	c17, [csp, #16]
; CHECK-NEXT:	add	csp, csp, #192
; CHECK-NEXT:	ret	c30

  %call = tail call i32 bitcast (i32 (...) addrspace(200)* @bar to i32 () addrspace(200)*)()
  %call1 = tail call i32 bitcast (i32 (...) addrspace(200)* @bar to i32 () addrspace(200)*)()
  %call2 = tail call i32 bitcast (i32 (...) addrspace(200)* @bar to i32 () addrspace(200)*)()
  %call3 = tail call i32 bitcast (i32 (...) addrspace(200)* @bar to i32 () addrspace(200)*)()
  %call4 = tail call i32 bitcast (i32 (...) addrspace(200)* @bar to i32 () addrspace(200)*)()
  %call5 = tail call i32 bitcast (i32 (...) addrspace(200)* @bar to i32 () addrspace(200)*)()
  %call6 = tail call i32 bitcast (i32 (...) addrspace(200)* @bar to i32 () addrspace(200)*)()
  %cmp24 = icmp sgt i32 %max, 0
  br i1 %cmp24, label %for.body, label %entry.for.cond.cleanup_crit_edge

entry.for.cond.cleanup_crit_edge:
  %.pre = load i32, i32 addrspace(200)* @aa, align 4
  br label %for.cond.cleanup

for.cond.cleanup:
  %0 = phi i32 [ %.pre, %entry.for.cond.cleanup_crit_edge ], [ 4, %for.body ]
  %add = add i32 %call1, %call
  %add9 = add i32 %add, %call2
  %add10 = add i32 %add9, %call3
  %add11 = add i32 %add10, %call4
  %add12 = add i32 %add11, %call5
  %add13 = add i32 %add12, %call6
  %add14 = add i32 %add13, %0
  store i32 %add14, i32 addrspace(200)* @aa, align 4
  ret i8 addrspace(200)* bitcast (i32 addrspace(200)* @aa to i8 addrspace(200)*)

for.body:
  %i.025 = phi i32 [ %inc, %for.body ], [ 0, %entry ]
  %call7 = tail call i32 bitcast (i32 (...) addrspace(200)* @baz to i32 () addrspace(200)*)()
  %call8 = tail call i32 bitcast (i32 (...) addrspace(200)* @biz to i32 (i32 addrspace(200)*) addrspace(200)*)(i32 addrspace(200)* nonnull @aa)
  store i32 4, i32 addrspace(200)* @aa, align 4
  %inc = add nuw nsw i32 %i.025, 1
  %exitcond = icmp eq i32 %inc, %max
  br i1 %exitcond, label %for.cond.cleanup, label %for.body
}

declare i32 @bar(...) local_unnamed_addr addrspace(200)

declare i32 @baz(...) local_unnamed_addr addrspace(200)

declare i32 @biz(...) local_unnamed_addr addrspace(200)

; Indirect calls are performed using ldpblr c29
; CHECK-LABEL: indirect:
; CHECK: stp	c20, c19
; CHECK: mov	c[[BRCAP:[0-9]+]], c0
; CHECK: ldpblr c29, [c[[BRCAP]]]
; CHECK: ldp	c20, c19
define i32 @indirect(i8 addrspace(200)* nocapture %a) local_unnamed_addr addrspace(200) {
entry:
  %0 = bitcast i8 addrspace(200)* %a to void (i32) addrspace(200)*
  tail call void %0(i32 10)
  ret i32 0
}

; We cannot tail call here because we need to restore c20 and c19 after the call.
; CHECK-LABEL: tc_indirect:
; CHECK: stp	c20, c19
; CHECK: mov	c[[BRCAP:[0-9]+]], c0
; CHECK: ldpblr c29, [c[[BRCAP]]]
; CHECK: ldp	c20, c19
define i32 @tc_indirect(i8 addrspace(200)* nocapture %a) local_unnamed_addr addrspace(200) {
entry:
  %0 = bitcast i8 addrspace(200)* %a to i32 (i32) addrspace(200)*
  %call = tail call i32 %0(i32 10)
  ret i32 %call
}

; Same for direct calls. We need to restore c20 and c19 since bat is not dso local
; and therefore we cannot tail call.
; CHECK-LABEL: tc_direct:
; CHECK: stp	c20, c19
; CHECK: bl bat
; CHECK: ldp	c20, c19
define i32 @tc_direct() local_unnamed_addr addrspace(200) {
entry:
  %call = tail call i32 @bat(i32 10)
  ret i32 %call
}

declare i32 @bat(i32) local_unnamed_addr addrspace(200)

; This is a missed optimization. Since local is dso local, the call won't clobber c19 and c20
; and we should be able to tail call.
; CHECK-LABEL: should_tail:
; CHECK: stp	c20, c19
; CHECK: bl local
; CHECK: ldp	c20, c19
define i32 @should_tail() local_unnamed_addr addrspace(200) {
entry:
  %call = tail call i32 @local(i32 10)
  ret i32 %call
}

declare dso_local i32 @local(i32) local_unnamed_addr addrspace(200)
