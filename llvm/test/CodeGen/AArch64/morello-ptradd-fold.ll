; FIXME: we shouldn't use O2 here
; RUN: llc -mtriple=arm64 -mattr=+c64,+morello -O2 -target-abi purecap -o - %s

; This example was crashing in the load store optimizer because we were producing
; a CAddImm instruction on an undef register operand.

target datalayout = "e-m:e-pf200:128:128-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none--elf"

%"struct.std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::__short.14.29.74.89.119.134.179.224.299.314.329.374.434.509.644.779.794.809.824.839.927" = type { %union.anon.0.13.28.73.88.118.133.178.223.298.313.328.373.433.508.643.778.793.808.823.838.926, [31 x i8] }
%union.anon.0.13.28.73.88.118.133.178.223.298.313.328.373.433.508.643.778.793.808.823.838.926 = type { i8 }

$_Z5test0INSt3__112basic_stringIcNS0_11char_traitsIcEENS0_9allocatorIcEEEEEvv = comdat any

@.str.1 = external unnamed_addr addrspace(200) constant [6 x i8], align 1
@.str.3 = external unnamed_addr addrspace(200) constant [21 x i8], align 1

define void @_Z5test0INSt3__112basic_stringIcNS0_11char_traitsIcEENS0_9allocatorIcEEEEEvv() local_unnamed_addr addrspace(200) comdat {
_ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEED2Ev.exit189:
  call void @llvm.memcpy.p200i8.p200i8.i64(i8 addrspace(200)* null, i8 addrspace(200)* getelementptr inbounds ([6 x i8], [6 x i8] addrspace(200)* @.str.1, i64 0, i64 0), i64 5, i32 1, i1 false) #0
  %arrayidx.i.i.i420 = getelementptr inbounds %"struct.std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::__short.14.29.74.89.119.134.179.224.299.314.329.374.434.509.644.779.794.809.824.839.927", %"struct.std::__1::basic_string<char, std::__1::char_traits<char>, std::__1::allocator<char> >::__short.14.29.74.89.119.134.179.224.299.314.329.374.434.509.644.779.794.809.824.839.927" addrspace(200)* undef, i64 0, i32 1, i64 0
  call void @llvm.memcpy.p200i8.p200i8.i64(i8 addrspace(200)* %arrayidx.i.i.i420, i8 addrspace(200)* getelementptr inbounds ([21 x i8], [21 x i8] addrspace(200)* @.str.3, i64 0, i64 0), i64 20, i32 1, i1 false) #0
  ret void
}

declare void @llvm.memcpy.p200i8.p200i8.i64(i8 addrspace(200)* nocapture writeonly, i8 addrspace(200)* nocapture readonly, i64, i32, i1) addrspace(200)

attributes #0 = { "must-preserve-cheri-tags" }
