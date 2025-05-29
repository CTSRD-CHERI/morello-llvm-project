; RUN: llc -mtriple=aarch64-none-elf -mattr=+morello,+c64 \
; RUN:     -frame-pointer=all -target-abi purecap < %s | FileCheck %s

$foo = comdat any
$bar = comdat any
@foo = internal addrspace(200) global i32 0, comdat, align 4
@bar = internal addrspace(200) global i32 0, comdat, align 4

define i32 @baz() {
  %1 = load i32, ptr addrspace(200) @foo
  %2 = load i32, ptr addrspace(200) @bar
  %3 = add i32 %1, %2
  ret i32 %3
}

; CHECK:	.hidden	__cap_merged_tablebar           // @__cap_merged_tablebar
; CHECK-NEXT:	.type	__cap_merged_tablebar,@object
; CHECK-NEXT:	.section	.data.rel.ro.__cap_merged_tablebar,"aGw",@progbits,__cap_bar,comdat
; CHECK-NEXT:	.weak	__cap_merged_tablebar
; CHECK-NEXT:	.p2align	4
; CHECK-NEXT: __cap_merged_tablebar:
; CHECK-NEXT:	.chericap	bar
; CHECK-NEXT:	.size	__cap_merged_tablebar, 16

; CHECK:	.hidden	__cap_merged_tablefoo           // @__cap_merged_tablefoo
; CHECK-NEXT:	.type	__cap_merged_tablefoo,@object
; CHECK-NEXT:	.section	.data.rel.ro.__cap_merged_tablefoo,"aGw",@progbits,__cap_foo,comdat
; CHECK-NEXT:	.weak	__cap_merged_tablefoo
; CHECK-NEXT:	.p2align	4
; CHECK-NEXT: __cap_merged_tablefoo:
; CHECK-NEXT:	.chericap	foo
; CHECK-NEXT:	.size	__cap_merged_tablefoo, 16
