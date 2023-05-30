# REQUIRES: aarch64
# RUN: llvm-mc -filetype=obj -triple=aarch64-unknown-freebsd -mattr=+morello,+c64 -target-abi purecap %p/Inputs/aarch64-tstbr14-reloc.s -o %t1
# RUN: llvm-mc -filetype=obj -triple=aarch64-unknown-freebsd -mattr=+morello,+c64 -target-abi purecap %s -o %t2
# RUN: ld.lld %t1 %t2 -o %t
# RUN: llvm-objdump --mattr=+morello -d --no-show-raw-insn %t | FileCheck %s
# RUN: ld.lld -shared %t1 %t2 -o %t3
# RUN: llvm-objdump --mattr=+morello -d --no-show-raw-insn %t3 | FileCheck --check-prefix=DSO %s
# RUN: llvm-readobj -S -r %t3 | FileCheck -check-prefix=DSOREL %s

# CHECK:      <_foo>:
# CHECK-NEXT:  210190: nop
# CHECK-NEXT:  210194: nop
# CHECK-NEXT:  210198: nop
# CHECK-NEXT:  21019c: nop
# CHECK:      <_bar>:
# CHECK-NEXT:  2101a0: nop
# CHECK-NEXT:  2101a4: nop
# CHECK-NEXT:  2101a8: nop
# CHECK:      <_start>:
# CHECK-NEXT:  2101ac: tbnz w3, #15, 0x210190 <_foo>
# CHECK-NEXT:  2101b0: tbnz w3, #15, 0x2101a0 <_bar>
# CHECK-NEXT:  2101b4: tbz x6, #45, 0x210190 <_foo>
# CHECK-NEXT:  2101b8: tbz x6, #45, 0x2101a0 <_bar>

#DSOREL:      Section {
#DSOREL:        Index:
#DSOREL:        Name: .got.plt
#DSOREL-NEXT:   Type: SHT_PROGBITS
#DSOREL-NEXT:   Flags [
#DSOREL-NEXT:     SHF_ALLOC
#DSOREL-NEXT:     SHF_WRITE
#DSOREL-NEXT:   ]
#DSOREL-NEXT:   Address: 0x30490
#DSOREL-NEXT:   Offset:
#DSOREL-NEXT:   Size:
#DSOREL-NEXT:   Link: 0
#DSOREL-NEXT:   Info: 0
#DSOREL-NEXT:   AddressAlignment: 16
#DSOREL-NEXT:   EntrySize: 0
#DSOREL-NEXT:  }
#DSOREL:      Relocations [
#DSOREL-NEXT:  Section ({{.*}}) .rela.plt {
#DSOREL-NEXT:    0x304C0 R_MORELLO_JUMP_SLOT _foo 0x0
#DSOREL-NEXT:    0x304D0 R_MORELLO_JUMP_SLOT _bar 0x0
#DSOREL-NEXT:  }
#DSOREL-NEXT:]

#DSO:      Disassembly of section .text:
#DSO-EMPTY:
#DSO-NEXT: <_foo>:
#DSO-NEXT:  10368: nop
#DSO-NEXT:  1036c: nop
#DSO-NEXT:  10370: nop
#DSO-NEXT:  10374: nop
#DSO:      <_bar>:
#DSO-NEXT:  10378: nop
#DSO-NEXT:  1037c: nop
#DSO-NEXT:  10380: nop
#DSO:      <_start>:
#DSO-NEXT:  10384: tbnz w3, #15, 0x103c0
#DSO-NEXT:  10388: tbnz w3, #15, 0x103d0
#DSO-NEXT:  1038c: tbz x6, #45, 0x103c0
#DSO-NEXT:  10390: tbz x6, #45, 0x103d0
#DSO-EMPTY:
#DSO-NEXT: Disassembly of section .plt:
#DSO-EMPTY:
#DSO-NEXT: <.plt>:
#DSO-NEXT:  103a0: stp c16, c30, [csp, #-32]!
#DSO-NEXT:  103a4: adrp c16, 0x30000 <.plt+0x84>
#DSO-NEXT:  103a8: ldr c17, [c16, #1200]
#DSO-NEXT:  103ac: add c16, c16, #1200
#DSO-NEXT:  103b0: br c17
#DSO-NEXT:  103b4: nop
#DSO-NEXT:  103b8: nop
#DSO-NEXT:  103bc: nop
#DSO-NEXT:  103c0: adrp c16, 0x30000 <.plt+0xa0>
#DSO-NEXT:  103c4: add c16, c16, #1216
#DSO-NEXT:  103c8: ldr c17, [c16, #0]
#DSO-NEXT:  103cc: br c17
#DSO-NEXT:  103d0: adrp c16, 0x30000 <.plt+0xb0>
#DSO-NEXT:  103d4: add c16, c16, #1232
#DSO-NEXT:  103d8: ldr c17, [c16, #0]
#DSO-NEXT:  103dc: br c17

.globl _start
_start:
 tbnz w3, #15, _foo
 tbnz w3, #15, _bar
 tbz x6, #45, _foo
 tbz x6, #45, _bar
