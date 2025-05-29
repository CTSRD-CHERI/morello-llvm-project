; RUN: llc < %s -mtriple=aarch64-none-elf -mattr=+morello -o - | FileCheck %s

; Capabilities are caller-saved.

declare void @bar(ptr addrspace(200) %x)
declare void @baz()

; CHECK-LABEL: foo
; CHECK:    sub sp, sp, #32
; CHECK:    str x30, [sp, #16]
; CHECK:    str c0, [sp, #0]
; CHECK:    bl  baz
; CHECK:    ldr c0, [sp, #0]
; CHECK:    bl  bar
; CHECK:    ldr x30, [sp, #16]
; CHECK:    add sp, sp, #32
; CHECK:    ret

define void @foo(ptr addrspace(200) %x) {
  call void @baz()
  call void @bar(ptr addrspace(200) %x)
  ret void
}
