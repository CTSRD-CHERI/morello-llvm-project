// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf %s -mattr=+c64,+morello --filetype=obj -o %t.o
// RUN: echo "SECTIONS { \
// RUN:       . = SIZEOF_HEADERS; \
// RUN:       .text_low : { *(.text.1) } \
// RUN:       .text_high 0xf000000 : { *(.text.2) *(.text.3) } \
// RUN:       } " > %t.script
// RUN: ld.lld %t.o -o %t --script=%t.script
// RUN: llvm-objdump -d --no-show-raw-insn --triple=aarch64-none-elf --mattr=+morello %t | FileCheck %s

        .section .text.1, "ax", %progbits
        .balign 4
        .global _start
        .type _start, %function
        .size _start, 4
_start:
        bl target
        b target2

        .section .text.2, "ax", %progbits
        .global target
        .type target, %function
        .size target, 4
target: ret

        .section .text.3, "ax", %progbits
        .global target2
        .type target2, %function
        .size target2, 4
target2: ret

// CHECK: <_start>:
// CHECK-NEXT:  bl      0x128 <__C64ADRPThunk_target>
// CHECK-NEXT:  b       0x134 <__C64ADRPThunk_target2>

// CHECK: <__C64ADRPThunk_target>:
// CHECK-NEXT:  adrp    c16, #251658240
// CHECK-NEXT:  c16, c16, #1
// CHECK-NEXT:  br      c16

// CHECK: <__C64ADRPThunk_target2>:
// CHECK-NEXT:  adrp    c16, #251658240
// CHECK-NEXT:  add     c16, c16, #5
// CHECK-NEXT:  br      c16

// CHECK: <target>:
// CHECK-NEXT:  ret

// CHECK: <target2>:
// CHECK-NEXT:  ret
