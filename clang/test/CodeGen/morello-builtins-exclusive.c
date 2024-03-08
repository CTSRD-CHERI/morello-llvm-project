// RUN: %clang_cc1 -Wall -Werror -triple aarch64-none-elf -target-feature +c64 -target-abi purecap -disable-O0-optnone -emit-llvm -o - %s | opt -S -mem2reg | FileCheck %s

struct Simple {
  char a, b;
};

int test_ldrex(char *addr, long long *addr64, float *addrfloat) {
// CHECK-LABEL: @test_ldrex
  int sum = 0;
  sum += __builtin_arm_ldrex(addr);
// CHECK: [[INTRES:%.*]] = call i64 @llvm.aarch64.ldxr.p200i8(i8 addrspace(200)* elementtype(i8) %addr)
// CHECK: trunc i64 [[INTRES]] to i8

  sum += __builtin_arm_ldrex((short *)addr);
// CHECK: [[ADDR16:%.*]] = bitcast i8 addrspace(200)* %addr to i16 addrspace(200)*
// CHECK: [[INTRES:%.*]] = call i64 @llvm.aarch64.ldxr.p200i16(i16 addrspace(200)* elementtype(i16) [[ADDR16]])
// CHECK: trunc i64 [[INTRES]] to i16

  sum += __builtin_arm_ldrex((int *)addr);
// CHECK: [[ADDR32:%.*]] = bitcast i8 addrspace(200)* %addr to i32 addrspace(200)*
// CHECK: [[INTRES:%.*]] = call i64 @llvm.aarch64.ldxr.p200i32(i32 addrspace(200)* elementtype(i32) [[ADDR32]])
// CHECK: trunc i64 [[INTRES]] to i32

  sum += __builtin_arm_ldrex((long long *)addr);
// CHECK: [[ADDR64:%.*]] = bitcast i8 addrspace(200)* %addr to i64 addrspace(200)*
// CHECK: call i64 @llvm.aarch64.ldxr.p200i64(i64 addrspace(200)* elementtype(i64) [[ADDR64]])

  sum += __builtin_arm_ldrex(addr64);
// CHECK: call i64 @llvm.aarch64.ldxr.p200i64(i64 addrspace(200)* elementtype(i64) %addr64)

  sum += __builtin_arm_ldrex(addrfloat);
// CHECK: [[INTADDR:%.*]] = bitcast float addrspace(200)* %addrfloat to i32 addrspace(200)*
// CHECK: [[INTRES:%.*]] = call i64 @llvm.aarch64.ldxr.p200i32(i32 addrspace(200)* elementtype(i32) [[INTADDR]])
// CHECK: [[TRUNCRES:%.*]] = trunc i64 [[INTRES]] to i32
// CHECK: bitcast i32 [[TRUNCRES]] to float

  sum += __builtin_arm_ldrex((double *)addr);
// CHECK: [[TMP4:%.*]] = bitcast i8 addrspace(200)* %addr to double addrspace(200)*
// CHECK: [[TMP5:%.*]] = bitcast double addrspace(200)* [[TMP4]] to i64 addrspace(200)*
// CHECK: [[INTRES:%.*]] = call i64 @llvm.aarch64.ldxr.p200i64(i64 addrspace(200)* elementtype(i64) [[TMP5]])
// CHECK: bitcast i64 [[INTRES]] to double

  sum += *__builtin_arm_ldrex((int **)addr);
// CHECK: [[TMP4:%.*]] = bitcast i8 addrspace(200)* %addr to i32 addrspace(200)* addrspace(200)*
// CHECK: [[TMP5:%.*]] = bitcast i32 addrspace(200)* addrspace(200)* [[TMP4]] to i8 addrspace(200)* addrspace(200)*
// CHECK: [[INTRES:%.*]] = call i8 addrspace(200)* @llvm.aarch64.cldxr.p200p200i8(i8 addrspace(200)* addrspace(200)* elementtype(i8 addrspace(200)*) [[TMP5]])
// CHECK: bitcast i8 addrspace(200)* [[INTRES]] to i32 addrspace(200)*

  sum += __builtin_arm_ldrex((struct Simple **)addr)->a;
// CHECK: [[TMP4:%.*]] = bitcast i8 addrspace(200)* %addr to %struct.Simple addrspace(200)* addrspace(200)*
// CHECK: [[TMP5:%.*]] = bitcast %struct.Simple addrspace(200)* addrspace(200)* [[TMP4]] to i8 addrspace(200)*
// CHECK: [[INTRES:%.*]] = call i8 addrspace(200)* @llvm.aarch64.cldxr.p200p200i8(i8 addrspace(200)* addrspace(200)* elementtype(i8 addrspace(200)*) [[TMP5]])
// CHECK: bitcast i8 addrspace(200)* [[INTRES]] to %struct.Simple addrspace(200)*
  return sum;
}

int test_ldaex(char *addr, long long *addr64, float *addrfloat) {
// CHECK-LABEL: @test_ldaex
  int sum = 0;
  sum += __builtin_arm_ldaex(addr);
// CHECK: [[INTRES:%.*]] = call i64 @llvm.aarch64.ldaxr.p200i8(i8 addrspace(200)* elementtype(i8) %addr)
// CHECK: trunc i64 [[INTRES]] to i8

  sum += __builtin_arm_ldaex((short *)addr);
// CHECK: [[ADDR16:%.*]] = bitcast i8 addrspace(200)* %addr to i16 addrspace(200)*
// CHECK: [[INTRES:%.*]] = call i64 @llvm.aarch64.ldaxr.p200i16(i16 addrspace(200)* elementtype(i16) [[ADDR16]])
// CHECK: [[TRUNCRES:%.*]] = trunc i64 [[INTRES]] to i16

  sum += __builtin_arm_ldaex((int *)addr);
// CHECK: [[ADDR32:%.*]] = bitcast i8 addrspace(200)* %addr to i32 addrspace(200)*
// CHECK: [[INTRES:%.*]] = call i64 @llvm.aarch64.ldaxr.p200i32(i32 addrspace(200)* elementtype(i32) [[ADDR32]])
// CHECK: trunc i64 [[INTRES]] to i32

  sum += __builtin_arm_ldaex((long long *)addr);
// CHECK: [[ADDR64:%.*]] = bitcast i8 addrspace(200)* %addr to i64 addrspace(200)*
// CHECK: call i64 @llvm.aarch64.ldaxr.p200i64(i64 addrspace(200)* elementtype(i64) [[ADDR64]])

  sum += __builtin_arm_ldaex(addr64);
// CHECK: call i64 @llvm.aarch64.ldaxr.p200i64(i64 addrspace(200)* elementtype(i64) %addr64)

  sum += __builtin_arm_ldaex(addrfloat);
// CHECK: [[INTADDR:%.*]] = bitcast float addrspace(200)* %addrfloat to i32 addrspace(200)*
// CHECK: [[INTRES:%.*]] = call i64 @llvm.aarch64.ldaxr.p200i32(i32 addrspace(200)* elementtype(i32) [[INTADDR]])
// CHECK: [[TRUNCRES:%.*]] = trunc i64 [[INTRES]] to i32
// CHECK: bitcast i32 [[TRUNCRES]] to float

  sum += __builtin_arm_ldaex((double *)addr);
// CHECK: [[TMP4:%.*]] = bitcast i8 addrspace(200)* %addr to double addrspace(200)*
// CHECK: [[TMP5:%.*]] = bitcast double addrspace(200)* [[TMP4]] to i64 addrspace(200)*
// CHECK: [[INTRES:%.*]] = call i64 @llvm.aarch64.ldaxr.p200i64(i64 addrspace(200)* elementtype(i64) [[TMP5]])
// CHECK: bitcast i64 [[INTRES]] to double

  sum += *__builtin_arm_ldaex((int **)addr);
// CHECK: [[TMP4:%.*]] = bitcast i8 addrspace(200)* %addr to i32 addrspace(200)* addrspace(200)*
// CHECK: [[TMP5:%.*]] = bitcast i32 addrspace(200)* addrspace(200)* [[TMP4]] to i8 addrspace(200)* addrspace(200)*
// CHECK: [[INTRES:%.*]] = call i8 addrspace(200)* @llvm.aarch64.cldaxr.p200p200i8(i8 addrspace(200)* addrspace(200)* elementtype(i8 addrspace(200)*) [[TMP5]])
// CHECK: bitcast i8 addrspace(200)* [[INTRES]] to i32 addrspace(200)*

  sum += __builtin_arm_ldaex((struct Simple **)addr)->a;
// CHECK: [[TMP4:%.*]] = bitcast i8 addrspace(200)* %addr to %struct.Simple addrspace(200)* addrspace(200)*
// CHECK: [[TMP5:%.*]] = bitcast %struct.Simple addrspace(200)* addrspace(200)* [[TMP4]] to i8 addrspace(200)* addrspace(200)*
// CHECK: [[INTRES:%.*]] = call i8 addrspace(200)* @llvm.aarch64.cldaxr.p200p200i8(i8 addrspace(200)* addrspace(200)* elementtype(i8 addrspace(200)*) [[TMP5]])
// CHECK: bitcast i8 addrspace(200)* [[INTRES]] to %struct.Simple addrspace(200)*
  return sum;
}

int test_strex(char *addr) {
// CHECK-LABEL: @test_strex
  int res = 0;
  struct Simple var = {0};
  res |= __builtin_arm_strex(4, addr);
// CHECK: call i32 @llvm.aarch64.stxr.p200i8(i64 4, i8 addrspace(200)* elementtype(i8) %addr)

  res |= __builtin_arm_strex(42, (short *)addr);
// CHECK: [[ADDR16:%.*]] = bitcast i8 addrspace(200)* %addr to i16 addrspace(200)*
// CHECK:  call i32 @llvm.aarch64.stxr.p200i16(i64 42, i16 addrspace(200)* elementtype(i16) [[ADDR16]])

  res |= __builtin_arm_strex(42, (int *)addr);
// CHECK: [[ADDR32:%.*]] = bitcast i8 addrspace(200)* %addr to i32 addrspace(200)*
// CHECK: call i32 @llvm.aarch64.stxr.p200i32(i64 42, i32 addrspace(200)* elementtype(i32) [[ADDR32]])

  res |= __builtin_arm_strex(42, (long long *)addr);
// CHECK: [[ADDR64:%.*]] = bitcast i8 addrspace(200)* %addr to i64 addrspace(200)*
// CHECK: call i32 @llvm.aarch64.stxr.p200i64(i64 42, i64 addrspace(200)* elementtype(i64) [[ADDR64]])

  res |= __builtin_arm_strex(2.71828f, (float *)addr);
// CHECK: [[TMP4:%.*]] = bitcast i8 addrspace(200)* %addr to float addrspace(200)*
// CHECK: [[TMP5:%.*]] = bitcast float addrspace(200)* [[TMP4]] to i32 addrspace(200)*
// CHECK: call i32 @llvm.aarch64.stxr.p200i32(i64 1076754509, i32 addrspace(200)* elementtype(i32) [[TMP5]])

  res |= __builtin_arm_strex(3.14159, (double *)addr);
// CHECK: [[TMP4:%.*]] = bitcast i8 addrspace(200)* %addr to double addrspace(200)*
// CHECK: [[TMP5:%.*]] = bitcast double addrspace(200)* [[TMP4]] to i64 addrspace(200)*
// CHECK: call i32 @llvm.aarch64.stxr.p200i64(i64 4614256650576692846, i64 addrspace(200)* elementtype(i64) [[TMP5]])

  res |= __builtin_arm_strex(&var, (struct Simple **)addr);
// CHECK: [[TMP4:%.*]] = bitcast i8 addrspace(200)* %addr to %struct.Simple addrspace(200)* addrspace(200)*
// CHECK: [[TMP5:%.*]] = bitcast %struct.Simple addrspace(200)* addrspace(200)* [[TMP4]] to i8 addrspace(200)*
// CHECK: [[PTRVAL:%.*]] = bitcast %struct.Simple addrspace(200)* %var to i8 addrspace(200)*
// CHECK: call i32 @llvm.aarch64.cstxr.p200p200i8(i8 addrspace(200)* %10, i8 addrspace(200)* addrspace(200)* elementtype(i8 addrspace(200)*) [[TMP5]])

  return res;
}

int test_stlex(char *addr) {
// CHECK-LABEL: @test_stlex
  int res = 0;
  struct Simple var = {0};
  res |= __builtin_arm_stlex(4, addr);
// CHECK: call i32 @llvm.aarch64.stlxr.p200i8(i64 4, i8 addrspace(200)* elementtype(i8) %addr)

  res |= __builtin_arm_stlex(42, (short *)addr);
// CHECK: [[ADDR16:%.*]] = bitcast i8 addrspace(200)* %addr to i16 addrspace(200)*
// CHECK:  call i32 @llvm.aarch64.stlxr.p200i16(i64 42, i16 addrspace(200)* elementtype(i16) [[ADDR16]])

  res |= __builtin_arm_stlex(42, (int *)addr);
// CHECK: [[ADDR32:%.*]] = bitcast i8 addrspace(200)* %addr to i32 addrspace(200)*
// CHECK: call i32 @llvm.aarch64.stlxr.p200i32(i64 42, i32 addrspace(200)* elementtype(i32) [[ADDR32]])

  res |= __builtin_arm_stlex(42, (long long *)addr);
// CHECK: [[ADDR64:%.*]] = bitcast i8 addrspace(200)* %addr to i64 addrspace(200)*
// CHECK: call i32 @llvm.aarch64.stlxr.p200i64(i64 42, i64 addrspace(200)* elementtype(i64) [[ADDR64]])

  res |= __builtin_arm_stlex(2.71828f, (float *)addr);
// CHECK: [[TMP4:%.*]] = bitcast i8 addrspace(200)* %addr to float addrspace(200)*
// CHECK: [[TMP5:%.*]] = bitcast float addrspace(200)* [[TMP4]] to i32 addrspace(200)*
// CHECK: call i32 @llvm.aarch64.stlxr.p200i32(i64 1076754509, i32 addrspace(200)* elementtype(i32) [[TMP5]])

  res |= __builtin_arm_stlex(3.14159, (double *)addr);
// CHECK: [[TMP4:%.*]] = bitcast i8 addrspace(200)* %addr to double addrspace(200)*
// CHECK: [[TMP5:%.*]] = bitcast double addrspace(200)* [[TMP4]] to i64 addrspace(200)*
// CHECK: call i32 @llvm.aarch64.stlxr.p200i64(i64 4614256650576692846, i64 addrspace(200)* elementtype(i64) [[TMP5]])

  res |= __builtin_arm_stlex(&var, (struct Simple **)addr);
// CHECK: [[TMP4:%.*]] = bitcast i8 addrspace(200)* %addr to %struct.Simple addrspace(200)* addrspace(200)*
// CHECK: [[TMP5:%.*]] = bitcast %struct.Simple addrspace(200)* addrspace(200)* [[TMP4]] to i8 addrspace(200)*
// CHECK: [[PTRVAL:%.*]] = bitcast %struct.Simple addrspace(200)* %var to i8 addrspace(200)*
// CHECK: call i32 @llvm.aarch64.cstlxr.p200p200i8(i8 addrspace(200)* %10, i8 addrspace(200)* addrspace(200)* elementtype(i8 addrspace(200)*) [[TMP5]])

  return res;
}

void test_clrex() {
// CHECK-LABEL: @test_clrex

  __builtin_arm_clrex();
// CHECK: call void @llvm.aarch64.clrex()
}

// 128-bit tests

__int128 test_ldrex_128(__int128 *addr) {
// CHECK-LABEL: @test_ldrex_128

  return __builtin_arm_ldrex(addr);
// CHECK: [[ADDR8:%.*]] = bitcast i128 addrspace(200)* %addr to i8 addrspace(200)*
// CHECK: [[STRUCTRES:%.*]] = call { i64, i64 } @llvm.aarch64.ldxp.p200i8(i8 addrspace(200)* [[ADDR8]])
// CHECK: [[RESHI:%.*]] = extractvalue { i64, i64 } [[STRUCTRES]], 1
// CHECK: [[RESLO:%.*]] = extractvalue { i64, i64 } [[STRUCTRES]], 0
// CHECK: [[RESHI64:%.*]] = zext i64 [[RESHI]] to i128
// CHECK: [[RESLO64:%.*]] = zext i64 [[RESLO]] to i128
// CHECK: [[RESHIHI:%.*]] = shl nuw i128 [[RESHI64]], 64
// CHECK: [[INTRES:%.*]] = or i128 [[RESHIHI]], [[RESLO64]]
// CHECK: ret i128 [[INTRES]]
}

int test_strex_128(__int128 *addr, __int128 val) {
// CHECK-LABEL: @test_strex_128

  return __builtin_arm_strex(val, addr);
// CHECK: store i128 %val, i128 addrspace(200)* [[TMP:%.*]], align 16
// CHECK: [[LOHI_ADDR:%.*]] = bitcast i128 addrspace(200)* [[TMP]] to { i64, i64 } addrspace(200)*
// CHECK: [[LOHI:%.*]] = load { i64, i64 }, { i64, i64 } addrspace(200)* [[LOHI_ADDR]]
// CHECK: [[LO:%.*]] = extractvalue { i64, i64 } [[LOHI]], 0
// CHECK: [[HI:%.*]] = extractvalue { i64, i64 } [[LOHI]], 1
// CHECK: [[ADDR8:%.*]] = bitcast i128 addrspace(200)* %addr to i8 addrspace(200)*
// CHECK: call i32 @llvm.aarch64.stxp.p200i8(i64 [[LO]], i64 [[HI]], i8 addrspace(200)* [[ADDR8]])
}

__int128 test_ldaex_128(__int128 *addr) {
// CHECK-LABEL: @test_ldaex_128

  return __builtin_arm_ldaex(addr);
// CHECK: [[ADDR8:%.*]] = bitcast i128 addrspace(200)* %addr to i8 addrspace(200)*
// CHECK: [[STRUCTRES:%.*]] = call { i64, i64 } @llvm.aarch64.ldaxp.p200i8(i8 addrspace(200)* [[ADDR8]])
// CHECK: [[RESHI:%.*]] = extractvalue { i64, i64 } [[STRUCTRES]], 1
// CHECK: [[RESLO:%.*]] = extractvalue { i64, i64 } [[STRUCTRES]], 0
// CHECK: [[RESHI64:%.*]] = zext i64 [[RESHI]] to i128
// CHECK: [[RESLO64:%.*]] = zext i64 [[RESLO]] to i128
// CHECK: [[RESHIHI:%.*]] = shl nuw i128 [[RESHI64]], 64
// CHECK: [[INTRES:%.*]] = or i128 [[RESHIHI]], [[RESLO64]]
// CHECK: ret i128 [[INTRES]]
}

int test_stlex_128(__int128 *addr, __int128 val) {
// CHECK-LABEL: @test_stlex_128

  return __builtin_arm_stlex(val, addr);
// CHECK: store i128 %val, i128 addrspace(200)* [[TMP:%.*]], align 16
// CHECK: [[LOHI_ADDR:%.*]] = bitcast i128 addrspace(200)* [[TMP]] to { i64, i64 } addrspace(200)*
// CHECK: [[LOHI:%.*]] = load { i64, i64 }, { i64, i64 } addrspace(200)* [[LOHI_ADDR]]
// CHECK: [[LO:%.*]] = extractvalue { i64, i64 } [[LOHI]], 0
// CHECK: [[HI:%.*]] = extractvalue { i64, i64 } [[LOHI]], 1
// CHECK: [[ADDR8:%.*]] = bitcast i128 addrspace(200)* %addr to i8 addrspace(200)*
// CHECK: [[RES:%.*]] = call i32 @llvm.aarch64.stlxp.p200i8(i64 [[LO]], i64 [[HI]], i8 addrspace(200)* [[ADDR8]])
}
