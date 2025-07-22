// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=aarch64 -mattr=+morello,+c64 -target-abi purecap -cheri-cap-table-abi=fn-desc %s -o %tmain.o
// RUN: llvm-mc -filetype=obj -triple=aarch64 -mattr=+morello,+c64 -target-abi purecap -cheri-cap-table-abi=fn-desc %p/Inputs/morello-desc-abi_func.s -o %tfunc.o
// RUN: ld.lld %tmain.o %tfunc.o -o %tout
// RUN: llvm-readobj  --cap-relocs --relocs --symbols --sections %tout | FileCheck %s --check-prefixes=SEC,SYM,RELOCS,NOCAPRELOCS
// RUN: llvm-objdump --triple=aarch64 --no-show-raw-insn --print-imm-hex --section-headers -d %tout | FileCheck %s --check-prefix=DIS

/// For undefined symbols, in a shared object it is same as the CAPINIT.
// RUN: ld.lld %tfunc.o -shared -o %tshared
// RUN: llvm-readobj --relocs %tshared | FileCheck --check-prefix=SHARED_RELOCS %s

  .global _start
  .type _start,%function
  .text
_start:
  mov c28, c29
  ret
  .size _start, .-_start

// SEC:   Sections [
// SEC:     Name: .rela.dyn
// SEC-NEXT:   Type: SHT_RELA
// SEC-NEXT:   Flags
// SEC-NEXT:     SHF_ALLOC
// SEC-NEXT:     SHF_INFO_LINK
// SEC-NEXT:   ]
// SEC-NEXT:   Address: 0x200248
// SEC:     Name: .text
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:    SHF_ALLOC
// SEC-NEXT:    SHF_EXECINSTR
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x2102A8
// SEC:     Name: function
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:    SHF_ALLOC
// SEC-NEXT:    SHF_EXECINSTR
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x2102B0
// SEC:     Name: ifunction
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:    SHF_ALLOC
// SEC-NEXT:    SHF_EXECINSTR
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x2102B4
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
// SEC-NEXT: Address: [[#%#X,GOT_PLT_ADDR:]]
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
// RELOCS-NEXT:     [[#%#X,FUNCPTR1_ADDR:]] R_MORELLO_DESC_FUNC_RELATIVE - 0x100B1
// RELOCS-NEXT:     [[#%#X,FUNCPTR2_ADDR:]] R_MORELLO_DESC_FUNC_RELATIVE - 0x100B1
// RELOCS-NEXT:     [[#%#X,IFUNCPTR_ADDR:]] R_MORELLO_DESC_FUNC_RELATIVE - 0x100C0
// RELOCS-NEXT:     [[#%#X,GOT_PLT_ADDR]] R_MORELLO_DESC_IRELATIVE - 0x100B5
// RELOCS-NEXT:   }
// RELOCS-NEXT: ]

// SYM: Symbol {
// SYM:   Name: funcptr1
// SYM-NEXT:   Value: [[#%#X,FUNCPTR1_ADDR]]
// SYM-NEXT:   Size: 16
// SYM-NEXT:   Binding: Local
// SYM-NEXT:   Type: None
// SYM-NEXT:   Other: 0
// SYM-NEXT:   Section: .data
// SYM-NEXT: }
// SYM:   Name: funcptr2
// SYM-NEXT:   Value: [[#%#X,FUNCPTR2_ADDR]]
// SYM-NEXT:   Size: 16
// SYM-NEXT:   Binding: Local
// SYM-NEXT:   Type: None
// SYM-NEXT:   Other: 0
// SYM-NEXT:   Section: .data
// SYM:   Name: ifuncptr
// SYM-NEXT:   Value: [[#%#X,IFUNCPTR_ADDR]]
// SYM-NEXT:   Size: 16
// SYM-NEXT:   Binding: Local
// SYM-NEXT:   Type: None
// SYM-NEXT:   Other: 0
// SYM-NEXT:   Section: .data
// SYM:   Name: func
// SYM-NEXT:   Value: 0x2102B1
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

// NOCAPRELOCS:   There is no __cap_relocs section in the file.
// CAPRELOCS-NOT:   There is no __cap_relocs section in the file.

// DIS: .got.plt      00000040 [[#%X,GOT_PLT_ADDR:]] DATA
// DIS: 00000000002102c0 <ifunc>:
// DIS-NEXT: 2102c0:    adrdp c16, 0x0
// DIS-NEXT: 2102c4:    add c16, c16, #[[#%#X,GOT_PLT_ADDR-mul(div(GOT_PLT_ADDR,1024),1024)]]
// DIS-NEXT: 2102c8:    ldr c29, [c16, #0x0]
// DIS-NEXT: 2102cc:    ldpbr c29, [c29]


// SHARED_RELOCS: Relocations
// SHARED_RELOCS-NEXT:   .rela.dyn
// SHARED_RELOCS-NEXT:     0x400A0 R_MORELLO_CAPINIT func 0x0
// SHARED_RELOCS-NEXT:     0x400B0 R_MORELLO_CAPINIT func 0x0
// SHARED_RELOCS-NEXT:     0x400C0 R_MORELLO_CAPINIT ifunc 0x0
