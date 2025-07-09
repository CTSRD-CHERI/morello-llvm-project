// REQUIRES: aarch64
// RUN: llvm-mc -filetype=obj -triple=aarch64-pc-linux %s -target-abi purecap -mattr=+c64,+morello -o %t.o
// RUN: ld.lld --hash-style=sysv -shared %t.o -o %t.so
// RUN: llvm-objdump -d --mattr=+morello --no-show-raw-insn --no-print-imm-hex %t.so | FileCheck %s
// RUN: llvm-readobj -r %t.so | FileCheck --check-prefix=REL %s

.text
  adrp    c0, :tlsdesc:a
  ldr     c1, [c0, :tlsdesc_lo12:a]
  add     c0, c0, :tlsdesc_lo12:a
  .tlsdesccall a
  blr     c1

// Create relocation against local TLS symbols where linker should
// create target specific dynamic TLSDESC relocation where addend is
// the symbol VMA in tls block.

// CHECK:      10308: adrp    c0, 0x20000 <local2+0x1fff8>
// CHECK-NEXT: 1030c: ldr     c1, [c0, #976]
// CHECK-NEXT: 10310: add     c0, c0, #976
// CHECK-NEXT: 10314: blr     c1

	adrp	c0, :tlsdesc:local1
	ldr	c1, [c0, :tlsdesc_lo12:local1]
	add	c0, c0, :tlsdesc_lo12:local1
  .tlsdesccall local1
  blr     c1

// CHECK:      10318: adrp    c0, 0x20000 <local2+0x1fff8>
// CHECK-NEXT: 1031c: ldr     c1, [c0, #1008]
// CHECK-NEXT: 10320: add     c0, c0, #1008
// CHECK-NEXT: 10324: blr     c1

  adrp	c0, :tlsdesc:local2
  ldr	c1, [c0, :tlsdesc_lo12:local2]
  add	c0, c0, :tlsdesc_lo12:local2
  .tlsdesccall local2
  blr     c1

// CHECK:      10328: adrp    c0, 0x20000 <local2+0x1fff8>
// CHECK-NEXT: 1032c: ldr     c1, [c0, #1040]
// CHECK-NEXT: 10330: add     c0, c0, #1040
// CHECK-NEXT: 10334: blr     c1

  .section .tbss,"awT",@nobits
  .type   local1,@object
  .p2align 2
local1:
  .word   0
  .size   local1, 4
  .type   local2,@object
  .p2align 3
local2:
  .xword  0
  .size   local2, 8


// 0x1000 + 4096 + 160 = 0x20A0
// 0x1000 + 4096 + 176 = 0x20B0
// 0x1000 + 4096 + 144 = 0x2090

// R_MORELLO_TLSDESC - 0x0 -> start of tls block
// R_MORELLO_TLSDESC - 0x8 -> align (sizeof (local1), 8)

// REL:      Relocations [
// REL-NEXT:   .rela.dyn {
// REL-NEXT:     0x203F0 R_MORELLO_TLSDESC - 0x0
// REL-NEXT:     0x20410 R_MORELLO_TLSDESC - 0x8
// REL-NEXT:     0x203D0 R_MORELLO_TLSDESC a 0x0
// REL-NEXT:   }
// REL-NEXT: ]
