; RUN: llc -mtriple=arm64 < %s -mattr=+c64,+morello -target-abi purecap | FileCheck %s

@object = external hidden global i64, align 8
@object1 = addrspace(200) global i64 zeroinitializer

; CHECK: @t1_cap
; CHECK: ldur xzr, [c{{[0-9]+}}, #-8]
; CHECK: ret
define void @t1_cap() {
  %incdec.ptr = getelementptr inbounds i64, i64 addrspace(200)* @object1, i64 -1
  %tmp = load volatile i64, i64 addrspace(200)* %incdec.ptr, align 8
  ret void
}

; CHECK: @t2_imm_cap
; CHECK: sub [[ADDREG:c[0-9]+]], c{{[0-9]+}}, #264
; CHECK: ldr xzr, [
; CHECK: [[ADDREG]]]
; CHECK: ret
define void @t2_imm_cap() {
  %incdec.ptr = getelementptr inbounds i64, i64 addrspace(200)* @object1, i64 -33
  %tmp = load volatile i64, i64 addrspace(200)* %incdec.ptr, align 8
  ret void
}

; CHECK: @t3_cap
; CHECK: ldr xzr, [c{{[0-9]+}}, #32760]
; CHECK: ret
define void @t3_cap() {
  %incdec.ptr = getelementptr inbounds i64, i64 addrspace(200)* @object1, i64 4095
  %tmp = load volatile i64, i64 addrspace(200)* %incdec.ptr, align 8
  ret void
}

; CHECK: @t3_cap_cadd
; CHECK: mov     w[[OFFSET:[0-9]+]], #32768
; CHECK: ldr             xzr, [c0, x[[OFFSET]]]
define void @t3_cap_cadd() {
  %incdec.ptr = getelementptr inbounds i64, i64 addrspace(200)* @object1, i64 4096
  %tmp = load volatile i64, i64 addrspace(200)* %incdec.ptr, align 8
  ret void
}

; CHECK: @t4_cap
; CHECK: mov    w[[NUM:[0-9]+]], #32776
; CHECK: ldr xzr, [c{{[0-9]+}}, x[[NUM]]]
; CHECK: ret
define void @t4_cap() {
  %incdec.ptr = getelementptr inbounds i64, i64 addrspace(200)* @object1, i64 4097
  %tmp = load volatile i64, i64 addrspace(200)* %incdec.ptr, align 8
  ret void
}

; base + reg
; CHECK: @t5_cap
; CHECK: ldr xzr, [c{{[0-9]+}}, x{{[0-9]+}}, lsl #3]
; CHECK: ret
define void @t5_cap(i64 %a) {
  %incdec.ptr = getelementptr inbounds i64, i64 addrspace(200)* @object1, i64 %a
  %tmp = load volatile i64, i64 addrspace(200)* %incdec.ptr, align 8
  ret void
}

; base + reg + imm
; CHECK: @t6_cap
; CHECK: mov w[[NUM:[0-9]+]], #32776
; CHECK: add c0, c1, x0, uxtx #3
; CHECK: ldr xzr, [c0, x[[NUM]]]
; CHECK: ret
define void @t6_cap(i64 %a) {
  %tmp1 = getelementptr inbounds i64, i64 addrspace(200)* @object1, i64 %a
  %incdec.ptr = getelementptr inbounds i64, i64 addrspace(200)* %tmp1, i64 4097
  %tmp = load volatile i64, i64 addrspace(200)* %incdec.ptr, align 8
  ret void
}

; CHECK-LABEL: LoadCapabilityRegisterFromCapWithScaledOffset
define i8 addrspace(200)* @LoadCapabilityRegisterFromCapWithScaledOffset(i8 addrspace(200)* addrspace(200)* %foo, i32 %offset) {
entry:
; CHECK: ldr c0, [c0, w1, sxtw #4]
  %ptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %foo, i32 %offset
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %ptr, align 16
  ret i8 addrspace(200)* %0
}
