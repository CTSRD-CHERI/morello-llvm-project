; RUN: llc -mtriple=aarch64 -mattr=+morello,+c64 -target-abi purecap-benchmark -verify-machineinstrs %s -o - | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none-unknown-elf"

; CHECK-LABEL: foo:
; CHECK: br x0
define i32 @foo(ptr addrspace(200) nocapture %arg) local_unnamed_addr addrspace(200) {
entry:
  %call = tail call i32 %arg()
  ret i32 %call
}

; CHECK-LABEL: bar:
; CHECK:       and x30, x30, #0xfffffffffffffffe
; CHECK-NEXT:  ret x30
define i32 @bar() local_unnamed_addr addrspace(200) {
entry:
  ret i32 42
}

; CHECK-LABEL: bat:
; CHECK:      blr x0
; CHECK:      and x30, x30, #0xfffffffffffffffe
; CHECK-NEXT: ret x30
define i32 @bat(ptr addrspace(200) nocapture %arg) local_unnamed_addr addrspace(200) {
entry:
  %call = tail call i32 %arg() #3
  %add = add nsw i32 %call, 1
  ret i32 %add
}
