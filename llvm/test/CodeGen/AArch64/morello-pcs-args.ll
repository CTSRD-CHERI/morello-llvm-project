; RUN: llc -march=aarch64 -mattr=+morello,+c64 -target-abi purecap -o - %s | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none-unknown-elf"


;----------------
; Generated from:
;
; uint64_t foo(uint64_t a0, uint64_t a1, uint64_t a2, uint64_t a3,
;              uint64_t a4, uint64_t a5, uint64_t a6, uint64_t a7) {
;   return a1 * a2 * a3 * a4 * a5 * a6 * a7 / a0;
; }
;
; Check that i64 args are passed on X0-X7
; and i64 return value is stored in X0.
;
; CHECK-LABEL: @foo
;
; CHECK-DAG:  mul  [[MUL:x[0-9]+]],    x2,  x1
; CHECK-DAG:  mul  [[MUL]],  [[MUL]],  x3
; CHECK-DAG:  mul  [[MUL]],  [[MUL]],  x4
; CHECK-DAG:  mul  [[MUL]],  [[MUL]],  x5
; CHECK-DAG:  mul  [[MUL]],  [[MUL]],  x6
; CHECK-DAG:  mul  [[MUL]],  [[MUL]],  x7
; CHECK-DAG:  udiv      x0,  [[MUL]],  x0
; CHECK-DAG:  ret  c30

define i64 @foo(i64 %a0, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, i64 %a6, i64 %a7) addrspace(200) {
entry:
  %mul = mul i64 %a2, %a1
  %mul1 = mul i64 %mul, %a3
  %mul2 = mul i64 %mul1, %a4
  %mul3 = mul i64 %mul2, %a5
  %mul4 = mul i64 %mul3, %a6
  %mul5 = mul i64 %mul4, %a7
  %div = udiv i64 %mul5, %a0
  ret i64 %div
}


;----------------
; Generated from:
;
; __uint128_t quad_args(__uint128_t a0, __uint128_t a1, __uint128_t a2, __uint128_t a3) {
;   return a0 - a1 - a2 - a3;
; }
;
; Check that i128 args are passed on X0-X7
; and i128 return value is stored in X0,X1.
;
; CHECK-LABEL: @quad_args
;
; CHECK-DAG: subs  [[SUB_HI:x[0-9]+]],  x0,  x2
; CHECK-DAG: sbc   [[SUB_LO:x[0-9]+]],  x1,  x3
; CHECK-DAG: subs  [[SUB_HI]],  [[SUB_HI]],  x4
; CHECK-DAG: sbc   [[SUB_LO]],  [[SUB_LO]],  x5
; CHECK-DAG: subs          x0,  [[SUB_HI]],  x6
; CHECK-DAG: sbc           x1,  [[SUB_LO]],  x7
; CHECK-DAG: ret   c30

define i128 @quad_args(i128 %a0, i128 %a1, i128 %a2, i128 %a3) addrspace(200) {
entry:
  %sub = sub i128 %a0, %a1
  %sub1 = sub i128 %sub, %a2
  %sub2 = sub i128 %sub1, %a3
  ret i128 %sub2
}


;----------------
; Generated from:
;
; void bar(char *a0, char *a1, char *a2, char *a3,
;          char *a4, char *a5, char *a6, char *a7,
;          int n) {
;
;   a0[n] = a1[n+1] + a2[n+2] + a3[n+3] + a4[n+4] +
;           a5[n+5] + a6[n+6] + a7[n+7];
; }
;
; Check that pointer args are passed on C0-C7
; and additional args are passed on the stack.
;
; CHECK-LABEL: @bar
;
; CHECK-DAG:  ldrsw  [[OFFSET:x[0-9]+]],  [csp]
;
; CHECK-DAG:  add  [[OFFSET1:x[0-9]+]],  [[OFFSET]],  #1
; CHECK-DAG:  add  [[OFFSET2:x[0-9]+]],  [[OFFSET]],  #2
; CHECK-DAG:  add  [[OFFSET3:x[0-9]+]],  [[OFFSET]],  #3
; CHECK-DAG:  add  [[OFFSET4:x[0-9]+]],  [[OFFSET]],  #4
; CHECK-DAG:  add  [[OFFSET5:x[0-9]+]],  [[OFFSET]],  #5
; CHECK-DAG:  add  [[OFFSET6:x[0-9]+]],  [[OFFSET]],  #6
; CHECK-DAG:  add  [[OFFSET7:x[0-9]+]],  [[OFFSET]],  #7
;
; CHECK-DAG:  ldrb  [[LD1:w[0-9]+]],  [c1,  [[OFFSET1]]{{]}}
; CHECK-DAG:  ldrb  [[LD2:w[0-9]+]],  [c2,  [[OFFSET2]]{{]}}
; CHECK-DAG:  ldrb  [[LD3:w[0-9]+]],  [c3,  [[OFFSET3]]{{]}}
; CHECK-DAG:  ldrb  [[LD4:w[0-9]+]],  [c4,  [[OFFSET4]]{{]}}
; CHECK-DAG:  ldrb  [[LD5:w[0-9]+]],  [c5,  [[OFFSET5]]{{]}}
; CHECK-DAG:  ldrb  [[LD6:w[0-9]+]],  [c6,  [[OFFSET6]]{{]}}
; CHECK-DAG:  ldrb  [[LD7:w[0-9]+]],  [c7,  [[OFFSET7]]{{]}}
;
; CHECK-DAG:  add  [[ADD:w[0-9]+]],  [[LD2]],  [[LD1]]
; CHECK-DAG:  add  [[ADD]],          [[ADD]],  [[LD3]]
; CHECK-DAG:  add  [[ADD]],          [[ADD]],  [[LD4]]
; CHECK-DAG:  add  [[ADD]],          [[ADD]],  [[LD5]]
; CHECK-DAG:  add  [[ADD]],          [[ADD]],  [[LD6]]
; CHECK-DAG:  add  [[ADD]],          [[ADD]],  [[LD7]]
;
; CHECK-DAG:  strb  [[ADD]],  [c0,  [[OFFSET]]{{]}}

define void @bar(i8 addrspace(200)* %a0, i8 addrspace(200)* %a1, i8 addrspace(200)* %a2, i8 addrspace(200)* %a3, i8 addrspace(200)* %a4, i8 addrspace(200)* %a5, i8 addrspace(200)* %a6, i8 addrspace(200)* %a7, i32 %n) addrspace(200) {
entry:
  %add = add nsw i32 %n, 1
  %idxprom = sext i32 %add to i64
  %arrayidx = getelementptr inbounds i8, i8 addrspace(200)* %a1, i64 %idxprom
  %0 = load i8, i8 addrspace(200)* %arrayidx, align 1
  %add1 = add nsw i32 %n, 2
  %idxprom2 = sext i32 %add1 to i64
  %arrayidx3 = getelementptr inbounds i8, i8 addrspace(200)* %a2, i64 %idxprom2
  %1 = load i8, i8 addrspace(200)* %arrayidx3, align 1
  %add5 = add i8 %1, %0
  %add6 = add nsw i32 %n, 3
  %idxprom7 = sext i32 %add6 to i64
  %arrayidx8 = getelementptr inbounds i8, i8 addrspace(200)* %a3, i64 %idxprom7
  %2 = load i8, i8 addrspace(200)* %arrayidx8, align 1
  %add10 = add i8 %add5, %2
  %add11 = add nsw i32 %n, 4
  %idxprom12 = sext i32 %add11 to i64
  %arrayidx13 = getelementptr inbounds i8, i8 addrspace(200)* %a4, i64 %idxprom12
  %3 = load i8, i8 addrspace(200)* %arrayidx13, align 1
  %add15 = add i8 %add10, %3
  %add16 = add nsw i32 %n, 5
  %idxprom17 = sext i32 %add16 to i64
  %arrayidx18 = getelementptr inbounds i8, i8 addrspace(200)* %a5, i64 %idxprom17
  %4 = load i8, i8 addrspace(200)* %arrayidx18, align 1
  %add20 = add i8 %add15, %4
  %add21 = add nsw i32 %n, 6
  %idxprom22 = sext i32 %add21 to i64
  %arrayidx23 = getelementptr inbounds i8, i8 addrspace(200)* %a6, i64 %idxprom22
  %5 = load i8, i8 addrspace(200)* %arrayidx23, align 1
  %add25 = add i8 %add20, %5
  %add26 = add nsw i32 %n, 7
  %idxprom27 = sext i32 %add26 to i64
  %arrayidx28 = getelementptr inbounds i8, i8 addrspace(200)* %a7, i64 %idxprom27
  %6 = load i8, i8 addrspace(200)* %arrayidx28, align 1
  %add30 = add i8 %add25, %6
  %idxprom32 = sext i32 %n to i64
  %arrayidx33 = getelementptr inbounds i8, i8 addrspace(200)* %a0, i64 %idxprom32
  store i8 %add30, i8 addrspace(200)* %arrayidx33, align 1
  ret void
}
