// RUN: %clang --target=aarch64-unknown-linux -fsanitize=cheriseed -c -o - %s \
// RUN:   | llvm-readelf -h - | FileCheck %s
// RUN: %clang --target=aarch64-unknown-linux -fsanitize=cheriseed -mabi=purecap -c -o - %s \
// RUN:   | llvm-readelf -h - | FileCheck %s

// Make sure ELF has no markings from Morello code paths.
// CHECK: Flags: 0x0
