; RUN: llc -mtriple=arm64 -mattr=+c64,+morello -target-abi purecap -o - %s | FileCheck %s

@.str = private unnamed_addr addrspace(200) constant [5 x i8] c"dsad\00", align 1

; CHECK-LABEL: fun
; CHECK: mov w[[REG:[0-9]+]], #29540
; CHECK: movk w[[REG]], #25697, lsl #16
; CHECK: strb wzr, [c0, #4]
; CHECK: str w8, [c0]
define void @fun(i8 addrspace(200)* nocapture %tt) {
entry:
  tail call void @llvm.memcpy.p200i8.p200i8.i64(i8 addrspace(200)* %tt, i8 addrspace(200)* getelementptr inbounds ([5 x i8], [5 x i8] addrspace(200)* @.str, i64 0, i64 0), i64 5, i32 1, i1 false)
  ret void
}

declare void @llvm.memcpy.p200i8.p200i8.i64(i8 addrspace(200)* nocapture writeonly, i8 addrspace(200)* nocapture readonly, i64, i32, i1)
