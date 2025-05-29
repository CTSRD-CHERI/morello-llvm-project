; RUN: llc -mtriple=arm64 -mattr=+c64,+morello -target-abi purecap -relocation-model=pic -o - %s | FileCheck %s

@v = internal addrspace(200) global i32 5, align 4

; Since v has internal linkage we can't load via the GOT and we need
; to use a constant pool.

; CHECK-LABEL: testGlobalAddress
define i32 @testGlobalAddress() {
entry:
  %l = load i32, ptr addrspace(200) @v, align 4
  ret i32 %l
; CHECK:      adrp	c[[H:[0-9]+]], .L__cap_merged_table
; CHECK-NEXT: ldr	c[[CB:[0-9]+]], [c[[H]], :lo12:.L__cap_merged_table]
; CHECK-NEXT:	ldr	w0, [c[[CB]]]
}

@externWeakSymbol = extern_weak addrspace(200) global i8, align 1

; CHECK-LABEL: testExternWeakSymbol
define i8 @testExternWeakSymbol() {
entry:
  %0 = load i8,  ptr addrspace(200) @externWeakSymbol
  ret i8 %0
; CHECK:      adrp	c[[H:[0-9]+]], :got:externWeakSymbol
; CHECK: ldr	c[[CB:[0-9]+]], [c[[H]], :got_lo12:externWeakSymbol]
; CHECK-NEXT:	ldrb	w0, [c[[CB]]]
; CHECK-NEXT:   ret
}

@w = addrspace(200) global i32 5, align 4

; CHECK-LABEL: testGlobalAddressCommon
define i32 @testGlobalAddressCommon() {
entry:
  %l = load i32, ptr addrspace(200) @w, align 4
  ret i32 %l
; CHECK:      adrp	c[[H:[0-9]+]], :got:w
; CHECK-NEXT: ldr	c[[CB:[0-9]+]], [c[[H]], :got_lo12:w]
}

declare i32 @myfunc(...)
declare ptr addrspace(200) @llvm.cheri.pcc.get()
declare i64 @llvm.cheri.cap.base.get(ptr addrspace(200))
declare ptr addrspace(200) @llvm.cheri.cap.offset.set(ptr addrspace(200), i64)

; CHECK: .p2align	4
; CHECK: .L__cap_merged_table:
; CHECK: .chericap v
