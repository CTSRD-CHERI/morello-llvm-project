// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64 -filetype=obj %s -o %t.o
// RUN: ld.lld -v --morello-c64-plt %t.o -o %t  2>&1 | FileCheck %s --check-prefix=WARN

/// Check for no "warning: Could not find a real symbol for .data.rel.ro.*"
// WARN-NOT: Could not find a real symbol for {{.*}}

    .text
    .balign 2
    .globl _start
    .type _start, %function
_start:
    ret
 .size _start, .-_start

  .section  .rodata.str,"aMS",%progbits,1
  .type  foo,%object
foo:
  .asciz  "foo"
  .size  foo, .-foo

  .type  bar,%object
bar:
  .asciz  "bar"
  .size  bar, .-bar

  .section .data.rel.ro..L__cap_merged_table,"aw",%progbits
  .p2align 4
  .chericap foo
  .chericap bar
