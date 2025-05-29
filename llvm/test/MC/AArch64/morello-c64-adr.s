// RUN: llvm-mc -triple aarch64-elf -mattr=+morello,+c64 -target-abi purecap -filetype=obj %s -o %t
// RUN: llvm-objdump --no-print-imm-hex -d -r %t
// RUN: llvm-mc -triple aarch64-elf -mattr=+morello,+c64 -filetype=obj %s -o - | llvm-objdump --mattr=+morello -d -r - | FileCheck %s
// RUN: llvm-mc -triple aarch64-elf -mattr=+morello,+c64 -target-abi purecap -filetype=obj %s -o - | llvm-objdump -d -r - | FileCheck %s

// CHECK: adr c0, 0x64 <Symbol+0x64>
// CHECK-NEXT: adr c2, 0x4 <Symbol+0x4>
// CHECK-NEXT: R_AARCH64_ADR_PREL_LO21	Symbol
// CHECK-NEXT: adr c3, 0x8 <Symbol+0x8>
// CHECK-NEXT: R_AARCH64_ADR_PREL_LO21	Symbol
// CHECK-NEXT: adr c4, 0xc <Symbol+0xc>
// CHECK-NEXT: R_AARCH64_ADR_PREL_LO21	Symbol+0xf1000
// CHECK-NEXT: adr c5, 0x10 <Symbol+0x10>
// CHECK-NEXT: R_AARCH64_ADR_PREL_LO21	Symbol+0xf1000
// CHECK-NEXT: adr c6, 0x14 <Symbol+0x14>
// CHECK-NEXT: R_AARCH64_ADR_PREL_LO21	Symbol+0xf1000

  adr c0, 100
  adr c2, Symbol
  adr c3, Symbol + 0
  adr c4, Symbol + 987136
  adr c5, (0xffffffff000f1000 - 0xffffffff00000000 + Symbol)
  adr c6, Symbol + (0xffffffff000f1000 - 0xffffffff00000000)

// CHECK-NEXT: adrp c0, 0x0 <Symbol>
// CHECK-NEXT: R_MORELLO_ADR_PREL_PG_HI20	Symbol
// CHECK-NEXT: adrp c2, 0x0 <Symbol>
// CHECK-NEXT: R_MORELLO_ADR_PREL_PG_HI20	Symbol
// CHECK-NEXT: adrp c3, 0x0 <Symbol>
// CHECK-NEXT: R_MORELLO_ADR_PREL_PG_HI20	Symbol+0xf1000
// CHECK-NEXT: adrp c4, 0x0 <Symbol>
// CHECK-NEXT: R_MORELLO_ADR_PREL_PG_HI20	Symbol+0xf1000
// CHECK-NEXT: adrp c5, 0x0 <Symbol>
// CHECK-NEXT: R_MORELLO_ADR_PREL_PG_HI20	Symbol+0xf1000

  adrp c0, Symbol
  adrp c2, Symbol + 0
  adrp c3, Symbol + 987136
  adrp c4, (0xffffffff000f1000 - 0xffffffff00000000 + Symbol)
  adrp c5, Symbol + (0xffffffff000f1000 - 0xffffffff00000000)
