// RUN: llvm-mc -triple=arm64 -mattr=+morello %s -o - -filetype=obj | llvm-readobj -r - | FileCheck %s

// CHECK: Relocations [
// CHECK:  Section (4) .rela.data {
// CHECK:    0x10 R_MORELLO_CAPINIT str 0x8
// CHECK:    0x20 R_MORELLO_CAPINIT str 0x0
// CHECK:  }
// CHECK: ]

	.type	str,@object
	.data
	.globl	str
str:
	.asciz	"foo bar baz"
	.size	str, 12

	.type	ptr1,@object
	.globl	ptr1
	.p2align	4
ptr1:
	.chericap str+8
	.size	ptr1, 16

	.type	ptr2,@object
	.globl	ptr2
	.p2align	4
ptr2:
	.chericap str
	.size	ptr2, 16

	.type	.L.str,@object
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"%d\n"
	.size	.L.str, 4
