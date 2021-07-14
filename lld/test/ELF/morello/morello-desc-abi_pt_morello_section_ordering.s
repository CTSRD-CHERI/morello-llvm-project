// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=aarch64 -mattr=+morello,+c64 -target-abi purecap -cheri-cap-table-abi=fn-desc %s -o %t.o

/// .got.plt is not RELRO
// RUN: ld.lld %t.o -o %t
// RUN: llvm-readelf --sections --section-mapping --program-headers --symbols %t | FileCheck %s

/// Check case when the .got.plt is RELRO (linked with -z now)
// RUN: ld.lld %t.o -z now -o %tnow
// RUN: llvm-readelf --sections --section-mapping --program-headers --symbols %tnow | FileCheck %s --check-prefix GOTPLT_RELRO

// CHECK: Section Headers:
// CHECK: Name              Type            Address          Off    Size
// CHECK:                   NULL            0000000000000000 000000 000000
// CHECK: .note.cheri       NOTE            0000000000200240 000240 000018
// CHECK: .desc.data        PROGBITS        0000000000200258 000258 000020
// CHECK: .other_ro         PROGBITS        0000000000200278 000278 000020
// CHECK: .text             PROGBITS        0000000000210298 000298 000000
// CHECK: .data.rel.ro      PROGBITS        0000000000220298 000298 000020
// CHECK: .desc.data.rel.ro PROGBITS        0000000000230000 010000 000020
// CHECK: .preinit_array    PREINIT_ARRAY   0000000000230020 010020 000020
// CHECK: .init_array       INIT_ARRAY      0000000000230040 010040 000020
// CHECK: .fini_array       FINI_ARRAY      0000000000230060 010060 000020
// CHECK: .got              PROGBITS        0000000000230080 010080 000020
// CHECK: .got.plt          PROGBITS        00000000002400a0 0100a0 000020
// CHECK: .data             PROGBITS        00000000002400c0 0100c0 000040
// CHECK: .other_rw         PROGBITS        0000000000240100 010100 000020
// CHECK: .bss              NOBITS          0000000000240120 010120 000020


// CHECK: Program Headers:
// CHECK:  Type           Offset   VirtAddr
// CHECK:  GNU_RELRO      {{.*}}   0x0000000000220298
// CHECK:  MORELLO_DESC   {{.*}}   0x0000000000230000

// CHECK: Section to Segment mapping:
// CHECK: Segment Sections...
/// The .got.plt is not in PT_GNU_RELRO
// CHECK: 04     .data.rel.ro .desc.data.rel.ro .preinit_array .init_array .fini_array .got
/// The PT_MORELLO_DESC segment RO region should start with .desc.data.rel.ro and end with the .got* sections
// CHECK: 05     .desc.data.rel.ro .preinit_array .init_array .fini_array .got .got.plt .data .other_rw .bss

// CHECK: 0000000000240140     0 NOTYPE  GLOBAL DEFAULT    {{.*}} __desc_end

/// __desc_ro_end points to end of .got (or start of .data)
// CHECK: 00000000002400a0     0 NOTYPE  GLOBAL DEFAULT    {{.*}} __desc_ro_end
// CHECK: 0000000000230000     0 NOTYPE  GLOBAL DEFAULT    {{.*}} __desc_ro_start
// CHECK: 0000000000230000     0 NOTYPE  GLOBAL DEFAULT    {{.*}} __desc_start


// GOTPLT_RELRO: Section Headers:
// GOTPLT_RELRO: Name              Type            Address          Off    Size
// GOTPLT_RELRO: .desc.data.rel.ro PROGBITS        0000000000230000 {{.*}} 000020
// GOTPLT_RELRO: .got.plt          PROGBITS        0000000000230020 {{.*}} 000020
// GOTPLT_RELRO: .preinit_array    PREINIT_ARRAY   0000000000230040 {{.*}} 000020
// GOTPLT_RELRO: .init_array       INIT_ARRAY      0000000000230060 {{.*}} 000020
// GOTPLT_RELRO: .fini_array       FINI_ARRAY      0000000000230080 {{.*}} 000020
// GOTPLT_RELRO: .got              PROGBITS        00000000002300a0 {{.*}} 000020
// GOTPLT_RELRO: .data             PROGBITS        00000000002400c0 {{.*}} 000040

// GOTPLT_RELRO: Program Headers:
// GOTPLT_RELRO:  Type           Offset   VirtAddr
// GOTPLT_RELRO:  GNU_RELRO      {{.*}}   0x0000000000220298
// GOTPLT_RELRO:  MORELLO_DESC   {{.*}}   0x0000000000230000

// GOTPLT_RELRO: Section to Segment mapping:

/// The .got.plt is in PT_GNU_RELRO
// GOTPLT_RELRO:  04     .data.rel.ro .desc.data.rel.ro .got.plt .preinit_array .init_array .fini_array .got

/// The PT_MORELLO_DESC segment RO region should start with .desc.data.rel.ro and end with the .got* sections
// GOTPLT_RELRO:  05     .desc.data.rel.ro .got.plt .preinit_array .init_array .fini_array .got .data .other_rw .bss

// GOTPLT_RELRO: 0000000000240140     0 NOTYPE  GLOBAL DEFAULT    {{.*}} __desc_end

/// __desc_ro_end points to end of .got (or start of .data)
// GOTPLT_RELRO: 00000000002400c0     0 NOTYPE  GLOBAL DEFAULT    {{.*}} __desc_ro_end

// GOTPLT_RELRO: 0000000000230000     0 NOTYPE  GLOBAL DEFAULT    {{.*}} __desc_ro_start
// GOTPLT_RELRO: 0000000000230000     0 NOTYPE  GLOBAL DEFAULT    {{.*}} __desc_start

  .data
  .zero 0x20
  .globl __desc_start
  .globl __desc_end
  .globl __desc_ro_start
  .globl __desc_ro_end
  .xword __desc_start
  .xword __desc_end
  .xword __desc_ro_start
  .xword __desc_ro_end

  .section .desc.data,"a",%progbits
  .zero 0x20

  .section .data.rel.ro,"a",%progbits
  .zero 0x20

  .section .desc.data.rel.ro,"aw",%progbits
  .zero 0x20

  .section .other_ro,"a",%progbits
  .zero 0x20

  .section .preinit_array, "a", %preinit_array
  .zero 0x20

  .section .init_array, "a", %init_array
  .zero 0x20

  .section .fini_array, "a", %fini_array
  .zero 0x20

  .section .got,"aw",%progbits
  .zero 0x20

  .section .got.plt,"aw",%progbits
  .zero 0x20

  .section .other_rw,"aw",%progbits
  .zero 0x20

  .bss
  .zero 0x20

