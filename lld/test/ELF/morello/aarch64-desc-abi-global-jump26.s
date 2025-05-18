// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=aarch64 -target-abi purecap -cheri-cap-table-abi=fn-desc %s -o %tmain.o
// RUN: llvm-mc -filetype=obj -triple=aarch64 -mattr=+morello,+c64 -target-abi purecap -cheri-cap-table-abi=fn-desc %p/Inputs/morello-desc-abi_func.s -o %tfunc.o
// RUN: ld.lld --shared  %tmain.o %tfunc.o -o %tout
// RUN: llvm-readobj --symbols --sections --relocs %tout | FileCheck %s --check-prefix=SEC --check-prefix=SYM --check-prefix=RELOCS
// RUN: llvm-objdump --triple=aarch64 --no-show-raw-insn --print-imm-hex -d %tout | FileCheck %s --check-prefix=DIS
  .global _start
  .type _start,%function
  .text
_start:
  b func
  b func
  ret
  .size _start, .-_start


// SEC:   Name: .text
// SEC-NEXT:   Type: SHT_PROGBITS
// SEC-NEXT:   Flags [
// SEC-NEXT:     SHF_ALLOC
// SEC-NEXT:     SHF_EXECINSTR
// SEC-NEXT:   ]
// SEC-NEXT:   Address: 0x103F0
// SEC:   Name: function
// SEC-NEXT:   Type: SHT_PROGBITS
// SEC-NEXT:   Flags [
// SEC-NEXT:     SHF_ALLOC
// SEC-NEXT:     SHF_EXECINSTR
// SEC-NEXT:   ]
// SEC-NEXT:   Address: 0x103FC
// SEC:   Name: ifunction
// SEC-NEXT:   Type: SHT_PROGBITS
// SEC-NEXT:   Flags [
// SEC-NEXT:     SHF_ALLOC
// SEC-NEXT:     SHF_EXECINSTR
// SEC-NEXT:   ]
// SEC-NEXT:   Address: 0x10400
// SEC:   Name: .plt
// SEC-NEXT:   Type: SHT_PROGBITS
// SEC-NEXT:   Flags [
// SEC-NEXT:     SHF_ALLOC
// SEC-NEXT:     SHF_EXECINSTR
// SEC-NEXT:   ]
// SEC-NEXT:   Address: 0x10410
// SEC-NEXT:   Offset:
// SEC-NEXT:   Size: 48
// SEC-NEXT:   Link: 0
// SEC-NEXT:   Info: 0
// SEC-NEXT:   AddressAlignment: 16
// SEC-NEXT:   EntrySize: 0
// SEC:   Name: .got.plt
// SEC-NEXT:   Type: SHT_PROGBITS
// SEC-NEXT:   Flags [
// SEC-NEXT:     SHF_ALLOC
// SEC-NEXT:     SHF_WRITE
// SEC-NEXT:   ]
// SEC-NEXT:   Address: 0x400E0
// SEC-NEXT:   Offset:
// SEC-NEXT:   Size: 96
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
// SEC-NEXT:   Address: 0x40140

// RELOCS:      Relocations [
// RELOCS-NEXT:   .rela.dyn {
// RELOCS-NEXT:     0x40140 R_MORELLO_CAPINIT func 0x0
// RELOCS-NEXT:     0x40150 R_MORELLO_CAPINIT func 0x0
// RELOCS-NEXT:     0x40160 R_MORELLO_CAPINIT ifunc 0x0
// RELOCS-NEXT:   }
// RELOCS-NEXT:   .rela.plt {
// RELOCS-NEXT:     0x40110 R_MORELLO_DESC_JUMP_SLOT func 0x0
// RELOCS-NEXT:   }
// RELOCS-NEXT: ]

// SYM:     Name: funcptr1
// SYM-NEXT:     Value: 0x40140
// SYM-NEXT:     Size: 16
// SYM-NEXT:     Binding: Local
// SYM-NEXT:     Type: None
// SYM-NEXT:     Other: 0
// SYM-NEXT:     Section: .data
// SYM:     Name: funcptr2
// SYM-NEXT:     Value: 0x40150
// SYM-NEXT:     Size: 16
// SYM-NEXT:     Binding: Local
// SYM-NEXT:     Type: None
// SYM-NEXT:     Other: 0
// SYM-NEXT:     Section: .data
// SYM:     Name: ifuncptr
// SYM-NEXT:     Value: 0x40160
// SYM-NEXT:     Size: 16
// SYM-NEXT:     Binding: Local
// SYM-NEXT:     Type: None
// SYM-NEXT:     Other: 0
// SYM-NEXT:     Section: .data
// SYM:     Name: func
// SYM-NEXT:     Value: 0x103FD
// SYM-NEXT:     Size: 3
// SYM-NEXT:     Binding: Global
// SYM-NEXT:     Type: Function
// SYM-NEXT:     Other: 0
// SYM-NEXT:     Section: function
// SYM:     Name: ifunc
// SYM-NEXT:     Value: 0x10401
// SYM-NEXT:     Size: 3
// SYM-NEXT:     Binding: Global
// SYM-NEXT:     Type: GNU_IFunc
// SYM-NEXT:     Other: 0
// SYM-NEXT:     Section: ifunction

// DIS: 00000000000103f0 <_start>:
// DIS-NEXT:   103f0:  b 0x10430
// DIS-NEXT:   103f4:  b 0x10430

// DIS: 00000000000103fc <func>:
// DIS: 0000000000010401 <ifunc>:

// DIS: 0000000000010410 <.plt>:
// DIS-NEXT:   10410: stp c16, c30, [csp, #-0x20]!
// DIS-NEXT:   10414: adrdp c16, 0x10000
// DIS-NEXT:   10418: ldr c17, [c16, #0x100]
// DIS-NEXT:   1041c: add c16, c16, #0x100
// DIS-NEXT:   10420: ldpbr c29, [c16]
// DIS-NEXT:   10424: nop
// DIS-NEXT:   10428: nop
// DIS-NEXT:   1042c: nop
// DIS-NEXT:   10430: adrdp c16, 0x10000
// DIS-NEXT:   10434: add c16, c16, #0x110
// DIS-NEXT:   10438: ldr c29, [c16, #0x0]
// DIS-NEXT:   1043c: ldpbr c29, [c29]
