; RUN: llc -mtriple=arm64 -mattr=+morello,+c64 -target-abi purecap -o - -cheri-no-pure-cap-libfunc=false %s | FileCheck %s --check-prefix=ALL --check-prefix=CFUN
; RUN: llc -mtriple=arm64 -mattr=+morello,+c64 -target-abi purecap -o - -cheri-no-cap-libfunc %s | FileCheck %s --check-prefix=ALL --check-prefix=NOCFUN
; RUN: llc -mtriple=arm64 -mattr=+morello,+c64 -target-abi purecap -o - %s | FileCheck %s --check-prefix=ALL --check-prefix=NOCFUN

target datalayout = "e-m:e-pf200:128:128-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"

; ALL-LABEL: bar
; CFUN: bl memcpy_c
; NOCFUN-NOT: memcpy_c
; NOCFUN: bl memcpy
define void @bar(i8 addrspace(200)* %dst, i8 addrspace(200)* %src, i32 %size) addrspace(200) {
entry:
  %conv.i = zext i32 %size to i64
  %0 = tail call i64 @llvm.objectsize.i64.p200i8(i8 addrspace(200)* %dst, i1 false)
  %call.i = tail call i8 addrspace(200)* @__memcpy_chk(i8 addrspace(200)* %dst, i8 addrspace(200)* %src, i64 %conv.i, i64 %0)
  ret void
}

; ALL-LABEL: baz
define void @baz(i8 addrspace(200)* %dst, i8 addrspace(200)* %src) addrspace(200) {
entry:
; CFUN: bl memcpy_c
; NOCFUN-NOT: memcpy_c
; NOCFUN: bl memcpy
  %call.i = tail call i8 addrspace(200)* @__memcpy_chk(i8 addrspace(200)* %dst, i8 addrspace(200)* %src, i64 32, i64 32) #0
  ret void
}

; ALLL-LABEL: foo
; CFUN: bl memcpy_c
; NOCFUN-NOT: memcpy_c
; NOCFUN: bl memcpy
define void @foo(i8 addrspace(200)* %dst, i8 addrspace(200)* %src, i32 %size) addrspace(200) {
entry:
  %call.i = tail call i8 addrspace(200)* @__memcpy_chk(i8 addrspace(200)* %dst, i8 addrspace(200)* %src, i64 32, i64 32)
  ret void
}

; ALL-LABEL: barmove
; CFUN: bl memmove_c
; NOCFUN-NOT: memmove_c
; NOCFUN: bl memmove
define void @barmove(i8 addrspace(200)* %dst, i8 addrspace(200)* %src, i32 %size) addrspace(200) {
entry:
  %conv.i = zext i32 %size to i64
  %0 = tail call i64 @llvm.objectsize.i64.p200i8(i8 addrspace(200)* %dst, i1 false)
  %call.i = tail call i8 addrspace(200)* @__memmove_chk(i8 addrspace(200)* %dst, i8 addrspace(200)* %src, i64 %conv.i, i64 %0)
  ret void
}

; ALL-LABEL: bazmove
define void @bazmove(i8 addrspace(200)* %dst, i8 addrspace(200)* %src) addrspace(200) {
entry:
; CFUN: bl memmove_c
; NOCFUN-NOT: memmove_c
; NOCFUN: bl memmove
  %call.i = tail call i8 addrspace(200)* @__memmove_chk(i8 addrspace(200)* %dst, i8 addrspace(200)* %src, i64 32, i64 32) #0
  ret void
}

; ALL-LABEL: foomove
; CFUN: bl memmove_c
; NOCFUN-NOT: memmove_c
; NOCFUN: bl memmove
define void @foomove(i8 addrspace(200)* %dst, i8 addrspace(200)* %src, i32 %size) addrspace(200) {
entry:
  %call.i = tail call i8 addrspace(200)* @__memmove_chk(i8 addrspace(200)* %dst, i8 addrspace(200)* %src, i64 32, i64 32)
  ret void
}

declare i8 addrspace(200)* @__memcpy_chk(i8 addrspace(200)*, i8 addrspace(200)*, i64, i64) addrspace(200)
declare i8 addrspace(200)* @__memmove_chk(i8 addrspace(200)*, i8 addrspace(200)*, i64, i64) addrspace(200)
declare i64 @llvm.objectsize.i64.p200i8(i8 addrspace(200)*, i1) addrspace(200)

attributes #0 = { "must-preserve-cheri-tags" }
