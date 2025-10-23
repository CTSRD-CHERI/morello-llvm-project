// Test that target features selected on morello.

// RUN: %clang -target aarch64-none-elf -march=armv8-a+a64c %s -### 2>&1 \
// RUN:   | FileCheck --check-prefixes=CPU-GENERIC,CHECK-A64C %s --implicit-check-not=-target-feature

// RUN: %clang -target aarch64-none-elf -march=morello %s -### 2>&1 \
// RUN:   | FileCheck --check-prefixes=CPU-GENERIC,CHECK-A64CHYBRID %s --implicit-check-not=-target-feature

// RUN: %clang -target aarch64-none-elf -march=morello -mabi=aapcs %s -### 2>&1 \
// RUN:   | FileCheck --check-prefixes=CPU-GENERIC,CHECK-A64CHYBRID,CHECK-A64CHYBRID-EXPLICIT-ABI %s --implicit-check-not=-target-feature

// RUN: %clang -target aarch64-none-elf -mcpu=rainier %s -### 2>&1 \
// RUN:   | FileCheck --check-prefixes=CPU-RAINIER,CHECK-CPU-RAINIER-NO-MARCH %s --implicit-check-not=-target-feature

// RUN: %clang -target aarch64-none-elf -mcpu=rainier -march=morello+noa64c %s -### 2>&1 \
// RUN:   | FileCheck --check-prefixes=CPU-RAINIER,CHECK-A64 %s --implicit-check-not=-target-feature

// RUN: %clang -target aarch64-none-elf -march=morello -mabi=purecap %s -### 2>&1 \
// RUN:   | FileCheck --check-prefixes=CPU-GENERIC,CHECK-C64PURECAP %s --implicit-check-not=-target-feature

// RUN: %clang -target aarch64-none-elf -march=morello -m16-cap-regs %s -### 2>&1 \
// RUN:   | FileCheck --check-prefixes=CPU-GENERIC,CHECK-16CAPREGS,CHECK-16-ABI-HYBRID %s --implicit-check-not=-target-feature

// RUN: %clang -target aarch64-none-elf -march=morello+c64 -mabi=purecap %s -### 2>&1 \
// RUN:   | FileCheck --check-prefixes=CPU-GENERIC,CHECK-C64PURECAP %s --implicit-check-not=-target-feature

// RUN: %clang -target aarch64-none-elf -march=morello+c64 %s -### 2>&1 \
// RUN:   | FileCheck --check-prefixes=CHECK-C64HYBRID %s --implicit-check-not=-target-feature

// RUN: %clang -target aarch64-none-elf -march=morello+c64 -mabi=aapcs %s -### 2>&1 \
// RUN:   | FileCheck --check-prefixes=CHECK-C64HYBRID %s --implicit-check-not=-target-feature

// RUN: %clang -target aarch64-none-elf -march=morello+c64 -mabi=purecap -m16-cap-regs %s -### 2>&1 \
// RUN:   | FileCheck --check-prefixes=CPU-GENERIC,CHECK-16CAPREGS,CHECK-16-ABI-PURECAP %s --implicit-check-not=-target-feature

// RUN: %clang -target aarch64-none-elf -march=morello+c64 -mabi=purecap %s -### 2>&1 \
// RUN:   | FileCheck --check-prefixes=CPU-GENERIC,CHECK-32CAPREGS %s --implicit-check-not=-target-feature

// RUN: %clang -target aarch64-none-elf -march=morello -mabi=purecap-benchmark %s -### 2>&1 \
// RUN:   | FileCheck --check-prefixes=CPU-GENERIC,CHECK-BENCHMARK %s --implicit-check-not=-target-feature

// CPU-GENERIC: "-target-cpu" "generic"
// CPU-RAINIER: "-target-cpu" "rainier"

// CHECK-A64C-NOT: "-target-abi" "purecap"
// CHECK-A64C: "-target-feature" "+neon" "-target-feature" "+v8a" "-target-feature" "-c64" "-target-feature" "+morello" "-target-abi" "aapcs"
// CHECK-A64C-NOT: "-target-abi" "purecap"


// CHECK-A64CHYBRID-NOT: "-target-abi" "purecap"
// CHECK-A64CHYBRID: "-target-feature" "+neon" "-target-feature" "+morello" "-target-feature" "+v8.2a"
// CHECK-A64CHYBRID-EXPLICIT-ABI: "-target-feature" "-c64"
// CHECK-A64CHYBRID-SAME:  "-target-abi" "aapcs"
// CHECK-A64CHYBRID-NOT: "-target-abi" "purecap"

// CHECK-CPU-RAINIER-NO-MARCH: "-target-feature" "+v8.2a" "-target-feature" "+aes" "-target-feature" "+crc" "-target-feature" "+dotprod" "-target-feature" "+fp-armv8" "-target-feature" "+fullfp16" "-target-feature" "+lse" "-target-feature" "+spe" "-target-feature" "+ras" "-target-feature" "+rcpc" "-target-feature" "+rdm" "-target-feature" "+sha2" "-target-feature" "+neon" "-target-feature" "+ssbs" "-target-feature" "+morello"


// CHECK-A64-NOT: "-target-abi" "purecap"
// CHECK-A64: "-target-feature" "+neon" "-target-feature" "+v8.2a" "-target-feature" "-morello" "-target-abi" "aapcs"
// CHECK-A64-NOT: "-target-abi" "purecap"

// CHECK-C64PURECAP: "-target-feature" "+neon"
// CHECK-C64PURECAP-DAG: "-target-feature" "+morello"
// CHECK-C64PURECAP-DAG: "-target-feature" "+v8.2a"
// CHECK-C64PURECAP-SAME: "-target-feature" "+c64"
// CHECK-C64PURECAP-SAME: "-target-abi" "purecap"

// CHECK-C64HYBRID: clang: warning: Using c64 in the arch string is deprecated. The CPU mode should be inferred from the ABI. [-Wdeprecated]
// CHECK-C64HYBRID: clang: error: Cannot use 'C64' encoding mode with 'aapcs' ABI
// CHECK-C64HYBRID: "-target-cpu" "generic" "-target-feature" "+neon"
// CHECK-C64HYBRID-DAG: "-target-feature" "+morello"
// CHECK-C64HYBRID-DAG: "-target-feature" "+v8.2a"
// CHECK-C64HYBRID-SAME: "-target-feature" "+c64"
// CHECK-C64HYBRID-SAME: "-target-abi" "aapcs"

// CHECK-16CAPREGS: "-target-feature" "+neon"
// CHECK-16CAPREGS-DAG: "-target-feature" "+morello"
// CHECK-16CAPREGS-DAG: "-target-feature" "+v8.2a"
// CHECK-16-ABI-PURECAP-SAME: "-target-feature" "+c64"
// CHECK-16CAPREGS-SAME: "-target-feature" "+use-16-cap-regs"
// CHECK-16-ABI-PURECAP-SAME: "-target-abi" "purecap"
// CHECK-16-ABI-HYBRID-SAME: "-target-abi" "aapcs"

// CHECK-32CAPREGS-NOT: "use-16-cap-regs"
// CHECK-32CAPREGS: "-target-feature" "+neon" "-target-feature" "+v8.2a" "-target-feature" "+morello" "-target-feature" "+c64" "-target-abi" "purecap"

// CHECK-BENCHMARK: "-target-feature" "+neon" "-target-feature" "+morello" "-target-feature" "+v8.2a" "-target-feature" "+c64"
// CHECK-BENCHMARK-SAME: "-target-abi" "purecap-benchmark"
