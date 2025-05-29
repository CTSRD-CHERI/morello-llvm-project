; RUN: llc -mtriple=arm64 -mattr=+c64,+morello -target-abi purecap -relocation-model=pic -aarch64-enable-sandbox-globals-opt=false -o - %s | FileCheck %s --check-prefix=PURE
; RUN: llc -mtriple=arm64 -mattr=+c64,+morello -target-abi purecap -relocation-model=static -aarch64-enable-sandbox-globals-opt=false -o - %s | FileCheck %s --check-prefix=PURE

@v = internal addrspace(200) global i32 5, align 4

; PURE: .p2align 4
; PURE-LABEL: .LCPI0_0
; PURE: .chericap v


; CHECK-PURE-LABEL: testGlobalAddress
define i32 @testGlobalAddress() {
entry:
  %l = load i32, ptr addrspace(200) @v, align 4
  ret i32 %l
; PURE:      adrp	c[[H:[0-9]+]], .LCPI0_0
; PURE-NEXT: ld{{u?}}r	c[[CB:[0-9]+]], [c[[H]], :lo12:.LCPI0_0]
; PURE-NEXT:	ldr	w0, [c[[CB]]]
}

@externWeakSymbol = extern_weak addrspace(200) global i8, align 1

; CHECK-PURE-LABEL: testExternWeakSymbol
define i8 @testExternWeakSymbol() {
entry:
  %0 = load i8,  ptr addrspace(200) @externWeakSymbol
  ret i8 %0
; PURE:      adrp	c[[H:[0-9]+]], :got:externWeakSymbol
; PURE-NEXT: ld{{u?}}r	c[[CB:[0-9]+]], [c[[H]], :got_lo12:externWeakSymbol]
; PURE:      ldrb
}

@w = addrspace(200) global i32 5, align 4

; CHECK-PURE-LABEL: testGlobalAddressCommon
define i32 @testGlobalAddressCommon() {
entry:
  %l = load i32, ptr addrspace(200) @w, align 4
  ret i32 %l
; PURE:      adrp	c[[H:[0-9]+]], :got:w
; PURE-NEXT: ld{{u?}}r	c[[CB:[0-9]+]], [c[[H]], :got_lo12:w]
}

; PURE-LABEL: testFuncAddress
; PURE: adrp c[[ADDR:[0-9]+]], :got:myfunc
; PURE: ldr c[[ADDR]], [c[[ADDR]], :got_lo12:myfunc]
define ptr addrspace(200) @testFuncAddress() {
entry:
  %0 = tail call ptr addrspace(200) @llvm.cheri.pcc.get()
  %1 = tail call i64 @llvm.cheri.cap.base.get(ptr addrspace(200) %0)
  %ptroffset = sub i64 ptrtoint (ptr addrspace(200) @myfunc to i64), %1
  %2 = tail call ptr addrspace(200) @llvm.cheri.cap.offset.set(ptr addrspace(200) %0, i64 %ptroffset)
  ret ptr addrspace(200) %2
}

declare i32 @myfunc(...)
declare ptr addrspace(200) @llvm.cheri.pcc.get()
declare i64 @llvm.cheri.cap.base.get(ptr addrspace(200))
declare ptr addrspace(200) @llvm.cheri.cap.offset.set(ptr addrspace(200), i64)
