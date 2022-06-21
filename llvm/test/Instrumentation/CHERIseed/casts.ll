; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------
; addrspacecast

; CHECK-LABEL: define void @addrspacecast(i8* %0)
define void @addrspacecast(i8* %0) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_ddc_get(%__cheriseed_cap_t* %2)
; CHECK-NEXT:  %4 = ptrtoint i8* %0 to i64
; CHECK-NEXT:  %5 = tail call %__cheriseed_cap_t* @__cheriseed_address_set(%__cheriseed_cap_t* %3, %__cheriseed_cap_t* %3, i64 %4)
  %2 = addrspacecast i8* %0 to i8 addrspace(200)*
; CHECK-NEXT:  %6 = tail call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %5)
; CHECK-NEXT:  %7 = inttoptr i64 %6 to i8*
  %3 = addrspacecast i8 addrspace(200)* %2 to i8*
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; bitcast

; CHECK-LABEL: define void @bitcast_1(i8* %p, %__cheriseed_cap_t* %c)
define void @bitcast_1(i8* %p, i8 addrspace(200)* %c) {
; CHECK-NEXT:  %v1 = bitcast i8* %p to i64*
  %v1 = bitcast i8* %p to i64*
; CHECK-NEXT:  %v2 = bitcast i8* %p to %__cheriseed_cap_t*
  %v2 = bitcast i8* %p to i8 addrspace(200)**
; no-op
  %v3 = bitcast i8 addrspace(200)* %c to i64 addrspace(200)*
; no-op
  %v4 = bitcast i8 addrspace(200)* %c to i8 addrspace(200)*
; CHECK-NEXT:  ret void
  ret void
}

%struct.BC = type { i32 }

; CHECK-LABEL: define void @bitcast_2(%struct.BC* %0)
define void @bitcast_2(%struct.BC* %0) {
; CHECK-NEXT:  %2 = bitcast %struct.BC* %0 to %struct.BC**
  %2 = bitcast %struct.BC* %0 to %struct.BC**
  ret void
}

; This is an example of inlining mempcy. The compiler assumes it can use
; capability registers to perform the copy and thus preserve the tags.
; Memcpy doesn't care about types, all it sees is two ranges of linear memory.
; CHECK-LABEL: @bitcast_3
define void @bitcast_3(%struct.BC* %0, %struct.BC* %1) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %3 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %4 = bitcast %struct.BC* %0 to %__cheriseed_cap_t*
  %3 = bitcast %struct.BC* %0 to i8 addrspace(200)**
; CHECK-NEXT:  %5 = bitcast %struct.BC* %1 to %__cheriseed_cap_t*
  %4 = bitcast %struct.BC* %1 to i8 addrspace(200)**
; CHECK-NEXT:  %6 = tail call %__cheriseed_cap_t* @__cheriseed_load_cap_hybrid(%__cheriseed_cap_t* %4, %__cheriseed_cap_t* %3)
  %5 = load i8 addrspace(200)*, i8 addrspace(200)** %3, align 16
; CHECK-NEXT:  tail call void @__cheriseed_store_cap_hybrid(%__cheriseed_cap_t* %5, %__cheriseed_cap_t* %6)
  store i8 addrspace(200)* %5, i8 addrspace(200)** %4, align 16
; And it is also possible to cast back.
; CHECK-NEXT:  %7 = bitcast %__cheriseed_cap_t* %4 to [2 x i64]*
  %6 = bitcast i8 addrspace(200)** %3 to [2 x i64]*
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; bitcast function

define void @bitcast_func(...) {
  ret void
}

; CHECK-LABEL: @bitcast_function
define void @bitcast_function() {
; CHECK-NEXT:  %1 = bitcast void (...)* @bitcast_func to void ()*
  %1 = bitcast void (...)* @bitcast_func to void ()*
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; bitcast function alias

define void @bitcast_func_aliasee() {
  ret void
}

@bitcast_func_alias = alias void (...), bitcast (void ()* @bitcast_func_aliasee to void (...)*)

; CHECK-LABEL: @bitcast_function_alias
define void @bitcast_function_alias() {
; CHECK-NEXT:  %1 = bitcast void (...)* @bitcast_func_alias to void ()*
  %1 = bitcast void (...)* @bitcast_func_alias to void ()*
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; bitcast function alias - capabilitites

define void @bitcast_func_aliasee_2() addrspace(200) {
  ret void
}

@bitcast_func_alias_2 = alias void (...), bitcast (void () addrspace(200)* @bitcast_func_aliasee_2 to void (...) addrspace(200)*)

; CHECK-LABEL: @bitcast_function_alias_2
define void @bitcast_function_alias_2() addrspace(200) {
; TODO: This is conservative, optimize later
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %2 = tail call %__cheriseed_cap_t* @__cheriseed_pcc_get(%__cheriseed_cap_t* %1)
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_address_set(%__cheriseed_cap_t* %2, %__cheriseed_cap_t* %2, i64 ptrtoint (void (...)* @bitcast_func_alias_2 to i64))
; CHECK-NEXT:  %4 = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %3, i64 0, i32 5)
; CHECK-NEXT:  %5 = inttoptr i64 %4 to void ()*
; CHECK-NEXT:  call void %5()
  call addrspace(200) void bitcast (void (...) addrspace(200)* @bitcast_func_alias_2 to void () addrspace(200)*)()
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; ptrtoint

; CHECK-LABEL: define void @ptrtoint(i8* %0, %__cheriseed_cap_t* %1)
define void @ptrtoint(i8* %0, i8 addrspace(200)* %1) {
; CHECK-NEXT:  %3 = ptrtoint i8* %0 to i64
  %3 = ptrtoint i8* %0 to i64
; CHECK-NEXT:  %4 = tail call i64 @__cheriseed_address_get(%__cheriseed_cap_t* %1)
  %4 = ptrtoint i8 addrspace(200)* %1 to i64
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @ptrtoint_hybrid(%__cheriseed_cap_t* %0)
define void @ptrtoint_hybrid(i8 addrspace(200)** %0) {
; CHECK-NEXT:  %2 = ptrtoint %__cheriseed_cap_t* %0 to i64
  %2 = ptrtoint i8 addrspace(200)** %0 to i64
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; inttoptr

; CHECK-LABEL: define void @inttoptr(i64 %0, i8 %1)
define void @inttoptr(i64 %0, i8 %1) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %3 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %4 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %5 = inttoptr i64 %0 to i64*
  %3 = inttoptr i64 %0 to i64*
; CHECK-NEXT:  %6 = inttoptr i8 %1 to i8*
  %4 = inttoptr i8 %1 to i8*
; CHECK-NEXT:  %7 = tail call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* %3, %__cheriseed_cap_t* null, i64 %0)
  %5 = inttoptr i64 %0 to i8 addrspace(200)*
; CHECK-NEXT:  %8 = zext i8 %1 to i64
; CHECK-NEXT:  %9 = tail call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* %4, %__cheriseed_cap_t* null, i64 %8)
  %6 = inttoptr i8 %1 to i8 addrspace(200)*
; CHECK-NEXT:  ret void
  ret void
}
