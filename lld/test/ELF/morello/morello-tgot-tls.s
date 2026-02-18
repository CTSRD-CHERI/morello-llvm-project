// REQUIRES: aarch64
// RUN: echo '.tbss; .globl evar; evar: .zero 4' > %t.s

// RUN: llvm-mc -triple=aarch64 -mattr=+c64,+morello -target-abi purecap \
// RUN:   -cheri-tgot-tls -filetype=obj %t.s -o %t1.o
// RUN: ld.lld -shared -soname=t1.so %t1.o -o %t1.so

// RUN: llvm-mc -triple=aarch64 -mattr=+c64,+morello -target-abi purecap \
// RUN:   --defsym LE=1 -cheri-tgot-tls -filetype=obj %s -o %t.o
// RUN: ld.lld %t.o %t1.so -o %t
// RUN: llvm-readobj -r %t | FileCheck --check-prefix=REL %s
// RUN: llvm-readelf -x .tgot %t | FileCheck --check-prefix=GOT %s
// RUN: llvm-objdump -d --no-show-raw-insn %t | FileCheck --check-prefix=DIS %s

// RUN: llvm-mc -triple=aarch64 -mattr=+c64,+morello -target-abi purecap \
// RUN:   --defsym LE=0 -cheri-tgot-tls -filetype=obj %s -o %t.pico
// RUN: ld.lld -shared %t.pico %t1.so -o %t.so
// RUN: llvm-readobj -r %t.so | FileCheck --check-prefix=SO-REL %s
// RUN: llvm-readelf -x .got -x .tgot %t.so | FileCheck --check-prefix=SO-GOT %s
// RUN: llvm-objdump -d --no-show-raw-insn %t.so | FileCheck --check-prefix=SO-DIS %s

// RUN: llvm-mc -triple=aarch64 -mattr=+c64,+morello,+morello-tgot-tls-compat -target-abi purecap \
// RUN:   --defsym LE=0 -cheri-tgot-tls -filetype=obj %s -o %t.compat.o
// RUN: ld.lld %t.compat.o %t1.so -o %t.compat
// RUN: llvm-readobj -r %t.compat | FileCheck --check-prefix=COMPAT-REL %s
// RUN: llvm-readelf -x .got -x .tgot %t.compat | FileCheck --check-prefix=COMPAT-GOT %s
// RUN: llvm-objdump -d --no-show-raw-insn %t.compat | FileCheck --check-prefix=COMPAT-DIS %s

// REL:      .rela.tgot {
// REL-NEXT:   0x200390 R_MORELLO_TLS_TGOT_SLOT evar 0x0
// REL-NEXT:   0x2003A0 R_MORELLO_TLS_TGOT_SLOT - 0x0
// REL-NEXT: }

// SO-REL:      .rela.dyn {
// SO-REL-NEXT:   0x20470 R_MORELLO_TLS_TGOTREL64 - 0x0
// SO-REL-NEXT:   0x20480 R_MORELLO_TGOT_TLSDESC - 0x0
// SO-REL-NEXT:   0x204A0 R_MORELLO_TLS_TGOTREL64 - 0x10
// SO-REL-NEXT:   0x204B0 R_MORELLO_TGOT_TLSDESC - 0x10
// SO-REL-NEXT: }
// SO-REL:      .rela.tgot {
// SO-REL-NEXT:   0x420 R_MORELLO_TLS_TGOT_SLOT evar 0x0
// SO-REL-NEXT:   0x430 R_MORELLO_TLS_TGOT_SLOT - 0x0
// SO-REL-NEXT: }

// COMPAT-REL:      .rela.dyn {
// COMPAT-REL-NEXT:   0x220410 R_MORELLO_TLS_TGOTREL64 - 0x0
// COMPAT-REL-NEXT:   0x220420 R_MORELLO_TLS_TGOTREL64 - 0x10
// COMPAT-REL-NEXT: }
// COMPAT-REL:      .rela.tgot {
// COMPAT-REL-NEXT:   0x2003C0 R_MORELLO_TLS_TGOT_SLOT evar 0x0
// COMPAT-REL-NEXT:   0x2003D0 R_MORELLO_TLS_TGOT_SLOT - 0x0
// COMPAT-REL-NEXT: }

// GOT: section '.tgot':
// GOT-NEXT: 0x00200390 00000000 00000000 00000000 00000000
/// lval: address: 0x4, size = 4, perms = RW (0x2)
// GOT-NEXT: 0x002003a0 04000000 00000000 04000000 00000002

// SO-GOT: section '.tgot':
// SO-GOT-NEXT: 0x00000420 00000000 00000000 00000000 00000000
/// lval: address: 0x4, size = 4, perms = RW (0x2)
// SO-GOT-NEXT: 0x00000430 04000000 00000000 04000000 00000002
// SO-GOT: section '.got':
// SO-GOT-NEXT: 0x00020470 00000000 00000000 00000000 00000000
// SO-GOT-NEXT: 0x00020480 00000000 00000000 00000000 00000000
// SO-GOT-NEXT: 0x00020490 00000000 00000000 00000000 00000000
// SO-GOT-NEXT: 0x000204a0 00000000 00000000 00000000 00000000
// SO-GOT-NEXT: 0x000204b0 00000000 00000000 00000000 00000000
// SO-GOT-NEXT: 0x000204c0 00000000 00000000 00000000 00000000

// COMPAT-GOT: section '.tgot':
// COMPAT-GOT-NEXT: 0x002003c0 00000000 00000000 00000000 00000000
/// lval: address: 0x4, size = 4, perms = RW (0x2)
// COMPAT-GOT-NEXT: 0x002003d0 04000000 00000000 04000000 00000002
// COMPAT-GOT: section '.got':
// COMPAT-GOT-NEXT: 0x00220410 00000000 00000000 00000000 00000000
// COMPAT-GOT-NEXT: 0x00220420 00000000 00000000 00000000 00000000

/// TGOTREL(eval) = 0x20
// DIS:      2103b0: movz x0, #0x0, lsl #16
// DIS-NEXT:         movk x0, #0x20
// DIS-NEXT:         ldr c0, [c1, x0]
// DIS-NEXT:         nop

/// TGOTREL(eval) = 0x20
// DIS:      2103c0: movz x0, #0x0, lsl #16
// DIS-NEXT:         movk x0, #0x20

/// TGOTREL(lval) = 0x30
// DIS:      2103c8: movz x0, #0x0, lsl #16
// DIS-NEXT:         movk x0, #0x30
// DIS-NEXT:         ldr c0, [c1, x0]
// DIS-NEXT:         nop

/// TGOTREL(lval) = 0x30
// DIS:      2103d8: movz x0, #0x0, lsl #16
// DIS-NEXT:         movk x0, #0x30

/// TGOTREL(lval) = 0x30
// DIS:      2103e0: ldr c0, [c0, #0x30]

/// TGOTREL(lval) = 0x30
// DIS:      2103e4: add c0, c0, #0x0, lsl #12
// DIS-NEXT:         ldr c0, [c0, #0x30]

/// TGOTREL(lval) = 0x30
// DIS:      2103ec: mov x0, #0x30

/// TGOTREL(lval) = 0x30
// DIS:      2103f0: movz x0, #0x0, lsl #16
// DIS-NEXT:         movk x0, #0x30

/// GTLSDESC(evar) = 0x20480
// SO-DIS:      10440: adrp c0, 0x20000
// SO-DIS-NEXT:        ldr c2, [c0, #0x480]
// SO-DIS-NEXT:        add c0, c0, #0x480
// SO-DIS-NEXT:        blr c2

/// GTGOTREL(evar) = 0x20470
// SO-DIS:      10450: adrp c0, 0x20000
// SO-DIS-NEXT:        ldr x0, [c0, #0x470]

/// GTLSDESC(lvar) = 0x204b0
// SO-DIS:      10458: adrp c0, 0x20000
// SO-DIS-NEXT:        ldr c2, [c0, #0x4b0]
// SO-DIS-NEXT:        add c0, c0, #0x4b0
// SO-DIS-NEXT:        blr c2

/// GTGOTREL(lvar) = 0x204a0
// SO-DIS:      10468: adrp c0, 0x20000
// SO-DIS-NEXT:        ldr x0, [c0, #0x4a0]

/// GTGOTREL(evar) = 0x220410
// COMPAT-DIS:      2103e0: adrp c0, 0x220000
// COMPAT-DIS-NEXT:         ldr x0, [c0, #0x410]
// COMPAT-DIS-NEXT:         ldr c0, [c1, x0]
// COMPAT-DIS-NEXT:         nop

/// GTGOTREL(evar) = 0x220410
// COMPAT-DIS:      2103f0: adrp c0, 0x220000
// COMPAT-DIS-NEXT:         ldr x0, [c0, #0x410]

/// GTGOTREL(lvar) = 0x220420
// COMPAT-DIS:      2103f8: adrp c0, 0x220000
// COMPAT-DIS-NEXT:         ldr x0, [c0, #0x420]
// COMPAT-DIS-NEXT:         ldr c0, [c1, x0]
// COMPAT-DIS-NEXT:         nop

/// GTGOTREL(lvar) = 0x220420
// COMPAT-DIS:      210408: adrp c0, 0x220000
// COMPAT-DIS-NEXT:         ldr x0, [c0, #0x420]

.global _start
_start:
	adrp c0, :tgot_tlsdesc:evar
	ldr c2, [c0, :tgot_tlsdesc_lo12:evar]
	add c0, c0, :tgot_tlsdesc_lo12:evar
	.tgot_tlsdesccall evar
	blr c2

	adrp c0, :gottgot:evar
	ldr x0, [c0, :gottgot_lo12:evar]

	adrp c0, :tgot_tlsdesc:lvar
	ldr c2, [c0, :tgot_tlsdesc_lo12:lvar]
	add c0, c0, :tgot_tlsdesc_lo12:lvar
	.tgot_tlsdesccall lvar
	blr c2

	adrp c0, :gottgot:lvar
	ldr x0, [c0, :gottgot_lo12:lvar]

.if LE == 1
	ldr c0, [c0, :tgot_lo12:lvar]

	add c0, c0, #:tgot:lvar, lsl #12
	ldr c0, [c0, :tgot_lo12_nc:lvar]

	movz x0, #:tgot_g0:lvar

	movz x0, #:tgot_g1:lvar
	movk x0, #:tgot_g0_nc:lvar
.endif

.tbss
	.zero 4
lvar:
	.zero 4
	.size lvar, . - lvar
