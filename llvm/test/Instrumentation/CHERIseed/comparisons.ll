; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------

%struct.S = type { i32 }

; CHECK-LABEL: @eq
define void @eq(i8 addrspace(200)* %0, i8 addrspace(200)* %1) {
; CHECK-NEXT:  %3 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %0)
; CHECK-NEXT:  %4 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %1)
; CHECK-NEXT:  %5 = icmp eq i64 %3, %4
  %3 = icmp eq i8 addrspace(200)* %0, %1
; CHECK-NEXT:  %6 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %0)
; CHECK-NEXT:  %7 = icmp eq i64 %6, 0
  %4 = icmp eq i8 addrspace(200)* %0, null
; CHECK-NEXT:  %8 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %0)
; CHECK-NEXT:  %9 = icmp eq i64 0, %8
  %5 = icmp eq i8 addrspace(200)* null, %0
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @ne
define void @ne(i8 addrspace(200)* %0, i8 addrspace(200)* %1) {
; CHECK-NEXT:  %3 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %0)
; CHECK-NEXT:  %4 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %1)
; CHECK-NEXT:  %5 = icmp ne i64 %3, %4
  %3 = icmp ne i8 addrspace(200)* %0, %1
; CHECK-NEXT:  %6 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %0)
; CHECK-NEXT:  %7 = icmp ne i64 %6, 0
  %4 = icmp ne i8 addrspace(200)* %0, null
; CHECK-NEXT:  %8 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %0)
; CHECK-NEXT:  %9 = icmp ne i64 0, %8
  %5 = icmp ne i8 addrspace(200)* null, %0
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @ult
define void @ult(i8 addrspace(200)* %0, i8 addrspace(200)* %1) {
; CHECK-NEXT:  %3 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %0)
; CHECK-NEXT:  %4 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %1)
; CHECK-NEXT:  %5 = icmp ult i64 %3, %4
  %3 = icmp ult i8 addrspace(200)* %0, %1
; CHECK-NEXT:  %6 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %0)
; CHECK-NEXT:  %7 = icmp ult i64 %6, 0
  %4 = icmp ult i8 addrspace(200)* %0, null
; CHECK-NEXT:  %8 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %0)
; CHECK-NEXT:  %9 = icmp ult i64 0, %8
  %5 = icmp ult i8 addrspace(200)* null, %0
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @ugt
define void @ugt(i8 addrspace(200)* %0, i8 addrspace(200)* %1) {
; CHECK-NEXT:  %3 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %0)
; CHECK-NEXT:  %4 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %1)
; CHECK-NEXT:  %5 = icmp ugt i64 %3, %4
  %3 = icmp ugt i8 addrspace(200)* %0, %1
; CHECK-NEXT:  %6 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %0)
; CHECK-NEXT:  %7 = icmp ugt i64 %6, 0
  %4 = icmp ugt i8 addrspace(200)* %0, null
; CHECK-NEXT:  %8 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %0)
; CHECK-NEXT:  %9 = icmp ugt i64 0, %8
  %5 = icmp ugt i8 addrspace(200)* null, %0
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @ule
define void @ule(i8 addrspace(200)* %0, i8 addrspace(200)* %1) {
; CHECK-NEXT:  %3 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %0)
; CHECK-NEXT:  %4 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %1)
; CHECK-NEXT:  %5 = icmp ule i64 %3, %4
  %3 = icmp ule i8 addrspace(200)* %0, %1
; CHECK-NEXT:  %6 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %0)
; CHECK-NEXT:  %7 = icmp ule i64 %6, 0
  %4 = icmp ule i8 addrspace(200)* %0, null
; CHECK-NEXT:  %8 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %0)
; CHECK-NEXT:  %9 = icmp ule i64 0, %8
  %5 = icmp ule i8 addrspace(200)* null, %0
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @uge
define void @uge(i8 addrspace(200)* %0, i8 addrspace(200)* %1) {
; CHECK-NEXT:  %3 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %0)
; CHECK-NEXT:  %4 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %1)
; CHECK-NEXT:  %5 = icmp uge i64 %3, %4
  %3 = icmp uge i8 addrspace(200)* %0, %1
; CHECK-NEXT:  %6 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %0)
; CHECK-NEXT:  %7 = icmp uge i64 %6, 0
  %4 = icmp uge i8 addrspace(200)* %0, null
; CHECK-NEXT:  %8 = call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %0)
; CHECK-NEXT:  %9 = icmp uge i64 0, %8
  %5 = icmp uge i8 addrspace(200)* null, %0
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @hybrid
define void @hybrid(i8 addrspace(200)** %0, i8 addrspace(200)** %1) {
; CHECK-NEXT:  %3 = icmp eq %__cheriseed_cap_t* %0, %1
  %3 = icmp eq i8 addrspace(200)** %0, %1
; CHECK-NEXT:  %4 = icmp ne %__cheriseed_cap_t* %0, %1
  %4 = icmp ne i8 addrspace(200)** %0, %1
; CHECK-NEXT:  %5 = icmp ult %__cheriseed_cap_t* %0, %1
  %5 = icmp ult i8 addrspace(200)** %0, %1
; CHECK-NEXT:  %6 = icmp ugt %__cheriseed_cap_t* %0, %1
  %6 = icmp ugt i8 addrspace(200)** %0, %1
; CHECK-NEXT:  %7 = icmp ule %__cheriseed_cap_t* %0, %1
  %7 = icmp ule i8 addrspace(200)** %0, %1
; CHECK-NEXT:  %8 = icmp uge %__cheriseed_cap_t* %0, %1
  %8 = icmp uge i8 addrspace(200)** %0, %1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @struct_null
define void @struct_null(%struct.S* %0) {
; CHECK-NEXT:  %2 = icmp ne %struct.S* %0, null
  %2 = icmp ne %struct.S* %0, null
; CHECK-NEXT:  ret void
  ret void
}
