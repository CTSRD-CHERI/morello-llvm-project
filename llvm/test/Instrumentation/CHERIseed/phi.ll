; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------

; CHECK-LABEL: @phinode
define void @phinode(i32 %i, i1 %cond) {
; CHECK-NEXT:  if.a:
if.a:
; CHECK-NEXT:  %a = add nsw i32 %i, 0
  %a = add nsw i32 %i, 0
; CHECK-NEXT:  br i1 %cond, label %if.b, label %if.c
  br i1 %cond, label %if.b, label %if.c
; CHECK-LABEL: if.b:
; CHECK-SAME:  ; preds = %if.a
if.b:
; CHECK-NEXT:  %b = add nsw i32 %i, 1
  %b = add nsw i32 %i, 1
; CHECK-NEXT:  br label %if.end
  br label %if.end
; CHECK-LABEL: if.c:
; CHECK-SAME:  ; preds = %if.a
if.c:
; CHECK-NEXT:  %c = add nsw i32 %i, 2
  %c = add nsw i32 %i, 2
; CHECK-NEXT:  br label %if.end
  br label %if.end
; CHECK-LABEL: if.end:
; CHECK-SAME:  ; preds = %if.c, %if.b
if.end:
; CHECK-NEXT:  %res = phi i32 [ %b, %if.b ], [ %c, %if.c ]
  %res = phi i32 [ %b, %if.b ], [ %c, %if.c ]
; CHECK-NEXT:  %d = add nsw i32 %res, 1
  %d = add nsw i32 %res, 1
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------

; CHECK-LABEL: @phi_for_loop
define void @phi_for_loop(i32 %n) {
; CHECK-NEXT:  entry:
entry:
; CHECK-NEXT:  %cmp = icmp slt i32 %n, 0
  %cmp = icmp slt i32 %n, 0
; CHECK-NEXT:  br i1 %cmp, label %entry.for.cond.cleanup_crit_edge, label %entry.for.body_crit_edge
  br i1 %cmp, label %for.cond.cleanup, label %for.body

; CHECK-LABEL: entry.for.body_crit_edge:
; CHECK-SAME:  ; preds = %entry
; CHECK-NEXT:    br label %for.body

; CHECK-LABEL: entry.for.cond.cleanup_crit_edge:
; CHECK-SAME:  ; preds = %entry
; CHECK-NEXT:    br label %for.cond.cleanup

; CHECK-LABEL: for.cond.cleanup:
; CHECK-SAME:  ; preds = %for.body.for.cond.cleanup_crit_edge, %entry.for.cond.cleanup_crit_edge
for.cond.cleanup:
; CHECK-NEXT:  ret void
  ret void
; CHECK-LABEL: for.body:
; CHECK-SAME:  ; preds = %for.body.for.body_crit_edge, %entry.for.body_crit_edge
for.body:
; CHECK-NEXT:  %i.04 = phi i32 [ %inc, %for.body.for.body_crit_edge ], [ 0, %entry.for.body_crit_edge ]
  %i.04 = phi i32 [ %inc, %for.body ], [ 0, %entry ]
; CHECK-NEXT:  %inc = add nuw i32 %i.04, 1
  %inc = add nuw i32 %i.04, 1
; CHECK-NEXT:  %exitcond = icmp eq i32 %i.04, %n
  %exitcond = icmp eq i32 %i.04, %n
; CHECK-NEXT:  br i1 %exitcond, label %for.body.for.cond.cleanup_crit_edge, label %for.body.for.body_crit_edge
  br i1 %exitcond, label %for.cond.cleanup, label %for.body

; CHECK-LABEL: for.body.for.body_crit_edge:
; CHECK-SAME:  ; preds = %for.body
; CHECK-NEXT:    br label %for.body

; CHECK-LABEL: for.body.for.cond.cleanup_crit_edge:
; CHECK-SAME:  ; preds = %for.body
; CHECK-NEXT:    br label %for.cond.cleanup
}

; ------------------------------------------------------------------------------

; CHECK-LABEL: @alloca_in_a_loop
define void @alloca_in_a_loop(i32 %n, i32 addrspace(200)* %v) {
; CHECK-NEXT:  entry:
entry:
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %0 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %cmp3 = icmp sgt i32 %n, 0
  %cmp3 = icmp sgt i32 %n, 0
; CHECK-NEXT:  br i1 %cmp3, label %entry.while.body_crit_edge, label %entry.while.end_crit_edge
  br i1 %cmp3, label %while.body, label %while.end

; CHECK-LABEL: entry.while.end_crit_edge:
; CHECK-SAME:  ; preds = %entry
; CHECK-NEXT:    br label %while.end

; CHECK-LABEL: entry.while.body_crit_edge:
; CHECK-SAME:  ; preds = %entry
; CHECK-NEXT:    %v.addr.05.tail.cpy1 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* %2, %__cheriseed_cap_t* %v, i64 0)
; CHECK-NEXT:    br label %while.body

; CHECK-LABEL: while.body:
; CHECK-SAME:  ; preds = %while.body.while.body_crit_edge, %entry.while.body_crit_edge
while.body:
; CHECK-NEXT:    %v.addr.05 = phi %__cheriseed_cap_t* [ %v.addr.05.tail.cpy, %while.body.while.body_crit_edge ], [ %v.addr.05.tail.cpy1, %entry.while.body_crit_edge ]
  %v.addr.05 = phi i32 addrspace(200)* [ %incdec.ptr, %while.body ], [ %v, %entry ]
; CHECK-NEXT:    %incdec.ptr = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* %0, %__cheriseed_cap_t* %v.addr.05, i64 4)
  %incdec.ptr = getelementptr inbounds i32, i32 addrspace(200)* %v.addr.05, i64 1
; CHECK-NEXT:    %cmp = icmp sgt i32 %n, 1
  %cmp = icmp sgt i32 %n, 1
; CHECK-NEXT:    br i1 %cmp, label %while.body.while.body_crit_edge, label %while.body.while.end_crit_edge
  br i1 %cmp, label %while.body, label %while.end

; CHECK-LABEL: while.body.while.end_crit_edge:
; CHECK-SAME:  ; preds = %while.body
; CHECK-NEXT:    br label %while.end

; CHECK-LABEL: while.body.while.body_crit_edge:
; CHECK-SAME:  ; preds = %while.body
; CHECK-NEXT:    %v.addr.05.tail.cpy = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* %1, %__cheriseed_cap_t* %incdec.ptr, i64 0)
; CHECK-NEXT:    br label %while.body

; CHECK-LABEL: while.end:
; CHECK-SAME:  ; preds = %while.body.while.end_crit_edge, %entry.while.end_crit_edge
while.end:
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------

; CHECK-LABEL: @phi_while_loop_cap
define void @phi_while_loop_cap(i32 addrspace(200)* %a, i32 addrspace(200)* %b) {
; CHECK-NEXT:  entry:
entry:
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %0 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %b)
; CHECK-NEXT:  %4 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %a)
; CHECK-NEXT:  %cmp3 = icmp ugt i64 %3, %4
  %cmp3 = icmp ugt i32 addrspace(200)* %b, %a
; CHECK-NEXT:  br i1 %cmp3, label %while.body.lr.ph, label %entry.while.end_crit_edge
  br i1 %cmp3, label %while.body.lr.ph, label %while.end

; CHECK-LABEL: entry.while.end_crit_edge:
; CHECK-SAME:  ; preds = %entry
; CHECK-NEXT:    br label %while.end

; CHECK-LABEL: while.body.lr.ph:
; CHECK-SAME:  ; preds = %entry
while.body.lr.ph:
; CHECK-NEXT:    %b.addr.tail.cpy = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* %1, %__cheriseed_cap_t* %b, i64 0)
; CHECK-NEXT:    br label %while.body
  br label %while.body

; CHECK-LABEL: while.body:
; CHECK-SAME:  ; preds = %while.body.while.body_crit_edge, %while.body.lr.ph
while.body:
; CHECK-NEXT:    %b.addr = phi %__cheriseed_cap_t* [ %b.addr.tail.cpy, %while.body.lr.ph ], [ %b.addr.tail.cpy1, %while.body.while.body_crit_edge ]
  %b.addr = phi i32 addrspace(200)* [ %b, %while.body.lr.ph ], [ %incdec.ptr, %while.body ]
; CHECK-NEXT:    %incdec.ptr = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* %0, %__cheriseed_cap_t* %b.addr, i64 -4)
  %incdec.ptr = getelementptr inbounds i32, i32 addrspace(200)* %b.addr, i64 -1
; CHECK-NEXT:    %5 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %incdec.ptr)
; CHECK-NEXT:    %6 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %a)
; CHECK-NEXT:    %cmp = icmp ugt i64 %5, %6
  %cmp = icmp ugt i32 addrspace(200)* %incdec.ptr, %a
; CHECK-NEXT:    br i1 %cmp, label %while.body.while.body_crit_edge, label %while.body.while.end_crit_edge
  br i1 %cmp, label %while.body, label %while.end

; CHECK-LABEL: while.body.while.end_crit_edge:
; CHECK-SAME:  ; preds = %while.body
; CHECK-NEXT:    br label %while.end

; CHECK-LABEL: while.body.while.body_crit_edge:
; CHECK-SAME:  ; preds = %while.body
; CHECK-NEXT:    %b.addr.tail.cpy1 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* %2, %__cheriseed_cap_t* %incdec.ptr, i64 0)
; CHECK-NEXT:    br label %while.body

; CHECK-LABEL: while.end:
; CHECK-SAME:  ; preds = %while.body.while.end_crit_edge, %entry.while.end_crit_edge
while.end:
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; Case when a PHINode is split into multiple instructions.

; CHECK-LABEL: @split_phinode
define void @split_phinode(i8 %v) {
; CHECK-NEXT:  entry
entry:
; CHECK-NEXT:  %tobool = icmp eq i8 %v, 0
  %tobool = icmp eq i8 %v, 0
; CHECK-NEXT:  %x = inttoptr i8 3 to i8*
  %x = inttoptr i8 3 to i8*
; CHECK-NEXT:  br i1 %tobool, label %a, label %entry.exit_crit_edge
  br i1 %tobool, label %a, label %exit

; CHECK-LABEL: entry.exit_crit_edge:
; CHECK-SAME:  ; preds = %entry
; CHECK-NEXT:    br label %exit

; CHECK-LABEL: a:
; CHECK-SAME:  ; preds = %entry
a:
; CHECK-NEXT:  %tobool2 = icmp eq i8 %v, 1
  %tobool2 = icmp eq i8 %v, 1
; CHECK-NEXT:  br i1 %tobool2, label %b, label %a.exit_crit_edge
  br i1 %tobool2, label %b, label %exit

; CHECK-LABEL: a.exit_crit_edge:
; CHECK-SAME:  ; preds = %a
; CHECK-NEXT:    %0 = inttoptr i64 1 to i8*
; CHECK-NEXT:    br label %exit

; CHECK-LABEL: b:
; CHECK-SAME:  ; preds = %a
b:
; CHECK-NEXT:  %1 = inttoptr i8 2 to i8*
; CHECK-NEXT:  %2 = inttoptr i64 4 to i8*
; CHECK-NEXT:  br label %exit
  br label %exit

; CHECK-LABEL: exit:
; CHECK-SAME:  ; preds = %b, %a.exit_crit_edge, %entry.exit_crit_edge
exit:
; CHECK-NEXT:  %phi0 = phi i8* [ %0, %a.exit_crit_edge ], [ %x, %entry.exit_crit_edge ], [ %1, %b ]
  %phi0 = phi i8* [ inttoptr (i64 1 to i8*), %a ], [ %x, %entry ], [ inttoptr (i8 2 to i8*), %b ]
; CHECK-NEXT:  %phi1 = phi i8* [ %2, %b ], [ %x, %a.exit_crit_edge ], [ %x, %entry.exit_crit_edge ]
  %phi1 = phi i8* [ inttoptr (i64 4 to i8*), %b ], [ %x, %a ], [ %x, %entry ]
; CHECK-NEXT:  br label %exit2
  br label %exit2
; CHECK-LABEL: exit2:
; CHECK-SAME:  ; preds = %exit
exit2:
; CHECK-NEXT:  %phi2 = phi i8* [ %x, %exit ]
  %phi2 = phi i8* [ %x, %exit ]
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; Complex CFG: when BasicBlocks processed linearly, there could be issues
; when a block uses a value from a predecessor.
;
; entry --> end <-.
; '->.--> inc --->'<--.
;    |     '-> body --'
;    '----------'

; CHECK-LABEL: @complex_cfg
define void @complex_cfg(i1 %bool) {
; CHECK-LABEL: entry:
entry:
; CHECK-NEXT:  br i1 %bool, label %entry.inc_crit_edge, label %entry.end_crit_edge
  br i1 %bool, label %inc, label %end

; CHECK-LABEL: entry.end_crit_edge:
; CHECK-SAME:  ; preds = %entry
; CHECK-NEXT:    br label %end

; CHECK-LABEL: entry.inc_crit_edge:
; CHECK-SAME:  ; preds = %entry
; CHECK-NEXT:    br label %inc

; CHECK-LABEL: body:
; CHECK-SAME:  ; preds = %inc
body:
; CHECK-NEXT:  %body_val_1 = add i8 %inc_val_1, 1
  %body_val_1 = add i8 %inc_val_1, 1
; CHECK-NEXT:  %body_val_2 = add i64 %inc_val_2, 1
  %body_val_2 = add i64 %inc_val_2, 1
; CHECK-NEXT:  br i1 %bool, label %body.end_crit_edge, label %body.inc_crit_edge
  br i1 %bool, label %end, label %inc

; CHECK-LABEL: body.inc_crit_edge:
; CHECK-SAME:  ; preds = %body
; CHECK-NEXT:    br label %inc

; CHECK-LABEL: body.end_crit_edge:
; CHECK-SAME:  ; preds = %body
; CHECK-NEXT:    br label %end

; CHECK-LABEL: inc:
; CHECK-SAME:  ; preds = %body.inc_crit_edge, %entry.inc_crit_edge
inc:
; CHECK-NEXT:  %inc_val_1 = phi i8 [ %body_val_1, %body.inc_crit_edge ], [ undef, %entry.inc_crit_edge ]
  %inc_val_1 = phi i8 [ %body_val_1, %body ], [ undef, %entry ]
; CHECK-NEXT:  %inc_val_2 = phi i64 [ %body_val_2, %body.inc_crit_edge ], [ undef, %entry.inc_crit_edge ]
  %inc_val_2 = phi i64 [ %body_val_2, %body ], [ undef, %entry ]
; CHECK-NEXT:  br i1 %bool, label %body, label %inc.end_crit_edge
  br i1 %bool, label %body, label %end

; CHECK-LABEL: inc.end_crit_edge:
; CHECK-SAME:  ; preds = %inc
; CHECK-NEXT:    br label %end

; CHECK-LABEL: end:
; CHECK-SAME:  ; preds = %inc.end_crit_edge, %body.end_crit_edge, %entry.end_crit_edge
end:
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; Regression test when phi's value is used in a store.

; CHECK-LABEL: @store_regression
define void @store_regression(i1 %bool, i8 addrspace(200)* %a , i8 addrspace(200)* %b) {
; CHECK-LABEL: entry:
entry:
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %0 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  br i1 %bool, label %l1, label %entry.l2_crit_edge
  br i1 %bool, label %l1, label %l2

; CHECK-LABEL: entry.l2_crit_edge:
; CHECK-NEXT:    %phi.tail.cpy = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* %0, %__cheriseed_cap_t* %a, i64 0)
; CHECK-NEXT:  br label %l2

; CHECK-LABEL: l1:
l1:
; CHECK-NEXT:  %phi.tail.cpy1 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:    %__cheriseed_cap_t* %1, %__cheriseed_cap_t* %b, i64 0)
; CHECK-NEXT:  br label %l2
  br label %l2

; CHECK-LABEL: l2:
l2:
; CHECK-NEXT:  %phi = phi %__cheriseed_cap_t* [ %phi.tail.cpy, %entry.l2_crit_edge ], [ %phi.tail.cpy1, %l1 ]
  %phi = phi i8 addrspace(200)* [ %a, %entry ], [ %b, %l1 ]
; This was faulty.
; CHECK-NEXT:  %2 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %phi, i64 1, i32 8, i64 0)
; CHECK-NEXT:  %3 = inttoptr i64 %2 to i8*
; CHECK-NEXT:  store i8 42, i8* %3
; CHECK-NEXT:  call void @__cheriseed_check_access_end(i64 %2, i64 1)
  store i8 42, i8 addrspace(200)* %phi
; CHECK-NEXT:  br label %end
  br label %end

; CHECK-LABEL: end:
end:
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; Regression test for when a __cheriseed_cap_t * is undef.

define void @capability_is_undef(i1 %bool) {
; CHECK-LABEL: entry:
entry:
  br i1 %bool, label %l1, label %l2

; CHECK-LABEL: l1:
l1:
  br label %l2

; CHECK-LABEL: l2:
l2:
; CHECK-NEXT:  %phi = phi %__cheriseed_cap_t* [ null, %entry.l2_crit_edge ], [ null, %l1 ]
  %phi = phi i8 addrspace(200)* [ undef, %entry ], [ undef, %l1 ]
; CHECK-NEXT:  br label %end
  br label %end

; CHECK-LABEL: end:
end:
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; Regression test for the order of PHI copies.
; The order of the emitted '__cheriseed_copy_cap_with_offset' should match the
; order of the PHI nodes apeparing in the IR

; CHECK-LABEL: @phi_copy_order
define void @phi_copy_order(i1 %bool, i8 addrspace(200)* %a , i8 addrspace(200)* %b) {
entry:
  br i1 %bool, label %l1, label %l2

; CHECK-LABEL: entry.l2_crit_edge:
; The order of copies was reversed.
; CHECK-NEXT: %phi1.tail.cpy = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:   %__cheriseed_cap_t* %0, %__cheriseed_cap_t* %a, i64 0)
; CHECK-NEXT: %phi2.tail.cpy = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:   %__cheriseed_cap_t* %2, %__cheriseed_cap_t* %a, i64 0)

; CHECK-LABEL: l1:
l1:
; The order of copies was reversed.
; CHECK-NEXT: %phi1.tail.cpy1 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:   %__cheriseed_cap_t* %1, %__cheriseed_cap_t* %b, i64 0)
; CHECK-NEXT: %phi2.tail.cpy2 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:   %__cheriseed_cap_t* %3, %__cheriseed_cap_t* %b, i64 0)
  br label %l2

; CHECK-LABEL: l2:
l2:
; CHECK-NEXT: %phi1 = phi %__cheriseed_cap_t* [ %phi1.tail.cpy, %entry.l2_crit_edge ], [ %phi1.tail.cpy1, %l1 ]
; CHECK-NEXT: %phi2 = phi %__cheriseed_cap_t* [ %phi2.tail.cpy, %entry.l2_crit_edge ], [ %phi2.tail.cpy2, %l1 ]
  %phi1 = phi i8 addrspace(200)* [ %a, %entry ], [ %b, %l1 ]
  %phi2 = phi i8 addrspace(200)* [ %a, %entry ], [ %b, %l1 ]
; CHECK-NEXT:  br label %end
  br label %end

end:
  ret void
}

; ------------------------------------------------------------------------------
