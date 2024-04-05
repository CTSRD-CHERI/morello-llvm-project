// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64,+morello -filetype=obj %S/Inputs/shlib.s -o %t1.o
// RUN: llvm-mc --triple=aarch64-none-elf -target-abi purecap -mattr=+c64,+morello -filetype=obj %s -o %t2.o
// RUN: ld.lld --shared --soname=t.so  %t1.o -o %t.so
// RUN: ld.lld %t.so %t2.o -o %t
// RUN: llvm-objdump --print-imm-hex --no-show-raw-insn -s -d --triple=aarch64-none-elf --mattr=+morello %t | FileCheck %s
// RUN: llvm-readobj --relocations %t | FileCheck %s --check-prefix=RELS
// RUN: ld.lld --pie  %t.so %t2.o -o %tpie
// RUN: llvm-objdump --print-imm-hex --no-show-raw-insn -s -d --triple=aarch64-none-elf --mattr=+morello %tpie | FileCheck %s --check-prefix=CHECK-PIE
// RUN: llvm-readobj --relocations %tpie | FileCheck %s --check-prefix=RELS-PIE

/// Application using a shared library. Expect to see dynamic
/// relocations and not a __cap_relocs section. The link is repeated for -fpie
 .text
 .global _start
 .type _start, %function
 .size _start, 8
_start:
 bl func
 adrp c0, :got: rodata
 ldr  c0, [c0, :got_lo12: rodata]
 adrp c1, :got: data
 ldr  c1, [c1, :got_lo12: data]
 adrp c2, :got: appdata
 ldr  c2, [c2, :got_lo12: appdata]
 adrp c3, :got: from_app
 ldr  c3, [c3, :got_lo12: from_app]
 adrp c4, :got: func2
 ldr  c4, [c4, :got_lo12: func2]
 adrp c5, :got: _start
 ldr  c5, [c5, :got_lo12: _start]
 ret

 .global from_app
 .type from_app, %function
 .size from_app, 4
from_app:
 ret

 .global func2

 .data.rel.ro
 .capinit rodata
 .xword 0
 .xword 0
 .capinit data
 .xword 0
 .xword 0
 .capinit appdata
 .xword 0
 .xword 0
 .capinit from_app
 .xword 0
 .xword 0
 .capinit func2
 .xword 0
 .xword 0

// CHECK: Contents of section .data.rel.ro:
/// rodata (shlib.so) rw (default) size 8
// CHECK-NEXT:  220510 00000000 00000000 08000000 00000002
/// data (shlib.so) rw (default) size 8
// CHECK-NEXT:  220520 00000000 00000000 08000000 00000002
/// appdata 0x2306d0 rw size 8
// CHECK-NEXT:  220530 d0062300 00000000 08000000 00000002
/// from_app 210469 exec size 4
// CHECK-NEXT:  220540 40022000 00000000 00050300 00000004
/// func2 (shlib.so) exec size 4
// CHECK-NEXT:  220550 00000000 00000000 04000000 00000004

// CHECK-PIE: Contents of section .data.rel.ro:
/// rodata (shlib.so) rw (default) size 8
// CHECK-PIE-NEXT:  20510 00000000 00000000 08000000 00000002
/// data (shlib.so) rw (default) size 8
// CHECK-PIE-NEXT:  20520 00000000 00000000 08000000 00000002
/// appdata 0x30670 rw size 8
// CHECK-PIE-NEXT:  20530 e0060300 00000000 08000000 00000002
/// from_app 14069 exec size 4
// CHECK-PIE-NEXT:  20540 40020000 00000000 00050300 00000004
/// func2 (shlib.so) exec size 4
// CHECK-PIE-NEXT:  20550 00000000 00000000 04000000 00000004

 .data
 .global appdata
 .type appdata, %object
 .size appdata, 8
appdata: .xword 8

// CHECK: Contents of section .got:
/// from_app 230622 exec size 4
// CHECK-NEXT:  220670 40022000 00000000 00050300 00000004
/// func2 (shlib.so) exec size 4
// CHECK-NEXT:  220680 00000000 00000000 04000000 00000004
/// rodata (shlib.so) RW (default) size 8
// CHECK-NEXT:  220690 00000000 00000000 08000000 00000002
/// data (shlib.so) RW (default) size 8
// CHECK-NEXT:  2206a0 00000000 00000000 08000000 00000002
/// _start 210431 exec size 4
// CHECK-NEXT:  2206b0 40022000 00000000 00050300 00000004
/// appdata 0x23000 rw size 8
// CHECK-NEXT:  2206c0 d0062300 00000000 08000000 00000002

// CHECK-PIE: Contents of section .got:
/// from_app 14069 exec size 4
// CHECK-PIE-NEXT:  20680 40020000 00000000 00050300 00000004
/// func2 (shlib.so) exec size 4
// CHECK-PIE-NEXT:  20690 00000000 00000000 04000000 00000004
/// rodata (shlib.so) RW (default) size 8
// CHECK-PIE-NEXT:  206a0 00000000 00000000 08000000 00000002
/// data (shlib.so) RW (default) size 8
// CHECK-PIE-NEXT:  206b0 00000000 00000000 08000000 00000002
/// _start 10431 exec size 4
// CHECK-PIE-NEXT:  206c0 40020000 00000000 00050300 00000004
/// appdata 0x30670 rw size 8
// CHECK-PIE-NEXT:  206d0 e0060300 00000000 08000000 00000002

// CHECK: Contents of section .data:
// CHECK-NEXT:  2306d0 08000000 00000000

// CHECK-PIE: Contents of section .data:
// CHECK-PIE-NEXT:  306e0 08000000 00000000

// CHECK: Contents of section .got.plt:
// CHECK-NEXT:  2306e0 00000000 00000000 00000000 00000000
// CHECK-NEXT:  2306f0 00000000 00000000 00000000 00000000
// CHECK-NEXT:  230700 00000000 00000000 00000000 00000000

/// .got.plt[3] should be initialized to point to the PLT Header (002104e1)
// CHECK-NEXT:  230710 41022000 00000000 00050300 00000004

// CHECK-PIE: Contents of section .got.plt:
// CHECK-PIE-NEXT: 306f0 00000000 00000000 00000000 00000000
// CHECK-PIE-NEXT: 30700 00000000 00000000 00000000 00000000
// CHECK-PIE-NEXT: 30710 00000000 00000000 00000000 00000000

/// .got.plt[3] should be initialized to point to the PLT Header (000104e1)
// CHECK-PIE-NEXT: 30720 41020000 00000000 00050300 00000004

// CHECK-LABEL: <_start>:
// CHECK-NEXT: 2104a0: bl   0x210500
// CHECK-NEXT:         adrp c0, 0x220000
// CHECK-NEXT:         ldr  c0, [c0, #0x690]
// CHECK-NEXT:         adrp c1, 0x220000
// CHECK-NEXT:         ldr  c1, [c1, #0x6a0]
// CHECK-NEXT:         adrp c2, 0x220000
// CHECK-NEXT:         ldr  c2, [c2, #0x6c0]
// CHECK-NEXT:         adrp c3, 0x220000
// CHECK-NEXT:         ldr  c3, [c3, #0x670]
// CHECK-NEXT:         adrp c4, 0x220000
// CHECK-NEXT:         ldr  c4, [c4, #0x680]
// CHECK-NEXT:         adrp c5, 0x220000
// CHECK-NEXT:         ldr  c5, [c5, #0x6b0]
// CHECK-NEXT:         ret  c30

// CHECK-LABEL: <from_app>:
// CHECK-NEXT:   2104d8:  ret c30

/// Check that the PLT header points to .got.plt[2] (2306f0)
// CHECK-LABEL: <.plt>:
// CHECK-NEXT: 2104e0: stp  c16, c30, [csp, #-0x20]!
// CHECK-NEXT:         adrp c16, 0x230000
// CHECK-NEXT:         ldr  c17, [c16, #0x700]
// CHECK-NEXT:         add  c16, c16, #0x700
// CHECK-NEXT:         br   c17
// CHECK-NEXT:         nop
// CHECK-NEXT:         nop
// CHECK-NEXT:         nop

/// Check that the next PLT entry (.plt[3]) points to .got.plt[3] (230710)
// CHECK-NEXT:         adrp c16, 0x230000
// CHECK-NEXT:         add  c16, c16, #0x710
// CHECK-NEXT:         ldr  c17, [c16, #0x0]
// CHECK-NEXT:         br   c17

// CHECK-PIE-LABEL: <_start>:
// CHECK-PIE-NEXT:    104a0: bl  0x10500
// CHECK-PIE-NEXT:           adrp c0, 0x20000
// CHECK-PIE-NEXT:           ldr  c0, [c0, #0x6a0]
// CHECK-PIE-NEXT:           adrp c1, 0x20000
// CHECK-PIE-NEXT:           ldr  c1, [c1, #0x6b0]
// CHECK-PIE-NEXT:           adrp c2, 0x20000
// CHECK-PIE-NEXT:           ldr  c2, [c2, #0x6d0]
// CHECK-PIE-NEXT:           adrp c3, 0x20000
// CHECK-PIE-NEXT:           ldr  c3, [c3, #0x680]
// CHECK-PIE-NEXT:           adrp c4, 0x20000
// CHECK-PIE-NEXT:           ldr  c4, [c4, #0x690]
// CHECK-PIE-NEXT:           adrp c5, 0x20000
// CHECK-PIE-NEXT:           ldr  c5, [c5, #0x6c0]
// CHECK-PIE-NEXT:           ret  c30

// CHECK-PIE-LABEL: <from_app>:
// CHECK-PIE-NEXT:    104d8: ret c30

/// Check that the PLT header points to .got.plt[2] (30700)
// CHECK-PIE-LABEL: <.plt>:
// CHECK-PIE-NEXT:    104e0: stp  c16, c30, [csp, #-0x20]!
// CHECK-PIE-NEXT:           adrp c16, 0x30000
// CHECK-PIE-NEXT:           ldr  c17, [c16, #0x710]
// CHECK-PIE-NEXT:           add  c16, c16, #0x710
// CHECK-PIE-NEXT:           br   c17
// CHECK-PIE-NEXT:           nop
// CHECK-PIE-NEXT:           nop
// CHECK-PIE-NEXT:           nop

/// Check that the next PLT entry (.plt[3]) points to .got.plt[3] (30710)
// CHECK-PIE-NEXT:           adrp  c16, 0x30000
// CHECK-PIE-NEXT:           add  c16, c16, #0x720
// CHECK-PIE-NEXT:           ldr  c17, [c16, #0x0]
// CHECK-PIE-NEXT:           br  c17

// RELS: Relocations [
// RELS-NEXT:   Section {{.*}} .rela.dyn {
/// .capinit appdata
// RELS-NEXT:     0x220530 R_MORELLO_RELATIVE - 0x0
//// .capinit from_app (strictly speaking don't need symbol here)
// RELS-NEXT:     0x220540 R_MORELLO_RELATIVE from_app 0x10299
/// .got from_app (strictly speaking don't need symbol here)
// RELS-NEXT:     0x220670 R_MORELLO_RELATIVE from_app 0x10299
/// _start
// RELS-NEXT:     0x2206B0 R_MORELLO_RELATIVE - 0x10261
// .got appdata
// RELS-NEXT:     0x2206C0 R_MORELLO_RELATIVE - 0x0
/// .capinit func2
// RELS-NEXT:     0x220550 R_MORELLO_CAPINIT func2 0x0
/// .got func2
// RELS-NEXT:     0x220680 R_MORELLO_GLOB_DAT func2 0x0
/// .capinit rodata
// RELS-NEXT:     0x220510 R_MORELLO_CAPINIT rodata 0x0
/// .got rodata
// RELS-NEXT:     0x220690 R_MORELLO_GLOB_DAT rodata 0x0
/// .capinit data
// RELS-NEXT:     0x220520 R_MORELLO_CAPINIT data 0x0
/// .got data
// RELS-NEXT:     0x2206A0 R_MORELLO_GLOB_DAT data 0x0
// RELS-NEXT:   }
// RELS-NEXT:   Section {{.*}} .rela.plt {
// RELS-NEXT:     0x230710 R_MORELLO_JUMP_SLOT func 0x102A0

// RELS-PIE: Relocations [
// RELS-PIE-NEXT:   Section {{.*}} .rela.dyn {
/// .capinit appdata
// RELS-PIE-NEXT:     0x20530 R_MORELLO_RELATIVE - 0x0
/// .capinit from_app (strictly speaking don't need symbol here)
// RELS-PIE-NEXT:     0x20540 R_MORELLO_RELATIVE from_app 0x10299
/// .got from_app (strictly speaking don't need symbol here)
// RELS-PIE-NEXT:     0x20680 R_MORELLO_RELATIVE from_app 0x10299
/// _start
// RELS-PIE-NEXT:     0x206C0 R_MORELLO_RELATIVE - 0x10261
/// .got appdata
// RELS-PIE-NEXT:     0x206D0 R_MORELLO_RELATIVE - 0x0
/// .capinit func2
// RELS-PIE-NEXT:     0x20550 R_MORELLO_CAPINIT func2 0x0
/// .got func2
// RELS-PIE-NEXT:     0x20690 R_MORELLO_GLOB_DAT func2 0x0
/// .capinit rodata
// RELS-PIE-NEXT:     0x20510 R_MORELLO_CAPINIT rodata 0x0
/// .got rodata
// RELS-PIE-NEXT:     0x206A0 R_MORELLO_GLOB_DAT rodata 0x0
/// .capinit data
// RELS-PIE-NEXT:     0x20520 R_MORELLO_CAPINIT data 0x0
/// .got data
// RELS-PIE-NEXT:     0x206B0 R_MORELLO_GLOB_DAT data 0x0
// RELS-PIE-NEXT:   }
// RELS-PIE-NEXT:   Section {{.*}} .rela.plt {
// RELS-PIE-NEXT:     0x30720 R_MORELLO_JUMP_SLOT func 0x102A0
