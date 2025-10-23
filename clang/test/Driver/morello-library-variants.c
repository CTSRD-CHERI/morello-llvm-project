// RUN: %clang -### -target aarch64-none-elf %s 2>&1 | FileCheck -check-prefix=VARIANT-A64 %s
// RUN: %clang -### -target aarch64-none-elf -march=morello %s 2>&1 | FileCheck -check-prefix=VARIANT-A64C %s
// RUN: %clang -### -target aarch64-none-elf -march=morello -mabi=purecap %s 2>&1 | FileCheck -check-prefix=VARIANT-C64-PURECAP %s

// VARIANT-A64: "{{.*}}/aarch64-none-elf/lib/{{.*}}"
// VARIANT-A64C: "{{.*}}/aarch64-none-elf+morello+a64c/lib/{{.*}}"
// VARIANT-C64-PURECAP: "{{.*}}/aarch64-none-elf+morello+c64+purecap/lib/{{.*}}"
