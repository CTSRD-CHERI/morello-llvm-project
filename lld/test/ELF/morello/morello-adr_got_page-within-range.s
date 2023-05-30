// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=arm64 -target-abi purecap -mattr=+c64,+morello %s -o %t.o
// RUN: ld.lld %t.o -o %t
// RUN: llvm-readobj --sections %t  | FileCheck %s
// RUN: llvm-readobj -r %t.o  | FileCheck %s --check-prefix=RELOCS
// RUN: llvm-objdump --mattr=+morello -d %t --no-show-raw-insn | FileCheck %s --check-prefix=DISASM

// CHECK:      Name: .got
// CHECK-NEXT: Type: SHT_PROGBITS
// CHECK-NEXT: Flags [
// CHECK-NEXT:   SHF_ALLOC
// CHECK-NEXT:   SHF_WRITE
// CHECK-NEXT: ]
// CHECK-NEXT: Address: 0x220260
// CHECK-NEXT: Offset:
// CHECK-NEXT: Size:
// CHECK-NEXT: Link:
// CHECK-NEXT: Info:
// CHECK-NEXT: AddressAlignment:

// RELOCS: Relocations [
// RELOCS-NEXT: Section
// RELOCS-NEXT:   0x0 R_MORELLO_ADR_GOT_PAGE foo 0x0

// DISASM: 210220: adrp c25, 0x220000 <_start+0x40>

/// P = 210220
/// Address of .got = 0x220260
///   -> foo@GOT = 0x220260 + 0 = 0x220260
/// Page ( foo@GOT )
///   = (0x220260 & ~0xFFF)
///   = 0x220000

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
