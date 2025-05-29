; RUN: llc -mtriple=arm64 -mattr=+morello,+c64 -target-abi purecap -o - %s | FileCheck %s

; CHECK-LABEL: LoadCapabilityRegisterFromPtr
define ptr addrspace(200) @LoadCapabilityRegisterFromPtr(ptr addrspace(200) %foo) {
entry:
; CHECK: ldr	c0, [c0, #0]
  %0 = load ptr addrspace(200), ptr addrspace(200) %foo, align 16
  ret ptr addrspace(200) %0
}

; CHECK-LABEL: StoreCapabilityRegisterToPtr
define void @StoreCapabilityRegisterToPtr(ptr addrspace(200) %foo, ptr addrspace(200) %bar) {
entry:
; CHECK: str	c1, [c0, #0]
  store ptr addrspace(200) %bar, ptr addrspace(200) %foo, align 16
  ret void
}

; CHECK-LABEL: LoadCapabilityRegisterFromPtrWithConstantOffset
define ptr addrspace(200) @LoadCapabilityRegisterFromPtrWithConstantOffset(ptr addrspace(200) %foo) {
entry:
; CHECK: ldr	c0, [c0, #32752]
  %ptr = getelementptr inbounds ptr addrspace(200), ptr addrspace(200) %foo, i64 2047
  %0 = load ptr addrspace(200), ptr addrspace(200) %ptr, align 16
  ret ptr addrspace(200) %0
}

; CHECK-LABEL: StoreCapabilityRegisterToPtrWithConstantOffset
define void @StoreCapabilityRegisterToPtrWithConstantOffset(ptr addrspace(200) %foo, ptr addrspace(200) %bar) {
entry:
; CHECK: str	c1, [c0, #32752]
  %ptr = getelementptr inbounds ptr addrspace(200), ptr addrspace(200) %foo, i64 2047
  store ptr addrspace(200) %bar, ptr addrspace(200) %ptr, align 16
  ret void
}

; CHECK-LABEL: LoadCapabilityRegisterFromPtrWithNegConstantOffset
define ptr addrspace(200) @LoadCapabilityRegisterFromPtrWithNegConstantOffset(ptr addrspace(200) %foo) {
entry:
; CHECK: ldur	c0, [c0, #-80]
  %ptr = getelementptr inbounds ptr addrspace(200), ptr addrspace(200) %foo, i64 -5
  %0 = load ptr addrspace(200), ptr addrspace(200) %ptr, align 16
  ret ptr addrspace(200) %0
}

; CHECK-LABEL: StoreCapabilityRegisterToPtrWithNegConstantOffset
define void @StoreCapabilityRegisterToPtrWithNegConstantOffset(ptr addrspace(200) %foo, ptr addrspace(200) %bar) {
entry:
; CHECK: stur	c1, [c0, #-80]
  %ptr = getelementptr inbounds ptr addrspace(200), ptr addrspace(200) %foo, i64 -5
  store ptr addrspace(200) %bar, ptr addrspace(200) %ptr, align 16
  ret void
}

; CHECK-LABEL: LoadCapabilityRegisterFromPtrWithScaledOffset
define ptr addrspace(200) @LoadCapabilityRegisterFromPtrWithScaledOffset(ptr addrspace(200) %foo, i64 %offset) {
entry:
; CHECK: ldr	c0, [c0, x1, lsl #4]
  %ptr = getelementptr inbounds ptr addrspace(200), ptr addrspace(200) %foo, i64 %offset
  %0 = load ptr addrspace(200), ptr addrspace(200) %ptr, align 16
  ret ptr addrspace(200) %0
}

; CHECK-LABEL: LoadCapabilityRegisterFromPtrWithScaledSextOffset32
define ptr addrspace(200) @LoadCapabilityRegisterFromPtrWithScaledSextOffset32(ptr addrspace(200) %foo, i32 %offset) {
entry:
; CHECK: ldr	c0, [c0, w1, sxtw #4]
  %soffset = sext i32 %offset to i64
  %ptr = getelementptr inbounds ptr addrspace(200), ptr addrspace(200) %foo, i64 %soffset
  %0 = load ptr addrspace(200), ptr addrspace(200) %ptr, align 16
  ret ptr addrspace(200) %0
}

; CHECK-LABEL: LoadCapabilityRegisterFromPtrWithScaledZextOffset32
define ptr addrspace(200) @LoadCapabilityRegisterFromPtrWithScaledZextOffset32(ptr addrspace(200) %foo, i32 %offset) {
entry:
; CHECK: ldr	c0, [c0, w1, uxtw #4]
  %zoffset = zext i32 %offset to i64
  %ptr = getelementptr inbounds ptr addrspace(200), ptr addrspace(200) %foo, i64 %zoffset
  %0 = load ptr addrspace(200), ptr addrspace(200) %ptr, align 16
  ret ptr addrspace(200) %0
}

; CHECK-LABEL: StoreCapabilityRegisterToPtrWithScaledOffset
define void @StoreCapabilityRegisterToPtrWithScaledOffset(ptr addrspace(200) %foo, ptr addrspace(200) %bar, i64 %offset) {
entry:
; CHECK: str	c1, [c0, x2, lsl #4]
  %ptr = getelementptr inbounds ptr addrspace(200), ptr addrspace(200) %foo, i64 %offset
  store ptr addrspace(200) %bar, ptr addrspace(200) %ptr, align 16
  ret void
}

; CHECK-LABEL: StoreCapabilityRegisterToPtrWithScaledSextOffset32
define void @StoreCapabilityRegisterToPtrWithScaledSextOffset32(ptr addrspace(200) %foo, ptr addrspace(200) %bar, i32 %offset) {
entry:
; CHECK: str	c1, [c0, w2, sxtw #4]
  %soffset = sext i32 %offset to i64
  %ptr = getelementptr inbounds ptr addrspace(200), ptr addrspace(200) %foo, i64 %soffset
  store ptr addrspace(200) %bar, ptr addrspace(200) %ptr, align 16
  ret void
}

; CHECK-LABEL: StoreCapabilityRegisterToPtrWithScaledZextOffset32
define void @StoreCapabilityRegisterToPtrWithScaledZextOffset32(ptr addrspace(200) %foo, ptr addrspace(200) %bar, i32 %offset) {
entry:
; CHECK: str	c1, [c0, w2, uxtw #4]
  %zoffset = zext i32 %offset to i64
  %ptr = getelementptr inbounds ptr addrspace(200), ptr addrspace(200) %foo, i64 %zoffset
  store ptr addrspace(200) %bar, ptr addrspace(200) %ptr, align 16
  ret void
}

define ptr addrspace(200) @ldridxcap_regbase(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: ldridxcap_regbase:
; CHECK: ldr   c[[REG:[0-9]+]], [c0], #4080
; CHECK: str   c[[REG]], [c1, #0]
; CHECK: ret
  %ptr = getelementptr inbounds ptr addrspace(200), ptr addrspace(200) %src, i64 255
  %tmp = load ptr addrspace(200), ptr addrspace(200) %src, align 16
  store ptr addrspace(200) %tmp, ptr addrspace(200) %out, align 16
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200) @ldridxcap_regbase_not(ptr addrspace(200) %src, ptr addrspace(200) %out) {
; CHECK-LABEL: ldridxcap_regbase_not:
; CHECK-NOT: ldr   c{{.*}}, [c0],
; CHECK: str   c{{.*}}, [c1, #0]
; CHECK: ret
  %ptr = getelementptr inbounds ptr addrspace(200), ptr addrspace(200) %src, i64 256
  %tmp = load ptr addrspace(200), ptr addrspace(200) %src, align 16
  store ptr addrspace(200) %tmp, ptr addrspace(200) %out, align 16
  ret ptr addrspace(200) %ptr
}

define ptr addrspace(200)
@store_cap_reg(ptr addrspace(200) %tmp, i64 %index, ptr addrspace(200) %spacing) nounwind noinline ssp {
; CHECK-LABEL: store_cap_reg:
; CHECK: str c{{[0-9+]}}, [c{{[0-9+]}}], #4080
; CHECK: ret
  %incdec.ptr = getelementptr inbounds ptr addrspace(200), ptr addrspace(200) %tmp, i64 255
  store ptr addrspace(200) %spacing, ptr addrspace(200) %tmp, align 16
  ret ptr addrspace(200) %incdec.ptr
}

define ptr addrspace(200)
@store_cap_reg_not(ptr addrspace(200) %tmp, i64 %index, ptr addrspace(200) %spacing) nounwind noinline ssp {
; CHECK-LABEL: store_cap_reg_not:
; CHECK-NOT: str c{{[0-9+]}}, [c{{[0-9+]}}],
  %incdec.ptr = getelementptr inbounds ptr addrspace(200), ptr addrspace(200) %tmp, i64 256
  store ptr addrspace(200) %spacing, ptr addrspace(200) %tmp, align 16
  ret ptr addrspace(200) %incdec.ptr
}

; CHECK-LABEL: StoreCapabilityRegOffsetImm
define void @StoreCapabilityRegOffsetImm(ptr addrspace(200) %foo, ptr addrspace(200) %bar) {
entry:
; CHECK: mov    w[[OFFSET:[0-9]+]]
; CHECK: str	c1, [c0, x[[OFFSET]]]
  %ptr = getelementptr inbounds i8, ptr addrspace(200) %foo, i64 8193
  store ptr addrspace(200) %bar, ptr addrspace(200) %ptr
  ret void
}
