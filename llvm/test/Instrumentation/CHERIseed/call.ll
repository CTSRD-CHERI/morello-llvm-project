; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------
; Pass a pointer to an extern function.

; CHECK-LABEL: define void @handler()
define void @handler() {
  ret void
}

; CHECK-LABEL: define void @add_handler()
define void @add_handler() {
; CHECK-NEXT:  call fastcc void @register_handler(void ()* @handler)
  call fastcc void @register_handler(void ()* @handler)
  ret void
}

; CHECK-LABEL: declare fastcc void @register_handler(void ()*)
declare fastcc void @register_handler(void ()*)

; ------------------------------------------------------------------------------
; Declare later than usage.

; CHECK-LABEL: define void @use_late_declaration(%__cheriseed_cap_t* %0)
define void @use_late_declaration(i8 addrspace(200)* %0) {
; CHECK-NEXT:  call void @late_declaration(%__cheriseed_cap_t* %0)
  call void @late_declaration(i8 addrspace(200)* %0)
  ret void
}

; CHECK-LABEL: declare void @late_declaration(%__cheriseed_cap_t*)
declare void @late_declaration(i8 addrspace(200)*)

; ------------------------------------------------------------------------------
; Define later than usage.

; CHECK-LABEL: define void @use_late_definition(%__cheriseed_cap_t* %0)
define void @use_late_definition(i8 addrspace(200)* %0) {
; CHECK-NEXT:  %2 = alloca void (%__cheriseed_cap_t*)*, align 8
  %2 = alloca void (i8 addrspace(200)*)*, align 8
; CHECK-NEXT:  store void (%__cheriseed_cap_t*)* @late_definition, void (%__cheriseed_cap_t*)** %2, align 8
  store void (i8 addrspace(200)*)* @late_definition, void (i8 addrspace(200)*)** %2, align 8
  ret void
}

; CHECK-LABEL: define void @late_definition(%__cheriseed_cap_t* %0)
define void @late_definition(i8 addrspace(200)* %0) {
  ret void
}

; ------------------------------------------------------------------------------
; Indirect function call via an Argument.

%struct.S = type { i8 addrspace(200)* }

; CHECK-LABEL: @call_func_ptr_1
define void @call_func_ptr_1(void (%struct.S*)* %f) {
; CHECK-NEXT:  call void %f(%struct.S* null)
  call void %f(%struct.S* null)
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; Indirect function call which returns a capability.

; CHECK-LABEL: @call_func_ptr_2
define void @call_func_ptr_2(i8 addrspace(200)* (i8 addrspace(200)*)* %f, i8 addrspace(200)* %p) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %2 = call %__cheriseed_cap_t* %f(%__cheriseed_cap_t* returned align 16 %1,
; CHECK-SAME:     %__cheriseed_cap_t* %p)
  call i8 addrspace(200)* %f(i8 addrspace(200)* %p)
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; Indirect function call which returns a capability, onstack, hybrid.

; CHECK-LABEL: @call_func_ptr_8
define void @call_func_ptr_8() {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = call %__cheriseed_cap_t* @__cheriseed_pcc_get(%__cheriseed_cap_t* %1)
  %1 = call i8 addrspace(200)* @llvm.cheri.pcc.get()
; CHECK-NEXT:  %4 = ptrtoint void ()* @call_func_ptr_8_callee to i64
; CHECK-NEXT:  %5 = call %__cheriseed_cap_t* @__cheriseed_address_set(%__cheriseed_cap_t* %2, %__cheriseed_cap_t* %3, i64 %4)
; CHECK-NEXT:  %6 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %5, i64 1, i32 2, i64 0)
  %2 = call i8 addrspace(200)* @llvm.cheri.cap.from.pointer.i64(i8 addrspace(200)* %1, i64 ptrtoint (void ()* @call_func_ptr_8_callee to i64))
; CHECK-NEXT:  %7 = inttoptr i64 %6 to void ()*
  %3 = bitcast i8 addrspace(200)* %2 to void () addrspace(200)*
; CHECK-NEXT:  call void %7()
  call void %3()
; CHECK-NEXT:  ret void
  ret void
}

; CHECK: @call_func_ptr_8_callee
declare void @call_func_ptr_8_callee()
declare i8 addrspace(200)* @llvm.cheri.pcc.get()
declare i8 addrspace(200)* @llvm.cheri.cap.from.pointer.i64(i8 addrspace(200)*, i64)

; ------------------------------------------------------------------------------
; Indirect function call which returns a capability, onstack, purecap
; Note that alloca is not in the AS200, because this file has no target-layout
; defined.

; CHECK-LABEL: @call_func_ptr_9
define void @call_func_ptr_9() addrspace(200) {
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = alloca %__cheriseed_cap_t, align 16
  %1 = alloca void () addrspace(200)*, align 16
; CHECK-NEXT:  %4 = call %__cheriseed_cap_t* @__cheriseed_generic_cap_init(
; CHECK-SAME:     %__cheriseed_cap_t* %2,
; CHECK-SAME:     i64 ptrtoint (void ()* @call_func_ptr_9_callee to i64),
; CHECK-SAME:     i64 1,
; CHECK-SAME:     i32 60)
; CHECK-NEXT:  call void @__cheriseed_store_cap_hybrid(%__cheriseed_cap_t* %1, %__cheriseed_cap_t* %4)
  store void () addrspace(200)* @call_func_ptr_9_callee, void () addrspace(200)** %1, align 16
; CHECK-NEXT:  %5 = call %__cheriseed_cap_t* @__cheriseed_load_cap_hybrid(%__cheriseed_cap_t* %1,
; CHECK-SAME:     %__cheriseed_cap_t* %3)
  %2 = load void () addrspace(200)*, void () addrspace(200)** %1, align 16
; CHECK-NEXT:  %6 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %5, i64 1, i32 2, i64 0)
; CHECK-NEXT:  %7 = inttoptr i64 %6 to void ()*
; CHECK-NEXT:  call void %7()
  call void %2()
; CHECK-NEXT:  ret void
  ret void
}

; CHECK: @call_func_ptr_9_callee
declare void @call_func_ptr_9_callee() addrspace(200)

; ------------------------------------------------------------------------------
; Indirect function call via an Instruction.

; CHECK-LABEL: @call_func_ptr_3
define void @call_func_ptr_3(void ()** %p) {
; CHECK-NEXT:  %1 = load void ()*, void ()** %p, align 4
  %1 = load void ()*, void ()** %p, align 4
; CHECK-NEXT:  call void %1()
  call void %1()
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @call_func_ptr_5
define void @call_func_ptr_5(void (%struct.S*)** %p) {
; CHECK-NEXT:  %1 = load void (%struct.S*)*, void (%struct.S*)** %p, align 4
  %1 = load void (%struct.S*)*, void (%struct.S*)** %p, align 4
; CHECK-NEXT:  call void %1(%struct.S* null)
  call void %1(%struct.S* null)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @call_func_ptr_6
define void @call_func_ptr_6(void () addrspace(200)* addrspace(200)* %cap) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %2 = call %__cheriseed_cap_t* @__cheriseed_load_cap(%__cheriseed_cap_t* %cap, %__cheriseed_cap_t* %1, i64 0)
  %1 = load void () addrspace(200)*, void () addrspace(200)* addrspace(200)* %cap, align 16
; CHECK-NEXT:  %3 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %2, i64 1, i32 2, i64 0)
; CHECK-NEXT:  %4 = inttoptr i64 %3 to void ()*
; CHECK-NEXT:  call void %4()
  call void %1()
; CHECK-NEXT: ret void
  ret void
}

; CHECK-LABEL: @call_func_ptr_7
define void @call_func_ptr_7([4 x void () addrspace(200)*] addrspace(200)* %0){
; CHECK-NEXT  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT  %3 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* %0, %__cheriseed_cap_t* %2, i64 48)
  %2 = getelementptr inbounds [4 x void () addrspace(200)*], [4 x void () addrspace(200)*] addrspace(200)* %0, i64 1, i64 2
; CHECK-NEXT  %4 = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %3, i64 8, i32 2, i64 0)
; CHECK-NEXT  %5 = inttoptr i64 %4 to void ()**
; CHECK-NEXT  %6 = load void ()*, void ()** %5, align 16
  %3 = load void () addrspace(200)*, void () addrspace(200)* addrspace(200)* %2, align 16
; CHECK-NEXT  call void %6()
  call void %3() #2
; CHECK-NEXT  ret void
  ret void
}

; ------------------------------------------------------------------------------
; Indirect function call mixed with a ConstantExpr.

declare i32 @global_func(...)

; CHECK-LABEL: @call_func_ptr_4
define void @call_func_ptr_4() {
; CHECK-NEXT:  %1 = bitcast i32 (...)* @global_func to i32 ()*
; CHECK-NEXT:  %call = call i32 %1()
  %call = call i32 bitcast (i32 (...)* @global_func to i32 ()*)()
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; Test that the pass can mutate FunctionType of a call.

; CHECK-LABEL: @mutate_functiontype
define void @mutate_functiontype() {
; CHECK-NEXT:  %umul = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 1, i64 2)
  %umul = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 1, i64 2)
; CHECK-NEXT:  %umul.ov = extractvalue { i64, i1 } %umul, 1
  %umul.ov = extractvalue { i64, i1 } %umul, 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL:  declare { i64, i1 } @llvm.umul.with.overflow.i64(i64, i64)
declare { i64, i1 } @llvm.umul.with.overflow.i64(i64, i64)

; ------------------------------------------------------------------------------
; Test byval<ty> in parameter list.

%struct.byval = type { i8 addrspace(200)* }

; CHECK-LABEL: define void @func_byval_1(%struct.byval* byval(%struct.byval) align 16 %0)
define void @func_byval_1(%struct.byval* byval(%struct.byval) align 16 %0) {
  ret void
}

; CHECK-LABEL: define void @func_byval_2(%__cheriseed_cap_t* align 16 %0)
define void @func_byval_2(i8 addrspace(200)* byval(i8) align 16 %0) {
  ret void
}

; ------------------------------------------------------------------------------
; Test byval<ty> calls: must make a copy.

; CHECK-LABEL: define void @func_byval_caller_1(%struct.byval* %0)
define void @func_byval_caller_1(%struct.byval* %0) {
; CHECK-NEXT:  call void @func_byval_1(%struct.byval* byval(%struct.byval) align 16 %0)
  call void @func_byval_1(%struct.byval* byval(%struct.byval) align 16 %0)
  ret void
}

; CHECK-LABEL: define void @func_byval_caller_2(%struct.byval* %0)
define void @func_byval_caller_2(%struct.byval* %0) {
; CHECK-NEXT:  call void @func_byval_1(%struct.byval* byval(%struct.byval) %0)
  call void @func_byval_1(%struct.byval* byval(%struct.byval) %0)
  ret void
}

%struct.byval.3 = type [42 x i8]

declare void @func_byval_call_3(%struct.byval.3 addrspace(200)* byval(%struct.byval.3) align 16);

; CHECK-LABEL: define void @func_byval_caller_3(i1 %cond, %__cheriseed_cap_t* %s)
define void @func_byval_caller_3(i1 %cond, %struct.byval.3 addrspace(200)* %s) {
; CHECK-LABEL: entry:
entry:
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %byval_cpy = alloca [42 x i8], align 1
; CHECK-NEXT:  %byval_cpy.shadow.cap = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %byval_cpy1 = alloca [42 x i8], align 1
; CHECK-NEXT:  %byval_cpy1.shadow.cap = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  br i1 %cond, label %if, label %else
  br i1 %cond, label %if, label %else

; CHECK-LABEL: if:
if:
; CHECK-NEXT:  %byval_cpy.addr = ptrtoint [42 x i8]* %byval_cpy to i64
; CHECK-NEXT:  %byval_cpy.cap = call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(
; CHECK-SAME:     %__cheriseed_cap_t* %byval_cpy.shadow.cap, i64 %byval_cpy.addr, i64 42)
; CHECK-NEXT:  %0 = call %__cheriseed_cap_t* @memcpy_c(%__cheriseed_cap_t* returned %byval_cpy.cap,
; CHECK-SAME:     %__cheriseed_cap_t* %byval_cpy.cap, %__cheriseed_cap_t* %s, i64 42)
; CHECK-NEXT:  call void @func_byval_call_3(%__cheriseed_cap_t* %0)
; CHECK-NEXT:  br label %exit
  call void @func_byval_call_3(%struct.byval.3 addrspace(200)* byval(%struct.byval.3) %s)
  br label %exit

; CHECK-LABEL: else:
else:
; CHECK-NEXT:  %byval_cpy1.addr = ptrtoint [42 x i8]* %byval_cpy1 to i64
; CHECK-NEXT:  %byval_cpy1.cap = call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(
; CHECK-SAME:     %__cheriseed_cap_t* %byval_cpy1.shadow.cap, i64 %byval_cpy1.addr, i64 42)
; CHECK-NEXT:  %1 = call %__cheriseed_cap_t* @memcpy_c(%__cheriseed_cap_t* returned %byval_cpy1.cap,
; CHECK-SAME:     %__cheriseed_cap_t* %byval_cpy1.cap, %__cheriseed_cap_t* %s, i64 42)
; CHECK-NEXT:  call void @func_byval_call_3(%__cheriseed_cap_t* %1)
; CHECK-NEXT:  br label %exit
  call void @func_byval_call_3(%struct.byval.3 addrspace(200)* byval(%struct.byval.3) %s)
  br label %exit

; CHECK-LABEL: exit:
exit:
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; Test dereferenceable attribute
; This attribute is not valid with '%__cheriseed_cap_t'.

; CHECK: declare %__cheriseed_cap_t* @call_attributes_helper(%__cheriseed_cap_t* returned align 16,
; CHECK-SAME:     %__cheriseed_cap_t*, %__cheriseed_cap_t*)
declare dereferenceable(4) i32 addrspace(200)* @call_attributes_helper(i32 addrspace(200)* dereferenceable(4), i32 addrspace(200)* dereferenceable(4))

; CHECK-LABEL: @dereferenceable_attribute
define void @dereferenceable_attribute() {
; CHECK:       %2 = call %__cheriseed_cap_t* @call_attributes_helper(
; CHECK-SAME:     %__cheriseed_cap_t* returned align 16 %1, %__cheriseed_cap_t* align 4 null,
; CHECK-SAME:     %__cheriseed_cap_t* align 8 null)
  %1 = call dereferenceable(4) i32 addrspace(200)* @call_attributes_helper(i32 addrspace(200)* dereferenceable(4) align 4 null, i32 addrspace(200)* dereferenceable(4) align 8 null)
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; Test calling a function which takes a capability, using a pointer.

; CHECK-LABEL: @call_ptr_to_cap
define void @call_ptr_to_cap(i8* %0) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = call %__cheriseed_cap_t* @__cheriseed_ddc_get(%__cheriseed_cap_t* %2)
; CHECK-NEXT:  %4 = ptrtoint i8* %0 to i64
; CHECK-NEXT:  %5 = call %__cheriseed_cap_t* @__cheriseed_address_set(%__cheriseed_cap_t* %3, %__cheriseed_cap_t* %3, i64 %4)
  %2 = addrspacecast i8* %0 to i8 addrspace(200)*
; CHECK-NEXT:  call void @call_ptr_to_cap_callee(%__cheriseed_cap_t* %5)
  call void @call_ptr_to_cap_callee(i8 addrspace(200)* %2)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK: declare void @call_ptr_to_cap_callee(%__cheriseed_cap_t*)
declare void @call_ptr_to_cap_callee(i8 addrspace(200)*)

; ------------------------------------------------------------------------------
; Test calling a function which takes a pointer, using a capability.

; CHECK-LABEL: @call_cap_to_ptr_call
define i8 addrspace(200)* @call_cap_to_ptr_call(i8 addrspace(200)* %0) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %3 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %4 = call i64 @__cheriseed_to_pointer(%__cheriseed_cap_t* %1,
; CHECK-SAME:     %__cheriseed_cap_t* %1)
  %2 = call i64 @llvm.cheri.cap.to.pointer.i64(i8 addrspace(200)* %0, i8 addrspace(200)* %0)
; CHECK-NEXT:  %5 = inttoptr i64 %4 to i8*
  %3 = inttoptr i64 %2 to i8*
; CHECK-NEXT:  %6 = call i8* @call_cap_to_ptr_callee(i8* %5)
  %4 = call i8* @call_cap_to_ptr_callee(i8* %3)
; CHECK-NEXT:  %7 = call %__cheriseed_cap_t* @__cheriseed_ddc_get(%__cheriseed_cap_t* %3)
; CHECK-NEXT:  %8 = ptrtoint i8* %6 to i64
; CHECK-NEXT:  %9 = call %__cheriseed_cap_t* @__cheriseed_address_set(
; CHECK-SAME:     %__cheriseed_cap_t* %7, %__cheriseed_cap_t* %7, i64 %8)
  %5 = addrspacecast i8* %4 to i8 addrspace(200)*
; CHECK-NEXT:  %10 = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(
; CHECK-SAME:     %__cheriseed_cap_t* %0, %__cheriseed_cap_t* %9, i64 0)
; CHECK-NEXT:  ret %__cheriseed_cap_t* %0
  ret i8 addrspace(200)* %5
}

; CHECK: declare i8* @call_cap_to_ptr_callee(i8*)
declare i8* @call_cap_to_ptr_callee(i8*)
; CHECK-NOT: @llvm.cheri.cap.to.pointer.i64
declare i64 @llvm.cheri.cap.to.pointer.i64(i8 addrspace(200)*, i8 addrspace(200)*)

; ------------------------------------------------------------------------------
; Simple call test with a capability.

; CHECK: declare void @call_with_cap_callee(%__cheriseed_cap_t*)
declare void @call_with_cap_callee(i8 addrspace(200)* addrspace(200)*) addrspace(200)

; CHECK-LABEL: define void @call_with_cap(%__cheriseed_cap_t* %0)
define void @call_with_cap(i8 addrspace(200)* addrspace(200)* %0) addrspace(200) {
; CHECK-NEXT: call void @call_with_cap_callee(%__cheriseed_cap_t* %0)
; CHECK-NEXT: ret void
  call addrspace(200) void @call_with_cap_callee(i8 addrspace(200)* addrspace(200)* %0)
  ret void
}

; ------------------------------------------------------------------------------
; Regression test for return attributes.

; CHECK-LABEL: @return_attributes
define i1 @return_attributes(i8 addrspace(200)* %c, i64 %p) {
; CHECK:       %i = call zeroext i1 @return_attributes(%__cheriseed_cap_t* nonnull %c, i64 signext 1)
  %i = call zeroext i1 @return_attributes(i8 addrspace(200)* nonnull %c, i64 signext 1)
; CHECK-NEXT:  %j = call nonnull %__cheriseed_cap_t* @return_attributes_helper(
; CHECK-SAME:     %__cheriseed_cap_t* returned align 16 %1, %__cheriseed_cap_t* nonnull %c, i64 signext 1)
  %j = call dereferenceable(16) nonnull i8 addrspace(200)* @return_attributes_helper(
      i8 addrspace(200)* returned nonnull %c, i64 signext 1)
; CHECK-NEXT: ret i1 %i
  ret i1 %i
}

declare i8 addrspace(200)* @return_attributes_helper(i8 addrspace(200)* nonnull %c, i64 signext %p);

; ------------------------------------------------------------------------------
; Check that allocsize attribute is ignored.

; CHECK-LABEL: @allocsize
define i8 addrspace(200)* @allocsize(i32 %size) #0 {
  ret i8 addrspace(200)* null
}

; CHECK-NOT: allocsize
attributes #0 = { allocsize(0) }

; ------------------------------------------------------------------------------
