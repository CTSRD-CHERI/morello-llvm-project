; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s
; RUN: opt -passes=cheriseed -S < %s | FileCheck --check-prefix=COMMON-LINKAGE %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------

@global_default = global i32 42, align 4
@global_cap_200 = addrspace(200) global i32 42, align 4
@cap_to_cap_200 = addrspace(200) global i32 addrspace(200)* @global_cap_200, align 16
@ext_cap_to_cap_200 = external addrspace(200) global i32 addrspace(200)*, align 16
@ptr_to_cap = global i32 addrspace(200)* addrspacecast (i32* @global_default to i32 addrspace(200)*), align 16
@null_ptr_to_cap = global i32 addrspace(200)* null, align 16

; CHECK-LABEL: define void @test_sum_globals()
define void @test_sum_globals() {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = call %__cheriseed_cap_t* @cap_to_cap_200()
; CHECK-NEXT:  %4 = call %__cheriseed_cap_t* @__cheriseed_load_cap(%__cheriseed_cap_t* %3, %__cheriseed_cap_t* %1)
  %1 = load i32 addrspace(200)*, i32 addrspace(200)* addrspace(200)* @cap_to_cap_200, align 16
; CHECK-NEXT:  %5 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %4, i64 4, i32 1)
; CHECK-NEXT:  %6 = inttoptr i64 %5 to i32*
; CHECK-NEXT:  %7 = load i32, i32* %6, align 4
  %2 = load i32, i32 addrspace(200)* %1, align 4
; CHECK-NEXT:  %8 = call %__cheriseed_cap_t* @global_cap_200()
; CHECK-NEXT:  %9 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %8, i64 4, i32 1)
; CHECK-NEXT:  %10 = inttoptr i64 %9 to i32*
; CHECK-NEXT:  %11 = load i32, i32* %10, align 4
  %3 = load i32, i32 addrspace(200)* @global_cap_200, align 4
; CHECK-NEXT:  %12 = add nsw i32 %11, %7
  %4 = add nsw i32 %3, %2
; CHECK-NEXT:  %13 = call %__cheriseed_cap_t* @global_cap_200()
; CHECK-NEXT:  %14 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %13, i64 4, i32 2)
; CHECK-NEXT:  %15 = inttoptr i64 %14 to i32*
; CHECK-NEXT:  store i32 %12, i32* %15, align 4
  store i32 %4, i32 addrspace(200)* @global_cap_200, align 4
; CHECK-NEXT:  %16 = call %__cheriseed_cap_t* @ext_cap_to_cap_200()
; CHECK-NEXT:  %17 = call %__cheriseed_cap_t* @__cheriseed_load_cap(%__cheriseed_cap_t* %16, %__cheriseed_cap_t* %2)
  %5 = load i32 addrspace(200)*, i32 addrspace(200)* addrspace(200)* @ext_cap_to_cap_200, align 16
; CHECK-NEXT:  %18 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %17, i64 4, i32 1)
; CHECK-NEXT:  %19 = inttoptr i64 %18 to i32*
; CHECK-NEXT:  %20 = load i32, i32* %19, align 4
  %6 = load i32, i32 addrspace(200)* %5, align 4
; CHECK-NEXT:  %21 = add nsw i32 %20, %12
  %7 = add nsw i32 %6, %4
; CHECK-NEXT:  %22 = call %__cheriseed_cap_t* @global_cap_200()
; CHECK-NEXT:  %23 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %22, i64 4, i32 2)
; CHECK-NEXT:  %24 = inttoptr i64 %23 to i32*
; CHECK-NEXT:  store i32 %21, i32* %24, align 4
  store i32 %7, i32 addrspace(200)* @global_cap_200, align 4
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @test_sum_hybrid_globals
define void @test_sum_hybrid_globals() {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = call %__cheriseed_cap_t* @ptr_to_cap()
; CHECK-NEXT:  %4 = call %__cheriseed_cap_t* @__cheriseed_load_cap_hybrid(%__cheriseed_cap_t* %3, %__cheriseed_cap_t* %1)
  %1 = load i32 addrspace(200)*, i32 addrspace(200)** @ptr_to_cap, align 16
; CHECK-NEXT:  %5 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %4, i64 4, i32 1)
; CHECK-NEXT:  %6 = inttoptr i64 %5 to i32*
; CHECK-NEXT:  %7 = load i32, i32* %6, align 4
  %2 = load i32, i32 addrspace(200)* %1, align 4
; CHECK-NEXT:  %8 = call %__cheriseed_cap_t* @null_ptr_to_cap()
; CHECK-NEXT:  %9 = call %__cheriseed_cap_t* @__cheriseed_load_cap_hybrid(%__cheriseed_cap_t* %8, %__cheriseed_cap_t* %2)
  %3 = load i32 addrspace(200)*, i32 addrspace(200)** @null_ptr_to_cap, align 16
; CHECK-NEXT:  %10 = add nsw i32 %7, 42
  %4 = add nsw i32 %2, 42
; CHECK-NEXT:  %11 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %9, i64 4, i32 2)
; CHECK-NEXT:  %12 = inttoptr i64 %11 to i32*
; CHECK-NEXT:  store i32 %10, i32* %12, align 4
  store i32 %4, i32 addrspace(200)* %3, align 4
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; Regression for 'common' linkage: shadow capabilitites should not have that.
; Use 'weak' linkage instead. When a definition other than 'common' is present,
; it will be chosen by the linker instead. See -fcommon compiler option.

; COMMON-LINKAGE: @__cheriseed_global_global_common_linkage = common
; COMMON-LINKAGE: @__cheriseed_shadow_capability_global_common_linkage = weak global
; COMMON-LINKAGE: define weak %__cheriseed_cap_t* @global_common_linkage()
@global_common_linkage = common addrspace(200) global i8 0, align 1

; ------------------------------------------------------------------------------
