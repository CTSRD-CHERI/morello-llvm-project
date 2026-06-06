// RUN: llvm-mc -triple=aarch64 -mattr=+morello,+c64 -target-abi purecap %s -filetype=obj -o %t.purecap.o
// RUN: llvm-readelf -r %t.purecap.o | FileCheck %s --check-prefix=PURECAP
// RUN: llvm-mc -triple=aarch64 -mattr=+morello,+c64 -target-abi purecap-benchmark %s -filetype=obj -o %t.benchmark.o
// RUN: llvm-readelf -r %t.benchmark.o | FileCheck %s --check-prefix=BENCHMARK

/// Verify that cross-section calls use a relocation against the real symbol
/// rather than a section symbol, even for the purecap benchmark ABI where the
/// symbol is not regarded as Thumb i.e. C64.

.section .text.foo, "ax", %progbits
.type foo, %function
foo:
  ret

.section .text.bar, "ax", %progbits
.type bar, %function
bar:
  bl foo
  b foo

// PURECAP: Relocation section '.rela.text.bar' at offset {{.*}} contains 2 entries:
// PURECAP-NEXT:     Offset             Info             Type               Symbol's Value  Symbol's Name + Addend
// PURECAP-NEXT: 0000000000000000          [[#%x,]] R_MORELLO_CALL26       0000000000000001 foo + 0
// PURECAP-NEXT: 0000000000000004          [[#%x,]] R_MORELLO_JUMP26       0000000000000001 foo + 0

// BENCHMARK: Relocation section '.rela.text.bar' at offset {{.*}} contains 2 entries:
// BENCHMARK-NEXT:     Offset             Info             Type               Symbol's Value  Symbol's Name + Addend
// BENCHMARK-NEXT: 0000000000000000          [[#%x,]] R_AARCH64_CALL26       0000000000000000 foo + 0
// BENCHMARK-NEXT: 0000000000000004          [[#%x,]] R_AARCH64_JUMP26       0000000000000000 foo + 0
