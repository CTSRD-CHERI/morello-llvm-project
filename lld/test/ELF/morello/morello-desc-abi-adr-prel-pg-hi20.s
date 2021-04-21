// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=aarch64 -mattr=+morello,+c64 -target-abi purecap -cheri-cap-table-abi=fn-desc %s -o %tmain.o
// RUN: llvm-mc -filetype=obj -triple=aarch64 -mattr=+morello,+c64 -target-abi purecap -cheri-cap-table-abi=fn-desc %p/Inputs/morello-desc-abi_data.s -o %tdata.o
// RUN: ld.lld %tmain.o %tdata.o -o %tout
// RUN: llvm-readobj --symbols --sections %tout | FileCheck %s --check-prefix=SEC --check-prefix=SYM
// RUN: llvm-objdump --triple=aarch64 --no-show-raw-insn --print-imm-hex -d  %tout | FileCheck %s --check-prefix=DIS

/// Do error checking.
/// Expect undefined symbol error for Executable output.
// RUN: not ld.lld %tmain.o -o /dev/null 2>&1 \
// RUN:   | FileCheck %s --check-prefix=STATIC_UNDEF

/// Expect relocation cannot be used error for Shared object output.
/// Similar to the R_MORELLO_ADR_PREL_PG_HI20 case.
// RUN: not ld.lld %tmain.o -shared -o /dev/null 2>&1 \
// RUN:   | FileCheck %s --check-prefix=SHARED_UNDEF

  .globl _start
  .type _start, %function
  .text
_start:
  /// "hello" is in .data.
  /// So expect this to be converted into an adrdp
  adrp c5, hello
  /// "bye" is in section .descdata.
  /// So expect this to be converted into an adrdp
  adrp c6, bye
  /// "foo" is in  .data.rel.ro.
  /// So expect this to remain adrp
  adrp c7, foo


// SEC:   Sections [
// SEC:     Name: .desc.data
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x200218
// SEC:     Name: .text
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_EXECINSTR
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x212224
// SEC:     Name: .data.rel.ro
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x222240
// SEC:     Name: .data
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x234244

// SYM:    Name: bye
// SYM-NEXT:    Value: 0x202218
// SYM-NEXT:    Size: 10
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: Object
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .desc.data
// SYM-NEXT:  }
// SYM-NEXT:  Symbol {
// SYM-NEXT:    Name: foo
// SYM-NEXT:    Value: 0x224240
// SYM-NEXT:    Size: 4
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: Object
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .data.rel.ro
// SYM-NEXT:  }
// SYM-NEXT:  Symbol {
// SYM-NEXT:    Name: hello
// SYM-NEXT:    Value: 0x234258
// SYM-NEXT:    Size: 12
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: Object
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .data
// SYM-NEXT:  }


// DIS: 0000000000212224 <_start>:

/// Immediate of adrdp = Page(hello) - Page(.data) =
/// Page(0x234258) - Page(0x234244) =
/// 0x234000 - 234000 =
/// 0x0
// DIS: 212224: adrdp	c5, #0x0

/// Immediate of adrdp = Page(bye) - Page(.desc.data) =
/// Page(0x202218) - Page(0x200200) =
/// 0x202000 - 200000 =
/// 0x2000
// DIS: 212228: adrdp	c6, #0x2000

/// Immediate of adrp = Page(foo) - Page(location) =
/// Page(0x224240) - Page(21222c) =
/// 0x224000 - 212000 =
/// 0x12000
// DIS: 21222c: adrp	c7, #0x12000

// STATIC_UNDEF: error: undefined symbol: hello
// SHARED_UNDEF: error: relocation R_MORELLO_DESC_ADR_PREL_PG_HI20 cannot be used against symbol hello; recompile with -fPIC
