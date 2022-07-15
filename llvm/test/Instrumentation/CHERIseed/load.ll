; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------

; CHECK-LABEL: define void @load_i1(%__cheriseed_cap_t* %c)
define void @load_i1(i1 addrspace(200)* %c) addrspace(200) {
; CHECK-NEXT:  %1 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 1, i32 1)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i1*
; CHECK-NEXT:  %3 = load i1, i1* %2, align 1
  %1 = load i1, i1 addrspace(200)* %c, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @load_i8_nocap(i8* %p)
define void @load_i8_nocap(i8* %p) {
; CHECK-NEXT:  %1 = load i8, i8* %p, align 1
  %1 = load i8, i8* %p, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @load_i8(%__cheriseed_cap_t* %c)
define void @load_i8(i8 addrspace(200)* %c) addrspace(200) {
; CHECK-NEXT:  %1 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 1, i32 1)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i8*
; CHECK-NEXT:  %3 = load i8, i8* %2, align 1
  %1 = load i8, i8 addrspace(200)* %c, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @load_i8_volatile(%__cheriseed_cap_t* %c)
define void @load_i8_volatile(i8 addrspace(200)* %c) {
; CHECK-NEXT:  %1 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 1, i32 1)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i8*
; CHECK-NEXT:  %3 = load i8, i8* %2, align 1
  %1 = load i8, i8 addrspace(200)* %c, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @load_i16(%__cheriseed_cap_t* %c)
define void @load_i16(i16 addrspace(200)* %c) addrspace(200) {
; CHECK-NEXT:  %1 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 2, i32 1)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i16*
; CHECK-NEXT:  %3 = load i16, i16* %2, align 1
  %1 = load i16, i16 addrspace(200)* %c, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @load_i32(%__cheriseed_cap_t* %c)
define void @load_i32(i32 addrspace(200)* %c) addrspace(200) {
; CHECK-NEXT:  %1 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 4, i32 1)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i32*
; CHECK-NEXT:  %3 = load i32, i32* %2, align 1
  %1 = load i32, i32 addrspace(200)* %c, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @load_i64(%__cheriseed_cap_t* %c)
define void @load_i64(i64 addrspace(200)* %c) addrspace(200) {
; CHECK-NEXT:  %1 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 8, i32 1)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i64*
; CHECK-NEXT:  %3 = load i64, i64* %2, align 1
  %1 = load i64, i64 addrspace(200)* %c, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @load_i128(%__cheriseed_cap_t* %c)
define void @load_i128(i128 addrspace(200)* %c) addrspace(200) {
; CHECK-NEXT:  %1 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 16, i32 1)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i128*
; CHECK-NEXT:  %3 = load i128, i128* %2, align 1
  %1 = load i128, i128 addrspace(200)* %c, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @load_i188(%__cheriseed_cap_t* %c)
define void @load_i188(i188 addrspace(200)* %c) addrspace(200) {
; CHECK-NEXT:  %1 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 24, i32 1)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i188*
; CHECK-NEXT:  %3 = load i188, i188* %2, align 1
  %1 = load i188, i188 addrspace(200)* %c, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @load_cap_hybrid(%__cheriseed_cap_t* %0)
define void @load_cap_hybrid(i8 addrspace(200)** %0) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = call %__cheriseed_cap_t* @__cheriseed_load_cap_hybrid(
; CHECK-SAME:     %__cheriseed_cap_t* %0, %__cheriseed_cap_t* %2)
  %2 = load i8 addrspace(200)*, i8 addrspace(200)** %0, align 16
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @load_ptr_to_cap_hybrid(%__cheriseed_cap_t** %0)
define void @load_ptr_to_cap_hybrid(i8 addrspace(200)*** %0) {
; CHECK-NEXT:  %2 = load %__cheriseed_cap_t*, %__cheriseed_cap_t** %0, align 8
  %2 = load i8 addrspace(200)**, i8 addrspace(200)*** %0, align 8
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define %__cheriseed_cap_t* @load_cap(%__cheriseed_cap_t* returned align 16 %0,
; CHECK-SAME:      %__cheriseed_cap_t* %1)
define i8 addrspace(200)* @load_cap(i8 addrspace(200)* addrspace(200)* %0) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %3 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %4 = call %__cheriseed_cap_t* @__cheriseed_load_cap(
; CHECK-SAME:     %__cheriseed_cap_t* %1, %__cheriseed_cap_t* %3)
  %2 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %0, align 16
; CHECK-NEXT:  %5 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:     %__cheriseed_cap_t* %0, %__cheriseed_cap_t* %4, i64 0)
; CHECK-NEXT:  ret %__cheriseed_cap_t* %0
  ret i8 addrspace(200)* %2
}
