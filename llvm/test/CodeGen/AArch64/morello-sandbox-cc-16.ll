; RUN: llc -mtriple=aarch64-none-elf -mattr=+morello,+c64,+use-16-cap-regs -target-abi purecap -o - %s \
; RUN:   | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none--elf"

declare [2 x ptr addrspace(200)] @g1([2 x ptr addrspace(200)])

; We only have 6 registers for argument passing in the pure capability ABI with 16 capability registers. Other
; arguments are passed on the stack.

; CHECK-LABEL: fun0
; CHECK:  ldp c1, c0, [csp, #0]
define [2 x ptr addrspace(200)] @fun0([2 x ptr addrspace(200)] %f0.coerce, [2 x ptr addrspace(200)] %f2.coerce,
                                            [2 x ptr addrspace(200)] %f3.coerce, [2 x ptr addrspace(200)] %f1.coerce) local_unnamed_addr addrspace(200) {
entry:
  %f1.coerce.fca.0.extract = extractvalue [2 x ptr addrspace(200)] %f1.coerce, 0
  %f1.coerce.fca.1.extract = extractvalue [2 x ptr addrspace(200)] %f1.coerce, 1
  %.fca.0.insert = insertvalue [2 x ptr addrspace(200)] undef, ptr addrspace(200) %f1.coerce.fca.1.extract, 0
  %.fca.1.insert = insertvalue [2 x ptr addrspace(200)] %.fca.0.insert, ptr addrspace(200) %f1.coerce.fca.0.extract, 1
  %call = tail call [2 x ptr addrspace(200)] @g1([2 x ptr addrspace(200)] %.fca.1.insert)
  ret [2 x ptr addrspace(200)] %call
}

; CHECK-LABEL: fun1
; CHECK: mov c0, c5
; CHECK: mov c1, c4
define [2 x ptr addrspace(200)] @fun1([2 x ptr addrspace(200)] %f0.coerce, [2 x ptr addrspace(200)] %f2.coerce,
                                            [2 x ptr addrspace(200)] %f1.coerce) local_unnamed_addr addrspace(200) {
entry:
  %f1.coerce.fca.0.extract = extractvalue [2 x ptr addrspace(200)] %f1.coerce, 0
  %f1.coerce.fca.1.extract = extractvalue [2 x ptr addrspace(200)] %f1.coerce, 1
  %.fca.0.insert = insertvalue [2 x ptr addrspace(200)] undef, ptr addrspace(200) %f1.coerce.fca.1.extract, 0
  %.fca.1.insert = insertvalue [2 x ptr addrspace(200)] %.fca.0.insert, ptr addrspace(200) %f1.coerce.fca.0.extract, 1
  %call = tail call [2 x ptr addrspace(200)] @g1([2 x ptr addrspace(200)] %.fca.1.insert)
  ret [2 x ptr addrspace(200)] %call
}

define [2 x ptr addrspace(200)] @fun2([2 x ptr addrspace(200)] %f0.coerce) local_unnamed_addr addrspace(200) {
entry:
  %call = tail call [2 x ptr addrspace(200)] @g1([2 x ptr addrspace(200)] %f0.coerce)
  ret [2 x ptr addrspace(200)] %call
}
