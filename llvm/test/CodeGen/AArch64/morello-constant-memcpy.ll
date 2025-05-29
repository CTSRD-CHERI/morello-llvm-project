; RUN: llc -mtriple=arm64 -mattr=+c64,+morello -target-abi purecap -o - %s | FileCheck %s

@.str = private unnamed_addr addrspace(200) constant [5 x i8] c"dsad\00", align 1

; CHECK-LABEL: fun
; CHECK: mov w[[REG:[0-9]+]], #29540
; CHECK: strb wzr, [c0, #4]
; CHECK: movk w[[REG]], #25697, lsl #16
; CHECK: str w8, [c0]
define void @fun(ptr addrspace(200) nocapture %tt) {
entry:
  tail call void @llvm.memcpy.p200.p200.i64(ptr addrspace(200) %tt, ptr addrspace(200) @.str, i64 5, i32 1, i1 false)
  ret void
}

declare void @llvm.memcpy.p200.p200.i64(ptr addrspace(200) nocapture writeonly, ptr addrspace(200) nocapture readonly, i64, i32, i1)
