; RUN: llc -march=arm64 -mattr=+morello,+c64 -o - -target-abi purecap %s | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none-unknown-elf"

; CHECK-LABEL: foo
; CHECK: br c
define dso_local ptr addrspace(200) @foo(ptr addrspace(200) (ptr addrspace(200), i32) addrspace(200)* nocapture %func2) local_unnamed_addr addrspace(200) #0 {
entry:
  %call = tail call ptr addrspace(200) %func2(ptr addrspace(200) null, i32 1)
  ret ptr addrspace(200) %call
}

; CHECK-LABEL: bar
; CHECK: blr c
define dso_local nonnull ptr addrspace(200) @bar(ptr addrspace(200) (ptr addrspace(200), i32) addrspace(200)* nocapture %func2) local_unnamed_addr addrspace(200) #0 {
entry:
  %call = tail call ptr addrspace(200) %func2(ptr addrspace(200) null, i32 1)
  %add.ptr = getelementptr inbounds i8, ptr addrspace(200) %call, i64 1
  ret ptr addrspace(200) %add.ptr
}
