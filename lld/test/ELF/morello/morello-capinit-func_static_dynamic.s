// REQUIRES: aarch64
// RUN: llvm-mc -target-abi purecap --triple=aarch64-none-elf -mattr=+c64 -filetype=obj %s -o %t.o
// RUN: ld.lld -v --local-caprelocs=elf %t.o -o %t --fatal-warnings
// RUN: llvm-readobj --symbols --relocs --expand-relocs --section-headers -x .data.rel.ro %t | FileCheck %s

/// An example showing .capinit to one of each of the permission types. We check
/// that the permissions, base, offsets are correct.

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

// CHECK:    Name: .rela.dyn
// CHECK-NEXT:     Type: SHT_RELA
// CHECK-NEXT:     Flags [
// CHECK-NEXT:       SHF_ALLOC
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x200218
// CHECK-NEXT:     Offset: 0x218
// CHECK-NEXT:     Size: 144
// CHECK-NEXT:     Link: 0
// CHECK-NEXT:     Info: 0
// CHECK-NEXT:     AddressAlignment: 8
// CHECK-NEXT:     EntrySize: 24
// CHECK-NEXT:   }
// CHECK-NEXT:   Section {
// CHECK-NEXT:     Index: 3
// CHECK-NEXT:     Name: .rodata
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
// CHECK-NEXT:     Index: 4
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
// CHECK-NEXT:     Index: 5
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
// CHECK-NEXT:     Index: 6
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
// CHECK-NEXT:     Index: 7
// CHECK-NEXT:     Name: .bss
// CHECK-NEXT:     Type: SHT_NOBITS
// CHECK-NEXT:     Flags [
// CHECK-NEXT:       SHF_ALLOC
// CHECK-NEXT:       SHF_WRITE
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x260004
// CHECK-NEXT:     Offset: 0x30004
// CHECK-NEXT:     Size: 4
// CHECK-NEXT:     Link: 0
// CHECK-NEXT:     Info: 0
// CHECK-NEXT:     AddressAlignment: 1
// CHECK-NEXT:     EntrySize: 0
// CHECK-NEXT:   }

/// Expect 6 capabilities, 2 for each type of permission. Note that the base
/// and limit for FUNC permissions is the range of addresses that a compiler
/// would access pc-relative via an ADRP. In effect the .rodata and .text in
/// this example.

// CHECK: Relocations [
// CHECK-NEXT:   .rela.dyn {
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x240040
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x240050
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x240060
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x2FE01
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x240070
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x2FE05
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x240080
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:     Relocation {
// CHECK-NEXT:       Offset: 0x240090
// CHECK-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-NEXT:       Symbol: - (0)
// CHECK-NEXT:       Addend: 0x0
// CHECK-NEXT:     }
// CHECK-NEXT:  }

// CHECK:       Symbol {
// CHECK:         Name: ro
// CHECK-NEXT:    Value: 0x210000
// CHECK-NEXT:    Size: 4
// CHECK-NEXT:    Binding: Global
// CHECK-NEXT:    Type: Object
// CHECK-NEXT:    Other: 0
// CHECK-NEXT:    Section: .rodata
// CHECK-NEXT:  }

// CHECK:       Symbol {
// CHECK:         Name: ro2
// CHECK-NEXT:    Value: 0x210004
// CHECK-NEXT:    Size: 4
// CHECK-NEXT:    Binding: Global
// CHECK-NEXT:    Type: Object
// CHECK-NEXT:    Other: 0
// CHECK-NEXT:    Section: .rodata
// CHECK-NEXT:  }

// CHECK:       Symbol {
// CHECK:         Name: _start
// CHECK-NEXT:    Value: 0x230001
// CHECK-NEXT:    Size: 4
// CHECK-NEXT:    Binding: Global
// CHECK-NEXT:    Type: Function
// CHECK-NEXT:    Other: 0
// CHECK-NEXT:    Section: .text
// CHECK-NEXT:  }

// CHECK:       Symbol {
// CHECK:         Name: func
// CHECK-NEXT:    Value: 0x230005
// CHECK-NEXT:    Size: 4
// CHECK-NEXT:    Binding: Global
// CHECK-NEXT:    Type: Function
// CHECK-NEXT:    Other: 0
// CHECK-NEXT:    Section: .text
// CHECK-NEXT:  }

// CHECK:       Symbol {
// CHECK:         Name: rw
// CHECK-NEXT:    Value: 0x260000
// CHECK-NEXT:    Size: 4
// CHECK-NEXT:    Binding: Global
// CHECK-NEXT:    Type: Object
// CHECK-NEXT:    Other: 0
// CHECK-NEXT:    Section: .data
// CHECK-NEXT:  }

// CHECK:       Symbol {
// CHECK:         Name: bss
// CHECK-NEXT:    Value: 0x260004
// CHECK-NEXT:    Size: 4
// CHECK-NEXT:    Binding: Global
// CHECK-NEXT:    Type: Object
// CHECK-NEXT:    Other: 0
// CHECK-NEXT:    Section: .bss
// CHECK-NEXT:  }

// CHECK: Hex dump of section '.data.rel.ro':
/// ro: address: 0x210000, size = 4, perms = RO(0x1)
// CHECK-NEXT: 0x00240040 00002100 00000000 04000000 00000001

/// ro2: address: 0x210004, size = 4, perms = RO(0x1)
// CHECK-NEXT: 0x00240050 04002100 00000000 04000000 00000001

/// _start: address: 0x230001, size = 4, perms = EXEC(0x4)
// CHECK-NEXT: 0x00240060 00022000 00000000 40fe0200 00000004

/// func: address: 0x230005, size = 4, perms = EXEC(0x4)
// CHECK-NEXT: 0x00240070 00022000 00000000 40fe0200 00000004

/// rw: address: 0x260000, size = 4, perms = RW(0x2)
// CHECK-NEXT: 0x00240080 00002600 00000000 04000000 00000002

/// bss: address: 0x260004, size = 4, perms = RW(0x2)
// CHECK-NEXT: 0x00240090 04002600 00000000 04000000 00000002

/// Rerun the test with .rodata after the .text, we would still expect to
/// see the same bounds for the capability.
// RUN: echo "SECTIONS { \
// RUN:       .text 0x210000: { *(.text) } \
// RUN:       .rodata : { *(.rodata) } \
// RUN:       .data.rel.ro : { *(.data.rel.ro) } \
// RUN:       .data : { *(data) } \
// RUN:       .bss : { *(.bss) } } " > %t.script
// RUN: ld.lld --local-caprelocs=elf %t.o -o %t2 --script=%t.script
// RUN: llvm-readobj --symbols --relocs --expand-relocs --section-headers -x .data.rel.ro %t2 | FileCheck %s --check-prefix=CHECK-SCRIPT

// CHECK-SCRIPT:          Name: .text
// CHECK-SCRIPT-NEXT:     Type: SHT_PROGBITS
// CHECK-SCRIPT-NEXT:     Flags [
// CHECK-SCRIPT-NEXT:       SHF_ALLOC
// CHECK-SCRIPT-NEXT:       SHF_EXECINSTR
// CHECK-SCRIPT-NEXT:     ]
// CHECK-SCRIPT-NEXT:     Address: 0x210000
// CHECK-SCRIPT-NEXT:     Offset: 0x20000
// CHECK-SCRIPT-NEXT:     Size: 8
// CHECK-SCRIPT-NEXT:     Link: 0
// CHECK-SCRIPT-NEXT:     Info: 0
// CHECK-SCRIPT-NEXT:     AddressAlignment: 65536
// CHECK-SCRIPT-NEXT:     EntrySize: 0
// CHECK-SCRIPT-NEXT:   }
// CHECK-SCRIPT-NEXT:   Section {
// CHECK-SCRIPT-NEXT:     Index:
// CHECK-SCRIPT-NEXT:     Name: .rela.dyn
// CHECK-SCRIPT-NEXT:     Type: SHT_RELA
// CHECK-SCRIPT-NEXT:     Flags [
// CHECK-SCRIPT-NEXT:       SHF_ALLOC
// CHECK-SCRIPT-NEXT:     ]
// CHECK-SCRIPT-NEXT:     Address: 0x210008
// CHECK-SCRIPT-NEXT:     Offset: 0x20008
// CHECK-SCRIPT-NEXT:     Size: 144
// CHECK-SCRIPT-NEXT:     Link: 0
// CHECK-SCRIPT-NEXT:     Info: 0
// CHECK-SCRIPT-NEXT:     AddressAlignment: 8
// CHECK-SCRIPT-NEXT:     EntrySize: 24
// CHECK-SCRIPT-NEXT:   }
// CHECK-SCRIPT-NEXT:   Section {
// CHECK-SCRIPT-NEXT:     Index:
// CHECK-SCRIPT-NEXT:     Name: .rodata
// CHECK-SCRIPT-NEXT:     Type: SHT_PROGBITS
// CHECK-SCRIPT-NEXT:     Flags [
// CHECK-SCRIPT-NEXT:       SHF_ALLOC
// CHECK-SCRIPT-NEXT:     ]
// CHECK-SCRIPT-NEXT:     Address: 0x220000
// CHECK-SCRIPT-NEXT:     Offset: 0x30000
// CHECK-SCRIPT-NEXT:     Size: 1024
// CHECK-SCRIPT-NEXT:     Link: 0
// CHECK-SCRIPT-NEXT:     Info: 0
// CHECK-SCRIPT-NEXT:     AddressAlignment: 65536
// CHECK-SCRIPT-NEXT:     EntrySize: 0
// CHECK-SCRIPT-NEXT:   }
// CHECK-SCRIPT-NEXT:   Section {
// CHECK-SCRIPT-NEXT:     Index:
// CHECK-SCRIPT-NEXT:     Name: .data.rel.ro
// CHECK-SCRIPT-NEXT:     Type: SHT_PROGBITS
// CHECK-SCRIPT-NEXT:     Flags [
// CHECK-SCRIPT-NEXT:       SHF_ALLOC
// CHECK-SCRIPT-NEXT:       SHF_WRITE
// CHECK-SCRIPT-NEXT:     ]
// CHECK-SCRIPT-NEXT:     Address: 0x220400
// CHECK-SCRIPT-NEXT:     Offset: 0x30400
// CHECK-SCRIPT-NEXT:     Size: 96
// CHECK-SCRIPT-NEXT:     Link: 0
// CHECK-SCRIPT-NEXT:     Info: 0
// CHECK-SCRIPT-NEXT:     AddressAlignment: 16
// CHECK-SCRIPT-NEXT:     EntrySize: 0
// CHECK-SCRIPT-NEXT:   }
// CHECK-SCRIPT-NEXT:   Section {
// CHECK-SCRIPT-NEXT:     Index:
// CHECK-SCRIPT-NEXT:     Name: .data
// CHECK-SCRIPT-NEXT:     Type: SHT_PROGBITS
// CHECK-SCRIPT-NEXT:     Flags [
// CHECK-SCRIPT-NEXT:       SHF_ALLOC
// CHECK-SCRIPT-NEXT:       SHF_WRITE
// CHECK-SCRIPT-NEXT:     ]
// CHECK-SCRIPT-NEXT:     Address: 0x230000
// CHECK-SCRIPT-NEXT:     Offset: 0x40000
// CHECK-SCRIPT-NEXT:     Size: 4
// CHECK-SCRIPT-NEXT:     Link: 0
// CHECK-SCRIPT-NEXT:     Info: 0
// CHECK-SCRIPT-NEXT:     AddressAlignment: 65536
// CHECK-SCRIPT-NEXT:     EntrySize: 0
// CHECK-SCRIPT-NEXT:   }
// CHECK-SCRIPT-NEXT:   Section {
// CHECK-SCRIPT-NEXT:     Index:
// CHECK-SCRIPT-NEXT:     Name: .bss
// CHECK-SCRIPT-NEXT:     Type: SHT_NOBITS
// CHECK-SCRIPT-NEXT:     Flags [
// CHECK-SCRIPT-NEXT:       SHF_ALLOC
// CHECK-SCRIPT-NEXT:       SHF_WRITE
// CHECK-SCRIPT-NEXT:     ]
// CHECK-SCRIPT-NEXT:     Address: 0x230004
// CHECK-SCRIPT-NEXT:     Offset: 0x40004
// CHECK-SCRIPT-NEXT:     Size: 4
// CHECK-SCRIPT-NEXT:     Link: 0
// CHECK-SCRIPT-NEXT:     Info: 0
// CHECK-SCRIPT-NEXT:     AddressAlignment: 1
// CHECK-SCRIPT-NEXT:     EntrySize: 0
// CHECK-SCRIPT-NEXT:   }

// CHECK-SCRIPT: Relocations [
// CHECK-SCRIPT-NEXT:   .rela.dyn {
// CHECK-SCRIPT-NEXT:     Relocation {
// CHECK-SCRIPT-NEXT:       Offset: 0x220400
// CHECK-SCRIPT-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-SCRIPT-NEXT:       Symbol: - (0)
// CHECK-SCRIPT-NEXT:       Addend: 0x0
// CHECK-SCRIPT-NEXT:     }
// CHECK-SCRIPT-NEXT:     Relocation {
// CHECK-SCRIPT-NEXT:       Offset: 0x220410
// CHECK-SCRIPT-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-SCRIPT-NEXT:       Symbol: - (0)
// CHECK-SCRIPT-NEXT:       Addend: 0x0
// CHECK-SCRIPT-NEXT:     }
// CHECK-SCRIPT-NEXT:     Relocation {
// CHECK-SCRIPT-NEXT:       Offset: 0x220420
// CHECK-SCRIPT-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-SCRIPT-NEXT:       Symbol: - (0)
// CHECK-SCRIPT-NEXT:       Addend: 0x210001
// CHECK-SCRIPT-NEXT:     }
// CHECK-SCRIPT-NEXT:     Relocation {
// CHECK-SCRIPT-NEXT:       Offset: 0x220430
// CHECK-SCRIPT-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-SCRIPT-NEXT:       Symbol: - (0)
// CHECK-SCRIPT-NEXT:       Addend: 0x210005
// CHECK-SCRIPT-NEXT:     }
// CHECK-SCRIPT-NEXT:     Relocation {
// CHECK-SCRIPT-NEXT:       Offset: 0x220440
// CHECK-SCRIPT-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-SCRIPT-NEXT:       Symbol: - (0)
// CHECK-SCRIPT-NEXT:       Addend: 0x0
// CHECK-SCRIPT-NEXT:     }
// CHECK-SCRIPT-NEXT:     Relocation {
// CHECK-SCRIPT-NEXT:       Offset: 0x220450
// CHECK-SCRIPT-NEXT:       Type: R_MORELLO_RELATIVE
// CHECK-SCRIPT-NEXT:       Symbol: - (0)
// CHECK-SCRIPT-NEXT:       Addend: 0x0
// CHECK-SCRIPT-NEXT:     }
// CHECK-SCRIPT-NEXT:   }
// CHECK-SCRIPT-NEXT: ]



// CHECK-SCRIPT:        Symbol {
// CHECK-SCRIPT:          Name: ro
// CHECK-SCRIPT-NEXT:     Value: 0x220000
// CHECK-SCRIPT-NEXT:     Size: 4
// CHECK-SCRIPT-NEXT:     Binding: Global
// CHECK-SCRIPT-NEXT:     Type: Object
// CHECK-SCRIPT-NEXT:     Other: 0
// CHECK-SCRIPT-NEXT:     Section: .rodata
// CHECK-SCRIPT-NEXT:   }

// CHECK-SCRIPT:        Symbol {
// CHECK-SCRIPT:          Name: ro2
// CHECK-SCRIPT-NEXT:     Value: 0x220004
// CHECK-SCRIPT-NEXT:     Size: 4
// CHECK-SCRIPT-NEXT:     Binding: Global
// CHECK-SCRIPT-NEXT:     Type: Object
// CHECK-SCRIPT-NEXT:     Other: 0
// CHECK-SCRIPT-NEXT:     Section: .rodata
// CHECK-SCRIPT-NEXT:   }

// CHECK-SCRIPT:        Symbol {
// CHECK-SCRIPT:          Name: _start
// CHECK-SCRIPT-NEXT:     Value: 0x210001
// CHECK-SCRIPT-NEXT:     Size: 4
// CHECK-SCRIPT-NEXT:     Binding: Global
// CHECK-SCRIPT-NEXT:     Type: Function
// CHECK-SCRIPT-NEXT:     Other: 0
// CHECK-SCRIPT-NEXT:     Section: .text
// CHECK-SCRIPT-NEXT:   }

// CHECK-SCRIPT:        Symbol {
// CHECK-SCRIPT:          Name: func
// CHECK-SCRIPT-NEXT:     Value: 0x210005
// CHECK-SCRIPT-NEXT:     Size: 4
// CHECK-SCRIPT-NEXT:     Binding: Global
// CHECK-SCRIPT-NEXT:     Type: Function
// CHECK-SCRIPT-NEXT:     Other: 0
// CHECK-SCRIPT-NEXT:     Section: .text
// CHECK-SCRIPT-NEXT:   }

// CHECK-SCRIPT:        Symbol {
// CHECK-SCRIPT:          Name: rw
// CHECK-SCRIPT-NEXT:     Value: 0x230000
// CHECK-SCRIPT-NEXT:     Size: 4
// CHECK-SCRIPT-NEXT:     Binding: Global
// CHECK-SCRIPT-NEXT:     Type: Object
// CHECK-SCRIPT-NEXT:     Other: 0
// CHECK-SCRIPT-NEXT:     Section: .data
// CHECK-SCRIPT-NEXT:   }

// CHECK-SCRIPT:        Symbol {
// CHECK-SCRIPT:          Name: bss
// CHECK-SCRIPT-NEXT:     Value: 0x230004
// CHECK-SCRIPT-NEXT:     Size: 4
// CHECK-SCRIPT-NEXT:     Binding: Global
// CHECK-SCRIPT-NEXT:     Type: Object
// CHECK-SCRIPT-NEXT:     Other: 0
// CHECK-SCRIPT-NEXT:     Section: .bss
// CHECK-SCRIPT-NEXT:   }


// CHECK-SCRIPT:      Hex dump of section '.data.rel.ro':

/// ro: address: 0x220000, size = 4, perms = RO(0x1)
// CHECK-SCRIPT-NEXT: 0x00220400 00002200 00000000 04000000 00000001

/// ro2: address: 0x220004, size = 4, perms = RO(0x1)
// CHECK-SCRIPT-NEXT: 0x00220410 04002200 00000000 04000000 00000001

/// _start: address: 0x210001, size = 4, perms = EXEC(0x4)
// CHECK-SCRIPT-NEXT: 0x00220420 00000000 00000000 00042200 00000004

/// func: address: 0x210005, size = 4, perms = EXEC(0x4)
// CHECK-SCRIPT-NEXT: 0x00220430 00000000 00000000 00042200 00000004

/// rw: address: 0x230000, size = 4, perms = RW(0x2)
// CHECK-SCRIPT-NEXT: 0x00220440 00002300 00000000 04000000 00000002

/// bss: address: 0x230004, size = 4, perms = RW(0x2)
// CHECK-SCRIPT-NEXT: 0x00220450 04002300 00000000 04000000 00000002
