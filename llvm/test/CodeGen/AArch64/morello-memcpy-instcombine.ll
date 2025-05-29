; RUN: opt -instcombine -march=arm64 -mattr=+c64 -target-abi purecap -S -o - %s | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none-unknown-elf"

%struct.y = type { ptr addrspace(200) }
%class.ay = type { i8 }

@ax = dso_local addrspace(200) global %struct.y zeroinitializer, align 16

; CHECK-LABEL: foo
; CHECK: call void @llvm.memcpy.p200.p200.i64{{.*}} [[ATTRIBUTE:#[0-9]+]]
; CHECK: attributes [[ATTRIBUTE]] = { must_preserve_cheri_tags }
define dso_local void @foo(ptr addrspace(200) %this, ptr addrspace(200) dereferenceable(16) %t) addrspace(200) align 2 {
entry:
  %this.addr = alloca ptr addrspace(200), align 16, addrspace(200)
  %t.addr = alloca ptr addrspace(200), align 16, addrspace(200)
  store ptr addrspace(200) %this, ptr addrspace(200) %this.addr, align 16
  store ptr addrspace(200) %t, ptr addrspace(200) %t.addr, align 16
  %this1 = load ptr addrspace(200), ptr addrspace(200) %this.addr, align 16
  %0 = load ptr addrspace(200), ptr addrspace(200) %t.addr, align 16
  %call = call ptr addrspace(200) @memcpy(ptr addrspace(200) %0, ptr addrspace(200) @ax, i64 16) #0
  ret void
}

declare dso_local ptr addrspace(200) @memcpy(ptr addrspace(200), ptr addrspace(200), i64) addrspace(200)

attributes #0 = { must_preserve_cheri_tags }
