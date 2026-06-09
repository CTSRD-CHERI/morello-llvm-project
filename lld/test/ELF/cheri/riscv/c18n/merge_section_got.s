# REQUIRES: riscv
# RUN: split-file %s %t

# RUN: %riscv64_cheri_purecap_llvm-mc -filetype=obj %t/one.s -o %t/one.o
# RUN: ld.lld --shared --compartment-policy=%t/compartments.json %t/one.o -o %t/merge_section_got.so
# RUN: llvm-readelf -t %t/merge_section_got.so | FileCheck --check-prefix=SECTIONS %s
# RUN: llvm-objdump -d --no-show-raw-insn %t/merge_section_got.so | FileCheck --check-prefix=DIS %s
# RUN: llvm-readelf --cap-relocs %t/merge_section_got.so | FileCheck --check-prefix=CAP-RELOCS %s

# SECTIONS-LABEL: Section Headers:
# SECTIONS:         [ 9] .rodata.one
# SECTIONS-NEXT:         PROGBITS        0000000000003570 000570 000010 01   0   0  8
# SECTIONS-NEXT:         [0000000000000032]: ALLOC, MERGE, STRINGS
# SECTIONS-NEXT:    [10] .text.one
# SECTIONS-NEXT:         PROGBITS        0000000000004580 000580 00000c 00   0   0  4
# SECTIONS-NEXT:         [0000000000000006]: ALLOC, EXEC
# SECTIONS-NEXT:    [11] .pad.cheri.pcc.one
# SECTIONS-NEXT:         PROGBITS        000000000000458c 00058c 000004 00   0   0  1
# SECTIONS-NEXT:         [0000000000000006]: ALLOC, EXEC
# SECTIONS-NEXT:    [12] .rodata.two
# SECTIONS-NEXT:         PROGBITS        0000000000005590 000590 000012 01   0   0  16
# SECTIONS-NEXT:         [0000000000000032]: ALLOC, MERGE, STRINGS
# SECTIONS-NEXT:    [13] .text.two
# SECTIONS-NEXT:         PROGBITS        00000000000065a4 0005a4 00000c 00   0   0  4
# SECTIONS-NEXT:         [0000000000000006]: ALLOC, EXEC
# SECTIONS-NEXT:    [14] .got.two
# SECTIONS-NEXT:         PROGBITS        00000000000075b0 0005b0 000020 00   0   0  16
# SECTIONS-NEXT:         [0000000000000003]: WRITE, ALLOC
# SECTIONS-NEXT:    [15] .pad.cheri.pcc.two

# DIS-LABEL: Disassembly of section .text.one:
# DIS:       <foo>:
## .Lfoo_str.one - . = 0x4580 - 0x3570 = 4096*-1 - 16
# DIS-NEXT:  4580:       auipcc  ct0, 1048575
# DIS-NEXT:              cincoffset      ct0, ct0, -16

# DIS-LABEL: Disassembly of section .text.two:
# DIS:       <bar>:
## .Lbar_str.two@got - . = 0x75c0 - 0x65a4 = 4096*1 + 28
# DIS-NEXT:  65a4:       auipcc  ct0, 1
# DIS-NEXT:              lc      ct0, 28(ct0)

# CAP-RELOCS:     Offset             Info         Type        Value
# CAP-RELOCS: 00000000000075c0  4000000000000000 RODATA  0000000000005590 [0000000000005590-00000000000055a2]

#--- one.s

	.section .text.foo,"ax",@progbits
	.p2align 2
	.global	foo
	.type	foo, @function
foo:
	cllc	ct0, .Lfoo_str
	ret
	.size	foo, . - foo

	.section .rodata.str1.1,"aMS",@progbits,1
.Lfoo_str:
	.asciz	"foo like grapes"
	.size	.Lfoo_str, . - .Lfoo_str

	.section .text.bar,"ax",@progbits
	.p2align 2
	.global	bar
	.type	bar, @function
bar:
	clgc	ct0, .Lbar_str
	ret
	.size	bar, . - bar

	.section .rodata.str1.1,"aMS",@progbits,1
.Lbar_str:
	.asciz	"bar likes oranges"
	.size	.Lbar_str, . - .Lbar_str

#--- compartments.json

{
    "compartments": {
	"one": { "symbols": ["foo"] },
	"two": { "symbols": ["bar"] }
    }
}
