; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------
; Test alloca insertion point, no alloca in entry BB.

define i8 addrspace(200)* @case.1.f(i8 addrspace(200)* %cap) {
; CHECK-LABEL: entry:
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  br label %exit
entry:
  br label %exit
exit:
  %cap.addr = alloca i8 addrspace(200)*, align 16
  store i8 addrspace(200)* %cap, i8 addrspace(200)** %cap.addr, align 16
  %0 = load i8 addrspace(200)*, i8 addrspace(200)** %cap.addr, align 16
  ret i8 addrspace(200)* %0
}

; ------------------------------------------------------------------------------
; Test alloca insertion point, alloca in entry BB.

define i8 addrspace(200)* @case.2.f(i8 addrspace(200)* %cap) {
; CHECK-LABEL: entry:
; CHECK-NEXT:  %dummy_1 = alloca i8, align 1
; CHECK-NEXT:  %dummy_2 = alloca i8, align 1
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  br label %exit
entry:
  %dummy_1 = alloca i8, align 1
  %dummy_2 = alloca i8, align 1
  br label %exit
exit:
  %cap.addr = alloca i8 addrspace(200)*, align 16
  store i8 addrspace(200)* %cap, i8 addrspace(200)** %cap.addr, align 16
  %0 = load i8 addrspace(200)*, i8 addrspace(200)** %cap.addr, align 16
  ret i8 addrspace(200)* %0
}

; ------------------------------------------------------------------------------
; Test alloca insertion point, alloca in entry BB with gap.
; Not sure if this is a real case though.

define i8 addrspace(200)* @case.3.f(i8 addrspace(200)* %cap) {
; CHECK-LABEL: entry:
; CHECK-NEXT:  %dummy_1 = alloca i8, align 1
; CHECK-NEXT:  %dummy_2 = add i8 0, 4
; CHECK-NEXT:  %dummy_3 = alloca i8, align 1
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  br label %exit
entry:
  %dummy_1 = alloca i8, align 1
  %dummy_2 = add i8 0, 4
  %dummy_3 = alloca i8, align 1
  br label %exit
exit:
  %cap.addr = alloca i8 addrspace(200)*, align 16
  store i8 addrspace(200)* %cap, i8 addrspace(200)** %cap.addr, align 16
  %0 = load i8 addrspace(200)*, i8 addrspace(200)** %cap.addr, align 16
  ret i8 addrspace(200)* %0
}

; ------------------------------------------------------------------------------
