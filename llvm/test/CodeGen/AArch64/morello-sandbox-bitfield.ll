; RUN: llc -mtriple=aarch64-none-elf -mattr=+c64,+morello -target-abi purecap -o - %s \
; RUN:   | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none--elf"

%struct.Data = type { [10 x i8], [2 x i8] }

@data = common addrspace(200) global %struct.Data zeroinitializer, align 4

; Check that accessing a simple value in a bitfield with type i<X> where X is
; bigger than 64 bits results in the correct code in the sandbox mode, in
; particular, the test examines that the load of the complete bitfield (here
; with type i80) gets successfully type-legalized.
;
; CHECK-LABEL: get_value
define i16 @get_value() addrspace(200) {
entry:
  %bf.load = load i80, ptr addrspace(200) @data, align 4
  %bf.lshr = lshr i80 %bf.load, 64
  %bf.cast = trunc i80 %bf.lshr to i32
  %conv = trunc i32 %bf.cast to i16
  ret i16 %conv

; CHECK:      adrp	{{x|c}}[[PTR:[0-9]+]], :got:data
; CHECK-NEXT:  ldr	c[[CAP:[0-9]+]], [c[[PTR]], :got_lo12:data]
; CHECK-NEXT:  ldrh    w0, [c[[CAP]], #8]
; CHECK-NEXT:      ret
}

; Test the same situation as in get_value() but for stores instead of loads.
;
; CHECK-LABEL: put_value
define void @put_value(i80 %v) addrspace(200) {
entry:
  store i80 %v, ptr addrspace(200) @data, align 4
  ret void

; CHECK:      adrp	{{x|c}}[[PTR:[0-9]+]], :got:data
; CHECK-NEXT:  ldr	c[[CAP:[0-9]+]], [c[[PTR]], :got_lo12:data]
; CHECK-NEXT:  str     x{{[0-9+]}}, [c[[CAP]]]
; CHECK-NEXT:  strh    w{{[0-9]+}}, [c[[CAP]], #8]
; CHECK-NEXT:      ret
}
