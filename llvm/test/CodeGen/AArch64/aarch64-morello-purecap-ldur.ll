; RUN: llc < %s -mtriple=arm64 -mattr=+c64,+morello -target-abi purecap | FileCheck %s

@var_8bit = addrspace(200) global i8 0
@var_16bit = addrspace(200) global i16 0
@var_32bit = addrspace(200) global i32 0
@var_64bit = addrspace(200) global i64 0

@var_float = addrspace(200) global float 0.0
@var_double =addrspace(200) global double 0.0

define i64 @fun0(i64 addrspace(200)* %p) {
; CHECK: fun0:
; CHECK: ldur x0, [c0, #-8]
; CHECK-NEXT: ret
  %tmp = getelementptr inbounds i64, i64 addrspace(200)* %p, i64 -1
  %ret = load i64, i64 addrspace(200)* %tmp, align 2
  ret i64 %ret
}
define i32 @fun1(i32 addrspace(200)* %p) {
; CHECK: fun1:
; CHECK: ldur w0, [c0, #-4]
; CHECK-NEXT: ret
  %tmp = getelementptr inbounds i32, i32 addrspace(200)* %p, i64 -1
  %ret = load i32, i32 addrspace(200)* %tmp, align 2
  ret i32 %ret
}
define i16 @fun2(i16 addrspace(200)* %p) {
; CHECK: fun2:
; CHECK: ldurh w0, [c0, #-2]
; CHECK-NEXT: ret
  %tmp = getelementptr inbounds i16, i16 addrspace(200)* %p, i64 -1
  %ret = load i16, i16 addrspace(200)* %tmp, align 2
  ret i16 %ret
}
define i8 @fun3(i8 addrspace(200)* %p) {
; CHECK: fun3:
; CHECK: ldurb w0, [c0, #-1]
; CHECK-NEXT: ret
  %tmp = getelementptr inbounds i8, i8 addrspace(200)* %p, i64 -1
  %ret = load i8, i8 addrspace(200)* %tmp, align 2
  ret i8 %ret
}

define i64 @zext32(i8 addrspace(200)* %a) nounwind ssp {
; CHECK-LABEL: zext32:
; CHECK: ldur w0, [c0, #-12]
; CHECK-NEXT: ret
  %p = getelementptr inbounds i8, i8 addrspace(200)* %a, i64 -12
  %tmp1 = bitcast i8 addrspace(200)* %p to i32 addrspace(200)*
  %tmp2 = load i32, i32 addrspace(200)* %tmp1, align 4
  %ret = zext i32 %tmp2 to i64

  ret i64 %ret
}
define i64 @zext16(i8 addrspace(200)* %a) nounwind ssp {
; CHECK-LABEL: zext16:
; CHECK: ldurh w0, [c0, #-12]
; CHECK-NEXT: ret
  %p = getelementptr inbounds i8, i8 addrspace(200)* %a, i64 -12
  %tmp1 = bitcast i8 addrspace(200)* %p to i16 addrspace(200)*
  %tmp2 = load i16, i16 addrspace(200)* %tmp1, align 2
  %ret = zext i16 %tmp2 to i64

  ret i64 %ret
}
define i64 @zext8(i8 addrspace(200)* %a) nounwind ssp {
; CHECK-LABEL: zext8:
; CHECK: ldurb w0, [c0, #-12]
; CHECK-NEXT: ret
  %p = getelementptr inbounds i8, i8 addrspace(200)* %a, i64 -12
  %tmp2 = load i8, i8 addrspace(200)* %p, align 1
  %ret = zext i8 %tmp2 to i64

  ret i64 %ret
}

define void @ldst_8bit(i8 addrspace(200)* %addr_8bit) {
; CHECK-LABEL: ldst_8bit:

; No architectural support for loads to 16-bit or 8-bit since we
; promote i8 during lowering.

; match a sign-extending load 8-bit -> 32-bit
   %addr_sext32 = getelementptr i8, i8 addrspace(200)* %addr_8bit, i64 -256
   %val8_sext32 = load volatile i8, i8 addrspace(200)* %addr_sext32
   %val32_signed = sext i8 %val8_sext32 to i32
   store volatile i32 %val32_signed, i32 addrspace(200)* @var_32bit
; CHECK: ldursb {{w[0-9]+}}, [{{c[0-9]+}}, #-256]

; match a zero-extending load volatile 8-bit -> 32-bit
  %addr_zext32 = getelementptr i8, i8 addrspace(200)* %addr_8bit, i64 -12
  %val8_zext32 = load volatile i8, i8 addrspace(200)* %addr_zext32
  %val32_unsigned = zext i8 %val8_zext32 to i32
  store volatile i32 %val32_unsigned, i32 addrspace(200)* @var_32bit
; CHECK: ldurb {{w[0-9]+}}, [{{c[0-9]+}}, #-12]

; match an any-extending load volatile 8-bit -> 32-bit
  %addr_anyext = getelementptr i8, i8 addrspace(200)* %addr_8bit, i64 -1
  %val8_anyext = load volatile i8, i8 addrspace(200)* %addr_anyext
  %newval8 = add i8 %val8_anyext, 1
  store volatile i8 %newval8, i8 addrspace(200)* @var_8bit
; CHECK: ldurb {{w[0-9]+}}, [{{c[0-9]+}}, #-1]

; match a sign-extending load volatile 8-bit -> 64-bit
  %addr_sext64 = getelementptr i8, i8 addrspace(200)* %addr_8bit, i64 -5
  %val8_sext64 = load volatile i8, i8 addrspace(200)* %addr_sext64
  %val64_signed = sext i8 %val8_sext64 to i64
  store volatile i64 %val64_signed, i64 addrspace(200)* @var_64bit
; CHECK: ldursb {{x[0-9]+}}, [{{c[0-9]+}}, #-5]

; match a zero-extending load volatile 8-bit -> 64-bit.
; This uses the fact that ldrb w0, [x0] will zero out the high 32-bits
; of x0 so it's identical to load volatileing to 32-bits.
  %addr_zext64 = getelementptr i8, i8 addrspace(200)* %addr_8bit, i64 -9
  %val8_zext64 = load volatile i8, i8 addrspace(200)* %addr_zext64
  %val64_unsigned = zext i8 %val8_zext64 to i64
  store volatile i64 %val64_unsigned, i64 addrspace(200)* @var_64bit
; CHECK: ldurb {{w[0-9]+}}, [{{c[0-9]+}}, #-9]

; truncating store volatile 32-bits to 8-bits
  %addr_trunc32 = getelementptr i8, i8 addrspace(200)* %addr_8bit, i64 -256
  %val32 = load volatile i32, i32 addrspace(200)* @var_32bit
  %val8_trunc32 = trunc i32 %val32 to i8
  store volatile i8 %val8_trunc32, i8 addrspace(200)* %addr_trunc32
; CHECK: sturb {{w[0-9]+}}, [{{c[0-9]+}}, #-256]

; truncating store volatile 64-bits to 8-bits
  %addr_trunc64 = getelementptr i8, i8 addrspace(200)* %addr_8bit, i64 -1
  %val64 = load volatile i64, i64 addrspace(200)* @var_64bit
  %val8_trunc64 = trunc i64 %val64 to i8
  store volatile i8 %val8_trunc64, i8 addrspace(200)* %addr_trunc64
; CHECK: sturb {{w[0-9]+}}, [{{c[0-9]+}}, #-1]

   ret void
}

define void @ldst_16bit(i8 addrspace(200)* %addr_8bit) {
; CHECK-LABEL: ldst_16bit:

; No architectural support for loads to 16-bit or 16-bit since we
; promote i16 during lowering.

; match a sign-extending load 16-bit -> 32-bit
   %addr8_sext32 = getelementptr i8, i8 addrspace(200)* %addr_8bit, i64 -256
   %addr_sext32 = bitcast i8 addrspace(200)* %addr8_sext32 to i16 addrspace(200)*
   %val16_sext32 = load volatile i16, i16 addrspace(200)* %addr_sext32
   %val32_signed = sext i16 %val16_sext32 to i32
   store volatile i32 %val32_signed, i32 addrspace(200)* @var_32bit
; CHECK: ldursh {{w[0-9]+}}, [{{c[0-9]+}}, #-256]

; match a zero-extending load volatile 16-bit -> 32-bit. With offset that would be unaligned.
  %addr8_zext32 = getelementptr i8, i8 addrspace(200)* %addr_8bit, i64 15
  %addr_zext32 = bitcast i8 addrspace(200)* %addr8_zext32 to i16 addrspace(200)*
  %val16_zext32 = load volatile i16, i16 addrspace(200)* %addr_zext32
  %val32_unsigned = zext i16 %val16_zext32 to i32
  store volatile i32 %val32_unsigned, i32 addrspace(200)* @var_32bit
; CHECK: ldurh {{w[0-9]+}}, [{{c[0-9]+}}, #15]

; match an any-extending load volatile 16-bit -> 32-bit
  %addr8_anyext = getelementptr i8, i8 addrspace(200)* %addr_8bit, i64 -1
  %addr_anyext = bitcast i8 addrspace(200)* %addr8_anyext to i16 addrspace(200)*
  %val16_anyext = load volatile i16, i16 addrspace(200)* %addr_anyext
  %newval16 = add i16 %val16_anyext, 1
  store volatile i16 %newval16, i16 addrspace(200)* @var_16bit
; CHECK: ldurh {{w[0-9]+}}, [{{c[0-9]+}}, #-1]

; match a sign-extending load volatile 16-bit -> 64-bit
  %addr8_sext64 = getelementptr i8, i8 addrspace(200)* %addr_8bit, i64 -5
  %addr_sext64 = bitcast i8 addrspace(200)* %addr8_sext64 to i16 addrspace(200)*
  %val16_sext64 = load volatile i16, i16 addrspace(200)* %addr_sext64
  %val64_signed = sext i16 %val16_sext64 to i64
  store volatile i64 %val64_signed, i64 addrspace(200)* @var_64bit
; CHECK: ldursh {{x[0-9]+}}, [{{c[0-9]+}}, #-5]

; match a zero-extending load volatile 16-bit -> 64-bit.
; This uses the fact that ldrb w0, [x0] will zero out the high 32-bits
; of x0 so it's identical to load volatileing to 32-bits.
  %addr8_zext64 = getelementptr i8, i8 addrspace(200)* %addr_8bit, i64 9
  %addr_zext64 = bitcast i8 addrspace(200)* %addr8_zext64 to i16 addrspace(200)*
  %val16_zext64 = load volatile i16, i16 addrspace(200)* %addr_zext64
  %val64_unsigned = zext i16 %val16_zext64 to i64
  store volatile i64 %val64_unsigned, i64 addrspace(200)* @var_64bit
; CHECK: ldurh {{w[0-9]+}}, [{{c[0-9]+}}, #9]

; truncating store volatile 32-bits to 16-bits
  %addr8_trunc32 = getelementptr i8, i8 addrspace(200)* %addr_8bit, i64 -256
  %addr_trunc32 = bitcast i8 addrspace(200)* %addr8_trunc32 to i16 addrspace(200)*
  %val32 = load volatile i32, i32 addrspace(200)* @var_32bit
  %val16_trunc32 = trunc i32 %val32 to i16
  store volatile i16 %val16_trunc32, i16 addrspace(200)* %addr_trunc32
; CHECK: sturh {{w[0-9]+}}, [{{c[0-9]+}}, #-256]

; truncating store volatile 64-bits to 16-bits
  %addr8_trunc64 = getelementptr i8, i8 addrspace(200)* %addr_8bit, i64 -1
  %addr_trunc64 = bitcast i8 addrspace(200)* %addr8_trunc64 to i16 addrspace(200)*
  %val64 = load volatile i64, i64 addrspace(200)* @var_64bit
  %val16_trunc64 = trunc i64 %val64 to i16
  store volatile i16 %val16_trunc64, i16 addrspace(200)* %addr_trunc64
; CHECK: sturh {{w[0-9]+}}, [{{c[0-9]+}}, #-1]

   ret void
}

define void @ldst_32bit(i8 addrspace(200)* %addr_8bit) {
; CHECK-LABEL: ldst_32bit:

; Straight 32-bit load/store
  %addr32_8_noext = getelementptr i8, i8 addrspace(200)* %addr_8bit, i64 1
  %addr32_noext = bitcast i8 addrspace(200)* %addr32_8_noext to i32 addrspace(200)*
  %val32_noext = load volatile i32, i32 addrspace(200)* %addr32_noext
  store volatile i32 %val32_noext, i32 addrspace(200)* %addr32_noext
; CHECK: ldur {{w[0-9]+}}, [{{c[0-9]+}}, #1]
; CHECK: stur {{w[0-9]+}}, [{{c[0-9]+}}, #1]

; Zero-extension to 64-bits
  %addr32_8_zext = getelementptr i8, i8 addrspace(200)* %addr_8bit, i64 -256
  %addr32_zext = bitcast i8 addrspace(200)* %addr32_8_zext to i32 addrspace(200)*
  %val32_zext = load volatile i32, i32 addrspace(200)* %addr32_zext
  %val64_unsigned = zext i32 %val32_zext to i64
  store volatile i64 %val64_unsigned, i64 addrspace(200)* @var_64bit
; CHECK: ldur {{w[0-9]+}}, [{{c[0-9]+}}, #-256]

; Sign-extension to 64-bits
  %addr32_8_sext = getelementptr i8, i8 addrspace(200)* %addr_8bit, i64 -12
  %addr32_sext = bitcast i8 addrspace(200)* %addr32_8_sext to i32 addrspace(200)*
  %val32_sext = load volatile i32, i32 addrspace(200)* %addr32_sext
  %val64_signed = sext i32 %val32_sext to i64
  store volatile i64 %val64_signed, i64 addrspace(200)* @var_64bit
; CHECK: ldursw {{x[0-9]+}}, [{{c[0-9]+}}, #-12]

; Truncation from 64-bits
  %addr64_8_trunc = getelementptr i8, i8 addrspace(200)* %addr_8bit, i64 255
  %addr64_trunc = bitcast i8 addrspace(200)* %addr64_8_trunc to i64 addrspace(200)*
  %addr32_8_trunc = getelementptr i8, i8 addrspace(200)* %addr_8bit, i64 -20
  %addr32_trunc = bitcast i8 addrspace(200)* %addr32_8_trunc to i32 addrspace(200)*

  %val64_trunc = load volatile i64, i64 addrspace(200)* %addr64_trunc
  %val32_trunc = trunc i64 %val64_trunc to i32
  store volatile i32 %val32_trunc, i32 addrspace(200)* %addr32_trunc
; CHECK: ldur {{x[0-9]+}}, [{{c[0-9]+}}, #255]
; CHECK: stur {{w[0-9]+}}, [{{c[0-9]+}}, #-20]

  ret void
}

define void @ldst_float(i8 addrspace(200)* %addr_8bit) {
; CHECK-LABEL: ldst_float:

  %addrfp_8 = getelementptr i8, i8 addrspace(200)* %addr_8bit, i64 -5
  %addrfp = bitcast i8 addrspace(200)* %addrfp_8 to float addrspace(200)*

  %valfp = load volatile float, float addrspace(200)* %addrfp
; CHECK: ldur {{s[0-9]+}}, [{{c[0-9]+}}, #-5]

  store volatile float %valfp, float addrspace(200)* %addrfp
; CHECK: stur {{s[0-9]+}}, [{{c[0-9]+}}, #-5]

  ret void
}

define void @ldst_double(i8 addrspace(200)* %addr_8bit) {
; CHECK-LABEL: ldst_double:

  %addrfp_8 = getelementptr i8, i8 addrspace(200)* %addr_8bit, i64 4
  %addrfp = bitcast i8 addrspace(200)* %addrfp_8 to double addrspace(200)*

  %valfp = load volatile double, double addrspace(200)* %addrfp
; CHECK: ldur {{d[0-9]+}}, [{{c[0-9]+}}, #4]

  store volatile double %valfp, double addrspace(200)* %addrfp
; CHECK: stur {{d[0-9]+}}, [{{c[0-9]+}}, #4]

   ret void
}

; CHECK-LABEL: LoadStoreCapability
define void @LoadStoreCapability(i8 addrspace(200)* addrspace(200)* %foo, i8 addrspace(200)* addrspace(200)* %res) {
entry:
; CHECK-DAG: ldr	[[B:c[0-9]+]], [c0, #0]
; CHECK-DAG: ldr	[[A:c[0-9]+]], [c0, #32]
; CHECK-DAG: stp	[[A]], [[B]], [c1, #0]
  %fptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %foo, i64 2
  %cap0 = load i8 addrspace(200) *, i8 addrspace(200)* addrspace(200)* %foo
  %cap1 = load i8 addrspace(200) *, i8 addrspace(200)* addrspace(200)* %fptr
  %tptr = getelementptr inbounds i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %res, i64 1
  store i8 addrspace(200)* %cap0, i8 addrspace(200)* addrspace(200)* %tptr, align 16
  store i8 addrspace(200)* %cap1, i8 addrspace(200)* addrspace(200)* %res, align 16
  ret void
}

define i64 @_f0_neg(i64* %p) {
; CHECK: f0_neg:
; CHECK: ldur x0, [x0, #-8]
; CHECK-NEXT: ret
  %tmp = getelementptr inbounds i64, i64* %p, i64 -1
  %ret = load i64, i64* %tmp, align 2
  ret i64 %ret
}
define i32 @_f1_neg(i32* %p) {
; CHECK: f1_neg:
; CHECK: ldur w0, [x0, #-4]
; CHECK-NEXT: ret
  %tmp = getelementptr inbounds i32, i32* %p, i64 -1
  %ret = load i32, i32* %tmp, align 2
  ret i32 %ret
}
define i16 @_f2_neg(i16* %p) {
; CHECK: f2_neg:
; CHECK: ldurh w0, [x0, #-2]
; CHECK-NEXT: ret
  %tmp = getelementptr inbounds i16, i16* %p, i64 -1
  %ret = load i16, i16* %tmp, align 2
  ret i16 %ret
}
define i8 @_f3_neg(i8* %p) {
; CHECK: f3_neg:
; CHECK: ldurb w0, [x0, #-1]
; CHECK-NEXT: ret
  %tmp = getelementptr inbounds i8, i8* %p, i64 -1
  %ret = load i8, i8* %tmp, align 2
  ret i8 %ret
}

define i64 @zext32_neg(i8* %a) nounwind ssp {
; CHECK-LABEL: zext32_neg:
; CHECK: ldur w0, [x0, #-12]
; CHECK-NEXT: ret
  %p = getelementptr inbounds i8, i8* %a, i64 -12
  %tmp1 = bitcast i8* %p to i32*
  %tmp2 = load i32, i32* %tmp1, align 4
  %ret = zext i32 %tmp2 to i64

  ret i64 %ret
}
define i64 @zext16_neg(i8* %a) nounwind ssp {
; CHECK-LABEL: zext16_neg:
; CHECK: ldurh w0, [x0, #-12]
; CHECK-NEXT: ret
  %p = getelementptr inbounds i8, i8* %a, i64 -12
  %tmp1 = bitcast i8* %p to i16*
  %tmp2 = load i16, i16* %tmp1, align 2
  %ret = zext i16 %tmp2 to i64

  ret i64 %ret
}
define i64 @zext8_neg(i8* %a) nounwind ssp {
; CHECK-LABEL: zext8_neg:
; CHECK: ldurb w0, [x0, #-12]
; CHECK-NEXT: ret
  %p = getelementptr inbounds i8, i8* %a, i64 -12
  %tmp2 = load i8, i8* %p, align 1
  %ret = zext i8 %tmp2 to i64

  ret i64 %ret
}

define i64 @_f0_pos(i64* %p) {
; CHECK: f0_pos:
; CHECK: ldur x0, [x0, #8]
; CHECK-NEXT: ret
  %tmp = getelementptr inbounds i64, i64* %p, i64 1
  %ret = load i64, i64* %tmp, align 2
  ret i64 %ret
}
define i32 @_f1_pos(i32* %p) {
; CHECK: f1_pos:
; CHECK: ldur w0, [x0, #4]
; CHECK-NEXT: ret
  %tmp = getelementptr inbounds i32, i32* %p, i64 1
  %ret = load i32, i32* %tmp, align 2
  ret i32 %ret
}
define i16 @_f2_pos(i16* %p) {
; CHECK: f2_pos:
; CHECK: ldurh w0, [x0, #2]
; CHECK-NEXT: ret
  %tmp = getelementptr inbounds i16, i16* %p, i64 1
  %ret = load i16, i16* %tmp, align 2
  ret i16 %ret
}
define i8 @_f3_pos(i8* %p) {
; CHECK: f3_pos:
; CHECK: ldurb w0, [x0, #1]
; CHECK-NEXT: ret
  %tmp = getelementptr inbounds i8, i8* %p, i64 1
  %ret = load i8, i8* %tmp, align 2
  ret i8 %ret
}

define i64 @zext32_pos(i8* %a) nounwind ssp {
; CHECK-LABEL: zext32_pos:
; CHECK: ldur w0, [x0, #12]
; CHECK-NEXT: ret
  %p = getelementptr inbounds i8, i8* %a, i64 12
  %tmp1 = bitcast i8* %p to i32*
  %tmp2 = load i32, i32* %tmp1, align 4
  %ret = zext i32 %tmp2 to i64

  ret i64 %ret
}
define i64 @zext16_pos(i8* %a) nounwind ssp {
; CHECK-LABEL: zext16_pos:
; CHECK: ldurh w0, [x0, #12]
; CHECK-NEXT: ret
  %p = getelementptr inbounds i8, i8* %a, i64 12
  %tmp1 = bitcast i8* %p to i16*
  %tmp2 = load i16, i16* %tmp1, align 2
  %ret = zext i16 %tmp2 to i64

  ret i64 %ret
}
define i64 @zext8_pos(i8* %a) nounwind ssp {
; CHECK-LABEL: zext8_pos:
; CHECK: ldurb w0, [x0, #12]
; CHECK-NEXT: ret
  %p = getelementptr inbounds i8, i8* %a, i64 12
  %tmp2 = load i8, i8* %p, align 1
  %ret = zext i8 %tmp2 to i64

  ret i64 %ret
}
