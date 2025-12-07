/// Check relaxation from Global Dynamic to Local Executable

// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=aarch64-unknown-linux %s -o %tmain.o -target-abi purecap -mattr=+c64,+morello
// RUN: llvm-mc -filetype=obj -triple=aarch64-unknown-linux %p/Inputs/aarch64-c64-tls-gdle.s -o %ttlsle.o -target-abi purecap -mattr=+c64,+morello
// RUN: ld.lld %tmain.o %ttlsle.o -o %tout
// RUN: llvm-objdump -d --mattr=+morello --print-imm-hex --no-show-raw-insn %tout | FileCheck %s
// RUN: llvm-readobj -rS %tout | FileCheck --check-prefix=REL --check-prefix=SEC %s
// RUN: llvm-readobj -x .got %tout | FileCheck %s --check-prefix=DATA

  .globl _start
_start:
  adrp    c0, :tlsdesc:foo
  ldr     c1, [c0, :tlsdesc_lo12:foo]
  add     c0, c0, :tlsdesc_lo12:foo
  nop
  .tlsdesccall foo
  blr     c1

  adrp    c0, :tlsdesc:bar
  ldr     c1, [c0, :tlsdesc_lo12:bar]
  add     c0, c0, :tlsdesc_lo12:bar
  nop
  .tlsdesccall bar
  blr     c1

  adrp    c0, :tlsdesc:foo
  ldr     c1, [c0, :tlsdesc_lo12:foo]
  add     c0, c0, :tlsdesc_lo12:foo
  nop
  .tlsdesccall foo
  blr     c1

// SEC:    Name: .got
// SEC-NEXT:    Type: SHT_PROGBITS
// SEC-NEXT:    Flags [
// SEC-NEXT:      SHF_ALLOC
// SEC-NEXT:      SHF_WRITE
// SEC-NEXT:    ]
// SEC-NEXT:    Address: 0x1DFFC40
// SEC-NEXT:    Offset:
// SEC-NEXT:    Size: 32

/// foo is in the same module. So no dynamic relocations needed.
// REL:      Relocations [
// REL-NEXT: ]

// The offset and size of foo and bar are encoded in .got.
// DATA: Hex dump of section '.got':
// DATA-NEXT: 0x01dffc40 20edfe00 00000000 00efbe00 00000000
// DATA-NEXT: 0x01dffc50 20000000 00000000 00edfe00 00000000

// CHECK-LABEL: <_start>:
// CHECK-NEXT:  212000: adrp   c0, 0x1dff000
// CHECK-NEXT:          add    c0, c0, #0xc40
// CHECK-NEXT:          ldp    x0, x1, [c0]
// CHECK-NEXT:          add    c0, c2, x0, uxtx
// CHECK-NEXT:          scbnds c0, c0, x1
// CHECK-NEXT:          adrp   c0, 0x1dff000
// CHECK-NEXT:          add    c0, c0, #0xc50
// CHECK-NEXT:          ldp    x0, x1, [c0]
// CHECK-NEXT:          add    c0, c2, x0, uxtx
// CHECK-NEXT:          scbnds c0, c0, x1
// CHECK-NEXT:          adrp   c0, 0x1dff000
// CHECK-NEXT:          add    c0, c0, #0xc40
// CHECK-NEXT:          ldp    x0, x1, [c0]
// CHECK-NEXT:          add    c0, c2, x0, uxtx
// CHECK-NEXT:          scbnds c0, c0, x1
