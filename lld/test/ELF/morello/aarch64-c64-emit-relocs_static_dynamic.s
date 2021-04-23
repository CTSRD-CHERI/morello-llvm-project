// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64,+morello -filetype=obj %s -o %t.o
// RUN: ld.lld --morello-static-caps=elf %t.o --emit-relocs -o %t --morello-c64-plt
// RUN: llvm-readobj --relocs --sections --symbols -x .got -x .data.rel.ro %t | FileCheck %s
// RUN: ld.lld %t.o --shared --emit-relocs -o %t.so --morello-c64-plt
// RUN: llvm-readobj --relocs --sections %t.so | FileCheck %s --check-prefix=SHARED

// Check that the --emit-relocs output is reasonably sane.
 .text
 .global _start
 .type _start, %function
 .size _start, 8
_start:
 bl target
 b target
 adrp c0, :got: foo
 ldr c0, [c0, :got_lo12: foo]

 .section .text.1, "ax", %progbits
 .global target
 .type target, %function
 .size target, 4
target:
 ret

 .data.rel.ro
 .capinit foo
 .xword 0
 .xword 0

 .data
 .global foo
 .type foo, %object
 .size foo, 4
foo:
 .word 0

// CHECK:     Name: .text
// CHECK-NEXT:     Type: SHT_PROGBITS (0x1)
// CHECK-NEXT:     Flags [ (0x6)
// CHECK-NEXT:       SHF_ALLOC (0x2)
// CHECK-NEXT:       SHF_EXECINSTR (0x4)
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x210230

// CHECK:    Name: .data.rel.ro
// CHECK-NEXT:     Type: SHT_PROGBITS (0x1)
// CHECK-NEXT:     Flags [ (0x3)
// CHECK-NEXT:       SHF_ALLOC (0x2)
// CHECK-NEXT:       SHF_WRITE (0x1)
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x220244

// CHECK:    Name: .got
// CHECK-NEXT:    Type: SHT_PROGBITS (0x1)
// CHECK-NEXT:    Flags [ (0x3)
// CHECK-NEXT:      SHF_ALLOC (0x2)
// CHECK-NEXT:      SHF_WRITE (0x1)
// CHECK-NEXT:    ]
// CHECK-NEXT:    Address: 0x220260

// CHECK: Relocations [
// CHECK-NEXT:   .rela.dyn {
// CHECK-NEXT:     0x220260 R_MORELLO_RELATIVE - 0x230280
// CHECK-NEXT:     0x220244 R_MORELLO_RELATIVE - 0x230280
// CHECK-NEXT:   }
// CHECK-NEXT:   .rela.text {
// CHECK-NEXT:     0x210230 R_MORELLO_CALL26 target 0x0
// CHECK-NEXT:     0x210234 R_MORELLO_JUMP26 target 0x0
// CHECK-NEXT:     0x210238 R_MORELLO_ADR_GOT_PAGE foo 0x0
// CHECK-NEXT:     0x21023C R_MORELLO_LD128_GOT_LO12_NC foo 0x0
// CHECK-NEXT:   }
// CHECK-NEXT:   .rela.data.rel.ro {
// CHECK-NEXT:     0x220244 R_MORELLO_CAPINIT foo 0x0

// CHECK:         Name: foo
// CHECK-NEXT:    Value: 0x230280
// CHECK-NEXT:    Size: 4
// CHECK-NEXT:    Binding: Global
// CHECK-NEXT:    Type: Object
// CHECK-NEXT:    Other: 0
// CHECK-NEXT:    Section: .data

// CHECK:      Hex dump of section '.data.rel.ro':
/// foo: address: 0x230280, size = 4, perms = EXEC(0x4)
// CHECK-NEXT: 0x00220244 80022300 00000000 04000000 00000002

// CHECK:      Hex dump of section '.got':
/// foo: address: 0x230280, size = 4, perms = EXEC(0x4)
// CHECK-NEXT: 0x00220260 80022300 00000000 04000000 00000002


// SHARED:     Name: .text
// SHARED-NEXT:     Type: SHT_PROGBITS
// SHARED-NEXT:     Flags [
// SHARED-NEXT:       SHF_ALLOC
// SHARED-NEXT:       SHF_EXECINSTR
// SHARED-NEXT:     ]
// SHARED-NEXT:     Address: 0x10310

// SHARED:     Name: .data.rel.ro
// SHARED-NEXT:     Type: SHT_PROGBITS
// SHARED-NEXT:     Flags [
// SHARED-NEXT:       SHF_ALLOC
// SHARED-NEXT:       SHF_WRITE
// SHARED-NEXT:     ]
// SHARED-NEXT:     Address: 0x20360

// SHARED:     Name: .got
// SHARED-NEXT:     Type: SHT_PROGBITS
// SHARED-NEXT:     Flags [
// SHARED-NEXT:       SHF_ALLOC
// SHARED-NEXT:       SHF_WRITE
// SHARED-NEXT:     ]
// SHARED-NEXT:     Address: 0x20450

// SHARED:     Name: .got.plt
// SHARED-NEXT:     Type: SHT_PROGBITS
// SHARED-NEXT:     Flags [
// SHARED-NEXT:       SHF_ALLOC
// SHARED-NEXT:       SHF_WRITE
// SHARED-NEXT:     ]
// SHARED-NEXT:     Address: 0x30470

// SHARED: Relocations [
// SHARED-NEXT:   Section (5) .rela.dyn {
// SHARED-NEXT:     0x20360 R_MORELLO_CAPINIT foo 0x0
// SHARED-NEXT:     0x20450 R_MORELLO_GLOB_DAT foo 0x0
// SHARED-NEXT:   }
// SHARED-NEXT:   Section (6) .rela.plt {
// SHARED-NEXT:     0x304A0 R_MORELLO_JUMP_SLOT target 0x0
// SHARED-NEXT:   }
// SHARED-NEXT:   Section (14) .rela.text {
// SHARED-NEXT:     0x10310 R_MORELLO_CALL26 target 0x0
// SHARED-NEXT:     0x10314 R_MORELLO_JUMP26 target 0x0
// SHARED-NEXT:     0x10318 R_MORELLO_ADR_GOT_PAGE foo 0x0
// SHARED-NEXT:     0x1031C R_MORELLO_LD128_GOT_LO12_NC foo 0x0
// SHARED-NEXT:   }
// SHARED-NEXT:   Section (15) .rela.data.rel.ro {
// SHARED-NEXT:     0x20360 R_MORELLO_CAPINIT foo 0x0
