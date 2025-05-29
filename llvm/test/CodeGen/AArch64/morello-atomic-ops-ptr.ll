; RUN: llc < %s -mtriple=aarch64-none-elf -mattr=+morello -verify-machineinstrs | FileCheck %s

; CHECK-LABEL: test_atomic_load_add_ptr
define ptr addrspace(200) @test_atomic_load_add_ptr(ptr addrspace(200) %offset, ptr %ptr) nounwind {
; CHECK-NOT: dmb
; CHECK: ldaxr c[[OLD:[0-9]+]], [x1]
; CHECK: add x[[RES:[0-9]+]], x[[OLD]], x0
; CHECK: scvalue  c[[NEW:[0-9]+]], c[[OLD]], x[[RES]]
; CHECK: stlxr   w[[TOK:[0-9]+]], c[[NEW]], [x1]
; CHECK: cbnz    w[[TOK]],
   %old = atomicrmw add ptr %ptr, ptr addrspace(200) %offset seq_cst
   ret ptr addrspace(200) %old
}

; CHECK-LABEL: test_atomic_load_sub_ptr
define ptr addrspace(200) @test_atomic_load_sub_ptr(ptr addrspace(200) %offset, ptr %ptr) nounwind {
; CHECK: ldaxr c[[OLD:[0-9]+]], [x1]
; CHECK: sub x[[RES:[0-9]+]], x[[OLD]], x0
; CHECK: scvalue  c[[NEW:[0-9]+]], c[[OLD]], x[[RES]]
; CHECK: stxr   w[[TOK:[0-9]+]], c[[NEW]], [x1]
; CHECK: cbnz    w[[TOK]],
   %old = atomicrmw sub ptr %ptr, ptr addrspace(200) %offset acquire
   ret ptr addrspace(200) %old
}

; CHECK-LABEL: test_atomic_load_and_ptr
define ptr addrspace(200) @test_atomic_load_and_ptr(ptr addrspace(200) %offset, ptr %ptr) nounwind {
; CHECK: ldxr c[[OLD:[0-9]+]], [x1]
; CHECK: and x[[RES:[0-9]+]], x[[OLD]], x0
; CHECK: scvalue  c[[NEW:[0-9]+]], c[[OLD]], x[[RES]]
; CHECK: stlxr   w[[TOK:[0-9]+]], c[[NEW]], [x1]
; CHECK: cbnz    w[[TOK]],

   %old = atomicrmw and ptr %ptr, ptr addrspace(200) %offset release
   ret ptr addrspace(200) %old
}

; CHECK-LABEL: test_atomic_load_or_ptr
define ptr addrspace(200) @test_atomic_load_or_ptr(ptr addrspace(200) %offset, ptr %ptr) nounwind {
; CHECK: ldxr c[[OLD:[0-9]+]], [x1]
; CHECK: orr x[[RES:[0-9]+]], x[[OLD]], x0
; CHECK: scvalue  c[[NEW:[0-9]+]], c[[OLD]], x[[RES]]
; CHECK: stxr   w[[TOK:[0-9]+]], c[[NEW]], [x1]
; CHECK: cbnz    w[[TOK]],

   %old = atomicrmw or ptr %ptr, ptr addrspace(200) %offset monotonic
   ret ptr addrspace(200) %old
}

; CHECK-LABEL: test_atomic_load_xor_ptr
define ptr addrspace(200) @test_atomic_load_xor_ptr(ptr addrspace(200) %offset, ptr %ptr) nounwind {
; CHECK: ldaxr c[[OLD:[0-9]+]], [x1]
; CHECK: eor x[[RES:[0-9]+]], x[[OLD]], x0
; CHECK: scvalue  c[[NEW:[0-9]+]], c[[OLD]], x[[RES]]
; CHECK: stlxr   w[[TOK:[0-9]+]], c[[NEW]], [x1]
; CHECK: cbnz    w[[TOK]],

   %old = atomicrmw xor ptr %ptr, ptr addrspace(200) %offset seq_cst
   ret ptr addrspace(200) %old
}

; CHECK-LABEL: test_atomic_load_xchg_ptr_monotonic
define ptr addrspace(200) @test_atomic_load_xchg_ptr_monotonic(ptr addrspace(200) %offset, ptr %ptr) nounwind {
; CHECK: swp c0, c0, [x1]
   %old = atomicrmw xchg ptr %ptr, ptr addrspace(200) %offset monotonic
   ret ptr addrspace(200) %old
}

; CHECK-LABEL: test_atomic_load_xchg_ptr_acquire
define ptr addrspace(200) @test_atomic_load_xchg_ptr_acquire(ptr addrspace(200) %offset, ptr %ptr) nounwind {
; CHECK: swpa c0, c0, [x1]
   %old = atomicrmw xchg ptr %ptr, ptr addrspace(200) %offset acquire
   ret ptr addrspace(200) %old
}

; CHECK-LABEL: test_atomic_load_xchg_ptr_release
define ptr addrspace(200) @test_atomic_load_xchg_ptr_release(ptr addrspace(200) %offset, ptr %ptr) nounwind {
; CHECK: swpl c0, c0, [x1]
   %old = atomicrmw xchg ptr %ptr, ptr addrspace(200) %offset release
   ret ptr addrspace(200) %old
}

; CHECK-LABEL: test_atomic_load_xchg_ptr_acq_rel
define ptr addrspace(200) @test_atomic_load_xchg_ptr_acq_rel(ptr addrspace(200) %offset, ptr %ptr) nounwind {
; CHECK: swpal c0, c0, [x1]
   %old = atomicrmw xchg ptr %ptr, ptr addrspace(200) %offset acq_rel
   ret ptr addrspace(200) %old
}

; CHECK-LABEL: test_atomic_load_xchg_ptr_seq_cst
define ptr addrspace(200) @test_atomic_load_xchg_ptr_seq_cst(ptr addrspace(200) %offset, ptr %ptr) nounwind {
; CHECK: swpal c0, c0, [x1]
   %old = atomicrmw xchg ptr %ptr, ptr addrspace(200) %offset seq_cst
   ret ptr addrspace(200) %old
}

; CHECK-LABEL: test_atomic_load_min_ptr
define ptr addrspace(200) @test_atomic_load_min_ptr(ptr addrspace(200) %offset, ptr %ptr) nounwind {
; CHECK: ldaxr c[[OLD:[0-9]+]], [x1]
; CHECK: cmp x[[OLD]], x[[TMP:[0-9]+]]
; CHECK: csel c[[RES:[0-9]+]], c[[OLD]], c[[TMP]], le
; CHECK: stxr   w[[TOK:[0-9]+]], c[[RES]], [x1]
; CHECK: cbnz    w[[TOK]],
   %old = atomicrmw min ptr %ptr, ptr addrspace(200) %offset acquire
   ret ptr addrspace(200) %old
}

; CHECK-LABEL: test_atomic_load_max_ptr
define ptr addrspace(200) @test_atomic_load_max_ptr(ptr addrspace(200) %offset, ptr %ptr) nounwind {
; CHECK: ldxr c[[OLD:[0-9]+]], [x1]
; CHECK: cmp x[[OLD]], x[[TMP:[0-9]+]]
; CHECK: csel c[[RES:[0-9]+]], c[[OLD]], c[[TMP]], gt
; CHECK: stlxr   w[[TOK:[0-9]+]], c[[RES]], [x1]
; CHECK: cbnz    w[[TOK]],
   %old = atomicrmw max ptr %ptr, ptr addrspace(200) %offset release
   ret ptr addrspace(200) %old
}

; CHECK-LABEL: test_atomic_load_umin_ptr
define ptr addrspace(200) @test_atomic_load_umin_ptr(ptr addrspace(200) %offset, ptr %ptr) nounwind {
; CHECK: ldxr c[[OLD:[0-9]+]], [x1]
; CHECK: cmp x[[OLD]], x[[TMP:[0-9]+]]
; CHECK: csel c[[RES:[0-9]+]], c[[OLD]], c[[TMP]], ls
; CHECK: stxr   w[[TOK:[0-9]+]], c[[RES]], [x1]
; CHECK: cbnz    w[[TOK]],
   %old = atomicrmw umin ptr %ptr, ptr addrspace(200) %offset monotonic
   ret ptr addrspace(200) %old
}

; CHECK-LABEL: test_atomic_load_umax_ptr
define ptr addrspace(200) @test_atomic_load_umax_ptr(ptr addrspace(200) %offset, ptr %ptr) nounwind {
; CHECK: ldaxr c[[OLD:[0-9]+]], [x1]
; CHECK: cmp x[[OLD]], x[[TMP:[0-9]+]]
; CHECK: csel c[[RES:[0-9]+]], c[[OLD]], c[[TMP]], hi
; CHECK: stxr   w[[TOK:[0-9]+]], c[[RES]], [x1]
; CHECK: cbnz    w[[TOK]],
   %old = atomicrmw umax ptr %ptr, ptr addrspace(200) %offset acquire
   ret ptr addrspace(200) %old
}

; CHECK-LABEL: test_cmpxchg_ptr_acquire
define ptr addrspace(200) @test_cmpxchg_ptr_acquire(ptr addrspace(200) %offset,
         ptr %ptr,
         ptr addrspace(200) %wanted, ptr addrspace(200) %new) nounwind {
   %pair = cmpxchg ptr %ptr, ptr addrspace(200) %wanted, ptr addrspace(200) %new acquire acquire
; CHECK: mov c0, c2
; CHECK: casa c0, c3, [x1]
   %old = extractvalue { ptr addrspace(200), i1 } %pair, 0
   ret ptr addrspace(200) %old
}

; CHECK-LABEL: test_cmpxchg_ptr_monotonic
define ptr addrspace(200) @test_cmpxchg_ptr_monotonic(ptr addrspace(200) %offset,
         ptr %ptr,
         ptr addrspace(200) %wanted, ptr addrspace(200) %new) nounwind {
   %pair = cmpxchg ptr %ptr, ptr addrspace(200) %wanted, ptr addrspace(200) %new monotonic monotonic
; CHECK: mov c0, c2
; CHECK: cas c0, c3, [x1]
   %old = extractvalue { ptr addrspace(200), i1 } %pair, 0
   ret ptr addrspace(200) %old
}

; CHECK-LABEL: test_cmpxchg_ptr_release
define ptr addrspace(200) @test_cmpxchg_ptr_release(ptr addrspace(200) %offset,
         ptr %ptr,
         ptr addrspace(200) %wanted, ptr addrspace(200) %new) nounwind {
   %pair = cmpxchg ptr %ptr, ptr addrspace(200) %wanted, ptr addrspace(200) %new release monotonic
; CHECK: mov c0, c2
; CHECK: casl c0, c3, [x1]
   %old = extractvalue { ptr addrspace(200), i1 } %pair, 0
   ret ptr addrspace(200) %old
}

; CHECK-LABEL: test_cmpxchg_ptr_acq_rel
define ptr addrspace(200) @test_cmpxchg_ptr_acq_rel(ptr addrspace(200) %offset,
         ptr %ptr,
         ptr addrspace(200) %wanted, ptr addrspace(200) %new) nounwind {
   %pair = cmpxchg ptr %ptr, ptr addrspace(200) %wanted, ptr addrspace(200) %new acq_rel monotonic

; CHECK: mov c0, c2
; CHECK: casal c0, c3, [x1]
   %old = extractvalue { ptr addrspace(200), i1 } %pair, 0
   ret ptr addrspace(200) %old
}

; CHECK-LABEL: test_cmpxchg_ptr_seq_cst
define ptr addrspace(200) @test_cmpxchg_ptr_seq_cst(ptr addrspace(200) %offset,
         ptr %ptr,
         ptr addrspace(200) %wanted, ptr addrspace(200) %new) nounwind {
   %pair = cmpxchg ptr %ptr, ptr addrspace(200) %wanted, ptr addrspace(200) %new seq_cst monotonic
; CHECK: mov c0, c2
; CHECK: casal c0, c3, [x1]
   %old = extractvalue { ptr addrspace(200), i1 } %pair, 0
   ret ptr addrspace(200) %old
}

; CHECK-LABEL: test_atomic_load_monotonic_ptr
define ptr addrspace(200) @test_atomic_load_monotonic_ptr(ptr %ptr) nounwind {
; CHECK:  ldr    c0, [x0, #0]
  %val = load atomic ptr addrspace(200), ptr %ptr monotonic, align 16

  ret ptr addrspace(200) %val
}

define void @CapabilityStoreSeqCst(ptr addrspace(200) %v, ptr %addr) nounwind {
; CHECK-LABEL: CapabilityStoreSeqCst:
; CHECK: stlr c0, [x1]
  store atomic volatile ptr addrspace(200) %v, ptr %addr seq_cst, align 16
  ret void
}

define void @CapabilityStoreMonotonic(ptr addrspace(200) %v, ptr %addr) nounwind {
; CHECK-LABEL: CapabilityStoreMonotonic:
; CHECK: str c0, [x1, #0]
  store atomic volatile ptr addrspace(200) %v, ptr %addr monotonic, align 16
  ret void
}

define void @CapabilityStoreRelease(ptr addrspace(200) %v, ptr %addr) nounwind {
; CHECK-LABEL: CapabilityStoreRelease:
; CHECK: stlr c0, [x1]
  store atomic volatile ptr addrspace(200) %v, ptr %addr release, align 16
  ret void
}

define ptr addrspace(200) @CapabilityLoadSeqCst(ptr %addr) nounwind {
; CHECK-LABEL: CapabilityLoadSeqCst:
; CHECK: ldar c0, [x0]
  %val = load atomic volatile ptr addrspace(200), ptr %addr seq_cst, align 16
  ret ptr addrspace(200) %val
}

define ptr addrspace(200) @CapabilityLoadAcq(ptr %addr) nounwind {
; CHECK-LABEL: CapabilityLoadAcq:
; CHECK: ldar c0, [x0]
  %val = load atomic volatile ptr addrspace(200), ptr %addr acquire, align 16
  ret ptr addrspace(200) %val
}
define ptr addrspace(200) @CapabilityLoadMonotonic(ptr %addr) nounwind {
; CHECK-LABEL: CapabilityLoadMonotonic:
; CHECK: ldr c0, [x0, #0]
  %val = load atomic volatile ptr addrspace(200), ptr %addr monotonic, align 16
  ret ptr addrspace(200) %val
}

; CHECK-LABEL: atomic_load_i8_acq_alt:
; CHECK: ldarb
define i8 @atomic_load_i8_acq_alt(ptr addrspace(200) %p) #0 {
   %r = load atomic i8, ptr addrspace(200) %p seq_cst, align 1
   ret i8 %r
}

; CHECK-LABEL: atomic_load_i8_alt:
; CHECK: ldurb
define i8 @atomic_load_i8_alt(ptr addrspace(200) %p) #0 {
   %r = load atomic i8, ptr addrspace(200) %p monotonic, align 1
   ret i8 %r
}

; CHECK-LABEL: atomc_store_i8_rel_alt:
; CHECK: stlrb
define void @atomc_store_i8_rel_alt(ptr addrspace(200) %p) #0 {
   store atomic i8 4, ptr addrspace(200) %p seq_cst, align 1
   ret void
}

; CHECK-LABEL: atomc_store_i8_alt:
; CHECK: sturb
define void @atomc_store_i8_alt(ptr addrspace(200) %p) #0 {
   store atomic i8 4, ptr addrspace(200) %p monotonic, align 1
   ret void
}

; CHECK-LABEL: atomic_load_i16_alt:
; CHECK: ldurh
define i16 @atomic_load_i16_alt(ptr addrspace(200) %p) #0 {
   %r = load atomic i16, ptr addrspace(200) %p monotonic, align 2
   ret i16 %r
}

; CHECK-LABEL: atomic_load_i16_seq_alt:
; CHECK: ldurh
define i16 @atomic_load_i16_seq_alt(ptr addrspace(200) %p) #0 {
   %r = load atomic i16, ptr addrspace(200) %p seq_cst, align 2
   ret i16 %r
}

; CHECK-LABEL: atomic_load_i16_acq_alt:
; CHECK: ldurh
define i16 @atomic_load_i16_acq_alt(ptr addrspace(200) %p) #0 {
   %r = load atomic i16, ptr addrspace(200) %p acquire, align 2
   ret i16 %r
}

; CHECK-LABEL: atomc_store_i16_seq_alt:
; CHECK: dmb     ish
; CHECK: sturh
; CHECK: dmb     ish
define void @atomc_store_i16_seq_alt(ptr addrspace(200) %p) #0 {
   store atomic i16 4, ptr addrspace(200) %p seq_cst, align 2
   ret void
}

; CHECK-LABEL: atomc_store_i16_rel_alt:
; CHECK: dmb     ish
; CHECK: sturh
; CHECK-NOT: dmb
define void @atomc_store_i16_rel_alt(ptr addrspace(200) %p) #0 {
   store atomic i16 4, ptr addrspace(200) %p release, align 2
   ret void
}

; CHECK-LABEL: atomc_store_i16_alt:
; CHECK: sturh
define void @atomc_store_i16_alt(ptr addrspace(200) %p) #0 {
   store atomic i16 4, ptr addrspace(200) %p monotonic, align 2
   ret void
}

; CHECK-LABEL: atomic_load_i32_acq_alt:
; CHECK: ldar w
define i32 @atomic_load_i32_acq_alt(ptr addrspace(200) %p) #0 {
   %r = load atomic i32, ptr addrspace(200) %p seq_cst, align 4
   ret i32 %r
}

; CHECK-LABEL: atomic_load_i32_alt:
; CHECK: ldur w
define i32 @atomic_load_i32_alt(ptr addrspace(200) %p) #0 {
   %r = load atomic i32, ptr addrspace(200) %p monotonic, align 4
   ret i32 %r
}

; CHECK-LABEL: atomc_store_i32_rel_alt:
; CHECK: stlr w
define void @atomc_store_i32_rel_alt(ptr addrspace(200) %p) #0 {
   store atomic i32 4, ptr addrspace(200) %p seq_cst, align 4
   ret void
}

; CHECK-LABEL: atomc_store_i32_alt:
; CHECK: stur w
define void @atomc_store_i32_alt(ptr addrspace(200) %p) #0 {
   store atomic i32 4, ptr addrspace(200) %p monotonic, align 4
   ret void
}

; CHECK-LABEL: atomic_load_i64_alt:
; CHECK: ldur
define i64 @atomic_load_i64_alt(ptr addrspace(200) %p) #0 {
   %r = load atomic i64, ptr addrspace(200) %p monotonic, align 8
   ret i64 %r
}

; CHECK-LABEL: atomic_load_i64_seq_alt:
; CHECK: ldur
; CHECK: dmb ish
define i64 @atomic_load_i64_seq_alt(ptr addrspace(200) %p) #0 {
   %r = load atomic i64, ptr addrspace(200) %p seq_cst, align 8
   ret i64 %r
}

; CHECK-LABEL: atomic_load_i64_acq_alt:
; CHECK: ldur
; CHECK: dmb ishld
define i64 @atomic_load_i64_acq_alt(ptr addrspace(200) %p) #0 {
   %r = load atomic i64, ptr addrspace(200) %p acquire, align 8
   ret i64 %r
}

; CHECK-LABEL: atomc_store_i64_alt:
; CHECK: stur
define void @atomc_store_i64_alt(ptr addrspace(200) %p) #0 {
   store atomic i64 4, ptr addrspace(200) %p monotonic, align 8
   ret void
}

; CHECK-LABEL: atomc_store_i64_rel_alt:
; CHECK: dmb     ish
; CHECK: stur
; CHECK-NOT: dmb     ish
define void @atomc_store_i64_rel_alt(ptr addrspace(200) %p) #0 {
   store atomic i64 4, ptr addrspace(200) %p release, align 8
   ret void
}

; CHECK-LABEL: atomc_store_i64_seq_alt:
; CHECL: dmb     ish
; CHECK: stur
; CHECK: dmb     ish
define void @atomc_store_i64_seq_alt(ptr addrspace(200) %p) #0 {
   store atomic i64 4, ptr addrspace(200) %p seq_cst, align 8
   ret void
}

; CHECK-LABEL: atomic_load_fatptr_acq_alt:
; CHECK: ldar c
define ptr addrspace(200) @atomic_load_fatptr_acq_alt(ptr addrspace(200) %p) #0 {
   %r = load atomic ptr addrspace(200), ptr addrspace(200) %p seq_cst, align 16
   ret ptr addrspace(200) %r
}

; CHECK-LABEL: atomic_load_fatptr_alt:
; CHECK: ldur c
define ptr addrspace(200) @atomic_load_fatptr_alt(ptr addrspace(200) %p) #0 {
   %r = load atomic ptr addrspace(200), ptr addrspace(200) %p monotonic, align 16
   ret ptr addrspace(200) %r
}

; CHECK-LABEL: atomc_store_fatptr_rel_alt:
; CHECK: stlr c
define void @atomc_store_fatptr_rel_alt(ptr addrspace(200) %p) #0 {
   store atomic ptr addrspace(200) null, ptr addrspace(200) %p seq_cst, align 16
   ret void
}

; CHECK-LABEL: atomc_store_fatptr_alt:
; CHECK: stur c
define void @atomc_store_fatptr_alt(ptr addrspace(200) %p) #0 {
   store atomic ptr addrspace(200) null, ptr addrspace(200) %p monotonic, align 16
   ret void
}
