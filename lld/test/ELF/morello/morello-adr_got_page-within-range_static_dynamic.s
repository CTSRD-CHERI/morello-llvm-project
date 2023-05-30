// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -target-abi purecap -triple=arm64 -mattr=+c64,+morello %s -o %t.o
// RUN: ld.lld --local-caprelocs=elf %t.o -o %t
// RUN: llvm-readobj --sections %t  | FileCheck %s
// RUN: llvm-readobj --relocs %t.o  | FileCheck %s --check-prefix=RELOCS
// RUN: llvm-objdump --mattr=+morello -d %t --print-imm-hex --no-show-raw-insn | FileCheck %s --check-prefix=DISASM

// CHECK:      Name: .got
// CHECK-NEXT: Type: SHT_PROGBITS
// CHECK-NEXT: Flags [
// CHECK-NEXT:   SHF_ALLOC
// CHECK-NEXT:   SHF_WRITE
// CHECK-NEXT: ]
// CHECK-NEXT: Address: 0x220240
// CHECK-NEXT: Offset:
// CHECK-NEXT: Size:
// CHECK-NEXT: Link:
// CHECK-NEXT: Info:
// CHECK-NEXT: AddressAlignment:

// RELOCS: Relocations [
// RELOCS-NEXT: Section
// RELOCS-NEXT:   0x0 R_MORELLO_ADR_GOT_PAGE foo 0x0

// DISASM: 210230: adrp c25, 0x220000

/// P = 210230
/// Address of .got = 0x220240
///   -> foo@GOT = 0x220240 + 0 = 0x220240
/// Page ( foo@GOT )
///   = (0x220240 & ~0xFFF)
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
