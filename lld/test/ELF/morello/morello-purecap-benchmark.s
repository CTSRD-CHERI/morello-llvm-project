// REQUIRES: aarch64
// RUN: split-file %s %t

// RUN: llvm-mc -filetype=obj -triple=aarch64 -mattr=+morello,+c64 -target-abi=purecap-benchmark %t/lib.s -o %t/lib.o
// RUN: ld.lld -shared -soname=lib.so %t/lib.o -o %t/lib.so
// RUN: llvm-mc -filetype=obj -triple=aarch64 -mattr=+morello,+c64 -target-abi=purecap-benchmark %t/prog.s -o %t/prog.o
// RUN: ld.lld %t/prog.o %t/lib.so -o %t/prog
// RUN: llvm-objdump --no-show-raw-insn -d %t/prog | FileCheck --check-prefix=DISAS %s
// RUN: llvm-objdump -s -j .got.plt %t/prog | FileCheck --check-prefix=GOTPLT %s
// RUN: llvm-readobj -r %t/prog | FileCheck %s --check-prefix=RELOC

// DISAS:      <_start>:
// DISAS-NEXT:         bl   0x210340

// DISAS:      <.plt>:
// DISAS-NEXT: 210320: stp  c16, c30, [csp, #-0x20]!
// DISAS-NEXT:         adrp c16, 0x230000
// DISAS-NEXT:         ldr  c17, [c16, #0x440]
// DISAS-NEXT:         add  c16, c16, #0x440
// DISAS-NEXT:         br   x17
// DISAS-NEXT:         nop
// DISAS-NEXT:         nop
// DISAS-NEXT:         nop

// DISAS:      <foo@plt>:
// DISAS-NEXT: 210340: adrp c16, 0x230000
// DISAS-NEXT:         add  c16, c16, #0x450
// DISAS-NEXT:         ldr  c17, [c16, #0x0]
// DISAS-NEXT:         br   x17

// GOTPLT: Contents of section .got.plt:
// GOTPLT-NEXT: 230420 00000000 00000000 00000000 00000000
// GOTPLT-NEXT: 230430 00000000 00000000 00000000 00000000
// GOTPLT-NEXT: 230440 00000000 00000000 00000000 00000000
// GOTPLT-NEXT: 230450 40022000 00000000 40020300 00000004

// RELOC:      .rela.plt {
/// LSB 0 despite being C64
// RELOC-NEXT:   0x230450 R_MORELLO_JUMP_SLOT foo 0x100E0
// RELOC-NEXT: }

//--- lib.s
	.global	foo
	.type	foo, @function
foo:
	and	x30, x30, #~1
	ret	x30
	.size	foo, . - foo

//--- prog.s
	.global	_start
	.type	_start, @function
_start:
	bl foo
	.size	_start, . - _start
