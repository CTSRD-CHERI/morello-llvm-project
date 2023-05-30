# REQUIRES: aarch64
# RUN: llvm-mc -filetype=obj -triple=aarch64-unknown-freebsd %s -mattr=+morello,+c64 -target-abi purecap -o %tdso.o
# RUN: ld.lld -shared %tdso.o -o %tdso.so
# RUN: llvm-objdump -s -j .got %tdso.so | FileCheck %s
# RUN: llvm-readobj -r %tdso.so | FileCheck -check-prefix=RELOC %s

# The size of the symbol used for R_MORELLO_TLSDESC is encoded in the
# fragment if it is statically known (the symbol is not in the dynamic
# symbol table).

# CHECK: Contents of section .got:
# CHECK-NEXT: 203b0 00000000 00000000 00000000 00000000  ................
# CHECK-NEXT: 203c0 00000000 00000000 04000000 00000000  ................
# CHECK-NEXT: 203d0 00000000 00000000 00000000 00000000  ................

# RELOC: Relocations [
# RELOC-NEXT:  Section ({{.*}}) .rela.dyn {
# RELOC-NEXT:    0x203B0 R_MORELLO_TLSDESC - 0x0
# RELOC-NEXT:  }
# RELOC-NEXT: ]

        .text
	.globl	getx
	.p2align	2
	.type	getx,@function
getx:
.Lfunc_begin0:
	stp	c29, c30, [csp, #-32]!
	mrs	c2, CTPIDR_EL0
	mov	c29, csp
	adrp	c0, :tlsdesc:value
	ldr	c1, [c0, :tlsdesc_lo12:value]
	add	c0, c0, :tlsdesc_lo12:value
	nop
	.tlsdesccall value
	blr	c1
	ldp	c29, c30, [csp], #32
	ret	c30
.Lfunc_end0:
	.size	getx, .Lfunc_end0-.Lfunc_begin0
	.type	value,@object
	.section	.tbss,"awT",@nobits
	.p2align	2
value:
	.word	0
	.size	value, 4
