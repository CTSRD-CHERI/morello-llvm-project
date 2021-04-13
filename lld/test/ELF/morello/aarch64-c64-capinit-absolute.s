// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64,+morello -filetype=obj %S/Inputs/aarch64-abs.s -o %t.o
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64,+morello -filetype=obj %s -o %t2.o
// RUN: ld.lld %t.o %t2.o -o %t --morello-c64-plt
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
 .capinit foo
 .xword 0
 .xword 0

 .capinit bar
 .xword 0
 .xword 0

// CHECK:    Name: __cap_relocs
// CHECK-NEXT:     Type: SHT_PROGBITS (0x1)
// CHECK-NEXT:     Flags [ (0x3)
// CHECK-NEXT:       SHF_ALLOC (0x2)
// CHECK-NEXT:       SHF_WRITE (0x1)
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x2201D0
// CHECK-NEXT:     Offset: 0x1D0
// CHECK-NEXT:     Size: 160

// CHECK: CHERI __cap_relocs [
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x2201B0 ($d.1)
// CHECK-NEXT:     Base: $c.0 (0x2101A0)
// CHECK-NEXT:     Offset: 32353
// CHECK-NEXT:     Length: 65792
// CHECK-NEXT:     Permissions: (FUNC) (0x8000000000013DBC)
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x2201C0
// CHECK-NEXT:     Base: bar (0x400000)
// CHECK-NEXT:     Offset: 0
// CHECK-NEXT:     Length: 8
// CHECK-NEXT:     Permissions: (RWDATA) (0x8FBE)
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x220270
// CHECK-NEXT:     Base: $c.0 (0x2101A0)
// CHECK-NEXT:     Offset: 32353
// CHECK-NEXT:     Length: 65792
// CHECK-NEXT:     Permissions: (FUNC) (0x8000000000013DBC)
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x220280
// CHECK-NEXT:     Base: bar (0x400000)
// CHECK-NEXT:     Offset: 0
// CHECK-NEXT:     Length: 8
// CHECK-NEXT:     Permissions: (RWDATA) (0x8FBE)
