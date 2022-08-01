// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj --triple=aarch64-none-elf -target-abi purecap -mattr=+c64,+morello %s -o %t.o
// RUN: ld.lld -pie %t.o -o %tpie
// RUN: llvm-readelf --dynamic --relocs -x .got -x .data %tpie | FileCheck %s -check-prefix=PIE -check-prefix=FRAGS
// RUN: ld.lld -shared %t.o -o %tshared
// RUN: llvm-readelf --dynamic --relocs -x .got -x .data %tshared | FileCheck %s -check-prefix=SHARED -check-prefix=FRAGS

    .weak   hiddensym
    .hidden hiddensym

    .data
    .chericap hiddensym

    .text
    .globl  _start
_start:
    adrp  c0, :got:hiddensym
    ldr   c0, [c0, #:got_lo12:hiddensym]
    ret

// PIE: There are no relocations in this file.
// PIE-NOT: (RELACOUNT)
// SHARED: (RELACOUNT) 2
// SHARED: Relocation section '.rela.dyn' {{.*}} contains 2 entries:
// SHARED: {{.*}}  R_MORELLO_RELATIVE                0
// SHARED-NEXT: {{.*}}  R_MORELLO_RELATIVE                0

// FRAGS: Hex dump of section '.got':
// FRAGS-NEXT: {{.*}} 00000000 00000000 00000000 00000002

// FRAGS: Hex dump of section '.data':
// FRAGS-NEXT: {{.*}} 00000000 00000000 00000000 00000002
