// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64 -filetype=obj %s -o %t.o
// RUN: not ld.lld -shared --cheri-codeptr-relocs %t.o -o %t 2>&1 | FileCheck %s --check-prefix=ERROR

 .text
 .globl func
 .type func, %function
 .size func, 4
func:
 ret

 .data
ptr:
 .chericap func@code

// ERROR: error: relocation R_MORELLO_CODE_CAPINIT cannot be used against preemptible symbol 'func'
// ERROR-NEXT: >>> defined in {{.*}}/morello-capinit-codeptr-global-error.s.tmp.o
// ERROR-NEXT: >>> referenced by {{.*}}/morello-capinit-codeptr-global-error.s.tmp.o:(.data+0x0)
