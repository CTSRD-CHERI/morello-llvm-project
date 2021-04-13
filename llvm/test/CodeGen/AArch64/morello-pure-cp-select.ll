; RUN: llc -mtriple=arm64 < %s -target-abi purecap -mattr=+c64,+morello | FileCheck %s

; CHECK-LABEL: foo
; CHECK-DAG: cmp	w0, #0
; CHECK-DAG: adrp	{{x|c}}[[ADRREG:[0-9]+]], .LCPI0_0
; CHECK-DAG: cset	w[[OFFREG:[0-9]+]], eq
; CHECK-DAG: add	c[[ADRREG1:[0-9+]]], c[[ADRREG]], :lo12:.LCPI0_0
; CHECK-DAG: ldr	q0, [c[[ADRREG1]], w[[OFFREG]], uxtw #4]

define dso_local fp128 @foo(i32 %sign) local_unnamed_addr addrspace(200) {
entry:
  %tobool = icmp eq i32 %sign, 0
  %cond = select i1 %tobool, fp128 0xL0000009000000000000000000000a000, fp128 0xL20000000000000000000000000000b00
  ret fp128 %cond
}
