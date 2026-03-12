@IF-MORELLO@; !DO NOT AUTOGEN! Fails with Morello right now:
@IF-MORELLO@; Reported as https://git.morello-project.org/morello/llvm-project/-/issues/35
@IF-MORELLO@; UNSUPPORTED: true
@IF-MORELLO@; LLVM ERROR: Cannot select: t5: c128,ch = AtomicSwap<(load store monotonic 16 on %ir.ptr, addrspace 200)> t0, t2, t4
@IF-MORELLO@;   t2: c128,ch = CopyFromReg t0, Register:c128 %0
@IF-MORELLO@;     t1: c128 = Register %0
@IF-MORELLO@;   t4: c128,ch = CopyFromReg t0, Register:c128 %1
@IF-MORELLO@;     t3: c128 = Register %1
@IF-MORELLO@; In function: atomic_cap_ptr_xchg_relaxed

; Check that we can generate sensible code for atomic operations using capability pointers on capabilities
; See https://github.com/CTSRD-CHERI/llvm-project/issues/470
@IF-RISCV@; RUN: llc @PURECAP_HARDFLOAT_ARGS@ -mattr=+a < %s | FileCheck %s --check-prefixes=PURECAP,PURECAP-ATOMICS --allow-unused-prefixes
@IF-RISCV@; RUN: llc @PURECAP_HARDFLOAT_ARGS@ -mattr=-a < %s | FileCheck %s --check-prefixes=PURECAP,PURECAP-LIBCALLS --allow-unused-prefixes
@IFNOT-RISCV@; RUN: llc @PURECAP_HARDFLOAT_ARGS@ %s -o - | FileCheck %s --check-prefix=PURECAP
@IF-RISCV@; RUN: llc @HYBRID_HARDFLOAT_ARGS@ -mattr=+a < %s | FileCheck %s --check-prefixes=HYBRID,HYBRID-ATOMICS --allow-unused-prefixes
@IF-RISCV@; RUN: llc @HYBRID_HARDFLOAT_ARGS@ -mattr=-a < %s | FileCheck %s --check-prefixes=HYBRID,HYBRID-LIBCALLS --allow-unused-prefixes
@IFNOT-RISCV@; RUN: llc @HYBRID_HARDFLOAT_ARGS@ %s -o - | FileCheck %s --check-prefix=HYBRID

define ptr addrspace(200) @atomic_cap_ptr_xchg_sc(ptr addrspace(200) %ptr, ptr addrspace(200) %val) nounwind {
  %tmp = atomicrmw xchg ptr addrspace(200) %ptr, ptr addrspace(200) %val seq_cst
  ret ptr addrspace(200) %tmp
}

define ptr addrspace(200) @atomic_cap_ptr_xchg_relaxed(ptr addrspace(200) %ptr, ptr addrspace(200) %val) nounwind {
  %tmp = atomicrmw xchg ptr addrspace(200) %ptr, ptr addrspace(200) %val monotonic
  ret ptr addrspace(200) %tmp
}

define ptr addrspace(200) @atomic_cap_ptr_xchg_acquire(ptr addrspace(200) %ptr, ptr addrspace(200) %val) nounwind {
  %tmp = atomicrmw xchg ptr addrspace(200) %ptr, ptr addrspace(200) %val acquire
  ret ptr addrspace(200) %tmp
}

define ptr addrspace(200) @atomic_cap_ptr_xchg_rel(ptr addrspace(200) %ptr, ptr addrspace(200) %val) nounwind {
  %tmp = atomicrmw xchg ptr addrspace(200) %ptr, ptr addrspace(200) %val release
  ret ptr addrspace(200) %tmp
}

define ptr addrspace(200) @atomic_cap_ptr_xchg_acq_rel(ptr addrspace(200) %ptr, ptr addrspace(200) %val) nounwind {
  %tmp = atomicrmw xchg ptr addrspace(200) %ptr, ptr addrspace(200) %val acq_rel
  ret ptr addrspace(200) %tmp
}

; Also check non-ptr xchg:
define ptr addrspace(200) @atomic_cap_ptr_xchg_i32ptr(ptr addrspace(200) %ptr, ptr addrspace(200) %val) nounwind {
  %tmp = atomicrmw xchg ptr addrspace(200) %ptr, ptr addrspace(200) %val acq_rel
  ret ptr addrspace(200) %tmp
}

define ptr addrspace(200) @atomic_cap_ptr_add(ptr addrspace(200) %ptr, ptr addrspace(200) %val) nounwind {
  %tmp = atomicrmw add ptr addrspace(200) %ptr, ptr addrspace(200) %val seq_cst
  ret ptr addrspace(200) %tmp
}

define ptr addrspace(200) @atomic_cap_ptr_sub(ptr addrspace(200) %ptr, ptr addrspace(200) %val) nounwind {
  %tmp = atomicrmw sub ptr addrspace(200) %ptr, ptr addrspace(200) %val seq_cst
  ret ptr addrspace(200) %tmp
}

define ptr addrspace(200) @atomic_cap_ptr_and(ptr addrspace(200) %ptr, ptr addrspace(200) %val) nounwind {
  %tmp = atomicrmw and ptr addrspace(200) %ptr, ptr addrspace(200) %val seq_cst
  ret ptr addrspace(200) %tmp
}

define ptr addrspace(200) @atomic_cap_ptr_nand(ptr addrspace(200) %ptr, ptr addrspace(200) %val) nounwind {
  %tmp = atomicrmw nand ptr addrspace(200) %ptr, ptr addrspace(200) %val seq_cst
  ret ptr addrspace(200) %tmp
}

define ptr addrspace(200) @atomic_cap_ptr_or(ptr addrspace(200) %ptr, ptr addrspace(200) %val) nounwind {
  %tmp = atomicrmw or ptr addrspace(200) %ptr, ptr addrspace(200) %val seq_cst
  ret ptr addrspace(200) %tmp
}

define ptr addrspace(200) @atomic_cap_ptr_xor(ptr addrspace(200) %ptr, ptr addrspace(200) %val) nounwind {
  %tmp = atomicrmw xor ptr addrspace(200) %ptr, ptr addrspace(200) %val seq_cst
  ret ptr addrspace(200) %tmp
}

define ptr addrspace(200) @atomic_cap_ptr_max(ptr addrspace(200) %ptr, ptr addrspace(200) %val) nounwind {
  %tmp = atomicrmw max ptr addrspace(200) %ptr, ptr addrspace(200) %val seq_cst
  ret ptr addrspace(200) %tmp
}

define ptr addrspace(200) @atomic_cap_ptr_min(ptr addrspace(200) %ptr, ptr addrspace(200) %val) nounwind {
  %tmp = atomicrmw min ptr addrspace(200) %ptr, ptr addrspace(200) %val seq_cst
  ret ptr addrspace(200) %tmp
}

define ptr addrspace(200) @atomic_cap_ptr_umax(ptr addrspace(200) %ptr, ptr addrspace(200) %val) nounwind {
  %tmp = atomicrmw umax ptr addrspace(200) %ptr, ptr addrspace(200) %val seq_cst
  ret ptr addrspace(200) %tmp
}

define ptr addrspace(200) @atomic_cap_ptr_umin(ptr addrspace(200) %ptr, ptr addrspace(200) %val) nounwind {
  %tmp = atomicrmw umin ptr addrspace(200) %ptr, ptr addrspace(200) %val seq_cst
  ret ptr addrspace(200) %tmp
}
