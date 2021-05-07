// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64,+morello -target-abi purecap -filetype=obj %s -o %t.o
// RUN: ld.lld --morello-static-caps=elf --morello-c64-plt %t.o -o %t
// RUN: llvm-readobj --relocs --symbols --expand-relocs -x .got.plt %t | FileCheck %s
// RUN: llvm-objdump --triple=arm64 --mattr=+morello,+c64 --no-show-raw-insn --print-imm-hex -d %t | FileCheck %s --check-prefix=DIS

 .data
 .balign 16
hello:
 .string "Hello World"

 .type foo, %object
 .size foo, 16
foo:
 .capinit hello
 .8byte 0
 .8byte 12

.text
.type ifunc STT_GNU_IFUNC
.globl ifunc
ifunc:
 ret
.size ifunc, .-ifunc

.globl _start
_start:
 bl ifunc
 add c2, c2, :lo12:foo
 add c2, c2, :lo12:__rela_iplt_start
 add c2, c2, :lo12:__rela_iplt_end
 add c2, c2, :lo12:__rela_dyn_start
 add c2, c2, :lo12:__rela_dyn_end

// CHECK: Relocations [
// CHECK-NEXT: .rela.dyn {
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Offset: 0x2201EC
// CHECK-NEXT:     Type: R_MORELLO_RELATIVE
// CHECK-NEXT:     Symbol: -
// CHECK-NEXT:     Addend: 0x2201E0
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Offset: 0x220200
// CHECK-NEXT:     Type: R_MORELLO_IRELATIVE
// CHECK-NEXT:     Symbol: -
// CHECK-NEXT:     Addend: 0x2101B1
// CHECK-NEXT:   }
// CHECK-NEXT: }


// CHECK: Symbol {
// CHECK:        Name: foo
// CHECK-NEXT:   Value: 0x2201EC
// CHECK-NEXT:   Size: 16
// CHECK-NEXT:   Binding: Local
// CHECK-NEXT:   Type: Object
// CHECK-NEXT:   Other: 0
// CHECK-NEXT:   Section: .data
// CHECK-NEXT: }
// CHECK-NEXT: Symbol {
// CHECK-NEXT:   Name: hello
// CHECK-NEXT:   Value: 0x2201E0
// CHECK-NEXT:   Size: 0
// CHECK-NEXT:   Binding: Local
// CHECK-NEXT:   Type: None
// CHECK-NEXT:   Other: 0
// CHECK-NEXT:   Section: .data
// CHECK-NEXT: }
// CHECK-NEXT: Symbol {
// CHECK-NEXT:   Name: __rela_dyn_end
// CHECK-NEXT:   Value: 0x200198
// CHECK-NEXT:   Size: 0
// CHECK-NEXT:   Binding: Local
// CHECK-NEXT:   Type: None
// CHECK-NEXT:   Other [
// CHECK-NEXT:     STV_HIDDEN
// CHECK-NEXT:   ]
// CHECK-NEXT:   Section: .rela.dyn
// CHECK-NEXT: }
// CHECK-NEXT: Symbol {
// CHECK-NEXT:   Name: __rela_dyn_start
// CHECK-NEXT:   Value: 0x200180
// CHECK-NEXT:   Size: 0
// CHECK-NEXT:   Binding: Local
// CHECK-NEXT:   Type: None
// CHECK-NEXT:   Other [
// CHECK-NEXT:     STV_HIDDEN
// CHECK-NEXT:   ]
// CHECK-NEXT:   Section: .rela.dyn
// CHECK-NEXT: }
// CHECK-NEXT: Symbol {
// CHECK-NEXT:   Name: __rela_iplt_end
// CHECK-NEXT:   Value: 0x2001B0
// CHECK-NEXT:   Size: 0
// CHECK-NEXT:   Binding: Local
// CHECK-NEXT:   Type: None
// CHECK-NEXT:   Other [
// CHECK-NEXT:     STV_HIDDEN
// CHECK-NEXT:   ]
// CHECK-NEXT:   Section: .rela.dyn
// CHECK-NEXT: }
// CHECK-NEXT: Symbol {
// CHECK-NEXT:   Name: __rela_iplt_start
// CHECK-NEXT:   Value: 0x200198
// CHECK-NEXT:   Size: 0
// CHECK-NEXT:   Binding: Local
// CHECK-NEXT:   Type: None
// CHECK-NEXT:   Other [
// CHECK-NEXT:     STV_HIDDEN
// CHECK-NEXT:   ]
// CHECK-NEXT:   Section: .rela.dyn
// CHECK-NEXT: }
// CHECK-NEXT: Symbol {
// CHECK-NEXT:   Name: _start
// CHECK-NEXT:   Value: 0x2101B4
// CHECK-NEXT:   Size: 0
// CHECK-NEXT:   Binding: Global
// CHECK-NEXT:   Type: None
// CHECK-NEXT:   Other: 0
// CHECK-NEXT:   Section: .text
// CHECK-NEXT: }
// CHECK-NEXT: Symbol {
// CHECK-NEXT:   Name: ifunc
// CHECK-NEXT:   Value: 0x2101B1
// CHECK-NEXT:   Size: 3
// CHECK-NEXT:   Binding: Global
// CHECK-NEXT:   Type: GNU_IFunc
// CHECK-NEXT:   Other: 0
// CHECK-NEXT:   Section: .text
// CHECK-NEXT: }


// CHECK:      Hex dump of section '.got.plt':
// CHECK-NEXT: 0x00220200 b1012100 00000000 03000000 00000004


// DIS: 2101b1 <ifunc>:

// DIS:      2101b4 <_start>:
// DIS-NEXT: 2101b4:  bl 0x2101d0
// DIS-NEXT: 2101b8:  add c2, c2, #0x1ec
// DIS-NEXT: 2101bc:  add c2, c2, #0x198
// DIS-NEXT: 2101c0:  add c2, c2, #0x1b0
// DIS-NEXT: 2101c4:  add c2, c2, #0x180
// DIS-NEXT: 2101c8:  add c2, c2, #0x198

// DIS:      2101d0 <.iplt>:
// DIS-NEXT: 2101d0:  adrp c16, #0x10000
// DIS-NEXT: 2101d4:  add c16, c16, #0x200
// DIS-NEXT: 2101d8:  ldr c17, [c16, #0x0]
// DIS-NEXT: 2101dc:  br c17

