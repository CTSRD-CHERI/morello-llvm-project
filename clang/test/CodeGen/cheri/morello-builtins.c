// RUN: %clang %s -target aarch64-none-linux-gnu -march=morello -S -emit-llvm -o - | FileCheck %s

void* __capability results[16];

long long test(void* __capability foo, void* __capability bar) {
  long long x = 42;
  int i = 0;

// CHECK: call i1 @llvm.cheri.cap.equal.exact
// CHECK: call i1 @llvm.cheri.cap.subset.test
// CHECK: call { ptr addrspace(200), i1 } @llvm.morello.subset.test.unseal
  if (__builtin_cheri_equal_exact(foo, bar) || __builtin_cheri_subset_test(foo, bar))
    results[i++] = __builtin_morello_chkssu(foo, bar);

// CHECK: [[RET:%.*]] = call { ptr addrspace(200), i1 } @llvm.morello.subset.test.unseal
// CHECK: [[VAL0:%.*]] = extractvalue { ptr addrspace(200), i1 } [[RET]], 0
// CHECK: [[VAL1:%.*]] = extractvalue { ptr addrspace(200), i1 } [[RET]], 1
// CHECK: select i1 [[VAL1]], ptr addrspace(200) [[VAL0]], ptr addrspace(200) null
  results[i++] = __builtin_morello_subset_test_unseal_or_null(foo, bar);

// CHECK: call i64 @llvm.morello.convert.to.ptr
  x &= __builtin_morello_cvt(foo, bar);

// CHECK: call ptr addrspace(200) @llvm.morello.convert.to.offset.null.cap.zero.semantics
  results[i++] = __builtin_morello_cvtz(foo, x);

  return x;
}

