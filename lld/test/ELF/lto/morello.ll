; REQUIRES: aarch64

; RUN: split-file %s %t
; RUN: llvm-mc -triple aarch64-unknown-freebsd14.0 -mattr=+morello,+c64 -target-abi purecap \
; RUN:     -filetype=obj %t/morello-crtbegin.s -o %t/morello-crtbegin.o
; RUN: llvm-readobj -h %t/morello-crtbegin.o | FileCheck %s --check-prefix=PURECAP-EFLAGS
; RUN: llvm-as %t/morello-main.ll -o %t/morello-main.o
; RUN: ld.lld %t/morello-crtbegin.o %t/morello-main.o -o %t/main.exe -plugin-opt=-emulated-tls

; RUN: llvm-readobj -h %t/main.exe | FileCheck %s --check-prefix=PURECAP-EFLAGS
; RUN: llvm-objdump -d %t/main.exe | FileCheck %s --check-prefix=DISASM

; PURECAP-EFLAGS: Flags [
; PURECAP-EFLAGS-NEXT: EF_AARCH64_CHERI_PURECAP

;; Check that the purecap ABI was inferred for LTO and we generated a purecap return instruction:
; DISASM: Disassembly of section .text:
; DISASM-EMPTY:
; DISASM-NEXT: 0000000000210190 <_start>:
; DISASM-NEXT:   210190: 01 00 00 94  	bl	0x210194 <main>
; DISASM-EMPTY:
; DISASM-NEXT: 0000000000210194 <main>:
; DISASM-NEXT:   210194: c0 53 c2 c2  	ret	c30



;--- morello-crtbegin.s
.globl _start
.type _start, @function
_start:
    bl main

;--- morello-main.ll
target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-unknown-freebsd14.0"

define void @main() {
entry:
  ret void
}
