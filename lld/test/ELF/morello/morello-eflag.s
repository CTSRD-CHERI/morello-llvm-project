// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+morello,+c64 -target-abi purecap -filetype=obj %s -o %t.o
// RUN: ld.lld -m aarch64elf %t.o -o %t
// RUN: llvm-readelf -h %t | FileCheck %s

// XXX should use split-file %s %t
// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+morello,+c64 -filetype=obj %s -o %t_purecap.o
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+morello -filetype=obj %S/Inputs/morello-eflags-hybrid.s -o %t_hybrid.o
// RUN: not ld.lld -m aarch64elf %t_purecap.o %t_hybrid.o -o %t_mixed 2>&1 | FileCheck %s --check-prefix ERROR-MSG

/// Check that the output file has the correct eflags

.text
.globl _start
.type _start, %function
.size _start, 4
_start:
	nop

// CHECK: Flags: 0x10000
// ERROR-MSG: error: {{.+}}tmp_hybrid.o is incompatible with {{.+}}tmp_purecap.o
