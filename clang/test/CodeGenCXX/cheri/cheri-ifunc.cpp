// RUN: %cheri_purecap_cc1 -emit-llvm -o - %s | FileCheck %s

// CHECK: @_ZL3barv = ifunc ptr addrspace(200) (), ptr addrspace(200) @bar_ifun
// CHECK: define dso_local ptr addrspace(200) @bar_ifun() addrspace(200)
// CHECK: define dso_local ptr addrspace(200) @foo() addrspace(200)

static const char* bar() __attribute__ ((ifunc("bar_ifun")));
extern "C" const char* foo() {
  return bar();
}

extern "C" void* bar_ifun() {
  return nullptr;
}

