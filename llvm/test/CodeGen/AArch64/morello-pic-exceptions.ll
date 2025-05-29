; RUN: llc -march=arm64 -relocation-model=pic -mattr=+morello,+c64 -target-abi purecap %s -o - | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none-unknown-elf"

%class.a = type { i8 }

@_ZTIi = external addrspace(200) constant ptr addrspace(200)
define void @_Z1bv() local_unnamed_addr addrspace(200) personality ptr addrspace(200) @__gxx_personality_v0 {
entry:
  %c = alloca %class.a, align 1, addrspace(200)
  call void @llvm.lifetime.start.p200(i64 1, ptr addrspace(200) nonnull %c)
  invoke void @_ZN1aC1Ev(ptr addrspace(200) nonnull %c)
          to label %invoke.cont unwind label %lpad

invoke.cont:
  call void @llvm.lifetime.end.p200(i64 1, ptr addrspace(200) nonnull %c)
  br label %try.cont

lpad:
  %0 = landingpad { ptr addrspace(200), i32 }
          cleanup
          catch ptr addrspace(200) @_ZTIi
  %1 = extractvalue { ptr addrspace(200), i32 } %0, 1
  call void @llvm.lifetime.end.p200(i64 1, ptr addrspace(200) nonnull %c)
  %2 = call i32 @llvm.eh.typeid.for(ptr addrspacecast (ptr addrspace(200) @_ZTIi to ptr))
  %matches = icmp eq i32 %1, %2
  br i1 %matches, label %catch, label %eh.resume

catch:
  %3 = extractvalue { ptr addrspace(200), i32 } %0, 0
  %4 = call ptr addrspace(200) @__cxa_begin_catch(ptr addrspace(200) %3)
  call void @__cxa_end_catch()
  br label %try.cont

try.cont:
  ret void

eh.resume:
  resume { ptr addrspace(200), i32 } %0
}

; CHECK: .L_ZTIi.DW.stub:
; CHECK-NEXT: .chericap _ZTIi
; CHECK: DW.ref.__gxx_personality_v0:
; CHECK-NEXT: .chericap __gxx_personality_v0

declare void @llvm.lifetime.start.p200(i64 immarg, ptr addrspace(200) nocapture) addrspace(200)
declare void @_ZN1aC1Ev(ptr addrspace(200)) unnamed_addr addrspace(200)
declare i32 @__gxx_personality_v0(...) addrspace(200)
declare void @llvm.lifetime.end.p200(i64 immarg, ptr addrspace(200) nocapture) addrspace(200)
declare i32 @llvm.eh.typeid.for(ptr) addrspace(200)
declare ptr addrspace(200) @__cxa_begin_catch(ptr addrspace(200)) local_unnamed_addr addrspace(200)
declare void @__cxa_end_catch() local_unnamed_addr addrspace(200)
