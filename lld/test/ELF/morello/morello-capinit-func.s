// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64 -filetype=obj %s -o %t.o
// RUN: ld.lld -v %t.o -o %t 2>&1 | FileCheck %s --check-prefix=WARN
// RUN: llvm-readobj --cap-relocs --expand-relocs --section-headers %t | FileCheck %s

/// An example showing .capinit to one of each of the permission types. We check
/// that the permissions, base, offsets are correct.

/// Check that we suppress the warning when there is no symbol
/// alongside the .capinit as the compiler uses section + offset
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
 .capinit ro
 .xword 0
 .xword 0
 .capinit ro2
 .xword 0
 .xword 0
 .capinit _start
 .xword 0
 .xword 0
 .capinit func
 .xword 0
 .xword 0
 .capinit rw
 .xword 0
 .xword 0
 .capinit bss
 .xword 0
 .xword 0

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

/// Executable capability ranges from the rodata up to the end of .text
/// range is [0x210000, 0x230200) including alignment to CHERI concentrate
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
// CHECK-NEXT:     Size: 64
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
// CHECK-NEXT:     Address: 0x240040
// CHECK-NEXT:     Offset: 0x20040
// CHECK-NEXT:     Size: 96
// CHECK-NEXT:     Link: 0
// CHECK-NEXT:     Info: 0
// CHECK-NEXT:     AddressAlignment: 16
// CHECK-NEXT:     EntrySize: 0
// CHECK-NEXT:   }
// CHECK-NEXT:   Section {
// CHECK-NEXT:     Index:
// CHECK-NEXT:     Name: __cap_relocs
// CHECK-NEXT:     Type: SHT_PROGBITS
// CHECK-NEXT:     Flags [
// CHECK-NEXT:       SHF_ALLOC
// CHECK-NEXT:       SHF_WRITE
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x2400A0
// CHECK-NEXT:     Offset: 0x200A0
// CHECK-NEXT:     Size: 240
// CHECK-NEXT:     Link: 0
// CHECK-NEXT:     Info: 0
// CHECK-NEXT:     AddressAlignment: 8
// CHECK-NEXT:     EntrySize: 40
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

// CHECK: CHERI __cap_relocs [
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x240040
// CHECK-NEXT:     Base: ro (0x210000)
// CHECK-NEXT:     Offset: 0
// CHECK-NEXT:     Length: 4
// CHECK-NEXT:     Permissions: (RODATA) (0x1BFBE)
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x240050
// CHECK-NEXT:     Base: ro2 (0x210004)
// CHECK-NEXT:     Offset: 0
// CHECK-NEXT:     Length: 4
// CHECK-NEXT:     Permissions: (RODATA) (0x1BFBE)
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x240060
// CHECK-NEXT:     Base: {{.*}} (0x200200)
// CHECK-NEXT:     Offset: 196097
// CHECK-NEXT:     Length: 196160
// CHECK-NEXT:     Permissions: (FUNC) (0x8000000000013DBC)
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x240070
// CHECK-NEXT:     Base: {{.*}} (0x200200)
// CHECK-NEXT:     Offset: 196101
// CHECK-NEXT:     Length: 196160
// CHECK-NEXT:     Permissions: (FUNC) (0x8000000000013DBC)
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x240080
// CHECK-NEXT:     Base: rw (0x260000)
// CHECK-NEXT:     Offset: 0
// CHECK-NEXT:     Length: 4
// CHECK-NEXT:     Permissions: (RWDATA) (0x8FBE)
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x240090
// CHECK-NEXT:     Base: bss (0x260004)
// CHECK-NEXT:     Offset: 0
// CHECK-NEXT:     Length: 4
// CHECK-NEXT:     Permissions: (RWDATA) (0x8FBE)

/// Rerun the test with .rodata after the .text, we would still expect to
/// see the same bounds for the capability.
// RUN: echo "SECTIONS { \
// RUN:       .text 0x210000: { *(.text) } \
// RUN:       .rodata : { *(.rodata) } \
// RUN:       .data.rel.ro : { *(.data.rel.ro) } \
// RUN:       __cap_relocs : { *(__cap_relocs) } \
// RUN:       .data : { *(data) } \
// RUN:       .bss : { *(.bss) } } " > %t.script
// RUN: ld.lld %t.o -o %t2 --script=%t.script
// RUN: llvm-readobj --cap-relocs --expand-relocs %t2 | FileCheck %s --check-prefix=CHECK-SCRIPT

// CHECK-SCRIPT: CHERI __cap_relocs [
// CHECK-SCRIPT-NEXT:   Relocation {
// CHECK-SCRIPT-NEXT:     Location: 0x220400 ($d.2)
// CHECK-SCRIPT-NEXT:     Base: ro (0x220000)
// CHECK-SCRIPT-NEXT:     Offset: 0
// CHECK-SCRIPT-NEXT:     Length: 4
// CHECK-SCRIPT-NEXT:     Permissions: (RODATA) (0x1BFBE)
// CHECK-SCRIPT-NEXT:   }
// CHECK-SCRIPT-NEXT:   Relocation {
// CHECK-SCRIPT-NEXT:     Location: 0x220410
// CHECK-SCRIPT-NEXT:     Base: ro2 (0x220004)
// CHECK-SCRIPT-NEXT:     Offset: 0
// CHECK-SCRIPT-NEXT:     Length: 4
// CHECK-SCRIPT-NEXT:     Permissions: (RODATA) (0x1BFBE)
// CHECK-SCRIPT-NEXT:   }
// CHECK-SCRIPT-NEXT:   Relocation {
// CHECK-SCRIPT-NEXT:     Location: 0x220420
// CHECK-SCRIPT-NEXT:     Base: <unknown symbol> (0x0)
// CHECK-SCRIPT-NEXT:     Offset: 2162689
// CHECK-SCRIPT-NEXT:     Length: 2229248
// CHECK-SCRIPT-NEXT:     Permissions: (FUNC) (0x8000000000013DBC)
// CHECK-SCRIPT-NEXT:   }
// CHECK-SCRIPT-NEXT:   Relocation {
// CHECK-SCRIPT-NEXT:     Location: 0x220430
// CHECK-SCRIPT-NEXT:     Base: <unknown symbol> (0x0)
// CHECK-SCRIPT-NEXT:     Offset: 2162693
// CHECK-SCRIPT-NEXT:     Length: 2229248
// CHECK-SCRIPT-NEXT:     Permissions: (FUNC) (0x8000000000013DBC)
// CHECK-SCRIPT-NEXT:   }
// CHECK-SCRIPT-NEXT:   Relocation {
// CHECK-SCRIPT-NEXT:     Location: 0x220440
// CHECK-SCRIPT-NEXT:     Base: rw (0x230000)
// CHECK-SCRIPT-NEXT:     Offset: 0
// CHECK-SCRIPT-NEXT:     Length: 4
// CHECK-SCRIPT-NEXT:     Permissions: (RWDATA) (0x8FBE)
// CHECK-SCRIPT-NEXT:   }
// CHECK-SCRIPT-NEXT:   Relocation {
// CHECK-SCRIPT-NEXT:     Location: 0x220450
// CHECK-SCRIPT-NEXT:     Base: bss (0x230004)
// CHECK-SCRIPT-NEXT:     Offset: 0
// CHECK-SCRIPT-NEXT:     Length: 4
// CHECK-SCRIPT-NEXT:     Permissions: (RWDATA) (0x8FBE)
