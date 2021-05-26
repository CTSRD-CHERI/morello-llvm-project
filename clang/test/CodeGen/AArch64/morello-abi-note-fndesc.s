# REQUIRES: aarch64-registered-target
# RUN: %clang -target aarch64-none-elf -march=morello+c64 -mabi=purecap-desc %s -c -o - | llvm-readelf --notes | FileCheck %s


# CHECK: Displaying notes found in: .note.cheri
# CHECK-NEXT:  Owner                Data size 	Description
# CHECK-NEXT:  CHERI                0x00000004	Unknown note type: (0x00000000)
# CHECK-NEXT:   description data: 02 00 00 00

