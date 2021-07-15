// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=aarch64 -mattr=+morello,+c64 -target-abi purecap -cheri-cap-table-abi=fn-desc %s -o %tmain.o
// RUN: llvm-mc -filetype=obj -triple=aarch64 -mattr=+morello,+c64 -target-abi purecap -cheri-cap-table-abi=fn-desc %p/Inputs/morello-desc-abi_func.s -o %tfunc.o
// RUN: ld.lld %tmain.o %tfunc.o -o %tout
// RUN: llvm-readobj  --cap-relocs --relocs --symbols --sections %tout | FileCheck %s --check-prefixes=SEC,SYM,RELOCS,NOCAPRELOCS
// RUN: llvm-objdump --triple=aarch64 --no-show-raw-insn --print-imm-hex -d %tout | FileCheck %s --check-prefix=DIS

/// Check that caprelocs section is generated when instructed explicitly
// RUN: ld.lld --morello-static-caps=legacy %tmain.o %tfunc.o -o %tcaprelocs
// RUN: llvm-readobj  --cap-relocs %tcaprelocs | FileCheck %s --check-prefix=CAPRELOCS

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
// SEC-NEXT:   Address: 0x200218
// SEC:     Name: .text
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:    SHF_ALLOC
// SEC-NEXT:    SHF_EXECINSTR
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x210278
// SEC:     Name: function
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:    SHF_ALLOC
// SEC-NEXT:    SHF_EXECINSTR
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x21027C
// SEC:     Name: ifunction
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:    SHF_ALLOC
// SEC-NEXT:    SHF_EXECINSTR
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x210280
// SEC:     Name: __desc_cap_plts
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:    SHF_ALLOC
// SEC-NEXT:    SHF_EXECINSTR
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x210288
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
// SEC-NEXT:     Address: 0x2102C0
// SEC-NEXT:     Offset:
// SEC-NEXT:     Size: 16
// SEC: Name: .got.plt
// SEC-NEXT: Type: SHT_PROGBITS
// SEC-NEXT: Flags [
// SEC-NEXT:   SHF_ALLOC
// SEC-NEXT:   SHF_WRITE
// SEC-NEXT: ]
// SEC-NEXT: Address: 0x230000
// SEC-NEXT: Offset:
// SEC-NEXT: Size: 64
// SEC:     Name: .data
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:    SHF_ALLOC
// SEC-NEXT:    SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x230040
// SEC-NEXT:     Offset:
// SEC-NEXT:     Size: 48

// RELOCS: Relocations [
// RELOCS-NEXT:   .rela.dyn {
// RELOCS-NEXT:     0x230040 R_MORELLO_DESC_FUNC_RELATIVE - 0x10089
// RELOCS-NEXT:     0x230050 R_MORELLO_DESC_FUNC_RELATIVE - 0x10089
// RELOCS-NEXT:     0x230060 R_MORELLO_DESC_FUNC_RELATIVE - 0x100A1
// RELOCS-NEXT:     0x230000 R_MORELLO_DESC_IRELATIVE - 0x10081
// RELOCS-NEXT:   }
// RELOCS-NEXT: ]

// SYM: Symbol {
// SYM:   Name: funcptr1
// SYM-NEXT:   Value: 0x230040
// SYM-NEXT:   Size: 16
// SYM-NEXT:   Binding: Local
// SYM-NEXT:   Type: None
// SYM-NEXT:   Other: 0
// SYM-NEXT:   Section: .data
// SYM-NEXT: }
// SYM:   Name: funcptr2
// SYM-NEXT:   Value: 0x230050
// SYM-NEXT:   Size: 16
// SYM-NEXT:   Binding: Local
// SYM-NEXT:   Type: None
// SYM-NEXT:   Other: 0
// SYM-NEXT:   Section: .data
// SYM:   Name: ifuncptr
// SYM-NEXT:   Value: 0x230060
// SYM-NEXT:   Size: 16
// SYM-NEXT:   Binding: Local
// SYM-NEXT:   Type: None
// SYM-NEXT:   Other: 0
// SYM-NEXT:   Section: .data
// SYM:   Name: func
// SYM-NEXT:   Value: 0x21027D
// SYM-NEXT:   Size: 3
// SYM-NEXT:   Binding: Global
// SYM-NEXT:   Type: Function
// SYM-NEXT:   Other: 0
// SYM-NEXT:   Section: function
// SYM:   Name: ifunc
// SYM-NEXT:   Value: 0x2102C0
// SYM-NEXT:   Size: 0
// SYM-NEXT:   Binding: Global
// SYM-NEXT:   Type: Function
// SYM-NEXT:   Other: 0
// SYM-NEXT:   Section: .iplt
// SYM:   Name: __descglobal_func
// SYM-NEXT:   Value: 0x210289
// SYM-NEXT:   Size: 24
// SYM-NEXT:   Binding: Global
// SYM-NEXT:   Type: Function
// SYM-NEXT:   Other: 0
// SYM-NEXT:   Section: __desc_cap_plts
// SYM:   Name: __descglobal_ifunc
// SYM-NEXT:   Value: 0x2102A1
// SYM-NEXT:   Size: 24
// SYM-NEXT:   Binding: Global
// SYM-NEXT:   Type: Function
// SYM-NEXT:   Other: 0
// SYM-NEXT:   Section: __desc_cap_plts

// NOCAPRELOCS:   There is no __cap_relocs section in the file.
// CAPRELOCS-NOT:   There is no __cap_relocs section in the file.

// DIS: 0000000000210288 <__descglobal_func>:
// DIS-NEXT: 210288:    mov c19, c28
// DIS-NEXT: 21028c:    mov c28, c29
// DIS-NEXT: 210290:    mov c20, c30
// DIS-NEXT: 210294:    bl  0x21027c <func
// DIS-NEXT: 210298:    mov c28, c19
// DIS-NEXT: 21029c:    ret c20

// DIS: 00000000002102a0 <__descglobal_ifunc>:
// DIS-NEXT: 2102a0:    mov c19, c28
// DIS-NEXT: 2102a4:    mov c28, c29
// DIS-NEXT: 2102a8:    mov c20, c30
// DIS-NEXT: 2102ac:    bl  0x2102bc <__descglobal_ifunc
// DIS-NEXT: 2102b0:    mov c28, c19
// DIS-NEXT: 2102b4:    ret c20

// DIS: 00000000002102c0 <ifunc>:
// DIS-NEXT: 2102c0:    adrdp c16, #0x20000
// DIS-NEXT: 2102c4:    add c16, c16, #0x0
// DIS-NEXT: 2102c8:    ldr c29, [c16, #0x0]
// DIS-NEXT: 2102cc:    ldpbr c29, [c29]


// SHARED_RELOCS: Relocations
// SHARED_RELOCS-NEXT:   .rela.dyn
// SHARED_RELOCS-NEXT:     0x400A0 R_MORELLO_CAPINIT func 0x0
// SHARED_RELOCS-NEXT:     0x400B0 R_MORELLO_CAPINIT func 0x0
// SHARED_RELOCS-NEXT:     0x400C0 R_MORELLO_CAPINIT ifunc 0x0
