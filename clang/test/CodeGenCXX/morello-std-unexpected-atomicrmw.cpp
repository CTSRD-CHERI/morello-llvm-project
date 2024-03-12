// REQUIRES: aarch64-registered-target
// RUN: %clang_cc1 -triple aarch64-none-elf -target-feature +c64 -target-abi purecap -emit-llvm \
// RUN:            -std=c++11 -mllvm -cheri-cap-table-abi=pcrel -o - %s | FileCheck %s
// RUN: %clang_cc1 -triple aarch64-none-elf -target-feature +c64 -target-abi purecap -target-feature +c64 \
// RUN:            -mllvm -cheri-cap-table-abi=pcrel -ast-dump -std=c++11 %s | FileCheck -check-prefix=AST %s

// Copied from the corresponding cheri file.

typedef void (*handler)();
__attribute__((__require_constant_initialization__)) static handler __handler;

handler set_handler_sync(handler func) noexcept {
  return __sync_lock_test_and_set(&__handler, func);
  // CHECK: atomicrmw xchg ptr addrspace(200) @_ZL9__handler, ptr addrspace(200) %0 seq_cst
  // AST: DeclRefExpr {{.*}} '__sync_lock_test_and_set_cap' '__intcap (volatile __intcap *, __intcap, ...) noexcept'
}

handler get_handler_sync() noexcept {
  // CHECK: atomicrmw add ptr addrspace(200) @_ZL9__handler, ptr addrspace(200) null seq_cst
  return __sync_fetch_and_add(&__handler, (handler)0);
  // AST: DeclRefExpr {{.*}} '__sync_fetch_and_add_cap' '__intcap (volatile __intcap *, __intcap, ...) noexcept'
}

handler set_handler_atomic(handler func) noexcept {
  // CHECK-NOT: bitcast ptr addrspace(200) %.atomictmp to ptr addrspace(200)
  // CHECK-NOT: bitcast ptr addrspace(200) %atomic-temp to ptr addrspace(200)
  // CHECK-NOT: bitcast ptr addrspace(200) %1 to ptr addrspace(200)
  // CHECK-NOT: bitcast ptr addrspace(200) %2 to ptr addrspace(200)
  // CHECK-NOT: bitcast ptr addrspace(200) %2 to ptr addrspace(200)
  // CHECK: atomicrmw xchg ptr addrspace(200) @_ZL9__handler, ptr addrspace(200) %1 seq_cst
  return __atomic_exchange_n(&__handler, func, __ATOMIC_SEQ_CST);
}

handler get_handler_atomic() noexcept {
  // CHECK-NOT: bitcast ptr addrspace(200) %atomic-temp to ptr addrspace(200)
  // CHECK-NOT: bitcast ptr addrspace(200) %0 to ptr addrspace(200)
  // CHECK-NOT: bitcast ptr addrspace(200) %0 to ptr addrspace(200)
  // CHECK: load atomic ptr addrspace(200), ptr addrspace(200) @_ZL9__handler seq_cst, align 16
  return __atomic_load_n(&__handler, __ATOMIC_SEQ_CST);
}

__attribute__((__require_constant_initialization__)) static _Atomic(handler) __atomic_handler;

handler set_handler_c11_atomic(handler func) noexcept {
  // CHECK-NOT: bitcast ptr addrspace(200) %.atomictmp to ptr addrspace(200)
  // CHECK-NOT: bitcast ptr addrspace(200) %atomic-temp to ptr addrspace(200)
  // CHECK-NOT: bitcast ptr addrspace(200) %1 to ptr addrspace(200)
  // CHECK-NOT: bitcast ptr addrspace(200) %2 to ptr addrspace(200)
  // CHECK-NOT: bitcast ptr addrspace(200) %2 to ptr addrspace(200)
  // CHECK: atomicrmw xchg ptr addrspace(200) @_ZL16__atomic_handler, ptr addrspace(200) %1 seq_cst
  return __c11_atomic_exchange(&__atomic_handler, func, __ATOMIC_SEQ_CST);
}
