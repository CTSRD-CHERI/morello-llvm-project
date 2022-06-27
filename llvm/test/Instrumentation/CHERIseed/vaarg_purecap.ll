; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------

target datalayout = "pf200:128:128:128:64-S128-A200-P200-G200"

%struct.S1 = type { i8 }
%struct.S2 = type { i128 }

; CHECK-LABEL: define void @caller_novarargs()
define void @caller_novarargs() addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  [[VA_SLOT_SHADOW_CAP:%.*]] = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  [[VA_SLOT_CAP:%.*]] = tail call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(%__cheriseed_cap_t* [[VA_SLOT_SHADOW_CAP]], i64 0, i64 0)
; CHECK-NEXT:  call void @callee(i32 0, %__cheriseed_cap_t* [[VA_SLOT_CAP]])
  call void (i32, ...) @callee(i32 0)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: define void @caller()
define void @caller() addrspace(200) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  [[VA_SLOT:%.*]] = alloca i8, i64 112, align 16
; CHECK-NEXT:  [[VA_SLOT_SHADOW_CAP:%.*]] = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  [[VA_SLOT_ADDR:%.*]] = ptrtoint i8* [[VA_SLOT]] to i64
; CHECK-NEXT:  [[VA_SLOT_CAP:%.*]] = tail call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(%__cheriseed_cap_t* [[VA_SLOT_SHADOW_CAP]], i64 [[VA_SLOT_ADDR]], i64 112)

; i8 1,
; CHECK-NEXT:  [[AG:%.*]] = getelementptr inbounds i8, i8* [[VA_SLOT]], i32 0
; CHECK-NEXT:  [[CLR:%.*]] = bitcast i8* [[AG:%.*]] to %__cheriseed_cap_t*
; CHECK-NEXT:  store %__cheriseed_cap_t zeroinitializer, %__cheriseed_cap_t* [[CLR:%.*]], align 16
; CHECK-NEXT:  store i8 1, i8* [[AG]], align 16
; i128 2,
; CHECK-NEXT:  [[AG:%.*]] = getelementptr inbounds i8, i8* [[VA_SLOT]], i32 16
; CHECK-NEXT:  [[AB:%.*]] = bitcast i8* [[AG]] to i128*
; CHECK-NEXT:  store i128 2, i128* [[AB]], align 16
; %struct.S1 { i8 3 }
; CHECK-NEXT:  [[AG:%.*]] = getelementptr inbounds i8, i8* [[VA_SLOT]], i32 32
; CHECK-NEXT:  [[CLR:%.*]] = bitcast i8* [[AG:%.*]] to %__cheriseed_cap_t*
; CHECK-NEXT:  store %__cheriseed_cap_t zeroinitializer, %__cheriseed_cap_t* [[CLR:%.*]], align 16
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
; CHECK-NEXT:  tail call void @__cheriseed_store_cap_hybrid(%__cheriseed_cap_t* [[AB]], %__cheriseed_cap_t* null)

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

declare void @callee(i32, ...) addrspace(200)
