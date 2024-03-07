; RUN: llc -march=arm64 -mattr=+c64,+morello,+use-16-cap-regs -target-abi purecap -o - %s | FileCheck %s --check-prefix=PCS16
; RUN: llc -march=arm64 -mattr=+c64,+morello -target-abi purecap -o - %s | FileCheck %s --check-prefix=PCS32

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none-unknown-elf"

; PCS16-LABEL: foo
; PCS32-LABEL: foo
define dso_local void @foo(i8 addrspace(200)* nocapture readnone %bb, i8 addrspace(200)* %cc) local_unnamed_addr addrspace(200) #0 {
entry:
  call void asm sideeffect "", "~{x19},~{x20},~{x21},~{x22},~{x23},~{x24},~{x25},~{x26},~{x27},~{x28},~{d8},~{d9},~{d10},~{d11},~{d12},~{d13},~{d14},~{d15}"() nounwind
  ret void
}

; PCS16:	stp	d15, d14, [csp, #-192]! // 16-byte Folded Spill
; PCS16-NEXT:	.cfi_def_cfa_offset 192
; PCS16-NEXT:	stp	d13, d12, [csp, #16]    // 16-byte Folded Spill
; PCS16-NEXT:	str	c28, [csp, #64]         // 16-byte Folded Spill
; PCS16-NEXT:	stp	d11, d10, [csp, #32]    // 16-byte Folded Spill
; PCS16-NEXT:	stp	c27, c26, [csp, #80]    // 32-byte Folded Spill
; PCS16-NEXT:	stp	d9, d8, [csp, #48]      // 16-byte Folded Spill
; PCS16-NEXT:	stp	c25, c24, [csp, #112]   // 32-byte Folded Spill
; PCS16-NEXT:	str	x23, [csp, #144]        // 8-byte Folded Spill
; PCS16-NEXT:	stp	x22, x21, [csp, #160]   // 16-byte Folded Spill
; PCS16-NEXT:	stp	x20, x19, [csp, #176]   // 16-byte Folded Spill

; PCS16:	ldp	x20, x19, [csp, #176]   // 16-byte Folded Reload
; PCS16-NEXT:	ldp	c25, c24, [csp, #112]   // 32-byte Folded Reload
; PCS16-NEXT:	ldp	c27, c26, [csp, #80]    // 32-byte Folded Reload
; PCS16-NEXT:	ldp	x22, x21, [csp, #160]   // 16-byte Folded Reload
; PCS16-NEXT:	ldr	c28, [csp, #64]         // 16-byte Folded Reload
; PCS16-NEXT:	ldp	d9, d8, [csp, #48]      // 16-byte Folded Reload
; PCS16-NEXT:	ldp	d11, d10, [csp, #32]    // 16-byte Folded Reload
; PCS16-NEXT:	ldp	d13, d12, [csp, #16]    // 16-byte Folded Reload
; PCS16-NEXT:	ldr	x23, [csp, #144]        // 8-byte Folded Reload
; PCS16-NEXT:	ldp	d15, d14, [csp], #192   // 16-byte Folded Reload

; PCS32:	stp	d15, d14, [csp, #-224]! // 16-byte Folded Spill
; PCS32-NEXT:	.cfi_def_cfa_offset 224
; PCS32-NEXT:	stp	d13, d12, [csp, #16]    // 16-byte Folded Spill
; PCS32-NEXT:	stp	c28, c27, [csp, #64]    // 32-byte Folded Spill
; PCS32-NEXT:	stp	d11, d10, [csp, #32]    // 16-byte Folded Spill
; PCS32-NEXT:	stp	c26, c25, [csp, #96]    // 32-byte Folded Spill
; PCS32-NEXT:	stp	d9, d8, [csp, #48]      // 16-byte Folded Spill
; PCS32-NEXT:	stp	c24, c23, [csp, #128]   // 32-byte Folded Spill
; PCS32-NEXT:	stp	c22, c21, [csp, #160]   // 32-byte Folded Spill
; PCS32-NEXT:	stp	c20, c19, [csp, #192]   // 32-byte Folded Spill

; PCS32:	ldp	d9, d8, [csp, #48]      // 16-byte Folded Reload
; PCS32-NEXT:	ldp	c20, c19, [csp, #192]   // 32-byte Folded Reload
; PCS32-NEXT: 	ldp	c22, c21, [csp, #160]   // 32-byte Folded Reload
; PCS32-NEXT:	ldp	d11, d10, [csp, #32]    // 16-byte Folded Reload
; PCS32-NEXT:	ldp	c24, c23, [csp, #128]   // 32-byte Folded Reload
; PCS32-NEXT:	ldp	c26, c25, [csp, #96]    // 32-byte Folded Reload
; PCS32-NEXT:	ldp	d13, d12, [csp, #16]    // 16-byte Folded Reload
; PCS32-NEXT:	ldp	c28, c27, [csp, #64]    // 32-byte Folded Reload
; PCS32-NEXT:	ldp	d15, d14, [csp], #224   // 16-byte Folded Reload


; Make sure we don't emit ldr	d14, [csp], #256.
; PCS32-LABEL: bar
; PCS32:	str	d14, [csp, #-256]!      // 8-byte Folded Spill
; PCS32-NEXT:   .cfi_def_cfa_offset 256
; PCS32-NEXT:   stp	d13, d12, [csp, #16]    // 16-byte Folded Spill
; PCS32-NEXT:   stp	c29, c30, [csp, #64]    // 32-byte Folded Spill
; PCS32-NEXT:   stp	d11, d10, [csp, #32]    // 16-byte Folded Spill
; PCS32-NEXT:   stp	c28, c27, [csp, #96]    // 32-byte Folded Spill
; PCS32-NEXT:   stp	d9, d8, [csp, #48]      // 16-byte Folded Spill
; PCS32-NEXT:   stp	c26, c25, [csp, #128]   // 32-byte Folded Spill
; PCS32-NEXT:   stp	c24, c23, [csp, #160]   // 32-byte Folded Spill
; PCS32-NEXT:   stp	c22, c21, [csp, #192]   // 32-byte Folded Spill
; PCS32-NEXT:   stp	c20, c19, [csp, #224]   // 32-byte Folded Spill

; PCS32:        ldp	d9, d8, [csp, #48]      // 16-byte Folded Reload
; PCS32-NEXT:   ldp	c20, c19, [csp, #224]   // 32-byte Folded Reload
; PCS32-NEXT:   ldp	c22, c21, [csp, #192]   // 32-byte Folded Reload
; PCS32-NEXT:   ldp	d11, d10, [csp, #32]    // 16-byte Folded Reload
; PCS32-NEXT:   ldp	c24, c23, [csp, #160]   // 32-byte Folded Reload
; PCS32-NEXT:   ldp	c26, c25, [csp, #128]   // 32-byte Folded Reload
; PCS32-NEXT:   ldp	d13, d12, [csp, #16]    // 16-byte Folded Reload
; PCS32-NEXT:   ldp	c28, c27, [csp, #96]    // 32-byte Folded Reload
; PCS32-NEXT:   ldp	c29, c30, [csp, #64]    // 32-byte Folded Reload
; PCS32-NEXT:   ldr	d14, [csp]              // 8-byte Folded Reload
; PCS32-NEXT:   add	csp, csp, #256
define dso_local void @bar(i8 addrspace(200)* nocapture readnone %bb, i8 addrspace(200)* %cc) local_unnamed_addr addrspace(200) #0 {
entry:
  %a = alloca [300 x i32], align 4, addrspace(200)
  call void asm sideeffect "", "~{x19},~{x20},~{x21},~{x22},~{x23},~{x24},~{x25},~{x26},~{x27},~{x28},~{d8},~{d9},~{d10},~{d11},~{d12},~{d13},~{d14}"() nounwind
  call void @baz([300 x i32] addrspace(200)* %a)
  call void @baz([300 x i32] addrspace(200)* %a)
  ret void
}

declare void @baz([300 x i32] addrspace(200)*) addrspace(200)
