// RUN: llvm-mc -triple=aarch64-linux-gnu -mattr=+morello,+c64 \
// RUN:         -filetype=obj -o - %s| llvm-objdump --mattr=+morello -r - -S | \
// RUN: FileCheck %s

somewhere:
  nop
  nop
  nop
  ldr c25, somewhere+1
  ldr c25, anywhere+2

  adrp c25, sym+4
  adrp c25, :got:sym+16
  adrp c25, :pg_hi21_nc:sym+32

  .global sym
sym:


// CHECK:      nop
// CHECK-NEXT: nop
// CHECK-NEXT: nop
// CHECK-NEXT: 82000019  ldr  c25, #0
// CHECK-NEXT:      R_MORELLO_LD_PREL_LO17 .text+0x1
// CHECK-NEXT: 82000019  ldr  c25, #0
// CHECK-NEXT:      R_MORELLO_LD_PREL_LO17 anywhere+0x2
// CHECK-NEXT: 90800019  adrp c25, 0x0
// CHECK-NEXT:      R_MORELLO_ADR_PREL_PG_HI20 sym+0x4
// CHECK-NEXT: 90800019  adrp c25, 0x0
// CHECK-NEXT:      R_MORELLO_ADR_GOT_PAGE sym+0x10
// CHECK-NEXT: 90800019  adrp c25, 0x0
// CHECK-NEXT:      R_MORELLO_ADR_PREL_PG_HI20_NC sym+0x20
