; RUN: llc -mtriple=aarch64-none-elf -mattr=+morello -o - %s \
; RUN:   | FileCheck %s
; RUN: llc -mtriple=aarch64-none-elf -mattr=+c64,+morello -target-abi purecap -o - %s \
; RUN:   | FileCheck %s

; CHECK-LABEL: get_stack
define ptr addrspace(200) @get_stack() {
entry:
; CHECK: mov c0, csp
  %0 = call ptr addrspace(200) @llvm.cheri.stack.cap.get()
  ret ptr addrspace(200) %0
}
declare ptr addrspace(200) @llvm.cheri.stack.cap.get()
