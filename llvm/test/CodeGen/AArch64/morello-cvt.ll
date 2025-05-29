; RUN: llc -march=arm64 -mattr=+c64 -target-abi purecap %s -o - | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none-unknown-elf"

; CHECK-LABEL: getaddr:
; CHECK: cvt	x0, c1, c0
define i64 @getaddr(ptr addrspace(200) readnone %base, ptr addrspace(200) readnone %cap) local_unnamed_addr addrspace(200) {
entry:
  %0 = tail call i64 @llvm.cheri.cap.to.pointer.i64(ptr addrspace(200) %base, ptr addrspace(200) %cap)
  ret i64 %0
}

; CHECK-LABEL: getcap:
; CHECK: cvtz	c0, c0, x1
define ptr addrspace(200) @getcap(ptr addrspace(200) readnone %cap, i64 %addr) local_unnamed_addr addrspace(200) {
entry:
  %0 = tail call ptr addrspace(200) @llvm.cheri.cap.from.pointer.i64(ptr addrspace(200) %cap, i64 %addr)
  ret ptr addrspace(200) %0
}

; CHECK-LABEL: getaddr_ddc:
; CHECK: cvtd	x0, c1
define i64 @getaddr_ddc(ptr addrspace(200) nocapture readnone %base, ptr addrspace(200) readnone %cap) local_unnamed_addr addrspace(200) {
entry:
  %0 = tail call ptr addrspace(200) @llvm.cheri.ddc.get()
  %1 = tail call i64 @llvm.cheri.cap.to.pointer.i64(ptr addrspace(200) %0, ptr addrspace(200) %cap)
  ret i64 %1
}

; CHECK-LABEL: getaddr_pcc:
; CHECK: cvtp	x0, c1
define i64 @getaddr_pcc(ptr addrspace(200) nocapture readnone %base, ptr addrspace(200) readnone %cap) local_unnamed_addr addrspace(200) {
entry:
  %0 = tail call ptr addrspace(200) @llvm.cheri.pcc.get()
  %1 = tail call i64 @llvm.cheri.cap.to.pointer.i64(ptr addrspace(200) %0, ptr addrspace(200) %cap)
  ret i64 %1
}

; CHECK-LABEL: getcap_ddc:
; CHECK: cvtdz	c0, x1
define ptr addrspace(200) @getcap_ddc(ptr addrspace(200) nocapture readnone %cap, i64 %addr) local_unnamed_addr addrspace(200) {
entry:
  %0 = tail call ptr addrspace(200) @llvm.cheri.ddc.get()
  %1 = tail call ptr addrspace(200) @llvm.cheri.cap.from.pointer.i64(ptr addrspace(200) %0, i64 %addr)
  ret ptr addrspace(200) %1
}

; CHECK-LABEL: getcap_pcc:
; CHECK: cvtpz	c0, x1
define ptr addrspace(200) @getcap_pcc(ptr addrspace(200) nocapture readnone %cap, i64 %addr) local_unnamed_addr addrspace(200) {
entry:
  %0 = tail call ptr addrspace(200) @llvm.cheri.pcc.get()
  %1 = tail call ptr addrspace(200) @llvm.cheri.cap.from.pointer.i64(ptr addrspace(200) %0, i64 %addr)
  ret ptr addrspace(200) %1
}

; CHECK-LABEL: getcap_ddc_nz:
; CHECK: cvtd	c0, x1
define ptr addrspace(200) @getcap_ddc_nz(ptr addrspace(200) nocapture readnone %cap, i64 %addr) local_unnamed_addr addrspace(200) {
entry:
  %0 = tail call ptr addrspace(200) @llvm.cheri.ddc.get()
  %1 = tail call ptr addrspace(200) @llvm.cheri.cap.from.pointer.nonnull.zero.i64(ptr addrspace(200) %0, i64 %addr)
  ret ptr addrspace(200) %1
}

; CHECK-LABEL: getcap_pcc_nz:
; CHECK: cvtp	c0, x1
define ptr addrspace(200) @getcap_pcc_nz(ptr addrspace(200) nocapture readnone %cap, i64 %addr) local_unnamed_addr addrspace(200) {
entry:
  %0 = tail call ptr addrspace(200) @llvm.cheri.pcc.get()
  %1 = tail call ptr addrspace(200) @llvm.cheri.cap.from.pointer.nonnull.zero.i64(ptr addrspace(200) %0, i64 %addr)
  ret ptr addrspace(200) %1
}

declare i64 @llvm.cheri.cap.to.pointer.i64(ptr addrspace(200), ptr addrspace(200)) addrspace(200)
declare ptr addrspace(200) @llvm.cheri.cap.from.pointer.i64(ptr addrspace(200), i64) addrspace(200)
declare ptr addrspace(200) @llvm.cheri.ddc.get() addrspace(200)
declare ptr addrspace(200) @llvm.cheri.pcc.get() addrspace(200)
declare ptr addrspace(200) @llvm.cheri.cap.from.pointer.nonnull.zero.i64(ptr addrspace(200), i64) addrspace(200)

