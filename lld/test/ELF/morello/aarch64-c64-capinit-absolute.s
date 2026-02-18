// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64,+morello -target-abi purecap -filetype=obj %S/Inputs/aarch64-abs.s -o %t.o
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64,+morello -target-abi purecap -filetype=obj %s -o %t2.o
// RUN: ld.lld %t.o %t2.o -o %t
// RUN: llvm-readobj --cap-relocs --sections --expand-relocs %t | FileCheck %s

/// Check that we can handle capability generating relocations to absolute
/// symbols.
/// FIXME: The linker does not alter the PCC capability depending on the
/// absolute symbol. At the moment it is the responsibility of the developer
/// to give a value in the PCC range.
 .text
 .global _start
 .type _start, %function
 .size _start, 20
_start:
 adrp c0, :got: foo
 ldr c0, [c0, :got_lo12: foo]
 adrp c1, :got: bar
 ldr c1, [c1, :got_lo12: bar]

 .data.rel.ro
 .chericap foo

 .chericap bar

// CHECK:    Name: __cap_relocs
// CHECK-NEXT:     Type: SHT_PROGBITS (0x1)
// CHECK-NEXT:     Flags [ (0x2)
// CHECK-NEXT:       SHF_ALLOC (0x2)
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x200248
// CHECK-NEXT:     Offset:
// CHECK-NEXT:     Size: 160

// CHECK: __cap_relocs {
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Offset: 0x220310
// CHECK-NEXT:     Type: FUNC (0x8000000000013DBC)
// CHECK-NEXT:     Address: 0x218001
// CHECK-NEXT:     Base: 0x210300
// CHECK-NEXT:     Length: 65632
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Offset: 0x220320
// CHECK-NEXT:     Type: DATA (0x8FBE)
// CHECK-NEXT:     Address: 0x400000
// CHECK-NEXT:     Base: 0x400000
// CHECK-NEXT:     Length: 8
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Offset: 0x220330
// CHECK-NEXT:     Type: FUNC (0x8000000000013DBC)
// CHECK-NEXT:     Address: 0x218001
// CHECK-NEXT:     Base: 0x210300
// CHECK-NEXT:     Length: 65632
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Offset: 0x220340
// CHECK-NEXT:     Type: DATA (0x8FBE)
// CHECK-NEXT:     Address: 0x400000
// CHECK-NEXT:     Base: 0x400000
// CHECK-NEXT:     Length: 8
