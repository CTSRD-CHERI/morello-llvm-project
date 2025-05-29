; RUN: llc -mtriple=arm64 -mattr=+morello,+c64 -target-abi purecap -o - %s | FileCheck %s

; CHECK-LABEL: testIntToPtr64:
define ptr addrspace(200) @testIntToPtr64(i64 %in) addrspace(200) {
entry:
; CHECK: gcvalue x0, c0
  %out = inttoptr i64 %in to ptr addrspace(200)
  ret ptr addrspace(200) %out
}

; CHECK-LABEL: testIntToPtr32:
define ptr addrspace(200) @testIntToPtr32(i32 %in) addrspace(200) {
entry:
; CHECK: gcvalue x0, c0
  %out = inttoptr i32 %in to ptr addrspace(200)
  ret ptr addrspace(200) %out
}

; CHECK-LABEL: testIntToPtrConst64:
define ptr addrspace(200) @testIntToPtrConst64() addrspace(200) {
entry:
; CHECK: mov x0, #64
  %out = inttoptr i64 64 to ptr addrspace(200)
  ret ptr addrspace(200) %out
}

; CHECK-LABEL: testIntToPtrConst32:
define ptr addrspace(200) @testIntToPtrConst32() addrspace(200) {
entry:
; CHECK: mov x0, #64
  %out = inttoptr i32 64 to ptr addrspace(200)
  ret ptr addrspace(200) %out
}

; CHECK-LABEL: testIntToPtrConst16:
define ptr addrspace(200) @testIntToPtrConst16() addrspace(200) {
entry:
; CHECK-DAG: mov x[[CONST:[0-9]+]], #64
  %out = inttoptr i16 64 to ptr addrspace(200)
  ret ptr addrspace(200) %out
}
