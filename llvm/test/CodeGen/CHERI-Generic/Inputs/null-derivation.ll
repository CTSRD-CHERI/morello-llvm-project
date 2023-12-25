; RUN: llc @PURECAP_HARDFLOAT_ARGS@ %s -o - < %s | FileCheck %s --check-prefix=PURECAP
; RUN: llc @HYBRID_HARDFLOAT_ARGS@ -o - < %s | FileCheck %s --check-prefix=HYBRID

define i8 addrspace(200)* @foo(i32 %x) {
entry:
  ret i8 addrspace(200)* getelementptr (i8, i8 addrspace(200)* null, i64 42)
}

define i8 addrspace(200)* @bat(i32 %x) {
entry:
  %conv = sext i32 %x to i64
  %0 = getelementptr i8, i8 addrspace(200)* null, i64 %conv
  ret i8 addrspace(200)* %0
}

define i8 addrspace(200)* @baz(i32 %x) {
entry:
  %add = add nsw i32 %x, 1
  %conv = sext i32 %add to i64
  %0 = getelementptr i8, i8 addrspace(200)* null, i64 %conv
  ret i8 addrspace(200)* %0
}

declare iCAPRANGE @llvm.cheri.cap.address.get.iCAPRANGE(i8 addrspace(200)*)

define iCAPRANGE @bif(i8 addrspace(200)* addrspace(200)* nocapture readonly %y) {
entry:
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %y, align 16
  %1 = tail call iCAPRANGE @llvm.cheri.cap.address.get.iCAPRANGE(i8 addrspace(200)* %0)
  ret iCAPRANGE %1
}

define i8 addrspace(200)* @baf(i64 %y) {
entry:
  %0 = getelementptr i8, i8 addrspace(200)* null, i64 %y
  ret i8 addrspace(200)* %0
}
