// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=aarch64 -mattr=+morello,+c64 -target-abi purecap -cheri-cap-table-abi=fn-desc %s -o %t.o
// RUN: ld.lld %t.o -o %t
// RUN: llvm-readelf --sections --section-mapping --program-headers --symbols %t | FileCheck %s -check-prefix PHDRS -check-prefix SEGMENTS -check-prefix SYM  -check-prefix SECHDRS

// SECHDRS: Section Headers:
// SECHDRS: Name              Type            Address          Off    Size  
// SECHDRS:                   NULL            0000000000000000 000000 000000
// SECHDRS: .note.cheri       NOTE            0000000000200240 000240 000018
// SECHDRS: .desc.data        PROGBITS        0000000000200258 000258 000020
// SECHDRS: .other_ro         PROGBITS        0000000000200278 000278 000020
// SECHDRS: .text             PROGBITS        0000000000210298 000298 000000
// SECHDRS: .data.rel.ro      PROGBITS        0000000000220298 000298 000020
// SECHDRS: .desc.data.rel.ro PROGBITS        0000000000230000 010000 000020
// SECHDRS: .preinit_array    PREINIT_ARRAY   0000000000230020 010020 000020
// SECHDRS: .init_array       INIT_ARRAY      0000000000230040 010040 000020
// SECHDRS: .fini_array       FINI_ARRAY      0000000000230060 010060 000020
// SECHDRS: .got              PROGBITS        0000000000230080 010080 000020
// SECHDRS: .got.plt          PROGBITS        00000000002400a0 0100a0 000020
// SECHDRS: .data             PROGBITS        00000000002400c0 0100c0 000040
// SECHDRS: .other_rw         PROGBITS        0000000000240100 010100 000020
// SECHDRS: .bss              NOBITS          0000000000240120 010120 000020


// PHDRS: Program Headers:
// PHDRS:  Type           Offset   VirtAddr           PhysAddr           FileSiz  MemSiz   Flg Align
// PHDRS:  PHDR           0x000040 0x0000000000200040 0x0000000000200040 0x0001f8 0x0001f8 R   0x8
// PHDRS:  LOAD           0x000000 0x0000000000200000 0x0000000000200000 0x000298 0x000298 R   0x10000
// PHDRS:  LOAD           0x000298 0x0000000000220298 0x0000000000220298 0x00fe08 0x00fe08 RW  0x10000
// PHDRS:  LOAD           0x0100a0 0x00000000002400a0 0x00000000002400a0 0x000080 0x0000a0 RW  0x10000
// PHDRS:  GNU_RELRO      0x000298 0x0000000000220298 0x0000000000220298 0x00fe08 0x010d68 R   0x1
// PHDRS:  0x70001000     0x010000 0x0000000000230000 0x0000000000230000 0x000120 0x010140 RW  0x10000
// PHDRS:  GNU_STACK      0x000000 0x0000000000000000 0x0000000000000000 0x000000 0x000000 RW  0x0

// SEGMENTS: Section to Segment mapping:
// SEGMENTS: Segment Sections...
// SEGMENTS: 00
// SEGMENTS: 01     .note.cheri .desc.data .other_ro
// SEGMENTS: 02     .data.rel.ro .desc.data.rel.ro .preinit_array .init_array .fini_array .got
// SEGMENTS: 03     .got.plt .data .other_rw .bss
// SEGMENTS: 04     .data.rel.ro .desc.data.rel.ro .preinit_array .init_array .fini_array .got

/// The PT_MORELLO_DESC segment should start with .desc.data.rel.ro and end with the .got* sections
// SEGMENTS: 05     .desc.data.rel.ro .preinit_array .init_array .fini_array .got .got.plt .data .other_rw .bss

// SEGMENTS: 06
// SEGMENTS: 07     .note.cheri
// SEGMENTS: None   .text .comment .symtab .shstrtab .strtab

// SYM: 0000000000240140     0 NOTYPE  GLOBAL DEFAULT    {{.*}} __desc_end
// SYM: 00000000002400a0     0 NOTYPE  GLOBAL DEFAULT    {{.*}} __desc_ro_end
// SYM: 0000000000230000     0 NOTYPE  GLOBAL DEFAULT    {{.*}} __desc_ro_start
// SYM: 0000000000230000     0 NOTYPE  GLOBAL DEFAULT    {{.*}} __desc_start

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

