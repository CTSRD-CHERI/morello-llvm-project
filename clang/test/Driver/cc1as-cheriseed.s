// Make sure the -cheriseed is passed down to cc1as.
//
// RUN: %clang -target aarch64-unknown-linux -fsanitize=cheriseed -### -c \
// RUN:   -integrated-as %s 2>&1 | FileCheck %s
// RUN: %clang -target x86_64-unknown-linux -fsanitize=cheriseed -### -c \
// RUN:   -integrated-as %s 2>&1 | FileCheck %s
//
// CHECK: "-cc1as"
// CHECK: "-cheriseed"
