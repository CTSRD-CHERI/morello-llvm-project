// RUN: %clang %s -target aarch64-none-elf -march=morello+c64 -mabi=purecap -o - -S -emit-llvm | FileCheck %s

// CHECK-LABEL: @add0
int add0(__intcap_t a, __intcap_t b, __intcap_t *c) {
// CHECK: call i64 @llvm.cheri.cap.address.get.i64
// CHECK: call i64 @llvm.cheri.cap.address.get.i64
// CHECK: @llvm.sadd.with.overflow.i64
// CHECK: extractvalue { i64, i1 } {{.*}}, 1
// CHECK: extractvalue { i64, i1 } {{.*}}, 0
// CHECK: call ptr addrspace(200) @llvm.cheri.cap.address.set.i64(ptr addrspace(200) {{.*}}, i64 {{.*}})
  return __builtin_add_overflow(a,b, c);
}

// CHECK-LABEL: @add1
int add1(int a, __intcap_t b, __intcap_t *c) {
// CHECK: call i64 @llvm.cheri.cap.address.get.i64
// CHECK-NOT: call i64 @llvm.cheri.cap.address.get.i64
// CHECK: @llvm.sadd.with.overflow.i64
// CHECK: extractvalue { i64, i1 } {{.*}}, 1
// CHECK: extractvalue { i64, i1 } {{.*}}, 0
// CHECK: call ptr addrspace(200) @llvm.cheri.cap.address.set.i64(ptr addrspace(200) {{.*}}, i64 {{.*}})
  return __builtin_add_overflow(a,b, c);
}

// CHECK-LABEL: @add2
int add2(__intcap_t a, int b, __intcap_t *c) {
// CHECK: call i64 @llvm.cheri.cap.address.get.i64
// CHECK-NOT: call i64 @llvm.cheri.cap.address.get.i64
// CHECK: @llvm.sadd.with.overflow.i64
// CHECK: extractvalue { i64, i1 } {{.*}}, 1
// CHECK: extractvalue { i64, i1 } {{.*}}, 0
// CHECK: call ptr addrspace(200) @llvm.cheri.cap.address.set.i64(ptr addrspace(200) {{.*}}, i64 {{.*}})
  return __builtin_add_overflow(a,b, c);
}

// CHECK-LABEL: @add3
int add3(int a, int b, __intcap_t *c) {
// CHECK-NOT: call i64 @llvm.cheri.cap.address.get.i64
// CHECK: @llvm.sadd.with.overflow.i64
// CHECK: extractvalue { i64, i1 } {{.*}}, 1
// CHECK: extractvalue { i64, i1 } {{.*}}, 0
// CHECK: getelementptr i8, ptr addrspace(200) null, i64 {{.*}}
  return __builtin_add_overflow(a,b, c);
}

// CHECK-LABEL: @sub0
int sub0(__intcap_t a, __intcap_t b, __intcap_t *c) {
// CHECK: call i64 @llvm.cheri.cap.address.get.i64
// CHECK: call i64 @llvm.cheri.cap.address.get.i64
// CHECK: @llvm.ssub.with.overflow.i64
// CHECK: extractvalue { i64, i1 } {{.*}}, 1
// CHECK: extractvalue { i64, i1 } {{.*}}, 0
// CHECK: call ptr addrspace(200) @llvm.cheri.cap.address.set.i64(ptr addrspace(200) {{.*}}, i64 {{.*}})
  return __builtin_sub_overflow(a,b, c);
}

// CHECK-LABEL: @sub1
int sub1(int a, __intcap_t b, __intcap_t *c) {
// CHECK: call i64 @llvm.cheri.cap.address.get.i64
// CHECK-NOT: call i64 @llvm.cheri.cap.address.get.i64
// CHECK: @llvm.ssub.with.overflow.i64
// CHECK: extractvalue { i64, i1 } {{.*}}, 1
// CHECK: extractvalue { i64, i1 } {{.*}}, 0
// CHECK: call ptr addrspace(200) @llvm.cheri.cap.address.set.i64(ptr addrspace(200) {{.*}}, i64 {{.*}})
  return __builtin_sub_overflow(a,b, c);
}

// CHECK-LABEL: @sub2
int sub2(__intcap_t a, int b, __intcap_t *c) {
// CHECK: call i64 @llvm.cheri.cap.address.get.i64
// CHECK-NOT: call i64 @llvm.cheri.cap.address.get.i64
// CHECK: @llvm.ssub.with.overflow.i64
// CHECK: extractvalue { i64, i1 } {{.*}}, 1
// CHECK: extractvalue { i64, i1 } {{.*}}, 0
// CHECK: call ptr addrspace(200) @llvm.cheri.cap.address.set.i64(ptr addrspace(200) {{.*}}, i64 {{.*}})
  return __builtin_sub_overflow(a,b, c);
}

// CHECK-LABEL: @sub3
int sub3(int a, int b, __intcap_t *c) {
// CHECK-NOT: call i64 @llvm.cheri.cap.address.get.i64
// CHECK: @llvm.ssub.with.overflow.i64
// CHECK: extractvalue { i64, i1 } {{.*}}, 1
// CHECK: extractvalue { i64, i1 } {{.*}}, 0
// CHECK: getelementptr i8, ptr addrspace(200) null, i64 {{.*}}
  return __builtin_sub_overflow(a,b, c);
}

// CHECK-LABEL: @mul0
int mul0(__intcap_t a, __intcap_t b, __intcap_t *c) {
// CHECK: call i64 @llvm.cheri.cap.address.get.i64
// CHECK: call i64 @llvm.cheri.cap.address.get.i64
// CHECK: @llvm.smul.with.overflow.i64
// CHECK: extractvalue { i64, i1 } {{.*}}, 1
// CHECK: extractvalue { i64, i1 } {{.*}}, 0
// CHECK: call ptr addrspace(200) @llvm.cheri.cap.address.set.i64(ptr addrspace(200) {{.*}}, i64 {{.*}})
  return __builtin_mul_overflow(a,b, c);
}

// CHECK-LABEL: @mul1
int mul1(int a, __intcap_t b, __intcap_t *c) {
// CHECK: call i64 @llvm.cheri.cap.address.get.i64
// CHECK-NOT: call i64 @llvm.cheri.cap.address.get.i64
// CHECK: @llvm.smul.with.overflow.i64
// CHECK: extractvalue { i64, i1 } {{.*}}, 1
// CHECK: extractvalue { i64, i1 } {{.*}}, 0
// CHECK: call ptr addrspace(200) @llvm.cheri.cap.address.set.i64(ptr addrspace(200) {{.*}}, i64 {{.*}})
  return __builtin_mul_overflow(a,b, c);
}

// CHECK-LABEL: @mul2
int mul2(__intcap_t a, int b, __intcap_t *c) {
// CHECK: call i64 @llvm.cheri.cap.address.get.i64
// CHECK-NOT: call i64 @llvm.cheri.cap.address.get.i64
// CHECK: @llvm.smul.with.overflow.i64
// CHECK: extractvalue { i64, i1 } {{.*}}, 1
// CHECK: extractvalue { i64, i1 } {{.*}}, 0
// CHECK: call ptr addrspace(200) @llvm.cheri.cap.address.set.i64(ptr addrspace(200) {{.*}}, i64 {{.*}})
  return __builtin_mul_overflow(a,b, c);
}

// CHECK-LABEL: @mul3
int mul3(int a, int b, __intcap_t *c) {
// CHECK-NOT: call i64 @llvm.cheri.cap.address.get.i64
// CHECK: @llvm.smul.with.overflow.i64
// CHECK: extractvalue { i64, i1 } {{.*}}, 1
// CHECK: extractvalue { i64, i1 } {{.*}}, 0
// CHECK: getelementptr i8, ptr addrspace(200) null, i64 {{.*}}
  return __builtin_mul_overflow(a,b, c);
}

int mixed(__intcap_t a, __uintcap_t b, __intcap_t *c) {
// CHECK: call i64 @llvm.cheri.cap.address.get.i64
// CHECK: call i64 @llvm.cheri.cap.address.get.i64
// CHECK: @llvm.sadd.with.overflow.i65
// CHECK: extractvalue { i65, i1 } {{.*}}, 1
// CHECK: extractvalue { i65, i1 } {{.*}}, 0
// CHECK: trunc i65 {{.*}} to i64
// CHECK: call ptr addrspace(200) @llvm.cheri.cap.address.set.i64(ptr addrspace(200) {{.*}}, i64 {{.*}})
  return __builtin_add_overflow(a,b, c);
}
