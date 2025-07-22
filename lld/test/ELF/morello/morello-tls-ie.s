# REQUIRES: aarch64
# RUN: llvm-mc -filetype=obj -triple=aarch64-unknown-freebsd %p/Inputs/aarch64-tls-ie.s -mattr=+morello,+c64 -target-abi purecap -o %tdso.o
# RUN: llvm-mc -filetype=obj -triple=aarch64-unknown-freebsd %s -mattr=+morello,+c64 -target-abi purecap -o %tmain.o
# RUN: ld.lld -shared -soname=tdso.so %tdso.o -o %tdso.so
# RUN: ld.lld --hash-style=sysv %tmain.o %tdso.so -o %tout
# RUN: llvm-objdump -d --no-show-raw-insn --no-print-imm-hex %tout | FileCheck %s
# RUN: llvm-readobj -S -r %tout | FileCheck -check-prefix=RELOC %s

# RELOC:      Section {
# RELOC:        Index:
# RELOC:        Name: .got
# RELOC-NEXT:   Type: SHT_PROGBITS
# RELOC-NEXT:   Flags [
# RELOC-NEXT:     SHF_ALLOC
# RELOC-NEXT:     SHF_WRITE
# RELOC-NEXT:   ]
# RELOC-NEXT:   Address: 0x2203C0
# RELOC-NEXT:   Offset: 0x3C0
# RELOC-NEXT:   Size: 64
# RELOC-NEXT:   Link: 0
# RELOC-NEXT:   Info: 0
# RELOC-NEXT:   AddressAlignment: 16
# RELOC-NEXT:   EntrySize: 0
# RELOC-NEXT: }
# RELOC:      Relocations [
# RELOC-NEXT:  Section ({{.*}}) .rela.dyn {
# RELOC-NEXT:    0x2203C0 R_MORELLO_TLS_TPREL128 foo 0x0
# RELOC-NEXT:    0x2203D0 R_MORELLO_TLS_TPREL128 bar 0x0
# RELOC-NEXT:  }
# RELOC-NEXT:]

## Page(0x2203c0) - Page(0x2102f8) = 0x10000 = 65536
## 0x2203c0 & 0xfff = 0x3c0 = 960
## Page(0x2203d0) - Page(0x210304) = 0x10000 = 65536
## 0x2203d0 & 0xfff = 0x3d0 = 976

# CHECK:     <_start>:
# CHECK-NEXT: 2102f8: adrp c0, 0x220000 <_start+0xfd08>
# CHECK-NEXT: 2102fc: add  c0, c0, #960
# CHECK-NEXT: 210300: ldp  x0, x1, [c0]
# CHECK-NEXT: 210304: adrp c0, 0x220000 <_start+0xfd08>
# CHECK-NEXT: 210308: add  c0, c0, #976
# CHECK-NEXT: 21030c: ldp  x0, x1, [c0]


.globl _start
_start:
 adrp c0, :gottprel:foo
 add c0, c0, #:gottprel_lo12:foo
 ldp x0, x1, [c0]

 adrp c0, :gottprel:bar
 add c0, c0, #:gottprel_lo12:bar
 ldp x0, x1, [c0]
