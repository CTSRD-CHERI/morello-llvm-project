// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64 -filetype=obj %s -o %t.o
// RUN: ld.lld %t.o -o %t --morello-c64-plt --shared
// RUN: llvm-objdump --triple=aarch64-none-elf --mattr=+morello --no-show-raw-insn -d %t | FileCheck %s --check-prefix=DIS
// RUN: llvm-objdump -s %t | FileCheck %s --check-prefix=GOTPLT
// RUN: llvm-readobj --sections --relocs %t | FileCheck %s
// RUN: llvm-objdump -s --triple=aarch64-none-elf --mattr=+morello %t | FileCheck %s --check-prefix=GOT

/// Test that GOT slots are 16-bytes when we use --morello-c64-plt.
/// Test that the Morello dynamic relocations are generated.
/// Test that the Morello PLT sequences are generated.
 .global foo
 .global bar
 .global _start
 .type _start, %function
 .size _start, 12
 .text
_start:
 adrp c1, :got:foo
 ldr  c1, [c1, :got_lo12: foo]
 adrp c2, :got:bar
 ldr  c2, [c2, :got_lo12: bar]
 adrp c3, :got:hidden
 ldr  c3, [c3, :got_lo12: hidden]
 adrp c4, :got:preemptible
 ldr  c4, [c4, :got_lo12: preemptible]
 bl imported

 .data
        .local local
        .type local, %object
        .size local, 8
local:  .xword 1

        .global preemptible
        .type preemptible, %object
        .size preemptible, 8
preemptible: .xword 2

        .global hidden
        .hidden hidden
        .type hidden, %object
        .size hidden, 8
hidden:  .xword 3

// DIS: 0000000000010390 <_start>:
// DIS-NEXT:    10390:          adrp    c1, #65536
// DIS-NEXT:    10394:          ldr     c1, [c1, #1248]
// DIS-NEXT:    10398:          adrp    c2, #65536
// DIS-NEXT:    1039c:          ldr     c2, [c2, #1264]
// DIS-NEXT:    103a0:          adrp    c3, #65536
// DIS-NEXT:    103a4:          ldr     c3, [c3, #1280]
// DIS-NEXT:    103a8:          adrp    c4, #65536
// DIS-NEXT:    103ac:          ldr     c4, [c4, #1296]
// DIS-NEXT:    103b0:          bl      0x103e0 <imported+0x103e0>

// DIS: 00000000000103c0 <.plt>:
// DIS-NEXT:    103c0:          stp     c16, c30, [csp, #-32]!
// DIS-NEXT:    103c4:          adrp    c16, #131072
// DIS-NEXT:    103c8:          ldr     c17, [c16, #1376]
// DIS-NEXT:    103cc:          add     c16, c16, #1376
// DIS-NEXT:    103d0:          br      c17
// DIS-NEXT:    103d4:          nop
// DIS-NEXT:    103d8:          nop
// DIS-NEXT:    103dc:          nop
// DIS-NEXT:    103e0:          adrp    c16, #131072
// DIS-NEXT:    103e4:          add     c16, c16, #1392
// DIS-NEXT:    103e8:          ldr     c17, [c16, #0]
// DIS-NEXT:    103ec:          br      c17

// GOTPLT: Contents of section .got.plt:
// GOTPLT-NEXT:  30540 00000000 00000000 00000000 00000000
// GOTPLT-NEXT:  30550 00000000 00000000 00000000 00000000
// GOTPLT-NEXT:  30560 00000000 00000000 00000000 00000000
/// Initial contents should be address of .plt[0], as plt[0] is C64 the bottom
/// bit should be set.
// GOTPLT-NEXT:  30570 c1030100 00000000 00000000 00000000

// CHECK:     Name: .got
// CHECK-NEXT:     Type: SHT_PROGBITS (0x1)
// CHECK-NEXT:     Flags [ (0x3)
// CHECK-NEXT:       SHF_ALLOC (0x2)
// CHECK-NEXT:       SHF_WRITE (0x1)
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x204E0
// CHECK-NEXT:     Offset: 0x4E0
// CHECK-NEXT:     Size: 64
// CHECK-NEXT:     Link: 0
// CHECK-NEXT:     Info: 0
// CHECK-NEXT:     AddressAlignment: 16

// CHECK:     Name: .got.plt (84)
// CHECK-NEXT:     Type: SHT_PROGBITS (0x1)
// CHECK-NEXT:     Flags [ (0x3)
// CHECK-NEXT:       SHF_ALLOC (0x2)
// CHECK-NEXT:       SHF_WRITE (0x1)
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x30540
// CHECK-NEXT:     Offset: 0x540
// CHECK-NEXT:     Size: 64
// CHECK-NEXT:     Link: 0
// CHECK-NEXT:     Info: 0
// CHECK-NEXT:     AddressAlignment: 16

// CHECK:     0x20500 R_MORELLO_RELATIVE - 0x0
// CHECK-NEXT:     0x204F0 R_MORELLO_GLOB_DAT bar 0x0
// CHECK-NEXT:     0x204E0 R_MORELLO_GLOB_DAT foo 0x0
// CHECK-NEXT:     0x20510 R_MORELLO_GLOB_DAT preemptible 0x0
// CHECK:     0x30570 R_MORELLO_JUMP_SLOT imported 0x0

// GOT: Contents of section .got:
// GOT-NEXT:  204e0 00000000 00000000 00000000 00000002
// GOT-NEXT:  204f0 00000000 00000000 00000000 00000002
// GOT-NEXT:  20500 30050300 00000000 08000000 00000002
// GOT-NEXT:  20510 28050300 00000000 08000000 00000002
