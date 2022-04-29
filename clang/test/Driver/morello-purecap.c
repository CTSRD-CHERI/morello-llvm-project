// RUN: not %clang -c -emit-llvm %s -o - 2>&1 -target aarch64-none-elf -mabi=purecap | FileCheck %s
//
// CHECK: ABI 'purecap' is not supported without feature 'morello or cheriseed'
