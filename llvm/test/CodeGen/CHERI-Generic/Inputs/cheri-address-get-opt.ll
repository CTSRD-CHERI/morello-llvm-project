; RUN: opt -S --passes=instcombine @HYBRID_HARDFLOAT_ARGS@ %s -o - | FileCheck %s --check-prefix=HYBRID
; RUN: opt -S --passes=instcombine @PURECAP_HARDFLOAT_ARGS@ %s -o - | FileCheck %s --check-prefix=PURECAP

target datalayout = "@PURECAP_DATALAYOUT@"


@a = addrspace(200) global [200 x i32] zeroinitializer, align 4

define iCAPRANGE @foo() {
entry:
  %0 = call iCAPRANGE @llvm.cheri.cap.address.get.iCAPRANGE(i8 addrspace(200)* bitcast (i32 addrspace(200)* getelementptr inbounds ([200 x i32], [200 x i32] addrspace(200)* @a, i64 0, i64 198) to i8 addrspace(200)*))
  %1 = call iCAPRANGE @llvm.cheri.cap.address.get.iCAPRANGE(i8 addrspace(200)* bitcast (i32 addrspace(200)* getelementptr inbounds ([200 x i32], [200 x i32] addrspace(200)* @a, i64 0, i64 2) to i8 addrspace(200)*))
  %sub.ptr.sub = sub iCAPRANGE %0, %1
  %sub.ptr.div = sdiv exact iCAPRANGE %sub.ptr.sub, 4
  ret iCAPRANGE %sub.ptr.div
}

declare iCAPRANGE @llvm.cheri.cap.address.get.iCAPRANGE(i8 addrspace(200)*)

; Don't fold a subtract of cheri_cap_address_get to cap_diff.
define iCAPRANGE @bar(iCAPRANGE %i) {
entry:
  %arrayidx = getelementptr inbounds [200 x i32], [200 x i32] addrspace(200)* @a, i64 0, iCAPRANGE %i
  %0 = call iCAPRANGE @llvm.cheri.cap.address.get.iCAPRANGE(i8 addrspace(200)* bitcast (i32 addrspace(200)* getelementptr inbounds ([200 x i32], [200 x i32] addrspace(200)* @a, i64 0, i64 198) to i8 addrspace(200)*))
  %1 = bitcast i32 addrspace(200)* %arrayidx to i8 addrspace(200)*
  %2 = call iCAPRANGE @llvm.cheri.cap.address.get.iCAPRANGE(i8 addrspace(200)* %1)
  %sub.ptr.sub = sub iCAPRANGE %0, %2
  %sub.ptr.div = sdiv exact iCAPRANGE %sub.ptr.sub, 4
  ret iCAPRANGE %sub.ptr.div
}
