; RUN: llc < %s -march=arm64 -mattr=+c64,+morello -target-abi purecap -cheri-landing-pad-encoding=absolute -o - | FileCheck %s --check-prefix=ABS
; RUN: llc < %s -march=arm64 -mattr=+c64,+morello -target-abi purecap -cheri-landing-pad-encoding=indirect -o - | FileCheck %s --check-prefix=IND
; RUN: llc < %s -march=arm64 -mattr=+c64,+morello -target-abi purecap -filetype=obj -o - | llvm-readelf -s - | FileCheck %s --check-prefix=SYM
; RUN: llc < %s -march=arm64 --relocation-model=pic -mattr=+c64,+morello -target-abi purecap -filetype=obj -o - | llvm-readelf -s - | FileCheck %s --check-prefix=SYM

; When optimizing the load in instruction in the lpad27 basic block  we used to insert
; instructions before the landingpad instruction, which caused us to crash later on.
; This also works to test that the compiler can generally code generation for exceptions.

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none-unknown-elf"

%"struct.std::__1::once_flag.0.280.560.700.980.1120.1260.1680.2100.3080.4900.5040.5180.5320.5460.5740.5880.7280" = type { i64 }
%"class.std::__1::basic_string.4.25.305.585.725.1005.1145.1285.1705.2125.3105.4925.5065.5205.5345.5485.5765.5905.7286" = type { %"class.std::__1::__compressed_pair.5.24.304.584.724.1004.1144.1284.1704.2124.3104.4924.5064.5204.5344.5484.5764.5904.7285" }
%"class.std::__1::__compressed_pair.5.24.304.584.724.1004.1144.1284.1704.2124.3104.4924.5064.5204.5344.5484.5764.5904.7285" = type { %"struct.std::__1::__compressed_pair_elem.6.23.303.583.723.1003.1143.1283.1703.2123.3103.4923.5063.5203.5343.5483.5763.5903.7284" }
%"struct.std::__1::__compressed_pair_elem.6.23.303.583.723.1003.1143.1283.1703.2123.3103.4923.5063.5203.5343.5483.5763.5903.7284" = type { %"struct.std::__1::basic_string<wchar_t, std::__1::char_traits<wchar_t>, std::__1::allocator<wchar_t> >::__rep.22.302.582.722.1002.1142.1282.1702.2122.3102.4922.5062.5202.5342.5482.5762.5902.7283" }
%"struct.std::__1::basic_string<wchar_t, std::__1::char_traits<wchar_t>, std::__1::allocator<wchar_t> >::__rep.22.302.582.722.1002.1142.1282.1702.2122.3102.4922.5062.5202.5342.5482.5762.5902.7283" = type { %union.anon.7.21.301.581.721.1001.1141.1281.1701.2121.3101.4921.5061.5201.5341.5481.5761.5901.7282 }
%union.anon.7.21.301.581.721.1001.1141.1281.1701.2121.3101.4921.5061.5201.5341.5481.5761.5901.7282 = type { %"struct.std::__1::basic_string<wchar_t, std::__1::char_traits<wchar_t>, std::__1::allocator<wchar_t> >::__long.20.300.580.720.1000.1140.1280.1700.2120.3100.4920.5060.5200.5340.5480.5760.5900.7281" }
%"struct.std::__1::basic_string<wchar_t, std::__1::char_traits<wchar_t>, std::__1::allocator<wchar_t> >::__long.20.300.580.720.1000.1140.1280.1700.2120.3100.4920.5060.5200.5340.5480.5760.5900.7281" = type { i64, i64, ptr addrspace(200) }

$_ZNKSt3__17num_getIwNS_19istreambuf_iteratorIwNS_11char_traitsIwEEEEE6do_getES4_S4_QRNS_8ios_baseEQRjQRb = comdat any

@_ZNSt3__15ctypeIwE2idE = external dso_local addrspace(200) global { %"struct.std::__1::once_flag.0.280.560.700.980.1120.1260.1680.2100.3080.4900.5040.5180.5320.5460.5740.5880.7280", i32 }, align 8

; Function Attrs: argmemonly nounwind
declare void @llvm.lifetime.end.p200(i64, ptr addrspace(200) nocapture) addrspace(200) #0

declare dso_local i32 @__gxx_personality_v0(...) addrspace(200)

define dso_local void @_ZNKSt3__17num_getIwNS_19istreambuf_iteratorIwNS_11char_traitsIwEEEEE6do_getES4_S4_QRNS_8ios_baseEQRjQRb() unnamed_addr addrspace(200) #1 comdat align 2 personality ptr addrspace(200) @__gxx_personality_v0 {
entry:
  %__names = alloca [2 x %"class.std::__1::basic_string.4.25.305.585.725.1005.1145.1285.1705.2125.3105.4925.5065.5205.5345.5485.5765.5905.7286"], align 16, addrspace(200)
  invoke void @_ZNKSt3__16locale9use_facetEQRNS0_2idE()
          to label %invoke.cont unwind label %lpad

invoke.cont:                                      ; preds = %entry
  invoke void @_ZNSt3__114__scan_keywordINS_19istreambuf_iteratorIwNS_11char_traitsIwEEEEQPKNS_12basic_stringIwS3_NS_9allocatorIwEEEENS_5ctypeIwEEEET0_QRT_SE_SD_SD_QRKT1_QRjb()
          to label %invoke.cont28 unwind label %lpad27

invoke.cont28:                                    ; preds = %invoke.cont
  unreachable

lpad:                                             ; preds = %entry
  %0 = landingpad { ptr addrspace(200), i32 }
          cleanup
  resume { ptr addrspace(200), i32 } undef

lpad27:                                           ; preds = %invoke.cont
  %1 = landingpad { ptr addrspace(200), i32 }
          cleanup
  %arraydestroy.element40 = getelementptr inbounds [2 x %"class.std::__1::basic_string.4.25.305.585.725.1005.1145.1285.1705.2125.3105.4925.5065.5205.5345.5485.5765.5905.7286"], ptr addrspace(200) %__names, i64 0, i64 1
  %2 = load i8, ptr addrspace(200) %arraydestroy.element40, align 16, !tbaa !1
  call void @llvm.lifetime.end.p200(i64 64, ptr addrspace(200) null) #2
  unreachable
}

declare hidden void @_ZNSt3__114__scan_keywordINS_19istreambuf_iteratorIwNS_11char_traitsIwEEEEQPKNS_12basic_stringIwS3_NS_9allocatorIwEEEENS_5ctypeIwEEEET0_QRT_SE_SD_SD_QRKT1_QRjb() local_unnamed_addr addrspace(200) #1

declare dso_local void @_ZNKSt3__16locale9use_facetEQRNS0_2idE() local_unnamed_addr addrspace(200) #1 align 2

attributes #0 = { argmemonly nounwind }
attributes #1 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="generic" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind }

!1 = !{!2, !2, i64 0}
!2 = !{!"omnipotent char", !3, i64 0}
!3 = !{!"Simple C++ TBAA"}

; ABS:	.section	.gcc_except_table.{{.*}},"aGw",@progbits
; ABS:	.p2align	2

; ABS-LABEL: GCC_except_table0:
; ABS-NEXT: .Lexception0:
; ABS-NEXT:	.byte	255                             // @LPStart Encoding = omit
; ABS-NEXT:	.byte	255                             // @TType Encoding = omit
; ABS-NEXT:	.byte	1                               // Call site Encoding = uleb128
; ABS-NEXT:	.uleb128 .Lcst_end0-.Lcst_begin0
; ABS-NEXT: .Lcst_begin0:
; ABS-NEXT:	.uleb128 .Ltmp0-.Lfunc_begin0           // >> Call Site 1 <<
; ABS-NEXT:	.uleb128 .Ltmp1-.Ltmp0                  //   Call between .Ltmp0 and .Ltmp1
; ABS-NEXT:	.byte	12                              // (landing pad is a capability)
; ABS-NEXT:	.chericap	.L_ZNKSt3__17num_getIwNS_19istreambuf_iteratorIwNS_11char_traitsIwEEEEE6do_getES4_S4_QRNS_8ios_baseEQRjQRb$local+(.Ltmp2-.Lfunc_begin0) //     jumps to .Ltmp2
; ABS-NEXT:	.byte	0                               //   On action: cleanup
; ABS-NEXT:	.uleb128 .Ltmp1-.Lfunc_begin0           // >> Call Site 2 <<
; ABS-NEXT:	.uleb128 .Lfunc_end0-.Ltmp1             //   Call between .Ltmp1 and .Lfunc_end0
; ABS-NEXT:	.byte	0                               //     has no landing pad
; ABS-NEXT:	.byte	0                               //   On action: cleanup
; ABS-NEXT: .Lcst_end0:

; IND:	.section	.gcc_except_table.{{.*}},"aG",@progbits
; IND:	.p2align	2
; IND-LABEL: GCC_except_table0:
; IND-NEXT: .Lexception0:
; IND-NEXT:	.byte	255                             // @LPStart Encoding = omit
; IND-NEXT:	.byte	255                             // @TType Encoding = omit
; IND-NEXT:	.byte	1                               // Call site Encoding = uleb128
; IND-NEXT:	.uleb128 .Lcst_end0-.Lcst_begin0
; IND-NEXT: .Lcst_begin0:
; IND-NEXT:	.uleb128 .Ltmp0-.Lfunc_begin0           // >> Call Site 1 <<
; IND-NEXT:	.uleb128 .Ltmp1-.Ltmp0                  //   Call between .Ltmp0 and .Ltmp1
; IND-NEXT:	.byte	13                              // (landing pad is a capability)
; IND-NEXT: .Llpoff0:                               //     jumps to .Ltmp2
; IND-NEXT:	.xword	.Ltmp3-.Llpoff0
; IND-NEXT:	.byte	0                               //   On action: cleanup
; IND-NEXT:	.uleb128 .Ltmp1-.Lfunc_begin0           // >> Call Site 2 <<
; IND-NEXT:	.uleb128 .Lfunc_end0-.Ltmp1             //   Call between .Ltmp1 and .Lfunc_end0
; IND-NEXT:	.byte	0                               //     has no landing pad
; IND-NEXT:	.byte	0                               //   On action: cleanup
; IND-NEXT: .Lcst_end0:

; IND: .section	.data.rel.ro,"aGw",@progbits,_ZNKSt3__17num_getIwNS_19istreambuf_iteratorIwNS_11char_traitsIwEEEEE6do_getES4_S4_QRNS_8ios_baseEQRjQRb,comdat
; IND-NEXT:	.p2align	4
; IND-NEXT: .Ltmp3:
; IND-NEXT:	.chericap	.L_ZNKSt3__17num_getIwNS_19istreambuf_iteratorIwNS_11char_traitsIwEEEEE6do_getES4_S4_QRNS_8ios_baseEQRjQRb$local+(.Ltmp2-.Lfunc_begin0)

; SYM: 0000000000000001    {{[0-9]+}} FUNC    LOCAL  DEFAULT     {{[0-9]+}} .L_ZNKSt3__17num_getIwNS_19istreambuf_iteratorIwNS_11char_traitsIwEEEEE6do_getES4_S4_QRNS_8ios_baseEQRjQRb$local
