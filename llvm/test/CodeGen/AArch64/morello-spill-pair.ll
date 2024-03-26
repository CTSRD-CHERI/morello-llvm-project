; RUN: llc -march=aarch64 -mattr=+morello,+c64 -mcpu=rainier -target-abi purecap %s -o - | \
; RUN:   FileCheck --check-prefix=CHECK-ASM %s
; RUN: llc -march=aarch64 -mattr=+morello,+c64 -mcpu=rainier -target-abi purecap %s -filetype=obj -o - | \
; RUN:   llvm-objdump --no-leading-addr --no-show-raw-insn -S --mcpu=rainier - | \
; RUN:   FileCheck --check-prefix=CHECK-OBJ %s

; Spilling an X pair to the stack was faulting because we were using
; the A64 opcode (STPXi).
define linkonce_odr hidden i128 @foo(i128 addrspace(200) *%in, i128 %in2, i128 %in3) addrspace(200) {
entry:
  br label %loop
loop:
  %0 = cmpxchg i128 addrspace(200)* %in, i128 %in2, i128 %in3 monotonic monotonic, align 16
  %1 = extractvalue { i128, i1 } %0, 0
  %2 = extractvalue { i128, i1 } %0, 1
  br i1 %2, label %done, label %loop
done:
  call void asm sideeffect "", "~{c0},~{c1},~{c2},~{c3},~{c4},~{c5},~{c6},~{c7},~{c8},~{c9},~{c10},~{c11},~{c12},~{c13},~{c14},~{c15},~{c16},~{c17},~{c18},~{c19},~{c20},~{c21},~{c22},~{c23},~{c24},~{c25},~{c26},~{c27},~{c28},~{cfp},~{clr}"()
  ret i128 %1
}

; CHECK-ASM-LABEL: foo:
; CHECK-ASM: stp	x6, x7, [csp]                   // 16-byte Folded Spill

; CHECK-OBJ-LABEL: <foo>:
; CHECK-OBJ: stp	x6, x7, [csp]
