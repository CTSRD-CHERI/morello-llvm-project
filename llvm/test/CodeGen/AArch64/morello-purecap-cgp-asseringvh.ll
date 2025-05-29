; RUN: llc -march=arm64 < %s -mattr=+c64,+morello -target-abi purecap -o - | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none--elf"

; This test cause an AssertingVH from CGP to trigger when a GEP was modified by
; the AArch64 Sandbox Globals Opt pass.

%struct.ImageParameters.13.38.163.188.213.288.538.563.588.613.688.812 = type { i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, float, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, ptr addrspace(200), ptr addrspace(200), i32, ptr addrspace(200), i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, [9 x [16 x [16 x i16]]], [5 x [16 x [16 x i16]]], [9 x [8 x [8 x i16]]], [2 x [4 x [16 x [16 x i16]]]], [16 x [16 x i16]], [16 x [16 x i32]], ptr addrspace(200), ptr addrspace(200), ptr addrspace(200), ptr addrspace(200), ptr addrspace(200), [1200 x %struct.syntaxelement.3.28.153.178.203.278.528.553.578.603.678.802], ptr addrspace(200), ptr addrspace(200), i32, i32, i32, i32, [4 x [4 x i32]], i32, i32, i32, i32, i32, double, i32, i32, i32, i32, ptr addrspace(200), ptr addrspace(200), ptr addrspace(200), ptr addrspace(200), [15 x i16], i32, i32, i32, i32, i32, i32, i32, i32, [6 x [15 x i32]], i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, [1 x i32], i32, i32, [2 x i32], i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, ptr addrspace(200), i32, i32, i32, i32, i32, double, i32, i32, i32, i32, i32, i32, i32, ptr addrspace(200), i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, [2 x i32], i32, i32, i32 }
%struct.Picture.10.35.160.185.210.285.535.560.585.610.685.809 = type { i32, i32, [100 x ptr addrspace(200)], i32, float, float, float }
%struct.Slice.9.34.159.184.209.284.534.559.584.609.684.808 = type { i32, i32, i32, i32, i32, i32, ptr addrspace(200), ptr addrspace(200), ptr addrspace(200), ptr addrspace(200), i32, ptr addrspace(200), ptr addrspace(200), ptr addrspace(200), i32, ptr addrspace(200), ptr addrspace(200), ptr addrspace(200), ptr addrspace(200), [3 x [2 x i32]] }
%struct.datapartition.4.29.154.179.204.279.529.554.579.604.679.803 = type { ptr addrspace(200), %struct.EncodingEnvironment.2.27.152.177.202.277.527.552.577.602.677.801, ptr addrspace(200) }
%struct.Bitstream.1.26.151.176.201.276.526.551.576.601.676.800 = type { i32, i32, i8, i32, i32, i8, i8, i32, i32, ptr addrspace(200), i32 }
%struct.EncodingEnvironment.2.27.152.177.202.277.527.552.577.602.677.801 = type { i32, i32, i32, i32, i32, ptr addrspace(200), ptr addrspace(200), i32, i32, i32, i32, i32, ptr addrspace(200), ptr addrspace(200), i32, i32, i32, i32, i32, i32 }
%struct.syntaxelement.3.28.153.178.203.278.528.553.578.603.678.802 = type { i32, i32, i32, i32, i32, i32, i32, i32, ptr addrspace(200), ptr addrspace(200) }
%struct.MotionInfoContexts.6.31.156.181.206.281.531.556.581.606.681.805 = type { [3 x [11 x %struct.BiContextType.5.30.155.180.205.280.530.555.580.605.680.804]], [2 x [9 x %struct.BiContextType.5.30.155.180.205.280.530.555.580.605.680.804]], [2 x [10 x %struct.BiContextType.5.30.155.180.205.280.530.555.580.605.680.804]], [2 x [6 x %struct.BiContextType.5.30.155.180.205.280.530.555.580.605.680.804]], [4 x %struct.BiContextType.5.30.155.180.205.280.530.555.580.605.680.804], [4 x %struct.BiContextType.5.30.155.180.205.280.530.555.580.605.680.804], [3 x %struct.BiContextType.5.30.155.180.205.280.530.555.580.605.680.804] }
%struct.BiContextType.5.30.155.180.205.280.530.555.580.605.680.804 = type { i16, i8, i64 }
%struct.TextureInfoContexts.7.32.157.182.207.282.532.557.582.607.682.806 = type { [2 x %struct.BiContextType.5.30.155.180.205.280.530.555.580.605.680.804], [4 x %struct.BiContextType.5.30.155.180.205.280.530.555.580.605.680.804], [3 x [4 x %struct.BiContextType.5.30.155.180.205.280.530.555.580.605.680.804]], [10 x [4 x %struct.BiContextType.5.30.155.180.205.280.530.555.580.605.680.804]], [10 x [15 x %struct.BiContextType.5.30.155.180.205.280.530.555.580.605.680.804]], [10 x [15 x %struct.BiContextType.5.30.155.180.205.280.530.555.580.605.680.804]], [10 x [5 x %struct.BiContextType.5.30.155.180.205.280.530.555.580.605.680.804]], [10 x [5 x %struct.BiContextType.5.30.155.180.205.280.530.555.580.605.680.804]], [10 x [15 x %struct.BiContextType.5.30.155.180.205.280.530.555.580.605.680.804]], [10 x [15 x %struct.BiContextType.5.30.155.180.205.280.530.555.580.605.680.804]] }
%struct.RMPNIbuffer_s.8.33.158.183.208.283.533.558.583.608.683.807 = type { i32, i32, ptr addrspace(200) }
%struct.macroblock.11.36.161.186.211.286.536.561.586.611.686.810 = type { i32, i32, i32, i32, i32, [8 x i32], ptr addrspace(200), ptr addrspace(200), i32, [2 x [4 x [4 x [2 x i32]]]], [16 x i32], [16 x i32], i32, i64, [4 x i32], [4 x i32], i64, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, i32, double, i32, i32, i32, i32, i32, i32, i32, i32, i32 }
%struct.DecRefPicMarking_s.12.37.162.187.212.287.537.562.587.612.687.811 = type { i32, i32, i32, i32, i32, ptr addrspace(200) }

@img = external dso_local local_unnamed_addr addrspace(200) global ptr addrspace(200), align 16

; CHECK-LABEL: find_distortion
define dso_local fastcc void @find_distortion() unnamed_addr addrspace(200) #0 {
entry:
  %0 = load ptr addrspace(200), ptr addrspace(200) @img, align 16, !tbaa !1
  br i1 undef, label %for.cond80.preheader.lr.ph, label %for.end107

for.cond80.preheader.lr.ph:
  %quad_t85 = getelementptr inbounds %struct.ImageParameters.13.38.163.188.213.288.538.563.588.613.688.812, ptr addrspace(200) %0, i64 0, i32 53
  br label %for.cond80.preheader

for.cond80.preheader:
  %1 = load ptr addrspace(200), ptr addrspace(200) %quad_t85, align 16, !tbaa !5
  br label %for.body84

for.body84:
  br i1 undef, label %for.body84, label %for.cond80.preheader

for.end107:
  ret void
}

attributes #0 = { nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="generic"  "unsafe-fp-math"="false" "use-soft-float"="false" }

!1 = !{!2, !2, i64 0}
!2 = !{!"any pointer", !3, i64 0}
!3 = !{!"omnipotent char", !4, i64 0}
!4 = !{!"Simple C/C++ TBAA"}
!5 = !{!6, !2, i64 91056}
!6 = !{!"", !7, i64 0, !7, i64 4, !7, i64 8, !7, i64 12, !7, i64 16, !7, i64 20, !7, i64 24, !7, i64 28, !7, i64 32, !7, i64 36, !7, i64 40, !7, i64 44, !8, i64 48, !7, i64 52, !7, i64 56, !7, i64 60, !7, i64 64, !7, i64 68, !7, i64 72, !7, i64 76, !7, i64 80, !7, i64 84, !7, i64 88, !7, i64 92, !7, i64 96, !2, i64 112, !2, i64 128, !7, i64 144, !2, i64 160, !7, i64 176, !7, i64 180, !7, i64 184, !7, i64 188, !7, i64 192, !7, i64 196, !7, i64 200, !7, i64 204, !7, i64 208, !7, i64 212, !7, i64 216, !7, i64 220, !3, i64 224, !3, i64 4832, !3, i64 7392, !3, i64 8544, !3, i64 12640, !3, i64 13152, !2, i64 14176, !2, i64 14192, !2, i64 14208, !2, i64 14224, !2, i64 14240, !3, i64 14256, !2, i64 91056, !2, i64 91072, !7, i64 91088, !7, i64 91092, !7, i64 91096, !7, i64 91100, !3, i64 91104, !7, i64 91168, !7, i64 91172, !7, i64 91176, !7, i64 91180, !7, i64 91184, !9, i64 91192, !7, i64 91200, !7, i64 91204, !7, i64 91208, !7, i64 91212, !2, i64 91216, !2, i64 91232, !2, i64 91248, !2, i64 91264, !3, i64 91280, !7, i64 91312, !7, i64 91316, !7, i64 91320, !7, i64 91324, !7, i64 91328, !7, i64 91332, !7, i64 91336, !7, i64 91340, !3, i64 91344, !7, i64 91704, !7, i64 91708, !7, i64 91712, !7, i64 91716, !7, i64 91720, !7, i64 91724, !7, i64 91728, !7, i64 91732, !7, i64 91736, !7, i64 91740, !7, i64 91744, !7, i64 91748, !3, i64 91752, !7, i64 91756, !7, i64 91760, !3, i64 91764, !7, i64 91772, !7, i64 91776, !7, i64 91780, !7, i64 91784, !7, i64 91788, !7, i64 91792, !7, i64 91796, !7, i64 91800, !7, i64 91804, !7, i64 91808, !7, i64 91812, !7, i64 91816, !7, i64 91820, !7, i64 91824, !7, i64 91828, !7, i64 91832, !7, i64 91836, !2, i64 91840, !7, i64 91856, !7, i64 91860, !7, i64 91864, !7, i64 91868, !7, i64 91872, !9, i64 91880, !7, i64 91888, !7, i64 91892, !7, i64 91896, !7, i64 91900, !7, i64 91904, !7, i64 91908, !7, i64 91912, !2, i64 91920, !7, i64 91936, !7, i64 91940, !7, i64 91944, !7, i64 91948, !7, i64 91952, !7, i64 91956, !7, i64 91960, !7, i64 91964, !7, i64 91968, !7, i64 91972, !7, i64 91976, !7, i64 91980, !7, i64 91984, !7, i64 91988, !7, i64 91992, !7, i64 91996, !7, i64 92000, !7, i64 92004, !7, i64 92008, !7, i64 92012, !7, i64 92016, !7, i64 92020, !7, i64 92024, !7, i64 92028, !7, i64 92032, !7, i64 92036, !7, i64 92040, !7, i64 92044, !7, i64 92048, !7, i64 92052, !7, i64 92056, !3, i64 92060, !7, i64 92068, !7, i64 92072, !7, i64 92076}
!7 = !{!"int", !3, i64 0}
!8 = !{!"float", !3, i64 0}
!9 = !{!"double", !3, i64 0}
