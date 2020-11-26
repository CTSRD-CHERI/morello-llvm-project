// RUN: llvm-mc -triple=arm64 -mattr=+morello,+c64 -target-abi purecap -cheri-cap-table-abi=fn-desc %s -o - -filetype=obj | llvm-readobj -r | FileCheck %s --check-prefix=RELOCS
// RUN: llvm-mc -triple=arm64 -mattr=+morello,+c64 -target-abi purecap -cheri-cap-table-abi=fn-desc %s -show-encoding -o - | FileCheck %s --check-prefix=ASM

// RELOCS:  Section (3) .rela.text {
// RELOCS:    0x0 R_MORELLO_DESC_ADR_PREL_PG_HI20 foo 0xC
// RELOCS:    0x4 R_MORELLO_DESC_ADR_GOT_PAGE foo 0x0
// RELOCS:    0x8 R_MORELLO_DESC_LD128_GOT_LO12_NC foo 0x0
// RELOCS:    0xC R_MORELLO_TLSDESC_ADR_PAGE20 var 0x0
// RELOCS:    0x10 R_MORELLO_TLSDESC_LD128_LO12 tlsvar 0x0
// RELOCS:    0x14 R_AARCH64_TLSDESC_ADD_LO12 tlsvar 0x0
// RELOCS:    0x18 R_MORELLO_DESC_TCALL bar 0x0
// RELOCS:    0x1C R_MORELLO_DESC_CALL bar 0x0
// RELOCS:    0x20 R_MORELLO_DESC_TCALL .text 0x18
// RELOCS:    0x24 R_MORELLO_DESC_CALL .text 0x18
// RELOCS:  }
// RELOCS:  Section (5) .rela.data {
// RELOCS:    0x10 R_MORELLO_DESC_CAPINIT str 0x8
// RELOCS:    0x20 R_MORELLO_DESC_CAPINIT str 0x0
// RELOCS:  }

// ASM:      adrp	c0, foo+12              // encoding: [A,A,0x80'A',0x90'A']
// ASM-NEXT:   //   fixup A - offset: 0, value: foo+12, kind: fixup_aarch64_pcrel_adrp_imm20
// ASM-NEXT: adrp	c0, :got:foo            // encoding: [A,A,0x80'A',0x90'A']
// ASM-NEXT:   //  fixup A - offset: 0, value: :got:foo, kind: fixup_aarch64_pcrel_adrp_imm20
// ASM-NEXT: ldr	c0, [c0, :got_lo12:foo] // encoding: [0x00,0bAAAAAA00,0b01AAAAAA,0xc2]
// ASM-NEXT:   //   fixup A - offset: 0, value: :got_lo12:foo, kind: fixup_aarch64_ldst_imm12_scale16
// ASM-NEXT: adrp	c0, :tlsdesc:var        // encoding: [A,A,0x80'A',0x90'A']
// ASM-NEXT:   //   fixup A - offset: 0, value: :tlsdesc:var, kind: fixup_aarch64_pcrel_adrp_imm20
// ASM-NEXT: ldr	c1, [c0, :tlsdesc_lo12:tlsvar] // encoding: [0x01,0bAAAAAA00,0b01AAAAAA,0xc2]
// ASM-NEXT:   //   fixup A - offset: 0, value: :tlsdesc_lo12:tlsvar, kind: fixup_aarch64_ldst_imm12_scale16
// ASM-NEXT: add	c0, c0, :tlsdesc_lo12:tlsvar // encoding: [0x00,0bAAAAAA00,0b00AAAAAA,0x02]
// ASM-NEXT:   //   fixup A - offset: 0, value: :tlsdesc_lo12:tlsvar, kind: fixup_aarch64_add_imm12
// ASM-LABEL: baz:
// ASM-NEXT: .desctcall bar                  // encoding: []
// ASM-NEXT:   //   fixup A - offset: 0, value: bar, kind: fixup_morello_desc_tcall
// ASM:      .desccall bar                   // encoding: []
// ASM-NEXT:   //   fixup A - offset: 0, value: bar, kind: fixup_morello_desc_call
// ASM:      .desctcall baz                  // encoding: []
// ASM-NEXT:   //   fixup A - offset: 0, value: baz, kind: fixup_morello_desc_tcall
// ASM:      .desccall baz                   // encoding: []
// ASM-NEXT:   //   fixup A - offset: 0, value: baz, kind: fixup_morello_desc_call

        adrp c0, foo+12
        adrp c0, :got:foo
        ldr c0, [c0, :got_lo12:foo]
        adrp  c0, :tlsdesc:var
        ldr   c1, [c0, #:tlsdesc_lo12:tlsvar]
        add   c0, c0, #:tlsdesc_lo12:tlsvar
baz:
        .desccall bar
        add c0, c0, #1
        .desctcall bar
        add c0, c0, #1
        .desccall baz
        add c0, c0, #1
        .desctcall baz
        add c0, c0, #1


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
	.capinit str+8
	.xword	0
	.xword	0
	.size	ptr1, 16

	.type	ptr2,@object
	.globl	ptr2
	.p2align	4
ptr2:
	.capinit str
	.xword	0
	.xword	0
	.size	ptr2, 16

	.type	.L.str,@object
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"%d\n"
	.size	.L.str, 4
