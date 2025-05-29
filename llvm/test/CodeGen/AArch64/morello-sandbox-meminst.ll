; RUN: llc -march=arm64 -mattr=+c64,+morello -target-abi purecap -cheri-no-pure-cap-libfunc=false -o - %s | FileCheck %s --check-prefix=ALL --check-prefix=CFUN
; RUN: llc -march=arm64 -mattr=+c64,+morello -target-abi purecap -cheri-no-cap-libfunc -o - %s | FileCheck %s --check-prefix=ALL --check-prefix=NOCFUN
; RUN: llc -march=arm64 -mattr=+c64,+morello -target-abi purecap -o - %s | FileCheck %s --check-prefix=ALL --check-prefix=NOCFUN

target datalayout = "e-m:e-i64:64-i128:128-n32:64-S128-pf200:128:128:128:64-A200-P200-G200"
target triple = "aarch64-none--elf"

%struct.x = type { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32 }

@blob = common addrspace(200) global %struct.x zeroinitializer, align 4
@blob2 = common addrspace(200) global %struct.x zeroinitializer, align 4

declare void @llvm.memset.p200.i64(ptr addrspace(200) nocapture, i8, i64, i1) addrspace(200)
declare void @llvm.memcpy.p200.p200.i64(ptr addrspace(200) nocapture, ptr addrspace(200) nocapture readonly, i64, i1) addrspace(200)
declare void @llvm.memmove.p200.p200.i64(ptr addrspace(200) nocapture, ptr addrspace(200) nocapture readonly, i64, i1) addrspace(200)

; ALL-LABEL: checkMemInst
define void @checkMemInst() {
entry:
  call void @llvm.memset.p200.i64(ptr addrspace(200) @blob, i8 0, i64 40, i1 false)
  call void @llvm.memcpy.p200.p200.i64(ptr addrspace(200) @blob2, ptr addrspace(200) @blob, i64 40, i1 false) no_preserve_cheri_tags

  tail call void @llvm.memmove.p200.p200.i64(ptr addrspace(200) @blob2, ptr addrspace(200) @blob, i64 40, i1 false) no_preserve_cheri_tags
  ret void
; ALL-NOT: bl	memset
; ALL-NOT: bl	memcpy
; ALL-NOT: bl	memmove
}

declare ptr addrspace(200) @memset(ptr addrspace(200), i32, i64) addrspace(200)
declare ptr addrspace(200) @memcpy(ptr addrspace(200), ptr addrspace(200), i64) addrspace(200)
declare ptr addrspace(200) @mempcpy(ptr addrspace(200), ptr addrspace(200), i64) addrspace(200)
declare ptr addrspace(200) @memmove(ptr addrspace(200), ptr addrspace(200), i64) addrspace(200)

; ALL-LABEL: testMemset
define ptr addrspace(200) @testMemset(ptr addrspace(200) %p, i64 %n) {
entry:
  %call = tail call ptr addrspace(200) @memset(ptr addrspace(200) %p, i32 0, i64 %n)
  ret ptr addrspace(200) %call
; CFUN: b	memset_c
; NOCFUN-NOT:   memset_c
; NOCFUN: b	memset
}

; ALL-LABEL: testMemset2
define void @testMemset2(ptr addrspace(200) %p, i64 %n) {
entry:
  %call = tail call ptr addrspace(200) @memset(ptr addrspace(200) %p, i32 0, i64 %n)
  ret void
; CFUN: b	memset_c
; NOCFUN-NOT:   memset_c
; NOCFUN: b	memset
}

; ALL-LABEL: testMemcpy
define ptr addrspace(200) @testMemcpy(ptr addrspace(200) %d, ptr addrspace(200) %s, i64 %n) {
entry:
  %call = tail call ptr addrspace(200) @memcpy(ptr addrspace(200) %d, ptr addrspace(200) %s, i64 %n)
  ret ptr addrspace(200) %call
; CFUN: b	memcpy_c
; NOCFUN-NOT:   memcpy_c
; NOCFUN: b	memcpy
}

; ALL-LABEL: testMemcpy2
define void @testMemcpy2(ptr addrspace(200) %d, ptr addrspace(200) %s, i64 %n) {
entry:
  %call = tail call ptr addrspace(200) @memcpy(ptr addrspace(200) %d, ptr addrspace(200) %s, i64 %n)
  ret void
; CFUN: b	memcpy_c
; NOCFUN-NOT:   memcpy_c
; NOCFUN: b	memcpy
}

; ALL-LABEL: testMempcpy
define ptr addrspace(200) @testMempcpy(ptr addrspace(200) %d, ptr addrspace(200) %s, i64 %n) {
entry:
  %call = tail call ptr addrspace(200) @mempcpy(ptr addrspace(200) %d, ptr addrspace(200) %s, i64 %n)
  ret ptr addrspace(200) %call
; CFUN: b	mempcpy_c
}

; ALL-LABEL: testMempcpy2
define void @testMempcpy2(ptr addrspace(200) %d, ptr addrspace(200) %s, i64 %n) {
entry:
  %call = tail call ptr addrspace(200) @mempcpy(ptr addrspace(200) %d, ptr addrspace(200) %s, i64 %n)
  ret void
; CFUN: b	mempcpy_c
; NOCFUN-NOT:   mempcpy_c
; NOTCFUN: b	mempcpy
}

; ALL-LABEL: testMemmove
define ptr addrspace(200) @testMemmove(ptr addrspace(200) %d, ptr addrspace(200) %s, i64 %n) {
entry:
  %call = tail call ptr addrspace(200) @memmove(ptr addrspace(200) %d, ptr addrspace(200) %s, i64 %n)
  ret ptr addrspace(200) %call
; CFUN: b	memmove_c
; NOCFUN-NOT:	memmove_c
; NOCFUN: b	memmove
}

; ALL-LABEL: testMemmove2
define void @testMemmove2(ptr addrspace(200) %d, ptr addrspace(200) %s, i64 %n) {
entry:
  %call = tail call ptr addrspace(200) @memmove(ptr addrspace(200) %d, ptr addrspace(200) %s, i64 %n)
  ret void
; CFUN: b	memmove_c
; NOCFUN-NOT:   memmove_c
; NOCFUN: b	memmove
}

; ALL-LABEL: checkMemSetIntrinsic
define void @checkMemSetIntrinsic(ptr addrspace(200) %in) {
entry:
; ALL: movi v0.2d, #0000000000000000
; ALL-DAG: str xzr, [c0, #32]
; ALL-DAG: stp q0, q0, [c0]
  call void @llvm.memset.p200.i64(ptr addrspace(200) align 16 %in, i8 0, i64 40, i1 false)
  ret void
}

; ALL-LABEL: checkMemCpyIntrinsic
define void @checkMemCpyIntrinsic(ptr addrspace(200) %in, ptr addrspace(200) %out) {
; ALL-DAG:	ldr	x[[REG:[0-9]+]], [c0, #32]
; ALL-DAG:	str	x[[REG]], [c1, #32]
; ALL-DAG:	ldp	c[[REG1:[0-9]+]], c[[REG2:[0-9]+]], [c0, #0]
; ALL-DAG:	stp	c[[REG1]], c[[REG2]], [c1, #0]
  call void @llvm.memcpy.p200.p200.i64(ptr addrspace(200) align 16 %out, ptr addrspace(200) align 16 %in, i64 40, i1 false)
  ret void
}

; ALL-LABEL: checkMemMoveIntrinsic
define void @checkMemMoveIntrinsic(ptr addrspace(200) %in, ptr addrspace(200) %out) {
; ALL-DAG:    ldr	x[[REG3:[0-9]+]], [c0, #32]
; ALL-DAG:	ldp	c[[REG1:[0-9]+]], c[[REG2:[0-9]+]], [c0, #0]
; ALL-DAG:	str	x[[REG3]], [c1, #32]
; ALL-DAG:	stp	c[[REG1:[0-9]+]], c[[REG2:[0-9]+]], [c1, #0]
  tail call void @llvm.memmove.p200.p200.i64(ptr addrspace(200) align 16 %out, ptr addrspace(200) align 16 %in, i64 40, i1 false)
  ret void
}

; ALL-LABEL: checkMemMoveIntrinsic_inline
define void @checkMemMoveIntrinsic_inline(ptr addrspace(200) %in, ptr addrspace(200) %out) {
; ALL-DAG:	ldp q[[REG1:[0-9]+]], q[[REG2:[0-9]+]], [c0]
; ALL-DAG:	stp q[[REG1]], q[[REG2]], [c1]
  tail call void @llvm.memmove.p200.p200.i64(ptr addrspace(200) align 8 %out, ptr addrspace(200) align 8 %in, i64 32, i1 false) no_preserve_cheri_tags
  ret void
}

; ALL-LABEL: checkMemMoveIntrinsic_inline_cap
define void @checkMemMoveIntrinsic_inline_cap(ptr addrspace(200) %in, ptr addrspace(200) %out) {
; CFUN: b memmove_c
; NOCFUN-NOT: memmove_c
; NOCFUN: b memmove
  tail call void @llvm.memmove.p200.p200.i64(ptr addrspace(200) align 8 %out, ptr addrspace(200) align 8 %in, i64 40, i1 false)
  ret void
}
