; RUN: llc -mtriple=arm64 -mattr=+morello -o - %s | FileCheck %s

; CHECK-LABEL: LoadCapabilityRegisterFromPtr
define i8 addrspace(200)* @LoadCapabilityRegisterFromPtr(i8 addrspace(200)** %foo) {
entry:
; CHECK: ldr	c0, [x0, #0]
  %0 = load i8 addrspace(200)*, i8 addrspace(200)** %foo, align 16
  ret i8 addrspace(200)* %0
}

; CHECK-LABEL: StoreCapabilityRegisterToPtr
define void @StoreCapabilityRegisterToPtr(i8 addrspace(200)** %foo, i8 addrspace(200)* %bar) {
entry:
; CHECK: str	c1, [x0, #0]
  store i8 addrspace(200)* %bar, i8 addrspace(200)** %foo, align 16
  ret void
}

; CHECK-LABEL: LoadCapabilityRegisterFromPtrWithConstantOffset
define i8 addrspace(200)* @LoadCapabilityRegisterFromPtrWithConstantOffset(i8 addrspace(200)** %foo) {
entry:
; CHECK: ldr	c0, [x0, #32752]
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)** %foo, i64 2047
  %0 = load i8 addrspace(200)*, i8 addrspace(200)** %ptr, align 16
  ret i8 addrspace(200)* %0
}

; CHECK-LABEL: StoreCapabilityRegisterToPtrWithConstantOffset
define void @StoreCapabilityRegisterToPtrWithConstantOffset(i8 addrspace(200)** %foo, i8 addrspace(200)* %bar) {
entry:
; CHECK: str	c1, [x0, #32752]
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)** %foo, i64 2047
  store i8 addrspace(200)* %bar, i8 addrspace(200)** %ptr, align 16
  ret void
}

; CHECK-LABEL: LoadCapabilityRegisterFromPtrWithNegConstantOffset
define i8 addrspace(200)* @LoadCapabilityRegisterFromPtrWithNegConstantOffset(i8 addrspace(200)** %foo) {
entry:
; CHECK: ldur	c0, [x0, #-80]
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)** %foo, i64 -5
  %0 = load i8 addrspace(200)*, i8 addrspace(200)** %ptr, align 16
  ret i8 addrspace(200)* %0
}

; CHECK-LABEL: StoreCapabilityRegisterToPtrWithNegConstantOffset
define void @StoreCapabilityRegisterToPtrWithNegConstantOffset(i8 addrspace(200)** %foo, i8 addrspace(200)* %bar) {
entry:
; CHECK: stur	c1, [x0, #-80]
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)** %foo, i64 -5
  store i8 addrspace(200)* %bar, i8 addrspace(200)** %ptr, align 16
  ret void
}

; CHECK-LABEL: LoadCapabilityRegisterFromPtrWithScaledOffset
define i8 addrspace(200)* @LoadCapabilityRegisterFromPtrWithScaledOffset(i8 addrspace(200)** %foo, i64 %offset) {
entry:
; CHECK: ldr	c0, [x0, x1, lsl #4]
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)** %foo, i64 %offset
  %0 = load i8 addrspace(200)*, i8 addrspace(200)** %ptr, align 16
  ret i8 addrspace(200)* %0
}

; CHECK-LABEL: LoadCapabilityRegisterFromPtrWithScaledSextOffset32
define i8 addrspace(200)* @LoadCapabilityRegisterFromPtrWithScaledSextOffset32(i8 addrspace(200)** %foo, i32 %offset) {
entry:
; CHECK: ldr	c0, [x0, w1, sxtw #4]
  %soffset = sext i32 %offset to i64
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)** %foo, i64 %soffset
  %0 = load i8 addrspace(200)*, i8 addrspace(200)** %ptr, align 16
  ret i8 addrspace(200)* %0
}

; CHECK-LABEL: LoadCapabilityRegisterFromPtrWithScaledZextOffset32
define i8 addrspace(200)* @LoadCapabilityRegisterFromPtrWithScaledZextOffset32(i8 addrspace(200)** %foo, i32 %offset) {
entry:
; CHECK: ldr	c0, [x0, w1, uxtw #4]
  %zoffset = zext i32 %offset to i64
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)** %foo, i64 %zoffset
  %0 = load i8 addrspace(200)*, i8 addrspace(200)** %ptr, align 16
  ret i8 addrspace(200)* %0
}

; CHECK-LABEL: StoreCapabilityRegisterToPtrWithScaledOffset
define void @StoreCapabilityRegisterToPtrWithScaledOffset(i8 addrspace(200)** %foo, i8 addrspace(200)* %bar, i64 %offset) {
entry:
; CHECK: str	c1, [x0, x2, lsl #4]
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)** %foo, i64 %offset
  store i8 addrspace(200)* %bar, i8 addrspace(200)** %ptr, align 16
  ret void
}

; CHECK-LABEL: StoreCapabilityRegisterToPtrWithScaledSextOffset32
define void @StoreCapabilityRegisterToPtrWithScaledSextOffset32(i8 addrspace(200)** %foo, i8 addrspace(200)* %bar, i32 %offset) {
entry:
; CHECK: str	c1, [x0, w2, sxtw #4]
  %soffset = sext i32 %offset to i64
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)** %foo, i64 %soffset
  store i8 addrspace(200)* %bar, i8 addrspace(200)** %ptr, align 16
  ret void
}

; CHECK-LABEL: StoreCapabilityRegisterToPtrWithScaledZextOffset32
define void @StoreCapabilityRegisterToPtrWithScaledZextOffset32(i8 addrspace(200)** %foo, i8 addrspace(200)* %bar, i32 %offset) {
entry:
; CHECK: str	c1, [x0, w2, uxtw #4]
  %zoffset = zext i32 %offset to i64
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)** %foo, i64 %zoffset
  store i8 addrspace(200)* %bar, i8 addrspace(200)** %ptr, align 16
  ret void
}

define i8 addrspace(200)** @ldridxcap_regbase(i8 addrspace(200)** %src, i8 addrspace(200)** %out) {
; CHECK-LABEL: ldridxcap_regbase:
; CHECK: ldr   c[[REG:[0-9]+]], [x0], #4080
; CHECK: str   c[[REG]], [x1, #0]
; CHECK: ret
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)** %src, i64 255
  %tmp = load i8 addrspace(200)*, i8 addrspace(200)** %src, align 16
  store i8 addrspace(200)* %tmp, i8 addrspace(200)** %out, align 16
  ret i8 addrspace(200)** %ptr
}

define i8 addrspace(200)** @ldridxcap_regbase_not(i8 addrspace(200)** %src, i8 addrspace(200)** %out) {
; CHECK-LABEL: ldridxcap_regbase_not:
; CHECK-NOT: ldr   c[[REG:[0-9]+]], [x0],
; CHECK: str   c[[REG]], [x1, #0]
; CHECK: ret
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)** %src, i64 256
  %tmp = load i8 addrspace(200)*, i8 addrspace(200)** %src, align 16
  store i8 addrspace(200)* %tmp, i8 addrspace(200)** %out, align 16
  ret i8 addrspace(200)** %ptr
}

define i64 addrspace(200)**
@store_cap_reg(i64 addrspace(200)** %tmp, i64 %index, i64 addrspace(200)* %spacing) nounwind noinline ssp {
; CHECK-LABEL: store_cap_reg:
; CHECK: str c{{[0-9+]}}, [x{{[0-9+]}}], #4080
; CHECK: ret
  %incdec.ptr = getelementptr inbounds i64 addrspace(200)*, i64 addrspace(200)** %tmp, i64 255
  store i64 addrspace(200)* %spacing, i64 addrspace(200)** %tmp, align 16
  ret i64 addrspace(200)** %incdec.ptr
}

define i64 addrspace(200)**
@store_cap_reg_not(i64 addrspace(200)** %tmp, i64 %index, i64 addrspace(200)* %spacing) nounwind noinline ssp {
; CHECK-LABEL: store_cap_reg_not:
; CHECK-NOT: str c{{[0-9+]}}, [x{{[0-9+]}}],
  %incdec.ptr = getelementptr inbounds i64 addrspace(200)*, i64 addrspace(200)** %tmp, i64 256
  store i64 addrspace(200)* %spacing, i64 addrspace(200)** %tmp, align 16
  ret i64 addrspace(200)** %incdec.ptr
}
