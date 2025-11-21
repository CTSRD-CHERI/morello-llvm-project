# REQUIRES: aarch64

# RUN: llvm-mc -filetype=obj -triple=aarch64 -mattr=+morello,+c64 -target-abi purecap %s -o %t.o
# RUN: ld.lld %t.o -o %t
# RUN: llvm-readobj -r --cap-relocs %t | FileCheck --check-prefix=RELOC %s
# RUN: llvm-readobj -x .data %t | FileCheck --check-prefix=HEX %s

# RELOC:      Relocations [
# RELOC-NEXT: ]
# RELOC-NEXT: CHERI Capability Relocations [
# RELOC-NEXT: ]

# HEX-LABEL: section '.data':
# HEX-NEXT:  [[#%x,]] 00000000 00000000 00000000 00000000
# HEX-NEXT:  [[#%x,]] 03000000 00000000 00000000 00000000

.weak undef_weak

.data
.chericap undef_weak
.chericap undef_weak + 3
