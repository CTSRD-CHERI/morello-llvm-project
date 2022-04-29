; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------

; CHECK-LABEL: define void @cheri_intrinsics(%__cheriseed_cap_t* %0, i64 %1)
define void @cheri_intrinsics(i8 addrspace(200)* %0, i64 %1) addrspace(200) {
; CHECK-NEXT:  %3 = tail call i64 @__cheriseed_length_get(%__cheriseed_cap_t* %0)
  %3 = call i64 @llvm.cheri.cap.length.get.i64(i8 addrspace(200)* %0)
; CHECK-NEXT:  %4 = tail call i64 @__cheriseed_base_get(%__cheriseed_cap_t* %0)
  %4 = call i64 @llvm.cheri.cap.base.get.i64(i8 addrspace(200)* %0)
; CHECK-NEXT:  %5 = tail call i64 @__cheriseed_copy_from_high(%__cheriseed_cap_t* %0)
  %5 = call i64 @llvm.cheri.cap.copy.from.high.i64(i8 addrspace(200)* %0)
; CHECK-NEXT:  %6 = tail call i64 @__cheriseed_perms_get(%__cheriseed_cap_t* %0)
  %6 = call i64 @llvm.cheri.cap.perms.get.i64(i8 addrspace(200)* %0)
; CHECK-NEXT:  %7 = tail call i64 @__cheriseed_flags_get(%__cheriseed_cap_t* %0)
  %7 = call i64 @llvm.cheri.cap.flags.get.i64(i8 addrspace(200)* %0)
; CHECK-NEXT:  %8 = tail call i64 @__cheriseed_type_get(%__cheriseed_cap_t* %0)
  %8 = call i64 @llvm.cheri.cap.type.get.i64(i8 addrspace(200)* %0)
; CHECK-NEXT:  %9 = tail call i1 @__cheriseed_tag_get(%__cheriseed_cap_t* %0)
  %9 = call i1 @llvm.cheri.cap.tag.get(i8 addrspace(200)* %0)
; CHECK-NEXT:  %10 = tail call i1 @__cheriseed_sealed_get(%__cheriseed_cap_t* %0)
  %10 = call i1 @llvm.cheri.cap.sealed.get(i8 addrspace(200)* %0)
; CHECK-NEXT:  tail call void @__cheriseed_perms_check(%__cheriseed_cap_t* %0, i64 1)
  call void @llvm.cheri.cap.perms.check.i64(i8 addrspace(200)* %0, i64 1)
; CHECK-NEXT:  tail call void @__cheriseed_type_check(%__cheriseed_cap_t* %0, %__cheriseed_cap_t* %0)
  call void @llvm.cheri.cap.type.check(i8 addrspace(200)* %0, i8 addrspace(200)* %0)
; CHECK-NEXT:  %11 = tail call i1 @__cheriseed_equal_exact(%__cheriseed_cap_t* %0, %__cheriseed_cap_t* %0)
  %11 = call i1 @llvm.cheri.cap.equal.exact(i8 addrspace(200)* %0, i8 addrspace(200)* %0)
; CHECK-NEXT:  %12 = tail call i1 @__cheriseed_subset_test(%__cheriseed_cap_t* %0, %__cheriseed_cap_t* %0)
  %12 = call i1 @llvm.cheri.cap.subset.test(i8 addrspace(200)* %0, i8 addrspace(200)* %0)
; CHECK-NEXT:  %13 = tail call i64 @__cheriseed_offset_get(%__cheriseed_cap_t* %0)
  %13 = call i64 @llvm.cheri.cap.offset.get(i8 addrspace(200)* %0)
; CHECK-NEXT:  %14 = tail call i64 @__cheriseed_diff(%__cheriseed_cap_t* %0, %__cheriseed_cap_t* %0)
  %14 = call i64 @llvm.cheri.cap.diff(i8 addrspace(200)* %0, i8 addrspace(200)* %0)
; CHECK-NEXT:  %15 = tail call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %0)
  %15 = call i64 @llvm.cheri.cap.address.get(i8 addrspace(200)* %0)
; CHECK-NEXT:  %16 = tail call i64 @__cheriseed_to_pointer(%__cheriseed_cap_t* %0, %__cheriseed_cap_t* %0)
  %16 = call i64 @llvm.cheri.cap.to.pointer(i8 addrspace(200)* %0, i8 addrspace(200)* %0)
; CHECK-NEXT:  %17 = tail call i64 @__cheriseed_load_tags(%__cheriseed_cap_t* %0)
  %17 = call i64 @llvm.cheri.cap.load.tags.i64.p200i8(i8 addrspace(200)* %0)
; CHECK-NEXT:  %18 = tail call i64 @__cheriseed_round_representable_length(i64 1)
  %18 = call i64 @llvm.cheri.round.representable.length.i64(i64 1)
; CHECK-NEXT:  %19 = tail call i64 @__cheriseed_representable_alignment_mask(i64 1)
  %19 = call i64 @llvm.cheri.representable.alignment.mask.i64(i64 1)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cheri_cap_copy_to_high_i64
define void @cheri_cap_copy_to_high_i64(i8 addrspace(200)* %0, i64 %1) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %3 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %4 = tail call %__cheriseed_cap_t* @__cheriseed_copy_to_high(%__cheriseed_cap_t* %3, %__cheriseed_cap_t* %0, i64 %1)
  %3 = call i8 addrspace(200)* @llvm.cheri.cap.copy.to.high.i64(i8 addrspace(200)* %0, i64 %1)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cheri.cap.perms.and.i64
define void @cheri.cap.perms.and.i64(i8 addrspace(200)* %0, i64 %1) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %3 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %4 = tail call %__cheriseed_cap_t* @__cheriseed_perms_and(%__cheriseed_cap_t* %3, %__cheriseed_cap_t* %0, i64 %1)
  %3 = call i8 addrspace(200)* @llvm.cheri.cap.perms.and.i64(i8 addrspace(200)* %0, i64 %1)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cheri.cap.flags.set.i64
define void @cheri.cap.flags.set.i64(i8 addrspace(200)* %0, i64 %1) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %3 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %4 = tail call %__cheriseed_cap_t* @__cheriseed_flags_set(%__cheriseed_cap_t* %3, %__cheriseed_cap_t* %0, i64 %1)
  %3 = call i8 addrspace(200)* @llvm.cheri.cap.flags.set.i64(i8 addrspace(200)* %0, i64 %1)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cheri.cap.bounds.set.i64
define void @cheri.cap.bounds.set.i64(i8 addrspace(200)* %0, i64 %1) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %3 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %4 = tail call %__cheriseed_cap_t* @__cheriseed_bounds_set(%__cheriseed_cap_t* %3, %__cheriseed_cap_t* %0, i64 %1)
  %3 = call i8 addrspace(200)* @llvm.cheri.cap.bounds.set.i64(i8 addrspace(200)* %0, i64 %1)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cheri.cap.bounds.set.exact.i64
define void @cheri.cap.bounds.set.exact.i64(i8 addrspace(200)* %0, i64 %1) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %3 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %4 = tail call %__cheriseed_cap_t* @__cheriseed_bounds_set_exact(%__cheriseed_cap_t* %3, %__cheriseed_cap_t* %0, i64 %1)
  %3 = call i8 addrspace(200)* @llvm.cheri.cap.bounds.set.exact.i64(i8 addrspace(200)* %0, i64 %1)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cheri.cap.tag.clear
define void @cheri.cap.tag.clear(i8 addrspace(200)* %0) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_tag_clear(%__cheriseed_cap_t* %2, %__cheriseed_cap_t* %0)
  %2 = call i8 addrspace(200)* @llvm.cheri.cap.tag.clear(i8 addrspace(200)* %0)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cheri.cap.seal
define void @cheri.cap.seal(i8 addrspace(200)* %0) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_seal(%__cheriseed_cap_t* %2, %__cheriseed_cap_t* %0, %__cheriseed_cap_t* %0)
  %2 = call i8 addrspace(200)* @llvm.cheri.cap.seal(i8 addrspace(200)* %0, i8 addrspace(200)* %0)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cheri.cap.conditional.seal
define void @cheri.cap.conditional.seal(i8 addrspace(200)* %0) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_conditional_seal(%__cheriseed_cap_t* %2, %__cheriseed_cap_t* %0, %__cheriseed_cap_t* %0)
  %2 = call i8 addrspace(200)* @llvm.cheri.cap.conditional.seal(i8 addrspace(200)* %0, i8 addrspace(200)* %0)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cheri.cap.unseal
define void @cheri.cap.unseal(i8 addrspace(200)* %0) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_unseal(%__cheriseed_cap_t* %2, %__cheriseed_cap_t* %0, %__cheriseed_cap_t* %0)
  %2 = call i8 addrspace(200)* @llvm.cheri.cap.unseal(i8 addrspace(200)* %0, i8 addrspace(200)* %0)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cheri.cap.seal.entry
define void @cheri.cap.seal.entry(i8 addrspace(200)* %0) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_seal_entry(%__cheriseed_cap_t* %2, %__cheriseed_cap_t* %0)
  %2 = call i8 addrspace(200)* @llvm.cheri.cap.seal.entry(i8 addrspace(200)* %0)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cheri.stack.cap.get
define void @cheri.stack.cap.get(i8 addrspace(200)* %0) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_stack_cap_get(%__cheriseed_cap_t* %2)
  %2 = call i8 addrspace(200)* @llvm.cheri.stack.cap.get()
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cheri.ddc.get
define void @cheri.ddc.get(i8 addrspace(200)* %0) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_ddc_get(%__cheriseed_cap_t* %2)
  %2 = call i8 addrspace(200)* @llvm.cheri.ddc.get()
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cheri.pcc.get
define void @cheri.pcc.get(i8 addrspace(200)* %0) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_pcc_get(%__cheriseed_cap_t* %2)
  %2 = call i8 addrspace(200)* @llvm.cheri.pcc.get()
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cheri.cap.offset.set.i64
define void @cheri.cap.offset.set.i64(i8 addrspace(200)* %0) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_offset_set(%__cheriseed_cap_t* %2, %__cheriseed_cap_t* %0, i64 1)
  %2 = call i8 addrspace(200)* @llvm.cheri.cap.offset.set.i64(i8 addrspace(200)* %0, i64 1)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cheri.cap.address.set.i64
define void @cheri.cap.address.set.i64(i8 addrspace(200)* %0) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_address_set(%__cheriseed_cap_t* %2, %__cheriseed_cap_t* %0, i64 1)
  %2 = call i8 addrspace(200)* @llvm.cheri.cap.address.set.i64(i8 addrspace(200)* %0, i64 1)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cheri.cap.from.pointer.i64
define void @cheri.cap.from.pointer.i64(i8 addrspace(200)* %0) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_address_set(%__cheriseed_cap_t* %2, %__cheriseed_cap_t* %0, i64 1)
  %2 = call i8 addrspace(200)* @llvm.cheri.cap.from.pointer.i64(i8 addrspace(200)* %0, i64 1)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cheri.cap.from.pointer.nonnull.zero.i64
define void @cheri.cap.from.pointer.nonnull.zero.i64(i8 addrspace(200)* %0) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_address_set(%__cheriseed_cap_t* %2, %__cheriseed_cap_t* %0, i64 1)
  %2 = call i8 addrspace(200)* @llvm.cheri.cap.from.pointer.nonnull.zero.i64(i8 addrspace(200)* %0, i64 1)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cheri.cap.build
define void @cheri.cap.build(i8 addrspace(200)* %0) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_build(%__cheriseed_cap_t* %2, %__cheriseed_cap_t* %0, %__cheriseed_cap_t* %0)
  %2 = call i8 addrspace(200)* @llvm.cheri.cap.build(i8 addrspace(200)* %0, i8 addrspace(200)* %0)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cheri.cap.type.copy
define void @cheri.cap.type.copy(i8 addrspace(200)* %0) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_type_copy(%__cheriseed_cap_t* %2, %__cheriseed_cap_t* %0, %__cheriseed_cap_t* %0)
  %2 = call i8 addrspace(200)* @llvm.cheri.cap.type.copy(i8 addrspace(200)* %0, i8 addrspace(200)* %0)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cheri.bounded.stack.cap.i64
define void @cheri.bounded.stack.cap.i64(i8 addrspace(200)* %0) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_bounded_stack_cap(%__cheriseed_cap_t* %2, %__cheriseed_cap_t* %0, i64 1)
  %2 = call i8 addrspace(200)* @llvm.cheri.bounded.stack.cap.i64(i8 addrspace(200)* %0, i64 1)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-NOT: @llvm.cheri.cap.length.get.i64
declare i64 @llvm.cheri.cap.length.get.i64(i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.cap.base.get.i64
declare i64 @llvm.cheri.cap.base.get.i64(i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.cap.copy.from.high.i64
declare i64 @llvm.cheri.cap.copy.from.high.i64(i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.cap.copy.to.high.i64
declare i8 addrspace(200)* @llvm.cheri.cap.copy.to.high.i64(i8 addrspace(200)*, i64)
; CHECK-NOT: @llvm.cheri.cap.perms.and.i64
declare i8 addrspace(200)* @llvm.cheri.cap.perms.and.i64(i8 addrspace(200)*, i64)
; CHECK-NOT: @llvm.cheri.cap.perms.get.i64
declare i64 @llvm.cheri.cap.perms.get.i64(i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.cap.flags.set.i64
declare i8 addrspace(200)* @llvm.cheri.cap.flags.set.i64(i8 addrspace(200)*, i64)
; CHECK-NOT: @llvm.cheri.cap.flags.get.i64
declare i64 @llvm.cheri.cap.flags.get.i64(i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.cap.bounds.set.i64
declare i8 addrspace(200)* @llvm.cheri.cap.bounds.set.i64(i8 addrspace(200)*, i64)
; CHECK-NOT: @llvm.cheri.cap.bounds.set.exact.i64
declare i8 addrspace(200)* @llvm.cheri.cap.bounds.set.exact.i64(i8 addrspace(200)*, i64)
; CHECK-NOT: @llvm.cheri.cap.type.get.i64
declare i64 @llvm.cheri.cap.type.get.i64(i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.cap.tag.get
declare i1 @llvm.cheri.cap.tag.get(i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.cap.sealed.get
declare i1 @llvm.cheri.cap.sealed.get(i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.cap.tag.clear
declare i8 addrspace(200)* @llvm.cheri.cap.tag.clear(i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.cap.seal
declare i8 addrspace(200)* @llvm.cheri.cap.seal(i8 addrspace(200)*, i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.cap.conditional.seal
declare i8 addrspace(200)* @llvm.cheri.cap.conditional.seal(i8 addrspace(200)*, i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.cap.unseal
declare i8 addrspace(200)* @llvm.cheri.cap.unseal(i8 addrspace(200)*, i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.cap.seal.entry
declare i8 addrspace(200)* @llvm.cheri.cap.seal.entry(i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.cap.perms.check.i64
declare void @llvm.cheri.cap.perms.check.i64(i8 addrspace(200)*, i64)
; CHECK-NOT: @llvm.cheri.cap.type.check
declare void @llvm.cheri.cap.type.check(i8 addrspace(200)*, i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.cap.equal.exact
declare i1 @llvm.cheri.cap.equal.exact(i8 addrspace(200)*, i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.cap.subset.test
declare i1 @llvm.cheri.cap.subset.test(i8 addrspace(200)*, i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.stack.cap.get
declare i8 addrspace(200)* @llvm.cheri.stack.cap.get()
; CHECK-NOT: @llvm.cheri.ddc.get
declare i8 addrspace(200)* @llvm.cheri.ddc.get()
; CHECK-NOT: @llvm.cheri.pcc.get
declare i8 addrspace(200)* @llvm.cheri.pcc.get()
; CHECK-NOT: @llvm.cheri.cap.offset.set.i64
declare i8 addrspace(200)* @llvm.cheri.cap.offset.set.i64(i8 addrspace(200)*, i64)
; CHECK-NOT: @llvm.cheri.cap.offset.get
declare i64 @llvm.cheri.cap.offset.get(i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.cap.diff
declare i64 @llvm.cheri.cap.diff(i8 addrspace(200)*, i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.cap.address.get
declare i64 @llvm.cheri.cap.address.get(i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.cap.address.set.i64
declare i8 addrspace(200)* @llvm.cheri.cap.address.set.i64(i8 addrspace(200)*, i64)
; CHECK-NOT: @llvm.cheri.cap.to.pointer
declare i64 @llvm.cheri.cap.to.pointer(i8 addrspace(200)*, i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.cap.from.pointer.i64
declare i8 addrspace(200)* @llvm.cheri.cap.from.pointer.i64(i8 addrspace(200)*, i64)
; CHECK-NOT: @llvm.cheri.cap.from.pointer.nonnull.zero.i64
declare i8 addrspace(200)* @llvm.cheri.cap.from.pointer.nonnull.zero.i64(i8 addrspace(200)*, i64)
; CHECK-NOT: @llvm.cheri.cap.build
declare i8 addrspace(200)* @llvm.cheri.cap.build(i8 addrspace(200)*, i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.cap.type.copy
declare i8 addrspace(200)* @llvm.cheri.cap.type.copy(i8 addrspace(200)*, i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.cap.load.tags.i64.p200i8
declare i64 @llvm.cheri.cap.load.tags.i64.p200i8(i8 addrspace(200)*)
; CHECK-NOT: @llvm.cheri.round.representable.length.i64
declare i64 @llvm.cheri.round.representable.length.i64(i64)
; CHECK-NOT: @llvm.cheri.representable.alignment.mask.i64
declare i64 @llvm.cheri.representable.alignment.mask.i64(i64)
; CHECK-NOT: @llvm.cheri.bounded.stack.cap.i64
declare i8 addrspace(200)* @llvm.cheri.bounded.stack.cap.i64(i8 addrspace(200)*, i64)

; CHECK: declare i64 @__cheriseed_length_get(%__cheriseed_cap_t*)
; CHECK: declare i64 @__cheriseed_base_get(%__cheriseed_cap_t*)
; CHECK: declare i64 @__cheriseed_copy_from_high(%__cheriseed_cap_t*)
; CHECK: declare i64 @__cheriseed_perms_get(%__cheriseed_cap_t*)
; CHECK: declare i64 @__cheriseed_flags_get(%__cheriseed_cap_t*)
; CHECK: declare i64 @__cheriseed_type_get(%__cheriseed_cap_t*)
; CHECK: declare i1 @__cheriseed_tag_get(%__cheriseed_cap_t*)
; CHECK: declare i1 @__cheriseed_sealed_get(%__cheriseed_cap_t*)
; CHECK: declare void @__cheriseed_perms_check(%__cheriseed_cap_t*, i64)
; CHECK: declare void @__cheriseed_type_check(%__cheriseed_cap_t*, %__cheriseed_cap_t*)
; CHECK: declare i1 @__cheriseed_equal_exact(%__cheriseed_cap_t*, %__cheriseed_cap_t*)
; CHECK: declare i1 @__cheriseed_subset_test(%__cheriseed_cap_t*, %__cheriseed_cap_t*)
; CHECK: declare i64 @__cheriseed_offset_get(%__cheriseed_cap_t*)
; CHECK: declare i64 @__cheriseed_diff(%__cheriseed_cap_t*, %__cheriseed_cap_t*)
; CHECK: declare i64 @__cheriseed_address_get(%__cheriseed_cap_t*)
; CHECK: declare i64 @__cheriseed_to_pointer(%__cheriseed_cap_t*, %__cheriseed_cap_t*)
; CHECK: declare i64 @__cheriseed_load_tags(%__cheriseed_cap_t*)
; CHECK: declare i64 @__cheriseed_round_representable_length(i64)
; CHECK: declare i64 @__cheriseed_representable_alignment_mask(i64)

; CHECK: declare %__cheriseed_cap_t* @__cheriseed_copy_to_high(%__cheriseed_cap_t*, %__cheriseed_cap_t*, i64)
; CHECK: declare %__cheriseed_cap_t* @__cheriseed_perms_and(%__cheriseed_cap_t*, %__cheriseed_cap_t*, i64)
; CHECK: declare %__cheriseed_cap_t* @__cheriseed_flags_set(%__cheriseed_cap_t*, %__cheriseed_cap_t*, i64)
; CHECK: declare %__cheriseed_cap_t* @__cheriseed_bounds_set(%__cheriseed_cap_t*, %__cheriseed_cap_t*, i64)
; CHECK: declare %__cheriseed_cap_t* @__cheriseed_bounds_set_exact(%__cheriseed_cap_t*, %__cheriseed_cap_t*, i64)
; CHECK: declare %__cheriseed_cap_t* @__cheriseed_tag_clear(%__cheriseed_cap_t*, %__cheriseed_cap_t*)
; CHECK: declare %__cheriseed_cap_t* @__cheriseed_seal(%__cheriseed_cap_t*, %__cheriseed_cap_t*, %__cheriseed_cap_t*)
; CHECK: declare %__cheriseed_cap_t* @__cheriseed_conditional_seal(%__cheriseed_cap_t*, %__cheriseed_cap_t*, %__cheriseed_cap_t*)
; CHECK: declare %__cheriseed_cap_t* @__cheriseed_unseal(%__cheriseed_cap_t*, %__cheriseed_cap_t*, %__cheriseed_cap_t*)
; CHECK: declare %__cheriseed_cap_t* @__cheriseed_seal_entry(%__cheriseed_cap_t*, %__cheriseed_cap_t*)
; CHECK: declare %__cheriseed_cap_t* @__cheriseed_stack_cap_get(%__cheriseed_cap_t*)
; CHECK: declare %__cheriseed_cap_t* @__cheriseed_ddc_get(%__cheriseed_cap_t*)
; CHECK: declare %__cheriseed_cap_t* @__cheriseed_pcc_get(%__cheriseed_cap_t*)
; CHECK: declare %__cheriseed_cap_t* @__cheriseed_offset_set(%__cheriseed_cap_t*, %__cheriseed_cap_t*, i64)
; CHECK: declare %__cheriseed_cap_t* @__cheriseed_address_set(%__cheriseed_cap_t*, %__cheriseed_cap_t*, i64)
; CHECK: declare %__cheriseed_cap_t* @__cheriseed_build(%__cheriseed_cap_t*, %__cheriseed_cap_t*, %__cheriseed_cap_t*)
; CHECK: declare %__cheriseed_cap_t* @__cheriseed_type_copy(%__cheriseed_cap_t*, %__cheriseed_cap_t*, %__cheriseed_cap_t*)
; CHECK: declare %__cheriseed_cap_t* @__cheriseed_bounded_stack_cap(%__cheriseed_cap_t*, %__cheriseed_cap_t*, i64)
