; RUN: llc @PURECAP_HARDFLOAT_ARGS@ < %s -o - | FileCheck %s --check-prefix=PURECAP
@IF-MORELLO@; Morello-hybrid does not reject this intrinsic.
@IF-MORELLO@; Reported as https://git.morello-project.org/morello/llvm-project/-/issues/33
@IFNOT-MORELLO@; RUN: not --crash llc @HYBRID_HARDFLOAT_ARGS@ < %s -o - 2>&1 | FileCheck %s --check-prefix HYBRID-ERROR
; This test checks target-independent CHERI intrinsics that are only available for purecap code

; Currently the only purecap-only intrinsic is llvm.cheri.stack.cap.get()
declare ptr addrspace(200) @llvm.cheri.stack.cap.get()

define ptr addrspace(200) @stack_get() nounwind {
  %cap = call ptr addrspace(200) @llvm.cheri.stack.cap.get()
  ret ptr addrspace(200) %cap
}
; HYBRID-ERROR: LLVM ERROR: Cannot select: intrinsic %llvm.cheri.stack.cap.get
