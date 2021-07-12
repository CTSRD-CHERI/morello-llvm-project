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

  .globl _start
  .type _start, %function
  .text
_start:
  /// Because all symbols are loaded from the GOT, and the GOT is
  /// in the private data segment, the adrdp instruction is used.
  /// "hello" is in .data.
  adrp c5, :got:hello
  ldr c5, [c5, :got_lo12:hello]
  /// "bye" is in section .desc.data.
  adrp c6, :got:bye
  ldr c6, [c6, :got_lo12:bye]
  /// "foo" is in section .data.rel.ro.
  adrp c7, :got:foo
  ldr c7, [c7, :got_lo12:foo]
  /// "bar" is in section .desc.data.rel.ro.
  adrp c8, :got:bar
  ldr c8, [c8, :got_lo12:bar]


// SEC:   Sections [
// SEC:     Name: .desc.data
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x440
// SEC:     Name: .text
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_EXECINSTR
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x1244C
// SEC:     Name: .data.rel.ro
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x2246C
// SEC:     Name: .desc.data.rel.ro
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x30000
// SEC:     Name: .got
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x320B0
// SEC:     Name: .data
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x42100

// RELOCS: Relocations [
// RELOCS-NEXT: .rela.dyn
// RELOCS-NEXT: 0x320E0 R_MORELLO_DESC_GLOB_DAT bar 0x0
// RELOCS-NEXT: 0x320C0 R_MORELLO_DESC_GLOB_DAT bye 0x0
// RELOCS-NEXT: 0x320D0 R_MORELLO_DESC_GLOB_DAT foo 0x0
// RELOCS-NEXT: 0x320B0 R_MORELLO_DESC_GLOB_DAT hello 0x0

// SYM:    Name: bar
// SYM-NEXT:    Value: 0x32000
// SYM-NEXT:    Size: 4
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: Object
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .desc.data.rel.ro
// SYM-NEXT:  }
// SYM:    Name: bye
// SYM-NEXT:    Value: 0x2440
// SYM-NEXT:    Size: 10
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: Object
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .desc.data
// SYM-NEXT:  }
// SYM-NEXT:  Symbol {
// SYM-NEXT:    Name: foo
// SYM-NEXT:    Value: 0x2446C
// SYM-NEXT:    Size: 4
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: Object
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .data.rel.ro
// SYM-NEXT:  }
// SYM-NEXT:  Symbol {
// SYM-NEXT:    Name: hello
// SYM-NEXT:    Value: 0x42114
// SYM-NEXT:    Size: 12
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: Object
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .data
// SYM-NEXT:  }
// SYM-NEXT:  Symbol {
// SYM-NEXT:    Name: bss
// SYM-NEXT:    Value: 0x42120
// SYM-NEXT:    Size: 4
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: Object
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .bss
// SYM-NEXT:  }

// GOT: Hex dump of section '.got'
// GOT-NEXT: 0x000320b0 14210400 00000000 0c000000 00000002
// GOT-NEXT: 0x000320c0 40240000 00000000 0a000000 00000001
// GOT-NEXT: 0x000320d0 6c440200 00000000 04000000 00000001
// GOT-NEXT: 0x000320e0 00200300 00000000 04000000 00000001
// GOT-NEXT: 0x000320f0 00000000 00000000 00000000 00000000

// DIS: 000000000001244c <_start>:

/// Immediate of adrdp = Page(GOT(Sym)) - Page(PT_MORELLO_DESC)
/// Page(PT_MORELLO_DESC) = 0x30000

/// GOT(hello) = 0x320B0
// DIS: 1244c: adrdp	c5, #0x2000
// DIS: 12450: ldr  c5, [c5, #0xb0]

/// GOT(bye) = 0x320C0
// DIS: 12454: adrdp	c6, #0x2000
// DIS: 12458: ldr  c6, [c6, #0xc0]

/// GOT(foo) = 0x320D0
// DIS: 1245c: adrdp	c7, #0x2000
// DIS: 12460: ldr  c7, [c7, #0xd0]

/// GOT(bar) = 0x320E0
// DIS: 12464: adrdp	c8, #0x2000
// DIS: 12468: ldr  c8, [c8, #0xe0]


// STATIC_UNDEF: error: undefined symbol: hello