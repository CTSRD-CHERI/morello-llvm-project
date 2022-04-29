; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------
; Test sorting of aliases.
; This is required because of possible dependencies.

@int = global i8 0, align 4
@cap = global i8 addrspace(200)* null, align 16

@alias_int = alias i8, i8* @int
@alias_int_2 = alias i8, i8* @alias_int
@alias_cap = alias i8 addrspace(200)*, i8 addrspace(200)** @cap
@alias_cap_2 = alias i8 addrspace(200)*, i8 addrspace(200)** @alias_cap
@alias_func_1 = alias void (), void ()* @uses_alias_int_2
@alias_func_2 = alias void (), void ()* @alias_func_1
@alias_func_3 = alias i8 addrspace(200)* (i8 addrspace(200)*), i8 addrspace(200)* (i8 addrspace(200)*)* @func_3
@alias_bitcast = weak alias void (...), bitcast (void ()* @uses_int to void (...)*)

; The order of the checks are different because of sorting.
; CHECK-NOT:  @alias_bitcast.old
; CHECK:      @alias_bitcast = weak alias void (...), bitcast (void ()* @uses_int to void (...)*)
; CHECK-NOT:  @alias_cap.old
; CHECK:      @alias_cap = alias %__cheriseed_cap_t* (), %__cheriseed_cap_t* ()* @cap
; CHECK-NOT:  @alias_cap_2.old
; CHECK:      @alias_cap_2 = alias %__cheriseed_cap_t* (), %__cheriseed_cap_t* ()* @alias_cap
; CHECK-NOT:  @alias_func_1.old
; CHECK:      @alias_func_1 = alias void (), void ()* @uses_alias_int_2
; CHECK-NOT:  @alias_func_2.old
; CHECK:      @alias_func_2 = alias void (), void ()* @alias_func_1
; CHECK-NOT:  @alias_func_3.old
; CHECK:      @alias_func_3 = alias %__cheriseed_cap_t* (%__cheriseed_cap_t*, %__cheriseed_cap_t*),
; CHECK-SAME:   %__cheriseed_cap_t* (%__cheriseed_cap_t*, %__cheriseed_cap_t*)* @func_3
; CHECK-NOT:  @alias_int.old
; CHECK:      @alias_int = alias i8* (), i8* ()* @int
; CHECK-NOT:  @alias_int_2.old
; CHECK:      @alias_int_2 = alias i8* (), i8* ()* @alias_int

; CHECK-LABEL: @func_3(%__cheriseed_cap_t* returned align 16 %0, %__cheriseed_cap_t* %1)
define i8 addrspace(200)* @func_3(i8 addrspace(200)* %0) {
  %2 = call i8 addrspace(200)* @alias_func_3(i8 addrspace(200)* %0)
  ret i8 addrspace(200)* %0
}

; CHECK-LABEL: @uses_int
define void @uses_int() {
; CHECK-NEXT:  %1 = tail call i8* @int()
; CHECK-NEXT:  %2 = load i8, i8* %1, align 1
  %1 = load i8, i8* @int, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @uses_alias_int_2
define void @uses_alias_int_2() {
; CHECK-NEXT:  %1 = tail call i8* @alias_int_2()
; CHECK-NEXT:  %2 = load i8, i8* %1, align 1
  %1 = load i8, i8* @alias_int_2, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @uses_cap
define void @uses_cap() {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %2 = tail call %__cheriseed_cap_t* @cap()
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_load_cap_hybrid(%__cheriseed_cap_t* %2, %__cheriseed_cap_t* %1)
  %1 = load i8 addrspace(200)*, i8 addrspace(200)** @cap, align 16
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @uses_alias_cap_2
define void @uses_alias_cap_2() {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %2 = tail call %__cheriseed_cap_t* @alias_cap_2()
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_load_cap_hybrid(%__cheriseed_cap_t* %2, %__cheriseed_cap_t* %1)
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

; CHECK-LABEL: @calls_alias_func_3(%__cheriseed_cap_t* returned align 16 %0, %__cheriseed_cap_t* %1)
define i8 addrspace(200)* @calls_alias_func_3(i8 addrspace(200)* %0) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %3 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %4 = call %__cheriseed_cap_t* @alias_func_3(%__cheriseed_cap_t* returned align 16 %3,
; CHECK-SAME:     %__cheriseed_cap_t* %1)
; CHECK-NEXT:  %5 = tail call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:     %__cheriseed_cap_t* %0, %__cheriseed_cap_t* %4, i64 0)
  %2 = call i8 addrspace(200)* @alias_func_3(i8 addrspace(200)* %0)
; CHECK-NEXT:  ret %__cheriseed_cap_t* %0
  ret i8 addrspace(200)* %2
}

; Test that sorting of aliases work as expexcted.
; If the sorting was broken this would result in an assert.
@alias_sort_u = alias i8 addrspace(200)*, i8 addrspace(200)** @alias_sort_preempt
@alias_sort_preempt = alias i8 addrspace(200)*, i8 addrspace(200)** @alias_sort_r
@alias_sort_q = alias i8 addrspace(200)*, i8 addrspace(200)** @alias_sort_r
@alias_sort_g = alias i8 addrspace(200)*, i8 addrspace(200)** @alias_sort_preempt
@alias_sort_r = alias i8 addrspace(200)*, i8 addrspace(200)** @sort_g
@sort_g = global i8 addrspace(200)* null, align 16

; ------------------------------------------------------------------------------
