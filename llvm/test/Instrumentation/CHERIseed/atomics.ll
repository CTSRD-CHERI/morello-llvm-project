; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------
; Atomic loads

; CHECK-LABEL: @load_atomic_i8
define void @load_atomic_i8(i8* %p, i8 addrspace(200)* %c) {
; CHECK-NEXT:  %v1 = load atomic i8, i8* %p monotonic, align 1
  %v1 = load atomic i8, i8* %p monotonic, align 1
; CHECK-NEXT:  %1 = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 1, i32 1)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i8*
; CHECK-NEXT:  %v2 = load atomic i8, i8* %2 monotonic, align 1
  %v2 = load atomic i8, i8 addrspace(200)* %c monotonic, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @load_atomic_p0
define void @load_atomic_p0(i8** %p, i8* addrspace(200)* %c) {
; CHECK-NEXT:  %v1 = load atomic i8*, i8** %p acquire, align 8
  %v1 = load atomic i8*, i8** %p acquire, align 8
; CHECK-NEXT:  %1 = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 8, i32 1)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i8**
; CHECK-NEXT:  %v2 = load atomic i8*, i8** %2 acquire, align 8
  %v2 = load atomic i8*, i8* addrspace(200)* %c acquire, align 8
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @load_atomic_p200
define void @load_atomic_p200(i8 addrspace(200)* addrspace(200)* %c) {
; CHECK:  %v1 = tail call %__cheriseed_cap_t* @__cheriseed_load_cap_atomic(%__cheriseed_cap_t* %1, %__cheriseed_cap_t* %c, i8 0)
  %v1 = load atomic i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %c monotonic, align 16
; CHECK:  %v2 = tail call %__cheriseed_cap_t* @__cheriseed_load_cap_atomic(%__cheriseed_cap_t* %2, %__cheriseed_cap_t* %c, i8 0)
  %v2 = load atomic i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %c unordered, align 16
; CHECK:  %v3 = tail call %__cheriseed_cap_t* @__cheriseed_load_cap_atomic(%__cheriseed_cap_t* %3, %__cheriseed_cap_t* %c, i8 2)
  %v3 = load atomic i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %c acquire, align 16
; CHECK:  %v4 = tail call %__cheriseed_cap_t* @__cheriseed_load_cap_atomic(%__cheriseed_cap_t* %4, %__cheriseed_cap_t* %c, i8 5)
  %v4 = load atomic i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %c seq_cst, align 16
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @load_atomic_p200_hybrid
define void @load_atomic_p200_hybrid(i8 addrspace(200)** %c) {
; CHECK:  %v1 = tail call %__cheriseed_cap_t* @__cheriseed_load_cap_hybrid_atomic(%__cheriseed_cap_t* %1, %__cheriseed_cap_t* %c, i8 0)
  %v1 = load atomic i8 addrspace(200)*, i8 addrspace(200)** %c monotonic, align 16
; CHECK:  %v2 = tail call %__cheriseed_cap_t* @__cheriseed_load_cap_hybrid_atomic(%__cheriseed_cap_t* %2, %__cheriseed_cap_t* %c, i8 0)
  %v2 = load atomic i8 addrspace(200)*, i8 addrspace(200)** %c unordered, align 16
; CHECK:  %v3 = tail call %__cheriseed_cap_t* @__cheriseed_load_cap_hybrid_atomic(%__cheriseed_cap_t* %3, %__cheriseed_cap_t* %c, i8 2)
  %v3 = load atomic i8 addrspace(200)*, i8 addrspace(200)** %c acquire, align 16
; CHECK:  %v4 = tail call %__cheriseed_cap_t* @__cheriseed_load_cap_hybrid_atomic(%__cheriseed_cap_t* %4, %__cheriseed_cap_t* %c, i8 5)
  %v4 = load atomic i8 addrspace(200)*, i8 addrspace(200)** %c seq_cst, align 16
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; Atomic stores

; CHECK-LABEL: @store_atomic_i8
define void @store_atomic_i8(i8* %p, i8 addrspace(200)* %c, i8 %v) {
; CHECK-NEXT:  store atomic i8 %v, i8* %p monotonic, align 1
  store atomic i8 %v, i8* %p monotonic, align 1
; CHECK-NEXT:  %1 = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 1, i32 2)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i8*
; CHECK-NEXT:  store atomic i8 %v, i8* %2 monotonic, align 1
  store atomic i8 %v, i8 addrspace(200)* %c monotonic, align 1
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @store_atomic_p0
define void @store_atomic_p0(i8** %p, i8* addrspace(200)* %c) {
; CHECK-NEXT:  store atomic i8* null, i8** %p monotonic, align 8
  store atomic i8* null, i8** %p monotonic, align 8
; CHECK-NEXT:  %1 = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 8, i32 2)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i8**
; CHECK-NEXT:  store atomic i8* null, i8** %2 monotonic, align 8
  store atomic i8* null, i8* addrspace(200)* %c monotonic, align 8
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @store_atomic_p200
define void @store_atomic_p200(i8 addrspace(200)* addrspace(200)* %c) {
; CHECK:       call void @__cheriseed_store_cap_atomic(%__cheriseed_cap_t* %c, %__cheriseed_cap_t* null, i8 0)
  store atomic i8 addrspace(200)* null, i8 addrspace(200)* addrspace(200)* %c monotonic, align 16
; CHECK:       call void @__cheriseed_store_cap_atomic(%__cheriseed_cap_t* %c, %__cheriseed_cap_t* null, i8 0)
  store atomic i8 addrspace(200)* null, i8 addrspace(200)* addrspace(200)* %c unordered, align 16
; CHECK:       call void @__cheriseed_store_cap_atomic(%__cheriseed_cap_t* %c, %__cheriseed_cap_t* null, i8 3)
  store atomic i8 addrspace(200)* null, i8 addrspace(200)* addrspace(200)* %c release, align 16
; CHECK:       call void @__cheriseed_store_cap_atomic(%__cheriseed_cap_t* %c, %__cheriseed_cap_t* null, i8 5)
  store atomic i8 addrspace(200)* null, i8 addrspace(200)* addrspace(200)* %c seq_cst, align 16
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @store_atomic_p200_hybrid
define void @store_atomic_p200_hybrid(i8 addrspace(200)** %c) {
; CHECK:       call void @__cheriseed_store_cap_hybrid_atomic(%__cheriseed_cap_t* %c, %__cheriseed_cap_t* null, i8 0)
  store atomic i8 addrspace(200)* null, i8 addrspace(200)** %c monotonic, align 8
; CHECK:       call void @__cheriseed_store_cap_hybrid_atomic(%__cheriseed_cap_t* %c, %__cheriseed_cap_t* null, i8 0)
  store atomic i8 addrspace(200)* null, i8 addrspace(200)** %c unordered, align 8
; CHECK:       call void @__cheriseed_store_cap_hybrid_atomic(%__cheriseed_cap_t* %c, %__cheriseed_cap_t* null, i8 3)
  store atomic i8 addrspace(200)* null, i8 addrspace(200)** %c release, align 8
; CHECK:       call void @__cheriseed_store_cap_hybrid_atomic(%__cheriseed_cap_t* %c, %__cheriseed_cap_t* null, i8 5)
  store atomic i8 addrspace(200)* null, i8 addrspace(200)** %c seq_cst, align 8
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; Atomic read-modify-writes

; CHECK-LABEL: @atomicrmw_i8
define void @atomicrmw_i8(i8 addrspace(200)* %c) {
; CHECK-NEXT:  %1 = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 1, i32 3)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i8*
; CHECK-NEXT:  %3 = atomicrmw xchg i8* %2, i8 1 acquire
  %1 = atomicrmw xchg i8 addrspace(200)* %c, i8 1 acquire
; CHECK-NEXT:  %4 = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 1, i32 3)
; CHECK-NEXT:  %5 = inttoptr i64 %4 to i8*
; CHECK-NEXT:  %6 = atomicrmw add i8* %5, i8 1 monotonic
  %2 = atomicrmw add i8 addrspace(200)* %c, i8 1 monotonic
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @atomicrmw_p0
define void @atomicrmw_p0(i8* addrspace(200)* %c, i8* %p) {
; CHECK-NEXT:  %1 = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 8, i32 3)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i8**
; CHECK-NEXT:  %3 = atomicrmw xchg i8** %2, i8* %p acquire
  %1 = atomicrmw xchg i8* addrspace(200)* %c, i8* %p acquire
; CHECK-NEXT:  %4 = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 8, i32 3)
; CHECK-NEXT:  %5 = inttoptr i64 %4 to i8**
; CHECK-NEXT:  %6 = atomicrmw add i8** %5, i8* %p monotonic
  %2 = atomicrmw add i8* addrspace(200)* %c, i8* %p monotonic
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @atomicrmw_p200
define void @atomicrmw_p200(i8* addrspace(200)* addrspace(200)* %c, i8* addrspace(200)* %p) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_rmw_cap(
; CHECK-SAME:     %__cheriseed_cap_t* %c, %__cheriseed_cap_t* %p, %__cheriseed_cap_t* %1, i8 0, i8 2)
  %1 = atomicrmw xchg i8* addrspace(200)* addrspace(200)* %c, i8* addrspace(200)* %p acquire
; CHECK-NEXT:  %4 = tail call %__cheriseed_cap_t* @__cheriseed_rmw_cap(
; CHECK-SAME:     %__cheriseed_cap_t* %c, %__cheriseed_cap_t* %p, %__cheriseed_cap_t* %2, i8 1, i8 0)
  %2 = atomicrmw add i8* addrspace(200)* addrspace(200)* %c, i8* addrspace(200)* %p monotonic
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @atomicrmw_p200_hybrid
define void @atomicrmw_p200_hybrid(i8* addrspace(200)** %c, i8* addrspace(200)* %p) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %2 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_rmw_cap_hybrid(
; CHECK-SAME:     %__cheriseed_cap_t* %c, %__cheriseed_cap_t* %p, %__cheriseed_cap_t* %1, i8 0, i8 2)
  %1 = atomicrmw xchg i8* addrspace(200)** %c, i8* addrspace(200)* %p acquire
; CHECK-NEXT:  %4 = tail call %__cheriseed_cap_t* @__cheriseed_rmw_cap_hybrid(
; CHECK-SAME:     %__cheriseed_cap_t* %c, %__cheriseed_cap_t* %p, %__cheriseed_cap_t* %2, i8 1, i8 0)
  %2 = atomicrmw add i8* addrspace(200)** %c, i8* addrspace(200)* %p monotonic
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; Atomic compare-exchanges

; CHECK-LABEL: @cmpxchg_i8
define void @cmpxchg_i8(i8* %p, i8 addrspace(200)* %c) {
; CHECK-NEXT:  %v1 = cmpxchg i8* %p, i8 0, i8 1 acquire monotonic
  %v1 = cmpxchg i8* %p, i8 0, i8 1 acquire monotonic
; CHECK-NEXT:  %1 = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 1, i32 3)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i8*
; CHECK-NEXT:  %v2 = cmpxchg i8* %2, i8 0, i8 1 seq_cst seq_cst
  %v2 = cmpxchg i8 addrspace(200)* %c, i8 0, i8 1 seq_cst seq_cst
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cmpxchg_p0
define void @cmpxchg_p0(i8** %p, i8* addrspace(200)* %c, i8* %n) {
; CHECK-NEXT:  %v1 = cmpxchg i8** %p, i8* null, i8* %n acquire monotonic
  %v1 = cmpxchg i8** %p, i8* null, i8* %n acquire monotonic
; CHECK-NEXT:  %1 = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %c, i64 8, i32 3)
; CHECK-NEXT:  %2 = inttoptr i64 %1 to i8*
; CHECK-NEXT:  %v2 = cmpxchg i8** %2, i8* null, i8* %n seq_cst seq_cst
  %v2 = cmpxchg i8* addrspace(200)* %c, i8* null, i8* %n seq_cst seq_cst
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cmpxchg_p200
define void @cmpxchg_p200(i8 addrspace(200)* addrspace(200)* %c, i8 addrspace(200)* %n) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %v1 = tail call { %__cheriseed_cap_t*, i1 } @__cheriseed_cmpxchg_cap(
; CHECK-SAME:     %__cheriseed_cap_t* %c, %__cheriseed_cap_t* null, %__cheriseed_cap_t* %n,
; CHECK-SAME:     %__cheriseed_cap_t* %1, i8 0, i8 0)
  %v1 = cmpxchg i8 addrspace(200)* addrspace(200)* %c, i8 addrspace(200)* null, i8 addrspace(200)* %n monotonic monotonic
; CHECK-NEXT:  %v2 = extractvalue { %__cheriseed_cap_t*, i1 } %v1, 0
  %v2 = extractvalue { i8 addrspace(200)*, i1 } %v1, 0
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @cmpxchg_p200_hybrid
define void @cmpxchg_p200_hybrid(i8 addrspace(200)** %p, i8 addrspace(200)* %n) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point" = bitcast i8 0 to i8
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %v1 = tail call { %__cheriseed_cap_t*, i1 } @__cheriseed_cmpxchg_cap_hybrid(
; CHECK-SAME:     %__cheriseed_cap_t* %p, %__cheriseed_cap_t* null, %__cheriseed_cap_t* %n,
; CHECK-SAME:     %__cheriseed_cap_t* %1, i8 5, i8 5)
  %v1 = cmpxchg i8 addrspace(200)** %p, i8 addrspace(200)* null, i8 addrspace(200)* %n seq_cst seq_cst
; CHECK-NEXT:  %v2 = extractvalue { %__cheriseed_cap_t*, i1 } %v1, 0
  %v2 = extractvalue { i8 addrspace(200)*, i1 } %v1, 0
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; Regression test

%regression.s = type { [4 x i64] }
@regression.g = external addrspace(200) global %regression.s

; CHECK-LABEL: @regression
define void @regression() {
; Make sure this mapping works with globals too.
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %2 = tail call %__cheriseed_cap_t* @regression.g()
; CHECK-NEXT:  %3 = tail call %__cheriseed_cap_t* @__cheriseed_copy_cap_with_offset(%__cheriseed_cap_t* %1, %__cheriseed_cap_t* %2, i64 16)
; CHECK-NEXT:  %4 = tail call i64 @__cheriseed_check_access(%__cheriseed_cap_t* %3, i64 8, i32 2)
; CHECK-NEXT:  %5 = inttoptr i64 %4 to i64*
; CHECK-NEXT:  store atomic i64 0, i64* %5 release, align 8
  store atomic i64 0, i64 addrspace(200)* bitcast (i64 addrspace(200)* getelementptr inbounds (%regression.s, %regression.s addrspace(200)* @regression.g, i64 0, i32 0, i64 2) to i64 addrspace(200)*) release, align 8
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
