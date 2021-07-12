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
  /// "bye" is in .desc.data.
  /// So expect this to remain adrp
  adrp c6, bye
  /// "foo" is in .data.rel.ro.
  /// So expect this to remain adrp
  adrp c7, foo
  /// "bar" is in .desc.data.rel.ro.
  /// So expect this to be converted into an adrdp
  adrp c8, bar


// SEC:   Sections [
// SEC:     Name: .desc.data
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x200258
// SEC:     Name: .text
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_EXECINSTR
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x212264
// SEC:     Name: .data.rel.ro
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x222280
// SEC:     Name: .desc.data.rel.ro
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x230000
// SEC:     Name: .data
// SEC-NEXT:     Type: SHT_PROGBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x242004
// SEC:     Name: .bss
// SEC-NEXT:     Type: SHT_NOBITS
// SEC-NEXT:     Flags [
// SEC-NEXT:       SHF_ALLOC
// SEC-NEXT:       SHF_WRITE
// SEC-NEXT:     ]
// SEC-NEXT:     Address: 0x242024

// SYM:    Symbols [
// SYM:    Name: bar
// SYM-NEXT:    Value: 0x232000
// SYM-NEXT:    Size: 4
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: Object
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .desc.data.rel.ro
// SYM-NEXT:  }
// SYM:    Name: bye
// SYM-NEXT:    Value: 0x202258
// SYM-NEXT:    Size: 10
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: Object
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .desc.data
// SYM-NEXT:  }
// SYM-NEXT:  Symbol {
// SYM-NEXT:    Name: foo
// SYM-NEXT:    Value: 0x224280
// SYM-NEXT:    Size: 4
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: Object
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .data.rel.ro
// SYM-NEXT:  }
// SYM-NEXT:  Symbol {
// SYM-NEXT:    Name: hello
// SYM-NEXT:    Value: 0x242018
// SYM-NEXT:    Size: 12
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: Object
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .data
// SYM-NEXT:  }
// SYM-NEXT:  Symbol {
// SYM-NEXT:    Name: bss
// SYM-NEXT:    Value: 0x242024
// SYM-NEXT:    Size: 4
// SYM-NEXT:    Binding: Global
// SYM-NEXT:    Type: Object
// SYM-NEXT:    Other: 0
// SYM-NEXT:    Section: .bss
// SYM-NEXT:  }


// DIS: 0000000000212264 <_start>:

/// Immediate of adrdp = Page(hello) - Page(PT_MORELLO_DESC) =
/// Page(0x242018) - Page(0x230000) =
// DIS: 212264: adrdp	c5, #0x12000

/// Immediate of adrp = Page(bye) - Page(location) =
/// Page(0x202258) - Page(212268) =
// DIS: 212268: adrp	c6, #-0x10000

/// Immediate of adrp = Page(foo) - Page(location) =
/// Page(0x224280) - Page(2122ac) =
// DIS: 21226c: adrp	c7, #0x12000

/// Immediate of adrp = Page(bar) - Page(PT_MORELLO_DESC) =
/// Page(0x232000) - Page(0x230000) =
// DIS: 212270: adrdp	c8, #0x2000

// STATIC_UNDEF: error: undefined symbol: hello
// SHARED_UNDEF: error: relocation R_MORELLO_DESC_ADR_PREL_PG_HI20 cannot be used against symbol hello; recompile with -fPIC
