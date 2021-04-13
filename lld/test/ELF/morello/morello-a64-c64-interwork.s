// RUN: echo "SECTIONS { \
// RUN:    . = SIZEOF_HEADERS; \
// RUN:    .text_low : { *(.text.1) *(.text.2) } \
// RUN:    .text_high 0xf000000 : { *(.text.3) } \
// RUN: } " > %t.script
// RUN: llvm-mc --triple=aarch64-none-elf %s -mattr=+c64,+morello --filetype=obj -o %t1.o
// RUN: llvm-mc --triple=aarch64-none-elf %S/Inputs/aarch64-faraway-func.s --filetype=obj -o %t2.o
// RUN: ld.lld %t1.o %t2.o --script=%t.script -o %t
// RUN: llvm-objdump -d --no-show-raw-insn --triple=aarch64-none-elf --mattr=+morello %t | FileCheck %s --check-prefix=CHECK --check-prefix=A64_LAST

// RUN: llvm-mc --triple=aarch64-none-elf %s --filetype=obj -o %t1.o
// RUN: llvm-mc --triple=aarch64-none-elf %S/Inputs/aarch64-faraway-func.s -mattr=+c64,+morello --filetype=obj -o %t2.o
// RUN: ld.lld %t1.o %t2.o --script=%t.script -o %t
// RUN: llvm-objdump -d --no-show-raw-insn --triple=aarch64-none-elf --mattr=+morello %t | FileCheck %s --check-prefix=CHECK --check-prefix=C64_LAST


  .section .text.1, "ax", %progbits
  .balign 4
  .global _start
  .type _start, %function
  .size _start, 4
_start:
  b  far_away
  bl far_away

/// The A64 Long Thunk is created last, and does not share the C64 Thunk
// A64_LAST: <_start>:
// A64_LAST-NEXT:  b  0x128 <__C64ADRPThunk_far_away>
// A64_LAST-NEXT:  bl 0x128 <__C64ADRPThunk_far_away>

// A64_LAST: <__C64ADRPThunk_far_away>:
// A64_LAST-NEXT: adrp c16, #251658240
// A64_LAST-NEXT: add  c16, c16, #0
// A64_LAST-NEXT: br   c16

// A64_LAST: <func>:
// A64_LAST-NEXT: b  0x13c <__AArch64AbsLongThunk_far_away>
// A64_LAST-NEXT: bl 0x13c <__AArch64AbsLongThunk_far_away>

// A64_LAST: <__AArch64AbsLongThunk_far_away>:
// A64_LAST-NEXT: ldr x16, 0x144 <$d>
// A64_LAST-NEXT: br  x16


/// The C64 Long Thunk is created last, and does not share the A64 Thunk
// C64_LAST: <_start>:
// C64_LAST-NEXT:  b  0x128 <__A64ToC64Thunk_far_away>
// C64_LAST-NEXT:  bl 0x128 <__A64ToC64Thunk_far_away>

// C64_LAST: <__A64ToC64Thunk_far_away>:
// C64_LAST-NEXT: bx   #4
// C64_LAST-EMPTY:
// C64_LAST-NEXT: <$c>:
// C64_LAST-NEXT: adrp c16, #251658240
// C64_LAST-NEXT: add  c16, c16, #1
// C64_LAST-NEXT: br   c16

// C64_LAST: <func>:
// C64_LAST-NEXT: b  0x140 <__C64ADRPThunk_far_away>
// C64_LAST-NEXT: bl 0x140 <__C64ADRPThunk_far_away>

// C64_LAST: <__C64ADRPThunk_far_away>:
// C64_LAST-NEXT: adrp c16, #251658240
// C64_LAST-NEXT: add  c16, c16, #1
// C64_LAST-NEXT: br   c16

// CHECK: <far_away>:
