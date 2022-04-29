; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-pf200:128:128:128:64-S128-A200-P200-G200"
target triple = "x86_64-unknown-linux-gnu"

; CHECK-LABEL: @alloca_int
define i32 @alloca_int(i32 %int) addrspace(200) {
; CHECK-NEXT:  %int.ptr = alloca i32, align 4
; CHECK-NEXT:  %int.ptr.addr = ptrtoint i32* %int.ptr to i64
; CHECK-NEXT:  %int.ptr.shadow.cap = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %int.ptr.cap = tail call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(%__cheriseed_cap_t* %int.ptr.shadow.cap, i64 %int.ptr.addr, i64 4)
  %int.ptr = alloca i32, align 4, addrspace(200)
; CHECK-NEXT:  %1 = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %int.ptr.cap, i64 4, i32 2)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i32*
; CHECK-NEXT:  store i32 %int, i32* %2, align 4
  store i32 %int, i32 addrspace(200)* %int.ptr, align 4
; CHECK-NEXT:  %3 = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %int.ptr.cap, i64 4, i32 1)
; CHECK-NEXT:  %4 = inttoptr i64 %3 to i32*
; CHECK-NEXT:  %5 = load i32, i32* %4, align 4
  %1 = load i32, i32 addrspace(200)* %int.ptr, align 4
; CHECK-NEXT:  ret i32 %5
  ret i32 %1
}

; CHECK-LABEL: @alloca_cap
define void @alloca_cap() {
; CHECK-NEXT:  %cap_to_cap = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %cap_to_cap.addr = ptrtoint %__cheriseed_cap_t* %cap_to_cap to i64
; CHECK-NEXT:  %cap_to_cap.shadow.cap = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %cap_to_cap.cap = tail call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(%__cheriseed_cap_t* %cap_to_cap.shadow.cap, i64 %cap_to_cap.addr, i64 16)
  %cap_to_cap = alloca i32 addrspace(200)*, align 16, addrspace(200)
; CHECK-NEXT:  %cap_to_int = alloca i32, align 4
; CHECK-NEXT:  %cap_to_int.addr = ptrtoint i32* %cap_to_int to i64
; CHECK-NEXT:  %cap_to_int.shadow.cap = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %cap_to_int.cap = tail call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(%__cheriseed_cap_t* %cap_to_int.shadow.cap, i64 %cap_to_int.addr, i64 4)
  %cap_to_int = alloca i32, align 4, addrspace(200)
; CHECK-NEXT:  tail call void @__cheriseed_store_cap(%__cheriseed_cap_t* %cap_to_cap.cap, %__cheriseed_cap_t* %cap_to_int.cap)
  store i32 addrspace(200)* %cap_to_int, i32 addrspace(200)* addrspace(200)* %cap_to_cap, align 16
; CHECK-NEXT:  ret void
  ret void
}
