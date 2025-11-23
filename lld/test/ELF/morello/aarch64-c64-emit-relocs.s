// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64,+morello -filetype=obj -target-abi purecap %s -o %t.o
// RUN: ld.lld %t.o --emit-relocs -o %t
// RUN: llvm-readobj --relocs --sections %t | FileCheck %s
// RUN: ld.lld %t.o --shared --emit-relocs -o %t.so
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
 .chericap foo

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
// CHECK-NEXT:     Address: 0x210298

// CHECK:    Name: .data.rel.ro
// CHECK-NEXT:     Type: SHT_PROGBITS (0x1)
// CHECK-NEXT:     Flags [ (0x3)
// CHECK-NEXT:       SHF_ALLOC (0x2)
// CHECK-NEXT:       SHF_WRITE (0x1)
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x2202B0

// CHECK: Relocations [
// CHECK-NEXT:   Section {{.*}} .rela.text {
// CHECK-NEXT:     0x210298 R_MORELLO_CALL26 target 0x0
// CHECK-NEXT:     0x21029C R_MORELLO_JUMP26 target 0x0
// CHECK-NEXT:     0x2102A0 R_MORELLO_ADR_GOT_PAGE foo 0x0
// CHECK-NEXT:     0x2102A4 R_MORELLO_LD128_GOT_LO12_NC foo 0x0
// CHECK-NEXT:   }
// CHECK-NEXT:   Section {{.*}} .rela.data.rel.ro {
// CHECK-NEXT:     0x2202B0 R_MORELLO_CAPINIT foo 0x0

// SHARED:     Name: .text
// SHARED-NEXT:     Type: SHT_PROGBITS
// SHARED-NEXT:     Flags [
// SHARED-NEXT:       SHF_ALLOC
// SHARED-NEXT:       SHF_EXECINSTR
// SHARED-NEXT:     ]
// SHARED-NEXT:     Address: 0x10398

// SHARED:     Name: .data.rel.ro
// SHARED-NEXT:     Type: SHT_PROGBITS
// SHARED-NEXT:     Flags [
// SHARED-NEXT:       SHF_ALLOC
// SHARED-NEXT:       SHF_WRITE
// SHARED-NEXT:     ]
// SHARED-NEXT:     Address: 0x203E0

// SHARED:     Name: .got
// SHARED-NEXT:     Type: SHT_PROGBITS
// SHARED-NEXT:     Flags [
// SHARED-NEXT:       SHF_ALLOC
// SHARED-NEXT:       SHF_WRITE
// SHARED-NEXT:     ]
// SHARED-NEXT:     Address: 0x204D0

// SHARED:     Name: .got.plt
// SHARED-NEXT:     Type: SHT_PROGBITS
// SHARED-NEXT:     Flags [
// SHARED-NEXT:       SHF_ALLOC
// SHARED-NEXT:       SHF_WRITE
// SHARED-NEXT:     ]
// SHARED-NEXT:     Address: 0x304F0

// SHARED: Relocations [
// SHARED-NEXT:   Section {{.*}} .rela.dyn {
// SHARED-NEXT:     0x203E0 R_MORELLO_CAPINIT foo 0x0
// SHARED-NEXT:     0x204D0 R_MORELLO_GLOB_DAT foo 0x0
// SHARED-NEXT:   }
// SHARED-NEXT:   Section {{.*}} .rela.plt {
// SHARED-NEXT:     0x30520 R_MORELLO_JUMP_SLOT target 0x10171
// SHARED-NEXT:   }
// SHARED-NEXT:   Section {{.*}} .rela.text {
// SHARED-NEXT:     0x10398 R_MORELLO_CALL26 target 0x0
// SHARED-NEXT:     0x1039C R_MORELLO_JUMP26 target 0x0
// SHARED-NEXT:     0x103A0 R_MORELLO_ADR_GOT_PAGE foo 0x0
// SHARED-NEXT:     0x103A4 R_MORELLO_LD128_GOT_LO12_NC foo 0x0
// SHARED-NEXT:   }
// SHARED-NEXT:   Section {{.*}} .rela.data.rel.ro {
// SHARED-NEXT:     0x203E0 R_MORELLO_CAPINIT foo 0x0
