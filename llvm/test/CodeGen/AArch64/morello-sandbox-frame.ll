; RUN: llc -march=arm64 -mattr=+c64,+morello,+use-16-cap-regs -target-abi purecap -o - %s | FileCheck %s

target datalayout = "e-m:e-i64:64-i128:128-n32:64-S128-pf200:128:128:128:64-A200-P200-G200"
target triple = "aarch64-none--elf"

; CHECK-LABEL: frameWithCapabilityRegisters
define i32 @frameWithCapabilityRegisters(i32 %argc, i8 addrspace(200)* addrspace(200)* %argv) addrspace(200) {
entry:
; CHECK: stp	c30, c24, [csp, #-48]!
; CHECK-NEXT: .cfi_def_cfa_offset 48
; CHECK-NEXT: str	x19, [csp, #32]
; CHECK: ldr	x19, [csp, #32]
; CHECK-NEXT: ldp	c30, c24, [csp], #48

  %call = call i32 addrspace(200)* @foo()
  %r1 = load i32, i32 addrspace(200)* %call, align 4
  %a = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %argv, align 16
  %call1 = call i32 @bar(i8 addrspace(200)* %a, i32 %r1)
  %add = add nsw i32 %call1, %r1
  ret i32 %add
}

declare i32 addrspace(200)* @foo() addrspace(200)
declare i32 @bar(i8 addrspace(200)*, i32) addrspace(200)
