# REQUIRES: riscv
# RUN: split-file %s %t

# RUN: %riscv64_cheri_purecap_llvm-mc -filetype=obj %t/one.s -o %t/one.o
# RUN: ld.lld --shared --compartment-policy=%t/compartments.json %t/one.o -o %t/shared_merge_sections.so
# RUN: ld.lld --gc-sections --shared --compartment-policy=%t/compartments.json %t/one.o -o %t/shared_merge_sections_gc.so
# RUN: llvm-readelf -t %t/shared_merge_sections.so | FileCheck --check-prefix=SECTIONS %s
# RUN: llvm-readelf -t %t/shared_merge_sections_gc.so | FileCheck --check-prefix=SECTIONS-GC %s
# RUN: llvm-objdump -s -j .rodata.one %t/shared_merge_sections.so | FileCheck --check-prefix=RODATA-ONE %s
# RUN: llvm-objdump -s -j .rodata.two %t/shared_merge_sections.so | FileCheck --check-prefix=RODATA-TWO %s
# RUN: llvm-objdump -s -j .rodata.one %t/shared_merge_sections_gc.so | FileCheck --check-prefix=RODATA-ONE %s
# RUN: llvm-objdump -s -j .rodata.two %t/shared_merge_sections_gc.so | FileCheck --check-prefix=RODATA-TWO %s

## Without --gc-sections, the empty .text is still present
# SECTIONS-LABEL: Section Headers:
# SECTIONS-NOT:   .rodata
# SECTIONS:         [ 8] .rodata.one
# SECTIONS-NEXT:         PROGBITS        00000000000034b8 0004b8 000004 04   0   0  8
# SECTIONS-NEXT:         [0000000000000012]: ALLOC, MERGE
# SECTIONS:         [11] .rodata.two
# SECTIONS-NEXT:         PROGBITS        00000000000054c8 0004c8 000004 04   0   0  8
# SECTIONS-NEXT:         [0000000000000012]: ALLOC, MERGE

# SECTIONS-GC-LABEL: Section Headers:
# SECTIONS-GC-NOT:   .rodata
# SECTIONS-GC:         [ 7] .rodata.one
# SECTIONS-GC-NEXT:         PROGBITS        0000000000002480 000480 000004 04   0   0  8
# SECTIONS-GC-NEXT:         [0000000000000012]: ALLOC, MERGE
# SECTIONS-GC:         [10] .rodata.two
# SECTIONS-GC-NEXT:         PROGBITS        0000000000004490 000490 000004 04   0   0  8
# SECTIONS-GC-NEXT:         [0000000000000012]: ALLOC, MERGE

# RODATA-ONE-LABEL: Contents of section .rodata.one:
# RODATA-ONE-NEXT: 34120000                             4...

# RODATA-TWO-LABEL: Contents of section .rodata.two:
# RODATA-TWO-NEXT: 78560000                             xV..

#--- one.s

	.section .text.foo,"ax",@progbits
	.p2align 2
	.global	foo
	.type	foo, @function
foo:
	cllc	ct0, .Lfoo_data
	ret
	.size	foo, . - foo

	.section .rodata.cst4,"aM",@progbits,4
	.p2align 2
.Lfoo_data:
	.word	0x1234
	.size	.Lfoo_data, . - .Lfoo_data

	.section .text.bar,"ax",@progbits
	.p2align 2
	.global	bar
	.type	bar, @function
bar:
	cllc	ct0, .Lbar_data
	ret
	.size	bar, . - bar

	.section .rodata.cst4,"aM",@progbits,4
	.p2align 2
.Lbar_data:
	.word	0x5678
	.size	.Lbar_data, . - .Lbar_data

#--- compartments.json

{
    "compartments": {
	"one": { "symbols": ["foo"] },
	"two": { "symbols": ["bar"] }
    }
}
