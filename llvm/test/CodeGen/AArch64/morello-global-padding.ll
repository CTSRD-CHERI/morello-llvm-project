; RUN: llc -mtriple=aarch64 -mattr=+morello,+c64 -target-abi purecap -o - %s | FileCheck %s --check-prefix=ASM
; RUN: llc -mtriple=aarch64 -mattr=+morello,+c64 -target-abi purecap -o - %s -filetype=obj | \
; RUN:     llvm-readelf --syms - | FileCheck %s --check-prefix=SYMS

@arr1 = internal addrspace(200) global [65535 x i8] zeroinitializer, align 1
@arr2 = common addrspace(200) global [65535 x i8] zeroinitializer, align 1
@arr3 = private addrspace(200) global [65535 x i8] zeroinitializer, align 1
@arr4 = linkonce addrspace(200) global [65535 x i8] zeroinitializer, align 1
@arr5 = weak addrspace(200) global [65535 x i8] zeroinitializer, align 1
@arr6 = thread_local addrspace(200) global [65535 x i8] zeroinitializer, align 1

define i32 @foo() addrspace(200) {
entry:
  %retval = alloca i32, align 4, addrspace(200)
  store i32 0, ptr addrspace(200) %retval, align 4
  %0 = load i8, ptr addrspace(200) @arr3, align 1
  %conv = zext i8 %0 to i32
  ret i32 %conv
}

; ASM:      .type arr1,@object                    // @arr1
; ASM-NEXT: .local  arr1
; ASM-NEXT: .comm arr1,65536,32                   // adding 1 bytes of tail padding for precise bounds.
; ASM-NEXT: .type arr2,@object                    // @arr2
; ASM-NEXT: .comm arr2,65536,32                   // adding 1 bytes of tail padding for precise bounds.
; ASM-NEXT: .type .Larr3,@object                  // @arr3
; ASM-NEXT: .local  .Larr3
; ASM-NEXT: .comm .Larr3,65536,32                 // adding 1 bytes of tail padding for precise bounds.
; ASM-NEXT: .type arr4,@object                    // @arr4
; ASM-NEXT: .bss
; ASM-NEXT: .weak arr4
; ASM-NEXT: .p2align  5
; ASM-LABEL: arr4:
; ASM-NEXT: .zero 65535
; ASM-NEXT: .zero 1                               // Tail padding to ensure precise bounds
; ASM-NEXT: .size arr4, 65536
; ASM:      .type arr5,@object                    // @arr5
; ASM-NEXT: .weak arr5
; ASM-NEXT: .p2align  5
; ASM-LABEL: arr5:
; ASM-NEXT: .zero 65535
; ASM-NEXT: .zero 1                               // Tail padding to ensure precise bounds
; ASM-NEXT: .size arr5, 65536
; ASM:      .type arr6,@object                    // @arr6
; ASM-NEXT: .section  .tbss,"awT",@nobits
; ASM-NEXT: .globl  arr6
; ASM-NEXT: .p2align  5
; ASM-LABEL: arr6:
; ASM-NEXT: .zero 65535
; ASM-NEXT: .zero 1                               // Tail padding to ensure precise bounds
; ASM-NEXT: .size arr6, 65536

; SYMS: Symbol table '.symtab' contains 17 entries:
; SYMS-NEXT:   Num:    Value          Size Type    Bind   Vis       Ndx Name
; SYMS-NEXT:     0: 0000000000000000     0 NOTYPE  LOCAL  DEFAULT   UND
; SYMS-NEXT:     1: 0000000000000000     0 FILE    LOCAL  DEFAULT   ABS morello-global-padding.ll
; SYMS-NEXT:     2: 0000000000000000     0 SECTION LOCAL  DEFAULT     2 .text
; SYMS-NEXT:     3: 0000000000000000     0 NOTYPE  LOCAL  DEFAULT     2 $c.0
; SYMS-NEXT:     4: 0000000000000000 65536 OBJECT  LOCAL  DEFAULT     4 arr1
; SYMS-NEXT:     5: 0000000000000000     0 NOTYPE  LOCAL  DEFAULT     4 $d.1
; SYMS-NEXT:     6: 0000000000010000 65536 OBJECT  LOCAL  DEFAULT     4 .Larr3
; SYMS-NEXT:     7: 0000000000000000     0 NOTYPE  LOCAL  DEFAULT     5 $d.2
; SYMS-NEXT:     8: 0000000000000000     0 SECTION LOCAL  DEFAULT     6 .data.rel.ro
; SYMS-NEXT:     9: 0000000000000000     0 NOTYPE  LOCAL  DEFAULT     6 $d.3
; SYMS-NEXT:    10: 0000000000000000     0 NOTYPE  LOCAL  DEFAULT     9 $d.4
; SYMS-NEXT:    11: 0000000000000000     0 NOTYPE  LOCAL  DEFAULT    10 $d.5
; SYMS-NEXT:    12: 0000000000000001    28 FUNC    GLOBAL DEFAULT     2 foo
; SYMS-NEXT:    13: 0000000000000020 65536 OBJECT  GLOBAL DEFAULT   COM arr2
; SYMS-NEXT:    14: 0000000000020000 65536 OBJECT  WEAK   DEFAULT     4 arr4
; SYMS-NEXT:    15: 0000000000030000 65536 OBJECT  WEAK   DEFAULT     4 arr5
; SYMS-NEXT:    16: 0000000000000000 65536 TLS     GLOBAL DEFAULT     5 arr6
