// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64 -filetype=obj %s -o %t.o
// RUN: ld.lld -v %t.o -o %t 2>&1 | FileCheck --check-prefix=WARN %s
// RUN: llvm-readobj --cap-relocs --expand-relocs %t | FileCheck %s

// WARN-NOT: warning: could not determine size of cap reloc against __preinit_array_start
// WARN-NOT: warning: could not determine size of cap reloc against __init_array_start
// WARN-NOT: warning: could not determine size of cap reloc against __fini_array_start
// WARN-NOT: ld.lld: warning: could not determine size of cap reloc against __start_mysection

/// Check that linker defined section start symbols get the size of the output
/// section, and stop/end symbols get a size of 0.

 .section .preinit_array, "a", %preinit_array
 .balign 1024
 .xword 0

 .section .init_array, "a", %init_array
 .balign 1024
 .xword 0

 .section .fini_array, "a", %fini_array
 .balign 1024
 .xword 0

 .section mysection, "a", %progbits
 .balign 1024
 .xword 0

 .text
 .balign 1024

 .globl _start
 .type _start, %function
_start: ret

 .data.rel.ro

 .chericap __preinit_array_start
 .chericap __preinit_array_end

 .chericap __init_array_start
 .chericap __init_array_end

 .chericap __fini_array_start
 .chericap __fini_array_end

 .chericap __start_mysection

 .chericap __stop_mysection
// CHECK: CHERI __cap_relocs [
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x221410
// CHECK-NEXT:     Base: __preinit_array_start (0x220C00)
// CHECK-NEXT:     Offset: 0
// CHECK-NEXT:     Length: 8
// CHECK-NEXT:     Permissions: (RODATA) (0x1BFBE)
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x221420
// CHECK-NEXT:     Base: __preinit_array_end (0x220C08)
// CHECK-NEXT:     Offset: 0
// CHECK-NEXT:     Length: 0
// CHECK-NEXT:     Permissions: (RODATA) (0x1BFBE)
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x221430
// CHECK-NEXT:     Base: __init_array_start (0x221000)
// CHECK-NEXT:     Offset: 0
// CHECK-NEXT:     Length: 8
// CHECK-NEXT:     Permissions: (RODATA) (0x1BFBE)
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x221440
// CHECK-NEXT:     Base: __init_array_end (0x221008)
// CHECK-NEXT:     Offset: 0
// CHECK-NEXT:     Length: 0
// CHECK-NEXT:     Permissions: (RODATA) (0x1BFBE)
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x221450
// CHECK-NEXT:     Base: __fini_array_start (0x221400)
// CHECK-NEXT:     Offset: 0
// CHECK-NEXT:     Length: 8
// CHECK-NEXT:     Permissions: (RODATA) (0x1BFBE)
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x221460
// CHECK-NEXT:     Base: __fini_array_end (0x221408)
// CHECK-NEXT:     Offset: 0
// CHECK-NEXT:     Length: 0
// CHECK-NEXT:     Permissions: (RODATA) (0x1BFBE)
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x221470
// CHECK-NEXT:     Base: __start_mysection (0x200400)
// CHECK-NEXT:     Offset: 0
// CHECK-NEXT:     Length: 8
// CHECK-NEXT:     Permissions: (RODATA) (0x1BFBE)
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Location: 0x221480
// CHECK-NEXT:     Base: __stop_mysection (0x200408)
// CHECK-NEXT:     Offset: 0
// CHECK-NEXT:     Length: 0
// CHECK-NEXT:     Permissions: (RODATA) (0x1BFBE)
