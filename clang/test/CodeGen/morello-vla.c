// RUN: %clang -O0 -target aarch64-none-linux-gnu -march=morello+c64 -mabi=purecap -S -emit-llvm -o - %s | FileCheck %s
// RUN: %clang -O0 -target aarch64-none-linux-gnu -march=morello+c64 -mabi=purecap -S -o - %s

// CHECK-LABEL: testStackSaveRestore
void testStackSaveRestore(unsigned long n) {
  int tab[n];
// CHECK:  %[[Slot:.*]] = alloca ptr addrspace(200), align 16
// CHECK:  %[[SP:.*]] = call ptr addrspace(200) @llvm.stacksave.p200()
// CHECK:  store ptr addrspace(200) %[[SP]], ptr addrspace(200) %[[Slot]], align 16
// CHECK:  %[[SPs:.*]] = load ptr addrspace(200), ptr addrspace(200) %[[Slot]], align 16
// CHECK:  call void @llvm.stackrestore.p200(ptr addrspace(200) %[[SPs]])
}
