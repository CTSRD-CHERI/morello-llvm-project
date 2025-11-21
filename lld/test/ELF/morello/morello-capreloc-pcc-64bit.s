// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=aarch64 %s -o %t.o -mattr=+morello,+c64 -target-abi purecap
// RUN: ld.lld --image-base 0x100000000 %t.o -o %t
// RUN: llvm-readobj --cap-relocs %t | FileCheck %s

/// Check that we can correctly handle PCC's range extending past 2^32

	.text
	.type code_sym, %function
code_sym:
	ret
	.size code_sym, . - code_sym

	.data
	.type code_cap, %object
code_cap:
	.chericap code_sym
	.size code_cap, . - code_cap

// CHECK:      __cap_relocs {
// CHECK-NEXT:   0x100030290 FUNC - 0x100010249 [0x100000200-0x100010260]
// CHECK-NEXT: }
