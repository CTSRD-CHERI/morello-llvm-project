// RUN: %clang_cc1 -triple  x86_64-unknown-linux -fsanitize=cheriseed -target-abi purecap -o - -emit-llvm %s | FileCheck %s -enable-var-scope
// RUN: %clang_cc1 -triple  x86_64-unknown-linux -fsanitize=cheriseed -target-abi purecap -flegacy-pass-manager -o - -emit-llvm %s | FileCheck %s -enable-var-scope
// RUN: %clang_cc1 -triple aarch64-unknown-linux -fsanitize=cheriseed -target-abi purecap -o - -emit-llvm %s | FileCheck %s -enable-var-scope
// RUN: %clang_cc1 -triple aarch64-unknown-linux -fsanitize=cheriseed -target-abi purecap -flegacy-pass-manager -o - -emit-llvm %s | FileCheck %s -enable-var-scope

#include <stdarg.h>

// CHECK-LABEL: @callee1
void callee1(int n, ...) {
// CHECK-LABEL: entry:
// CHECK-NEXT:  [[N_ADDR:%.*]] = alloca i32, align 4
// CHECK-NEXT:  [[N_ADDR_ADDR:%.*]] = ptrtoint i32* [[N_ADDR]] to i64
// CHECK-NEXT:  [[N_ADDR_SHADOW_CAP:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[N_ADDR_CAP:%.*]] = tail call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(%__cheriseed_cap_t* [[N_ADDR_SHADOW_CAP]], i64 [[N_ADDR_ADDR]], i64 4)
// CHECK-NEXT:  [[LST:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[LST_ADDR:%.*]] = ptrtoint %__cheriseed_cap_t* [[LST]] to i64
// CHECK-NEXT:  [[LST_SHADOW_CAP:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[LST_CAP:%.*]] = tail call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(%__cheriseed_cap_t* [[LST_SHADOW_CAP]], i64 [[LST_ADDR]], i64 16)
// CHECK-NEXT:  [[CAP:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[CAP_ADDR:%.*]] = ptrtoint %__cheriseed_cap_t* [[CAP]] to i64
// CHECK-NEXT:  [[CAP_SHADOW_CAP:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  %"CHERIseed Alloca Insertion Point" = bitcast i8 0 to i8
// CHECK-NEXT:  [[V1:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[V2:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[V3:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[V4:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[V5:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[V6:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[CAP_CAP:%.*]] = tail call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(%__cheriseed_cap_t* [[CAP_SHADOW_CAP]], i64 [[CAP_ADDR]], i64 16)
// CHECK-NEXT:  [[V7:%.*]] = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* [[N_ADDR_CAP]], i64 4, i32 2)
// CHECK-NEXT:  [[V8:%.*]] = inttoptr i64 [[V7]] to i32*
// CHECK-NEXT:  store i32 %n, i32* [[V8]], align 4
// CHECK-NEXT:  [[LST1:%.*]] = tail call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* [[V1]], %__cheriseed_cap_t* [[LST_CAP]], i64 0)
// CHECK-NEXT:  tail call void @__cheriseed_store_cap(%__cheriseed_cap_t* [[LST1]], %__cheriseed_cap_t* %0)
// CHECK-NEXT:  %stack = tail call %__cheriseed_cap_t* @__cheriseed_load_cap(%__cheriseed_cap_t* [[LST_CAP]], %__cheriseed_cap_t* [[V2]])
// CHECK-NEXT:  [[V9:%.*]] = tail call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* [[V3]], %__cheriseed_cap_t* %stack, i64 0)
// CHECK-NEXT:  %new_stack = tail call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* [[V4]], %__cheriseed_cap_t* %stack, i64 16)
// CHECK-NEXT:  tail call void @__cheriseed_store_cap(%__cheriseed_cap_t* [[LST_CAP]], %__cheriseed_cap_t* %new_stack)
// CHECK-NEXT:  [[V10:%.*]] = tail call %__cheriseed_cap_t* @__cheriseed_load_cap(%__cheriseed_cap_t* [[V9]], %__cheriseed_cap_t* [[V5]])
// CHECK-NEXT:  tail call void @__cheriseed_store_cap(%__cheriseed_cap_t* [[CAP_CAP]], %__cheriseed_cap_t* [[V10]])
// CHECK-NEXT:  [[LST2:%.*]] = tail call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* [[V6]], %__cheriseed_cap_t* [[LST_CAP]], i64 0)
// CHECK-NEXT:  ret void
  va_list lst;
  va_start(lst, n);
  int *__capability cap = va_arg(lst, int *__capability);
// va_end does nothing and is currently simply discarded.
  va_end(lst);
}

// CHECK-LABEL: @callee2
void callee2(int n, ...) {
// CHECK-LABEL: entry:
// CHECK-NEXT:  [[N_ADDR:%.*]] = alloca i32, align 4
// CHECK-NEXT:  [[N_ADDR_ADDR:%.*]] = ptrtoint i32* [[N_ADDR]] to i64
// CHECK-NEXT:  [[N_ADDR_SHADOW_CAP:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[N_ADDR_CAP:%.*]] = tail call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(%__cheriseed_cap_t* [[N_ADDR_SHADOW_CAP]], i64 [[N_ADDR_ADDR]], i64 4)
// CHECK-NEXT:  [[LST1:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[LST1_ADDR:%.*]] = ptrtoint %__cheriseed_cap_t* [[LST1]] to i64
// CHECK-NEXT:  [[LST1_SHADOW_CAP:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[LST1_CAP:%.*]] = tail call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(%__cheriseed_cap_t* [[LST1_SHADOW_CAP]], i64 [[LST1_ADDR]], i64 16)
// CHECK-NEXT:  [[LST2:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[LST2_ADDR:%.*]] = ptrtoint %__cheriseed_cap_t* [[LST2]] to i64
// CHECK-NEXT:  [[LST2_SHADOW_CAP:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  %"CHERIseed Alloca Insertion Point" = bitcast i8 0 to i8
// CHECK-NEXT:  [[V1:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[V2:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[V3:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[V4:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[LST2_CAP:%.*]] = tail call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(%__cheriseed_cap_t* [[LST2_SHADOW_CAP]], i64 [[LST2_ADDR]], i64 16)
// CHECK-NEXT:  [[V5:%.*]] = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* [[N_ADDR_CAP]], i64 4, i32 2)
// CHECK-NEXT:  [[V6:%.*]] = inttoptr i64 [[V5]] to i32*
// CHECK-NEXT:  store i32 %n, i32* [[V6]], align 4
// CHECK-NEXT:  [[LST11:%.*]] = tail call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* [[V1]], %__cheriseed_cap_t* [[LST1_CAP]], i64 0)
// CHECK-NEXT:  tail call void @__cheriseed_store_cap(%__cheriseed_cap_t* [[LST11]], %__cheriseed_cap_t* %0)
// CHECK-NEXT:  [[V7:%.*]] = tail call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* [[V2]], %__cheriseed_cap_t* [[LST2_CAP]], i64 0)
// CHECK-NEXT:  [[V8:%.*]] = tail call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* [[V3]], %__cheriseed_cap_t* [[LST1_CAP]], i64 0)
// CHECK-NEXT:  [[V9:%.*]] = tail call %__cheriseed_cap_t* @__cheriseed_load_cap(%__cheriseed_cap_t* [[V8]], %__cheriseed_cap_t* [[V4]])
// CHECK-NEXT:  tail call void @__cheriseed_store_cap(%__cheriseed_cap_t* [[V7]], %__cheriseed_cap_t* [[V9]])
// CHECK-NEXT:  ret void
  va_list lst1;
  va_list lst2;
  va_start(lst1, n);
  va_copy(lst2, lst1);
}
