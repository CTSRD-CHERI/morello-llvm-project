; DO NOT EDIT -- This file was generated from test/CodeGen/CHERI-Generic/Inputs/atomic-rmw-cap-ptr.ll
; Reported as https://git.morello-project.org/morello/llvm-project/-/issues/34
; UNSUPPORTED: true
; LLVM ERROR: Cannot select: t5: f32,ch = AtomicLoadFAdd<(load store seq_cst 4 on %ir.ptr, addrspace 200)> t0, t2, t4
;   t2: c128,ch = CopyFromReg t0, Register:c128 %0
;     t1: c128 = Register %0
;   t4: f32,ch = CopyFromReg t0, Register:f32 %1
;     t3: f32 = Register %1
; In function: atomic_cap_ptr_fadd

; Check that we can generate sensible code for atomic operations using capability pointers
; https://github.com/CTSRD-CHERI/llvm-project/issues/470
; RUN: llc -mtriple=aarch64 --relocation-model=pic -target-abi purecap -mattr=+morello,+c64 %s -o - | FileCheck %s --check-prefix=PURECAP
; RUN: llc -mtriple=aarch64 --relocation-model=pic -target-abi aapcs -mattr=+morello,-c64 %s -o - | FileCheck %s --check-prefix=HYBRID

define i64 @atomic_cap_ptr_xchg(ptr addrspace(200) %ptr, i64 %val) nounwind {
  %tmp = atomicrmw xchg ptr addrspace(200) %ptr, i64 %val seq_cst
  ret i64 %tmp
}

define i64 @atomic_cap_ptr_add(ptr addrspace(200) %ptr, i64 %val) nounwind {
  %tmp = atomicrmw add ptr addrspace(200) %ptr, i64 %val seq_cst
  ret i64 %tmp
}

define i64 @atomic_cap_ptr_sub(ptr addrspace(200) %ptr, i64 %val) nounwind {
  %tmp = atomicrmw sub ptr addrspace(200) %ptr, i64 %val seq_cst
  ret i64 %tmp
}

define i64 @atomic_cap_ptr_and(ptr addrspace(200) %ptr, i64 %val) nounwind {
  %tmp = atomicrmw and ptr addrspace(200) %ptr, i64 %val seq_cst
  ret i64 %tmp
}

define i64 @atomic_cap_ptr_nand(ptr addrspace(200) %ptr, i64 %val) nounwind {
  %tmp = atomicrmw nand ptr addrspace(200) %ptr, i64 %val seq_cst
  ret i64 %tmp
}

define i64 @atomic_cap_ptr_or(ptr addrspace(200) %ptr, i64 %val) nounwind {
  %tmp = atomicrmw or ptr addrspace(200) %ptr, i64 %val seq_cst
  ret i64 %tmp
}

define i64 @atomic_cap_ptr_xor(ptr addrspace(200) %ptr, i64 %val) nounwind {
  %tmp = atomicrmw xor ptr addrspace(200) %ptr, i64 %val seq_cst
  ret i64 %tmp
}

define i64 @atomic_cap_ptr_max(ptr addrspace(200) %ptr, i64 %val) nounwind {
  %tmp = atomicrmw max ptr addrspace(200) %ptr, i64 %val seq_cst
  ret i64 %tmp
}

define i64 @atomic_cap_ptr_min(ptr addrspace(200) %ptr, i64 %val) nounwind {
  %tmp = atomicrmw min ptr addrspace(200) %ptr, i64 %val seq_cst
  ret i64 %tmp
}

define i64 @atomic_cap_ptr_umax(ptr addrspace(200) %ptr, i64 %val) nounwind {
  %tmp = atomicrmw umax ptr addrspace(200) %ptr, i64 %val seq_cst
  ret i64 %tmp
}

define i64 @atomic_cap_ptr_umin(ptr addrspace(200) %ptr, i64 %val) nounwind {
  %tmp = atomicrmw umin ptr addrspace(200) %ptr, i64 %val seq_cst
  ret i64 %tmp
}

define float @atomic_cap_ptr_fadd(ptr addrspace(200) %ptr, float %val) nounwind {
  %tmp = atomicrmw fadd ptr addrspace(200) %ptr, float %val seq_cst
  ret float %tmp
}

define float @atomic_cap_ptr_fsub(ptr addrspace(200) %ptr, float %val) nounwind {
  %tmp = atomicrmw fsub ptr addrspace(200) %ptr, float %val seq_cst
  ret float %tmp
}
