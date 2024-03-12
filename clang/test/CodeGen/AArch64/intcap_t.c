// REQUIRES: aarch64-registered-target
// RUN: %clang %s -O0 -target aarch64-none-linux-gnu -march=morello -o - -emit-llvm -S -cheri-uintcap=offset | FileCheck %s --check-prefix=offset --check-prefix=CHECK
// RUN: %clang %s -O0 -target aarch64-none-linux-gnu -march=morello -o - -emit-llvm -S -cheri-uintcap=addr | FileCheck %s --check-prefix=addr --check-prefix=CHECK
// Check that we can actually compile this file...
// RUN: %clang %s -O1 -target aarch64-none-linux-gnu -march=morello -o /dev/null -c -cheri-uintcap=offset
// RUN: %clang %s -O1 -target aarch64-none-linux-gnu -march=morello -o /dev/null -c -cheri-uintcap=addr

// CHECK: c1
int c1(__capability void* x, __capability void* y)
{
  __intcap_t a = (__intcap_t)x;
  __intcap_t b = (__intcap_t)y;
  // CHECK: icmp slt ptr addrspace(200)
  return a < b;
}
// CHECK c2
int c2(__capability void* x, __capability void* y)
{
  __intcap_t a = (__intcap_t)x;
  __intcap_t b = (__intcap_t)y;
  // CHECK: icmp eq ptr addrspace(200)
  return a == b;
}
// CHECK: c3
int c3(__capability void* x, __capability void* y)
{
  __intcap_t a = (__intcap_t)x;
  __intcap_t b = (__intcap_t)y;
  // CHECK: icmp sgt ptr addrspace(200)
  return a > b;
}
// CHECK: c4
int c4(__capability void* x, __capability void* y)
{
  __intcap_t a = (__intcap_t)x;
  __intcap_t b = (__intcap_t)y;
  // CHECK: icmp sge ptr addrspace(200)
  return a >= b;
}
// CHECK: c5
int c5(__capability void* x, __capability void* y)
{
  __intcap_t a = (__intcap_t)x;
  __intcap_t b = (__intcap_t)y;
  // CHECK: icmp sle ptr addrspace(200)
  return a <= b;
}

// CHECK: ca1
int ca1(__capability void* x, __capability void* y)
{
  // offset: @llvm.cheri.cap.offset.get.i64(ptr addrspace(200)
  // addr: @llvm.cheri.cap.address.get.i64(ptr addrspace(200)
  __intcap_t a = (__intcap_t)x;
  // offset: @llvm.cheri.cap.offset.get.i64(ptr addrspace(200)
  // addr: @llvm.cheri.cap.address.get.i64(ptr addrspace(200)
  __intcap_t b = (__intcap_t)y;
  // CHECK: sub
  return a - b;
}

// CHECK: ca2
int ca2(__capability void* x, __capability void* y)
{
  // offset: @llvm.cheri.cap.offset.get.i64(ptr addrspace(200)
  // addr: @llvm.cheri.cap.address.get.i64(ptr addrspace(200)
  __intcap_t a = (__intcap_t)x;
  // offset: @llvm.cheri.cap.offset.get.i64(ptr addrspace(200)
  // addr: @llvm.cheri.cap.address.get.i64(ptr addrspace(200)
  __intcap_t b = (__intcap_t)y;
  // CHECK: add
  return a + b;
}

// CHECK: ca3
int ca3(__capability void* x, __capability void* y)
{
  // offset: @llvm.cheri.cap.offset.get.i64(ptr addrspace(200)
  // addr: @llvm.cheri.cap.address.get.i64(ptr addrspace(200)
  __intcap_t a = (__intcap_t)x;
  // offset: @llvm.cheri.cap.offset.get.i64(ptr addrspace(200)
  // addr: @llvm.cheri.cap.address.get.i64(ptr addrspace(200)
  __intcap_t b = (__intcap_t)y;
  // CHECK: mul
  return a * b;
}

// CHECK: ca4
int ca4(__capability void* x, __capability void* y)
{
  // offset: @llvm.cheri.cap.offset.get.i64(ptr addrspace(200)
  // addr: @llvm.cheri.cap.address.get.i64(ptr addrspace(200)
  __intcap_t a = (__intcap_t)x;
  // offset: @llvm.cheri.cap.offset.get.i64(ptr addrspace(200)
  // addr: @llvm.cheri.cap.address.get.i64(ptr addrspace(200)
  __intcap_t b = (__intcap_t)y;
  // CHECK: sdiv
  return a / b;
}

// CHECK: p1
int p1(void* x, void* y)
{
  __intcap_t a = (__intcap_t)x;
  __intcap_t b = (__intcap_t)y;
  // CHECK: icmp slt ptr addrspace(200)
  return a < b;
}

// CHECK: castc
__capability void *castc(__intcap_t a)
{
  // CHECK-NOT: ptrtoint
  return (__capability void*)a;
}

void *castp(__intcap_t a)
{
  // CHECK: llvm.cheri.cap.to.pointer.i64
  // CHECK: inttoptr
  return (void*)a;
}

// increment and decrement should work
__intcap_t x;
__uintcap_t y;

void incdec(void)
{
  x++;
  y++;
  x--;
  y--;
}

__uintcap_t xor(__uintcap_t f)
{
  f ^= 2;
  return f;
}

int capdiff(__capability int *a, __capability int *b)
{
  // CHECK-LABEL: @capdiff(ptr addrspace(200) noundef %{{.*}}, ptr addrspace(200) noundef %{{.*}}) #0 {
  // addr: [[ADDR1:%[a-z_0-9]+]] = call i64 @llvm.cheri.cap.address.get.i64(ptr addrspace(200) {{.*}})
  // addr: [[ADDR2:%[a-z_0-9]+]] = call i64 @llvm.cheri.cap.address.get.i64(ptr addrspace(200) {{.*}})
  // addr: sub i64 [[ADDR1]], [[ADDR2]]
  // offset: call i64 @llvm.cheri.cap.diff
  return a-b;
}

// CHECK: negativeint
void negativeint()
{
  // CHECK: getelementptr (i8, ptr addrspace(200) null, i64 -5)
  __intcap_t minus = -5;
}

// CHECK: largeint
void largeint()
{
  // CHECK: getelementptr (i8, ptr addrspace(200) null, i64 4294967295)
  __uintcap_t large = 4294967295; // 2^32 - 1
}
