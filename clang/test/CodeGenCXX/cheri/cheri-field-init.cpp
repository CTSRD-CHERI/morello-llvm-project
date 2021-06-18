// RUN: %cheri_purecap_cc1 -emit-llvm -o - %s | %cheri_FileCheck %s

struct foo {
  struct bar {
    bar(const bar&);
    float b1;
    float b2;
  } a1;
  foo(const foo&);
  float a2;
  float a3;
  float a4;
  float a5;
  void *a6;
};

foo::foo(const foo&) = default;

// CHECK-LABEL: @_ZN3fooC2ERKS_(
// CHECK:  call void @llvm.memcpy.p200i8.p200i8.i64(i8 addrspace(200)* align 8 [[DEST:%.*]], i8 addrspace(200)* align 8 [[SRC:%.*]], i64 8, i1 false)
// CHECK-NEXT:  [[DESTINC:%.*]] = getelementptr inbounds i8, i8 addrspace(200)* [[DEST]], i64 8
// CHECK-NEXT:  [[SRCINC:%.*]] = getelementptr inbounds i8, i8 addrspace(200)* [[SRC]], i64 8
// CHECK-NEXT:  call void @llvm.memcpy.p200i8.p200i8.i64(i8 addrspace(200)* align 16 [[DESTINC]], i8 addrspace(200)* align 16 [[SRCINC]], i64 32, i1 false)
// CHECK-NEXT:  ret void
