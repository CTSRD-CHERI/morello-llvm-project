; RUN: llc -mtriple=arm64 -mattr=+morello,+c64 -target-abi purecap -o - -cheri-no-pure-cap-libfunc=false %s | FileCheck %s --check-prefix=ALL --check-prefix=CFUN
; RUN: llc -mtriple=arm64 -mattr=+morello,+c64 -target-abi purecap -o - -cheri-no-cap-libfunc %s | FileCheck %s --check-prefix=ALL --check-prefix=NOCFUN
; RUN: llc -mtriple=arm64 -mattr=+morello,+c64 -target-abi purecap -o - %s | FileCheck %s --check-prefix=ALL --check-prefix=NOCFUN

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"

; ALL-LABEL: bar
; CFUN: b memcpy_c
; NOCFUN-NOT: memcpy_c
; NOCFUN: b memcpy
define void @bar(ptr addrspace(200) %dst, ptr addrspace(200) %src, i32 %size) addrspace(200) {
entry:
  %conv.i = zext i32 %size to i64
  %0 = tail call i64 @llvm.objectsize.i64.p200(ptr addrspace(200) %dst, i1 false)
  %call.i = tail call ptr addrspace(200) @__memcpy_chk(ptr addrspace(200) %dst, ptr addrspace(200) %src, i64 %conv.i, i64 %0) #0
  ret void
}

; ALL-LABEL: baz
define void @baz(ptr addrspace(200) %dst, ptr addrspace(200) %src) addrspace(200) {
entry:
; CFUN: b memcpy_c
; NOCFUN-NOT: memcpy_c
; NOCFUN: b memcpy
  %call.i = tail call ptr addrspace(200) @__memcpy_chk(ptr addrspace(200) %dst, ptr addrspace(200) %src, i64 32, i64 32) #0
  ret void
}

; ALLL-LABEL: foo
; CFUN: b memcpy_c
; NOCFUN-NOT: memcpy_c
; NOCFUN: b memcpy
define void @foo(ptr addrspace(200) %dst, ptr addrspace(200) %src, i32 %size) addrspace(200) {
entry:
  %call.i = tail call ptr addrspace(200) @__memcpy_chk(ptr addrspace(200) %dst, ptr addrspace(200) %src, i64 32, i64 32) #0
  ret void
}

; ALL-LABEL: barmove
; CFUN: b memmove_c
; NOCFUN-NOT: memmove_c
; NOCFUN: b memmove
define void @barmove(ptr addrspace(200) %dst, ptr addrspace(200) %src, i32 %size) addrspace(200) {
entry:
  %conv.i = zext i32 %size to i64
  %0 = tail call i64 @llvm.objectsize.i64.p200(ptr addrspace(200) %dst, i1 false)
  %call.i = tail call ptr addrspace(200) @__memmove_chk(ptr addrspace(200) %dst, ptr addrspace(200) %src, i64 %conv.i, i64 %0) #0
  ret void
}

; ALL-LABEL: bazmove
define void @bazmove(ptr addrspace(200) %dst, ptr addrspace(200) %src) addrspace(200) {
entry:
; CFUN: b memmove_c
; NOCFUN-NOT: memmove_c
; NOCFUN: b memmove
  %call.i = tail call ptr addrspace(200) @__memmove_chk(ptr addrspace(200) %dst, ptr addrspace(200) %src, i64 32, i64 32) #0
  ret void
}

; ALL-LABEL: foomove
; CFUN: b memmove_c
; NOCFUN-NOT: memmove_c
; NOCFUN: b memmove
define void @foomove(ptr addrspace(200) %dst, ptr addrspace(200) %src, i32 %size) addrspace(200) {
entry:
  %call.i = tail call ptr addrspace(200) @__memmove_chk(ptr addrspace(200) %dst, ptr addrspace(200) %src, i64 32, i64 32) #0
  ret void
}

declare ptr addrspace(200) @__memcpy_chk(ptr addrspace(200), ptr addrspace(200), i64, i64) addrspace(200)
declare ptr addrspace(200) @__memmove_chk(ptr addrspace(200), ptr addrspace(200), i64, i64) addrspace(200)
declare i64 @llvm.objectsize.i64.p200(ptr addrspace(200), i1) addrspace(200)

attributes #0 = { must_preserve_cheri_tags }
