; RUN: llc -march=aarch64 -mattr=+morello,+c64 -target-abi purecap -o - %s | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none-unknown-elf"


;----------------
; Generated from:
;
; struct s1 { uint64_t x,y; };
;
; struct s2 { struct s1 a,b; };
;
; struct s2 foo(uint64_t x, uint64_t y) {
;   struct s2 ret;
;
;   ret.a.x = x+1;
;   ret.a.y = y+1;
;
;   ret.b.x = x-1;
;   ret.b.y = y-1;
;
;   return ret;
; }
;
; Check that non-aggregate return types
; are indirectly passed through C8.
;
; CHECK-LABEL:  @foo
;
; CHECK-DAG:  add  [[ADDX:x[0-9]+]],  x0,  #1
; CHECK-DAG:  add  [[ADDY:x[0-9]+]],  x1,  #1
; CHECK-DAG:  sub  [[SUBX:x[0-9]+]],  x0,  #1
; CHECK-DAG:  sub  [[SUBY:x[0-9]+]],  x1,  #1
; CHECK-DAG:  stp  [[ADDX]],  [[ADDY]],  [c8]
; CHECK-DAG:  stp  [[SUBX]],  [[SUBY]],  [c8, #16]
; CHECK-DAG:  ret  c30

%struct.s2 = type { %struct.s1, %struct.s1 }
%struct.s1 = type { i64, i64 }

define void @foo(ptr addrspace(200) sret(%struct.s2) %agg.result, i64 %x, i64 %y) addrspace(200) {
entry:
  %add = add i64 %x, 1
  store i64 %add, ptr addrspace(200) %agg.result, align 8
  %add2 = add i64 %y, 1
  %y4 = getelementptr inbounds %struct.s2, ptr addrspace(200) %agg.result, i64 0, i32 0, i32 1
  store i64 %add2, ptr addrspace(200) %y4, align 8
  %sub = add i64 %x, -1
  %x5 = getelementptr inbounds %struct.s2, ptr addrspace(200) %agg.result, i64 0, i32 1, i32 0
  store i64 %sub, ptr addrspace(200) %x5, align 8
  %sub6 = add i64 %y, -1
  %y8 = getelementptr inbounds %struct.s2, ptr addrspace(200) %agg.result, i64 0, i32 1, i32 1
  store i64 %sub6, ptr addrspace(200) %y8, align 8
  ret void
}
