; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------
; Test aliases.
; This is required because of possible dependencies.

@int = global i8 0, align 4
@int_as200 = addrspace(200) global i8 0, align 4
@cap = global i8 addrspace(200)* null, align 16

; CHECK: @alias_int = alias i8, i8* @int
@alias_int = alias i8, i8* @int
; CHECK: @alias_int_2 = alias i8, i8* @alias_int
@alias_int_2 = alias i8, i8* @alias_int
; CHECK: @alias_int_3_as200 = alias %__cheriseed_cap_t, %__cheriseed_cap_t* @int_as200
@alias_int_3_as200 = alias i8, i8 addrspace(200)* @int_as200
; CHECK: @alias_cap = alias %__cheriseed_cap_t, %__cheriseed_cap_t* @cap
@alias_cap = alias i8 addrspace(200)*, i8 addrspace(200)** @cap
; CHECK: @alias_cap_2 = alias %__cheriseed_cap_t, %__cheriseed_cap_t* @alias_cap
@alias_cap_2 = alias i8 addrspace(200)*, i8 addrspace(200)** @alias_cap
; CHECK: @alias_func_1 = alias void (), void ()* @uses_alias_int_2
@alias_func_1 = alias void (), void ()* @uses_alias_int_2
; CHECK: @alias_func_2 = alias void (), void ()* @alias_func_1
@alias_func_2 = alias void (), void ()* @alias_func_1
; CHECK:      @alias_func_3 = alias %__cheriseed_cap_t* (%__cheriseed_cap_t*,
; CHECK-SAME:   %__cheriseed_cap_t*), %__cheriseed_cap_t* (%__cheriseed_cap_t*, %__cheriseed_cap_t*)* @func_3
@alias_func_3 = alias i8 addrspace(200)* (i8 addrspace(200)*), i8 addrspace(200)* (i8 addrspace(200)*)* @func_3
; CHECK: @alias_bitcast = weak alias void (...), bitcast (void ()* @uses_int to void (...)*)
@alias_bitcast = weak alias void (...), bitcast (void ()* @uses_int to void (...)*)

; ------------------------------------------------------------------------------
; Test aliases referencing each other.

; CHECK: @alias_sort_u = alias %__cheriseed_cap_t, %__cheriseed_cap_t* @alias_sort_preempt
@alias_sort_u = alias i8 addrspace(200)*, i8 addrspace(200)** @alias_sort_preempt
; CHECK: @alias_sort_preempt = alias %__cheriseed_cap_t, %__cheriseed_cap_t* @alias_sort_r
@alias_sort_preempt = alias i8 addrspace(200)*, i8 addrspace(200)** @alias_sort_r
; CHECK: @alias_sort_q = alias %__cheriseed_cap_t, %__cheriseed_cap_t* @alias_sort_r
@alias_sort_q = alias i8 addrspace(200)*, i8 addrspace(200)** @alias_sort_r
; CHECK: @alias_sort_g = alias %__cheriseed_cap_t, %__cheriseed_cap_t* @alias_sort_preempt
@alias_sort_g = alias i8 addrspace(200)*, i8 addrspace(200)** @alias_sort_preempt
; CHECK: @alias_sort_r = alias %__cheriseed_cap_t, %__cheriseed_cap_t* @sort_g
@alias_sort_r = alias i8 addrspace(200)*, i8 addrspace(200)** @sort_g
; Not checked on purpose.
@sort_g = global i8 addrspace(200)* null, align 16

; ------------------------------------------------------------------------------
; Some function aliases.

; CHECK-LABEL: @func_alias_1 = weak hidden alias void (),
; CHECK-SAME:    void ()* @func_alias_1_aliasee
@func_alias_1 = weak hidden alias void (),
  void () addrspace(200)* @func_alias_1_aliasee

; CHECK-LABEL: @func_alias_2 = weak hidden alias void (%__cheriseed_cap_t*),
; CHECK-SAME:    void (%__cheriseed_cap_t*)* @func_alias_2_aliasee
@func_alias_2 = weak hidden alias void (i32 addrspace(200)* %0),
  bitcast (void (i8 addrspace(200)* %0) addrspace(200)* @func_alias_2_aliasee to
  void (i32 addrspace(200)* %0) addrspace(200)*)

; ------------------------------------------------------------------------------
; Uses od aliases.

; CHECK-LABEL: @func_3(%__cheriseed_cap_t* returned align 16 %0, %__cheriseed_cap_t* %1)
define i8 addrspace(200)* @func_3(i8 addrspace(200)* %0) {
  %2 = call i8 addrspace(200)* @alias_func_3(i8 addrspace(200)* %0)
  ret i8 addrspace(200)* %0
}

; CHECK-LABEL: @uses_int
define void @uses_int() {
; CHECK-NEXT:  %1 = load i8, i8* @int, align 1
  %1 = load i8, i8* @int, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @uses_alias_int_2
define void @uses_alias_int_2() {
; CHECK-NEXT:  %1 = load i8, i8* @alias_int_2, align 1
  %1 = load i8, i8* @alias_int_2, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @uses_cap
define void @uses_cap() {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %2 = call %__cheriseed_cap_t* @__cheriseed_load_cap_hybrid(%__cheriseed_cap_t* @cap, %__cheriseed_cap_t* %1)
  %1 = load i8 addrspace(200)*, i8 addrspace(200)** @cap, align 16
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @uses_alias_cap_2
define void @uses_alias_cap_2() {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %2 = call %__cheriseed_cap_t* @__cheriseed_load_cap_hybrid(%__cheriseed_cap_t* @alias_cap_2, %__cheriseed_cap_t* %1)
  %1 = load i8 addrspace(200)*, i8 addrspace(200)** @alias_cap_2, align 16
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @calls_alias_func_2
define void @calls_alias_func_2() {
; CHECK-NEXT:  call void @alias_func_2()
  call void @alias_func_2()
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @calls_alias_func_3(%__cheriseed_cap_t* returned align 16 %0,
; CHECK-SAME:    %__cheriseed_cap_t* %1)
define i8 addrspace(200)* @calls_alias_func_3(i8 addrspace(200)* %0) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %3 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %4 = call %__cheriseed_cap_t* @alias_func_3(
; CHECK-SAME:    %__cheriseed_cap_t* returned align 16 %3,
; CHECK-SAME:    %__cheriseed_cap_t* %1)
; CHECK-NEXT:  %5 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:    %__cheriseed_cap_t* %0, %__cheriseed_cap_t* %4, i64 0)
  %2 = call i8 addrspace(200)* @alias_func_3(i8 addrspace(200)* %0)
; CHECK-NEXT:  ret %__cheriseed_cap_t* %0
  ret i8 addrspace(200)* %2
}

define void @func_alias_1_aliasee() addrspace(200) {
  ret void
}

define void @func_alias_2_aliasee(i8 addrspace(200)* %0) addrspace(200) {
  ret void
}

; ------------------------------------------------------------------------------
