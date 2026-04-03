; DO NOT EDIT -- This file was generated from test/CodeGen/CHERI-Generic/Inputs/atomic-rmw-cap-ptr-arg.ll
; Reported as https://git.morello-project.org/morello/llvm-project/-/issues/35
; UNSUPPORTED: true
; LLVM ERROR: Cannot select: t5: c128,ch = AtomicSwap<(load store monotonic 16 on %ir.ptr, addrspace 200)> t0, t2, t4
;   t2: c128,ch = CopyFromReg t0, Register:c128 %0
;     t1: c128 = Register %0
;   t4: c128,ch = CopyFromReg t0, Register:c128 %1
;     t3: c128 = Register %1
; In function: atomic_cap_ptr_xchg_relaxed

; Check that we can generate sensible code for atomic operations using capability pointers on capabilities
; See https://github.com/CTSRD-CHERI/llvm-project/issues/470
; RUN: llc -mtriple=aarch64 --relocation-model=pic -target-abi purecap -mattr=+morello,+c64 %s -o - | FileCheck %s --check-prefix=PURECAP
; RUN: llc -mtriple=aarch64 --relocation-model=pic -target-abi aapcs -mattr=+morello,-c64 %s -o - | FileCheck %s --check-prefix=HYBRID

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
