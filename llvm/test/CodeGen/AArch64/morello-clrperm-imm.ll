; RUN: llc -march=arm64 -mattr=+morello,+c64 -target-abi purecap %s -o - | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none-unknown-elf"

declare ptr addrspace(200) @llvm.cheri.cap.perms.and.i64(ptr addrspace(200), i64) addrspace(200)

; cheri_perms_clear(a, CHERI_PERM_EXECUTE);
; CHECK-LABEL: foo
; CHECK: clrperm c0, c0, x
define ptr addrspace(200) @foo(ptr addrspace(200) readnone %a) local_unnamed_addr addrspace(200) #0 {
entry:
  %0 = tail call ptr addrspace(200) @llvm.cheri.cap.perms.and.i64(ptr addrspace(200) %a, i64 -32769)
  ret ptr addrspace(200) %0
}

; cheri_perms_clear(a, CHERI_PERM_EXECUTE | CHERI_PERM_STORE);
; CHECK-LABEL: baz
; CHECK: clrperm c0, c0, wx
define ptr addrspace(200) @baz(ptr addrspace(200) readnone %a) local_unnamed_addr addrspace(200)  {
entry:
  %0 = tail call ptr addrspace(200) @llvm.cheri.cap.perms.and.i64(ptr addrspace(200) %a, i64 -98305)
  ret ptr addrspace(200) %0
}

; cheri_perms_clear(a, CHERI_PERM_EXECUTE | CHERI_PERM_STORE | CHERI_PERM_LOAD);
; CHECK-LABEL: bif
; CHECK: clrperm c0, c0, rwx
define ptr addrspace(200) @bif(ptr addrspace(200) readnone %a) local_unnamed_addr addrspace(200)  {
entry:
  %0 = tail call ptr addrspace(200) @llvm.cheri.cap.perms.and.i64(ptr addrspace(200) %a, i64 -229377)
  ret ptr addrspace(200) %0
}

; unsigned perms = ~((1 << 15) | (1 << 14)) & ((1 << 19) -1);
; return cheri_perms_and(a, perms);
; CHECK-LABEL: bar
; CHECK: movk
define ptr addrspace(200) @bar(ptr addrspace(200) readnone %a) local_unnamed_addr addrspace(200)  {
entry:
  %0 = tail call ptr addrspace(200) @llvm.cheri.cap.perms.and.i64(ptr addrspace(200) %a, i64 475135)
  ret ptr addrspace(200) %0
}

; unsigned perms = ~((1 << 15) | (1 << 17)) & ((1 << 19) -1);
; return cheri_perms_and(a, perms);
; CHECK-LABEL: bat
define ptr addrspace(200) @bat(ptr addrspace(200) readnone %a) local_unnamed_addr addrspace(200)  {
entry:
  %0 = tail call ptr addrspace(200) @llvm.cheri.cap.perms.and.i64(ptr addrspace(200) %a, i64 360447)
  ret ptr addrspace(200) %0
}

; Permision bits are from 0 to 17, so an 18th bit is ignored.
; unsigned perms = ~((1 << 15) | (1 << 18)) & ((1 << 19) -1);
; return cheri_perms_and(a, perms);
; CHECK-LABEL: fiz
; CHECK: clrperm c0, c0, x
define ptr addrspace(200) @fiz(ptr addrspace(200) readnone %a) local_unnamed_addr addrspace(200)  {
entry:
  %0 = tail call ptr addrspace(200) @llvm.cheri.cap.perms.and.i64(ptr addrspace(200) %a, i64 229375)
  ret ptr addrspace(200) %0
}

; unsigned perms = ~((1 << 16) | (1 << 17)) & ((1 << 19) -1);
; return cheri_perms_and(a, perms);
; CHECK-LABEL: fib
; CHECK: clrperm c0, c0, rw
define ptr addrspace(200) @fib(ptr addrspace(200) readnone %a) local_unnamed_addr addrspace(200)  {
entry:
  %0 = tail call ptr addrspace(200) @llvm.cheri.cap.perms.and.i64(ptr addrspace(200) %a, i64 327679)
  ret ptr addrspace(200) %0
}

; This is almost a nop, except it can clear the tag if the input capability is sealed.
; CHECK-LABEL: fig
; CHECK: clrperm c0, c0, #0
define ptr addrspace(200) @fig(ptr addrspace(200) readnone %a) local_unnamed_addr addrspace(200)  {
entry:
  %0 = tail call ptr addrspace(200) @llvm.cheri.cap.perms.and.i64(ptr addrspace(200) %a, i64 -1)
  ret ptr addrspace(200) %0
}
