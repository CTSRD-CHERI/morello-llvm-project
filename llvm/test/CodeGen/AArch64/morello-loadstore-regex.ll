; RUN: llc -mtriple=arm64 -mattr=+morello -o - %s | FileCheck %s

; CHECK-LABEL: LoadCapabilityRegisterFromPtrWithScaledOffset
define i8 addrspace(200)* @LoadCapabilityRegisterFromPtrWithScaledOffset(i8 addrspace(200)* addrspace(200)* %foo, i64 %offset) {
entry:
; CHECK: ldr c0, [c0, x1, lsl #4]
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %foo, i64 %offset
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %ptr, align 16
  ret i8 addrspace(200)* %0
}

; CHECK-LABEL: LoadCapabilityRegisterFromPtrWith32ScaledOffset
define i8 addrspace(200)* @LoadCapabilityRegisterFromPtrWith32ScaledOffset(i8 addrspace(200)* addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldr c0, [c0, w1, sxtw #4]
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %foo, i32 %offset
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %ptr, align 16
  ret i8 addrspace(200)* %0
}

; CHECK-LABEL: LoadCapabilityRegisterFromPtrWith32ZextScaledOffset
define i8 addrspace(200)* @LoadCapabilityRegisterFromPtrWith32ZextScaledOffset(i8 addrspace(200)* addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldr c0, [c0, w1, uxtw #4]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %foo, i64 %new
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %ptr, align 16
  ret i8 addrspace(200)* %0
}

; CHECK-LABEL: LoadCapabilityRegisterFromPtrWithUnscaledOffset
define i8 addrspace(200)* @LoadCapabilityRegisterFromPtrWithUnscaledOffset(i8 addrspace(200)* %foo, i64 %offset) {
entry:
; CHECK: ldr c0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to i8 addrspace(200)* addrspace(200) *
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %castptr, align 16
  ret i8 addrspace(200)* %0
}

; CHECK-LABEL: LoadCapabilityRegisterFromPtrWith32UnscaledOffset
define i8 addrspace(200)* @LoadCapabilityRegisterFromPtrWith32UnscaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldr c0, [c0, w1, sxtw]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i32 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to i8 addrspace(200)* addrspace(200) *
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %castptr, align 16
  ret i8 addrspace(200)* %0
}

; CHECK-LABEL: LoadCapabilityRegisterFromPtrWith32ZextUnscaledOffset
define i8 addrspace(200)* @LoadCapabilityRegisterFromPtrWith32ZextUnscaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldr c0, [c0, w1, uxtw]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %new
  %castptr = bitcast i8 addrspace(200)* %ptr to i8 addrspace(200)* addrspace(200) *
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %castptr, align 16
  ret i8 addrspace(200)* %0
}

; CHECK-LABEL: LoadCapabilityRegisterFromPtrWithImm
define i8 addrspace(200)* @LoadCapabilityRegisterFromPtrWithImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: ldr c0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 10000
  %castptr = bitcast i8 addrspace(200)* %ptr to i8 addrspace(200)* addrspace(200) *
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %castptr, align 16
  ret i8 addrspace(200)* %0
}

; CHECK-LABEL: LoadCapabilityRegisterFromPtrWithNegImm
define i8 addrspace(200)* @LoadCapabilityRegisterFromPtrWithNegImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: ldr c0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 -10000
  %castptr = bitcast i8 addrspace(200)* %ptr to i8 addrspace(200)* addrspace(200) *
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %castptr, align 16
  ret i8 addrspace(200)* %0
}

; CHECK-LABEL: StoreCapabilityRegisterFromPtrWithScaledOffset
define void @StoreCapabilityRegisterFromPtrWithScaledOffset(i8 addrspace(200)* addrspace(200)* %foo, i64 %offset, i8 addrspace(200) * %toStore) {
entry:
; CHECK: str c2, [c0, x1, lsl #4]
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %foo, i64 %offset
  store i8 addrspace(200)* %toStore, i8 addrspace(200)* addrspace(200)* %ptr, align 16
  ret void
}

; CHECK-LABEL: StoreCapabilityRegisterFromPtrWith32ScaledOffset
define void @StoreCapabilityRegisterFromPtrWith32ScaledOffset(i8 addrspace(200)* addrspace(200)* %foo, i32 %offset, i8 addrspace(200) * %toStore) {
entry:
; CHECK: str c2, [c0, w1, sxtw #4]
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %foo, i32 %offset
  store i8 addrspace(200)* %toStore, i8 addrspace(200)* addrspace(200)* %ptr, align 16
  ret void
}
; CHECK-LABEL: StoreCapabilityRegisterFromPtrWith32ZextScaledOffset
define void @StoreCapabilityRegisterFromPtrWith32ZextScaledOffset(i8 addrspace(200)* addrspace(200)* %foo, i32 %offset, i8 addrspace(200) * %toStore) {
entry:
; CHECK: str c2, [c0, w1, uxtw #4]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %foo, i64 %new
  store i8 addrspace(200)* %toStore, i8 addrspace(200)* addrspace(200)* %ptr, align 16
  ret void
}

; CHECK-LABEL: StoreCapabilityRegisterFromPtrWithUnscaledOffset
define void @StoreCapabilityRegisterFromPtrWithUnscaledOffset(i8 addrspace(200)* %foo, i64 %offset, i8 addrspace(200) * %toStore) {
entry:
; CHECK: str c2, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to i8 addrspace(200)* addrspace(200) *
  store i8 addrspace(200) * %toStore, i8 addrspace(200)* addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: StoreCapabilityRegisterFromPtrWith32UnscaledOffset
define void @StoreCapabilityRegisterFromPtrWith32UnscaledOffset(i8 addrspace(200)* %foo, i32 %offset, i8 addrspace(200) * %toStore) {
entry:
; CHECK: str c2, [c0, w1, sxtw]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i32 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to i8 addrspace(200)* addrspace(200) *
  store i8 addrspace(200) * %toStore, i8 addrspace(200)* addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: StoreCapabilityRegisterFromPtrWith32ZextUnscaledOffset
define void @StoreCapabilityRegisterFromPtrWith32ZextUnscaledOffset(i8 addrspace(200)* %foo, i32 %offset, i8 addrspace(200) * %toStore) {
entry:
; CHECK: str c2, [c0, w1, uxtw]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %new
  %castptr = bitcast i8 addrspace(200)* %ptr to i8 addrspace(200)* addrspace(200) *
  store i8 addrspace(200) * %toStore, i8 addrspace(200)* addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: StoreCapabilityRegisterFromPtrWithImm
define void @StoreCapabilityRegisterFromPtrWithImm(i8 addrspace(200)* %foo, i8 addrspace(200) * %toStore) {
entry:
; CHECK: str c1, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 10000
  %castptr = bitcast i8 addrspace(200)* %ptr to i8 addrspace(200)* addrspace(200) *
  store i8 addrspace(200)* %toStore, i8 addrspace(200)* addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: StoreCapabilityRegisterFromPtrWithNegImm
define void @StoreCapabilityRegisterFromPtrWithNegImm(i8 addrspace(200)* %foo, i8 addrspace(200) * %toStore) {
entry:
; CHECK: str c1, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 -10000
  %castptr = bitcast i8 addrspace(200)* %ptr to i8 addrspace(200)* addrspace(200) *
  store i8 addrspace(200)* %toStore, i8 addrspace(200)* addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Loadi64RegisterFromPtrWithScaledOffset
define i64 @Loadi64RegisterFromPtrWithScaledOffset(i64 addrspace(200)* %foo, i64 %offset) {
entry:
; CHECK: ldr x0, [c0, x1, lsl #3]
  %ptr = getelementptr inbounds i64, i64 addrspace(200)* %foo, i64 %offset
  %0 = load i64, i64 addrspace(200)* %ptr, align 16
  ret i64 %0
}

; CHECK-LABEL: Loadi64RegisterFromPtrWith32ScaledOffset
define i64 @Loadi64RegisterFromPtrWith32ScaledOffset(i64 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldr x0, [c0, w1, sxtw #3]
  %ptr = getelementptr inbounds i64, i64 addrspace(200)* %foo, i32 %offset
  %0 = load i64, i64 addrspace(200)* %ptr, align 16
  ret i64 %0
}

; CHECK-LABEL: Loadi64RegisterFromPtrWith32ZextScaledOffset
define i64 @Loadi64RegisterFromPtrWith32ZextScaledOffset(i64 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldr x0, [c0, w1, uxtw #3]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i64, i64 addrspace(200)* %foo, i64 %new
  %0 = load i64, i64 addrspace(200)* %ptr, align 16
  ret i64 %0
}

; CHECK-LABEL: Loadi64RegisterFromPtrWithUnscaledOffset
define i64 @Loadi64RegisterFromPtrWithUnscaledOffset(i8 addrspace(200)* %foo, i64 %offset) {
entry:
; CHECK: ldr x0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to i64 addrspace(200) *
  %0 = load i64, i64 addrspace(200)* %castptr, align 16
  ret i64 %0
}

; CHECK-LABEL: Loadi64RegisterFromPtrWith32UnscaledOffset
define i64 @Loadi64RegisterFromPtrWith32UnscaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldr x0, [c0, w1, sxtw]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i32 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to i64 addrspace(200) *
  %0 = load i64, i64 addrspace(200)* %castptr, align 16
  ret i64 %0
}

; CHECK-LABEL: Loadi64RegisterFromPtrWith32ZextUnscaledOffset
define i64 @Loadi64RegisterFromPtrWith32ZextUnscaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldr x0, [c0, w1, uxtw]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %new
  %castptr = bitcast i8 addrspace(200)* %ptr to i64 addrspace(200) *
  %0 = load i64, i64 addrspace(200)* %castptr, align 16
  ret i64 %0
}

; CHECK-LABEL: Loadi64RegisterFromPtrWithImm
define i64 @Loadi64RegisterFromPtrWithImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: ldr x0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 10000
  %castptr = bitcast i8 addrspace(200)* %ptr to i64 addrspace(200) *
  %0 = load i64, i64 addrspace(200)* %castptr, align 16
  ret i64 %0
}

; CHECK-LABEL: Loadi64RegisterFromPtrWithNegImm
define i64 @Loadi64RegisterFromPtrWithNegImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: ldr x0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 -10000
  %castptr = bitcast i8 addrspace(200)* %ptr to i64 addrspace(200) *
  %0 = load i64, i64 addrspace(200)* %castptr, align 16
  ret i64 %0
}

; CHECK-LABEL: Storei64RegisterFromPtrWithScaledOffset
define void @Storei64RegisterFromPtrWithScaledOffset(i64 addrspace(200)* %foo, i64 %offset, i64 %toStore) {
entry:
; CHECK: str x2, [c0, x1, lsl #3]
  %ptr = getelementptr inbounds i64, i64 addrspace(200)* %foo, i64 %offset
  store i64 %toStore, i64 addrspace(200)* %ptr, align 16
  ret void
}

; CHECK-LABEL: Storei64RegisterFromPtrWith32ScaledOffset
define void @Storei64RegisterFromPtrWith32ScaledOffset(i64 addrspace(200)* %foo, i32 %offset, i64 %toStore) {
entry:
; CHECK: str x2, [c0, w1, sxtw #3]
  %ptr = getelementptr inbounds i64, i64 addrspace(200)* %foo, i32 %offset
  store i64 %toStore, i64 addrspace(200)* %ptr, align 16
  ret void
}

; CHECK-LABEL: Storei64RegisterFromPtrWith32ZextScaledOffset
define void @Storei64RegisterFromPtrWith32ZextScaledOffset(i64 addrspace(200)* %foo, i32 %offset, i64 %toStore) {
entry:
; CHECK: str x2, [c0, w1, uxtw #3]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i64, i64 addrspace(200)* %foo, i64 %new
  store i64 %toStore, i64 addrspace(200)* %ptr, align 16
  ret void
}

; CHECK-LABEL: Storei64RegisterFromPtrWithUnscaledOffset
define void @Storei64RegisterFromPtrWithUnscaledOffset(i8 addrspace(200)* %foo, i64 %offset) {
entry:
; CHECK:	str	x{{[0-9+]}}, [c0, x1]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to i64 addrspace(200) *
  store i64 22, i64 addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Storei64RegisterFromPtrWith32UnscaledOffset
define void @Storei64RegisterFromPtrWith32UnscaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK:	str	x{{[0-9+]}}, [c0, w1, sxtw]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i32 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to i64 addrspace(200) *
  store i64 22, i64 addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Storei64RegisterFromPtrWith32ZextUnscaledOffset
define void @Storei64RegisterFromPtrWith32ZextUnscaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK:	str	x{{[0-9+]}}, [c0, w1, uxtw]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %new
  %castptr = bitcast i8 addrspace(200)* %ptr to i64 addrspace(200) *
  store i64 22, i64 addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Storei64RegisterFromPtrWithImm
define void @Storei64RegisterFromPtrWithImm(i8 addrspace(200)* %foo) {
entry:
; CHECK:	str	x{{[0-9]+}}, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 10000
  %castptr = bitcast i8 addrspace(200)* %ptr to i64 addrspace(200) *
  store i64 22, i64 addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Storei64RegisterFromPtrWithNegImm
define void @Storei64RegisterFromPtrWithNegImm(i8 addrspace(200)* %foo) {
entry:
; CHECK:	str	x{{[0-9]+}}, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 -10000
  %castptr = bitcast i8 addrspace(200)* %ptr to i64 addrspace(200) *
  store i64 22, i64 addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Loadi32RegisterFromPtrWithScaledOffset
define i32 @Loadi32RegisterFromPtrWithScaledOffset(i32 addrspace(200)* %foo, i64 %offset) {
entry:
; CHECK: ldr w0, [c0, x1, lsl #2]
  %ptr = getelementptr inbounds i32, i32 addrspace(200)* %foo, i64 %offset
  %0 = load i32, i32 addrspace(200)* %ptr, align 16
  ret i32 %0
}

; CHECK-LABEL: Loadi32RegisterFromPtrWith32ScaledOffset
define i32 @Loadi32RegisterFromPtrWith32ScaledOffset(i32 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldr w0, [c0, w1, sxtw #2]
  %ptr = getelementptr inbounds i32, i32 addrspace(200)* %foo, i32 %offset
  %0 = load i32, i32 addrspace(200)* %ptr, align 16
  ret i32 %0
}

; CHECK-LABEL: Loadi32RegisterFromPtrWith32ZextScaledOffset
define i32 @Loadi32RegisterFromPtrWith32ZextScaledOffset(i32 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldr w0, [c0, w1, uxtw #2]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i32, i32 addrspace(200)* %foo, i64 %new
  %0 = load i32, i32 addrspace(200)* %ptr, align 16
  ret i32 %0
}

; CHECK-LABEL: Loadi32RegisterFromPtrWithUnscaledOffset
define i32 @Loadi32RegisterFromPtrWithUnscaledOffset(i8 addrspace(200)* %foo, i64 %offset) {
entry:
; CHECK: ldr w0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to i32 addrspace(200) *
  %0 = load i32, i32 addrspace(200)* %castptr, align 16
  ret i32 %0
}

; CHECK-LABEL: Loadi32RegisterFromPtrWith32UnscaledOffset
define i32 @Loadi32RegisterFromPtrWith32UnscaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldr w0, [c0, w1, sxtw]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i32 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to i32 addrspace(200) *
  %0 = load i32, i32 addrspace(200)* %castptr, align 16
  ret i32 %0
}

; CHECK-LABEL: Loadi32RegisterFromPtrWith32ZextUnscaledOffset
define i32 @Loadi32RegisterFromPtrWith32ZextUnscaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldr w0, [c0, w1, uxtw]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %new
  %castptr = bitcast i8 addrspace(200)* %ptr to i32 addrspace(200) *
  %0 = load i32, i32 addrspace(200)* %castptr, align 16
  ret i32 %0
}

; CHECK-LABEL: Loadi32RegisterFromPtrWithImm
define i32 @Loadi32RegisterFromPtrWithImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: ldr w0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 10000
  %castptr = bitcast i8 addrspace(200)* %ptr to i32 addrspace(200) *
  %0 = load i32, i32 addrspace(200)* %castptr, align 16
  ret i32 %0
}

; CHECK-LABEL: Loadi32RegisterFromPtrWithNegImm
define i32 @Loadi32RegisterFromPtrWithNegImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: ldr w0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 -10000
  %castptr = bitcast i8 addrspace(200)* %ptr to i32 addrspace(200) *
  %0 = load i32, i32 addrspace(200)* %castptr, align 16
  ret i32 %0
}

; CHECK-LABEL: Storei32RegisterFromPtrWithScaledOffset
define void @Storei32RegisterFromPtrWithScaledOffset(i32 addrspace(200)* %foo, i64 %offset, i32 %toStore) {
entry:
; CHECK: str w2, [c0, x1, lsl #2]
  %ptr = getelementptr inbounds i32, i32 addrspace(200)* %foo, i64 %offset
  store i32 %toStore, i32 addrspace(200)* %ptr, align 16
  ret void
}

; CHECK-LABEL: Storei32RegisterFromPtrWith32ScaledOffset
define void @Storei32RegisterFromPtrWith32ScaledOffset(i32 addrspace(200)* %foo, i32 %offset, i32 %toStore) {
entry:
; CHECK: str w2, [c0, w1, sxtw #2]
  %ptr = getelementptr inbounds i32, i32 addrspace(200)* %foo, i32 %offset
  store i32 %toStore, i32 addrspace(200)* %ptr, align 16
  ret void
}

; CHECK-LABEL: Storei32RegisterFromPtrWith32ZextScaledOffset
define void @Storei32RegisterFromPtrWith32ZextScaledOffset(i32 addrspace(200)* %foo, i32 %offset, i32 %toStore) {
entry:
; CHECK: str w2, [c0, w1, uxtw #2]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i32, i32 addrspace(200)* %foo, i64 %new
  store i32 %toStore, i32 addrspace(200)* %ptr, align 16
  ret void
}

; CHECK-LABEL: Storei32RegisterFromPtrWithUnscaledOffset
define void @Storei32RegisterFromPtrWithUnscaledOffset(i8 addrspace(200)* %foo, i64 %offset) {
entry:
; CHECK: str w{{[0-9]+}}, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to i32 addrspace(200) *
  store i32 22, i32 addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Storei32RegisterFromPtrWith32UnscaledOffset
define void @Storei32RegisterFromPtrWith32UnscaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: str w{{[0-9]+}}, [c0, w1, sxtw]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i32 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to i32 addrspace(200) *
  store i32 22, i32 addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Storei32RegisterFromPtrWith32ZextUnscaledOffset
define void @Storei32RegisterFromPtrWith32ZextUnscaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: str w{{[0-9]+}}, [c0, w1, uxtw]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %new
  %castptr = bitcast i8 addrspace(200)* %ptr to i32 addrspace(200) *
  store i32 22, i32 addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Storei32RegisterFromPtrWithImm
define void @Storei32RegisterFromPtrWithImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: str w{{[0-9]+}}, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 10000
  %castptr = bitcast i8 addrspace(200)* %ptr to i32 addrspace(200) *
  store i32 22, i32 addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Storei32RegisterFromPtrWithNegImm
define void @Storei32RegisterFromPtrWithNegImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: str w{{[0-9]+}}, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 -10000
  %castptr = bitcast i8 addrspace(200)* %ptr to i32 addrspace(200) *
  store i32 22, i32 addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Loadi16RegisterFromPtrWithScaledOffset
define i16 @Loadi16RegisterFromPtrWithScaledOffset(i16 addrspace(200)* %foo, i64 %offset) {
entry:
; CHECK: ldrh w0, [c0, x1, lsl #1]
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %foo, i64 %offset
  %0 = load i16, i16 addrspace(200)* %ptr, align 16
  ret i16 %0
}

; CHECK-LABEL: Loadi16RegisterFromPtrWith32ScaledOffset
define i16 @Loadi16RegisterFromPtrWith32ScaledOffset(i16 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldrh w0, [c0, w1, sxtw #1]
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %foo, i32 %offset
  %0 = load i16, i16 addrspace(200)* %ptr, align 16
  ret i16 %0
}

; CHECK-LABEL: Loadi16RegisterFromPtrWith32ZextScaledOffset
define i16 @Loadi16RegisterFromPtrWith32ZextScaledOffset(i16 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldrh w0, [c0, w1, uxtw #1]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %foo, i64 %new
  %0 = load i16, i16 addrspace(200)* %ptr, align 16
  ret i16 %0
}

; CHECK-LABEL: Loadi16RegisterFromPtrWithUnscaledOffset
define i16 @Loadi16RegisterFromPtrWithUnscaledOffset(i8 addrspace(200)* %foo, i64 %offset) {
entry:
; CHECK: ldrh w0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to i16 addrspace(200) *
  %0 = load i16, i16 addrspace(200)* %castptr, align 16
  ret i16 %0
}

; CHECK-LABEL: Loadi16RegisterFromPtrWith32UnscaledOffset
define i16 @Loadi16RegisterFromPtrWith32UnscaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldrh w0, [c0, w1, sxtw]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i32 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to i16 addrspace(200) *
  %0 = load i16, i16 addrspace(200)* %castptr, align 16
  ret i16 %0
}

; CHECK-LABEL: Loadi16RegisterFromPtrWith32ZextUnscaledOffset
define i16 @Loadi16RegisterFromPtrWith32ZextUnscaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldrh w0, [c0, w1, sxtw]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i32 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to i16 addrspace(200) *
  %0 = load i16, i16 addrspace(200)* %castptr, align 16
  ret i16 %0
}

; CHECK-LABEL: Loadi16RegisterFromPtrWithImm
define i16 @Loadi16RegisterFromPtrWithImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: ldrh w0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 10000
  %castptr = bitcast i8 addrspace(200)* %ptr to i16 addrspace(200) *
  %0 = load i16, i16 addrspace(200)* %castptr, align 16
  ret i16 %0
}

; CHECK-LABEL: Loadi16RegisterFromPtrWithNegImm
define i16 @Loadi16RegisterFromPtrWithNegImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: ldrh w0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 -10000
  %castptr = bitcast i8 addrspace(200)* %ptr to i16 addrspace(200) *
  %0 = load i16, i16 addrspace(200)* %castptr, align 16
  ret i16 %0
}

; CHECK-LABEL: Storei16RegisterFromPtrWithScaledOffset
define void @Storei16RegisterFromPtrWithScaledOffset(i16 addrspace(200)* %foo, i64 %offset, i16 %toStore) {
entry:
; CHECK: strh w2, [c0, x1, lsl #1]
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %foo, i64 %offset
  store i16 %toStore, i16 addrspace(200)* %ptr, align 16
  ret void
}

; CHECK-LABEL: Storei16RegisterFromPtrWith32ScaledOffset
define void @Storei16RegisterFromPtrWith32ScaledOffset(i16 addrspace(200)* %foo, i32 %offset, i16 %toStore) {
entry:
; CHECK: strh w2, [c0, w1, sxtw #1]
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %foo, i32 %offset
  store i16 %toStore, i16 addrspace(200)* %ptr, align 16
  ret void
}

; CHECK-LABEL: Storei16RegisterFromPtrWith32ZextScaledOffset
define void @Storei16RegisterFromPtrWith32ZextScaledOffset(i16 addrspace(200)* %foo, i32 %offset, i16 %toStore) {
entry:
; CHECK: strh w2, [c0, w1, uxtw #1]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %foo, i64 %new
  store i16 %toStore, i16 addrspace(200)* %ptr, align 16
  ret void
}

; CHECK-LABEL: Storei16RegisterFromPtrWithUnscaledOffset
define void @Storei16RegisterFromPtrWithUnscaledOffset(i8 addrspace(200)* %foo, i64 %offset) {
entry:
; CHECK: strh w{{[0-9]+}}, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to i16 addrspace(200) *
  store i16 22, i16 addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Storei16RegisterFromPtrWith32UnscaledOffset
define void @Storei16RegisterFromPtrWith32UnscaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: strh w{{[0-9]+}}, [c0, w1, sxtw]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i32 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to i16 addrspace(200) *
  store i16 22, i16 addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Storei16RegisterFromPtrWith32ZextUnscaledOffset
define void @Storei16RegisterFromPtrWith32ZextUnscaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: strh w{{[0-9]+}}, [c0, w1, uxtw]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %new
  %castptr = bitcast i8 addrspace(200)* %ptr to i16 addrspace(200) *
  store i16 22, i16 addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Storei16RegisterFromPtrWithImm
define void @Storei16RegisterFromPtrWithImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: strh w{{[0-9]+}}, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 10000
  %castptr = bitcast i8 addrspace(200)* %ptr to i16 addrspace(200) *
  store i16 22, i16 addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Storei16RegisterFromPtrWithNegImm
define void @Storei16RegisterFromPtrWithNegImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: strh w{{[0-9]+}}, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 -10000
  %castptr = bitcast i8 addrspace(200)* %ptr to i16 addrspace(200) *
  store i16 22, i16 addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Loadi8RegisterFromPtrWithScaledOffset
define i8 @Loadi8RegisterFromPtrWithScaledOffset(i8 addrspace(200)* %foo, i64 %offset) {
entry:
; CHECK: ldrb w0, [c0, x1]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %offset
  %0 = load i8, i8 addrspace(200)* %ptr, align 16
  ret i8 %0
}

; CHECK-LABEL: Loadi8RegisterFromPtrWith32ScaledOffset
define i8 @Loadi8RegisterFromPtrWith32ScaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldrb w0, [c0, w1, sxtw]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i32 %offset
  %0 = load i8, i8 addrspace(200)* %ptr, align 16
  ret i8 %0
}

; CHECK-LABEL: Loadi8RegisterFromPtrWith32ZextScaledOffset
define i8 @Loadi8RegisterFromPtrWith32ZextScaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldrb w0, [c0, w1, uxtw]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %new
  %0 = load i8, i8 addrspace(200)* %ptr, align 16
  ret i8 %0
}


; CHECK-LABEL: Loadi8RegisterFromPtrWithImm
define i8 @Loadi8RegisterFromPtrWithImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: ldrb w0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 10000
  %0 = load i8, i8 addrspace(200)* %ptr, align 16
  ret i8 %0
}

; CHECK-LABEL: Loadi8RegisterFromPtrWithNegImm
define i8 @Loadi8RegisterFromPtrWithNegImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: ldrb w0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 -10000
  %0 = load i8, i8 addrspace(200)* %ptr, align 16
  ret i8 %0
}

; CHECK-LABEL: Storei8RegisterFromPtrWithScaledOffset
define void @Storei8RegisterFromPtrWithScaledOffset(i8 addrspace(200)* %foo, i64 %offset, i8 %toStore) {
entry:
; CHECK: strb w2, [c0, x1]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %offset
  store i8 %toStore, i8 addrspace(200)* %ptr, align 16
  ret void
}

; CHECK-LABEL: Storei8RegisterFromPtrWith32ScaledOffset
define void @Storei8RegisterFromPtrWith32ScaledOffset(i8 addrspace(200)* %foo, i32 %offset, i8 %toStore) {
entry:
; CHECK: strb w2, [c0, w1, sxtw]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i32 %offset
  store i8 %toStore, i8 addrspace(200)* %ptr, align 16
  ret void
}

; CHECK-LABEL: Storei8RegisterFromPtrWith32ZextScaledOffset
define void @Storei8RegisterFromPtrWith32ZextScaledOffset(i8 addrspace(200)* %foo, i32 %offset, i8 %toStore) {
entry:
; CHECK: strb w2, [c0, w1, uxtw]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %new
  store i8 %toStore, i8 addrspace(200)* %ptr, align 16
  ret void
}

; CHECK-LABEL: Storei8RegisterFromPtrWithImm
define void @Storei8RegisterFromPtrWithImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: strb w{{[0-9]+}}, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 10000
  store i8 22, i8 addrspace(200)* %ptr, align 16
  ret void
}

; CHECK-LABEL: Storei8RegisterFromPtrWithNegImm
define void @Storei8RegisterFromPtrWithNegImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: strb w{{[0-9]+}}, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 -10000
  store i8 22, i8 addrspace(200)* %ptr, align 16
  ret void
}

; CHECK-LABEL: Loads32i8RegisterFromPtrWithScaledOffset
define i32 @Loads32i8RegisterFromPtrWithScaledOffset(i8 addrspace(200)* %foo, i64 %offset) {
entry:
; CHECK: ldrsb w0, [c0, x1]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %offset
  %0 = load i8, i8 addrspace(200)* %ptr, align 16
  %1 = sext i8 %0 to i32
  ret i32 %1
}

; CHECK-LABEL: Loads32i8RegisterFromPtrWith32ScaledOffset
define i32 @Loads32i8RegisterFromPtrWith32ScaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldrsb w0, [c0, w1, sxtw]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i32 %offset
  %0 = load i8, i8 addrspace(200)* %ptr, align 16
  %1 = sext i8 %0 to i32
  ret i32 %1
}

; CHECK-LABEL: Loads32i8RegisterFromPtrWith32ZextScaledOffset
define i32 @Loads32i8RegisterFromPtrWith32ZextScaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldrsb w0, [c0, w1, uxtw]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %new
  %0 = load i8, i8 addrspace(200)* %ptr, align 16
  %1 = sext i8 %0 to i32
  ret i32 %1
}


; CHECK-LABEL: Loads32i8RegisterFromPtrWithImm
define i32 @Loads32i8RegisterFromPtrWithImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: ldrsb w0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 10000
  %0 = load i8, i8 addrspace(200)* %ptr, align 16
  %1 = sext i8 %0 to i32
  ret i32 %1
}

; CHECK-LABEL: Loads32i8RegisterFromPtrWithNegImm
define i32 @Loads32i8RegisterFromPtrWithNegImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: ldrsb w0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 -10000
  %0 = load i8, i8 addrspace(200)* %ptr, align 16
  %1 = sext i8 %0 to i32
  ret i32 %1
}

; CHECK-LABEL: Loads64i8RegisterFromPtrWithScaledOffset
define i64 @Loads64i8RegisterFromPtrWithScaledOffset(i8 addrspace(200)* %foo, i64 %offset) {
entry:
; CHECK: ldrsb x0, [c0, x1]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %offset
  %0 = load i8, i8 addrspace(200)* %ptr, align 16
  %1 = sext i8 %0 to i64
  ret i64 %1
}

; CHECK-LABEL: Loads64i8RegisterFromPtrWith32ScaledOffset
define i64 @Loads64i8RegisterFromPtrWith32ScaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldrsb x0, [c0, w1, sxtw]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i32 %offset
  %0 = load i8, i8 addrspace(200)* %ptr, align 16
  %1 = sext i8 %0 to i64
  ret i64 %1
}

; CHECK-LABEL: Loads64i8RegisterFromPtrWith32ZextScaledOffset
define i64 @Loads64i8RegisterFromPtrWith32ZextScaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldrsb x0, [c0, w1, uxtw]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %new
  %0 = load i8, i8 addrspace(200)* %ptr, align 16
  %1 = sext i8 %0 to i64
  ret i64 %1
}

; CHECK-LABEL: Loads64i8RegisterFromPtrWithImm
define i64 @Loads64i8RegisterFromPtrWithImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: ldrsb x0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 10000
  %0 = load i8, i8 addrspace(200)* %ptr, align 16
  %1 = sext i8 %0 to i64
  ret i64 %1
}

; CHECK-LABEL: Loads64i8RegisterFromPtrWithNegImm
define i64 @Loads64i8RegisterFromPtrWithNegImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: ldrsb x0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 -10000
  %0 = load i8, i8 addrspace(200)* %ptr, align 16
  %1 = sext i8 %0 to i64
  ret i64 %1
}

; CHECK-LABEL: Loads32i16RegisterFromPtrWithScaledOffset
define i32 @Loads32i16RegisterFromPtrWithScaledOffset(i16 addrspace(200)* %foo, i64 %offset) {
entry:
; CHECK: ldrsh w0, [c0, x1, lsl #1]
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %foo, i64 %offset
  %0 = load i16, i16 addrspace(200)* %ptr, align 16
  %1 = sext i16 %0 to i32
  ret i32 %1
}

; CHECK-LABEL: Loads32i16RegisterFromPtrWith32ScaledOffset
define i32 @Loads32i16RegisterFromPtrWith32ScaledOffset(i16 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldrsh w0, [c0, w1, sxtw #1]
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %foo, i32 %offset
  %0 = load i16, i16 addrspace(200)* %ptr, align 16
  %1 = sext i16 %0 to i32
  ret i32 %1
}

; CHECK-LABEL: Loads32i16RegisterFromPtrWith32ZextScaledOffset
define i32 @Loads32i16RegisterFromPtrWith32ZextScaledOffset(i16 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldrsh w0, [c0, w1, uxtw #1]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %foo, i64 %new
  %0 = load i16, i16 addrspace(200)* %ptr, align 16
  %1 = sext i16 %0 to i32
  ret i32 %1
}

; CHECK-LABEL: Loads32i16RegisterFromPtrWithImm
define i32 @Loads32i16RegisterFromPtrWithImm(i16 addrspace(200)* %foo) {
entry:
; CHECK: ldrsh w0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %foo, i64 10000
  %0 = load i16, i16 addrspace(200)* %ptr, align 16
  %1 = sext i16 %0 to i32
  ret i32 %1
}

; CHECK-LABEL: Loads32i16RegisterFromPtrWithNegImm
define i32 @Loads32i16RegisterFromPtrWithNegImm(i16 addrspace(200)* %foo) {
entry:
; CHECK: ldrsh w0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %foo, i64 -10000
  %0 = load i16, i16 addrspace(200)* %ptr, align 16
  %1 = sext i16 %0 to i32
  ret i32 %1
}

; CHECK-LABEL: Loads64i16RegisterFromPtrWithScaledOffset
define i64 @Loads64i16RegisterFromPtrWithScaledOffset(i16 addrspace(200)* %foo, i64 %offset) {
entry:
; CHECK: ldrsh x0, [c0, x1, lsl #1]
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %foo, i64 %offset
  %0 = load i16, i16 addrspace(200)* %ptr, align 16
  %1 = sext i16 %0 to i64
  ret i64 %1
}

; CHECK-LABEL: Loads64i16RegisterFromPtrWith32ScaledOffset
define i64 @Loads64i16RegisterFromPtrWith32ScaledOffset(i16 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldrsh x0, [c0, w1, sxtw #1]
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %foo, i32 %offset
  %0 = load i16, i16 addrspace(200)* %ptr, align 16
  %1 = sext i16 %0 to i64
  ret i64 %1
}

; CHECK-LABEL: Loads64i16RegisterFromPtrWith32ZextScaledOffset
define i64 @Loads64i16RegisterFromPtrWith32ZextScaledOffset(i16 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldrsh x0, [c0, w1, uxtw #1]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %foo, i64 %new
  %0 = load i16, i16 addrspace(200)* %ptr, align 16
  %1 = sext i16 %0 to i64
  ret i64 %1
}

; CHECK-LABEL: Loads64i16RegisterFromPtrWithImm
define i64 @Loads64i16RegisterFromPtrWithImm(i16 addrspace(200)* %foo) {
entry:
; CHECK: ldrsh x0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %foo, i64 10000
  %0 = load i16, i16 addrspace(200)* %ptr, align 16
  %1 = sext i16 %0 to i64
  ret i64 %1
}

; CHECK-LABEL: Loads64i16RegisterFromPtrWithNegImm
define i64 @Loads64i16RegisterFromPtrWithNegImm(i16 addrspace(200)* %foo) {
entry:
; CHECK: ldrsh x0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i16, i16 addrspace(200)* %foo, i64 -10000
  %0 = load i16, i16 addrspace(200)* %ptr, align 16
  %1 = sext i16 %0 to i64
  ret i64 %1
}

; CHECK-LABEL: Loadf32RegisterFromPtrWithScaledOffset
define float @Loadf32RegisterFromPtrWithScaledOffset(float addrspace(200)* %foo, i64 %offset) {
entry:
; CHECK: ldr s0, [c0, x1, lsl #2]
  %ptr = getelementptr inbounds float, float addrspace(200)* %foo, i64 %offset
  %0 = load float, float addrspace(200)* %ptr, align 16
  ret float %0
}

; CHECK-LABEL: Loadf32RegisterFromPtrWith32ScaledOffset
define float @Loadf32RegisterFromPtrWith32ScaledOffset(float addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldr s0, [c0, w1, sxtw #2]
  %ptr = getelementptr inbounds float, float addrspace(200)* %foo, i32 %offset
  %0 = load float, float addrspace(200)* %ptr, align 16
  ret float %0
}

; CHECK-LABEL: Loadf32RegisterFromPtrWith32ZextScaledOffset
define float @Loadf32RegisterFromPtrWith32ZextScaledOffset(float addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldr s0, [c0, w1, uxtw #2]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds float, float addrspace(200)* %foo, i64 %new
  %0 = load float, float addrspace(200)* %ptr, align 16
  ret float %0
}

; CHECK-LABEL: Loadf32RegisterFromPtrWithUnscaledOffset
define float @Loadf32RegisterFromPtrWithUnscaledOffset(i8 addrspace(200)* %foo, i64 %offset) {
entry:
; CHECK: ldr s0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to float addrspace(200) *
  %0 = load float, float addrspace(200)* %castptr, align 16
  ret float %0
}

; CHECK-LABEL: Loadf32RegisterFromPtrWith32UnscaledOffset
define float @Loadf32RegisterFromPtrWith32UnscaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldr s0, [c0, w1, sxtw]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i32 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to float addrspace(200) *
  %0 = load float, float addrspace(200)* %castptr, align 16
  ret float %0
}

; CHECK-LABEL: Loadf32RegisterFromPtrWith32ZextUnscaledOffset
define float @Loadf32RegisterFromPtrWith32ZextUnscaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldr s0, [c0, w1, uxtw]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %new
  %castptr = bitcast i8 addrspace(200)* %ptr to float addrspace(200) *
  %0 = load float, float addrspace(200)* %castptr, align 16
  ret float %0
}

; CHECK-LABEL: Loadf32RegisterFromPtrWithImm
define float @Loadf32RegisterFromPtrWithImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: ldr s0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 10000
  %castptr = bitcast i8 addrspace(200)* %ptr to float addrspace(200) *
  %0 = load float, float addrspace(200)* %castptr, align 16
  ret float %0
}

; CHECK-LABEL: Loadf32RegisterFromPtrWithNegImm
define float @Loadf32RegisterFromPtrWithNegImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: ldr s0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 -10000
  %castptr = bitcast i8 addrspace(200)* %ptr to float addrspace(200) *
  %0 = load float, float addrspace(200)* %castptr, align 16
  ret float %0
}

; CHECK-LABEL: Storef32RegisterFromPtrWithScaledOffset
define void @Storef32RegisterFromPtrWithScaledOffset(float addrspace(200)* %foo, i64 %offset, float %toStore) {
entry:
; CHECK: str s0, [c0, x1, lsl #2]
  %ptr = getelementptr inbounds float, float addrspace(200)* %foo, i64 %offset
  store float %toStore, float addrspace(200)* %ptr, align 16
  ret void
}

; CHECK-LABEL: Storef32RegisterFromPtrWith32ScaledOffset
define void @Storef32RegisterFromPtrWith32ScaledOffset(float addrspace(200)* %foo, i32 %offset, float %toStore) {
entry:
; CHECK: str s0, [c0, w1, sxtw #2]
  %ptr = getelementptr inbounds float, float addrspace(200)* %foo, i32 %offset
  store float %toStore, float addrspace(200)* %ptr, align 16
  ret void
}

; CHECK-LABEL: Storef32RegisterFromPtrWith32ZextScaledOffset
define void @Storef32RegisterFromPtrWith32ZextScaledOffset(float addrspace(200)* %foo, i32 %offset, float %toStore) {
entry:
; CHECK: str s0, [c0, w1, uxtw #2]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds float, float addrspace(200)* %foo, i64 %new
  store float %toStore, float addrspace(200)* %ptr, align 16
  ret void
}

; CHECK-LABEL: Storef32RegisterFromPtrWithUnscaledOffset
define void @Storef32RegisterFromPtrWithUnscaledOffset(i8 addrspace(200)* %foo, i64 %offset, float %in) {
entry:
; CHECK: str s0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to float addrspace(200) *
  store float %in, float addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Storef32RegisterFromPtrWith32UnscaledOffset
define void @Storef32RegisterFromPtrWith32UnscaledOffset(i8 addrspace(200)* %foo, i32 %offset, float %in) {
entry:
; CHECK: str s0, [c0, w1, sxtw]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i32 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to float addrspace(200) *
  store float %in, float addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Storef32RegisterFromPtrWith32ZextUnscaledOffset
define void @Storef32RegisterFromPtrWith32ZextUnscaledOffset(i8 addrspace(200)* %foo, i32 %offset, float %in) {
entry:
; CHECK: str s0, [c0, w1, uxtw]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %new
  %castptr = bitcast i8 addrspace(200)* %ptr to float addrspace(200) *
  store float %in, float addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Storef32RegisterFromPtrWithImm
define void @Storef32RegisterFromPtrWithImm(i8 addrspace(200)* %foo, float %in) {
entry:
; CHECK: str s0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 10000
  %castptr = bitcast i8 addrspace(200)* %ptr to float addrspace(200) *
  store float %in, float addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Storef32RegisterFromPtrWithNegImm
define void @Storef32RegisterFromPtrWithNegImm(i8 addrspace(200)* %foo, float %in) {
entry:
; CHECK: str s0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 -10000
  %castptr = bitcast i8 addrspace(200)* %ptr to float addrspace(200) *
  store float %in, float addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Loadf64RegisterFromPtrWithScaledOffset
define double @Loadf64RegisterFromPtrWithScaledOffset(double addrspace(200)* %foo, i64 %offset) {
entry:
; CHECK: ldr d0, [c0, x1, lsl #3]
  %ptr = getelementptr inbounds double, double addrspace(200)* %foo, i64 %offset
  %0 = load double, double addrspace(200)* %ptr, align 16
  ret double %0
}

; CHECK-LABEL: Loadf64RegisterFromPtrWith32ScaledOffset
define double @Loadf64RegisterFromPtrWith32ScaledOffset(double addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldr d0, [c0, w1, sxtw #3]
  %ptr = getelementptr inbounds double, double addrspace(200)* %foo, i32 %offset
  %0 = load double, double addrspace(200)* %ptr, align 16
  ret double %0
}

; CHECK-LABEL: Loadf64RegisterFromPtrWith32ZextScaledOffset
define double @Loadf64RegisterFromPtrWith32ZextScaledOffset(double addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldr d0, [c0, w1, uxtw #3]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds double, double addrspace(200)* %foo, i64 %new
  %0 = load double, double addrspace(200)* %ptr, align 16
  ret double %0
}

; CHECK-LABEL: Loadf64RegisterFromPtrWithUnscaledOffset
define double @Loadf64RegisterFromPtrWithUnscaledOffset(i8 addrspace(200)* %foo, i64 %offset) {
entry:
; CHECK: ldr d0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to double addrspace(200) *
  %0 = load double, double addrspace(200)* %castptr, align 16
  ret double %0
}

; CHECK-LABEL: Loadf64RegisterFromPtrWithImm
define double @Loadf64RegisterFromPtrWithImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: ldr d0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 10000
  %castptr = bitcast i8 addrspace(200)* %ptr to double addrspace(200) *
  %0 = load double, double addrspace(200)* %castptr, align 16
  ret double %0
}

; CHECK-LABEL: Loadf64RegisterFromPtrWithNegImm
define double @Loadf64RegisterFromPtrWithNegImm(i8 addrspace(200)* %foo) {
entry:
; CHECK: ldr d0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 -10000
  %castptr = bitcast i8 addrspace(200)* %ptr to double addrspace(200) *
  %0 = load double, double addrspace(200)* %castptr, align 16
  ret double %0
}

; CHECK-LABEL: Storef64RegisterFromPtrWithScaledOffset
define void @Storef64RegisterFromPtrWithScaledOffset(double addrspace(200)* %foo, i64 %offset, double %toStore) {
entry:
; CHECK: str d0, [c0, x1, lsl #3]
  %ptr = getelementptr inbounds double, double addrspace(200)* %foo, i64 %offset
  store double %toStore, double addrspace(200)* %ptr, align 16
  ret void
}

; CHECK-LABEL: Storef64RegisterFromPtrWith32ScaledOffset
define void @Storef64RegisterFromPtrWith32ScaledOffset(double addrspace(200)* %foo, i32 %offset, double %toStore) {
entry:
; CHECK: str d0, [c0, w1, sxtw #3]
  %ptr = getelementptr inbounds double, double addrspace(200)* %foo, i32 %offset
  store double %toStore, double addrspace(200)* %ptr, align 16
  ret void
}

; CHECK-LABEL: Storef64RegisterFromPtrWith32ZextScaledOffset
define void @Storef64RegisterFromPtrWith32ZextScaledOffset(double addrspace(200)* %foo, i32 %offset, double %toStore) {
entry:
; CHECK: str d0, [c0, w1, uxtw #3]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds double, double addrspace(200)* %foo, i64 %new
  store double %toStore, double addrspace(200)* %ptr, align 16
  ret void
}

; CHECK-LABEL: Storef64RegisterFromPtrWithUnscaledOffset
define void @Storef64RegisterFromPtrWithUnscaledOffset(i8 addrspace(200)* %foo, i64 %offset, double %in) {
entry:
; CHECK: str d0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to double addrspace(200) *
  store double %in, double addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Storef64RegisterFromPtrWith32UnscaledOffset
define void @Storef64RegisterFromPtrWith32UnscaledOffset(i8 addrspace(200)* %foo, i32 %offset, double %in) {
entry:
; CHECK: str d0, [c0, w1, sxtw]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i32 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to double addrspace(200) *
  store double %in, double addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Storef64RegisterFromPtrWith32ZextUnscaledOffset
define void @Storef64RegisterFromPtrWith32ZextUnscaledOffset(i8 addrspace(200)* %foo, i32 %offset, double %in) {
entry:
; CHECK: str d0, [c0, w1, uxtw]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %new
  %castptr = bitcast i8 addrspace(200)* %ptr to double addrspace(200) *
  store double %in, double addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Storef64RegisterFromPtrWithImm
define void @Storef64RegisterFromPtrWithImm(i8 addrspace(200)* %foo, double %in) {
entry:
; CHECK: str d0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 10000
  %castptr = bitcast i8 addrspace(200)* %ptr to double addrspace(200) *
  store double %in, double addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Storef64RegisterFromPtrWithNegImm
define void @Storef64RegisterFromPtrWithNegImm(i8 addrspace(200)* %foo, double %in) {
entry:
; CHECK: str d0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 -10000
  %castptr = bitcast i8 addrspace(200)* %ptr to double addrspace(200) *
  store double %in, double addrspace(200)* %castptr, align 16
  ret void
}

; CHECK-LABEL: Loadv2f32RegisterFromPtrWithScaledOffset
define <2 x float> @Loadv2f32RegisterFromPtrWithScaledOffset(<2 x float> addrspace(200)* %foo, i64 %offset) {
entry:
; CHECK: ldr d0, [c0, x1, lsl #3]
  %ptr = getelementptr inbounds <2 x float>, <2 x float> addrspace(200)* %foo, i64 %offset
  %0 = load <2 x float>, <2 x float> addrspace(200)* %ptr, align 16
  ret <2 x float> %0
}

; CHECK-LABEL: Loadv4f16RegisterFromPtr32WithScaledOffset
define <4 x half> @Loadv4f16RegisterFromPtr32WithScaledOffset(<4 x half> addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldr d0, [c0, w1, sxtw #3]
  %ptr = getelementptr inbounds <4 x half>, <4 x half> addrspace(200)* %foo, i32 %offset
  %0 = load <4 x half>, <4 x half> addrspace(200)* %ptr, align 16
  ret <4 x half> %0
}

; CHECK-LABEL: Loadv2i32RegisterFromPtr32ZextWithScaledOffset
define <2 x i32> @Loadv2i32RegisterFromPtr32ZextWithScaledOffset(<2 x i32> addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldr d0, [c0, w1, uxtw #3]
  %new = zext i32 %offset to i64
  %ptr = getelementptr inbounds <2 x i32>, <2 x i32> addrspace(200)* %foo, i64 %new
  %0 = load <2 x i32>, <2 x i32> addrspace(200)* %ptr, align 16
  ret <2 x i32> %0
}

; CHECK-LABEL: Loadv4i16RegisterFromPtrWithUnscaledOffset
define <4 x i16> @Loadv4i16RegisterFromPtrWithUnscaledOffset(i8 addrspace(200)* %foo, i64 %offset) {
entry:
; CHECK: ldr d0, [c0, x{{[0-9]+}}]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i64 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to <4 x i16> addrspace(200) *
  %0 = load <4 x i16>, <4 x i16> addrspace(200)* %castptr, align 16
  ret <4 x i16> %0
}

; CHECK-LABEL: Loadv8i8RegisterFromPtr32WithUnscaledOffset
define <8 x i8> @Loadv8i8RegisterFromPtr32WithUnscaledOffset(i8 addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldr d0, [c0, w1, sxtw]
  %ptr = getelementptr inbounds i8, i8 addrspace(200)* %foo, i32 %offset
  %castptr = bitcast i8 addrspace(200)* %ptr to <8 x i8> addrspace(200) *
  %0 = load <8 x i8>, <8 x i8> addrspace(200)* %castptr, align 16
  ret <8 x i8> %0
}
