// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64 -filetype=obj %s -o %t.o
// RUN: ld.lld %t.o -o %t --shared
// RUN: llvm-objdump --triple=aarch64-none-elf --mattr=+morello --no-show-raw-insn -d %t | FileCheck %s --check-prefix=DIS
// RUN: llvm-objdump -s %t | FileCheck %s --check-prefix=GOTPLT
// RUN: llvm-readobj --sections --relocs %t | FileCheck %s
// RUN: llvm-objdump -s --triple=aarch64-none-elf --mattr=+morello %t | FileCheck %s --check-prefix=GOT

/// Test that GOT slots are 16-bytes when we using the purecap ABI.
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

// DIS-LABEL: <_start>:
// DIS-NEXT: 10400: adrp  c1, 0x20000
// DIS-NEXT:        ldr   c1, [c1, #1360]
// DIS-NEXT:        adrp  c2, 0x20000
// DIS-NEXT:        ldr   c2, [c2, #1376]
// DIS-NEXT:        adrp  c3, 0x20000
// DIS-NEXT:        ldr   c3, [c3, #1392]
// DIS-NEXT:        adrp  c4, 0x20000
// DIS-NEXT:        ldr   c4, [c4, #1408]
// DIS-NEXT:        bl  0x10450

// DIS-LABEL: <.plt>:
// DIS-NEXT: 10430: stp  c16, c30, [csp, #-32]!
// DIS-NEXT:        adrp c16, 0x30000
// DIS-NEXT:        ldr  c17, [c16, #1488]
// DIS-NEXT:        add  c16, c16, #1488
// DIS-NEXT:        br  c17
// DIS-NEXT:        nop
// DIS-NEXT:        nop
// DIS-NEXT:        nop
// DIS-NEXT:        adrp c16, 0x30000
// DIS-NEXT:        add  c16, c16, #1504
// DIS-NEXT:        ldr  c17, [c16, #0]
// DIS-NEXT:        br   c17

// GOTPLT: Contents of section .got.plt:
// GOTPLT-NEXT:  305b0 00000000 00000000 00000000 00000000
// GOTPLT-NEXT:  305c0 00000000 00000000 00000000 00000000
// GOTPLT-NEXT:  305d0 00000000 00000000 00000000 00000000
/// Initial contents should be address of .plt[0], as plt[0] is C64 the bottom
/// bit should be set.
// GOTPLT-NEXT:  305e0 41020000 00000000 c0030300 00000004

// CHECK:     Name: .got
// CHECK-NEXT:     Type: SHT_PROGBITS (0x1)
// CHECK-NEXT:     Flags [ (0x3)
// CHECK-NEXT:       SHF_ALLOC (0x2)
// CHECK-NEXT:       SHF_WRITE (0x1)
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x20550
// CHECK-NEXT:     Offset: 0x550
// CHECK-NEXT:     Size: 64
// CHECK-NEXT:     Link: 0
// CHECK-NEXT:     Info: 0
// CHECK-NEXT:     AddressAlignment: 16

// CHECK:     Name: .got.plt
// CHECK-NEXT:     Type: SHT_PROGBITS (0x1)
// CHECK-NEXT:     Flags [ (0x3)
// CHECK-NEXT:       SHF_ALLOC (0x2)
// CHECK-NEXT:       SHF_WRITE (0x1)
// CHECK-NEXT:     ]
// CHECK-NEXT:     Address: 0x305B0
// CHECK-NEXT:     Offset: 0x5B0
// CHECK-NEXT:     Size: 80
// CHECK-NEXT:     Link: 0
// CHECK-NEXT:     Info: 0
// CHECK-NEXT:     AddressAlignment: 16

// CHECK:      0x20570 R_MORELLO_RELATIVE - 0x0
// CHECK-NEXT: 0x20550 R_MORELLO_GLOB_DAT foo 0x0
// CHECK-NEXT: 0x20560 R_MORELLO_GLOB_DAT bar 0x0
// CHECK-NEXT: 0x20580 R_MORELLO_GLOB_DAT preemptible 0x0
// CHECK:      0x305E0 R_MORELLO_JUMP_SLOT imported 0x101F0

// GOT: Contents of section .got:
// GOT-NEXT: 20550 00000000 00000000 00000000 00000002
// GOT-NEXT: 20560 00000000 00000000 00000000 00000002
// GOT-NEXT: 20570 a0050300 00000000 08000000 00000002
// GOT-NEXT: 20580 98050300 00000000 08000000 00000002
