// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64,+morello -filetype=obj -target-abi purecap %s -o %t.o
// RUN: llvm-mc --triple=aarch64-none-elf -filetype=obj %S/Inputs/aarch64-funcs.s -target-abi purecap -o %t2.o
// RUN: ld.lld %t.o %t2.o -o %t
// RUN: llvm-objdump --no-show-raw-insn --triple=aarch64-none-elf --mattr=+morello -d %t | FileCheck %s
// RUN: llvm-readobj --symbols %t | FileCheck --check-prefix=CHECK-SYM %s

/// Simple interworking test between AArch64 and C64, the execution state change
/// is done on the indirect branch.
 .text
 .global _start
 .type _start, %function
 .size _start, 4
_start: b func2

 .global func
 .type func, %function
 .size func, 4
func:  bl func2

// CHECK-LABEL: <_start>:
// CHECK-NEXT:   210190:       b       0x2101a4 <__C64ADRPThunk_func2>

// CHECK-LABEL: <func>:
// CHECK-NEXT:   210194:       bl      0x2101a4 <__C64ADRPThunk_func2>

// CHECK-LABEL: <func2>:
// CHECK-NEXT:   210198:       bl      0x2101b0 <__A64ToC64Thunk_func>
// CHECK-NEXT:                 b       0x2101c0 <__A64ToC64Thunk__start>
// CHECK-NEXT:                 ret

// CHECK-LABEL: <__C64ADRPThunk_func2>:
// CHECK-NEXT:   2101a4:       adrp    c16, 0x210000 <__C64ADRPThunk_func2>
// CHECK-NEXT:                 add     c16, c16, #408
// CHECK-NEXT:                 br      c16

// CHECK-LABEL: <__A64ToC64Thunk_func>:
// CHECK-NEXT:   2101b0:       bx      #4
// CHECK-EMPTY:
// CHECK-LABEL:   <$c>:
// CHECK-NEXT:   2101b4:       adrp    c16, 0x210000 <$c>
// CHECK-NEXT:                 add     c16, c16, #405
// CHECK-NEXT:                 br      c16

// CHECK-LABEL: <__A64ToC64Thunk__start>:
// CHECK-NEXT:   2101c0:       bx      #4
// CHECK-EMPTY:
// CHECK-LABEL:   <$c>:
// CHECK-NEXT:   2101c4:       adrp    c16, 0x210000 <$c>
// CHECK-NEXT:                 add     c16, c16, #401
// CHECK-NEXT:                 br      c16

// CHECK-SYM:        Name: __C64ADRPThunk_func2
// CHECK-SYM-NEXT:   Value: 0x2101A5
// CHECK-SYM-NEXT:   Size: 12
// CHECK-SYM-NEXT:   Binding: Local
// CHECK-SYM-NEXT:   Type: Function

// CHECK-SYM:        Name: $c
// CHECK-SYM-NEXT:   Value: 0x2101A4
// CHECK-SYM-NEXT:   Size: 0
// CHECK-SYM-NEXT:   Binding: Local
// CHECK-SYM-NEXT:   Type: None

// CHECK-SYM:        Name: __A64ToC64Thunk_func
// CHECK-SYM-NEXT:   Value: 0x2101B0
// CHECK-SYM-NEXT:   Size: 16
// CHECK-SYM-NEXT:   Binding: Local
// CHECK-SYM-NEXT:   Type: Function

// CHECK-SYM:        Name: $x
// CHECK-SYM-NEXT:   Value: 0x2101B0
// CHECK-SYM-NEXT:   Size: 0
// CHECK-SYM-NEXT:   Binding: Local
// CHECK-SYM-NEXT:   Type: None

// CHECK-SYM:        Name: $c
// CHECK-SYM-NEXT:   Value: 0x2101B4
// CHECK-SYM-NEXT:   Size: 0
// CHECK-SYM-NEXT:   Binding: Local
// CHECK-SYM-NEXT:   Type: None
