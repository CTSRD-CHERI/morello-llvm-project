// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64,+morello -filetype=obj %S/Inputs/shlib.s -o %t.o
// RUN: ld.lld --shared --soname=t.so --morello-c64-plt %t.o -o %t.so
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64,+morello -filetype=obj %s -o %t.o
// RUN: ld.lld --morello-c64-plt %t.so %t.o -o %t
// RUN: llvm-objdump --print-imm-hex --no-show-raw-insn -s -d --triple=aarch64-none-elf --mattr=+morello %t | FileCheck %s
// RUN: llvm-readobj --relocations %t | FileCheck %s --check-prefix=RELS
// RUN: ld.lld --pie --morello-c64-plt %t.so %t.o -o %tpie
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
// CHECK-NEXT:  2204a0 00000000 00000000 08000000 00000002
/// data (shlib.so) rw (default) size 8
// CHECK-NEXT:  2204b0 00000000 00000000 08000000 00000002
/// appdata 0x230660 rw size 8
// CHECK-NEXT:  2204c0 60062300 00000000 08000000 00000002
/// from_app 210469 exec size 4
// CHECK-NEXT:  2204d0 69042100 00000000 04000000 00000004
/// func2 (shlib.so) exec size 4
// CHECK-NEXT:  2204e0 00000000 00000000 04000000 00000004

// CHECK-PIE: Contents of section .data.rel.ro:
/// rodata (shlib.so) rw (default) size 8
// CHECK-PIE-NEXT:  204a0 00000000 00000000 08000000 00000002
/// data (shlib.so) rw (default) size 8
// CHECK-PIE-NEXT:  204b0 00000000 00000000 08000000 00000002
/// appdata 0x30660 rw size 8
// CHECK-PIE-NEXT:  204c0 60060300 00000000 08000000 00000002
/// from_app 14069 exec size 4
// CHECK-PIE-NEXT:  204d0 69040100 00000000 04000000 00000004
/// func2 (shlib.so) exec size 4
// CHECK-PIE-NEXT:  204e0 00000000 00000000 04000000 00000004

 .data
 .global appdata
 .type appdata, %object
 .size appdata, 8
appdata: .xword 8

// CHECK: Contents of section .got:
/// rodata (shlib.so) RW (default) size 8
// CHECK-NEXT:  220600 00000000 00000000 08000000 00000002
/// data (shlib.so) RW (default) size 8
// CHECK-NEXT:  220610 00000000 00000000 08000000 00000002
/// appdata 0x23000 rw size 8
// CHECK-NEXT:  220620 60062300 00000000 08000000 00000002
/// from_app 230622 exec size 4
// CHECK-NEXT:  220630 69042100 00000000 04000000 00000004
/// func2 (shlib.so) exec size 4
// CHECK-NEXT:  220640 00000000 00000000 04000000 00000004
/// _start 210431 exec size 4
// CHECK-NEXT:  220650 31042100 00000000 08000000 00000004

// CHECK-PIE: Contents of section .got:
/// rodata (shlib.so) RW (default) size 8
// CHECK-PIE-NEXT:  20600 00000000 00000000 08000000 00000002
/// data (shlib.so) RW (default) size 8
// CHECK-PIE-NEXT:  20610 00000000 00000000 08000000 00000002
/// appdata 0x30660 rw size 8
// CHECK-PIE-NEXT:  20620 60060300 00000000 08000000 00000002
/// from_app 14069 exec size 4
// CHECK-PIE-NEXT:  20630 69040100 00000000 04000000 00000004
/// func2 (shlib.so) exec size 4
// CHECK-PIE-NEXT:  20640 00000000 00000000 04000000 00000004
/// _start 10431 exec size 4
// CHECK-PIE-NEXT:  20650 31040100 00000000 08000000 00000004

// CHECK: Contents of section .data:
// CHECK-NEXT:  230660 08000000 00000000

// CHECK-PIE: Contents of section .data:
// CHECK-PIE-NEXT:  30660 08000000 00000000

// CHECK: Contents of section .got.plt:
// CHECK-NEXT:  230670 00000000 00000000 00000000 00000000
// CHECK-NEXT:  230680 00000000 00000000 00000000 00000000
// CHECK-NEXT:  230690 00000000 00000000 00000000 00000000

/// .got.plt[3] should be initialized to point to the PLT Header (00210470)
// CHECK-NEXT:  2306a0 71042100 00000000 00000000 00000000

// CHECK-PIE: Contents of section .got.plt:
// CHECK-PIE-NEXT:  30670 00000000 00000000 00000000 00000000
// CHECK-PIE-NEXT:  30680 00000000 00000000 00000000 00000000
// CHECK-PIE-NEXT:  30690 00000000 00000000 00000000 00000000

/// .got.plt[3] should be initialized to point to the PLT Header (00010470)
// CHECK-PIE-NEXT:  306a0 71040100 00000000 00000000 00000000

// CHECK: 0000000000210430 <_start>:
// CHECK-NEXT:   210430:        bl      0x210490 <rodata+0x210490>
// CHECK-NEXT:   210434:        adrp    c0, #0x10000
// CHECK-NEXT:   210438:        ldr     c0, [c0, #0x600]
// CHECK-NEXT:   21043c:        adrp    c1, #0x10000
// CHECK-NEXT:   210440:        ldr     c1, [c1, #0x610]
// CHECK-NEXT:   210444:        adrp    c2, #0x10000
// CHECK-NEXT:   210448:        ldr     c2, [c2, #0x620]
// CHECK-NEXT:   21044c:        adrp    c3, #0x10000
// CHECK-NEXT:   210450:        ldr     c3, [c3, #0x630]
// CHECK-NEXT:   210454:        adrp    c4, #0x10000
// CHECK-NEXT:   210458:        ldr     c4, [c4, #0x640]
// CHECK-NEXT:   21045c:        adrp    c5, #0x10000
// CHECK-NEXT:   210460:        ldr     c5, [c5, #0x650]
// CHECK-NEXT:   210464:        ret

// CHECK: 0000000000210468 <from_app>:
// CHECK-NEXT:   210468:        ret

/// Check that the PLT header points to .got.plt[2] (230690)
// CHECK: 0000000000210470 <.plt>:
// CHECK-NEXT:   210470:        stp     c16, c30, [csp, #-0x20]!
// CHECK-NEXT:   210474:        adrp    c16, #0x20000
// CHECK-NEXT:   210478:        ldr     c17, [c16, #0x690]
// CHECK-NEXT:   21047c:        add     c16, c16, #0x690
// CHECK-NEXT:   210480:        br      c17
// CHECK-NEXT:   210484:        nop
// CHECK-NEXT:   210488:        nop
// CHECK-NEXT:   21048c:        nop

/// Check that the next PLT entry (.plt[3]) points to .got.plt[3] (2306a0)
// CHECK-NEXT:   210490:        adrp    c16, #0x20000
// CHECK-NEXT:   210494:        add     c16, c16, #0x6a0
// CHECK-NEXT:   210498:        ldr     c17, [c16, #0x0]
// CHECK-NEXT:   21049c:        br      c17

// CHECK-PIE: 0000000000010430 <_start>:
// CHECK-PIE-NEXT:    10430:            bl      0x10490 <rodata+0x10490>
// CHECK-PIE-NEXT:    10434:            adrp    c0, #0x10000
// CHECK-PIE-NEXT:    10438:            ldr     c0, [c0, #0x600]
// CHECK-PIE-NEXT:    1043c:            adrp    c1, #0x10000
// CHECK-PIE-NEXT:    10440:            ldr     c1, [c1, #0x610]
// CHECK-PIE-NEXT:    10444:            adrp    c2, #0x10000
// CHECK-PIE-NEXT:    10448:            ldr     c2, [c2, #0x620]
// CHECK-PIE-NEXT:    1044c:            adrp    c3, #0x10000
// CHECK-PIE-NEXT:    10450:            ldr     c3, [c3, #0x630]
// CHECK-PIE-NEXT:    10454:            adrp    c4, #0x10000
// CHECK-PIE-NEXT:    10458:            ldr     c4, [c4, #0x640]
// CHECK-PIE-NEXT:    1045c:            adrp    c5, #0x10000
// CHECK-PIE-NEXT:    10460:            ldr     c5, [c5, #0x650]
// CHECK-PIE-NEXT:    10464:            ret

// CHECK-PIE: 0000000000010468 <from_app>:
// CHECK-PIE-NEXT:    10468:            ret

/// Check that the PLT header points to .got.plt[2] (30690)
// CHECK-PIE: 0000000000010470 <.plt>:
// CHECK-PIE-NEXT:    10470:            stp     c16, c30, [csp, #-0x20]!
// CHECK-PIE-NEXT:    10474:            adrp    c16, #0x20000
// CHECK-PIE-NEXT:    10478:            ldr     c17, [c16, #0x690]
// CHECK-PIE-NEXT:    1047c:            add     c16, c16, #0x690
// CHECK-PIE-NEXT:    10480:            br      c17
// CHECK-PIE-NEXT:    10484:            nop
// CHECK-PIE-NEXT:    10488:            nop
// CHECK-PIE-NEXT:    1048c:            nop

/// Check that the next PLT entry (.plt[3]) points to .got.plt[3] (306a0)
// CHECK-PIE-NEXT:    10490:            adrp    c16, #0x20000
// CHECK-PIE-NEXT:    10494:            add     c16, c16, #0x6a0
// CHECK-PIE-NEXT:    10498:            ldr     c17, [c16, #0x0]
// CHECK-PIE-NEXT:    1049c:            br      c17

// RELS: Relocations [
// RELS-NEXT:   Section (5) .rela.dyn {
/// .capinit appdata
// RELS-NEXT:     0x2204C0 R_MORELLO_RELATIVE - 0x0
/// .got appdata
// RELS-NEXT:     0x220620 R_MORELLO_RELATIVE - 0x0
/// _start
// RELS-NEXT:     0x220650 R_MORELLO_RELATIVE - 0x0
/// .capinit from_app (strictly speaking don't need symbol here)
// RELS-NEXT:     0x2204D0 R_MORELLO_RELATIVE from_app 0x0
/// .got from_app (strictly speaking don't need symbol here)
// RELS-NEXT:     0x220630 R_MORELLO_RELATIVE from_app 0x0
/// .capinit data
// RELS-NEXT:     0x2204B0 R_MORELLO_CAPINIT data 0x0
/// .got data
// RELS-NEXT:     0x220610 R_MORELLO_GLOB_DAT data 0x0
/// .capinit func2
// RELS-NEXT:     0x2204E0 R_MORELLO_CAPINIT func2 0x0
/// .got func2
// RELS-NEXT:     0x220640 R_MORELLO_GLOB_DAT func2 0x0
/// .capinit rodata
// RELS-NEXT:     0x2204A0 R_MORELLO_CAPINIT rodata 0x0
/// .got rodata
// RELS-NEXT:     0x220600 R_MORELLO_GLOB_DAT rodata 0x0
// RELS-NEXT:   }
// RELS-NEXT:   Section (6) .rela.plt {
// RELS-NEXT:     0x2306A0 R_MORELLO_JUMP_SLOT func 0x0

// RELS-PIE: Relocations [
// RELS-PIE-NEXT:   Section (5) .rela.dyn {
/// .capinit appdata
// RELS-PIE-NEXT:     0x204C0 R_MORELLO_RELATIVE - 0x0
/// .got appdata
// RELS-PIE-NEXT:     0x20620 R_MORELLO_RELATIVE - 0x0
/// _start
// RELS-PIE-NEXT:     0x20650 R_MORELLO_RELATIVE - 0x0
/// .capinit from_app (strictly speaking don't need symbol here)
// RELS-PIE-NEXT:     0x204D0 R_MORELLO_RELATIVE from_app 0x0
/// .got from_app (strictly speaking don't need symbol here)
// RELS-PIE-NEXT:     0x20630 R_MORELLO_RELATIVE from_app 0x0
/// .capinit data
// RELS-PIE-NEXT:     0x204B0 R_MORELLO_CAPINIT data 0x0
/// .got data
// RELS-PIE-NEXT:     0x20610 R_MORELLO_GLOB_DAT data 0x0
/// .capinit func2
// RELS-PIE-NEXT:     0x204E0 R_MORELLO_CAPINIT func2 0x0
/// .got func2
// RELS-PIE-NEXT:     0x20640 R_MORELLO_GLOB_DAT func2 0x0
/// .capinit rodata
// RELS-PIE-NEXT:     0x204A0 R_MORELLO_CAPINIT rodata 0x0
/// .got rodata
// RELS-PIE-NEXT:     0x20600 R_MORELLO_GLOB_DAT rodata 0x0
// RELS-PIE-NEXT:   }
// RELS-PIE-NEXT:   Section (6) .rela.plt {
// RELS-PIE-NEXT:     0x306A0 R_MORELLO_JUMP_SLOT func 0x0
