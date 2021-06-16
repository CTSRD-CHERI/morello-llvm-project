// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=aarch64 -mattr=+morello,+c64 -target-abi purecap -cheri-cap-table-abi=fn-desc %s -o %tmain.o
// RUN: llvm-mc -filetype=obj -triple=aarch64 -mattr=+morello,+c64 -target-abi purecap -cheri-cap-table-abi=fn-desc %p/Inputs/morello-desc-abi_func.s -o %tfunc.o
// RUN: ld.lld --strip-note-cheri %tmain.o %tfunc.o -o %tout
// RUN: llvm-readobj --relocs --symbols --sections %tout | FileCheck --check-prefix=SEC --check-prefix=SYM %s
// RUN: llvm-objdump --triple=aarch64 --no-show-raw-insn --print-imm-hex -d %tout | FileCheck --check-prefix=DIS %s

/// For undefined symbols, in a shared object it is same as the CAPINIT.
// RUN: ld.lld %tfunc.o -shared -o %tshared
// RUN: llvm-readobj --relocs %tshared | FileCheck --check-prefix=SHARED_RELOCS %s

  .global _start
  .type _start,%function
  .text
_start:
  ret
  .size _start, .-_start

// SEC:   Sections [
// SEC:     Name: .rela.dyn
// SEC-NEXT:   Type: SHT_RELA
// SEC-NEXT:   Flags
// SEC-NEXT:     SHF_ALLOC
// SEC-NEXT:   ]
// SEC-NEXT:   Address: 0x200200
// SEC:     Name: .text
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:    SHF_ALLOC
// SEC-NEXT:    SHF_EXECINSTR
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x210218
// SEC:     Name: function
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:    SHF_ALLOC
// SEC-NEXT:    SHF_EXECINSTR
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x21021C
// SEC:     Name: ifunction
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:    SHF_ALLOC
// SEC-NEXT:    SHF_EXECINSTR
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x210220
// SEC:     Name: __desc_cap_plts
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:    SHF_ALLOC
// SEC-NEXT:    SHF_EXECINSTR
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x210228
// SEC-NEXT:     Offset:
// SEC-NEXT:     Size: 48
// SEC-NEXT:     Link: 0
// SEC-NEXT:     Info: 0
// SEC-NEXT:     AddressAlignment: 8
// SEC-NEXT:     EntrySize: 24
// SEC:     Name: .iplt
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:    SHF_ALLOC
// SEC-NEXT:    SHF_EXECINSTR
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x210260
// SEC-NEXT:     Offset:
// SEC-NEXT:     Size: 16
// SEC:  Name: __cap_relocs
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:    SHF_ALLOC
// SEC-NEXT:    SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x220270
// SEC-NEXT:     Offset:
// SEC-NEXT:     Size: 120
// SEC:     Name: .data
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:    SHF_ALLOC
// SEC-NEXT:    SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x2302E8
// SEC: Name: .got.plt
// SEC-NEXT: Type: SHT_PROGBITS
// SEC-NEXT: Flags [
// SEC-NEXT:   SHF_ALLOC
// SEC-NEXT:   SHF_WRITE
// SEC-NEXT: ]
// SEC-NEXT: Address: 0x230320
// SEC-NEXT: Offset:
// SEC-NEXT: Size: 32

// RELOCS: Relocations [
// RELOCS-NEXT:   .rela.dyn {
// RELOCS-NEXT:     0x230320 R_MORELLO_IRELATIVE - 0x21021D
// RELOCS-NEXT:   }
// RELOCS-NEXT: ]

// SYM: Symbol {
// SYM:   Name: funcptr1
// SYM-NEXT:   Value: 0x2302E8
// SYM-NEXT:   Size: 16
// SYM-NEXT:   Binding: Local
// SYM-NEXT:   Type: None
// SYM-NEXT:   Other: 0
// SYM-NEXT:   Section: .data
// SYM-NEXT: }
// SYM:   Name: funcptr2
// SYM-NEXT:   Value: 0x2302F8
// SYM-NEXT:   Size: 16
// SYM-NEXT:   Binding: Local
// SYM-NEXT:   Type: None
// SYM-NEXT:   Other: 0
// SYM-NEXT:   Section: .data
// SYM:   Name: ifuncptr
// SYM-NEXT:   Value: 0x230308
// SYM-NEXT:   Size: 16
// SYM-NEXT:   Binding: Local
// SYM-NEXT:   Type: None
// SYM-NEXT:   Other: 0
// SYM-NEXT:   Section: .data
// SYM:   Name: func
// SYM-NEXT:   Value: 0x21021D
// SYM-NEXT:   Size: 3
// SYM-NEXT:   Binding: Global
// SYM-NEXT:   Type: Function
// SYM-NEXT:   Other: 0
// SYM-NEXT:   Section: function
// SYM:   Name: ifunc
// SYM-NEXT:   Value: 0x210260
// SYM-NEXT:   Size: 0
// SYM-NEXT:   Binding: Global
// SYM-NEXT:   Type: Function
// SYM-NEXT:   Other: 0
// SYM-NEXT:   Section: .iplt
// SYM:   Name: __descglobal_func
// SYM-NEXT:   Value: 0x210229
// SYM-NEXT:   Size: 24
// SYM-NEXT:   Binding: Global
// SYM-NEXT:   Type: Function
// SYM-NEXT:   Other: 0
// SYM-NEXT:   Section: __desc_cap_plts
// SYM:   Name: __descglobal_ifunc
// SYM-NEXT:   Value: 0x210241
// SYM-NEXT:   Size: 24
// SYM-NEXT:   Binding: Global
// SYM-NEXT:   Type: Function
// SYM-NEXT:   Other: 0
// SYM-NEXT:   Section: __desc_cap_plts


// DIS: 0000000000210228 <__descglobal_func>:
// DIS-NEXT: 210228:    mov c19, c28
// DIS-NEXT: 21022c:    mov c28, c29
// DIS-NEXT: 210230:    mov c20, c30
// DIS-NEXT: 210234:    bl  0x21021c <func
// DIS-NEXT: 210238:    mov c28, c19
// DIS-NEXT: 21023c:    ret c20

// DIS: 0000000000210240 <__descglobal_ifunc>:
// DIS-NEXT: 210240:    mov c19, c28
// DIS-NEXT: 210244:    mov c28, c29
// DIS-NEXT: 210248:    mov c20, c30
// DIS-NEXT: 21024c:    bl  0x21025c <__descglobal_ifunc
// DIS-NEXT: 210250:    mov c28, c19
// DIS-NEXT: 210254:    ret c20

// DIS: 0000000000210260 <ifunc>:
// DIS-NEXT: 210260:    adrdp c16, #0x20000
// DIS-NEXT: 210264:    add c16, c16, #0x320
// DIS-NEXT: 210268:    ldr c29, [c16, #0x0]
// DIS-NEXT: 21026c:    ldpbr c29, [c29]


// SHARED_RELOCS: Relocations
// SHARED_RELOCS-NEXT:   .rela.dyn
// SHARED_RELOCS-NEXT:     0x30480 R_MORELLO_CAPINIT func 0x0
// SHARED_RELOCS-NEXT:     0x30490 R_MORELLO_CAPINIT func 0x0
// SHARED_RELOCS-NEXT:     0x304A0 R_MORELLO_CAPINIT ifunc 0x0
