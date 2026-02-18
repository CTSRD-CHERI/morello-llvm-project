// REQUIRES: aarch64
// RUN: llvm-mc --triple=aarch64-none-elf -mattr=+c64,+morello -target-abi purecap -filetype=obj %s -o %t.o
// RUN: ld.lld --local-caprelocs=elf --morello-c64-plt %t.o -o %t
// RUN: llvm-readobj --relocs --symbols --expand-relocs -x .got.plt -x .data %t | FileCheck %s
// RUN: llvm-objdump --triple=arm64 --mattr=+morello,+c64 --no-show-raw-insn --print-imm-hex -d %t | FileCheck %s --check-prefix=DIS

 .data
 .balign 16
hello:
 .string "Hello World"
 .size hello, . - hello

 .type foo, %object
 .size foo, 16
foo:
 .chericap hello

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
// CHECK-NEXT:     Offset: 0x220290
// CHECK-NEXT:     Type: R_MORELLO_RELATIVE
// CHECK-NEXT:     Symbol: -
// CHECK-NEXT:     Addend: 0x0
// CHECK-NEXT:   }
// CHECK-NEXT:   Relocation {
// CHECK-NEXT:     Offset: 0x220270
// CHECK-NEXT:     Type: R_MORELLO_IRELATIVE
// CHECK-NEXT:     Symbol: -
// CHECK-NEXT:     Addend: 0x1
// CHECK-NEXT:   }
// CHECK-NEXT: }


// CHECK:      Symbol {
// CHECK:        Name: hello
// CHECK-NEXT:   Value: 0x220280
// CHECK-NEXT:   Size: 12
// CHECK-NEXT:   Binding: Local
// CHECK-NEXT:   Type: None
// CHECK-NEXT:   Other: 0
// CHECK-NEXT:   Section: .data
// CHECK-NEXT: }

// CHECK:      Symbol {
// CHECK:        Name: foo
// CHECK-NEXT:   Value: 0x22028C
// CHECK-NEXT:   Size: 16
// CHECK-NEXT:   Binding: Local
// CHECK-NEXT:   Type: Object
// CHECK-NEXT:   Other: 0
// CHECK-NEXT:   Section: .data
// CHECK-NEXT: }

// CHECK:      Symbol {
// CHECK:        Name: __rela_iplt_start
// CHECK-NEXT:   Value: 0x200228
// CHECK-NEXT:   Size: 48
// CHECK-NEXT:   Binding: Local
// CHECK-NEXT:   Type: None
// CHECK-NEXT:   Other [
// CHECK-NEXT:     STV_HIDDEN
// CHECK-NEXT:   ]
// CHECK-NEXT:   Section: .rela.dyn
// CHECK-NEXT: }

// CHECK:      Symbol {
// CHECK:        Name: __rela_iplt_end
// CHECK-NEXT:   Value: 0x200240
// CHECK-NEXT:   Size: 0
// CHECK-NEXT:   Binding: Local
// CHECK-NEXT:   Type: None
// CHECK-NEXT:   Other [
// CHECK-NEXT:     STV_HIDDEN
// CHECK-NEXT:   ]
// CHECK-NEXT:   Section: .rela.dyn
// CHECK-NEXT: }

// CHECK:      Symbol {
// CHECK:        Name: __rela_dyn_start
// CHECK-NEXT:   Value: 0x200210
// CHECK-NEXT:   Size: 48
// CHECK-NEXT:   Binding: Local
// CHECK-NEXT:   Type: None
// CHECK-NEXT:   Other [
// CHECK-NEXT:     STV_HIDDEN
// CHECK-NEXT:   ]
// CHECK-NEXT:   Section: .rela.dyn
// CHECK-NEXT: }

// CHECK:      Symbol {
// CHECK:        Name: __rela_dyn_end
// CHECK-NEXT:   Value: 0x200228
// CHECK-NEXT:   Size: 0
// CHECK-NEXT:   Binding: Local
// CHECK-NEXT:   Type: None
// CHECK-NEXT:   Other [
// CHECK-NEXT:     STV_HIDDEN
// CHECK-NEXT:   ]
// CHECK-NEXT:   Section: .rela.dyn
// CHECK-NEXT: }

// CHECK:      Symbol {
// CHECK:        Name: ifunc
// CHECK-NEXT:   Value: 0x210241
// CHECK-NEXT:   Size: 3
// CHECK-NEXT:   Binding: Global
// CHECK-NEXT:   Type: GNU_IFunc
// CHECK-NEXT:   Other: 0
// CHECK-NEXT:   Section: .text
// CHECK-NEXT: }

// CHECK:      Symbol {
// CHECK:        Name: _start
// CHECK-NEXT:   Value: 0x210244
// CHECK-NEXT:   Size: 0
// CHECK-NEXT:   Binding: Global
// CHECK-NEXT:   Type: None
// CHECK-NEXT:   Other: 0
// CHECK-NEXT:   Section: .text
// CHECK-NEXT: }

// CHECK:      Hex dump of section '.got.plt':
// CHECK-NEXT: 0x00220270 40022100 00000000 40000100 00000004

// CHECK:      Hex dump of section '.data':
// CHECK-NEXT: 0x00220280 48656c6c 6f20576f 726c6400 00000000 Hello World
// CHECK-NEXT: 0x00220290 80022200 00000000 0c000000 00000002


// DIS: 210241 <ifunc>:

// DIS:      210244 <_start>
// DIS-NEXT: 210244:  bl  0x210260
// DIS-NEXT: 210248:  add c2, c2, #0x28c
// DIS-NEXT: 21024c:  add c2, c2, #0x228
// DIS-NEXT: 210250:  add c2, c2, #0x240
// DIS-NEXT: 210254:  add c2, c2, #0x210
// DIS-NEXT: 210258:  add c2, c2, #0x228

// DIS:      210260 <.iplt>:
// DIS-NEXT: 210260:  adrp c16, 0x220000
// DIS-NEXT: 210264:  add c16, c16, #0x270
// DIS-NEXT: 210268:  ldr c17, [c16, #0x0]
// DIS-NEXT: 21026c:  br c17
