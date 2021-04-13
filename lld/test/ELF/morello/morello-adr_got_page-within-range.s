// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=arm64 -mattr=+c64,+morello %s -o %t.o
// RUN: ld.lld %t.o -o %t --morello-c64-plt
// RUN: llvm-readobj -s %t  | FileCheck %s
// RUN: llvm-readobj -r %t.o  | FileCheck %s --check-prefix=RELOCS
// RUN: llvm-objdump --mattr=+morello -d %t --no-show-raw-insn | FileCheck %s --check-prefix=DISASM

// CHECK:      Name: .got
// CHECK-NEXT: Type: SHT_PROGBITS
// CHECK-NEXT: Flags [
// CHECK-NEXT:   SHF_ALLOC
// CHECK-NEXT:   SHF_WRITE
// CHECK-NEXT: ]
// CHECK-NEXT: Address: 0x220220
// CHECK-NEXT: Offset:
// CHECK-NEXT: Size:
// CHECK-NEXT: Link:
// CHECK-NEXT: Info:
// CHECK-NEXT: AddressAlignment:

// RELOCS: Relocations [
// RELOCS-NEXT: Section
// RELOCS-NEXT:   0x0 R_MORELLO_ADR_GOT_PAGE foo 0x0

// DISASM: 2101e0: adrp c25, #65536

/// P = 0x210200
/// Address of .got = 0x220220
///   -> foo@GOT = 0x220220 + 16 = 0x220230
/// A = 0
/// G( GDAT (S + A) ) = 0x220230
/// Page ( G( GDAT (S + A) ) ) - Page (P)
///   = (0x220230 & ~0xFFF) - (0x2101E0 & ~0xFFF)
///   = 0x10000 = 65536

  .balign 16
  .text
  .global _start
  .type _start, %function
 .size _start, 16
_start:
  adrp c25, :got:foo

  .balign 16
  .data
  .global foo
 .size foo, 8
foo:
 .xword 10
