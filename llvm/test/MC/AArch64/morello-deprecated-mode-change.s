# RUN: llvm-mc -triple aarch64-none-elf %s -aarch64-warn-on-deprecated-arch
# RUN: llvm-mc -triple aarch64-none-elf %s -aarch64-warn-on-deprecated-arch 2> %t.log | FileCheck %s
# RUN: FileCheck %s --check-prefix=CHECK-WARN < %t.log

# Warn on mode change when using the .arch directive.
  .arch morello
  adr x0, .
# CHECK:  adr x0, .

  .arch morello+c64
  adr c1, .

# CHECK-WARN: warning: Using deprecated arch extension c64. Use .code c64 or .code a64 to change the CPU mode instead
# CHECK-WARN-NEXT:  .arch morello+c64
# CHECK-WARN: warning: Changing state with arch directive is deprecated
# CHECK-WARN-NEXT:  .arch morello+c64
# CHECK: .code	c64
# CHECK:  adr c1, .

  .arch morello
  adr x2, .
# CHECK: .code	a64
# CHECK:  adr x2, .
# CHECK-WARN:: warning: Changing state with arch directive is deprecated
# CHECK-WARN-NEXT:  .arch morello

  .arch morello+c64
  adr c3, .
# CHECK-WARN: warning: Using deprecated arch extension c64. Use .code c64 or .code a64 to change the CPU mode instead
# CHECK-WARN-NEXT:  .arch morello+c64
# CHECK-WARN: warning: Changing state with arch directive is deprecated
# CHECK-WARN-NEXT:  .arch morello+c64
# CHECK: .code	c64
# CHECK:  adr c3, .

  .arch armv8.2-a+a64c
  adr x4, .
# CHECK-WARN: warning: Changing state with arch directive is deprecated
# CHECK-WARN-NEXT:  .arch armv8.2-a+a64c
# CHECK: .code	a64
# CHECK:  adr x4, .

# Warn on mode change using the .arch_extension directive.

  .arch_extension c64
  adr c5, .
# CHECK-WARN: warning: Using deprecated arch extension c64. Use .code c64 or .code a64 to change the CPU mode instead
# CHECK-WARN-NEXT:  .arch_extension c64
# CHECK-WARN:  warning: Changing state with arch directive is deprecated
# CHECK-WARN-NEXT:  .arch_extension c64
# CHECK: .code	c64
# CHECK:  adr c5, .

  .arch_extension noc64
  adr x6, .
# CHECK-WARN: warning: Using deprecated arch extension c64. Use .code c64 or .code a64 to change the CPU mode instead
# CHECK-WARN-NEXT:  .arch_extension noc64
# CHECK-WARN:  warning: Changing state with arch directive is deprecated
# CHECK-WARN-NEXT:  .arch_extension noc64
# CHECK: .code	a64
# CHECK:  adr x6, .
