// RUN: %clang -### -target aarch64-none-elf %s 2>&1 | FileCheck -check-prefix=VARIANT-A64 %s

// RUN: %clang -### -target aarch64-none-elf -march=morello %s 2>&1 | FileCheck -check-prefix=VARIANT-HYBRID %s
// RUN: %clang -### -target aarch64-none-elf -march=morello -mabi=purecap %s 2>&1 | FileCheck -check-prefix=VARIANT-PURECAP %s

// RUN: %clang -### -target aarch64-none-elf -march=morello+c64 -mabi=purecap %s 2>&1 | FileCheck -check-prefix=VARIANT-PURECAP %s
// RUN: %clang -### -target aarch64-none-elf -march=morello+c64 %s 2>&1 | FileCheck -check-prefix=VARIANT-HYBRID %s
// RUN: %clang -### -target aarch64-none-elf -march=morello+c64 -mabi=aapcs %s 2>&1 | FileCheck -check-prefix=VARIANT-HYBRID %s

// RUN: %clang -### -target aarch64-none-elf -march=morello %s 2>&1 | FileCheck -check-prefix=VARIANT-HYBRID %s
// RUN: %clang -### -target aarch64-none-elf -march=morello+c64 -mabi=purecap  %s 2>&1 | FileCheck -check-prefix=VARIANT-PURECAP %s

// RUN: %clang -### -target aarch64-none-elf -march=morello+c64 -mabi=purecap-desc  %s 2>&1 | FileCheck -check-prefix=VARIANT-PURECAP-DESC %s
// RUN: %clang -### -target aarch64-none-elf -march=morello -mabi=purecap-desc  %s 2>&1 | FileCheck -check-prefix=VARIANT-PURECAP-DESC %s

// VARIANT-A64: "{{.*}}/aarch64-none-elf/lib/{{.*}}"
// VARIANT-PURECAP: "{{.*}}/aarch64-none-elf+morello+c64+purecap/lib/{{.*}}"
// VARIANT-PURECAP-DESC: "{{.*}}/aarch64-none-elf+morello+c64+purecap+desc/lib/{{.*}}"
// VARIANT-HYBRID: "{{.*}}/aarch64-none-elf+morello+a64c/lib/{{.*}}"
