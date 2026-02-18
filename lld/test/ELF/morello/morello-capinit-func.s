// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64 -filetype=obj %s -o %t.o
// RUN: ld.lld -v %t.o -o %t 2>&1 | FileCheck %s --check-prefix=WARN
// RUN: llvm-readobj --cap-relocs --expand-relocs --section-headers %t | FileCheck %s

/// An example showing .chericap to one of each of the permission types. We check
/// that the permissions, base, offsets are correct.

/// Check that we suppress the warning when there is no symbol
/// alongside the capinit as the compiler uses section + offset
// WARN-NOT: Could not find a real symbol for __cap_reloc against .data.rel.ro+0x10
// WARN-NOT: Could not find a real symbol for __cap_reloc against .data.rel.ro+0x20
// WARN-NOT: Could not find a real symbol for __cap_reloc against .data.rel.ro+0x30
// WARN-NOT: Could not find a real symbol for __cap_reloc against .data.rel.ro+0x40
// WARN-NOT: Could not find a real symbol for __cap_reloc against .data.rel.ro+0x50

 .rodata
 .balign 65536
 .globl ro
 .type ro, %object
 .size ro, 4
ro: .word 4
 .globl ro2
 .type ro2, %object
 .size ro2, 4
ro2: .word 8

 .text
 .balign 65536
 .globl _start
 .type _start, %function
 .size _start, 4
_start:
 ret

 .globl func
 .type func, %function
 .size func, 4
func:
 ret

 .data.rel.ro
 .balign 16
 .chericap ro
 .chericap ro2
 .chericap _start
 .chericap func
 .chericap rw
 .chericap bss

 .data
 .balign 65536
 .globl rw
 .type rw, %object
 .size rw, 4
rw:
 .word 4

 .bss
 .globl bss
 .type bss, %object
 .size bss, 4
bss:
 .space 4

/// Executable capability ranges from .rodata up to the end of
/// .data.rel.ro (and the ensuing .pad.cheri.pcc).
/// Range is [0x210000, 0x240080) including alignment to CHERI concentrate
/// boundary.

// CHECK:          Name: .rodata
// CHECK-NEXT:     Type: SHT_PROGBITS
// CHECK-NEXT:     Flags [
// CHECK-NEXT:       SHF_ALLOC
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x210000
// CHECK-NEXT:     Offset: 0x10000
// CHECK-NEXT:     Size: 8
// CHECK-NEXT:     Link: 0
// CHECK-NEXT:     Info: 0
// CHECK-NEXT:     AddressAlignment: 65536
// CHECK-NEXT:     EntrySize: 0
// CHECK-NEXT:   }
// CHECK-NEXT:   Section {
// CHECK-NEXT:     Index:
// CHECK-NEXT:     Name: .text
// CHECK-NEXT:     Type: SHT_PROGBITS
// CHECK-NEXT:     Flags [
// CHECK-NEXT:       SHF_ALLOC
// CHECK-NEXT:       SHF_EXECINSTR
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x230000
// CHECK-NEXT:     Offset: 0x20000
// CHECK-NEXT:     Size: 8
// CHECK-NEXT:     Link: 0
// CHECK-NEXT:     Info: 0
// CHECK-NEXT:     AddressAlignment: 65536
// CHECK-NEXT:     EntrySize: 0
// CHECK-NEXT:   }
// CHECK-NEXT:   Section {
// CHECK-NEXT:     Index:
// CHECK-NEXT:     Name: .data.rel.ro
// CHECK-NEXT:     Type: SHT_PROGBITS
// CHECK-NEXT:     Flags [
// CHECK-NEXT:       SHF_ALLOC
// CHECK-NEXT:       SHF_WRITE
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x240010
// CHECK-NEXT:     Offset: 0x20010
// CHECK-NEXT:     Size: 96
// CHECK-NEXT:     Link: 0
// CHECK-NEXT:     Info: 0
// CHECK-NEXT:     AddressAlignment: 16
// CHECK-NEXT:     EntrySize: 0
// CHECK-NEXT:   }
// CHECK-NEXT:   Section {
// CHECK-NEXT:     Index:
// CHECK-NEXT:     Name: .pad.cheri.pcc
// CHECK-NEXT:     Type: SHT_PROGBITS
// CHECK-NEXT:     Flags [
// CHECK-NEXT:       SHF_ALLOC
// CHECK-NEXT:       SHF_WRITE
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x240070
// CHECK-NEXT:     Offset: 0x20070
// CHECK-NEXT:     Size: 16
// CHECK-NEXT:     Link: 0
// CHECK-NEXT:     Info: 0
// CHECK-NEXT:     AddressAlignment: 1
// CHECK-NEXT:     EntrySize: 0
// CHECK-NEXT:   }
// CHECK-NEXT:   Section {
// CHECK-NEXT:     Index:
// CHECK-NEXT:     Name: .data
// CHECK-NEXT:     Type: SHT_PROGBITS
// CHECK-NEXT:     Flags [
// CHECK-NEXT:       SHF_ALLOC
// CHECK-NEXT:       SHF_WRITE
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x260000
// CHECK-NEXT:     Offset: 0x30000
// CHECK-NEXT:     Size: 4
// CHECK-NEXT:     Link: 0
// CHECK-NEXT:     Info: 0
// CHECK-NEXT:     AddressAlignment: 65536
// CHECK-NEXT:     EntrySize: 0
// CHECK-NEXT:   }
// CHECK-NEXT:   Section {
// CHECK-NEXT:     Index:
// CHECK-NEXT:     Name: .bss
// CHECK-NEXT:     Type: SHT_NOBITS (0x8)
// CHECK-NEXT:     Flags [
// CHECK-NEXT:       SHF_ALLOC
// CHECK-NEXT:       SHF_WRITE
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x260004
// CHECK-NEXT:     Offset: 0x30004
// CHECK-NEXT:     Size: 4


/// Expect 6 capabilities, 2 for each type of permission. Note that the base
/// and limit for FUNC permissions is the range of addresses that a compiler
/// would access pc-relative via an ADRP. In effect the .rodata and .text in
/// this example.

// CHECK: __cap_relocs {
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Offset: 0x240010
// CHECK-NEXT:     Type: RODATA (0x1BFBE)
// CHECK-NEXT:     Address: 0x210000
// CHECK-NEXT:     Base: 0x210000
// CHECK-NEXT:     Length: 4
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Offset: 0x240020
// CHECK-NEXT:     Type: RODATA (0x1BFBE)
// CHECK-NEXT:     Address: 0x210004
// CHECK-NEXT:     Base: 0x210004
// CHECK-NEXT:     Length: 4
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Offset: 0x240030
// CHECK-NEXT:     Type: FUNC (0x8000000000013DBC)
// CHECK-NEXT:     Address: 0x230001
// CHECK-NEXT:     Base: 0x210000
// CHECK-NEXT:     Length: 196736
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Offset: 0x240040
// CHECK-NEXT:     Type: FUNC (0x8000000000013DBC)
// CHECK-NEXT:     Address: 0x230005
// CHECK-NEXT:     Base: 0x210000
// CHECK-NEXT:     Length: 196736
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Offset: 0x240050
// CHECK-NEXT:     Type: DATA (0x8FBE)
// CHECK-NEXT:     Address: 0x260000
// CHECK-NEXT:     Base: 0x260000
// CHECK-NEXT:     Length: 4
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Offset: 0x240060
// CHECK-NEXT:     Type: DATA (0x8FBE)
// CHECK-NEXT:     Address: 0x260004
// CHECK-NEXT:     Base: 0x260004
// CHECK-NEXT:     Length: 4

/// Rerun the test with .rodata after the .text, we would still expect to
/// see the same bounds for the capability.
// RUN: echo "SECTIONS { \
// RUN:       __cap_relocs : { *(__cap_relocs) } \
// RUN:       .text 0x210000: { *(.text) } \
// RUN:       .rodata : { *(.rodata) } \
// RUN:       .data.rel.ro : { *(.data.rel.ro) } \
// RUN:       .data : { *(data) } \
// RUN:       .bss : { *(.bss) } } " > %t.script
// RUN: ld.lld %t.o -o %t2 --script=%t.script
// RUN: llvm-readobj --cap-relocs --expand-relocs %t2 | FileCheck %s --check-prefix=CHECK-SCRIPT

// CHECK-SCRIPT: __cap_relocs {
// CHECK-SCRIPT-NEXT:   Relocation {
// CHECK-SCRIPT-NEXT:     Offset: 0x220010
// CHECK-SCRIPT-NEXT:     Type: RODATA (0x1BFBE)
// CHECK-SCRIPT-NEXT:     Address: 0x220000
// CHECK-SCRIPT-NEXT:     Base: 0x220000
// CHECK-SCRIPT-NEXT:     Length: 4
// CHECK-SCRIPT-NEXT:   }
// CHECK-SCRIPT-NEXT:   Relocation {
// CHECK-SCRIPT-NEXT:     Offset: 0x220020
// CHECK-SCRIPT-NEXT:     Type: RODATA (0x1BFBE)
// CHECK-SCRIPT-NEXT:     Address: 0x220004
// CHECK-SCRIPT-NEXT:     Base: 0x220004
// CHECK-SCRIPT-NEXT:     Length: 4
// CHECK-SCRIPT-NEXT:   }
// CHECK-SCRIPT-NEXT:   Relocation {
// CHECK-SCRIPT-NEXT:     Offset: 0x220030
// CHECK-SCRIPT-NEXT:     Type: FUNC (0x8000000000013DBC)
// CHECK-SCRIPT-NEXT:     Address: 0x210001
// CHECK-SCRIPT-NEXT:     Base: 0x210000
// CHECK-SCRIPT-NEXT:     Length: 65664
// CHECK-SCRIPT-NEXT:   }
// CHECK-SCRIPT-NEXT:   Relocation {
// CHECK-SCRIPT-NEXT:     Offset: 0x220040
// CHECK-SCRIPT-NEXT:     Type: FUNC (0x8000000000013DBC)
// CHECK-SCRIPT-NEXT:     Address: 0x210005
// CHECK-SCRIPT-NEXT:     Base: 0x210000
// CHECK-SCRIPT-NEXT:     Length: 65664
// CHECK-SCRIPT-NEXT:   }
// CHECK-SCRIPT-NEXT:   Relocation {
// CHECK-SCRIPT-NEXT:     Offset: 0x220050
// CHECK-SCRIPT-NEXT:     Type: DATA (0x8FBE)
// CHECK-SCRIPT-NEXT:     Address: 0x230000
// CHECK-SCRIPT-NEXT:     Base: 0x230000
// CHECK-SCRIPT-NEXT:     Length: 4
// CHECK-SCRIPT-NEXT:   }
// CHECK-SCRIPT-NEXT:   Relocation {
// CHECK-SCRIPT-NEXT:     Offset: 0x220060
// CHECK-SCRIPT-NEXT:     Type: DATA (0x8FBE)
// CHECK-SCRIPT-NEXT:     Address: 0x230004
// CHECK-SCRIPT-NEXT:     Base: 0x230004
// CHECK-SCRIPT-NEXT:     Length: 4
