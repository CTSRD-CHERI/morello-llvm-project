; RUN: llc -march=arm64 < %s -mattr=+c64,+morello -target-abi purecap -o - | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none-unknown-elf"

; Use a local label when computing the function size.

define void @foo() addrspace(200) {
; CHECK-LABEL: foo:
; CHECK-LABEL: .Lfunc_begin0:
; CHECK:         ret c30
; CHECK-LABEL: .Lfunc_end0:
; CHECK:	.size	foo, .Lfunc_end0-.Lfunc_begin0
entry:
  ret void
}
