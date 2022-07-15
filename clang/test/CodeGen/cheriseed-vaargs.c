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
// CHECK-NEXT:  [[N_ADDR_CAP:%.*]] = call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(%__cheriseed_cap_t* [[N_ADDR_SHADOW_CAP]], i64 [[N_ADDR_ADDR]], i64 4)
// CHECK-NEXT:  [[LST:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[LST_ADDR:%.*]] = ptrtoint %__cheriseed_cap_t* [[LST]] to i64
// CHECK-NEXT:  [[LST_SHADOW_CAP:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[LST_CAP:%.*]] = call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(%__cheriseed_cap_t* [[LST_SHADOW_CAP]], i64 [[LST_ADDR]], i64 16)
// CHECK-NEXT:  [[CAP:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[CAP_ADDR:%.*]] = ptrtoint %__cheriseed_cap_t* [[CAP]] to i64
// CHECK-NEXT:  [[CAP_SHADOW_CAP:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
// CHECK-NEXT:  [[V1:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[V2:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[V3:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[CAP_CAP:%.*]] = call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(%__cheriseed_cap_t* [[CAP_SHADOW_CAP]], i64 [[CAP_ADDR]], i64 16)
// CHECK-NEXT:  [[V4:%.*]] = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* [[N_ADDR_CAP]], i64 4, i32 2)
// CHECK-NEXT:  [[V5:%.*]] = inttoptr i64 [[V4]] to i32*
// CHECK-NEXT:  store i32 %n, i32* [[V5]], align 4
// CHECK-NEXT:  call void @__cheriseed_store_cap(%__cheriseed_cap_t* [[LST_CAP]], %__cheriseed_cap_t* %0)
// CHECK-NEXT:  %stack = call %__cheriseed_cap_t* @__cheriseed_load_cap(%__cheriseed_cap_t* [[LST_CAP]], %__cheriseed_cap_t* [[V1]])
// CHECK-NEXT:  %new_stack = call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* [[V2]], %__cheriseed_cap_t* %stack, i64 16)
// CHECK-NEXT:  call void @__cheriseed_store_cap(%__cheriseed_cap_t* [[LST_CAP]], %__cheriseed_cap_t* %new_stack)
// CHECK-NEXT:  [[V6:%.*]] = call %__cheriseed_cap_t* @__cheriseed_load_cap(%__cheriseed_cap_t* %stack, %__cheriseed_cap_t* [[V3]])
// CHECK-NEXT:  call void @__cheriseed_store_cap(%__cheriseed_cap_t* [[CAP_CAP]], %__cheriseed_cap_t* [[V6]])
// CHECK-NEXT:  [[V7:%.*]] = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* [[LST_CAP]], i64 16, i32 0)
// CHECK-NEXT:  [[V8:%.*]] = inttoptr i64 [[V7]] to %__cheriseed_cap_t*
// CHECK-NEXT:  [[V9:%.*]] = call %__cheriseed_cap_t* @__cheriseed_perms_and(%__cheriseed_cap_t* [[V8]], %__cheriseed_cap_t* [[V8]], i64 0)
// CHECK-NEXT:  ret void
  va_list lst;
  va_start(lst, n);
  int *__capability cap = va_arg(lst, int *__capability);
  va_end(lst);
}

// CHECK-LABEL: @callee2
void callee2(int n, ...) {
// CHECK-LABEL: entry:
// CHECK-NEXT:  [[N_ADDR:%.*]] = alloca i32, align 4
// CHECK-NEXT:  [[N_ADDR_ADDR:%.*]] = ptrtoint i32* [[N_ADDR]] to i64
// CHECK-NEXT:  [[N_ADDR_SHADOW_CAP:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[N_ADDR_CAP:%.*]] = call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(%__cheriseed_cap_t* [[N_ADDR_SHADOW_CAP]], i64 [[N_ADDR_ADDR]], i64 4)
// CHECK-NEXT:  [[LST1:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[LST1_ADDR:%.*]] = ptrtoint %__cheriseed_cap_t* [[LST1]] to i64
// CHECK-NEXT:  [[LST1_SHADOW_CAP:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[LST1_CAP:%.*]] = call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(%__cheriseed_cap_t* [[LST1_SHADOW_CAP]], i64 [[LST1_ADDR]], i64 16)
// CHECK-NEXT:  [[LST2:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[LST2_ADDR:%.*]] = ptrtoint %__cheriseed_cap_t* [[LST2]] to i64
// CHECK-NEXT:  [[LST2_SHADOW_CAP:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
// CHECK-NEXT:  [[V1:%.*]] = alloca %__cheriseed_cap_t, align 16
// CHECK-NEXT:  [[LST2_CAP:%.*]] = call %__cheriseed_cap_t* @__cheriseed_stack_cap_init(%__cheriseed_cap_t* [[LST2_SHADOW_CAP]], i64 [[LST2_ADDR]], i64 16)
// CHECK-NEXT:  [[V2:%.*]] = call i64 @__cheriseed_check_access(%__cheriseed_cap_t* [[N_ADDR_CAP]], i64 4, i32 2)
// CHECK-NEXT:  [[V3:%.*]] = inttoptr i64 [[V2]] to i32*
// CHECK-NEXT:  store i32 %n, i32* [[V3]], align 4
// CHECK-NEXT:  call void @__cheriseed_store_cap(%__cheriseed_cap_t* [[LST1_CAP]], %__cheriseed_cap_t* %0)
// CHECK-NEXT:  [[V4:%.*]] = call %__cheriseed_cap_t* @__cheriseed_load_cap(%__cheriseed_cap_t* [[LST1_CAP]], %__cheriseed_cap_t* [[V1]])
// CHECK-NEXT:  call void @__cheriseed_store_cap(%__cheriseed_cap_t* [[LST2_CAP]], %__cheriseed_cap_t* [[V4]])
// CHECK-NEXT:  ret void
  va_list lst1;
  va_list lst2;
  va_start(lst1, n);
  va_copy(lst2, lst1);
}
