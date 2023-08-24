// RUN: %cheri_purecap_cc1 -emit-llvm -o - %s | FileCheck %s
// RUN: %clang_cc1 -triple aarch64-none-elf -target-feature +c64 -target-abi purecap -mllvm -cheri-cap-table-abi=pcrel -emit-llvm -o - %s | FileCheck %s

// Check that arguments that are passed indirectly by pointer have the correct
// address space

class unique_lock {
  public:
    unique_lock() { }
    unique_lock(unique_lock const&) { }
};

// CHECK: define dso_local void @_Z25notify_all_at_thread_exit11unique_lock(ptr addrspace(200) noundef %lk)
void notify_all_at_thread_exit(unique_lock lk) { }

int main(void) {
  unique_lock l;
  notify_all_at_thread_exit(l);
  return 0;
}

