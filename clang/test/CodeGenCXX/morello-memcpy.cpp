// RUN: %clang %s -fno-rtti -std=c++11 -target aarch64-none-elf -march=morello+c64 -mabi=purecap -o - -emit-llvm -S -fPIC | FileCheck %s

union tt {
  void * tt[1];
  struct {
    long xx[2];
  } tq;
};

// CHECK-LABEL: ff
void ff(union tt &x1, union tt &x2) {
// Make sure we preserve the alignment on the copy from the base struct.
// This will maintain the capability tags.
// Note: the complier isn't required to maintain the tags, and might decide to do an element-by-element copy
// which would definetly not copy over any tags.

// CHECK: call void @llvm.memcpy.p200.p200.i64(ptr addrspace(200) align 16 {{.*}}, ptr addrspace(200) align 16 {{.*}}, i64 16, i1 false)
  x2.tq = x1.tq;
}

// CHECK-LABEL: test1
void test1(void *v1, void *v2, void *v3, void *p, unsigned n) {
// CHECK: call void @llvm.memcpy.p200.p200.i64
  __builtin_memcpy(v1, v2, 16);
// CHECK: call void @llvm.memmove.p200.p200.i64
  __builtin_memmove(v2, v3, 16);
// CHECK: call ptr addrspace(200) @__memcpy_chk
  __builtin___memcpy_chk (p, "abcde", n, __builtin_object_size (p, 3));
// CHECK: call ptr addrspace(200) @__memcpy_chk
  __builtin___memcpy_chk (p, v3, n, __builtin_object_size (p, 0));
// CHECK: call ptr addrspace(200) @__memmove_chk
  __builtin___memmove_chk (p, v3, n, __builtin_object_size (p, 0));
}
