// RUN: llvm-mc -triple=arm64 -mattr=+morello,+c64,+v8.2a -show-encoding < %s 2>&1 | FileCheck %s -check-prefix=32CAP
// RUN: not llvm-mc -triple=arm64 -mattr=+morello,+c64,+use-16-cap-regs,+v8.2a -show-encoding < %s 2>&1 | FileCheck %s -check-prefix=16CAP

  adr c17, #0
// 32CAP: adr c17, #0                   // encoding: [0x11,0x00,0x00,0x10]
// 16CAP: error: invalid operand for instruction
// 16CAP-NEXT: adr c17, #0

  dc zva, c17
  dc ivac, c17
  dc cvac, c17
  dc cvau, c17
  dc civac, c17
  dc cvap, c17
  ic ivau, c17
// 16CAP: expected register operand
// 16CAP-NEXT:  dc zva, c17
// 16CAP: expected register operand
// 16CAP-NEXT:  dc ivac, c17
// 16CAP: expected register operand
// 16CAP-NEXT:  dc cvac, c17
// 16CAP: expected register operand
// 16CAP-NEXT:  dc cvau, c17
// 16CAP: expected register operand
// 16CAP-NEXT:  dc civac, c17
// 16CAP: expected register operand
// 16CAP-NEXT:  dc cvap, c17
// 16CAP: expected register operand
// 16CAP-NEXT:  ic ivau, c17
// 32CAP:  dc zva, c17                  // encoding: [0x31,0x74,0x0b,0xd5]
// 32CAP:  dc ivac, c17                 // encoding: [0x31,0x76,0x08,0xd5]
// 32CAP:  dc cvac, c17                 // encoding: [0x31,0x7a,0x0b,0xd5]
// 32CAP:  dc cvau, c17                 // encoding: [0x31,0x7b,0x0b,0xd5]
// 32CAP:  dc civac, c17                // encoding: [0x31,0x7e,0x0b,0xd5]
// 32CAP:  dc cvap, c17                 // encoding: [0x31,0x7c,0x0b,0xd5]
// 32CAP:  ic ivau, c17                 // encoding: [0x31,0x75,0x0b,0xd5]

  adr c0, #0
// 32CAP: adr c0, #0                    // encoding: [0x00,0x00,0x00,0x10]
// 16CAP: adr c0, #0                    // encoding: [0x00,0x00,0x00,0x10]

  dc zva, c0
  dc ivac, c0
  dc cvac, c0
  dc cvau, c0
  dc civac, c0
  dc cvap, c0
  ic ivau, c0
// 16CAP:  dc zva, c0                   // encoding: [0x20,0x74,0x0b,0xd5]
// 16CAP:  dc ivac, c0                  // encoding: [0x20,0x76,0x08,0xd5]
// 16CAP:  dc cvac, c0                  // encoding: [0x20,0x7a,0x0b,0xd5]
// 16CAP:  dc cvau, c0                  // encoding: [0x20,0x7b,0x0b,0xd5]
// 16CAP:  dc civac, c0                 // encoding: [0x20,0x7e,0x0b,0xd5]
// 16CAP:  dc cvap, c0                  // encoding: [0x20,0x7c,0x0b,0xd5]
// 16CAP:  ic ivau, c0                  // encoding: [0x20,0x75,0x0b,0xd5]
// 32CAP:  dc zva, c0                   // encoding: [0x20,0x74,0x0b,0xd5]
// 32CAP:  dc ivac, c0                  // encoding: [0x20,0x76,0x08,0xd5]
// 32CAP:  dc cvac, c0                  // encoding: [0x20,0x7a,0x0b,0xd5]
// 32CAP:  dc cvau, c0                  // encoding: [0x20,0x7b,0x0b,0xd5]
// 32CAP:  dc civac, c0                 // encoding: [0x20,0x7e,0x0b,0xd5]
// 32CAP:  dc cvap, c0                  // encoding: [0x20,0x7c,0x0b,0xd5]
// 32CAP:  ic ivau, c0                  // encoding: [0x20,0x75,0x0b,0xd5]
