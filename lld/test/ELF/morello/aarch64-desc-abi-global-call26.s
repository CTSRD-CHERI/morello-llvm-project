// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=aarch64 -target-abi purecap -cheri-cap-table-abi=fn-desc %s -o %tmain.o
// RUN: llvm-mc -filetype=obj -triple=aarch64 -mattr=+morello,+c64 -target-abi purecap -cheri-cap-table-abi=fn-desc %p/Inputs/morello-desc-abi_func.s -o %tfunc.o
// RUN: ld.lld --shared --strip-note-cheri %tmain.o %tfunc.o -o %tout
// RUN: llvm-readobj --symbols --sections --relocs %tout | FileCheck %s --check-prefix=SEC --check-prefix=SYM --check-prefix=RELOCS
// RUN: llvm-objdump --triple=aarch64 --no-show-raw-insn --print-imm-hex -d %tout | FileCheck %s --check-prefix=DIS
  .global _start
  .type _start,%function
  .text
_start:
  bl func
  bl func
  ret
  .size _start, .-_start


// SEC:   Name: .text
// SEC-NEXT:   Type: SHT_PROGBITS
// SEC-NEXT:   Flags [
// SEC-NEXT:     SHF_ALLOC
// SEC-NEXT:     SHF_EXECINSTR
// SEC-NEXT:   ]
// SEC-NEXT:   Address: 0x10390
// SEC:   Name: function
// SEC-NEXT:   Type: SHT_PROGBITS
// SEC-NEXT:   Flags [
// SEC-NEXT:     SHF_ALLOC
// SEC-NEXT:     SHF_EXECINSTR
// SEC-NEXT:   ]
// SEC-NEXT:   Address: 0x1039C
// SEC:   Name: ifunction
// SEC-NEXT:   Type: SHT_PROGBITS
// SEC-NEXT:   Flags [
// SEC-NEXT:     SHF_ALLOC
// SEC-NEXT:     SHF_EXECINSTR
// SEC-NEXT:   ]
// SEC-NEXT:   Address: 0x103A0
// SEC:   Name: __desc_cap_plts
// SEC-NEXT:   Type: SHT_PROGBITS
// SEC-NEXT:   Flags [
// SEC-NEXT:     SHF_ALLOC
// SEC-NEXT:     SHF_EXECINSTR
// SEC-NEXT:   ]
// SEC-NEXT:   Address: 0x103A8
// SEC-NEXT:   Offset:
// SEC-NEXT:   Size: 48
// SEC-NEXT:   Link: 0
// SEC-NEXT:   Info: 0
// SEC-NEXT:   AddressAlignment: 8
// SEC-NEXT:   EntrySize: 24
// SEC:   Name: .plt
// SEC-NEXT:   Type: SHT_PROGBITS
// SEC-NEXT:   Flags [
// SEC-NEXT:     SHF_ALLOC
// SEC-NEXT:     SHF_EXECINSTR
// SEC-NEXT:   ]
// SEC-NEXT:   Address: 0x103E0
// SEC-NEXT:   Offset:
// SEC-NEXT:   Size: 48
// SEC-NEXT:   Link: 0
// SEC-NEXT:   Info: 0
// SEC-NEXT:   AddressAlignment: 16
// SEC-NEXT:   EntrySize: 0
// SEC:   Name: .data
// SEC-NEXT:   Type: SHT_PROGBITS
// SEC-NEXT:   Flags [
// SEC-NEXT:     SHF_ALLOC
// SEC-NEXT:     SHF_WRITE
// SEC-NEXT:   ]
// SEC-NEXT:   Address: 0x304F0
// SEC:   Name: .got.plt
// SEC-NEXT:   Type: SHT_PROGBITS
// SEC-NEXT:   Flags [
// SEC-NEXT:     SHF_ALLOC
// SEC-NEXT:     SHF_WRITE
// SEC-NEXT:   ]
// SEC-NEXT:   Address: 0x30520
// SEC-NEXT:   Offset:
// SEC-NEXT:   Size: 96
// SEC-NEXT:   Link: 0
// SEC-NEXT:   Info: 0
// SEC-NEXT:   AddressAlignment: 16
// SEC-NEXT:   EntrySize: 0
// SEC-NEXT: }

// RELOCS:      Relocations [
// RELOCS-NEXT:   .rela.dyn {
// RELOCS-NEXT:     0x304F0 R_MORELLO_CAPINIT func 0x0
// RELOCS-NEXT:     0x30500 R_MORELLO_CAPINIT func 0x0
// RELOCS-NEXT:     0x30510 R_MORELLO_CAPINIT ifunc 0x0
// RELOCS-NEXT:   }
// RELOCS-NEXT:   .rela.plt {
// RELOCS-NEXT:     0x30550 R_MORELLO_DESC_JUMP_SLOT func 0x0
// RELOCS-NEXT:   }
// RELOCS-NEXT: ]

// SYM:     Name: funcptr1
// SYM-NEXT:     Value: 0x304F0
// SYM-NEXT:     Size: 16
// SYM-NEXT:     Binding: Local
// SYM-NEXT:     Type: None
// SYM-NEXT:     Other: 0
// SYM-NEXT:     Section: .data
// SYM:     Name: funcptr2
// SYM-NEXT:     Value: 0x30500
// SYM-NEXT:     Size: 16
// SYM-NEXT:     Binding: Local
// SYM-NEXT:     Type: None
// SYM-NEXT:     Other: 0
// SYM-NEXT:     Section: .data
// SYM:     Name: func
// SYM-NEXT:     Value: 0x1039D
// SYM-NEXT:     Size: 3
// SYM-NEXT:     Binding: Global
// SYM-NEXT:     Type: Function
// SYM-NEXT:     Other: 0
// SYM-NEXT:     Section: function
// SYM:     Name: ifunc
// SYM-NEXT:     Value: 0x103A1
// SYM-NEXT:     Size: 3
// SYM-NEXT:     Binding: Global
// SYM-NEXT:     Type: GNU_IFunc
// SYM-NEXT:     Other: 0
// SYM-NEXT:     Section: ifunction
// SYM:     Name: __descglobal_func
// SYM-NEXT:     Value: 0x103A9
// SYM-NEXT:     Size: 24
// SYM-NEXT:     Binding: Global
// SYM-NEXT:     Type: Function
// SYM-NEXT:     Other: 0
// SYM-NEXT:     Section: __desc_cap_plts

// DIS: 0000000000010390 <_start>:
// DIS-NEXT:   10390:  bl 0x10400
// DIS-NEXT:   10394:  bl 0x10400

// DIS: 000000000001039c <func>:
// DIS: 00000000000103a1 <ifunc>:

// DIS: 00000000000103a8 <__descglobal_func>:
// DIS-NEXT:   103a8:  mov c19, c28
// DIS-NEXT:   103ac:  mov c28, c29
// DIS-NEXT:   103b0:  mov c20, c30
// DIS-NEXT:   103b4:  bl 0x1039c <func
// DIS-NEXT:   103b8:  mov c28, c19
// DIS-NEXT:   103bc:  ret c20

// DIS: 00000000000103e0 <.plt>:
// DIS-NEXT:   103e0: stp c16, c30, [csp, #-0x20]!
// DIS-NEXT:   103e4: adrp c16, #0x20000
// DIS-NEXT:   103e8: ldr c17, [c16, #0x540]
// DIS-NEXT:   103ec: add c16, c16, #0x540
// DIS-NEXT:   103f0: ldpbr c29, [c16]
// DIS-NEXT:   103f4: nop
// DIS-NEXT:   103f8: nop
// DIS-NEXT:   103fc: nop
// DIS-NEXT:   10400: adrdp c16, #0x20000
// DIS-NEXT:   10404: add c16, c16, #0x550
// DIS-NEXT:   10408: ldr c29, [c16, #0x0]
// DIS-NEXT:   1040c: ldpbr c29, [c29]
