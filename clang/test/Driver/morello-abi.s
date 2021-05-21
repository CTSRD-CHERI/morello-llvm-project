# RUN: %clang -target aarch64-none-elf -march=morello+c64 -mabi=purecap %s -c -### 2>&1 | FileCheck %s

# Make sure the ABI is passed down to the integrated assembler.
# CHECK: "-target-abi" "purecap"
