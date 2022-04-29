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
; CHECK-NEXT:  @__cheriseed_shadow_capability_intlike_global_200 = global %__cheriseed_cap_t { i128 -1 }, align 16
@intlike_global_200 = addrspace(200) global i32 42, align 4

; CHECK-NEXT:  @__cheriseed_global_nonzero_global_cap_default = global %__cheriseed_cap_t zeroinitializer, align 16
; CHECK-NEXT:  @__cheriseed_global_nonzero_global_cap_default_shadow_flag = global i8 0
@nonzero_global_cap_default = global i32 addrspace(200)* @intlike_global_200, align 16

; CHECK-NEXT:  @__cheriseed_global_nonzero_global_cap_default_2 = global %__cheriseed_cap_t zeroinitializer, align 16
; CHECK-NEXT:  @__cheriseed_global_nonzero_global_cap_default_2_shadow_flag = global i8 0
@nonzero_global_cap_default_2 = global i32 addrspace(200)* addrspacecast (i32* @intlike_global_default to i32 addrspace(200)*), align 16

; CHECK-LABEL: define void @init(%struct.S* %0)
define void @init(%struct.S* %0) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %4 = getelementptr inbounds %struct.S, %struct.S* %0, i64 0, i32 0
  %2 = getelementptr inbounds %struct.S, %struct.S* %0, i64 0, i32 0
; CHECK-NEXT:  store i8 1, i8* %4, align 1
  store i8 1, i8* %2, align 1
; CHECK-NEXT:  %5 = getelementptr inbounds %struct.S, %struct.S* %0, i64 0, i32 1
  %3 = getelementptr inbounds %struct.S, %struct.S* %0, i64 0, i32 1
; CHECK-NEXT:  store i32 2, i32* %5, align 4
  store i32 2, i32* %3, align 4
; CHECK-NEXT:  %6 = tail call %__cheriseed_cap_t* @__cheriseed_ddc_get(%__cheriseed_cap_t* %2)
; CHECK-NEXT:  %7 = ptrtoint i32* %5 to i64
; CHECK-NEXT:  %8 = tail call %__cheriseed_cap_t* @__cheriseed_address_set(%__cheriseed_cap_t* %6, %__cheriseed_cap_t* %6, i64 %7)
  %4 = addrspacecast i32* %3 to i32 addrspace(200)*
; CHECK-NEXT:  %9 = getelementptr inbounds %struct.S, %struct.S* %0, i64 0, i32 2
  %5 = getelementptr inbounds %struct.S, %struct.S* %0, i64 0, i32 2
; CHECK-NEXT:  tail call void @__cheriseed_store_cap_hybrid(%__cheriseed_cap_t* %9, %__cheriseed_cap_t* %8)
  store i32 addrspace(200)* %4, i32 addrspace(200)** %5, align 16
; CHECK-NEXT:  %10 = tail call %__cheriseed_cap_t* @__cheriseed_load_cap_hybrid(%__cheriseed_cap_t* %9, %__cheriseed_cap_t* %3)
  %6 = load i32 addrspace(200)*, i32 addrspace(200)** %5, align 16
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define i64* @cap_to_ptr(%__cheriseed_cap_t* %0)
define i64* @cap_to_ptr(i64 addrspace(200)* %0) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* %2, %__cheriseed_cap_t* %0, i64 0)
  %2 = bitcast i64 addrspace(200)* %0 to i8 addrspace(200)*
; CHECK-NEXT:  %4 = tail call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %3)
  %3 = tail call i64 @llvm.cheri.cap.address.get.i64(i8 addrspace(200)* %2)
; CHECK-NEXT:  %5 = inttoptr i64 %4 to i64*
  %4 = inttoptr i64 %3 to i64*
; CHECK-NEXT:  ret i64* %5
  ret i64* %4
}

declare i64 @llvm.cheri.cap.address.get.i64(i8 addrspace(200)*)

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
; CHECK-NEXT:  %4 = tail call %__cheriseed_cap_t* @zero_global_cap_default()
; CHECK-NEXT:  tail call void @__cheriseed_store_cap_hybrid(%__cheriseed_cap_t* %4, %__cheriseed_cap_t* %0)
  store i32 addrspace(200)* %0, i32 addrspace(200)** @zero_global_cap_default, align 8
; CHECK-NEXT:  %5 = tail call i32* @intlike_global_default()
; CHECK-NEXT:  %6 = load i32, i32* %5, align 4
  %2 = load i32, i32* @intlike_global_default, align 4
; CHECK-NEXT:  %7 = tail call %__cheriseed_cap_t* @intlike_global_200()
; CHECK-NEXT:  %8 = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %7, i64 4, i32 1)
; CHECK-NEXT:  %9 = inttoptr i64 %8 to i32*
; CHECK-NEXT:  %10 = load i32, i32* %9, align 4
  %3 = load i32, i32 addrspace(200)* @intlike_global_200, align 4
; CHECK-NEXT:  %11 = add nsw i32 %6, %10
  %4 = add nsw i32 %2, %3
; CHECK-NEXT:  %12 = tail call %__cheriseed_cap_t* @nonzero_global_cap_default()
; CHECK-NEXT:  %13 = tail call %__cheriseed_cap_t* @__cheriseed_load_cap_hybrid(%__cheriseed_cap_t* %12, %__cheriseed_cap_t* %2)
  %5 = load i32 addrspace(200)*, i32 addrspace(200)** @nonzero_global_cap_default, align 8
; CHECK-NEXT:  %14 = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %13, i64 4, i32 1)
; CHECK-NEXT:  %15 = inttoptr i64 %14 to i32*
; CHECK-NEXT:  %16 = load i32, i32* %15, align 4
  %6 = load i32, i32 addrspace(200)* %5, align 4
; CHECK-NEXT:  %17 = tail call %__cheriseed_cap_t* @nonzero_global_cap_default_2()
; CHECK-NEXT:  %18 = tail call %__cheriseed_cap_t* @__cheriseed_load_cap_hybrid(%__cheriseed_cap_t* %17, %__cheriseed_cap_t* %3)
  %7 = load i32 addrspace(200)*, i32 addrspace(200)** @nonzero_global_cap_default_2, align 8
; CHECK-NEXT:  %19 = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %18, i64 4, i32 1)
; CHECK-NEXT:  %20 = inttoptr i64 %19 to i32*
; CHECK-NEXT:  %21 = load i32, i32* %20, align 4
  %8 = load i32, i32 addrspace(200)* %7, align 4
; CHECK-NEXT:  %22 = add nsw i32 %16, %21
  %9 = add nsw i32 %6, %8
; CHECK-NEXT:  %23 = add nsw i32 %11, %22
  %10 = add nsw i32 %4, %9
; CHECK-NEXT:  %24 = tail call i32* @intlike_global_default()
; CHECK-NEXT:  store i32 %23, i32* %24, align 4
  store i32 %10, i32* @intlike_global_default, align 4
; CHECK-NEXT:  ret void
  ret void
}
