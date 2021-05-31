; RUN: llc -mtriple=arm64 -mattr=+morello,+c64 -target-abi purecap -cheri-cap-table-abi=fn-desc -o - %s | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none-unknown-elf"

; Constants that need relocations against symbols in the private data segment
; or functions need to go into the private data segment as well.

%struct.test1 = type { i32, i8 addrspace(200)* }

@x = dso_local addrspace(200) constant i32 4, align 4
@.str = private unnamed_addr addrspace(200) constant [4 x i8] c"foo\00", align 1
@.str.1 = private unnamed_addr addrspace(200) constant [4 x i8] c"bar\00", align 1
@nodesc1 = dso_local addrspace(200) constant [2 x %struct.test1] [%struct.test1 { i32 1, i8 addrspace(200)* getelementptr inbounds ([4 x i8], [4 x i8] addrspace(200)* @.str, i32 0, i32 0) }, %struct.test1 { i32 2, i8 addrspace(200)* getelementptr inbounds ([4 x i8], [4 x i8] addrspace(200)* @.str.1, i32 0, i32 0) }], align 16
@g = internal addrspace(200) global i8 addrspace(200)* null, align 16
@desc2 = dso_local addrspace(200) constant [2 x %struct.test1] [%struct.test1 { i32 1, i8 addrspace(200)* bitcast (i8 addrspace(200)* addrspace(200)* @g to i8 addrspace(200)*) }, %struct.test1 { i32 2, i8 addrspace(200)* getelementptr inbounds ([4 x i8], [4 x i8] addrspace(200)* @.str.1, i32 0, i32 0) }], align 16
@nodesc3 = dso_local addrspace(200) constant [2 x %struct.test1] [%struct.test1 { i32 1, i8 addrspace(200)* bitcast ([2 x %struct.test1] addrspace(200)* @nodesc1 to i8 addrspace(200)*) }, %struct.test1 { i32 2, i8 addrspace(200)* getelementptr inbounds ([4 x i8], [4 x i8] addrspace(200)* @.str.1, i32 0, i32 0) }], align 16
@desc4 = dso_local addrspace(200) constant [2 x %struct.test1] [%struct.test1 { i32 1, i8 addrspace(200)* bitcast (i8 addrspace(200)* () addrspace(200)* @getconst to i8 addrspace(200)*) }, %struct.test1 { i32 2, i8 addrspace(200)* getelementptr inbounds ([4 x i8], [4 x i8] addrspace(200)* @.str.1, i32 0, i32 0) }], align 16
@desc5 = dso_local addrspace(200) constant [2 x %struct.test1] [%struct.test1 { i32 1, i8 addrspace(200)* bitcast (i32 addrspace(200)* @x to i8 addrspace(200)*) }, %struct.test1 { i32 2, i8 addrspace(200)* getelementptr inbounds ([4 x i8], [4 x i8] addrspace(200)* @.str.1, i32 0, i32 0) }], align 16

define dso_local i8 addrspace(200)* @getconst() addrspace(200) #0 {
entry:
  ret i8 addrspace(200)* getelementptr inbounds ([4 x i8], [4 x i8] addrspace(200)* @.str, i64 0, i64 0)
}

define dso_local i8 addrspace(200)* @getg() addrspace(200) #0 {
entry:
  ret i8 addrspace(200)* bitcast (i8 addrspace(200)* addrspace(200)* @g to i8 addrspace(200)*)
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
