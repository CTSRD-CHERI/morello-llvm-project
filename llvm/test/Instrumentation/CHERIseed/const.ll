; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -passes=cheriseed -S < %s | FileCheck --check-prefix=CHECK-TYPE %s
; RUN: opt -cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck --check-prefix=CHECK-TYPE %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------
; General-purpose function for testing.

declare void @sink(i32, ...)

; ------------------------------------------------------------------------------
; Test addspacecast with ConstExpr.

declare void @bar()

; CHECK-LABEL: define %__cheriseed_cap_t* @foo(%__cheriseed_cap_t* returned align 16 %0)
define i32 addrspace(200)* @foo() {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = bitcast void ()* @bar to i32*
; CHECK-NEXT:  %4 = tail call %__cheriseed_cap_t* @__cheriseed_ddc_get(%__cheriseed_cap_t* %2)
; CHECK-NEXT:  %5 = ptrtoint i32* %3 to i64
; CHECK-NEXT:  %6 = tail call %__cheriseed_cap_t* @__cheriseed_address_set(%__cheriseed_cap_t* %4, %__cheriseed_cap_t* %4, i64 %5)
; CHECK-NEXT:  %7 = tail call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* %0, %__cheriseed_cap_t* %6, i64 0)
; CHECK-NEXT:  ret %__cheriseed_cap_t* %0
  ret i32 addrspace(200)* addrspacecast (i32* bitcast (void ()* @bar to i32*) to i32 addrspace(200)*)
}

; ------------------------------------------------------------------------------
; Test handling ConstantAggregateZero.

; CHECK-LABEL: @caz_struct
define { i8, i8*, i8 addrspace(200)*, i8 addrspace(200)** } @caz_struct() {
; %0 here because Type mapping will map anonymous struct below.
; CHECK-TYPE:  %0 = type { i8, i8*, %__cheriseed_cap_t, %__cheriseed_cap_t* }
; CHECK-NEXT:  ret %0 zeroinitializer
  ret { i8, i8*, i8 addrspace(200)*, i8 addrspace(200)** } zeroinitializer
}

; CHECK-LABEL: @caz_array_1
define [2 x i8] @caz_array_1() {
; CHECK-NEXT:  ret [2 x i8] zeroinitializer
  ret [2 x i8] zeroinitializer
}

; CHECK-LABEL: @caz_array_2
define [2 x i8 addrspace(200)*] @caz_array_2() {
; CHECK-NEXT:  ret [2 x %__cheriseed_cap_t] zeroinitializer
  ret [2 x i8 addrspace(200)*] zeroinitializer
}

; CHECK-LABEL: @caz_array_3
define [2 x i8 addrspace(200)**] @caz_array_3() {
; CHECK-NEXT:  ret [2 x %__cheriseed_cap_t*] zeroinitializer
  ret [2 x i8 addrspace(200)**] zeroinitializer
}

; CHECK-LABEL: @caz_vector_1
define <2 x i8> @caz_vector_1() {
  ret <2 x i8> zeroinitializer
}

; FIXME: Would get transformed into <2 x %__cheriseed_cap_t> and it would
; trigger an assert.
; _CHECK-LABEL: @caz_vector_2
; define <2 x i8 addrspace(200)*> @caz_vector_2() {
; _CHECK-NEXT:  ret <2 x %__cheriseed_cap_t> zeroinitializer
;   ret <2 x i8 addrspace(200)*> zeroinitializer
; }

; ------------------------------------------------------------------------------
; Test handling UndefValue ('undef').

%struct.Undef = type { i8 }

; CHECK-LABEL: @undef
define void @undef(i1 %0, %struct.Undef* %1) {
La:
  br i1 %0, label %Lb, label %Lc
Lb:
  br label %Lc
Lc:
; CHECK: %2 = phi %struct.Undef* [ undef, %La.Lc_crit_edge ], [ %1, %Lb ]
  %2 = phi %struct.Undef* [ undef, %La ], [ %1, %Lb ]
  ret void
}

; ------------------------------------------------------------------------------
; Test for ConstantStruct

; CHECK-LABEL: @constant_struct
define void @constant_struct() {
; CHECK-NEXT:  call void (i32, ...) @sink(i32 undef, { i64, i64 } { i64 0, i64 1 })
  call void (i32, ...) @sink(i32 undef, { i64, i64 } { i64 0, i64 1 })
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: { i64, i64 } @return_constant_struct
define { i64, i64 } @return_constant_struct() {
; Note: this is no similar thing to ConstantDataArray,
;       this is actually a ConstantStruct here.
; CHECK-NEXT:  ret { i64, i64 } { i64 0, i64 1 }
  ret { i64, i64 } { i64 0, i64 1 }
}

; ------------------------------------------------------------------------------
; Test for ConstantArray

; CHECK-LABEL: @constant_array
define void @constant_array() {
; CHECK-NEXT:  call void (i32, ...) @sink(i32 undef, [2 x i64] [i64 1, i64 undef])
  call void (i32, ...) @sink(i32 undef, [2 x i64] [i64 1, i64 undef])
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: [2 x i64] @return_constant_array
define [2 x i64] @return_constant_array() {
; Note: this is actually ConstantDataArray
; CHECK-NEXT:  ret [2 x i64] [i64 0, i64 1]
  ret [2 x i64] [i64 0, i64 1]
}

; ------------------------------------------------------------------------------
; Test for ConstantVector

; CHECK-LABEL: @constant_vector
define void @constant_vector() {
; CHECK-NEXT:  %1 = insertelement <2 x i8> undef, i8 1, i32 0
  %1 = insertelement <2 x i8> undef, i8 1, i32 0
; CHECK-NEXT:  %2 = insertelement <2 x i8> <i8 undef, i8 1>, i8 1, i32 0
  %2 = insertelement <2 x i8> <i8 undef, i8 1>, i8 1, i32 0
; CHECK-NEXT:  call void (i32, ...) @sink(i32 undef, <2 x i8> <i8 undef, i8 1>)
  call void (i32, ...) @sink(i32 undef, <2 x i8> <i8 undef, i8 1>)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: <2 x i64> @return_constant_vector
define <2 x i64> @return_constant_vector() {
; Note: this is actually ConstantDataVector
; CHECK-NEXT:  ret <2 x i64> <i64 0, i64 1>
  ret <2 x i64> <i64 0, i64 1>
}

; ------------------------------------------------------------------------------
; Test that ConstExpr is always mapped.
; This should have only happended with ConstExpr, because those are uniqued
; Values but they are not to be transformed into "uniqued mappings".

@always_map_g = external global { i64 }

; CHECK-LABEL: @always_map
define void @always_map(i1 %cond) {
; CHECK-LABEL: entry:
entry:
; CHECK-NEXT:    %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:    %0 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:    %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:    br i1 %cond, label %l1, label %l2
  br i1 %cond, label %l1, label %l2

; CHECK-LABEL: l1:
l1:
; CHECK-NEXT:    %2 = tail call { i64 }* @always_map_g()
; CHECK-NEXT:    %3 = bitcast { i64 }* %2 to i8*
; CHECK-NEXT:    %4 = tail call %__cheriseed_cap_t* @__cheriseed_ddc_get(%__cheriseed_cap_t* %0)
; CHECK-NEXT:    %5 = ptrtoint i8* %3 to i64
; CHECK-NEXT:    %6 = tail call %__cheriseed_cap_t* @__cheriseed_address_set(%__cheriseed_cap_t* %4, %__cheriseed_cap_t* %4, i64 %5)
; CHECK-NEXT:    %7 = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %6, i64 1, i32 2)
; CHECK-NEXT:    %8 = inttoptr i64 %7 to i8*
; CHECK-NEXT:    store i8 42, i8* %8
  store i8 42, i8 addrspace(200)* addrspacecast (i64* getelementptr inbounds ({ i64 }, { i64 }* @always_map_g, i64 0, i32 0) to i8 addrspace(200)*)
; CHECK-NEXT:    br label %end
  br label %end

; CHECK-LABEL: l2:
l2:
; Ensure that constant expressions are always resolved in-place,
; rather than re-use %2, which is defined in a non-dominating block
; CHECK-NEXT:    %9 = tail call { i64 }* @always_map_g()
; CHECK-NEXT:    %10 = bitcast { i64 }* %9 to i8*
; CHECK-NEXT:    %11 = tail call %__cheriseed_cap_t* @__cheriseed_ddc_get(%__cheriseed_cap_t* %1)
; CHECK-NEXT:    %12 = ptrtoint i8* %10 to i64
; CHECK-NEXT:    %13 = tail call %__cheriseed_cap_t* @__cheriseed_address_set(%__cheriseed_cap_t* %11, %__cheriseed_cap_t* %11, i64 %12)
; CHECK-NEXT:    %14 = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %13, i64 1, i32 2)
; CHECK-NEXT:    %15 = inttoptr i64 %14 to i8*
; CHECK-NEXT:    store i8 42, i8* %15
  store i8 42, i8 addrspace(200)* addrspacecast (i64* getelementptr inbounds ({ i64 }, { i64 }* @always_map_g, i64 0, i32 0) to i8 addrspace(200)*)
; CHECK-NEXT:    br label %end
  br label %end

; CHECK-LABEL: end:
end:
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
