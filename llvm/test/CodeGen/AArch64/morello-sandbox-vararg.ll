; RUN: llc -march=arm64 -mattr=+morello,+c64,+legacy-morello-vararg -frame-pointer=all -target-abi purecap -o - %s | FileCheck %s
target datalayout = "e-m:e-i64:64-i128:128-n32:64-S128-pf200:128:128:128:64-A200-P200-G200"
target triple = "aarch64-none--elf"

declare i32 @bar(ptr addrspace(200), ...) addrspace(200)

; CHECK-LABEL: testSetFPVarArgs
define i32 @testSetFPVarArgs(ptr addrspace(200) %fmt, double %d, float %f) addrspace(200) {
entry:
  %conv = fpext float %f to double
  %call = tail call i32 (ptr addrspace(200), ...) @bar(ptr addrspace(200) %fmt, double %d, double %conv, double 1.000000e+00, double 2.000000e+00, double 2.000000e+00, double 4.000000e+00, double 5.000000e+00, double 6.000000e+00, double %d, double %conv) #3
  ret i32 %call
; CHECK: fcvt	d1, s1
; CHECK: stp	d0, d1, [csp]
}

; CHECK-LABEL: testSetGPVarArgs
define i32 @testSetGPVarArgs(ptr addrspace(200) %fmt, i64 %n, i32 %w, i16 %s, i8 %c) addrspace(200) {
entry:
  %conv = sext i16 %s to i32
  %conv1 = zext i8 %c to i32
  %call = tail call i32 (ptr addrspace(200), ...) @bar(ptr addrspace(200) %fmt, ptr addrspace(200) %fmt, i64 %n, i32 %w, i32 %conv, i32 %conv1, i32 1, i32 2, ptr addrspace(200) %fmt, i64 %n, i32 %w, i32 %conv, i32 %conv1, ptr addrspace(200) %fmt)
  ret i32 %call

; The following arguments get spilled to stack with the following offsets in the pure capability ABI from CSP:
; i8 addrspace(200) %fmt   #0
; i64 n                    #16
; i32 w                    #24
; i32 conv                 #32
; i32 conv1                #40
; i8 addrspace(200) %fmt   #48

; CHECK-DAG: str	c{{.*}}, [csp, #48]
; CHECK-DAG: str	w{{.*}}, [csp, #40]
; CHECK-DAG: str	w{{.*}}, [csp, #32]
; CHECK-DAG: str	w{{.*}}, [csp, #24]
; CHECK-DAG: str	x{{.*}}, [csp, #16]
; CHECK-DAG: str	c{{.*}}, [csp, #0]
}

declare void @llvm.lifetime.start.p200(i64, ptr addrspace(200) nocapture) addrspace(200)
declare void @llvm.lifetime.end.p200(i64, ptr addrspace(200) nocapture) addrspace(200)
declare void @llvm.va_start.p200(ptr addrspace(200)) addrspace(200)
declare void @llvm.va_end.p200(ptr addrspace(200)) addrspace(200)
declare i32 @foo(ptr addrspace(200), ptr addrspace(200)) addrspace(200)

%struct.__va_list = type { ptr addrspace(200), ptr addrspace(200), ptr addrspace(200), i32, i32 }

; CHECK-LABEL: testVAListAddress
define i32 @testVAListAddress(ptr addrspace(200) %fmt, ...) addrspace(200) {
entry:
  %vl = alloca %struct.__va_list, align 16, addrspace(200)
  call void @llvm.lifetime.start.p200(i64 64, ptr addrspace(200) %vl)
  call void @llvm.va_start.p200(ptr addrspace(200) %vl)
  %call = call i32 @foo(ptr addrspace(200) %fmt, ptr addrspace(200) nonnull %vl)
  call void @llvm.va_end.p200(ptr addrspace(200) %vl)
  call void @llvm.lifetime.end.p200(i64 64, ptr addrspace(200) %vl)
  ret i32 %call
; CHECK-NOT: str c{{[0-9]+}}, [x{{[0-9]+}}
}
