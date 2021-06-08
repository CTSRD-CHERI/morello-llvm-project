// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap %s -o -| llvm-readobj -h | FileCheck %s
// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap -cheri-cap-table-abi=pcrel %s -o -| llvm-readobj -h | FileCheck %s
// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap -cheri-cap-table-abi=fn-desc %s -o -| llvm-readobj -h | FileCheck %s
// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap -cheri-cap-table-abi=plt %s -o -| llvm-readobj -h | FileCheck %s
// CHECK: Flags [ (0x10000)

// RUN: llvm-mc -filetype=obj -triple aarch64 %s -o -| llvm-readobj -h | FileCheck --check-prefix=NO-PURECAP %s
// NO-PURECAP: Flags [ (0x0)
