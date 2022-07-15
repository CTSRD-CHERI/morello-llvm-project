; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------

target datalayout = "pf200:128:128:128:64-S128-A200-P200-G200"

%struct.S1 = type { i8 }
%struct.S2 = type { i128 }
%struct.S3 = type { i128, i8 }
%union.U1 = type { i128 }

; ------------------------------------------------------------------------------

; CHECK-LABEL: define void @caller_novarargs()
define void @caller_novarargs() addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  [[VA_SLOT_SHADOW_CAP:%.*]] = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  [[VA_SLOT_CAP:%.*]] = call %__cheriseed_cap_t*
; CHECK-SAME:      @__cheriseed_stack_cap_init(%__cheriseed_cap_t*
; CHECK-SAME:      [[VA_SLOT_SHADOW_CAP]], i64 0, i64 0)
; CHECK-NEXT:  call void @callee(i32 0, %__cheriseed_cap_t* [[VA_SLOT_CAP]])
  call void (i32, ...) @callee(i32 0)
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------

; CHECK-LABEL: define void @caller()
define void @caller() addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  [[VA_SLOT:%.*]] = alloca i8, i64 112, align 16
; CHECK-NEXT:  [[VA_SLOT_SHADOW_CAP:%.*]] = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  [[VA_SLOT_ADDR:%.*]] = ptrtoint i8* [[VA_SLOT]] to i64
; CHECK-NEXT:  [[VA_SLOT_CAP:%.*]] = call %__cheriseed_cap_t*
; CHECK-SAME:      @__cheriseed_stack_cap_init(%__cheriseed_cap_t*
; CHECK-SAME:      [[VA_SLOT_SHADOW_CAP]], i64 [[VA_SLOT_ADDR]], i64 112)

; i8 1,
; CHECK-NEXT:  [[AG:%.*]] = getelementptr inbounds i8, i8* [[VA_SLOT]], i32 0
; CHECK-NEXT:  [[CLR:%.*]] = bitcast i8* [[AG:%.*]] to %__cheriseed_cap_t*
; CHECK-NEXT:  store %__cheriseed_cap_t zeroinitializer, %__cheriseed_cap_t*
; CHECK-SAME:      [[CLR:%.*]], align 16
; CHECK-NEXT:  store i8 1, i8* [[AG]], align 16
; i128 2,
; CHECK-NEXT:  [[AG:%.*]] = getelementptr inbounds i8, i8* [[VA_SLOT]], i32 16
; CHECK-NEXT:  [[AB:%.*]] = bitcast i8* [[AG]] to i128*
; CHECK-NEXT:  store i128 2, i128* [[AB]], align 16
; %struct.S1 { i8 3 }
; CHECK-NEXT:  [[AG:%.*]] = getelementptr inbounds i8, i8* [[VA_SLOT]], i32 32
; CHECK-NEXT:  [[CLR:%.*]] = bitcast i8* [[AG:%.*]] to %__cheriseed_cap_t*
; CHECK-NEXT:  store %__cheriseed_cap_t zeroinitializer, %__cheriseed_cap_t*
; CHECK-SAME:      [[CLR:%.*]], align 16
; CHECK-NEXT:  [[AB:%.*]] = bitcast i8* [[AG]] to %struct.S1*
; CHECK-NEXT:  store %struct.S1 { i8 3 }, %struct.S1* [[AB]], align 16
; %struct.S2 { i128 4 }
; CHECK-NEXT:  [[AG:%.*]] = getelementptr inbounds i8, i8* [[VA_SLOT]], i32 48
; CHECK-NEXT:  [[AB:%.*]] = bitcast i8* [[AG]] to %struct.S2*
; CHECK-NEXT:  store %struct.S2 { i128 4 }, %struct.S2* [[AB]], align 16
; [16 x i8] undef
; CHECK-NEXT:  [[AG:%.*]] = getelementptr inbounds i8, i8* [[VA_SLOT]], i32 64
; CHECK-NEXT:  [[AB:%.*]] = bitcast i8* [[AG]] to [16 x i8]*
; CHECK-NEXT:  store [16 x i8] undef, [16 x i8]* [[AB]], align 16
; <16 x i8> undef
; CHECK-NEXT:  [[AG:%.*]] = getelementptr inbounds i8, i8* [[VA_SLOT]], i32 80
; CHECK-NEXT:  [[AB:%.*]] = bitcast i8* [[AG]] to <16 x i8>*
; CHECK-NEXT:  store <16 x i8> undef, <16 x i8>* [[AB]], align 16
; i8 addrspace(200)* undef
; CHECK-NEXT:  [[AG:%.*]] = getelementptr inbounds i8, i8* [[VA_SLOT]], i32 96
; CHECK-NEXT:  [[AB:%.*]] = bitcast i8* [[AG]] to %__cheriseed_cap_t*
; CHECK-NEXT:  call void @__cheriseed_store_cap_hybrid(%__cheriseed_cap_t*
; CHECK-SAME:      [[AB]], %__cheriseed_cap_t* null)

; CHECK-NEXT:  call void @callee(i32 0, %__cheriseed_cap_t* [[VA_SLOT_CAP]])
  call void (i32, ...) @callee(i32 0,
; Types <= 16 bytes
    i8 1,
    i128 2,
    %struct.S1 { i8 3 },
    %struct.S2 { i128 4 },
    [16 x i8] undef,
    <16 x i8> undef,
    i8 addrspace(200)* undef
  )
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------

; CHECK-LABEL: define void @caller_byval_16bytes()
define void @caller_byval_16bytes() addrspace(200) {
; CHECK-NEXT:  %u = alloca %union.U1, align 16
; CHECK-NEXT:  %u.addr = ptrtoint %union.U1* %u to i64
; CHECK-NEXT:  %u.shadow.cap = alloca %__cheriseed_cap_t, align 16
  %u = alloca %union.U1, align 16, addrspace(200)
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  [[VA_SLOT:%.*]] = alloca i8, i64 16, align 16
; CHECK-NEXT:  [[VA_SLOT_SHADOW_CAP:%.*]] = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %u.cap =  call %__cheriseed_cap_t*
; CHECK-SAME:      @__cheriseed_stack_cap_init(%__cheriseed_cap_t*
; CHECK_SAME:      %u.shadow.cap, i64 %u.addr, i64 16)
; CHECK-NEXT:  [[VA_SLOT_ADDR:%.*]] = ptrtoint i8* [[VA_SLOT]] to i64
; CHECK-NEXT:  [[VA_SLOT_CAP:%.*]] = call %__cheriseed_cap_t*
; CHECK-SAME:      @__cheriseed_stack_cap_init(%__cheriseed_cap_t*
; CHECK-SAME:      [[VA_SLOT_SHADOW_CAP]], i64 [[VA_SLOT_ADDR]], i64 16)
; CHECK-NEXT:  [[AG:%.*]] = getelementptr inbounds i8, i8* %va_slot, i32 0
; CHECK-NEXT:  [[AB:%.*]] = bitcast i8* [[AG]] to %union.U1*
; CHECK-NEXT:  [[U_ADDR:%.*]] = call i64 @__cheriseed_check_access(
; CHECK-SAME:      %__cheriseed_cap_t* %u.cap, i64 16, i32 1)
; CHECK-NEXT:  [[I2P:%.*]] = inttoptr i64 %3 to %union.U1*
; CHECK-NEXT:  [[U:%.*]] = load %union.U1, %union.U1* [[I2P]], align 16
; CHECK-NEXT:  store %union.U1 [[U]], %union.U1* [[AB]], align 16
; CHECK-NEXT:  call void @callee(i32 0, %__cheriseed_cap_t* %va_slot.cap)
  call void (i32, ...) @callee(i32 0,
  %union.U1 addrspace(200)* byval(%union.U1) align 16 %u
  )
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------

; CHECK-LABEL: define void @caller_byval()
define void @caller_byval() addrspace(200) {
; CHECK-NEXT:  %s = alloca %struct.S3, align 16
; CHECK-NEXT:  %s.addr = ptrtoint %struct.S3* %s to i64
; CHECK-NEXT:  %s.shadow.cap = alloca %__cheriseed_cap_t, align 16
  %s = alloca %struct.S3, align 16, addrspace(200)
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  [[VA_SLOT:%.*]] = alloca i8, i64 16, align 16
; CHECK-NEXT:  [[VA_SLOT_SHADOW_CAP:%.*]] = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %s.cap =  call %__cheriseed_cap_t*
; CHECK-SAME:      @__cheriseed_stack_cap_init(%__cheriseed_cap_t*
; CHECK-SAME:      %s.shadow.cap, i64 %s.addr, i64 20)
; CHECK-NEXT:  [[VA_SLOT_ADDR:%.*]] = ptrtoint i8* [[VA_SLOT]] to i64
; CHECK-NEXT:  [[VA_SLOT_CAP:%.*]] = call %__cheriseed_cap_t*
; CHECK-SAME:      @__cheriseed_stack_cap_init(%__cheriseed_cap_t*
; CHECK-SAME:      [[VA_SLOT_SHADOW_CAP]], i64 [[VA_SLOT_ADDR]], i64 16)
; CHECK-NEXT:  [[AG:%.*]] = getelementptr inbounds i8, i8* %va_slot, i32 0
; CHECK-NEXT:  [[AB:%.*]] = bitcast i8* [[AG]] to %__cheriseed_cap_t*
; CHECK-NEXT:  call void @__cheriseed_store_cap_hybrid(%__cheriseed_cap_t*
; CHECK-SAME:      [[AB]], %__cheriseed_cap_t* %s.cap)
; CHECK-NEXT:  call void @callee(i32 0, %__cheriseed_cap_t* %va_slot.cap)
  call void (i32, ...) @callee(i32 0,
  %struct.S3 addrspace(200)* byval(%struct.S3) align 16 %s
  )
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------

declare void @callee(i32, ...) addrspace(200)
