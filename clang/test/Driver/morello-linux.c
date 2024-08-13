// RUN: %clang -no-canonical-prefixes %s -### -o %t.o 2>&1 \
// RUN:     -rtlib=compiler-rt \
// RUN:     -resource-dir=%S/Inputs/resource_dir_with_per_target_subdir \
// RUN:     --target=aarch64-unknown-linux-gnu_purecap \
// RUN:     -march=morello \
// RUN:     --gcc-toolchain="" \
// RUN:     --sysroot=%S/Inputs/basic_linux_tree \
// RUN:   | FileCheck --check-prefix=CHECK-AARCH64 %s
// CHECK-AARCH64: "-target-abi" "purecap"
// CHECK-AARCH64: "-resource-dir" "[[RESOURCE_DIR:[^"]+]]"
// CHECK-AARCH64: "{{.*}}ld{{(.exe)?}}" "--sysroot=[[SYSROOT:[^"]+]]"
// CHECK-AARCH64-NOT: "--be8"
// CHECK-AARCH64: "-EL"
// CHECK-AARCH64: "-m" "aarch64linux"
// CHECK-AARCH64: "[[RESOURCE_DIR]]{{/|\\\\}}lib{{/|\\\\}}aarch64-unknown-linux-gnu_purecap{{/|\\\\}}libclang_rt.builtins.a"

// RUN: %clang %s -### -o %t.o 2>&1 \
// RUN:     -rtlib=compiler-rt \
// RUN:     -resource-dir=%S/Inputs/resource_dir_with_per_target_subdir \
// RUN:     -march=morello \
// RUN:     --target=aarch64-unknown-linux-musl_purecap \
// RUN:   | FileCheck --check-prefix=CHECK-MUSL-AARCH64 %s
// CHECK-MUSL-AARCH64: "-target-abi" "purecap"
// CHECK-MUSL-AARCH64: "-resource-dir" "[[RESOURCE_DIR:[^"]+]]"
// CHECK-MUSL-AARCH64:    "-dynamic-linker" "/lib/ld-musl-aarch64_purecap.so.1"
// CHECK-MUSL-AARCH64: "[[RESOURCE_DIR]]{{/|\\\\}}lib{{/|\\\\}}aarch64-unknown-linux-musl_purecap{{/|\\\\}}libclang_rt.builtins.a"

// RUN: %clang -no-canonical-prefixes %s -### -o %t.o 2>&1 \
// RUN:     -march=morello \
// RUN:     --target=aarch64-linux-gnu_purecap -rtlib=platform \
// RUN:     --gcc-toolchain="" \
// RUN:     --sysroot=%S/Inputs/debian_multiarch_tree \
// RUN:   | FileCheck --check-prefix=CHECK-DEBIAN-AARCH64 %s
// CHECK-DEBIAN-AARCH64: "-target-abi" "purecap"
// CHECK-DEBIAN-AARCH64: "{{.*}}ld{{(.exe)?}}" "--sysroot=[[SYSROOT:[^"]+]]"
// CHECK-DEBIAN-AARCH64: "-dynamic-linker" "/lib/ld-linux-aarch64_purecap.so.1"
// CHECK-DEBIAN-AARCH64: "-L[[SYSROOT]]/usr/lib/gcc/aarch64-linux-gnu_purecap/4.5"
// CHECK-DEBIAN-AARCH64: "-L[[SYSROOT]]/lib/aarch64-linux-gnu_purecap"
// CHECK-DEBIAN-AARCH64: "-L[[SYSROOT]]/usr/lib/aarch64-linux-gnu_purecap"
// CHECK-DEBIAN-AARCH64: "-L[[SYSROOT]]/lib"
// CHECK-DEBIAN-AARCH64: "-L[[SYSROOT]]/usr/lib"

// RUN: %clang -no-canonical-prefixes %s -### -o %t.o 2>&1 \
// RUN:     -march=morello \
// RUN:     --target=aarch64-linux-gnu_purecap -rtlib=platform \
// RUN:     --gcc-toolchain="" \
// RUN:     --sysroot=%S/Inputs/linux-purecap-tree \
// RUN:   | FileCheck --check-prefix=CHECK-PURECAP-TRIPLE-AARCH64 %s
// CHECK-PURECAP-TRIPLE-AARCH64: "-target-abi" "purecap"
// CHECK-PURECAP-TRIPLE-AARCH64: "{{.*}}ld{{(.exe)?}}" "--sysroot=[[SYSROOT:[^"]+]]"
// CHECK-PURECAP-TRIPLE-AARCH64: "-dynamic-linker" "/lib/ld-linux-aarch64_purecap.so.1"
// CHECK-PURECAP-TRIPLE-AARCH64: "-L[[SYSROOT]]/usr/lib/gcc/aarch64-unknown-linux-gnu_purecap/4.6.0/purecap/c64"
// CHECK-PURECAP-TRIPLE-AARCH64: "-L[[SYSROOT]]/usr/lib/gcc/aarch64-unknown-linux-gnu_purecap/4.6.0/../../../../lib64c"
// CHECK-PURECAP-TRIPLE-AARCH64: "-L[[SYSROOT]]/usr/lib/../lib64c"
// CHECK-PURECAP-TRIPLE-AARCH64: "-L[[SYSROOT]]/lib"
// CHECK-PURECAP-TRIPLE-AARCH64: "-L[[SYSROOT]]/usr/lib"

// RUN: %clang -no-canonical-prefixes %s -### -o %t.o 2>&1 \
// RUN:     -march=morello \
// RUN:     --target=aarch64-linux-gnu -rtlib=platform \
// RUN:     --gcc-toolchain="" \
// RUN:     --sysroot=%S/Inputs/linux-purecap-tree \
// RUN:   | FileCheck --check-prefix=CHECK-HYBRID-AARCH64 %s
// CHECK-HYBRID-AARCH64: "{{.*}}ld{{(.exe)?}}" "--sysroot=[[SYSROOT:[^"]+]]"
// CHECK-HYBRID-AARCH64: "-dynamic-linker" "/lib/ld-linux-aarch64.so.1"
// CHECK-HYBRID-AARCH64: "-L[[SYSROOT]]/usr/lib/gcc/aarch64-unknown-linux-gnu/4.6.0"
// CHECK-HYBRID-AARCH64: "-L[[SYSROOT]]/usr/lib/gcc/aarch64-unknown-linux-gnu/4.6.0/../../../../lib64"
// CHECK-HYBRID-AARCH64: "-L[[SYSROOT]]/usr/lib/../lib64"
// CHECK-HYBRID-AARCH64: "-L[[SYSROOT]]/lib"
// CHECK-HYBRID-AARCH64: "-L[[SYSROOT]]/usr/lib"

// RUN: %clang -no-canonical-prefixes %s -### -o %t.o 2>&1 \
// RUN:     -march=morello -mabi=purecap \
// RUN:     --target=aarch64-linux-gnu -rtlib=platform \
// RUN:     --gcc-toolchain="" \
// RUN:     --sysroot=%S/Inputs/linux-purecap-tree \
// RUN:   | FileCheck --check-prefix=CHECK-PURECAP-AARCH64 %s
// CHECK-PURECAP-AARCH64: "-target-abi" "purecap"
// CHECK-PURECAP-AARCH64: "{{.*}}ld{{(.exe)?}}" "--sysroot=[[SYSROOT:[^"]+]]"
// CHECK-PURECAP-AARCH64: "-dynamic-linker" "/lib/ld-linux-aarch64_purecap.so.1"
// CHECK-PURECAP-AARCH64: "-L[[SYSROOT]]/usr/lib/gcc/aarch64-unknown-linux-gnu/4.6.0/purecap/c64"
// CHECK-PURECAP-AARCH64: "-L[[SYSROOT]]/usr/lib/gcc/aarch64-unknown-linux-gnu/4.6.0/../../../../lib64c"
// CHECK-PURECAP-AARCH64: "-L[[SYSROOT]]/usr/lib/../lib64c"
// CHECK-PURECAP-AARCH64: "-L[[SYSROOT]]/lib"
// CHECK-PURECAP-AARCH64: "-L[[SYSROOT]]/usr/lib"
