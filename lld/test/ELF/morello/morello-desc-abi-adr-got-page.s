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


// SEC:   Sections [
// SEC:     Name: .desc.data
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x390
// SEC:     Name: .text
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_EXECINSTR
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x1239C
// SEC:     Name: .data.rel.ro
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x223B4
// SEC:     Name: .got
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x24460
// SEC:     Name: .data
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x344C0

// RELOCS: Relocations [
// RELOCS-NEXT: .rela.dyn
// RELOCS-NEXT: 0x24470 R_MORELLO_GLOB_DAT bye 0x0
// RELOCS-NEXT: 0x24480 R_MORELLO_GLOB_DAT foo 0x0
// RELOCS-NEXT: 0x24460 R_MORELLO_GLOB_DAT hello 0x0

// SYM:    Name: bye
// SYM-NEXT:    Value: 0x2390
// SYM-NEXT:    Size: 10
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: Object
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .desc.data
// SYM-NEXT:  }
// SYM-NEXT:  Symbol {
// SYM-NEXT:    Name: foo
// SYM-NEXT:    Value: 0x243B4
// SYM-NEXT:    Size: 4
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: Object
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .data.rel.ro
// SYM-NEXT:  }
// SYM-NEXT:  Symbol {
// SYM-NEXT:    Name: hello
// SYM-NEXT:    Value: 0x344D4
// SYM-NEXT:    Size: 12
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: Object
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .data
// SYM-NEXT:  }

// GOT: Hex dump of section '.got'
// GOT-NEXT: 0x00024460 d4440300 00000000 0c000000 00000002
// GOT-NEXT: 0x00024470 90230000 00000000 0a000000 00000001
// GOT-NEXT: 0x00024480 b4430200 00000000 04000000 00000001

// DIS: 000000000001239c <_start>:

/// Immediate of adrdp = Page(GOT(hello)) - Page(.data) =
/// Page(0x24450) - Page(0x34480 =
/// 0x24000 - 34000 =
/// #0xffff0000
// DIS: 1239c: adrdp	c5, #0xffff0000
// DIS: 123a0: ldr  c5, [c5, #0x460]

/// Immediate of adrdp = Page(GOT(bye)) - Page(.desc.data) =
/// Page(0x24460) - Page(0x390) =
/// 0x24000 - 0 =
/// 0x24000
// DIS: 123a4: adrdp	c6, #0x24000
// DIS: 123a8: ldr  c6, [c6, #0x470]

/// Immediate of adrdp = Page(GOT(foo)) - Page(location) =
/// Page(0x24470) - Page(123a4) =
/// 0x24000 - 0x12000 =
/// 0x12000
// DIS: 123ac: adrp	c7, #0x12000
// DIS: 123b0: ldr  c7, [c7, #0x480]

// STATIC_UNDEF: error: undefined symbol: hello

// SHARED_RELOCS: Relocations
// SHARED_RELOCS-NEXT: .rela.dyn
// SHARED_RELOCS-NEXT: 0x20410 R_MORELLO_GLOB_DAT bye 0x0
// SHARED_RELOCS-NEXT: 0x20420 R_MORELLO_GLOB_DAT foo 0x0
// SHARED_RELOCS-NEXT: 0x20400 R_MORELLO_GLOB_DAT hello 0x0


// SHARED_SYM:  Symbol
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
// SHARED_GOT-NEXT: 0x00020400 00000000 00000000 00000000 00000002
// SHARED_GOT-NEXT: 0x00020410 00000000 00000000 00000000 00000002
// SHARED_GOT-NEXT: 0x00020420 00000000 00000000 00000000 00000002

/// Because all symbols are undefined, the adrp instruction is used.
/// Immediate of adrp = Page(GOT(symbol)) - Page(location) =
/// Page(0x203X0) - Page(0x10308) =
/// 0x20000 - 10000 =
/// 0x10000

// SHARED_DIS: 0000000000010340 <_start>:
// SHARED_DIS: 10340: adrp	c5, #0x10000
// SHARED_DIS: 10344: ldr  c5, [c5, #0x400]
// SHARED_DIS: 10348: adrp	c6, #0x10000
// SHARED_DIS: 1034c: ldr  c6, [c6, #0x410]
// SHARED_DIS: 10350: adrp	c7, #0x10000
// SHARED_DIS: 10354: ldr  c7, [c7, #0x420]
