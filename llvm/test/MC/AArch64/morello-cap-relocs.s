// RUN: llvm-mc -triple=arm64 -mattr=+morello %s -o - -filetype=obj | \
// RUN:     llvm-readelf -r - | FileCheck %s --check-prefix=RELOCS
// RUN: llvm-mc -triple=arm64 -mattr=+morello %s -o - -filetype=obj | \
// RUN:     llvm-readelf -s - | FileCheck %s --check-prefix=SYMS
// RUN: llvm-mc -triple=arm64 -mattr=+morello %s -o - -filetype=obj | \
// RUN:     llvm-objdump -s -j .data - | FileCheck %s --check-prefix=DATA

.data
start:
.chericap sym1
.chericap sym2
end:
.size start, end-start

start1:
.chericap sym1
.chericap sym2
end1:
.size start1, end1-start1

// RELOCS: R_MORELLO_CAPINIT 0000000000000000 sym1 + 0
// RELOCS: R_MORELLO_CAPINIT 0000000000000000 sym2 + 0
// RELOCS: R_MORELLO_CAPINIT 0000000000000000 sym1 + 0
// RELOCS: R_MORELLO_CAPINIT 0000000000000000 sym2 + 0

// SYMS: 32 NOTYPE LOCAL DEFAULT {{.*}} start
// SYMS: 32 NOTYPE LOCAL DEFAULT {{.*}} start1

// DATA:  0000 00000000 00000000 00000000 00000000
// DATA:  0010 00000000 00000000 00000000 00000000
// DATA:  0020 00000000 00000000 00000000 00000000
// DATA:  0030 00000000 00000000 00000000 00000000
