// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64,+morello -filetype=obj %s -o %t.o
// RUN: ld.lld %t.o -o %t --morello-c64-plt
// RUN: llvm-objdump -d --no-show-raw-insn --triple=aarch64-none-elf --mattr=+morello %t | FileCheck %s --check-prefix=DIS
// RUN: llvm-readobj --sections --cap-relocs --expand-relocs %t | FileCheck %s

/// The R_MORELLO_LD128_GOT_LO12_NC relocation causes the linker to create a
/// 16-byte aligned, 16-byte sized entry in the .got that will be initialised
/// by a __cap_reloc entry with a location of the entry in the .got.
 .global foo
 .global _start
 .type _start, %function
 .size _start, 16
_start:
 .text
 adrp c0, :got: _start
 ldr  c0, [c0, :got_lo12: _start]

 adrp c1, :got: foo
 ldr  c1, [c1, :got_lo12: foo]

 adrp c1, :got: foo
 ldr  c1, [c1, :got_lo12: foo]

 adrp c2, :got: bar
 ldr  c2, [c1, :got_lo12: bar]


 .rodata
 .global bar
 .size bar, 8
bar:
 .xword 10

 .data
 .global foo
 .size foo, 8
foo:
 .xword 10

// DIS: 0000000000210208 <_start>:
// DIS-NEXT:   210208:        adrp    c0, #65536
// DIS-NEXT:   21020c:        ldr     c0, [c0, #672]
// DIS-NEXT:   210210:        adrp    c1, #65536
// DIS-NEXT:   210214:        ldr     c1, [c1, #688]
// DIS-NEXT:   210218:        adrp    c1, #65536
// DIS-NEXT:   21021c:        ldr     c1, [c1, #688]
// DIS-NEXT:   210220:        adrp    c2, #65536
// DIS-NEXT:   210224:        ldr     c2, [c1, #704]

/// .rodata is the start of the executable capability range

// CHECK:          Name: .rodata
// CHECK-NEXT:     Type: SHT_PROGBITS (0x1)
// CHECK-NEXT:     Flags [ (0x2)
// CHECK-NEXT:       SHF_ALLOC (0x2)
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x200200

/// Check that .got exists, has 16-byte entries and is 16-byte aligned.
/// The executable capability should extend to the end of the .got
// CHECK:          Name: .got
// CHECK-NEXT:     Type: SHT_PROGBITS (0x1)
// CHECK-NEXT:     Flags [ (0x3)
// CHECK-NEXT:       SHF_ALLOC (0x2)
// CHECK-NEXT:       SHF_WRITE (0x1)
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x2202A0
// CHECK-NEXT:     Offset: 0x2A0
// CHECK-NEXT:     Size: 96
// CHECK-NEXT:     Link: 0
// CHECK-NEXT:     Info: 0
// CHECK-NEXT:     AddressAlignment: 16

/// Check 3 locations in the .got are referred to by __cap_relocs
/// Note the length of of the executable capability is aligned end of .got -
/// aligned base of .rodata.
// CHECK: CHERI __cap_relocs [
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x2202A0
// CHECK-NEXT:     Base: bar (0x200200)
// CHECK-NEXT:     Offset: 65545
// CHECK-NEXT:     Length: 131328
// CHECK-NEXT:     Permissions: (FUNC) (0x8000000000013DBC)
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x2202B0
// CHECK-NEXT:     Base: foo (0x230300)
// CHECK-NEXT:     Offset: 0
// CHECK-NEXT:     Length: 8
// CHECK-NEXT:     Permissions: (RWDATA) (0x8FBE)
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x2202C0
// CHECK-NEXT:     Base: bar (0x200200)
// CHECK-NEXT:     Offset: 0
// CHECK-NEXT:     Length: 8
// CHECK-NEXT:     Permissions: (RODATA) (0x1BFBE)
// CHECK-NEXT:   }
