; RUN: llc -mtriple=arm64 -mattr=+morello -o - %s | FileCheck %s

; The cheri ccall on Morello (currently) passes the first two capability arguments
; in c9/c10 and first i64 argument in x11.

; CHECK-LABEL: test_i64
define chericcallcc void @test_i64(i8 addrspace(200)* %a1, i8 addrspace(200)* %a2, i64 %foo, i8 addrspace(200)* %a3, i64 %bar) {
; CHECK: mov	x[[TMP:[0-9]+]], x11
; CHECK: mov	c2, c10
; CHECK: mov	c10, c9
; CHECK: mov	c9, c0
; CHECK: mov	 x11, x1
; CHECK: mov	c0, c2
; CHECK: mov	 x1, x[[TMP]]
; CHECK-DAG: mov x2, xzr
; CHECK-DAG: mov x3, xzr
; CHECK-DAG: mov x4, xzr
; CHECK-DAG: mov x5, xzr
; CHECK-DAG: mov x6, xzr
; CHECK-DAG: mov x7, xzr
; CHECK-DAG: mov x8, xzr
; CHECK-DAG: fmov d0, xzr
; CHECK-DAG: fmov d1, xzr
; CHECK-DAG: fmov d2, xzr
; CHECK-DAG: fmov d3, xzr
; CHECK-DAG: fmov d4, xzr
; CHECK-DAG: fmov d5, xzr
; CHECK-DAG: fmov d6, xzr
; CHECK-DAG: fmov d7, xzr
  tail call chericcallcc void @b_i64(i8 addrspace(200)* %a3, i8 addrspace(200)* %a1, i64 %bar, i8 addrspace(200)* %a2, i64 %foo)
  ret void
}

; CHECK-LABEL: test_sret_fat
define void @test_sret_fat(i8 addrspace(200) *%sr, i8 addrspace(200)* %a1, i64 %foo, i8 addrspace(200)* %a2, i8 addrspace(200)* %a3, i64 %bar) {
; CHECK-NOT: mov x8, xzr
; CHECK: mov c8, c0
; CHECK: mov c9, c4
; CHECK: mov c10, c3
; CHECK: mov x11, x5
; CHECK-DAG: mov x2, xzr
; CHECK-DAG: mov x3, xzr
; CHECK-DAG: mov x4, xzr
; CHECK-DAG: mov x5, xzr
; CHECK-DAG: mov x6, xzr
; CHECK-DAG: mov x7, xzr
; CHECK-DAG: fmov d0, xzr
; CHECK-DAG: fmov d1, xzr
; CHECK-DAG: fmov d2, xzr
; CHECK-DAG: fmov d3, xzr
; CHECK-DAG: fmov d4, xzr
; CHECK-DAG: fmov d5, xzr
; CHECK-DAG: fmov d6, xzr
; CHECK-DAG: fmov d7, xzr
  tail call chericcallcc void @b_sret(i8 addrspace(200)* sret %sr, i8 addrspace(200)* %a3, i8 addrspace(200)* %a2, i64 %bar, i8 addrspace(200)* %a1, i64 %foo)
  ret void
}

; CHECK-LABEL: test_sret_i64
define chericcallcc void @test_sret_i64(i8 *%sr, i8 addrspace(200)* %a1, i64 %foo, i8 addrspace(200)* %a2, i8 addrspace(200)* %a3, i64 %bar) {
; CHECK: mov    x[[TMP:[0-9]+]], x0
; CHECK: mov    c0, c9
; CHECK: mov    x8, x11
; CHECK: mov    c9, c1
; CHECK: mov    x11, x2
; CHECK: mov    x1, x[[TMP]]
; CHECK-DAG: mov x2, xzr
; CHECK-DAG: mov x3, xzr
; CHECK-DAG: mov x4, xzr
; CHECK-DAG: mov x5, xzr
; CHECK-DAG: mov x6, xzr
; CHECK-DAG: mov x7, xzr
; CHECK-DAG: fmov d0, xzr
; CHECK-DAG: fmov d1, xzr
; CHECK-DAG: fmov d2, xzr
; CHECK-DAG: fmov d3, xzr
; CHECK-DAG: fmov d4, xzr
; CHECK-DAG: fmov d5, xzr
; CHECK-DAG: fmov d6, xzr
; CHECK-DAG: fmov d7, xzr
  tail call chericcallcc void @b_sret_i64(i8* sret %sr, i8 addrspace(200)* %a3, i8 addrspace(200)* %a2, i64 %bar, i8 addrspace(200)* %a1, i64 %foo)
  ret void
}

; CHECK-LABEL: test_i32
define chericcallcc void @test_i32(i8 addrspace(200)* %a1, i8 addrspace(200)* %a2, i32 %foo, i8 addrspace(200)* %a3, i32 %bar) {
; CHECK: mov	w8, w11
; CHECK: mov	c2, c10
; CHECK: mov	c10, c9
; CHECK: mov	c9, c0
; CHECK: mov	w11, w1
; CHECK: mov	c0, c2
; CHECK: mov	w1, w8
; CHECK-DAG: mov x2, xzr
; CHECK-DAG: mov x3, xzr
; CHECK-DAG: mov x4, xzr
; CHECK-DAG: mov x5, xzr
; CHECK-DAG: mov x6, xzr
; CHECK-DAG: mov x7, xzr
; CHECK-DAG: mov x8, xzr
; CHECK-DAG: fmov d0, xzr
; CHECK-DAG: fmov d1, xzr
; CHECK-DAG: fmov d2, xzr
; CHECK-DAG: fmov d3, xzr
; CHECK-DAG: fmov d4, xzr
; CHECK-DAG: fmov d5, xzr
; CHECK-DAG: fmov d6, xzr
; CHECK-DAG: fmov d7, xzr
  tail call chericcallcc void @b_i32(i8 addrspace(200)* %a3, i8 addrspace(200)* %a1, i32 %bar, i8 addrspace(200)* %a2, i32 %foo)
  ret void
}

declare chericcallcc void @b_i64(i8 addrspace(200)*, i8 addrspace(200)*, i64, i8 addrspace(200)*, i64)
declare chericcallcc void @b_i32(i8 addrspace(200)*, i8 addrspace(200)*, i32, i8 addrspace(200)*, i32)
declare chericcallcc void @b_sret(i8 addrspace(200)* sret, i8 addrspace(200)*, i8 addrspace(200)*, i64, i8 addrspace(200)*, i64)
declare chericcallcc void @b_sret_i64(i8* sret, i8 addrspace(200)*, i8 addrspace(200)*, i64, i8 addrspace(200)*, i64)
