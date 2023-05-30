// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap %s -o - | llvm-readelf --notes - | FileCheck %s --check-prefixes=CHECK,PCREL
// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap -cheri-cap-table-abi=pcrel %s -o -| llvm-readelf --notes - | FileCheck %s --check-prefixes=CHECK,PCREL
// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap -cheri-cap-table-abi=fn-desc %s -o -| llvm-readelf --notes - | FileCheck %s --check-prefixes=CHECK,FDESC
// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap -cheri-cap-table-abi=plt %s -o -| llvm-readelf --notes - | FileCheck %s --check-prefixes=CHECK,PLT


foo:

// CHECK: Displaying notes found in: .note.cheri
// CHECK-NEXT:  Owner                Data size 	Description
// CHECK-NEXT:  CHERI                0x00000004	Unknown note type: (0x00000000)
// PCREL:   description data: 00 00 00 00
// PLT:   description data: 01 00 00 00
// FDESC:   description data: 02 00 00 00

// RUN: llvm-mc -filetype=obj -triple aarch64 %s -o - | llvm-readelf --notes - | FileCheck %s --allow-empty --check-prefixes=NONOTES
// NONOTES-NOT: Displaying notes found in: .note.cheri
