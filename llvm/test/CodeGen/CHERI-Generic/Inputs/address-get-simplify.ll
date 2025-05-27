; RUN: opt < %s @HYBRID_HARDFLOAT_ARGS@ -passes=instsimplify -S | FileCheck %s
; RUN: opt < %s @PURECAP_HARDFLOAT_ARGS@ -passes=instsimplify -S | FileCheck %s

target datalayout = "@PURECAP_DATALAYOUT@"

; Derived from various existing ptrtoint tests.

declare iCAPRANGE @llvm.cheri.cap.address.get.iCAPRANGE(i8 addrspace(200)*)

define i1 @or_cmps_ptr_eq_zero_with_mask_commute1(iCAPRANGE addrspace(200)* %p, iCAPRANGE %y) {
  %isnull = icmp eq iCAPRANGE addrspace(200)* %p, null
  %p1 = bitcast iCAPRANGE addrspace(200)* %p to i8 addrspace(200)*
  %x = call iCAPRANGE @llvm.cheri.cap.address.get.iCAPRANGE(i8 addrspace(200)* %p1)
  %somebits = and iCAPRANGE %x, %y
  %somebits_are_zero = icmp eq iCAPRANGE %somebits, 0
  %r = or i1 %somebits_are_zero, %isnull
  ret i1 %r
}

define i1 @or_cmps_ptr_eq_zero_with_mask_commute3(i4 addrspace(200)* %p, i4 %y) {
  %isnull = icmp eq i4 addrspace(200)* %p, null
  %p1 = bitcast i4 addrspace(200)* %p to i8 addrspace(200)*
  %xaddr = call iCAPRANGE @llvm.cheri.cap.address.get.iCAPRANGE(i8 addrspace(200)* %p1)
  %x = trunc iCAPRANGE %xaddr to i4
  %somebits = and i4 %y, %x
  %somebits_are_zero = icmp eq i4 %somebits, 0
  %r = or i1 %somebits_are_zero, %isnull
  ret i1 %r
}

define i1 @and_cmps_ptr_eq_zero_with_mask_commute2(i4 addrspace(200)* %p, i4 %y) {
  %isnotnull = icmp ne i4 addrspace(200)* %p, null
  %p1 = bitcast i4 addrspace(200)* %p to i8 addrspace(200)*
  %xaddr = call iCAPRANGE @llvm.cheri.cap.address.get.iCAPRANGE(i8 addrspace(200)* %p1)
  %x = trunc iCAPRANGE %xaddr to i4
  %somebits = and i4 %x, %y
  %somebits_are_not_zero = icmp ne i4 %somebits, 0
  %r = and i1 %isnotnull, %somebits_are_not_zero
  ret i1 %r
}

define i1 @and_cmps_ptr_eq_zero_with_mask_commute4(iCAPRANGE addrspace(200)* %p, iCAPRANGE %y) {
  %isnotnull = icmp ne iCAPRANGE addrspace(200)* %p, null
  %p1 = bitcast iCAPRANGE addrspace(200)* %p to i8 addrspace(200)*
  %x = call iCAPRANGE @llvm.cheri.cap.address.get.iCAPRANGE(i8 addrspace(200)* %p1)
  %somebits = and iCAPRANGE %y, %x
  %somebits_are_not_zero = icmp ne iCAPRANGE %somebits, 0
  %r = and i1 %isnotnull, %somebits_are_not_zero
  ret i1 %r
}

define i8 addrspace(200)* @D98611_1(i8 addrspace(200)* %c1, iCAPRANGE %offset) {
  %c2 = getelementptr inbounds i8, i8 addrspace(200)* %c1, iCAPRANGE %offset
  %ptrtoint1 = call iCAPRANGE @llvm.cheri.cap.address.get.iCAPRANGE(i8 addrspace(200)* %c1)
  %ptrtoint2 = call iCAPRANGE @llvm.cheri.cap.address.get.iCAPRANGE(i8 addrspace(200)* %c2)
  %sub = sub iCAPRANGE %ptrtoint2, %ptrtoint1
  %gep = getelementptr inbounds i8, i8 addrspace(200)* %c1, iCAPRANGE %sub
  ret i8 addrspace(200)* %gep
}

%struct.A = type { [7 x i8] }

define %struct.A addrspace(200)* @D98611_2(%struct.A addrspace(200)* %c1, iCAPRANGE %offset) {
  %c2 = getelementptr inbounds %struct.A, %struct.A addrspace(200)* %c1, iCAPRANGE %offset
  %p1 = bitcast %struct.A addrspace(200)* %c1 to i8 addrspace(200)*
  %p2 = bitcast %struct.A addrspace(200)* %c2 to i8 addrspace(200)*
  %ptrtoint1 = call iCAPRANGE @llvm.cheri.cap.address.get.iCAPRANGE(i8 addrspace(200)* %p1)
  %ptrtoint2 = call iCAPRANGE @llvm.cheri.cap.address.get.iCAPRANGE(i8 addrspace(200)* %p2)
  %sub = sub iCAPRANGE %ptrtoint2, %ptrtoint1
  %sdiv = sdiv exact iCAPRANGE %sub, 7
  %gep = getelementptr inbounds %struct.A, %struct.A addrspace(200)* %c1, iCAPRANGE %sdiv
  ret %struct.A addrspace(200)* %gep
}

define i32 addrspace(200)* @D98611_3(i32 addrspace(200)* %c1, iCAPRANGE %offset) {
  %c2 = getelementptr inbounds i32, i32 addrspace(200)* %c1, iCAPRANGE %offset
  %p1 = bitcast i32 addrspace(200)* %c1 to i8 addrspace(200)*
  %p2 = bitcast i32 addrspace(200)* %c2 to i8 addrspace(200)*
  %ptrtoint1 = call iCAPRANGE @llvm.cheri.cap.address.get.iCAPRANGE(i8 addrspace(200)* %p1)
  %ptrtoint2 = call iCAPRANGE @llvm.cheri.cap.address.get.iCAPRANGE(i8 addrspace(200)* %p2)
  %sub = sub iCAPRANGE %ptrtoint2, %ptrtoint1
  %ashr = ashr exact iCAPRANGE %sub, 2
  %gep = getelementptr inbounds i32, i32 addrspace(200)* %c1, iCAPRANGE %ashr
  ret i32 addrspace(200)* %gep
}
