; RUN: llc -relocation-model=static -mtriple=aarch64-none-elf -target-abi purecap -mattr=+c64 -filetype=obj %s -o - | \
; RUN: llvm-readobj -r - | FileCheck %s

target datalayout = "e-m:e-i64:64-i128:128:128:64-n32:64-S128-pf200:128:128:128:64-A200-P200-G200"
target triple = "aarch64-none--elf"

@str = addrspace(200) global [12 x i8] c"foo bar baz\00", align 1
@ptr1 = addrspace(200) global ptr addrspace(200) getelementptr inbounds ([12 x i8], ptr addrspace(200) @str, i32 0, i64 8), align 16
@ptr2 = addrspace(200) global ptr addrspace(200) @str, align 16

; Don't emit symbols for the capinit relocations as offsets from the section start.

; CHECK: Relocations [
; CHECK-NEXT:  Section (4) .rela.data {
; CHECK-NEXT:    0x10 R_MORELLO_CAPINIT str 0x8
; CHECK-NEXT:    0x20 R_MORELLO_CAPINIT str 0x0
; CHECK-NEXT:  }
; CHECK-NEXT: ]
