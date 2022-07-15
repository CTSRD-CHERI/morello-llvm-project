; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-pf200:128:128:128:64-S128-A200-P200-G200"
target triple = "x86_64-unknown-linux-gnu"

; CHECK-LABEL: @alloca_int
define void @alloca_int(i64 %cnt) addrspace(200) {
; CHECK-NEXT:  %int = alloca i32, align 4
; CHECK-NEXT:  %int.addr = ptrtoint i32* %int to i64
; CHECK-NEXT:  %int.shadow.cap = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %int.cap = call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(
; CHECK-SAME:     %__cheriseed_cap_t* %int.shadow.cap, i64 %int.addr, i64 4)
  %int = alloca i32, align 4, addrspace(200)
; CHECK-NEXT:  %int_array = alloca i32, i64 %cnt, align 4
; CHECK-NEXT:  %int_array.size = mul i64 %cnt, 4
; CHECK-NEXT:  %int_array.addr = ptrtoint i32* %int_array to i64
; CHECK-NEXT:  %int_array.shadow.cap = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %int_array.cap = call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(
; CHECK-SAME:     %__cheriseed_cap_t* %int_array.shadow.cap, i64 %int_array.addr, i64 %int_array.size)
  %int_array = alloca i32, i64 %cnt, align 4, addrspace(200)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @alloca_cap
define void @alloca_cap() {
; CHECK-NEXT:  %cap_to_cap = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %cap_to_cap.addr = ptrtoint %__cheriseed_cap_t* %cap_to_cap to i64
; CHECK-NEXT:  %cap_to_cap.shadow.cap = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %cap_to_cap.cap = call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(
; CHECK-SAME:     %__cheriseed_cap_t* %cap_to_cap.shadow.cap, i64 %cap_to_cap.addr, i64 16)
  %cap_to_cap = alloca i32 addrspace(200)*, align 16, addrspace(200)
; CHECK-NEXT:  %cap_to_int = alloca i32, align 4
; CHECK-NEXT:  %cap_to_int.addr = ptrtoint i32* %cap_to_int to i64
; CHECK-NEXT:  %cap_to_int.shadow.cap = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %cap_to_int.cap = call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(
; CHECK-SAME:     %__cheriseed_cap_t* %cap_to_int.shadow.cap, i64 %cap_to_int.addr, i64 4)
  %cap_to_int = alloca i32, align 4, addrspace(200)
; CHECK-NEXT:  call void @__cheriseed_store_cap(%__cheriseed_cap_t* %cap_to_cap.cap,
; CHECK-SAME:     %__cheriseed_cap_t* %cap_to_int.cap)
  store i32 addrspace(200)* %cap_to_int, i32 addrspace(200)* addrspace(200)* %cap_to_cap, align 16
; CHECK-NEXT:  ret void
  ret void
}
