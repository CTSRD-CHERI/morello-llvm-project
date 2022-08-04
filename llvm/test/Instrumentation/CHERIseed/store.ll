; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------

; CHECK-LABEL: define void @store_i1(%__cheriseed_cap_t* %c, i1 %p)
define void @store_i1(i1 addrspace(200)* %c, i1 %p) addrspace(200) {
; CHECK-NEXT:  %1 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 1, i32 2)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i1*
; CHECK-NEXT:  store i1 %p, i1* %2, align 1
; CHECK-NEXT:  call void @__cheriseed_check_access_end(i64 %1, i64 1)
  store i1 %p, i1 addrspace(200)* %c, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @store_nocap(i8* %p1, i8 %p2)
define void @store_nocap(i8* %p1, i8 %p2) {
; CHECK-NEXT:  store i8 %p2, i8* %p1, align 1
  store i8 %p2, i8* %p1, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @store_i8(%__cheriseed_cap_t* %c, i8 %p)
define void @store_i8(i8 addrspace(200)* %c, i8 %p) addrspace(200) {
; CHECK-NEXT:  %1 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 1, i32 2)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i8*
; CHECK-NEXT:  store i8 %p, i8* %2, align 1
; CHECK-NEXT:  call void @__cheriseed_check_access_end(i64 %1, i64 1)
  store i8 %p, i8 addrspace(200)* %c, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @store_i8_volatile(%__cheriseed_cap_t* %c, i8 %p)
define void @store_i8_volatile(i8 addrspace(200)* %c, i8 %p) addrspace(200) {
; CHECK-NEXT:  %1 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 1, i32 2)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i8*
; CHECK-NEXT:  store volatile i8 %p, i8* %2, align 1
; CHECK-NEXT:  call void @__cheriseed_check_access_end(i64 %1, i64 1)
  store volatile i8 %p, i8 addrspace(200)* %c, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @store_i16(%__cheriseed_cap_t* %c, i16 %p)
define void @store_i16(i16 addrspace(200)* %c, i16 %p) addrspace(200) {
; CHECK-NEXT:  %1 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 2, i32 2)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i16*
; CHECK-NEXT:  store i16 %p, i16* %2, align 1
; CHECK-NEXT:  call void @__cheriseed_check_access_end(i64 %1, i64 2)
  store i16 %p, i16 addrspace(200)* %c, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @store_i32(%__cheriseed_cap_t* %c, i32 %p)
define void @store_i32(i32 addrspace(200)* %c, i32 %p) addrspace(200) {
; CHECK-NEXT:  %1 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 4, i32 2)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i32*
; CHECK-NEXT:  store i32 %p, i32* %2, align 1
; CHECK-NEXT:  call void @__cheriseed_check_access_end(i64 %1, i64 4)
  store i32 %p, i32 addrspace(200)* %c, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @store_i64(%__cheriseed_cap_t* %c, i64 %p)
define void @store_i64(i64 addrspace(200)* %c, i64 %p) addrspace(200) {
; CHECK-NEXT:  %1 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 8, i32 2)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i64*
; CHECK-NEXT:  store i64 %p, i64* %2, align 1
; CHECK-NEXT:  call void @__cheriseed_check_access_end(i64 %1, i64 8)
  store i64 %p, i64 addrspace(200)* %c, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @store_i128(%__cheriseed_cap_t* %c, i128 %p)
define void @store_i128(i128 addrspace(200)* %c, i128 %p) addrspace(200) {
; CHECK-NEXT:  %1 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 16, i32 2)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i128*
; CHECK-NEXT:  store i128 %p, i128* %2, align 1
; CHECK-NEXT:  call void @__cheriseed_check_access_end(i64 %1, i64 16)
  store i128 %p, i128 addrspace(200)* %c, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @store_i188(%__cheriseed_cap_t* %c, i188 %p)
define void @store_i188(i188 addrspace(200)* %c, i188 %p) addrspace(200) {
; CHECK-NEXT:  %1 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 24, i32 2)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i188*
; CHECK-NEXT:  store i188 %p, i188* %2, align 1
; CHECK-NEXT:  call void @__cheriseed_check_access_end(i64 %1, i64 24)
  store i188 %p, i188 addrspace(200)* %c, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @store_cap_hybrid(%__cheriseed_cap_t* %0, %__cheriseed_cap_t* %1)
define void @store_cap_hybrid(i8 addrspace(200)** %0, i8 addrspace(200)* %1) {
; CHECK-NEXT:  call void @__cheriseed_store_cap_hybrid(%__cheriseed_cap_t* %0, %__cheriseed_cap_t* %1)
  store i8 addrspace(200)* %1, i8 addrspace(200)** %0, align 16
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @store_ptr_to_cap_hybrid(%__cheriseed_cap_t** %0, %__cheriseed_cap_t* %1)
define void @store_ptr_to_cap_hybrid(i8 addrspace(200)*** %0, i8 addrspace(200)** %1) {
; CHECK-NEXT:  store %__cheriseed_cap_t* %1, %__cheriseed_cap_t** %0, align 8
  store i8 addrspace(200)** %1, i8 addrspace(200)*** %0, align 8
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @store_cap(%__cheriseed_cap_t* %0, %__cheriseed_cap_t* %1)
define void @store_cap(i8 addrspace(200)* addrspace(200)* %0, i8 addrspace(200)* %1) addrspace(200) {
; CHECK-NEXT:  call void @__cheriseed_store_cap(%__cheriseed_cap_t* %0, %__cheriseed_cap_t* %1)
; CHECK-NEXT:  ret void
  store i8 addrspace(200)* %1, i8 addrspace(200)* addrspace(200)* %0, align 16
  ret void
}
