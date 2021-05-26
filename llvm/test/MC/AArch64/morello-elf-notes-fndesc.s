// RUN: llvm-mc -triple aarch64-none-linux-gnu -assemble -filetype=obj \
// RUN:   -mattr=+morello,+c64 -target-abi purecap -cheri-cap-table-abi=fn-desc %s -o - | \
// RUN:  llvm-readelf --notes | FileCheck %s

foo:

// CHECK: Displaying notes found in: .note.cheri
// CHECK-NEXT:  Owner                Data size 	Description
// CHECK-NEXT:  CHERI                0x00000004	Unknown note type: (0x00000000)
// CHECK-NEXT:   description data: 02 00 00 00
