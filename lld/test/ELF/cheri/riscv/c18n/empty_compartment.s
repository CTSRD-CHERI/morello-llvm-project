# REQUIRES: riscv
# RUN: split-file %s %t

# RUN: %riscv64_cheri_purecap_llvm-mc -filetype=obj %t/one.s -o %t/one.o
# RUN: %riscv64_cheri_purecap_llvm-mc -filetype=obj %t/two.s -o %t/two.o
# RUN: not ld.lld --shared --compartment-policy=%t/compartments.json %t/one.o -o %t/empty.so.0 2>&1 | FileCheck %s
# RUN: not ld.lld --shared --compartment-policy=%t/compartments.json %t/two.o -o %t/empty.so.0 2>&1 | FileCheck %s

# CHECK: ld.lld: error: no output sections for compartment two

#--- one.s

	.text
	.global	foo
	.type	foo, @function
foo:
	ret
	.size	foo, . - foo

#--- two.s

	.text
	.global	foo
	.type	foo, @function
foo:
	cllc	ct0, .Lfoo_str
	ret
	.size	foo, . - foo

	.section .rodata.str.1.1,"aMS",@progbits,1
.Lfoo_str:
	.asciz	"foo like grapes"
	.size	.Lfoo_str, . - .Lfoo_str

#--- compartments.json

{
    "compartments": {
	"one": { "symbols": ["foo"] },
	"two": { "symbols": ["bar"] }
    }
}
