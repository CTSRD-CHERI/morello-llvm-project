; RUN: llc -mtriple=arm64 -mattr=+morello,+c64 -target-abi purecap -cheri-cap-table-abi=fn-desc -o - %s | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none-unknown-elf"

; Constants that need relocations against symbols in the private data segment
; or functions need to go into the private data segment as well.

%struct.test1 = type { i32, ptr addrspace(200) }

@x = dso_local addrspace(200) constant i32 4, align 4
@.str = private unnamed_addr addrspace(200) constant [4 x i8] c"foo\00", align 1
@.str.1 = private unnamed_addr addrspace(200) constant [4 x i8] c"bar\00", align 1
@nodesc1 = dso_local addrspace(200) constant [2 x %struct.test1] [%struct.test1 { i32 1, ptr addrspace(200) @.str }, %struct.test1 { i32 2, ptr addrspace(200) @.str.1 }], align 16
@g = internal addrspace(200) global ptr addrspace(200) null, align 16
@desc2 = dso_local addrspace(200) constant [2 x %struct.test1] [%struct.test1 { i32 1, ptr addrspace(200) @g }, %struct.test1 { i32 2, ptr addrspace(200) @.str.1 }], align 16
@nodesc3 = dso_local addrspace(200) constant [2 x %struct.test1] [%struct.test1 { i32 1, ptr addrspace(200) @nodesc1 }, %struct.test1 { i32 2, ptr addrspace(200) @.str.1 }], align 16
@desc4 = dso_local addrspace(200) constant [2 x %struct.test1] [%struct.test1 { i32 1, ptr addrspace(200) () addrspace(200)* @getconst }, %struct.test1 { i32 2, ptr addrspace(200) @.str.1 }], align 16
@desc5 = dso_local addrspace(200) constant [2 x %struct.test1] [%struct.test1 { i32 1, ptr addrspace(200) @x }, %struct.test1 { i32 2, ptr addrspace(200) @.str.1 }], align 16

define dso_local ptr addrspace(200) @getconst() addrspace(200) #0 {
entry:
  ret ptr addrspace(200) @.str
}

define dso_local ptr addrspace(200) @getg() addrspace(200) #0 {
entry:
  ret ptr addrspace(200) @g
}

; CHECK:	.type	nodesc1,@object         // @nodesc1
; CHECK-NEXT:	.section	.data.rel.ro,"aw",@progbits
; CHECK-NEXT:	.globl	nodesc1
; CHECK-NEXT:	.p2align	4
; CHECK-NEXT:   nodesc1:

; CHECK:	.type	desc2,@object           // @desc2
; CHECK-NEXT:	.section	.desc.data.rel.ro,"aw",@progbits
; CHECK-NEXT:	.globl	desc2
; CHECK-NEXT:	.p2align	4
; CHECK-NEXT:   desc2:

; CHECK:	.type	nodesc3,@object         // @nodesc3
; CHECK-NEXT:	.section	.data.rel.ro,"aw",@progbits
; CHECK-NEXT:	.globl	nodesc3
; CHECK-NEXT:	.p2align	4
; CHECK-NEXT:  nodesc3:

; CHECK:	.type	desc4,@object           // @desc4
; CHECK-NEXT:	.section	.desc.data.rel.ro,"aw",@progbits
; CHECK-NEXT:	.globl	desc4
; CHECK-NEXT:	.p2align	4
; CHECK-NEXT:   desc4:

; CHECK:	.type	desc5,@object           // @desc5
; CHECK-NEXT:	.section	.data.rel.ro,"aw",@progbits
; CHECK-NEXT:	.globl	desc5
; CHECK-NEXT:	.p2align	4
; CHECK-NEXT:   desc5:

; CHECK:	.type	.L__cap_merged_table,@object // @__cap_merged_table
; CHECK-NEXT:	.section	.desc.data.rel.ro,"aw",@progbits
; CHECK-NEXT:	.p2align	4
; CHECK-NEXT:   .L__cap_merged_table:
