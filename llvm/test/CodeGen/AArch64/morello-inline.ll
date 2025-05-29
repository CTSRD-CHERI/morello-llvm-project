; RUN: llc -mtriple=arm64 -mattr=+morello -o - %s | FileCheck %s

; CHECK-LABEL: testInlineAsmCapabilityConstraint
define ptr addrspace(200) @testInlineAsmCapabilityConstraint(ptr addrspace(200) %foo, i64 %bar) {
entry:
; CHECK: scbnds	c0, c0, x1
; CHECK: scbnds	c0, c0, x1
  %0 = tail call ptr addrspace(200) asm sideeffect "scbnds\09$0, $1, $2", "=C,C,r"(ptr addrspace(200) %foo, i64 %bar)
  %1 = tail call ptr addrspace(200) asm sideeffect "scbnds\09$0, $1, $2", "=r,C,r"(ptr addrspace(200) %0, i64 %bar)
  ret ptr addrspace(200) %1
}
