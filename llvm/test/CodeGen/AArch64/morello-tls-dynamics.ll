; RUN: llc -mtriple=arm64-none-linux-gnu -mattr=+c64 -target-abi purecap -relocation-model=pic -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=arm64-none-linux-gnu -mattr=+c64 -target-abi purecap -relocation-model=pic -filetype=obj < %s | llvm-objdump --mattr=+morello -r - | FileCheck --check-prefix=CHECK-RELOC %s
; RUN: llc -mtriple=arm64-none-linux-gnu -mattr=+c64 -target-abi purecap -relocation-model=pic -filetype=obj < %s | llvm-objdump -r - | FileCheck --check-prefix=CHECK-RELOC %s
; RUN: llc -mtriple=arm64-none-linux-gnu -mattr=+c64 -target-abi purecap -verify-machineinstrs < %s | FileCheck %s
; RUN: llc -mtriple=arm64-none-linux-gnu -mattr=+c64 -target-abi purecap -filetype=obj < %s | llvm-objdump -r - | FileCheck --check-prefix=CHECK-RELOC %s
; RUN: llc -mtriple=arm64-none-linux-gnu -mattr=+c64 -target-abi purecap -filetype=obj < %s | llvm-objdump -d --mattr=+morello - | FileCheck --check-prefix=CHECK-ASM %s
; RUN: llc -mtriple=arm64-none-linux-gnu -mattr=+c64 -target-abi purecap -filetype=obj < %s | llvm-objdump -d - | FileCheck --check-prefix=CHECK-ASM %s

target datalayout = "e-m:e-i64:64-i128:128-n32:64-S128-pf200:128:128-A200-P200-G200"

@general_dynamic_var = external thread_local addrspace(200) global i32

; CHECK-ASM-NOT: blr x

define i32 @test_generaldynamic() {
; CHECK-LABEL: test_generaldynamic:

  %val = load i32, i32 addrspace(200)* @general_dynamic_var
  ret i32 %val

; CHECK: mrs c2, CTPIDR_EL0
; CHECK: nop
; CHECK-NEXT: adrp c0, :tlsdesc:general_dynamic_var
; CHECK-NEXT: ldr c1, [c0, :tlsdesc_lo12:general_dynamic_var]
; CHECK-NEXT: add c0, c0, :tlsdesc_lo12:general_dynamic_var
; CHECK-NEXT: .tlsdesccall general_dynamic_var
; CHECK-NEXT: blr c1
; CHECK: scbnds	c[[ADDR:[0-9]+]], c0, x1
; CHECK: ldr w0, [c[[ADDR]]]

; CHECK-RELOC: R_MORELLO_TLSDESC_ADR_PAGE20
; CHECK-RELOC: R_MORELLO_TLSDESC_LD128_LO12
; CHECK-RELOC: R_AARCH64_TLSDESC_ADD_LO12
; CHECK-RELOC: R_MORELLO_TLSDESC_CALL
}

define i32 addrspace(200)* @test_generaldynamic_addr() {
; CHECK-LABEL: test_generaldynamic_addr:

  ret i32 addrspace(200)* @general_dynamic_var

; CHECK: mrs c2, CTPIDR_EL0
; CHECK: nop
; CHECK-NEXT: adrp c0, :tlsdesc:general_dynamic_var
; CHECK-NEXT: ldr c1, [c0, :tlsdesc_lo12:general_dynamic_var]
; CHECK-NEXT: add c0, c0, :tlsdesc_lo12:general_dynamic_var
; CHECK-NEXT: .tlsdesccall general_dynamic_var
; CHECK-NEXT: blr c1
; CHECK: scbnds	c[[ADDR:[0-9]+]], c0, x1

; CHECK-RELOC: R_MORELLO_TLSDESC_ADR_PAGE20
; CHECK-RELOC: R_MORELLO_TLSDESC_LD128_LO12
; CHECK-RELOC: R_AARCH64_TLSDESC_ADD_LO12
; CHECK-RELOC: R_MORELLO_TLSDESC_CALL
}

@local_dynamic_var = external thread_local(localdynamic) addrspace(200) global i32

; For now we're using general dynamic for local dynamic as well.
define i32 @test_localdynamic() {
; CHECK-LABEL: test_localdynamic:
; CHECK-ASM-LABEL: <test_localdynamic>:

  %val = load i32, i32 addrspace(200)* @local_dynamic_var
  ret i32 %val

; CHECK: mrs c2, CTPIDR_EL0
; CHECK: nop
; CHECK-NEXT: adrp c0, :tlsdesc:local_dynamic_var
; CHECK-NEXT: ldr c1, [c0, :tlsdesc_lo12:local_dynamic_var]
; CHECK-NEXT: add c0, c0, :tlsdesc_lo12:local_dynamic_var
; CHECK-NEXT: .tlsdesccall local_dynamic_var
; CHECK-NEXT: blr c1
; CHECK: scbnds	c[[ADDR:[0-9]+]], c0, x1
; CHECK: ldr w0, [c[[ADDR]]]

; CHECK-RELOC: R_MORELLO_TLSDESC_ADR_PAGE20
; CHECK-RELOC: R_MORELLO_TLSDESC_LD128_LO12
; CHECK-RELOC: R_AARCH64_TLSDESC_ADD_LO12
; CHECK-RELOC: R_MORELLO_TLSDESC_CALL

; CHECK-ASM: mrs c2, CTPIDR_EL0
; CHECK-ASM: nop
; CHECK-ASM-NEXT: adrp c0, #0
; CHECK-ASM-NEXT: ldr c1, [c0, #0]
; CHECK-ASM-NEXT: add c0, c0, #0
; CHECK-ASM-NEXT: blr c1
}

define i32 addrspace(200)* @test_localdynamic_addr() {
; CHECK-LABEL: test_localdynamic_addr:
; CHECK: mrs c2, CTPIDR_EL0
; CHECK: nop
; CHECK-NEXT: adrp c0, :tlsdesc:local_dynamic_var
; CHECK-NEXT: ldr c1, [c0, :tlsdesc_lo12:local_dynamic_var]
; CHECK-NEXT: add c0, c0, :tlsdesc_lo12:local_dynamic_var
; CHECK-NEXT: .tlsdesccall local_dynamic_var
; CHECK-NEXT: blr c1
; CHECK: scbnds	c[[ADDR:[0-9]+]], c0, x1

 ret i32 addrspace(200)* @local_dynamic_var

; CHECK-RELOC: R_MORELLO_TLSDESC_ADR_PAGE20
; CHECK-RELOC: R_MORELLO_TLSDESC_LD128_LO12
; CHECK-RELOC: R_AARCH64_TLSDESC_ADD_LO12
; CHECK-RELOC: R_MORELLO_TLSDESC_CALL
}

; We don't support the local dynamic model yet so don't attemp to
; deduplicate this just yet.

@local_dynamic_var2 = external thread_local(localdynamic) addrspace(200) global i32

define i32 @test_localdynamic_deduplicate() {
; CHECK-LABEL: test_localdynamic_deduplicate:

  %val = load i32, i32 addrspace(200)* @local_dynamic_var
  %val2 = load i32, i32 addrspace(200)* @local_dynamic_var2

  %sum = add i32 %val, %val2
  ret i32 %sum

; CHECK: mrs c2, CTPIDR_EL0
; CHECK: nop
; CHECK-NEXT: adrp c0, :tlsdesc:local_dynamic_var
; CHECK-NEXT: ldr c1, [c0, :tlsdesc_lo12:local_dynamic_var]
; CHECK-NEXT: add c0, c0, :tlsdesc_lo12:local_dynamic_var
; CHECK-NEXT: .tlsdesccall local_dynamic_var
; CHECK-NEXT: blr c1
; CHECK: scbnds	c[[ADDR:[0-9]+]], c0, x1
; CHECK: ldr w{{.*}}, [c[[ADDR]]]

; CHECK: nop
; CHECK-NEXT: adrp c0, :tlsdesc:local_dynamic_var2
; CHECK-NEXT: ldr c1, [c0, :tlsdesc_lo12:local_dynamic_var2]
; CHECK-NEXT: add c0, c0, :tlsdesc_lo12:local_dynamic_var2
; CHECK-NEXT: .tlsdesccall local_dynamic_var2
; CHECK-NEXT: blr c1
; CHECK: scbnds	c[[ADDR:[0-9]+]], c0, x1
; CHECK: ldr w{{.*}}, [c[[ADDR]]]
}
