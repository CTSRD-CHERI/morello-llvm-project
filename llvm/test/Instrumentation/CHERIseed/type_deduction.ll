; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------
; Make sure there is no infinite recursion in Type mapping.

; CHECK-LABEL: %struct.A = type { %struct.B* }
%struct.A = type { %struct.B* }
; CHECK-NEXT: %struct.B = type { %struct.A* }
%struct.B = type { %struct.A* }

; CHECK-LABEL: define void @recursive1(%struct.A* %0)
define void @recursive1(%struct.A* %0) {
  ret void
}

; CHECK-LABEL: @argument_type_deduction
; Data pointers:
; CHECK-SAME:  i8* %0
; CHECK-SAME:  i8** %1
; CHECK-SAME:  %__cheriseed_cap_t* %2
; CHECK-SAME:  %__cheriseed_cap_t* %3
; CHECK-SAME:  %__cheriseed_cap_t** %4
; CHECK-SAME:  %__cheriseed_cap_t* %5
; CHECK-SAME:  %__cheriseed_cap_t* %6
; CHECK-SAME:  %__cheriseed_cap_t** %7
; Function pointers:
; CHECK-SAME:  i8 ()* %8
; CHECK-SAME:  i8 ()** %9
; CHECK-SAME:  %__cheriseed_cap_t* %10
; CHECK-SAME:  %__cheriseed_cap_t* %11
; CHECK-SAME:  %__cheriseed_cap_t* %12
; CHECK-SAME:  %__cheriseed_cap_t* %13
; CHECK-SAME:  %__cheriseed_cap_t* %14
define void @argument_type_deduction(
  i8* %0,
  i8** %1,
  i8 addrspace(200)* %2,
  i8 addrspace(200)** %3,
  i8 addrspace(200)*** %4,
  i8 addrspace(200)* addrspace(200)* %5,
  i8 addrspace(200)* addrspace(200)** %6,
  i8 addrspace(200)* addrspace(200)*** %7,
; Function pointers:
  i8 ()* %8,
  i8 ()** %9,
  i8 () addrspace(200)* %10,
  i8 () addrspace(200)** %11,
  i8 () addrspace(200)* addrspace(200)* %12,
  void (i8 addrspace(200)*) addrspace(200)* %13,
  i8 addrspace(200)* (i8 addrspace(200)*) addrspace(200)* %14
) {
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @alloca_type_deduction
define void @alloca_type_deduction() {
; CHECK-NEXT:  %1 = alloca i8*, align 8
  %1 = alloca i8*, align 8
; Check that increased alignment is preserved.
; CHECK-NEXT:  %2 = alloca i8**, align 16
  %2 = alloca i8**, align 16
; CHECK-NEXT:  %3 = alloca %__cheriseed_cap_t, align 16
  %3 = alloca i8 addrspace(200)*, align 16
; CHECK-NEXT:  %4 = alloca %__cheriseed_cap_t*, align 8
  %4 = alloca i8 addrspace(200)**, align 8
; CHECK-NEXT:  %5 = alloca %__cheriseed_cap_t**, align 8
  %5 = alloca i8 addrspace(200)***, align 8
; CHECK-NEXT:  %6 = alloca %__cheriseed_cap_t, align 16
  %6 = alloca i8 addrspace(200)* addrspace(200)*, align 16
; CHECK-NEXT:  %7 = alloca %__cheriseed_cap_t*, align 8
  %7 = alloca i8 addrspace(200)* addrspace(200)**, align 8
; CHECK-NEXT:  %8 = alloca %__cheriseed_cap_t**, align 8
  %8 = alloca i8 addrspace(200)* addrspace(200)***, align 8
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @function_type_deduction_1(%__cheriseed_cap_t* noalias readnone %0)
define void @function_type_deduction_1(i32 addrspace(200)* noalias readnone %0) {
; CHECK-NEXT:  ret void
  ret void
}

; Note: Omitting 'returned' keyword for %0 on purpose here.
; CHECK-LABEL: define %__cheriseed_cap_t* @function_type_deduction_2(
; CHECK-SAME:     %__cheriseed_cap_t* returned align 16 %0, %__cheriseed_cap_t* noalias readnone %1)
define i8 addrspace(200)* @function_type_deduction_2(i8 addrspace(200)* noalias readnone %0) {
; CHECK-NEXT:  %3 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:     %__cheriseed_cap_t* %0, %__cheriseed_cap_t* %1, i64 0)
; CHECK-NEXT:  ret %__cheriseed_cap_t* %0
  ret i8 addrspace(200)* %0
}

; Case when a capability parameter is marked as the return value; see 'returned' keyword.
; CHECK-LABEL: define %__cheriseed_cap_t* @function_type_deduction_3(
; CHECK-SAME:     %__cheriseed_cap_t* returned align 16 %0, %__cheriseed_cap_t* noalias readnone %1)
define i32 addrspace(200)* @function_type_deduction_3(i32 addrspace(200)* noalias readnone returned %0) {
; CHECK-NEXT:  %3 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:     %__cheriseed_cap_t* %0, %__cheriseed_cap_t* %1, i64 0)
; CHECK-NEXT:  ret %__cheriseed_cap_t* %0
  ret i32 addrspace(200)* %0
}

; CHECK-LABEL: define %__cheriseed_cap_t* @function_type_deduction_4(%__cheriseed_cap_t* returned %0)
define i32 addrspace(200)** @function_type_deduction_4(i32 addrspace(200)** returned %0) {
; CHECK-NEXT:  ret %__cheriseed_cap_t* %0
  ret i32 addrspace(200)** %0
}

; CHECK-NOT: "cheriseed-accessor"
; CHECK-NOT: "cheriseed-internal"
