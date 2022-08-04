; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------

target datalayout = "p200:128:128:128:64"

%struct.S = type { i8, i8 addrspace(200)* }

; CHECK-LABEL: define void @gep_constant_01(%__cheriseed_cap_t* %0)
define void @gep_constant_01(%struct.S addrspace(200)* %0) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* %2, %__cheriseed_cap_t* %0, i64 32)
  %2 = getelementptr inbounds %struct.S, %struct.S addrspace(200)* %0, i64 1, i32 0
; CHECK-NEXT:  %4 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %3, i64 1, i32 2)
; CHECK-NEXT:  %5 = inttoptr i64 %4 to i8*
; CHECK-NEXT:  store i8 2, i8* %5, align 16
; CHECK-NEXT:  call void @__cheriseed_check_access_end(i64 %4, i64 1)
  store i8 2, i8 addrspace(200)* %2, align 16
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @gep_constant_02(%__cheriseed_cap_t* %0)
define void @gep_constant_02(%struct.S addrspace(200)* addrspace(200)* %0) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %4 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %5 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %6 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* %2, %__cheriseed_cap_t* %0, i64 16)
  %2 = getelementptr inbounds %struct.S addrspace(200)*, %struct.S addrspace(200)* addrspace(200)* %0, i64 1
; CHECK-NEXT:  %7 = call %__cheriseed_cap_t* @__cheriseed_load_cap(%__cheriseed_cap_t* %6, %__cheriseed_cap_t* %3)
  %3 = load %struct.S addrspace(200)*, %struct.S addrspace(200)* addrspace(200)* %2, align 16
; CHECK-NEXT:  %8 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* %4, %__cheriseed_cap_t* %7, i64 0)
  %4 = getelementptr inbounds %struct.S, %struct.S addrspace(200)* %3, i64 0, i32 0
; CHECK-NEXT:  %9 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %8, i64 1, i32 2)
; CHECK-NEXT:  %10 = inttoptr i64 %9 to i8*
; CHECK-NEXT:  store i8 2, i8* %10, align 16
; CHECK-NEXT:  call void @__cheriseed_check_access_end(i64 %9, i64 1)
  store i8 2, i8 addrspace(200)* %4, align 16
; CHECK-NEXT:  %11 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* %5, %__cheriseed_cap_t* %7, i64 16)
  %5 = getelementptr inbounds %struct.S, %struct.S addrspace(200)* %3, i64 0, i32 1
; CHECK-NEXT:  call void @__cheriseed_store_cap(%__cheriseed_cap_t* %11, %__cheriseed_cap_t* %8)
  store i8 addrspace(200)* %4, i8 addrspace(200)* addrspace(200)* %5, align 16
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @gep_variable_01(%__cheriseed_cap_t* %0, i64 %1)
define void @gep_variable_01(%struct.S addrspace(200)* %0, i64 %1) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %3 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %4 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %0)
; CHECK-NEXT:  %5 = inttoptr i64 %4 to %struct.S*
; CHECK-NEXT:  %6 = getelementptr inbounds %struct.S, %struct.S* %5, i64 %1, i32 0
; CHECK-NEXT:  %7 = ptrtoint i8* %6 to i64
; CHECK-NEXT:  %8 = call %__cheriseed_cap_t* @__cheriseed_address_set(%__cheriseed_cap_t* %3, %__cheriseed_cap_t* %0, i64 %7)
  %3 = getelementptr inbounds %struct.S, %struct.S addrspace(200)* %0, i64 %1, i32 0
; CHECK-NEXT:  %9 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %8, i64 1, i32 2)
; CHECK-NEXT:  %10 = inttoptr i64 %9 to i8*
; CHECK-NEXT:  store i8 2, i8* %10, align 16
; CHECK-NEXT:  call void @__cheriseed_check_access_end(i64 %9, i64 1)
  store i8 2, i8 addrspace(200)* %3, align 16
; CHECK-NEXT:  ret void
  ret void
}

; Equivalent to
; int gep_regression(int *v, int c) {
;    return v[c];
; }
; CHECK-LABEL: define i32 @gep_regression(%__cheriseed_cap_t* %0, i32 %1)
define i32 @gep_regression(i32 addrspace(200)* %0, i32 %1) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %3 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %4 = sext i32 %1 to i64
  %3 = sext i32 %1 to i64
; CHECK-NEXT:  %5 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %0)
; CHECK-NEXT:  %6 = inttoptr i64 %5 to i32*
; CHECK-NEXT:  %7 = getelementptr inbounds i32, i32* %6, i64 %4
; CHECK-NEXT:  %8 = ptrtoint i32* %7 to i64
; CHECK-NEXT:  %9 = call %__cheriseed_cap_t* @__cheriseed_address_set(%__cheriseed_cap_t* %3, %__cheriseed_cap_t* %0, i64 %8)
  %4 = getelementptr inbounds i32, i32 addrspace(200)* %0, i64 %3
; CHECK-NEXT:  %10 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %9, i64 4, i32 1)
; CHECK-NEXT:  %11 = inttoptr i64 %10 to i32*
; CHECK-NEXT:  %12 = load i32, i32* %11, align 4
  %5 = load i32, i32 addrspace(200)* %4, align 4
; CHECK-NEXT:  ret i32 %12
  ret i32 %5
}

; ------------------------------------------------------------------------------
; Check that the pass handles ConstantExpr well in GEPs (GetElementPtrConstantExpr).

%struct.S2 = type { i8, i8 }
@C_S2 = internal constant [2 x %struct.S2] [%struct.S2 {i8 0, i8 1}, %struct.S2 {i8 2, i8 3}], align 1

; CHECK-LABEL: @gep_constant_expr
define %struct.S2* @gep_constant_expr() {
; CHECK-NEXT:  %1 = call [2 x %struct.S2]* @C_S2()
; CHECK-NEXT:  %2 = getelementptr inbounds [2 x %struct.S2], [2 x %struct.S2]* %1, i64 0, i64 0
  %1 = getelementptr inbounds [2 x %struct.S2], [2 x %struct.S2]* @C_S2, i64 0, i64 0
; CHECK-NEXT:  %3 = getelementptr inbounds %struct.S2, %struct.S2* %2, i64 1
  %2 = getelementptr inbounds %struct.S2, %struct.S2* %1, i64 1
; CHECK-NEXT:  ret %struct.S2* %3
  ret %struct.S2* %2
}

; ------------------------------------------------------------------------------
; Regression test for 'i8 addrspace(200)*' in a GEP.

; CHECK-LABEL: @gep_capability
define void @gep_capability(i8 addrspace(200)** %p) {
; CHECK-NEXT:  %1 = getelementptr inbounds %__cheriseed_cap_t, %__cheriseed_cap_t* %p, i64 0
  %1 = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)** %p, i64 0
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; Regression test GEP to a capability.

; CHECK-LABEL: @gep_capability_2
define void @gep_capability_2(i8 addrspace(200)* addrspace(200)* %0) addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* %2, %__cheriseed_cap_t* %0, i64 16)
  %2 = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %0, i64 1
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; Regression test GEP to an array of capabilities

; CHECK-LABEL: @gep_capability_array
define void @gep_capability_array(i8 addrspace(200)* addrspace(200)* %c, i64 %i) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %2 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %c)
; CHECK-NEXT:  %3 = inttoptr i64 %2 to %__cheriseed_cap_t*
; CHECK-NEXT:  %4 = getelementptr %__cheriseed_cap_t, %__cheriseed_cap_t* %3, i64 %i
; CHECK-NEXT:  %5 = ptrtoint %__cheriseed_cap_t* %4 to i64
; CHECK-NEXT:  %6 = call %__cheriseed_cap_t* @__cheriseed_address_set(%__cheriseed_cap_t* %1, %__cheriseed_cap_t* %c, i64 %5)
  %1 = getelementptr i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %c, i64 %i
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; Regression test GEP to a structure with an array of capabilities.

%struct.S3 = type { [42 x i32 addrspace(200)*] }

; CHECK-LABEL: @gep_struct_capability
define i32 addrspace(200)* @gep_struct_capability(i32 %0, %struct.S3 addrspace(200)* nocapture readonly %1) local_unnamed_addr addrspace(200) #0 {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %4 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %5 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %6 = sext i32 %1 to i64
  %3 = sext i32 %0 to i64
; CHECK-NEXT:  %7 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %2)
; CHECK-NEXT:  %8 = inttoptr i64 %7 to %struct.S3*
; CHECK-NEXT:  %9 = getelementptr inbounds %struct.S3, %struct.S3* %8, i64 0, i32 0, i64 %6
; CHECK-NEXT:  %10 = ptrtoint %__cheriseed_cap_t* %9 to i64
; CHECK-NEXT:  %11 = call %__cheriseed_cap_t* @__cheriseed_address_set(%__cheriseed_cap_t* %4, %__cheriseed_cap_t* %2, i64 %10)
  %4 = getelementptr inbounds %struct.S3, %struct.S3 addrspace(200)* %1, i64 0, i32 0, i64 %3
; CHECK-NEXT:  %12 = call %__cheriseed_cap_t* @__cheriseed_load_cap(%__cheriseed_cap_t* %11, %__cheriseed_cap_t* %5)
  %5 = load i32 addrspace(200)*, i32 addrspace(200)* addrspace(200)* %4, align 16
; CHECK-NEXT:  %13 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* %0, %__cheriseed_cap_t* %12, i64 0)
; CHECK-NEXT:  ret %__cheriseed_cap_t* %0
  ret i32 addrspace(200)* %5
}
