; RUN: llc -march=arm64 -mattr=+c64,+morello -target-abi purecap -o - %s | FileCheck %s
; RUN: llc -march=arm64 -mattr=+c64,+morello -target-abi purecap -filetype=obj -function-sections -o - %s | llvm-readobj --symbols - | FileCheck %s --check-prefix=SYMS

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none--elf"

@memset_c = alias ptr addrspace(200) (ptr addrspace(200), i32, i64), ptr addrspace(200) (ptr addrspace(200), i32, i64) addrspace(200)* @memset
@memcpy_c = alias ptr addrspace(200) (ptr addrspace(200), ptr addrspace(200), i64), ptr addrspace(200) (ptr addrspace(200), ptr addrspace(200), i64) addrspace(200)* @memcpy
@mempcpy_c = alias ptr addrspace(200) (ptr addrspace(200), ptr addrspace(200), i64), ptr addrspace(200) (ptr addrspace(200), ptr addrspace(200), i64) addrspace(200)* @mempcpy
@memmove_c = alias ptr addrspace(200) (ptr addrspace(200), ptr addrspace(200), i64), ptr addrspace(200) (ptr addrspace(200), ptr addrspace(200), i64) addrspace(200)* @memmove

define ptr addrspace(200) @memset(ptr addrspace(200) readnone returned %a, i32 %b, i64 %c) addrspace(200) #0 {
entry:
  ret ptr addrspace(200) %a
}

define ptr addrspace(200) @memcpy(ptr addrspace(200) readnone returned %a, ptr addrspace(200) nocapture readnone %b, i64 %c) addrspace(200) #0 {
entry:
  ret ptr addrspace(200) %a
}

define ptr addrspace(200) @mempcpy(ptr addrspace(200) readnone returned %a, ptr addrspace(200) nocapture readnone %b, i64 %c) addrspace(200) #0 {
entry:
  ret ptr addrspace(200) %a
}

define ptr addrspace(200) @memmove(ptr addrspace(200) readnone returned %a, ptr addrspace(200) nocapture readnone %b, i64 %c) addrspace(200) #0 {
entry:
  ret ptr addrspace(200) %a
}

attributes #0 = { norecurse nounwind readnone "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

; CHECK: .globl memset_c
; CHECK-NEXT: .type memset_c,@function
; CHECK-NEXT: .set memset_c, memset
; CHECK: .globl memcpy_c
; CHECK-NEXT: .type memcpy_c,@function
; CHECK-NEXT: .set memcpy_c, memcpy
; CHECK: .globl mempcpy_c
; CHECK-NEXT: .type mempcpy_c,@function
; CHECK-NEXT: .set mempcpy_c, mempcpy
; CHECK: .globl memmove_c
; CHECK-NEXT: .type memmove_c,@function
; CHECK-NEXT: .set memmove_c, memmove

; SYMS:        Name: memset
; SYMS-NEXT:   Value: 0x1
; SYMS-NEXT:   Size: 4
; SYMS-NEXT:   Binding: Global
; SYMS-NEXT:   Type: Function
; SYMS-NEXT:   Other: 0
; SYMS-NEXT:   Section: .text.memset

; SYMS:      Name: memcpy
; SYMS-NEXT: Value: 0x1
; SYMS-NEXT: Size: 4
; SYMS-NEXT: Binding: Global
; SYMS-NEXT: Type: Function
; SYMS-NEXT: Other: 0
; SYMS-NEXT: Section: .text.memcpy

; SYMS:        Name: mempcpy
; SYMS-NEXT:   Value: 0x1
; SYMS-NEXT:   Size: 4
; SYMS-NEXT:   Binding: Global
; SYMS-NEXT:   Type: Function
; SYMS-NEXT:   Other: 0
; SYMS-NEXT:   Section: .text.mempcpy

; SYMS:        Name: memmove
; SYMS-NEXT:   Value: 0x1
; SYMS-NEXT:   Size: 4
; SYMS-NEXT:   Binding: Global
; SYMS-NEXT:   Type: Function
; SYMS-NEXT:   Other: 0
; SYMS-NEXT:   Section: .text.memmove

; SYMS:        Name: memset_c
; SYMS-NEXT:   Value: 0x1
; SYMS-NEXT:   Size: 4
; SYMS-NEXT:   Binding: Global
; SYMS-NEXT:   Type: Function
; SYMS-NEXT:   Other: 0
; SYMS-NEXT:   Section: .text.memset

; SYMS:        Name: memcpy_c
; SYMS-NEXT:   Value: 0x1
; SYMS-NEXT:   Size: 4
; SYMS-NEXT:   Binding: Global
; SYMS-NEXT:   Type: Function
; SYMS-NEXT:   Other: 0
; SYMS-NEXT:   Section: .text.memcpy

; SYMS:        Name: mempcpy_c
; SYMS-NEXT:   Value: 0x1
; SYMS-NEXT:   Size: 4
; SYMS-NEXT:   Binding: Global
; SYMS-NEXT:   Type: Function
; SYMS-NEXT:   Other: 0
; SYMS-NEXT:   Section: .text.mempcpy

; SYMS:        Name: memmove_c
; SYMS-NEXT:   Value: 0x1
; SYMS-NEXT:   Size: 4
; SYMS-NEXT:   Binding: Global
; SYMS-NEXT:   Type: Function
; SYMS-NEXT:   Other: 0
; SYMS-NEXT:   Section: .text.memmove
