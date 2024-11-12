// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64,+morello -filetype=obj -target-abi purecap %s -o %t.o
// RUN: llvm-mc --triple=aarch64-none-elf -filetype=obj %S/Inputs/aarch64-funcs.s -target-abi purecap -o %t2.o
// RUN: ld.lld %t.o %t2.o -o %t
// RUN: llvm-objdump --no-print-imm-hex --no-show-raw-insn --triple=aarch64-none-elf --mattr=+morello -d %t | FileCheck %s
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
// CHECK-NEXT:   2101d8:       b       0x2101ec <__C64ADRPThunk_func2>

// CHECK-LABEL: <func>:
// CHECK-NEXT:   2101dc:       bl      0x2101ec <__C64ADRPThunk_func2>

// CHECK-LABEL: <func2>:
// CHECK-NEXT:   2101e0:       bl      0x2101f8 <__A64ToC64Thunk_func>
// CHECK-NEXT:                 b       0x210208 <__A64ToC64Thunk__start>
// CHECK-NEXT:                 ret

// CHECK-LABEL: <__C64ADRPThunk_func2>:
// CHECK-NEXT:   2101ec:       adrp    c16, 0x210000
// CHECK-NEXT:                 add     c16, c16, #480
// CHECK-NEXT:                 br      c16

// CHECK-LABEL: <__A64ToC64Thunk_func>:
// CHECK-NEXT:   2101f8:       bx      #4
// CHECK-EMPTY:
// CHECK-LABEL:   <$c>:
// CHECK-NEXT:   2101fc:       adrp    c16, 0x210000
// CHECK-NEXT:                 add     c16, c16, #477
// CHECK-NEXT:                 br      c16

// CHECK-LABEL: <__A64ToC64Thunk__start>:
// CHECK-NEXT:   210208:       bx      #4
// CHECK-EMPTY:
// CHECK-LABEL:   <$c>:
// CHECK-NEXT:   21020c:       adrp    c16, 0x210000
// CHECK-NEXT:                 add     c16, c16, #473
// CHECK-NEXT:                 br      c16

// CHECK-SYM:        Name: __C64ADRPThunk_func2
// CHECK-SYM-NEXT:   Value: 0x2101ED
// CHECK-SYM-NEXT:   Size: 12
// CHECK-SYM-NEXT:   Binding: Local
// CHECK-SYM-NEXT:   Type: Function

// CHECK-SYM:        Name: $c
// CHECK-SYM-NEXT:   Value: 0x2101EC
// CHECK-SYM-NEXT:   Size: 0
// CHECK-SYM-NEXT:   Binding: Local
// CHECK-SYM-NEXT:   Type: None

// CHECK-SYM:        Name: __A64ToC64Thunk_func
// CHECK-SYM-NEXT:   Value: 0x2101F8
// CHECK-SYM-NEXT:   Size: 16
// CHECK-SYM-NEXT:   Binding: Local
// CHECK-SYM-NEXT:   Type: Function

// CHECK-SYM:        Name: $x
// CHECK-SYM-NEXT:   Value: 0x2101F8
// CHECK-SYM-NEXT:   Size: 0
// CHECK-SYM-NEXT:   Binding: Local
// CHECK-SYM-NEXT:   Type: None

// CHECK-SYM:        Name: $c
// CHECK-SYM-NEXT:   Value: 0x2101FC
// CHECK-SYM-NEXT:   Size: 0
// CHECK-SYM-NEXT:   Binding: Local
// CHECK-SYM-NEXT:   Type: None
