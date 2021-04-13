; RUN: not llc -mtriple=arm64 -mattr=+morello -o - %s 2>&1 | FileCheck %s

; CHECK: couldn't allocate input reg for constraint 'C'
define void @foo(i64 %in) {
  call void asm sideeffect "", "C,~{memory}"(i64 %in)
  ret void
}
