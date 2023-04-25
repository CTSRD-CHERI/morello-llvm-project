; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-pf200:128:128:128:64-S128-A200-P200-G200"
target triple = "x86_64-unknown-linux-gnu"

; ------------------------------------------------------------------------------
; Check that blockaddress translates properly.

; CHECK-LABEL: @__cheriseed_shadowed_global_blockaddresses = global [2 x %__cheriseed_cap_t]
; CHECK-SAME:     zeroinitializer, align 16
@blockaddresses = addrspace(200) constant [2 x i8 addrspace(200)*] [
  i8 addrspace(200)* blockaddress(@blockaddress, %BB1),
  i8 addrspace(200)* blockaddress(@blockaddress, %BB2)
], align 16

; CHECK-LABEL: @blockaddress
define void @blockaddress(i1 %cond) addrspace(200) {
  br i1 %cond, label %BB1, label %BB2
; CHECK-LABEL: BB1:
BB1:
  br label %BB2
; CHECK-LABEL: BB2:
BB2:
  ret void
}

; ------------------------------------------------------------------------------

; CHECK-LABEL: @blockaddress_indirect
define void @blockaddress_indirect() addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = call %__cheriseed_cap_t* @__cheriseed_generic_cap_init(%__cheriseed_cap_t* %2,
; CHECK-SAME:     i64 ptrtoint (i8* blockaddress(@blockaddress_indirect_func, %BB1) to i64), i64 1, i32 60)
; CHECK-NEXT:  %indirect = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* %1,
; CHECK-SAME:     %__cheriseed_cap_t* %3, i64 0)
  %indirect = getelementptr i8, i8 addrspace(200)* blockaddress(@blockaddress_indirect_func, %BB1), i64 0
; CHECK-NEXT:  ret void
  ret void
}

define void @blockaddress_indirect_func() addrspace(200) {
  br label %BB1
BB1:
  ret void
}

; ------------------------------------------------------------------------------

; CHECK-LABEL: define internal void @__cheriseed_initializer_blockaddresses()
; CHECK-NEXT:    %1 = call %__cheriseed_cap_t* @__cheriseed_generic_cap_init(
; CHECK-SAME:      %__cheriseed_cap_t* getelementptr inbounds ([2 x %__cheriseed_cap_t],
; CHECK-SAME:        [2 x %__cheriseed_cap_t]* @__cheriseed_shadowed_global_blockaddresses, i32 0, i64 0),
; CHECK-SAME:      i64 ptrtoint (i8* blockaddress(@blockaddress, %BB1) to i64), i64 1, i32 60)
; CHECK-NEXT:    %2 = call %__cheriseed_cap_t* @__cheriseed_generic_cap_init(
; CHECK-SAME:      %__cheriseed_cap_t* getelementptr inbounds ([2 x %__cheriseed_cap_t],
; CHECK-SAME:        [2 x %__cheriseed_cap_t]* @__cheriseed_shadowed_global_blockaddresses, i32 0, i64 1),
; CHECK-SAME:      i64 ptrtoint (i8* blockaddress(@blockaddress, %BB2) to i64), i64 1, i32 60)
; CHECK-NEXT:    ret void

; ------------------------------------------------------------------------------
