// RUN: llvm-mc -triple aarch64-elf -mattr=+morello,+c64 -filetype=obj %s -o - | llvm-objdump --mattr=+morello -d -r - | FileCheck %s
// RUN: llvm-mc -triple aarch64-elf -mattr=+morello,+c64 -target-abi purecap -filetype=obj %s -o - | llvm-objdump -d -r - | FileCheck %s

// CHECK:      adrp c0, #0
// CHECK-NEXT: R_MORELLO_ADR_PREL_PG_HI20	Symbol
// CHECK-NEXT: adrp c2, #0
// CHECK-NEXT: R_MORELLO_ADR_PREL_PG_HI20	Symbol
// CHECK-NEXT: adrp c3, #0
// CHECK-NEXT: R_MORELLO_ADR_PREL_PG_HI20	Symbol+0xf1000
// CHECK-NEXT: adrp c4, #0
// CHECK-NEXT: R_MORELLO_ADR_PREL_PG_HI20	Symbol+0xf1000
// CHECK-NEXT: adrp c5, #0
// CHECK-NEXT: R_MORELLO_ADR_PREL_PG_HI20	Symbol+0xf1000

  adrp c0, Symbol
  adrp c2, Symbol + 0
  adrp c3, Symbol + 987136
  adrp c4, (0xffffffff000f1000 - 0xffffffff00000000 + Symbol)
  adrp c5, Symbol + (0xffffffff000f1000 - 0xffffffff00000000)
