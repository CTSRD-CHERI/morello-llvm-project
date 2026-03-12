@IF-MORELLO@; !DO NOT AUTOGEN! Fails with Morello right now:
@IF-MORELLO@; Reported as https://git.morello-project.org/morello/llvm-project/-/issues/34
@IF-MORELLO@; UNSUPPORTED: true
@IF-MORELLO@; LLVM ERROR: Cannot select: t5: f32,ch = AtomicLoadFAdd<(load store seq_cst 4 on %ir.ptr, addrspace 200)> t0, t2, t4
@IF-MORELLO@;   t2: c128,ch = CopyFromReg t0, Register:c128 %0
@IF-MORELLO@;     t1: c128 = Register %0
@IF-MORELLO@;   t4: f32,ch = CopyFromReg t0, Register:f32 %1
@IF-MORELLO@;     t3: f32 = Register %1
@IF-MORELLO@; In function: atomic_cap_ptr_fadd

; Check that we can generate sensible code for atomic operations using capability pointers
; https://github.com/CTSRD-CHERI/llvm-project/issues/470
@IF-RISCV@; RUN: llc @PURECAP_HARDFLOAT_ARGS@ -mattr=+a < %s | FileCheck %s --check-prefixes=PURECAP,PURECAP-ATOMICS --allow-unused-prefixes
@IF-RISCV@; RUN: llc @PURECAP_HARDFLOAT_ARGS@ -mattr=-a < %s | FileCheck %s --check-prefixes=PURECAP,PURECAP-LIBCALLS --allow-unused-prefixes
@IFNOT-RISCV@; RUN: llc @PURECAP_HARDFLOAT_ARGS@ %s -o - | FileCheck %s --check-prefix=PURECAP
@IF-RISCV@; RUN: llc @HYBRID_HARDFLOAT_ARGS@ -mattr=+a < %s | FileCheck %s --check-prefixes=HYBRID,HYBRID-ATOMICS --allow-unused-prefixes
@IF-RISCV@; RUN: llc @HYBRID_HARDFLOAT_ARGS@ -mattr=-a < %s | FileCheck %s --check-prefixes=HYBRID,HYBRID-LIBCALLS --allow-unused-prefixes
@IFNOT-RISCV@; RUN: llc @HYBRID_HARDFLOAT_ARGS@ %s -o - | FileCheck %s --check-prefix=HYBRID

define iCAPRANGE @atomic_cap_ptr_xchg(ptr addrspace(200) %ptr, iCAPRANGE %val) nounwind {
  %tmp = atomicrmw xchg ptr addrspace(200) %ptr, iCAPRANGE %val seq_cst
  ret iCAPRANGE %tmp
}

define iCAPRANGE @atomic_cap_ptr_add(ptr addrspace(200) %ptr, iCAPRANGE %val) nounwind {
  %tmp = atomicrmw add ptr addrspace(200) %ptr, iCAPRANGE %val seq_cst
  ret iCAPRANGE %tmp
}

define iCAPRANGE @atomic_cap_ptr_sub(ptr addrspace(200) %ptr, iCAPRANGE %val) nounwind {
  %tmp = atomicrmw sub ptr addrspace(200) %ptr, iCAPRANGE %val seq_cst
  ret iCAPRANGE %tmp
}

define iCAPRANGE @atomic_cap_ptr_and(ptr addrspace(200) %ptr, iCAPRANGE %val) nounwind {
  %tmp = atomicrmw and ptr addrspace(200) %ptr, iCAPRANGE %val seq_cst
  ret iCAPRANGE %tmp
}

define iCAPRANGE @atomic_cap_ptr_nand(ptr addrspace(200) %ptr, iCAPRANGE %val) nounwind {
  %tmp = atomicrmw nand ptr addrspace(200) %ptr, iCAPRANGE %val seq_cst
  ret iCAPRANGE %tmp
}

define iCAPRANGE @atomic_cap_ptr_or(ptr addrspace(200) %ptr, iCAPRANGE %val) nounwind {
  %tmp = atomicrmw or ptr addrspace(200) %ptr, iCAPRANGE %val seq_cst
  ret iCAPRANGE %tmp
}

define iCAPRANGE @atomic_cap_ptr_xor(ptr addrspace(200) %ptr, iCAPRANGE %val) nounwind {
  %tmp = atomicrmw xor ptr addrspace(200) %ptr, iCAPRANGE %val seq_cst
  ret iCAPRANGE %tmp
}

define iCAPRANGE @atomic_cap_ptr_max(ptr addrspace(200) %ptr, iCAPRANGE %val) nounwind {
  %tmp = atomicrmw max ptr addrspace(200) %ptr, iCAPRANGE %val seq_cst
  ret iCAPRANGE %tmp
}

define iCAPRANGE @atomic_cap_ptr_min(ptr addrspace(200) %ptr, iCAPRANGE %val) nounwind {
  %tmp = atomicrmw min ptr addrspace(200) %ptr, iCAPRANGE %val seq_cst
  ret iCAPRANGE %tmp
}

define iCAPRANGE @atomic_cap_ptr_umax(ptr addrspace(200) %ptr, iCAPRANGE %val) nounwind {
  %tmp = atomicrmw umax ptr addrspace(200) %ptr, iCAPRANGE %val seq_cst
  ret iCAPRANGE %tmp
}

define iCAPRANGE @atomic_cap_ptr_umin(ptr addrspace(200) %ptr, iCAPRANGE %val) nounwind {
  %tmp = atomicrmw umin ptr addrspace(200) %ptr, iCAPRANGE %val seq_cst
  ret iCAPRANGE %tmp
}

define float @atomic_cap_ptr_fadd(ptr addrspace(200) %ptr, float %val) nounwind {
  %tmp = atomicrmw fadd ptr addrspace(200) %ptr, float %val seq_cst
  ret float %tmp
}

define float @atomic_cap_ptr_fsub(ptr addrspace(200) %ptr, float %val) nounwind {
  %tmp = atomicrmw fsub ptr addrspace(200) %ptr, float %val seq_cst
  ret float %tmp
}
