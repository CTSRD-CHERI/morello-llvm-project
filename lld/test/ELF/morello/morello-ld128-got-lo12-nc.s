// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64,+morello -filetype=obj %s -o %t.o
// RUN: ld.lld %t.o -o %t
// RUN: llvm-objdump -d --no-show-raw-insn --no-print-imm-hex --triple=aarch64-none-elf --mattr=+morello %t | FileCheck %s --check-prefix=DIS
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

// DIS: 0000000000210258 <_start>:
// DIS-NEXT:   210258:        adrp    c0, 0x220000 <_start+0xfda8>
// DIS-NEXT:   21025c:        ldr     c0, [c0, #768]
// DIS-NEXT:   210260:        adrp    c1, 0x220000 <_start+0xfda8>
// DIS-NEXT:   210264:        ldr     c1, [c1, #752]
// DIS-NEXT:   210268:        adrp    c1, 0x220000 <_start+0xfda8>
// DIS-NEXT:   21026c:        ldr     c1, [c1, #752]
// DIS-NEXT:   210270:        adrp    c2, 0x220000 <_start+0xfda8>
// DIS-NEXT:   210274:        ldr     c2, [c1, #784]

/// .rodata is the start of the executable capability range

// CHECK:          Name: .rodata
// CHECK-NEXT:     Type: SHT_PROGBITS (0x1)
// CHECK-NEXT:     Flags [ (0x2)
// CHECK-NEXT:       SHF_ALLOC (0x2)
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x200250

/// Check that .got exists, has 16-byte entries and is 16-byte aligned.
/// The executable capability should extend to the end of the .got
// CHECK:          Name: .got
// CHECK-NEXT:     Type: SHT_PROGBITS (0x1)
// CHECK-NEXT:     Flags [ (0x3)
// CHECK-NEXT:       SHF_ALLOC (0x2)
// CHECK-NEXT:       SHF_WRITE (0x1)
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x2202F0
// CHECK-NEXT:     Offset: 0x2F0
// CHECK-NEXT:     Size: 80
// CHECK-NEXT:     Link: 0
// CHECK-NEXT:     Info: 0
// CHECK-NEXT:     AddressAlignment: 16

/// Check 3 locations in the .got are referred to by __cap_relocs
/// Note the length of of the executable capability is aligned end of .got -
/// aligned base of .rodata.
// CHECK: __cap_relocs {
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Offset: 0x2202F0
// CHECK-NEXT:     Type: DATA (0x8FBE)
// CHECK-NEXT:     Address: 0x230340
// CHECK-NEXT:     Base: 0x230340
// CHECK-NEXT:     Length: 8
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Offset: 0x220300
// CHECK-NEXT:     Type: FUNC (0x8000000000013DBC)
// CHECK-NEXT:     Address: 0x210259
// CHECK-NEXT:     Base: 0x200200
// CHECK-NEXT:     Length: 131392
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Offset: 0x220310
// CHECK-NEXT:     Type: RODATA (0x1BFBE)
// CHECK-NEXT:     Address: 0x200250
// CHECK-NEXT:     Base: 0x200250
// CHECK-NEXT:     Length: 8
// CHECK-NEXT:   }
