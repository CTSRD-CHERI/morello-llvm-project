// REQUIRES: aarch64
// RUN: llvm-mc -target-abi purecap --triple=aarch64-none-elf -mattr=+c64,+morello -filetype=obj %s -o %t.o
// RUN: ld.lld --local-caprelocs=elf %t.o -o %t
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

// DIS: 0000000000210298 <_start>:
// DIS-NEXT: 210298:  adrp c0, 0x220000
// DIS-NEXT: 21029c:  ldr c0, [c0, #0x2d0]
// DIS-NEXT: 2102a0:  adrp c1, 0x220000
// DIS-NEXT: 2102a4:  ldr c1, [c1, #0x2c0]
// DIS-NEXT: 2102a8:  adrp c1, 0x220000
// DIS-NEXT: 2102ac:  ldr c1, [c1, #0x2c0]
// DIS-NEXT: 2102b0:  adrp c2, 0x220000
// DIS-NEXT: 2102b4:  ldr c2, [c1, #0x2e0]

/// .rodata is the start of the executable capability range

// CHECK:          Name: .rodata
// CHECK-NEXT:     Type: SHT_PROGBITS
// CHECK-NEXT:     Flags [
// CHECK-NEXT:       SHF_ALLOC
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x200290

/// Check that .got exists, has 16-byte entries and is 16-byte aligned.
/// The executable capability should extend to the end of the .got
// CHECK:          Name: .got
// CHECK-NEXT:     Type: SHT_PROGBITS
// CHECK-NEXT:     Flags [
// CHECK-NEXT:       SHF_ALLOC
// CHECK-NEXT:       SHF_WRITE
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x2202C0
// CHECK-NEXT:     Offset: 0x2C0
// CHECK-NEXT:     Size: 64
// CHECK-NEXT:     Link: 0
// CHECK-NEXT:     Info: 0
// CHECK-NEXT:     AddressAlignment: 16

/// Check 3 locations in the .got are referred to by CAPINITs in rela.dyn.
/// Note the length of of the executable capability is aligned end of .got -
/// aligned base of .rodata.
// CHECK: Relocations [
// CHECK-NEXT:   .rela.dyn {
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x2202C0
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x2202D0
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x10099
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x2202E0
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:   }
// CHECK-NEXT: ]

// CHECK:          Name: foo
// CHECK-NEXT:     Value: 0x230300
// CHECK-NEXT:     Size: 8
// CHECK-NEXT:     Binding: Global
// CHECK-NEXT:     Type: None (0x0)
// CHECK-NEXT:     Other: 0
// CHECK-NEXT:     Section: .data

// CHECK:          Name: _start
// CHECK-NEXT:     Value: 0x210299
// CHECK-NEXT:     Size: 16
// CHECK-NEXT:     Binding: Global
// CHECK-NEXT:     Type: Function
// CHECK-NEXT:     Other: 0
// CHECK-NEXT:     Section: .text

// CHECK:          Name: bar
// CHECK-NEXT:     Value: 0x200290
// CHECK-NEXT:     Size: 8
// CHECK-NEXT:     Binding: Global
// CHECK-NEXT:     Type: None (0x0)
// CHECK-NEXT:     Other: 0
// CHECK-NEXT:     Section: .rodata

/// Check the fragments in .got match
// CHECK:      Hex dump of section '.got':

/// foo: address: 0x230300, size = 8 (0x8), perms = RW(0x2)
// CHECK-NEXT: 0x002202c0 00032300 00000000 08000000 00000002

/// _start: address: 0x210299, size = 16 (0x10), perms = exec(0x4)
// CHECK-NEXT: 0x002202d0 00022000 00000000 00010200 00000004

/// bar: address: 0x200290, size = 8 (0x8), perms = RO(0x1)
// CHECK-NEXT: 0x002202e0 90022000 00000000 08000000 00000001
