; RUN: llc -mtriple=arm64 -mattr=+morello,+c64 -target-abi purecap -o - %s | FileCheck %s

; CHECK-LABEL: testIntToPtr64:
define i32 addrspace(200)* @testIntToPtr64(i64 %in) addrspace(200) {
entry:
; CHECK: mov x[[ZERO:[0-9]+]], #0
; CHECK: scvalue c0, c[[ZERO]], x0
  %out = inttoptr i64 %in to i32 addrspace(200)*
  ret i32 addrspace(200)* %out
}

; CHECK-LABEL: testIntToPtr32:
define i32 addrspace(200)* @testIntToPtr32(i32 %in) addrspace(200) {
entry:
; CHECK: mov x[[ZERO:[0-9]+]], #0
; CHECK: scvalue c0, c[[ZERO]], x0
  %out = inttoptr i32 %in to i32 addrspace(200)*
  ret i32 addrspace(200)* %out
}

; CHECK-LABEL: testIntToPtrConst64:
define i32 addrspace(200)* @testIntToPtrConst64() addrspace(200) {
entry:
; CHECK-DAG: mov x[[ZERO:[0-9]+]], #0
; CHECK-DAG: mov w[[CONST:[0-9]+]], #64
; CHECK-DAG: scvalue c0, c[[ZERO]], x[[CONST]]
  %out = inttoptr i64 64 to i32 addrspace(200)*
  ret i32 addrspace(200)* %out
}

; CHECK-LABEL: testIntToPtrConst32:
define i32 addrspace(200)* @testIntToPtrConst32() addrspace(200) {
entry:
; CHECK-DAG: mov x[[ZERO:[0-9]+]], #0
; CHECK-DAG: mov w[[CONST:[0-9]+]], #64
; CHECK-DAG: scvalue c0, c[[ZERO]], x[[CONST]]
  %out = inttoptr i32 64 to i32 addrspace(200)*
  ret i32 addrspace(200)* %out
}

; CHECK-LABEL: testIntToPtrConst16:
define i32 addrspace(200)* @testIntToPtrConst16() addrspace(200) {
entry:
; CHECK-DAG: mov x[[ZERO:[0-9]+]], #0
; CHECK-DAG: mov w[[CONST:[0-9]+]], #64
; CHECK-DAG: scvalue c0, c[[ZERO]], x[[CONST]]
  %out = inttoptr i16 64 to i32 addrspace(200)*
  ret i32 addrspace(200)* %out
}
