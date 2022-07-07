; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------

; CHECK-LABEL: %struct.S = type { i8, i32, %__cheriseed_cap_t }
%struct.S = type { i8, i32, i32 addrspace(200)* }

; CHECK-LABEL: @__cheriseed_global_intlike_global_default = global i32 42, align 4
; CHECK-NOT:   @__cheriseed_shadow_capability_intlike_global_default
@intlike_global_default = global i32 42, align 4

; CHECK-LABEL: @__cheriseed_global_zero_global_cap_default = global %__cheriseed_cap_t zeroinitializer, align 16
; CHECK-NOT:   @__cheriseed_shadow_capability_zero_global_cap_default
@zero_global_cap_default = global i32 addrspace(200)* null, align 16

; CHECK-LABEL: @__cheriseed_global_intlike_global_200 = global i32 42, align 4
; CHECK-NEXT:  @__cheriseed_shadow_capability_intlike_global_200 = global %__cheriseed_cap_t zeroinitializer, align 16
@intlike_global_200 = addrspace(200) global i32 42, align 4

; CHECK-NEXT:  @__cheriseed_global_nonzero_global_cap_default = global %__cheriseed_cap_t zeroinitializer, align 16
@nonzero_global_cap_default = global i32 addrspace(200)* @intlike_global_200, align 16

; CHECK-NEXT:  @__cheriseed_global_nonzero_global_cap_default_2 = global %__cheriseed_cap_t zeroinitializer, align 16
@nonzero_global_cap_default_2 = global i32 addrspace(200)* addrspacecast (i32* @intlike_global_default to i32 addrspace(200)*), align 16

; CHECK-LABEL: @"__cheriseed_inits_<stdin>" = internal global [3 x %__cheriseed_initializer_t] [
; CHECK-SAME: { i64 ptrtoint (%__cheriseed_cap_t* @__cheriseed_shadow_capability_intlike_global_200 to i64),
; CHECK-SAME:   i64 ptrtoint (i32* @__cheriseed_global_intlike_global_200 to i64),
; CHECK-SAME:   i64 4, i32 4, void ()* null },
; CHECK-SAME: { i64 0, i64 0, i64 0, i32 0,
; CHECK-SAME:   void ()* @__cheriseed_initializer_nonzero_global_cap_default },
; CHECK-SAME: { i64 0, i64 0, i64 0, i32 0,
; CHECK-SAME:   void ()* @__cheriseed_initializer_nonzero_global_cap_default_2 }],
; CHECK-SAME: section "__cheriseed_initializers", align 8

; CHECK-LABEL: define void @init(%struct.S* %0)
define void @init(%struct.S* %0) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %4 = getelementptr inbounds %struct.S, %struct.S* %0, i64 0, i32 0
  %2 = getelementptr inbounds %struct.S, %struct.S* %0, i64 0, i32 0
; CHECK-NEXT:  %5 = getelementptr inbounds %struct.S, %struct.S* %0, i64 0, i32 1
  %3 = getelementptr inbounds %struct.S, %struct.S* %0, i64 0, i32 1
; CHECK-NEXT:  store i32 2, i32* %5, align 4
  store i32 2, i32* %3, align 4
; CHECK-NEXT:  %6 = call %__cheriseed_cap_t* @__cheriseed_ddc_get(%__cheriseed_cap_t* %2)
; CHECK-NEXT:  %7 = ptrtoint i32* %5 to i64
; CHECK-NEXT:  %8 = call %__cheriseed_cap_t* @__cheriseed_address_set(%__cheriseed_cap_t* %6, %__cheriseed_cap_t* %6, i64 %7)
  %4 = addrspacecast i32* %3 to i32 addrspace(200)*
; CHECK-NEXT:  %9 = getelementptr inbounds %struct.S, %struct.S* %0, i64 0, i32 2
  %5 = getelementptr inbounds %struct.S, %struct.S* %0, i64 0, i32 2
; CHECK-NEXT:  call void @__cheriseed_store_cap_hybrid(%__cheriseed_cap_t* %9, %__cheriseed_cap_t* %8)
  store i32 addrspace(200)* %4, i32 addrspace(200)** %5, align 16
; CHECK-NEXT:  %10 = call %__cheriseed_cap_t* @__cheriseed_load_cap_hybrid(%__cheriseed_cap_t* %9, %__cheriseed_cap_t* %3)
  %6 = load i32 addrspace(200)*, i32 addrspace(200)** %5, align 16
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @alloca_cap()
define void @alloca_cap() {
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
  %1 = alloca i8 addrspace(200)*, align 16
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t*, align 8
  %2 = alloca i8 addrspace(200)**, align 8
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @interact_with_globals(%__cheriseed_cap_t* %0)
define void @interact_with_globals(i32 addrspace(200)* %0) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %4 = call %__cheriseed_cap_t* @zero_global_cap_default()
; CHECK-NEXT:  call void @__cheriseed_store_cap_hybrid(%__cheriseed_cap_t* %4, %__cheriseed_cap_t* %0)
  store i32 addrspace(200)* %0, i32 addrspace(200)** @zero_global_cap_default, align 8
; CHECK-NEXT:  %5 = call i32* @intlike_global_default()
; CHECK-NEXT:  %6 = load i32, i32* %5, align 4
  %2 = load i32, i32* @intlike_global_default, align 4
; CHECK-NEXT:  %7 = call %__cheriseed_cap_t* @intlike_global_200()
; CHECK-NEXT:  %8 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %7, i64 4, i32 1)
; CHECK-NEXT:  %9 = inttoptr i64 %8 to i32*
; CHECK-NEXT:  %10 = load i32, i32* %9, align 4
  %3 = load i32, i32 addrspace(200)* @intlike_global_200, align 4
; CHECK-NEXT:  %11 = add nsw i32 %6, %10
  %4 = add nsw i32 %2, %3
; CHECK-NEXT:  %12 = call %__cheriseed_cap_t* @nonzero_global_cap_default()
; CHECK-NEXT:  %13 = call %__cheriseed_cap_t* @__cheriseed_load_cap_hybrid(%__cheriseed_cap_t* %12, %__cheriseed_cap_t* %2)
  %5 = load i32 addrspace(200)*, i32 addrspace(200)** @nonzero_global_cap_default, align 8
; CHECK-NEXT:  %14 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %13, i64 4, i32 1)
; CHECK-NEXT:  %15 = inttoptr i64 %14 to i32*
; CHECK-NEXT:  %16 = load i32, i32* %15, align 4
  %6 = load i32, i32 addrspace(200)* %5, align 4
; CHECK-NEXT:  %17 = call %__cheriseed_cap_t* @nonzero_global_cap_default_2()
; CHECK-NEXT:  %18 = call %__cheriseed_cap_t* @__cheriseed_load_cap_hybrid(%__cheriseed_cap_t* %17, %__cheriseed_cap_t* %3)
  %7 = load i32 addrspace(200)*, i32 addrspace(200)** @nonzero_global_cap_default_2, align 8
; CHECK-NEXT:  %19 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %18, i64 4, i32 1)
; CHECK-NEXT:  %20 = inttoptr i64 %19 to i32*
; CHECK-NEXT:  %21 = load i32, i32* %20, align 4
  %8 = load i32, i32 addrspace(200)* %7, align 4
; CHECK-NEXT:  %22 = add nsw i32 %16, %21
  %9 = add nsw i32 %6, %8
; CHECK-NEXT:  %23 = add nsw i32 %11, %22
  %10 = add nsw i32 %4, %9
; CHECK-NEXT:  %24 = call i32* @intlike_global_default()
; CHECK-NEXT:  store i32 %23, i32* %24, align 4
  store i32 %10, i32* @intlike_global_default, align 4
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL:  define i32* @intlike_global_default() {
; CHECK-NEXT:    ret i32* @__cheriseed_global_intlike_global_default
; CHECK-NEXT:  }

; CHECK-NOT:    define internal void @__cheriseed_initializer_intlike_global_default()

; CHECK-LABEL:  define %__cheriseed_cap_t* @zero_global_cap_default() {
; CHECK-NEXT:    ret %__cheriseed_cap_t* @__cheriseed_global_zero_global_cap_default
; CHECK-NEXT:  }

; CHECK-NOT:    define internal void @__cheriseed_initializer_zero_global_cap_default()

; CHECK-LABEL:  define %__cheriseed_cap_t* @intlike_global_200() {
; CHECK-NEXT:    ret %__cheriseed_cap_t* @__cheriseed_shadow_capability_intlike_global_200
; CHECK-NEXT:  }

; CHECK-NOT:    define internal void @__cheriseed_initializer_intlike_global_200()

; CHECK-LABEL:  define %__cheriseed_cap_t* @nonzero_global_cap_default() {
; CHECK-NEXT:    ret %__cheriseed_cap_t* @__cheriseed_global_nonzero_global_cap_default
; CHECK-NEXT:  }

; CHECK-LABEL:  define internal void @__cheriseed_initializer_nonzero_global_cap_default() {
; CHECK-NEXT:    %gep.intlike_global_200 = call %__cheriseed_cap_t* @intlike_global_200()
; CHECK-NEXT:    %1 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* @__cheriseed_global_nonzero_global_cap_default, %__cheriseed_cap_t* %gep.intlike_global_200, i64 0)
; CHECK-NEXT:    ret void
; CHECK-NEXT:  }

; CHECK-LABEL:  define %__cheriseed_cap_t* @nonzero_global_cap_default_2() {
; CHECK-NEXT:    ret %__cheriseed_cap_t* @__cheriseed_global_nonzero_global_cap_default_2
; CHECK-NEXT:  }

; CHECK-LABEL:  define internal void @__cheriseed_initializer_nonzero_global_cap_default_2() {
; CHECK-NEXT:    %"CHERIseed Alloca Insertion Point" = bitcast i8 0 to i8
; CHECK-NEXT:    %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:    %2 = call i32* @intlike_global_default()
; CHECK-NEXT:    %3 = call %__cheriseed_cap_t* @__cheriseed_ddc_get(%__cheriseed_cap_t* %1)
; CHECK-NEXT:    %4 = ptrtoint i32* %2 to i64
; CHECK-NEXT:    %5 = call %__cheriseed_cap_t* @__cheriseed_address_set(%__cheriseed_cap_t* %3, %__cheriseed_cap_t* %3, i64 %4)
; CHECK-NEXT:    %6 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* @__cheriseed_global_nonzero_global_cap_default_2, %__cheriseed_cap_t* %5, i64 0)
; CHECK-NEXT:    ret void
; CHECK-NEXT:  }
