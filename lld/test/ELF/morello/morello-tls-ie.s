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
# RELOC-NEXT:   Address: 0x2203B0
# RELOC-NEXT:   Offset: 0x3B0
# RELOC-NEXT:   Size: 80
# RELOC-NEXT:   Link: 0
# RELOC-NEXT:   Info: 0
# RELOC-NEXT:   AddressAlignment: 16
# RELOC-NEXT:   EntrySize: 0
# RELOC-NEXT: }
# RELOC:      Relocations [
# RELOC-NEXT:  Section ({{.*}}) .rela.dyn {
# RELOC-NEXT:    0x2203B0 R_MORELLO_TLS_TPREL128 foo 0x0
# RELOC-NEXT:    0x2203C0 R_MORELLO_TLS_TPREL128 bar 0x0
# RELOC-NEXT:  }
# RELOC-NEXT:]

## Page(0x2203b0) - Page(0x2102b0) = 0x10000 = 65536
## 0x2203b0 & 0xfff = 0x3b0 = 944
## Page(0x2203c0) - Page(0x2102bc) = 0x10000 = 65536
## 0x2203c0 & 0xfff = 0x3c0 = 960

# CHECK:     <_start>:
# CHECK-NEXT: 2102e0: adrp c0, 0x220000 <_start+0xfd20>
# CHECK-NEXT: 2102e4: add  c0, c0, #944
# CHECK-NEXT: 2102e8: ldp  x0, x1, [c0]
# CHECK-NEXT: 2102ec: adrp c0, 0x220000 <_start+0xfd20>
# CHECK-NEXT: 2102f0: add  c0, c0, #960
# CHECK-NEXT: 2102f4: ldp  x0, x1, [c0]


.globl _start
_start:
 adrp c0, :gottprel:foo
 add c0, c0, #:gottprel_lo12:foo
 ldp x0, x1, [c0]

 adrp c0, :gottprel:bar
 add c0, c0, #:gottprel_lo12:bar
 ldp x0, x1, [c0]
