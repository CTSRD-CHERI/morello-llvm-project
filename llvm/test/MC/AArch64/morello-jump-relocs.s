// RUN: llvm-mc -triple=aarch64-none-elf -mattr=+morello %s -filetype=obj -o - | llvm-objdump --mattr=+morello --no-print-imm-hex -d - -r | FileCheck %s

.arch armv8-a+a64c
.text
.align 4
.globl foo
.type foo, @function
foo:
// CHECK: b 0x0 <foo>
// CHECK-NEXT: R_AARCH64_JUMP26 bar
  b bar

// CHECK: b.ls 0x4
// CHECK-NEXT: R_AARCH64_CONDBR19 sym
  b.ls sym

// CHECK: tbz x6, #45, 0x8
// CHECK-NEXT: R_AARCH64_TSTBR14 sym
  tbz x6, #45, sym

.arch armv8-a+c64
.globl bar
.type bar, @function
bar:
// CHECK: b 0xc <bar>
// CHECK-NEXT: R_MORELLO_JUMP26 foo
  b foo
// CHECK: b 0x10 <bar+0x4>
// CHECK-NEXT: R_MORELLO_JUMP26 baz
  b baz

// CHECK: b.ls 0x14
// CHECK-NEXT: R_MORELLO_CONDBR19 sym
  b.ls sym

// CHECK: tbz x6, #45, 0x18
// CHECK-NEXT: R_MORELLO_TSTBR14 sym
  tbz x6, #45, sym

// CHECK: b.ls 0x1c
// CHECK-NEXT: R_MORELLO_CONDBR19 bat
  b.ls bat

// CHECK: tbz x6, #45, 0x20
// CHECK-NEXT: R_MORELLO_TSTBR14 bat
  tbz x6, #45, bat

.arch armv8-a+a64c
.text
.globl baz
.type baz, @function
baz:
// CHECK: bl 0x24 <baz>
// CHECK-NEXT: R_AARCH64_CALL26 bar
  bl bar
// CHECK: bl 0x28 <baz+0x4>
// CHECK-NEXT: R_AARCH64_CALL26 bat
  bl bat

.arch armv8-a+c64
.globl bat
.type bat, @function
bat:
// CHECK: bl 0x2c <bat>
// CHECK-NEXT: R_MORELLO_CALL26 buf
  bl buf
// CHECK: bl 0x30 <bat+0x4>
// CHECK-NEXT: R_MORELLO_CALL26 baz
  bl baz

.arch armv8-a+a64c
.globl buf
.type buf, @function
buf:
// CHECK: b 0x34 <buf>
// CHECK-NEXT: R_AARCH64_JUMP26 bat
  b bat
  ret
