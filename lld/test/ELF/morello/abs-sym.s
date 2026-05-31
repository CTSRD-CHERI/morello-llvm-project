// REQUIRES: aarch64
// RUN: split-file %s %t

// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64,+morello -target-abi purecap -filetype=obj %t/abs.s -o %t/abs.o
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64,+morello -target-abi purecap -filetype=obj %t/use.s -o %t/use.o
// RUN: ld.lld -T %t/lds --defsym abs3=0x42424242 %t/abs.o %t/use.o --local-caprelocs=legacy -o %t.caprelocs
// RUN: llvm-readobj --relocs --cap-relocs %t.caprelocs | FileCheck --check-prefix=RELOC %s
// RUN: llvm-readobj -x .got -x .data %t.caprelocs | FileCheck --check-prefix=HEX %s
// RUN: ld.lld -T %t/lds --defsym abs3=0x42424242 %t/abs.o %t/use.o --local-caprelocs=elf -o %t.elf
// RUN: llvm-readobj --relocs --cap-relocs %t.elf | FileCheck --check-prefix=RELOC %s
// RUN: llvm-readobj -x .got -x .data %t.elf | FileCheck --check-prefix=HEX %s

// RELOC-LABEL: Relocations [
// RELOC-NEXT:  ]

// RELOC-LABEL: CHERI Capability Relocations [
// RELOC-NEXT:  ]

// HEX-LABEL: section '.got':
// HEX-NEXT:  [[#%x,]] 78563412 00000000 00000000 00000000
// HEX-NEXT:  [[#%x,]] b55aab00 00000000 00000000 00000000
// HEX-NEXT:  [[#%x,]] 42424242 00000000 00000000 00000000
// HEX-LABEL: section '.data':
// HEX-NEXT:  [[#%x,]] 78563412 00000000 00000000 00000000
// HEX-NEXT:  [[#%x,]] 7b563412 00000000 00000000 00000000
// HEX-NEXT:  [[#%x,]] b55aab00 00000000 00000000 00000000
// HEX-NEXT:  [[#%x,]] b95aab00 00000000 00000000 00000000
// HEX-NEXT:  [[#%x,]] 42424242 00000000 00000000 00000000
// HEX-NEXT:  [[#%x,]] 47424242 00000000 00000000 00000000

//--- abs.s

.global abs
.type abs, %object
.set abs, 0x12345678
.size abs, 0xdead

//--- lds

abs2 = 0xab5ab5;

//--- use.s

adrp c0, :got:abs
ldr c0, [c0, :got_lo12:abs]
adrp c0, :got:abs2
ldr c0, [c0, :got_lo12:abs2]
adrp c0, :got:abs3
ldr c0, [c0, :got_lo12:abs3]

.data
.chericap abs
.chericap abs + 3
.chericap abs2
.chericap abs2 + 4
.chericap abs3
.chericap abs3 + 5
