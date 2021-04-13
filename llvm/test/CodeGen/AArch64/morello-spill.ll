; RUN: llc -mtriple=arm64 -mattr=+morello -o - %s | FileCheck %s

declare i32 addrspace(200)* @getCap(...)

; CHECK-LABLE: testCapSpill
define i32 @testCapSpill() {
entry:
  %call = tail call i32 addrspace(200)* bitcast (i32 addrspace(200)* (...)* @getCap to i32 addrspace(200)* ()*)()
  %call1 = tail call i32 addrspace(200)* bitcast (i32 addrspace(200)* (...)* @getCap to i32 addrspace(200)* ()*)()
  %call2 = tail call i32 addrspace(200)* bitcast (i32 addrspace(200)* (...)* @getCap to i32 addrspace(200)* ()*)()
  %call3 = tail call i32 addrspace(200)* bitcast (i32 addrspace(200)* (...)* @getCap to i32 addrspace(200)* ()*)()
  %call4 = tail call i32 addrspace(200)* bitcast (i32 addrspace(200)* (...)* @getCap to i32 addrspace(200)* ()*)()
  %call5 = tail call i32 addrspace(200)* bitcast (i32 addrspace(200)* (...)* @getCap to i32 addrspace(200)* ()*)()
  %call6 = tail call i32 addrspace(200)* bitcast (i32 addrspace(200)* (...)* @getCap to i32 addrspace(200)* ()*)()
  %call7 = tail call i32 addrspace(200)* bitcast (i32 addrspace(200)* (...)* @getCap to i32 addrspace(200)* ()*)()
  %call8 = tail call i32 addrspace(200)* bitcast (i32 addrspace(200)* (...)* @getCap to i32 addrspace(200)* ()*)()
  %call9 = tail call i32 addrspace(200)* bitcast (i32 addrspace(200)* (...)* @getCap to i32 addrspace(200)* ()*)()
  %call10 = tail call i32 addrspace(200)* bitcast (i32 addrspace(200)* (...)* @getCap to i32 addrspace(200)* ()*)()
  %call11 = tail call i32 addrspace(200)* bitcast (i32 addrspace(200)* (...)* @getCap to i32 addrspace(200)* ()*)()
  %call19 = tail call i32 addrspace(200)* bitcast (i32 addrspace(200)* (...)* @getCap to i32 addrspace(200)* ()*)()
  %0 = load i32, i32 addrspace(200)* %call, align 4
  %1 = load i32, i32 addrspace(200)* %call1, align 4
  %add = add nsw i32 %1, %0
  %2 = load i32, i32 addrspace(200)* %call2, align 4
  %add12 = add nsw i32 %add, %2
  %3 = load i32, i32 addrspace(200)* %call3, align 4
  %add13 = add nsw i32 %add12, %3
  %4 = load i32, i32 addrspace(200)* %call4, align 4
  %add14 = add nsw i32 %add13, %4
  %5 = load i32, i32 addrspace(200)* %call5, align 4
  %add15 = add nsw i32 %add14, %5
  %6 = load i32, i32 addrspace(200)* %call6, align 4
  %add16 = add nsw i32 %add15, %6
  %7 = load i32, i32 addrspace(200)* %call7, align 4
  %add17 = add nsw i32 %add16, %7
  %8 = load i32, i32 addrspace(200)* %call8, align 4
  %add18 = add nsw i32 %add17, %8
  %9 = load i32, i32 addrspace(200)* %call9, align 4
  %add19 = add nsw i32 %add18, %9
  %10 = load i32, i32 addrspace(200)* %call10, align 4
  %add20 = add nsw i32 %add19, %10
  %11 = load i32, i32 addrspace(200)* %call11, align 4
  %add21 = add nsw i32 %add20, %11
  store i32 %add21, i32 addrspace(200)* %call19, align 4
  ret i32 %add21
; CHECK:	sub	sp, sp, #208
; CHECK:	str	c0, [sp, #0]
; CHECK:	ldr	{{c[0-9]+}}, [sp, #0]
}
