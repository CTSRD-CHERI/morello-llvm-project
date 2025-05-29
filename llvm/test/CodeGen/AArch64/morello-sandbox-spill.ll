; RUN: llc -march=arm64 -mattr=+c64,+morello,+use-16-cap-regs -target-abi purecap -o - %s | FileCheck %s
target datalayout = "e-m:e-i64:64-i128:128-n32:64-S128-pf200:128:128:128:64-A200-P200-G200"
target triple = "aarch64-none--elf"

declare ptr addrspace(200) @getCap(...) addrspace(200)

; CHECK-LABEL: testCapSpill
define i32 @testCapSpill() addrspace(200) {
entry:
  %call = tail call ptr addrspace(200) bitcast (ptr addrspace(200) (...) addrspace(200)* @getCap to ptr addrspace(200) () addrspace(200)*)()
  %call1 = tail call ptr addrspace(200) bitcast (ptr addrspace(200) (...) addrspace(200)* @getCap to ptr addrspace(200) () addrspace(200)*)()
  %call2 = tail call ptr addrspace(200) bitcast (ptr addrspace(200) (...) addrspace(200)* @getCap to ptr addrspace(200) () addrspace(200)*)()
  %call3 = tail call ptr addrspace(200) bitcast (ptr addrspace(200) (...) addrspace(200)* @getCap to ptr addrspace(200) () addrspace(200)*)()
  %call4 = tail call ptr addrspace(200) bitcast (ptr addrspace(200) (...) addrspace(200)* @getCap to ptr addrspace(200) () addrspace(200)*)()
  %call5 = tail call ptr addrspace(200) bitcast (ptr addrspace(200) (...) addrspace(200)* @getCap to ptr addrspace(200) () addrspace(200)*)()
  %call6 = tail call ptr addrspace(200) bitcast (ptr addrspace(200) (...) addrspace(200)* @getCap to ptr addrspace(200) () addrspace(200)*)()
  %call7 = tail call ptr addrspace(200) bitcast (ptr addrspace(200) (...) addrspace(200)* @getCap to ptr addrspace(200) () addrspace(200)*)()
  %call8 = tail call ptr addrspace(200) bitcast (ptr addrspace(200) (...) addrspace(200)* @getCap to ptr addrspace(200) () addrspace(200)*)()
  %call9 = tail call ptr addrspace(200) bitcast (ptr addrspace(200) (...) addrspace(200)* @getCap to ptr addrspace(200) () addrspace(200)*)()
  %call10 = tail call ptr addrspace(200) bitcast (ptr addrspace(200) (...) addrspace(200)* @getCap to ptr addrspace(200) () addrspace(200)*)()
  %call11 = tail call ptr addrspace(200) bitcast (ptr addrspace(200) (...) addrspace(200)* @getCap to ptr addrspace(200) () addrspace(200)*)()
  %call19 = tail call ptr addrspace(200) bitcast (ptr addrspace(200) (...) addrspace(200)* @getCap to ptr addrspace(200) () addrspace(200)*)()
  %0 = load i32, ptr addrspace(200) %call, align 4
  %1 = load i32, ptr addrspace(200) %call1, align 4
  %add = add nsw i32 %1, %0
  %2 = load i32, ptr addrspace(200) %call2, align 4
  %add12 = add nsw i32 %add, %2
  %3 = load i32, ptr addrspace(200) %call3, align 4
  %add13 = add nsw i32 %add12, %3
  %4 = load i32, ptr addrspace(200) %call4, align 4
  %add14 = add nsw i32 %add13, %4
  %5 = load i32, ptr addrspace(200) %call5, align 4
  %add15 = add nsw i32 %add14, %5
  %6 = load i32, ptr addrspace(200) %call6, align 4
  %add16 = add nsw i32 %add15, %6
  %7 = load i32, ptr addrspace(200) %call7, align 4
  %add17 = add nsw i32 %add16, %7
  %8 = load i32, ptr addrspace(200) %call8, align 4
  %add18 = add nsw i32 %add17, %8
  %9 = load i32, ptr addrspace(200) %call9, align 4
  %add19 = add nsw i32 %add18, %9
  %10 = load i32, ptr addrspace(200) %call10, align 4
  %add20 = add nsw i32 %add19, %10
  %11 = load i32, ptr addrspace(200) %call11, align 4
  %add21 = add nsw i32 %add20, %11

  store i32 %add21, ptr addrspace(200) %call19, align 4
  ret i32 %add21
; CHECK:	sub	csp, csp, #208
; CHECK:	str	c{{[0-9]+}}, [csp, #0]
; CHECK:	ldr	c{{[0-9]+}}, [csp, #0]
}
