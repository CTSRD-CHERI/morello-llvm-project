// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64,+morello -filetype=obj %s -o %t.o
// RUN: ld.lld --morello-static-caps=elf %t.o -o %t --morello-c64-plt
// RUN: llvm-objdump -d --print-imm-hex --no-show-raw-insn --triple=aarch64-none-elf --mattr=+morello %t | FileCheck %s --check-prefix=DIS
// RUN: llvm-readobj --symbols --sections --relocs --expand-relocs -x .got %t | FileCheck %s

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

// DIS: 0000000000210250 <_start>:
// DIS-NEXT:   210250:        adrp    c0, #0x10000
// DIS-NEXT:   210254:        ldr     c0, [c0, #0x270]
// DIS-NEXT:   210258:        adrp    c1, #0x10000
// DIS-NEXT:   21025c:        ldr     c1, [c1, #0x280]
// DIS-NEXT:   210260:        adrp    c1, #0x10000
// DIS-NEXT:   210264:        ldr     c1, [c1, #0x280]
// DIS-NEXT:   210268:        adrp    c2, #0x10000
// DIS-NEXT:   21026c:        ldr     c2, [c1, #0x290]

/// .rodata is the start of the executable capability range

// CHECK:          Name: .rodata
// CHECK-NEXT:     Type: SHT_PROGBITS (0x1)
// CHECK-NEXT:     Flags [ (0x2)
// CHECK-NEXT:       SHF_ALLOC (0x2)
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x200248

/// Check that .got exists, has 16-byte entries and is 16-byte aligned.
/// The executable capability should extend to the end of the .got
// CHECK:          Name: .got
// CHECK-NEXT:     Type: SHT_PROGBITS (0x1)
// CHECK-NEXT:     Flags [ (0x3)
// CHECK-NEXT:       SHF_ALLOC (0x2)
// CHECK-NEXT:       SHF_WRITE (0x1)
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x220270
// CHECK-NEXT:     Offset: 0x270
// CHECK-NEXT:     Size: 80
// CHECK-NEXT:     Link: 0
// CHECK-NEXT:     Info: 0
// CHECK-NEXT:     AddressAlignment: 16

/// Check 3 locations in the .got are referred to by CAPINITs in rela.dyn.
/// Note the length of of the executable capability is aligned end of .got -
/// aligned base of .rodata.
// CHECK: Relocations [
// CHECK-NEXT:   .rela.dyn {
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x220270
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x220280
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x220290
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:   }
// CHECK-NEXT: ]

// CHECK:        Symbol {
// CHECK:          Name: _start
// CHECK-NEXT:     Value: 0x210251
// CHECK-NEXT:     Size: 16
// CHECK-NEXT:     Binding: Global (0x1)
// CHECK-NEXT:     Type: Function (0x2)
// CHECK-NEXT:     Other: 0
// CHECK-NEXT:     Section: .text (0x3)
// CHECK-NEXT:   }
// CHECK-NEXT:   Symbol {
// CHECK-NEXT:     Name: bar
// CHECK-NEXT:     Value: 0x200248
// CHECK-NEXT:     Size: 8
// CHECK-NEXT:     Binding: Global (0x1)
// CHECK-NEXT:     Type: None (0x0)
// CHECK-NEXT:     Other: 0
// CHECK-NEXT:     Section: .rodata (0x2)
// CHECK-NEXT:   }
// CHECK-NEXT:   Symbol {
// CHECK-NEXT:     Name: foo
// CHECK-NEXT:     Value: 0x2302C0
// CHECK-NEXT:     Size: 8
// CHECK-NEXT:     Binding: Global (0x1)
// CHECK-NEXT:     Type: None (0x0)
// CHECK-NEXT:     Other: 0
// CHECK-NEXT:     Section: .data (0x5)
// CHECK-NEXT:   }

/// Check the fragments in .got match
// CHECK:      Hex dump of section '.got':

/// _start: address: 0x200200, size = 16 (0x10), perms = EXEC(0x4)
// CHECK-NEXT: 0x00220270 00022000 00000000 00010200 00000004

/// foo: address: 0x2302C0, size = 8 (0x8), perms = RW(0x2)
// CHECK-NEXT: 0x00220280 c0022300 00000000 08000000 00000002

/// bar: address: 0x200248, size = 8 (0x8), perms = RO(0x1)
// CHECK-NEXT: 0x00220290 48022000 00000000 08000000 00000001
