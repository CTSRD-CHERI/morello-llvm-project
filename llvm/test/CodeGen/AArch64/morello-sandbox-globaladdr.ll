; RUN: llc -mtriple=arm64 -mattr=+c64,+morello -target-abi purecap -o - %s -aarch64-enable-sandbox-globals-opt=false | FileCheck %s --check-prefix=PURE --check-prefix=ALL --check-prefix=PURE-STATIC
; RUN: llc -mtriple=arm64 -mattr=+c64,+morello -target-abi purecap -relocation-model=pic -aarch64-enable-sandbox-globals-opt=false -o - %s | FileCheck %s --check-prefix=PURE --check-prefix=ALL --check-prefix=PURE-PIC --check-prefix=PURE-PIC-C64

@v = internal addrspace(200) global i32 5, align 4

; ALL: .p2align 4
; ALL-LABEL: .LCPI0_0
; ALL: .capinit v
; ALL: .xword 0
; ALL: .xword 0


; CHECK-PURE-LABEL: testGlobalAddress
define i32 @testGlobalAddress() {
entry:
  %l = load i32, i32 addrspace(200)* @v, align 4
  ret i32 %l
; PURE:      adrp	c[[H:[0-9]+]], .LCPI0_0
; PURE-NEXT: ld{{u?}}r	c[[CB:[0-9]+]], [c[[H]], :lo12:.LCPI0_0]
; PURE-NEXT:	ldr	w0, [c[[CB]]]
}

@externWeakSymbol = extern_weak addrspace(200) global i8, align 1

; CHECK-PURE-LABEL: testExternWeakSymbol
define i8 @testExternWeakSymbol() {
entry:
  %0 = load i8,  i8 addrspace(200)* @externWeakSymbol
  ret i8 %0
; PURE:      adrp	c[[H:[0-9]+]], :got:externWeakSymbol
; PURE-NEXT: ld{{u?}}r	c[[CB:[0-9]+]], [c[[H]], :got_lo12:externWeakSymbol]
; PURE:      ldrb
}

@w = addrspace(200) global i32 5, align 4

; CHECK-PURE-LABEL: testGlobalAddressCommon
define i32 @testGlobalAddressCommon() {
entry:
  %l = load i32, i32 addrspace(200)* @w, align 4
  ret i32 %l
; PURE:      adrp	c[[H:[0-9]+]], :got:w
; PURE-NEXT: ld{{u?}}r	c[[CB:[0-9]+]], [c[[H]], :got_lo12:w]
}

; PURE-STATIC-LABEL: testFuncAddress
; PURE-STATIC: adrp c[[ADDR:[0-9]+]], myfunc
; PURE-STATIC: add      c[[ADDR]], c[[ADDR]], :lo12:myfunc
; PURE-PIC-LABEL: testFuncAddress
; PURE-PIC: adrp c[[ADDR:[0-9]+]], :got:myfunc
; PURE-PIC-C64: ldr c[[ADDR]], [c[[ADDR]], :got_lo12:myfunc]
define i8 addrspace(200)* @testFuncAddress() {
entry:
  %0 = tail call i8 addrspace(200)* @llvm.cheri.pcc.get()
  %1 = tail call i64 @llvm.cheri.cap.base.get(i8 addrspace(200)* %0)
  %ptroffset = sub i64 ptrtoint (i32 (...)* @myfunc to i64), %1
  %2 = tail call i8 addrspace(200)* @llvm.cheri.cap.offset.set(i8 addrspace(200)* %0, i64 %ptroffset)
  ret i8 addrspace(200)* %2
}

declare i32 @myfunc(...)
declare i8 addrspace(200)* @llvm.cheri.pcc.get()
declare i64 @llvm.cheri.cap.base.get(i8 addrspace(200)*)
declare i8 addrspace(200)* @llvm.cheri.cap.offset.set(i8 addrspace(200)*, i64)
