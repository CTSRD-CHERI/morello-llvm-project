; RUN: opt -S -loop-reduce -target-abi purecap -march=arm64 -mattr=+c64 -o -  %s | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none--elf"

%struct.arc.11.81.95.165.263.277.305.375.529.543.557.571.655.711.725.739.827 = type { ptr addrspace(200), ptr addrspace(200), ptr addrspace(200), ptr addrspace(200), i64, i64, i64, i64 }
%struct.node.12.82.96.166.264.278.306.376.530.544.558.572.656.712.726.740.826 = type { i64, ptr addrspace(200), ptr addrspace(200), ptr addrspace(200), ptr addrspace(200), ptr addrspace(200), i64, i64, ptr addrspace(200), ptr addrspace(200), ptr addrspace(200), i64, i64, ptr addrspace(200), i64 }

; CHECK-LABEL: foo
define void @foo() addrspace(200) {
entry:
  br label %for.body76

; CHECK-NOT: inttoptr
; CHECK: icmp eq i64

for.body76:
  %arcnew.1219 = phi ptr addrspace(200) [ %incdec.ptr87, %for.body76 ], [ undef, %entry ]
  %incdec.ptr87 = getelementptr inbounds %struct.arc.11.81.95.165.263.277.305.375.529.543.557.571.655.711.725.739.827, ptr addrspace(200) %arcnew.1219, i64 1
  %cmp75 = icmp eq ptr addrspace(200) %incdec.ptr87, undef
  br label %for.body76
}
