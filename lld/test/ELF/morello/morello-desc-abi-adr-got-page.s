// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=aarch64 -mattr=+morello,+c64 -target-abi purecap -cheri-cap-table-abi=fn-desc %s -o %tmain.o
// RUN: llvm-mc -filetype=obj -triple=aarch64 -mattr=+morello,+c64 -target-abi purecap -cheri-cap-table-abi=fn-desc %p/Inputs/morello-desc-abi_data.s -o %tdata.o
// RUN: ld.lld -shared %tmain.o %tdata.o -o %tout
// RUN: llvm-readobj --symbols --sections --relocs -x .got %tout | FileCheck --check-prefix=SEC --check-prefix=SYM --check-prefix=RELOCS --check-prefix=GOT %s
// RUN: llvm-objdump --triple=aarch64 --no-show-raw-insn --print-imm-hex -d  %tout | FileCheck --check-prefix=DIS %s

/// Do error checking.
/// Expect undefined symbol error for Executable output.
// RUN: not ld.lld %tmain.o -o /dev/null 2>&1 \
// RUN:   | FileCheck %s --check-prefix=STATIC_UNDEF

/// Similar to the R_MORELLO_ADR_GOT_PAGE case.
// RUN: ld.lld %tmain.o -shared -o %tmain.so
// RUN: llvm-readobj --symbols --sections --relocs -x .got %tmain.so \
// RUN:   | FileCheck --check-prefix=SHARED_SYM --check-prefix=SHARED_RELOCS --check-prefix=SHARED_GOT %s
// RUN: llvm-objdump --triple=aarch64 --no-show-raw-insn --print-imm-hex -d  %tmain.so | FileCheck --check-prefix=SHARED_DIS %s

  .globl _start
  .type _start, %function
  .text
_start:
  /// "hello" is in .data.
  /// So expect this to be converted into an adrdp
  adrp c5, :got:hello
  ldr c5, [c5, :got_lo12:hello]
  /// "bye" is in section .descdata.
  /// So expect this to be converted into an adrdp
  adrp c6, :got:bye
  ldr c6, [c6, :got_lo12:bye]
  /// "foo" is in section .data.rel.ro.
  /// So expect this to remain adrp
  adrp c7, :got:foo
  ldr c7, [c7, :got_lo12:foo]
  /// "bar" is in section .desc.data.rel.ro.
  /// So expect this to be converted into an adrdp
  adrp c8, :got:bar
  ldr c8, [c8, :got_lo12:bar]


// SEC:   Sections [
// SEC:     Name: .desc.data
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x568
// SEC:     Name: .text
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_EXECINSTR
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x12574
// SEC:     Name: .data.rel.ro
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x22594
// SEC:     Name: .desc.data.rel.ro
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x40000
// SEC:     Name: .got
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x42010
// SEC:     Name: .data
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x42080
// SEC:     Name: .init_array
// SEC-NEXT:     Type: SHT_INIT_ARRAY
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x420C0
// SEC:     Name: .fini_array
// SEC-NEXT:     Type: SHT_FINI_ARRAY
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x420C8
// SEC:     Name: .bss
// SEC-NEXT:     Type: SHT_NOBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x42108

// RELOCS: Relocations [
// RELOCS-NEXT: .rela.dyn
// RELOCS-NEXT: 0x42040 R_MORELLO_DESC_GLOB_DAT bar 0x0
// RELOCS-NEXT: 0x420A8 R_AARCH64_ABS64 __desc_end 0x0
// RELOCS-NEXT: 0x420B8 R_AARCH64_ABS64 __desc_ro_end 0x0
// RELOCS-NEXT: 0x42020 R_MORELLO_DESC_GLOB_DAT bye 0x0
// RELOCS-NEXT: 0x42030 R_MORELLO_DESC_GLOB_DAT foo 0x0
// RELOCS-NEXT: 0x42010 R_MORELLO_DESC_GLOB_DAT hello 0x0
// RELOCS-NEXT: 0x420B0 R_AARCH64_ABS64 __desc_ro_start 0x0
// RELOCS-NEXT: 0x420A0 R_AARCH64_ABS64 __desc_start 0x0

// SYM:    Name: bar
// SYM-NEXT:    Value: 0x42000
// SYM-NEXT:    Size: 4
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: Object
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .desc.data.rel.ro
// SYM-NEXT:  }
// SYM:    Name: bye
// SYM-NEXT:    Value: 0x2568
// SYM-NEXT:    Size: 10
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: Object
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .desc.data
// SYM-NEXT:  }
// SYM-NEXT:  Symbol {
// SYM-NEXT:    Name: foo
// SYM-NEXT:    Value: 0x24594
// SYM-NEXT:    Size: 4
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: Object
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .data.rel.ro
// SYM-NEXT:  }
// SYM-NEXT:  Symbol {
// SYM-NEXT:    Name: hello
// SYM-NEXT:    Value: 0x42094
// SYM-NEXT:    Size: 12
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: Object
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .data
// SYM-NEXT:  }
// SYM-NEXT:  Symbol {
// SYM-NEXT:    Name: __desc_end
// SYM-NEXT:    Value: 0x4210C
// SYM-NEXT:    Size: 0
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: None
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .bss
// SYM-NEXT:  }
// SYM-NEXT:  Symbol {
// SYM-NEXT:    Name: __desc_ro_end
// SYM-NEXT:    Value: 0x40000
// SYM-NEXT:    Size: 0
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: None
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .desc.data.rel.ro
// SYM-NEXT:  }
// SYM-NEXT:  Symbol {
// SYM-NEXT:    Name: __desc_ro_start
// SYM-NEXT:    Value: 0x40000
// SYM-NEXT:    Size: 0
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: None
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .desc.data.rel.ro
// SYM-NEXT:  }
// SYM-NEXT:  Symbol {
// SYM-NEXT:    Name: __desc_start
// SYM-NEXT:    Value: 0x40000
// SYM-NEXT:    Size: 0
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: None
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .desc.data.rel.ro
// SYM-NEXT:  }
// SYM-NEXT:  Symbol {
// SYM-NEXT:    Name: bss
// SYM-NEXT:    Value: 0x42108
// SYM-NEXT:    Size: 4
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: Object
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .bss
// SYM-NEXT:  }

// GOT: Hex dump of section '.got'
// GOT-NEXT: 0x00042010 94200400 00000000 0c000000 00000002
// GOT-NEXT: 0x00042020 68250000 00000000 0a000000 00000001
// GOT-NEXT: 0x00042030 94450200 00000000 04000000 00000001
// GOT-NEXT: 0x00042040 00200400 00000000 04000000 00000002
// GOT-NEXT: 0x00042050 00000000 00000000 00000000 00000000
// GOT-NEXT: 0x00042060 00000000 00000000 00000000 00000000
// GOT-NEXT: 0x00042070 00000000 00000000 00000000 00000000

// DIS: 0000000000012574 <_start>:

/// Immediate of adrdp = Page(GOT(hello)) - Page(PT_MORELLO_DESC) =
/// Page(0x42010) - Page(0x40000) =
/// 0x42000 - 0x40000 =
/// 0x42000
// DIS: 12574: adrdp	c5, #0x2000
// DIS: 12578: ldr  c5, [c5, #0x10]

/// Immediate of adrdp = Page(GOT(bye)) - Page(PT_MORELLO_DESC) =
/// Page(0x42020) - Page(0x40000) =
/// 0x42000 - 0x40000 =
/// 0x2000
// DIS: 1257c: adrdp	c6, #0x2000
// DIS: 12580: ldr  c6, [c6, #0x20]

/// Immediate of adrp = Page(GOT(foo)) - Page(PT_MORELLO_DESC) =
/// Page(0x42030) - Page(0x40000) =
/// 0x42000 - 0x40000 =
/// 0x2000
// DIS: 12584: adrdp	c7, #0x2000
// DIS: 12588: ldr  c7, [c7, #0x30]

/// Immediate of adrdp = Page(GOT(bar)) - Page(PT_MORELLO_DESC) =
/// Page(0x42040) - Page(0x40000) =
/// 0x42000 - 0x40000 =
/// 0x2000
// DIS: 1258c: adrdp	c8, #0x2000
// DIS: 12590: ldr  c8, [c8, #0x40]


// STATIC_UNDEF: error: undefined symbol: hello

// SHARED_RELOCS: Relocations
// SHARED_RELOCS-NEXT: .rela.dyn
// SHARED_RELOCS-NEXT: 0x40030 R_MORELLO_DESC_GLOB_DAT bar 0x0
// SHARED_RELOCS-NEXT: 0x40010 R_MORELLO_DESC_GLOB_DAT bye 0x0
// SHARED_RELOCS-NEXT: 0x40020 R_MORELLO_DESC_GLOB_DAT foo 0x0
// SHARED_RELOCS-NEXT: 0x40000 R_MORELLO_DESC_GLOB_DAT hello 0x0


// SHARED_SYM:  Symbol
// SHARED-SYM:    Name: bar
// SHARED-SYM-NEXT:    Value: 0x0
// SHARED-SYM-NEXT:    Size: 0
// SHARED-SYM-NEXT:    Binding: Global
// SHARED-SYM-NEXT:    Type: None
// SHARED-SYM-NEXT:    Other: 0
// SHARED-SYM-NEXT:    Section: Undefined
// SHARED-SYM-NEXT:  }
// SHARED_SYM:    Name: bye
// SHARED_SYM-NEXT:    Value: 0x0
// SHARED_SYM-NEXT:    Size: 0
// SHARED_SYM-NEXT:    Binding: Global
// SHARED_SYM-NEXT:    Type: None
// SHARED_SYM-NEXT:    Other: 0
// SHARED_SYM-NEXT:    Section: Undefined
// SHARED_SYM-NEXT:  }
// SHARED_SYM:    Name: foo
// SHARED_SYM-NEXT:    Value: 0x0
// SHARED_SYM-NEXT:    Size: 0
// SHARED_SYM-NEXT:    Binding: Global
// SHARED_SYM-NEXT:    Type: None
// SHARED_SYM-NEXT:    Other: 0
// SHARED_SYM-NEXT:    Section: Undefined
// SHARED_SYM-NEXT:  }
// SHARED_SYM-NEXT:  Symbol
// SHARED_SYM-NEXT:    Name: hello
// SHARED_SYM-NEXT:    Value: 0x0
// SHARED_SYM-NEXT:    Size: 0
// SHARED_SYM-NEXT:    Binding: Global
// SHARED_SYM-NEXT:    Type: None
// SHARED_SYM-NEXT:    Other: 0
// SHARED_SYM-NEXT:    Section: Undefined
// SHARED_SYM-NEXT:  }

// SHARED_GOT: Hex dump of section '.got'
// SHARED_GOT-NEXT: 0x00040000 00000000 00000000 00000000 00000002
// SHARED_GOT-NEXT: 0x00040010 00000000 00000000 00000000 00000002
// SHARED_GOT-NEXT: 0x00040020 00000000 00000000 00000000 00000002
// SHARED_GOT-NEXT: 0x00040030 00000000 00000000 00000000 00000002

/// Because all symbols are loaded from the GOT, and the GOT is
/// in the private data segment, the adrdp instruction is used.
/// Immediate of adrp = Page(GOT(symbol)) - Page(PT_MORELLO_DESC) =
/// Page(0x400X0) - Page(0x40000) =
/// 0x40000 - 40000 =
/// 0x0

// SHARED_DIS: 0000000000010400 <_start>:
// SHARED_DIS: 10400: adrdp	c5, #0x0
// SHARED_DIS: 10404: ldr  c5, [c5, #0x0]
// SHARED_DIS: 10408: adrdp	c6, #0x0
// SHARED_DIS: 1040c: ldr  c6, [c6, #0x10]
// SHARED_DIS: 10410: adrdp	c7, #0x0
// SHARED_DIS: 10414: ldr  c7, [c7, #0x20]
// SHARED_DIS: 10418: adrdp	c8, #0x0
// SHARED_DIS: 1041c: ldr  c8, [c8, #0x30]