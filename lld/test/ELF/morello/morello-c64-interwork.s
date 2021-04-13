// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64,+morello -filetype=obj %s -o %t.o
// RUN: llvm-mc --triple=aarch64-none-elf -filetype=obj %S/Inputs/aarch64-funcs.s -o %t2.o
// RUN: ld.lld %t.o %t2.o --morello-c64-plt -o %t
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

// CHECK: 0000000000210120 <_start>:
// CHECK-NEXT:   210120:       b       0x210134 <__C64ADRPThunk_func2>

// CHECK: 0000000000210124 <func>:
// CHECK-NEXT:   210124:       bl      0x210134 <__C64ADRPThunk_func2>

// CHECK: 0000000000210128 <func2>:
// CHECK-NEXT:   210128:       bl      0x210140 <__A64ToC64Thunk_func>
// CHECK-NEXT:   21012c:       b       0x210150 <__A64ToC64Thunk__start>
// CHECK-NEXT:   210130:       ret

// CHECK: 0000000000210134 <__C64ADRPThunk_func2>:
// CHECK-NEXT:   210134:       adrp    c16, #0
// CHECK-NEXT:   210138:       add     c16, c16, #296
// CHECK-NEXT:   21013c:       br      c16

// CHECK: 0000000000210140 <__A64ToC64Thunk_func>:
// CHECK-NEXT:   210140:       bx      #4
// CHECK-EMPTY:
// CHECK-NEXT:   0000000000210144 <$c>:
// CHECK-NEXT:   210144:       adrp    c16, #0
// CHECK-NEXT:   210148:       add     c16, c16, #293
// CHECK-NEXT:   21014c:       br      c16

// CHECK: 0000000000210150 <__A64ToC64Thunk__start>:
// CHECK-NEXT:   210150:       bx      #4
// CHECK-EMPTY:
// CHECK-NEXT:   0000000000210154 <$c>:
// CHECK-NEXT:   210154:       adrp    c16, #0
// CHECK-NEXT:   210158:       add     c16, c16, #289
// CHECK-NEXT:   21015c:       br      c16

// CHECK-SYM:        Name: __C64ADRPThunk_func2
// CHECK-SYM-NEXT:   Value: 0x210135
// CHECK-SYM-NEXT:   Size: 12
// CHECK-SYM-NEXT:   Binding: Local
// CHECK-SYM-NEXT:   Type: Function

// CHECK-SYM:        Name: $c
// CHECK-SYM-NEXT:   Value: 0x210134
// CHECK-SYM-NEXT:   Size: 0
// CHECK-SYM-NEXT:   Binding: Local
// CHECK-SYM-NEXT:   Type: None

// CHECK-SYM:        Name: __A64ToC64Thunk_func
// CHECK-SYM-NEXT:   Value: 0x210140
// CHECK-SYM-NEXT:   Size: 16
// CHECK-SYM-NEXT:   Binding: Local
// CHECK-SYM-NEXT:   Type: Function

// CHECK-SYM:        Name: $x
// CHECK-SYM-NEXT:   Value: 0x210140
// CHECK-SYM-NEXT:   Size: 0
// CHECK-SYM-NEXT:   Binding: Local
// CHECK-SYM-NEXT:   Type: None

// CHECK-SYM:        Name: $c
// CHECK-SYM-NEXT:   Value: 0x210144
// CHECK-SYM-NEXT:   Size: 0
// CHECK-SYM-NEXT:   Binding: Local
// CHECK-SYM-NEXT:   Type: None
