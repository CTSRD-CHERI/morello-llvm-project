; RUN: llc -emulated-tls -mtriple=aarch64-linux-android -mattr=+c64,+morello -target-abi=purecap < %s | FileCheck %s

; Copied from AArch64/emutls.ll

; Use my_emutls_get_address like __emutls_get_address.
@my_emutls_v_xyz = external addrspace(200) global i8, align 4
declare ptr addrspace(200) @my_emutls_get_address(ptr addrspace(200))

define i32 @my_get_xyz() {
; CHECK-LABEL: my_get_xyz:
; CHECK:        adrp c[[ADDR:[0-9]+]], :got:my_emutls_v_xyz
; CHECK-NEXT:   ldr c0, [c[[ADDR]], :got_lo12:my_emutls_v_xyz]
; CHECK-NEXT:   bl my_emutls_get_address
; CHECK-NEXT:   ldr w0, [c0]
; CHECK-NEXT:   ldr c30, [csp], #16

entry:
  %call = call ptr addrspace(200) @my_emutls_get_address(ptr addrspace(200) @my_emutls_v_xyz)
  %0 = load i32, ptr addrspace(200) %call, align 4
  ret i32 %0
}

@i1 = thread_local addrspace(200) global i32 15
@i2 = external thread_local addrspace(200) global i32
@i3 = internal thread_local addrspace(200) global i32 15
@i4 = hidden thread_local addrspace(200) global i32 15
@i5 = external hidden thread_local addrspace(200) global i32
@s1 = thread_local addrspace(200) global i16 15
@b1 = thread_local addrspace(200) global i8 0

define i32 @f1() {
; CHECK-LABEL: f1:
; CHECK:        ldr c0, [c[[ADDR]], :got_lo12:__emutls_v.i1]
; CHECK-NEXT:   bl __emutls_get_address
; CHECK-NEXT:   ldr w0, [c0]
; CHECK-NEXT:   ldr c30, [csp], #16

entry:
  %tmp1 = load i32, ptr addrspace(200) @i1
  ret i32 %tmp1
}

define ptr addrspace(200) @f2() {
; CHECK-LABEL: f2:
; CHECK:        adrp c[[ADDR:[0-9]+]], :got:__emutls_v.i1
; CHECK-NEXT:   ldr c0, [c[[ADDR]], :got_lo12:__emutls_v.i1]
; CHECK-NEXT:   bl __emutls_get_address
; CHECK-NEXT:   ldr c30, [csp], #16

entry:
  ret ptr addrspace(200) @i1
}

; CHECK-LABEL: .LCPI3_0
; CHECK-NEXT: .chericap __emutls_v.i3

define i32 @f5() nounwind {
; CHECK-LABEL: f5:
; CHECK:        adrp c[[ADDR:[0-9]+]], .LCPI3_0
; CHECK-NEXT:   ldr c0, [c[[ADDR]], :lo12:.LCPI3_0]
; CHECK-NEXT:   bl __emutls_get_address
; CHECK-NEXT:   ldr w0, [c0]
; CHECK-NEXT:   ldr c30, [csp], #16

entry:
  %tmp1 = load i32, ptr addrspace(200) @i3
  ret i32 %tmp1
}

; CHECK-LABEL: .LCPI4_0
; CHECK-NEXT: .chericap __emutls_v.i3

define ptr addrspace(200) @f6() {
; CHECK-LABEL: f6:
; CHECK:        adrp c[[ADDR:[0-9]+]], .LCPI4_0
; CHECK-NEXT:   ldr c0, [c[[ADDR]], :lo12:.LCPI4_0]
; CHECK-NEXT:   bl __emutls_get_address
; CHECK-NEXT:   ldr c30, [csp], #16

entry:
  ret ptr addrspace(200) @i3
}

; Simple test of comdat __thread variables.
; template <class T> struct A { static __thread T x; };
; template <class T> T __thread A<T>::x;
; int getIntX() { return A<int>::x++; }
; float getFloatX() { return A<float>::x++; }

$_ZN1AIiE1xE = comdat any
$_ZN1AIfE1xE = comdat any
@_ZN1AIiE1xE = linkonce_odr thread_local addrspace(200) global i32 0, comdat, align 4
@_ZN1AIfE1xE = linkonce_odr thread_local addrspace(200) global float 0.000000e+00, comdat, align 4

define i32 @_Z7getIntXv() {
; CHECK-LABEL: _Z7getIntXv:
; CHECK:        adrp c[[ADDR:[0-9]+]], :got:__emutls_v._ZN1AIiE1xE
; CHECK-NEXT:   ldr c0, [c[[ADDR]], :got_lo12:__emutls_v._ZN1AIiE1xE]
; CHECK-NEXT:   bl __emutls_get_address
; CHECK-NEXT:   mov c1, c0
; CHECK-NEXT:   ldr {{.*}}, [c0]
; CHECK:        add
; CHECK:        str {{.*}}, [c1]

entry:
  %0 = load i32, ptr addrspace(200) @_ZN1AIiE1xE, align 4
  %inc = add nsw i32 %0, 1
  store i32 %inc, ptr addrspace(200) @_ZN1AIiE1xE, align 4
  ret i32 %0
}

define float @_Z9getFloatXv() {
; CHECK-LABEL: _Z9getFloatXv:
; CHECK:        adrp c[[ADDR:[0-9]+]], :got:__emutls_v._ZN1AIfE1xE
; CHECK-NEXT:   ldr c0, [c[[ADDR]], :got_lo12:__emutls_v._ZN1AIfE1xE]
; CHECK-NEXT:   bl __emutls_get_address
; CHECK-NEXT:   fmov
; CHECK-NEXT:   ldr {{.*}}, [c0]
; CHECK:        fadd s{{.*}}, s
; CHECK:        str {{.*}}, [c0]

entry:
  %0 = load float, ptr addrspace(200) @_ZN1AIfE1xE, align 4
  %inc = fadd float %0, 1.000000e+00
  store float %inc, ptr addrspace(200) @_ZN1AIfE1xE, align 4
  ret float %0
}


;;;;;;;;;;;;;; __emutls_v. and __emutls_t.

; CHECK:      .data{{$}}
; CHECK:      .globl __emutls_v.i1
; CHECK-LABEL: __emutls_v.i1:
; CHECK-NEXT: .xword 4
; CHECK-NEXT: .xword 4
; CHECK-NEXT: .chericap 0
; CHECK-NEXT: .chericap __emutls_t.i1

; CHECK:      .section .rodata,
; CHECK-LABEL: __emutls_t.i1:
; CHECK-NEXT: .word 15

; CHECK-NOT:   __emutls_v.i2

; CHECK:      .data{{$}}
; CHECK-NOT:  .globl
; CHECK-LABEL: __emutls_v.i3:
; CHECK-NEXT: .xword 4
; CHECK-NEXT: .xword 4
; CHECK-NEXT: .chericap 0
; CHECK-NEXT: .chericap __emutls_t.i3

; CHECK:      .section .rodata,
; CHECK-LABEL: __emutls_t.i3:
; CHECK-NEXT: .word 15

; CHECK:      .hidden __emutls_v.i4
; CHECK:      .data{{$}}
; CHECK:      .globl __emutls_v.i4
; CHECK-LABEL: __emutls_v.i4:
; CHECK-NEXT: .xword 4
; CHECK-NEXT: .xword 4
; CHECK-NEXT: .chericap 0
; CHECK-NEXT: .chericap __emutls_t.i4


; CHECK:      .section .rodata,
; CHECK-LABEL: __emutls_t.i4:
; CHECK-NEXT: .word 15

; CHECK-NOT:   __emutls_v.i5:
; CHECK:      .hidden __emutls_v.i5
; CHECK-NOT:   __emutls_v.i5:

; CHECK:      .data{{$}}
; CHECK:      .globl __emutls_v.s1
; CHECK-LABEL: __emutls_v.s1:
; CHECK-NEXT: .xword 2
; CHECK-NEXT: .xword 2
; CHECK-NEXT: .chericap 0
; CHECK-NEXT: .chericap __emutls_t.s1

; CHECK:      .section .rodata,
; CHECK-LABEL: __emutls_t.s1:
; CHECK-NEXT: .hword 15

; CHECK:      .data{{$}}
; CHECK-LABEL: __emutls_v.b1:
; CHECK-NEXT: .xword 1
; CHECK-NEXT: .xword 1
; CHECK-NEXT: .chericap 0
; CHECK-NEXT: .chericap 0

; CHECK-NOT:   __emutls_t.b1

; CHECK:      .section .data.__emutls_v._ZN1AIiE1xE,{{.*}},__emutls_v._ZN1AIiE1xE,comdat
; CHECK:      .weak __emutls_v._ZN1AIiE1xE
; CHECK:      .p2align 4
; CHECK-LABEL: __emutls_v._ZN1AIiE1xE:
; CHECK-NEXT: .xword 4
; CHECK-NEXT: .xword 4
; CHECK-NEXT: .chericap 0
; CHECK-NEXT: .chericap 0

; CHECK:      .section .data.__emutls_v._ZN1AIfE1xE,{{.*}},__emutls_v._ZN1AIfE1xE,comdat
; CHECK:      .weak __emutls_v._ZN1AIfE1xE
; CHECK:      .p2align 4
; CHECK-LABEL: __emutls_v._ZN1AIfE1xE:
; CHECK-NEXT: .xword 4
; CHECK-NEXT: .xword 4
; CHECK-NEXT: .chericap 0
; CHECK-NEXT: .chericap __emutls_t._ZN1AIfE1xE


; CHECK:      .section .rodata.__emutls_t._ZN1AIfE1xE,{{.*}},__emutls_t._ZN1AIfE1xE,comdat
; CHECK:      .weak __emutls_t._ZN1AIfE1xE
; CHECK:      .p2align 2
; CHECK-LABEL: __emutls_t._ZN1AIfE1xE:
; CHECK-NEXT: .word 0
; CHECK-NEXT: .size
