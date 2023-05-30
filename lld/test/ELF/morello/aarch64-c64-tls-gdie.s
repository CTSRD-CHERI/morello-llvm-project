// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=aarch64-unknown-linux %s -o %tmain.o -target-abi purecap -mattr=+c64,+morello
// RUN: llvm-mc -filetype=obj -triple=aarch64-unknown-linux %p/Inputs/aarch64-c64-tls-gdie.s -o %t2.o -target-abi purecap -mattr=+c64,+morello
// RUN: ld.lld %t2.o -o %t2.so -shared -soname=t2.so
// RUN: ld.lld --hash-style=sysv %tmain.o %t2.so -o %tout
// RUN: llvm-objdump -d --mattr=+morello --no-show-raw-insn --print-imm-hex %tout | FileCheck %s
// RUN: llvm-readobj -rS %tout | FileCheck --check-prefix=SEC --check-prefix=REL %s

  .globl  _start
_start:
  adrp    c0, :tlsdesc:foo
  ldr     c1, [c0, :tlsdesc_lo12:foo]
  add     c0, c0, :tlsdesc_lo12:foo
  nop
  .tlsdesccall foo
  blr     c1

// SEC:      Name: .got
// SEC-NEXT: Type: SHT_PROGBITS
// SEC-NEXT: Flags [
// SEC-NEXT:   SHF_ALLOC
// SEC-NEXT:   SHF_WRITE
// SEC-NEXT: ]
// SEC-NEXT: Address: 0x220350

// REL:      Relocations [
// REL-NEXT:   .rela.dyn {
// REL-NEXT:     0x220350 R_MORELLO_TLS_TPREL128 foo 0x0
// REL-NEXT:   }
// REL-NEXT: ]

// CHECK-LABEL:      <_start>:
// CHECK-NEXT:   210288: adrp c0, 0x220000
// CHECK-NEXT:   21028c: add  c0, c0, #0x350
// CHECK-NEXT:   210290: ldp  x0, x1, [c0]
// CHECK-NEXT:   210294: add  c0, c2, x0, uxtx
// CHECK-NEXT:   210298: scbnds c0, c0, x1
