; RUN: opt -target-abi purecap -mattr=+morello,+c64 -o - -interleaved-load-combine %s -S | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none-unknown-elf"

%struct.blam = type { %struct.wibble }
%struct.wibble = type { ptr addrspace(200), i64, i32, ptr addrspace(200) }
%struct.wobble = type { float, float }

; CHECK-NOT: addrspacecast
; CHECK-LABEL: pluto
; CHECK: %interleaved.wide.load = load <8 x float>, ptr addrspace(200) %interleaved.wide.ptrcast, align 16
define void @pluto(ptr addrspace(200) nonnull dereferenceable(48) %arg, ptr addrspace(200) %arg1, i64 %arg2, i64 %arg3, i64 %arg4) unnamed_addr addrspace(200)  align 2 {
bb:
  br i1 false, label %bb15, label %bb5

bb5:
  %tmp = lshr i64 undef, 1
  %tmp6 = getelementptr inbounds <4 x float>, ptr addrspace(200) undef, i64 %tmp
  %tmp7 = load <4 x float>, ptr addrspace(200) %tmp6, align 16
  %tmp8 = add i64 undef, 2
  %tmp9 = lshr i64 %tmp8, 1
  %tmp10 = getelementptr inbounds <4 x float>, ptr addrspace(200) undef, i64 %tmp9
  %tmp11 = load <4 x float>, ptr addrspace(200) %tmp10, align 16
  %tmp12 = shufflevector <4 x float> %tmp7, <4 x float> %tmp11, <4 x i32> <i32 0, i32 2, i32 4, i32 6>
  %tmp13 = shufflevector <4 x float> %tmp7, <4 x float> %tmp11, <4 x i32> <i32 1, i32 3, i32 5, i32 7>
  %tmp14 = tail call <4 x float> @llvm.fma.v4f32(<4 x float> undef, <4 x float> undef, <4 x float> undef)
  unreachable

bb15:
  ret void
}

declare <4 x float> @llvm.fma.v4f32(<4 x float>, <4 x float>, <4 x float>) addrspace(200)
