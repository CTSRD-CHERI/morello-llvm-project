; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------
; Test memcpy and generic intrinsic handling scenarios.

; CHECK-NOT: @llvm.memcpy.p0i8.p0i8.i64
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly, i8* noalias nocapture readonly, i64, i1 immarg)

; CHECK-NOT: @llvm.memcpy.p200i8.p200i8.i64
declare void @llvm.memcpy.p200i8.p200i8.i64(i8 addrspace(200)* noalias nocapture writeonly, i8 addrspace(200)* noalias nocapture readonly, i64, i1 immarg)

; CHECK-LABEL: @int_memcpy
define void @int_memcpy(i8* %dest, i8* %src, i64 %n) {
; CHECK-NEXT:  %1 = call i8* @memcpy(i8* align 1 %dest, i8* align 1 %src, i64 %n)
  tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 1 %dest, i8* align 1 %src, i64 %n, i1 false)
; CHECK-NEXT:  %2 = call i8* @memcpy(i8* align 1 %dest, i8* align 1 %src, i64 %n)
  tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 1 %dest, i8* align 1 %src, i64 %n, i1 true)
; CHECK-NEXT:  %3 = call i8* @memcpy(i8* align 1 %dest, i8* align 1 %src, i64 1)
  tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 1 %dest, i8* align 1 %src, i64 1, i1 false)
; CHECK-NEXT:  %4 = call i8* @memcpy(i8* align 4 %dest, i8* align 4 %src, i64 %n)
  tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 4 %dest, i8* align 4 %src, i64 %n, i1 false)
; CHECK-NEXT:  %5 = call i8* @memcpy(i8* align 4 %dest, i8* align 4 %src, i64 %n)
  %1 = call i8* @memcpy(i8* align 4 %dest, i8* align 4 %src, i64 %n)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @int_memcpy_c
define void @int_memcpy_c(i8 addrspace(200)* %dest, i8 addrspace(200)* %src, i64 %n) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %2 = call %__cheriseed_cap_t* @memcpy_c(%__cheriseed_cap_t* returned %dest,
; CHECK-SAME:     %__cheriseed_cap_t* %dest, %__cheriseed_cap_t* %src, i64 %n)
  call void @llvm.memcpy.p200i8.p200i8.i64(i8 addrspace(200)* %dest, i8 addrspace(200)* %src, i64 %n, i1 false)
; CHECK-NEXT:  %3 = call %__cheriseed_cap_t* @memcpy_c(%__cheriseed_cap_t* returned align 16 %1,
; CHECK-SAME:     %__cheriseed_cap_t* %dest, %__cheriseed_cap_t* %src, i64 %n)
  %1 = call i8 addrspace(200)* @memcpy_c(i8 addrspace(200)* %dest, i8 addrspace(200)* %src, i64 %n)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK: declare i8* @memcpy(i8*, i8*, i64)
declare i8* @memcpy(i8*, i8*, i64)

; CHECK: declare %__cheriseed_cap_t* @memcpy_c(%__cheriseed_cap_t* returned align 16,
; CHECK-SAME:     %__cheriseed_cap_t*, %__cheriseed_cap_t*, i64)
declare i8 addrspace(200)* @memcpy_c(i8 addrspace(200)*, i8 addrspace(200)*, i64)

; ------------------------------------------------------------------------------
; Test memset

; CHECK-LABEL: @int_memset
define void @int_memset(i8* %p, i8 addrspace(200)* %c, i8 %v) {
; CHECK-NEXT:  %1 = zext i8 %v to i32
; CHECK-NEXT:  %2 = call i8* @memset(i8* %p, i32 %1, i64 4)
  call void @llvm.memset.p0i8.i64(i8* %p, i8 %v, i64 4, i1 false)
; CHECK-NEXT:  %3 = zext i8 %v to i32
; CHECK-NEXT:  %4 = call %__cheriseed_cap_t* @memset_c(%__cheriseed_cap_t* returned %c,
; CHECK-SAME:     %__cheriseed_cap_t* %c, i32 %3, i64 4)
  call void @llvm.memset.p200i8.i64(i8 addrspace(200)* %c, i8 %v, i64 4, i1 false)
; CHECK-NEXT:  ret void
  ret void
}

declare void @llvm.memset.p0i8.i64(i8* nocapture writeonly, i8, i64, i1 immarg)
declare void @llvm.memset.p200i8.i64(i8 addrspace(200)* nocapture writeonly, i8, i64, i1 immarg)

; ------------------------------------------------------------------------------
; Test memmove

; CHECK-LABEL: @int_memmove
define void @int_memmove(i8* %p, i8 addrspace(200)* %c) {
; CHECK-NEXT:  %1 = call i8* @memmove(i8* %p, i8* %p, i64 4)
  call void @llvm.memmove.p0i8.i64(i8* %p, i8* %p, i64 4, i1 false)
; CHECK-NEXT:  %2 = call %__cheriseed_cap_t* @memmove_c(%__cheriseed_cap_t* returned %c,
; CHECK-SAME:     %__cheriseed_cap_t* %c, %__cheriseed_cap_t* %c, i64 4)
  call void @llvm.memmove.p200i8.i64(i8 addrspace(200)* %c, i8 addrspace(200)* %c, i64 4, i1 false)
; CHECK-NEXT:  ret void
  ret void
}

declare void @llvm.memmove.p0i8.i64(i8* nocapture writeonly, i8* nocapture readonly, i64, i1 immarg)
declare void @llvm.memmove.p200i8.i64(i8 addrspace(200)* nocapture writeonly, i8 addrspace(200)* nocapture readonly, i64, i1 immarg)

; ------------------------------------------------------------------------------
; Test @llvm.stacksave and @llvm.stackrestore

; CHECK-LABEL: @int_stacksave
define void @int_stacksave() {
; Default address space
; CHECK-LABEL: %s1 = call i8* @llvm.stacksave.p0i8()
  %s1 = call i8* @llvm.stacksave.p0i8()
; CHECK-NEXT:  call void @llvm.stackrestore.p0i8(i8* %s1)
  call void @llvm.stackrestore.p0i8(i8* %s1)
; Capability address space
; CHECK-LABEL: %2 = call i8* @llvm.stacksave.p0i8()
; CHECK-NEXT:  %3 = ptrtoint i8* %2 to i64
; CHECK-NEXT:  %s2 = tail call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* %1, %__cheriseed_cap_t* null, i64 %3)
  %s2 = call i8 addrspace(200)* @llvm.stacksave.p200i8()
; CHECK-NEXT:  %4 = tail call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %s2)
; CHECK-NEXT:  %5 = inttoptr i64 %4 to i8*
; CHECK-NEXT:  call void @llvm.stackrestore.p0i8(i8* %5)
  call void @llvm.stackrestore.p200i8(i8 addrspace(200)* %s2)
; CHECK-NEXT:  ret void
  ret void
}

declare i8* @llvm.stacksave.p0i8()
declare i8 addrspace(200)* @llvm.stacksave.p200i8()
declare void @llvm.stackrestore.p0i8(i8*)
declare void @llvm.stackrestore.p200i8(i8 addrspace(200)*)

; ------------------------------------------------------------------------------
; Test @llvm.returnaddress

; CHECK-LABEL: @int_returnaddress
define void @int_returnaddress() {
; Default address space
; CHECK-LABEL: %s1 = call i8* @llvm.returnaddress.p0i8(i32 0)
  %s1 = call i8* @llvm.returnaddress.p0i8(i32 0)
; Capability address space
; CHECK-LABEL: %2 = call i8* @llvm.returnaddress.p0i8(i32 0)
; CHECK-NEXT:  %3 = ptrtoint i8* %2 to i64
; CHECK-NEXT:  %s2 = tail call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* %1, %__cheriseed_cap_t* null, i64 %3)
  %s2 = call i8 addrspace(200)* @llvm.returnaddress.p200i8(i32 0)
; CHECK-NEXT:  ret void
  ret void
}

declare i8* @llvm.returnaddress.p0i8(i32 immarg)
declare i8 addrspace(200)* @llvm.returnaddress.p200i8(i32 immarg)

; ------------------------------------------------------------------------------
; Test @llvm.frameaddress

; CHECK-LABEL: @int_frameaddress
define void @int_frameaddress() {
; Default address space
; CHECK-LABEL: %s1 = call i8* @llvm.frameaddress.p0i8(i32 0)
  %s1 = call i8* @llvm.frameaddress.p0i8(i32 0)
; Capability address space
; CHECK-LABEL: %2 = call i8* @llvm.frameaddress.p0i8(i32 0)
; CHECK-NEXT:  %3 = ptrtoint i8* %2 to i64
; CHECK-NEXT:  %s2 = tail call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:      %__cheriseed_cap_t* %1, %__cheriseed_cap_t* null, i64 %3)
  %s2 = call i8 addrspace(200)* @llvm.frameaddress.p200i8(i32 0)
; CHECK-NEXT:  ret void
  ret void
}

declare i8* @llvm.frameaddress.p0i8(i32 immarg)
declare i8 addrspace(200)* @llvm.frameaddress.p200i8(i32 immarg)

; ------------------------------------------------------------------------------
; Test @llvm.thread.pointer

; CHECK-LABEL: @int_thread_pointer
define void @int_thread_pointer() {
; Default address space
; CHECK-LABEL: %s1 = call i8* @llvm.thread.pointer.p0i8()
  %s1 = call i8* @llvm.thread.pointer.p0i8()
; Capability address space
; CHECK-NEXT:  %s2 = tail call %__cheriseed_cap_t* @__cheriseed_thread_pointer(%__cheriseed_cap_t* %1)
  %s2 = call i8 addrspace(200)* @llvm.thread.pointer.p200i8()
; CHECK-NEXT:  ret void
  ret void
}

declare i8* @llvm.thread.pointer.p0i8()
declare i8 addrspace(200)* @llvm.thread.pointer.p200i8()

; ------------------------------------------------------------------------------
; Test @llvm.prefetch

; CHECK-LABEL: @int_prefetch
define void @int_prefetch(i8* %p, i8 addrspace(200)* %c) {
; Default address space
; CHECK-LABEL: call void @llvm.prefetch.p0i8(i8* %p, i32 0, i32 0, i32 0)
  call void @llvm.prefetch.p0i8(i8* %p, i32 0, i32 0, i32 0)
; Capability address space
; CHECK-NEXT:  %1 = tail call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %c)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i8*
; CHECK-NEXT:  call void @llvm.prefetch.p0i8(i8* %2, i32 0, i32 0, i32 0)
  call void @llvm.prefetch.p200i8(i8 addrspace(200)* %c, i32 0, i32 0, i32 0)
; CHECK-NEXT:  ret void
  ret void
}

declare void @llvm.prefetch.p0i8(i8*, i32 immarg, i32 immarg, i32)
declare void @llvm.prefetch.p200i8(i8 addrspace(200)*, i32 immarg, i32 immarg, i32)

; ------------------------------------------------------------------------------
