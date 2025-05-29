; RUN: llc < %s -mtriple=aarch64-none-elf -mattr=+c64,+morello -verify-machineinstrs -target-abi purecap -aarch64-enable-sandbox-globals-opt=false | FileCheck  %s

; Point of CHECK-REG is to make sure UNPREDICTABLE instructions aren't created
; (i.e. reusing a register for status & data in store exclusive).
; CHECK-REG-NOT: stlxrb w[[NEW:[0-9]+]], w[[NEW]], [x{{[0-9]+}}]
; CHECK-REG-NOT: stlxrb w[[NEW:[0-9]+]], x[[NEW]], [x{{[0-9]+}}]

@var8 = internal addrspace(200) global i8 0
@var16 = internal addrspace(200) global i16 0
@var32 = internal addrspace(200) global  i32 0
@var64 = internal addrspace(200) global  i64 0
@varfatptr = internal addrspace(200) global  ptr addrspace(200) null

define i8 @test_atomic_load_add_i8(i8 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_add_i8:
   %old = atomicrmw add ptr addrspace(200) @var8, i8 %offset seq_cst
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldaxrb w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.
; CHECK-NEXT: add w[[NEW:[0-9]+]], w[[OLD]], w0
; CHECK-NEXT: stlxrb [[STATUS:w[0-9]+]], w[[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

; CHECK: mov {{[xw]}}0, {{[xw]}}[[OLD]]
   ret i8 %old
}

define i16 @test_atomic_load_add_i16(i16 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_add_i16:
   %old = atomicrmw add ptr addrspace(200) @var16, i16 %offset acquire
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldaxrh w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.
; CHECK-NEXT: add w[[NEW:[0-9]+]], w[[OLD]], w0
; CHECK-NEXT: stxrh [[STATUS:w[0-9]+]], w[[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

; CHECK: mov {{[xw]}}0, {{[xw]}}[[OLD]]
   ret i16 %old
}

define i32 @test_atomic_load_add_i32(i32 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_add_i32:
   %old = atomicrmw add ptr addrspace(200) @var32, i32 %offset release
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldxr w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.
; CHECK-NEXT: add [[NEW:w[0-9]+]], w[[OLD]], w0
; CHECK-NEXT: stlxr [[STATUS:w[0-9]+]], [[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

; CHECK: mov {{[xw]}}0, {{[xw]}}[[OLD]]
   ret i32 %old
}

define i64 @test_atomic_load_add_i64(i64 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_add_i64:
   %old = atomicrmw add ptr addrspace(200) @var64, i64 %offset monotonic
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldxr x[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; x0 below is a reasonable guess but could change: it certainly comes into the
  ; function there.
; CHECK-NEXT: add [[NEW:x[0-9]+]], x[[OLD]], x{{.*}}
; CHECK-NEXT: stxr [[STATUS:w[0-9]+]], [[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

   ret i64 %old
}

define i8 @test_atomic_load_sub_i8(i8 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_sub_i8:
   %old = atomicrmw sub ptr addrspace(200) @var8, i8 %offset monotonic
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldxrb w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.
; CHECK-NEXT: sub w[[NEW:[0-9]+]], w[[OLD]], w0
; CHECK-NEXT: stxrb [[STATUS:w[0-9]+]], w[[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

; CHECK: mov {{[xw]}}0, {{[xw]}}[[OLD]]
   ret i8 %old
}

define i16 @test_atomic_load_sub_i16(i16 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_sub_i16:
   %old = atomicrmw sub ptr addrspace(200) @var16, i16 %offset release
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldxrh w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.
; CHECK-NEXT: sub w[[NEW:[0-9]+]], w[[OLD]], w0
; CHECK-NEXT: stlxrh [[STATUS:w[0-9]+]], w[[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

; CHECK: mov {{[xw]}}0, {{[xw]}}[[OLD]]
   ret i16 %old
}

define i32 @test_atomic_load_sub_i32(i32 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_sub_i32:
   %old = atomicrmw sub ptr addrspace(200) @var32, i32 %offset acquire
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldaxr w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.
; CHECK-NEXT: sub [[NEW:w[0-9]+]], w[[OLD]], w0
; CHECK-NEXT: stxr [[STATUS:w[0-9]+]], [[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

; CHECK: mov {{[xw]}}0, {{[xw]}}[[OLD]]
   ret i32 %old
}

define i64 @test_atomic_load_sub_i64(i64 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_sub_i64:
   %old = atomicrmw sub ptr addrspace(200) @var64, i64 %offset seq_cst
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldaxr x[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; x0 below is a reasonable guess but could change: it certainly comes into the
  ; function there.
; CHECK-NEXT: sub [[NEW:x[0-9]+]], x[[OLD]], x{{.*}}
; CHECK-NEXT: stlxr [[STATUS:w[0-9]+]], [[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

   ret i64 %old
}

define i8 @test_atomic_load_and_i8(i8 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_and_i8:
   %old = atomicrmw and ptr addrspace(200) @var8, i8 %offset release
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldxrb w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.
; CHECK-NEXT: and [[NEW:w[0-9]+]], w[[OLD]], w0
; CHECK-NEXT: stlxrb [[STATUS:w[0-9]+]], [[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

; CHECK: mov {{[xw]}}0, {{[xw]}}[[OLD]]
   ret i8 %old
}

define i16 @test_atomic_load_and_i16(i16 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_and_i16:
   %old = atomicrmw and ptr addrspace(200) @var16, i16 %offset monotonic
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldxrh w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.
; CHECK-NEXT: and [[NEW:w[0-9]+]], w[[OLD]], w0
; CHECK-NEXT: stxrh [[STATUS:w[0-9]+]], [[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

; CHECK: mov {{[xw]}}0, {{[xw]}}[[OLD]]
   ret i16 %old
}

define i32 @test_atomic_load_and_i32(i32 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_and_i32:
   %old = atomicrmw and ptr addrspace(200) @var32, i32 %offset seq_cst
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldaxr w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.
; CHECK-NEXT: and [[NEW:w[0-9]+]], w[[OLD]], w0
; CHECK-NEXT: stlxr [[STATUS:w[0-9]+]], [[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

; CHECK: mov {{[xw]}}0, {{[xw]}}[[OLD]]
   ret i32 %old
}

define i64 @test_atomic_load_and_i64(i64 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_and_i64:
   %old = atomicrmw and ptr addrspace(200) @var64, i64 %offset acquire
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldaxr x[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; x0 below is a reasonable guess but could change: it certainly comes into the
  ; function there.
; CHECK-NEXT: and [[NEW:x[0-9]+]], x[[OLD]], x{{.*}}
; CHECK-NEXT: stxr [[STATUS:w[0-9]+]], [[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

   ret i64 %old
}

define i8 @test_atomic_load_or_i8(i8 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_or_i8:
   %old = atomicrmw or ptr addrspace(200) @var8, i8 %offset seq_cst
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; ; CHECK: ldaxrb w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.
; CHECK-NEXT: orr w[[NEW:[0-9]+]], w[[OLD]], w{{.*}}
; CHECK-NEXT: stlxrb [[STATUS:w[0-9]+]], w[[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

   ret i8 %old
}

define i16 @test_atomic_load_or_i16(i16 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_or_i16:
   %old = atomicrmw or ptr addrspace(200) @var16, i16 %offset monotonic
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; ; CHECK: ldxrh w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.
; CHECK-NEXT: orr w[[NEW:[0-9]+]], w[[OLD]], w0
; CHECK-NEXT: stxrh [[STATUS:w[0-9]+]], w[[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

; CHECK: mov {{[xw]}}0, {{[xw]}}[[OLD]]
   ret i16 %old
}

define i32 @test_atomic_load_or_i32(i32 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_or_i32:
   %old = atomicrmw or ptr addrspace(200) @var32, i32 %offset acquire
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; ; CHECK: ldaxr w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.
; CHECK-NEXT: orr [[NEW:w[0-9]+]], w[[OLD]], w0
; CHECK-NEXT: stxr [[STATUS:w[0-9]+]], [[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

; CHECK: mov {{[xw]}}0, {{[xw]}}[[OLD]]
   ret i32 %old
}

define i64 @test_atomic_load_or_i64(i64 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_or_i64:
   %old = atomicrmw or ptr addrspace(200) @var64, i64 %offset release
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; ; CHECK: ldxr x[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; x0 below is a reasonable guess but could change: it certainly comes into the
  ; function there.
; CHECK-NEXT: orr [[NEW:x[0-9]+]], x[[OLD]], x{{.*}}
; CHECK-NEXT: stlxr [[STATUS:w[0-9]+]], [[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

   ret i64 %old
}

define i8 @test_atomic_load_xor_i8(i8 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_xor_i8:
   %old = atomicrmw xor ptr addrspace(200) @var8, i8 %offset acquire
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; ; CHECK: ldaxrb w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.
; CHECK-NEXT: eor w[[NEW:[0-9]+]], w[[OLD]], w0
; CHECK-NEXT: stxrb [[STATUS:w[0-9]+]], w[[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

; CHECK: mov {{[xw]}}0, {{[xw]}}[[OLD]]
   ret i8 %old
}

define i16 @test_atomic_load_xor_i16(i16 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_xor_i16:
   %old = atomicrmw xor ptr addrspace(200) @var16, i16 %offset release
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; ; CHECK: ldxrh w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.
; CHECK-NEXT: eor w[[NEW:[0-9]+]], w[[OLD]], w0
; CHECK-NEXT: stlxrh [[STATUS:w[0-9]+]], w[[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

; CHECK: mov {{[xw]}}0, {{[xw]}}[[OLD]]
   ret i16 %old
}

define i32 @test_atomic_load_xor_i32(i32 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_xor_i32:
   %old = atomicrmw xor ptr addrspace(200) @var32, i32 %offset seq_cst
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; ; CHECK: ldaxr w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.
; CHECK-NEXT: eor [[NEW:w[0-9]+]], w[[OLD]], w0
; CHECK-NEXT: stlxr [[STATUS:w[0-9]+]], [[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

; CHECK: mov {{[xw]}}0, {{[xw]}}[[OLD]]
   ret i32 %old
}

define i64 @test_atomic_load_xor_i64(i64 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_xor_i64:
   %old = atomicrmw xor ptr addrspace(200) @var64, i64 %offset monotonic
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; ; CHECK: ldxr x[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; x0 below is a reasonable guess but could change: it certainly comes into the
  ; function there.
; CHECK-NEXT: eor [[NEW:x[0-9]+]], x[[OLD]], x{{.*}}
; CHECK-NEXT: stxr [[STATUS:w[0-9]+]], [[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

   ret i64 %old
}

define i8 @test_atomic_load_xchg_i8(i8 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_xchg_i8:
   %old = atomicrmw xchg ptr addrspace(200) @var8, i8 %offset monotonic
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; ; CHECK: ldxrb [[ARG:w[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ; function there.
; CHECK-NEXT: stxrb [[STATUS:w[0-9]+]], w0, [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1

; CHECK: mov w0, [[ARG]]
; CHECK-NOT: dmb

   ret i8 %old
}

define i16 @test_atomic_load_xchg_i16(i16 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_xchg_i16:
   %old = atomicrmw xchg ptr addrspace(200) @var16, i16 %offset seq_cst
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; ; CHECK: ldaxrh [[ARG:w[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ; function there.
; CHECK-NEXT: stlxrh [[STATUS:w[0-9]+]], w0, [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb
; CHECK: mov w0, [[ARG]]

   ret i16 %old
}

define i32 @test_atomic_load_xchg_i32(i32 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_xchg_i32:
   %old = atomicrmw xchg ptr addrspace(200) @var32, i32 %offset release
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK: mov  [[ARG:w[0-9]+]], w0
; CHECK: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldxr w0, [c[[ADDR1]]]
; CHECK-NEXT: stlxr [[STATUS:w[0-9]+]], [[ARG]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb
   ret i32 %old
}

define i64 @test_atomic_load_xchg_i64(i64 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_xchg_i64:
   %old = atomicrmw xchg ptr addrspace(200) @var64, i64 %offset acquire
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldaxr x[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; x0 below is a reasonable guess but could change: it certainly comes into the
  ; function there.
; CHECK-NEXT: stxr [[STATUS:w[0-9]+]], x{{.*}}, [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

   ret i64 %old
}


define i8 @test_atomic_load_min_i8(i8 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_min_i8:
   %old = atomicrmw min ptr addrspace(200) @var8, i8 %offset acquire
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldaxrb w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.

; CHECK-NEXT: sxtb w[[OLD_EXT:[0-9]+]], w[[OLD]]
; CHECK-NEXT: cmp w[[OLD_EXT]], w0, sxtb
; CHECK-NEXT: csel w[[NEW:[0-9]+]], w[[OLD]], w0, le

; CHECK-NEXT: stxrb [[STATUS:w[0-9]+]], w[[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

; CHECK: mov {{[xw]}}0, {{[xw]}}[[OLD_EXT]]
   ret i8 %old
}

define i16 @test_atomic_load_min_i16(i16 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_min_i16:
   %old = atomicrmw min ptr addrspace(200) @var16, i16 %offset release
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldxrh w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.

; CHECK-NEXT: sxth w[[OLD_EXT:[0-9]+]], w[[OLD]]
; CHECK-NEXT: cmp w[[OLD_EXT]], w0, sxth
; CHECK-NEXT: csel w[[NEW:[0-9]+]], w[[OLD]], w0, le

; CHECK-NEXT: stlxrh [[STATUS:w[0-9]+]], w[[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

; CHECK: mov {{[xw]}}0, {{[xw]}}[[OLD_EXT]]
   ret i16 %old
}

define i32 @test_atomic_load_min_i32(i32 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_min_i32:
   %old = atomicrmw min ptr addrspace(200) @var32, i32 %offset monotonic
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldxr w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.

; CHECK-NEXT: cmp w[[OLD]], w0
; CHECK-NEXT: csel [[NEW:w[0-9]+]], w[[OLD]], w0, le

; CHECK-NEXT: stxr [[STATUS:w[0-9]+]], [[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

; CHECK: mov {{[xw]}}0, {{[xw]}}[[OLD]]
   ret i32 %old
}

define i64 @test_atomic_load_min_i64(i64 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_min_i64:
   %old = atomicrmw min ptr addrspace(200) @var64, i64 %offset seq_cst
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldaxr x[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; x0 below is a reasonable guess but could change: it certainly comes into the
  ; function there.

; CHECK-NEXT: cmp x[[OLD]], x{{.*}}
; CHECK-NEXT: csel [[NEW:x[0-9]+]], x[[OLD]], x{{.*}}, le


; CHECK-NEXT: stlxr [[STATUS:w[0-9]+]], [[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

   ret i64 %old
}

define i8 @test_atomic_load_max_i8(i8 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_max_i8:
   %old = atomicrmw max ptr addrspace(200) @var8, i8 %offset seq_cst
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldaxrb w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.

; CHECK-NEXT: sxtb w[[OLD_EXT:[0-9]+]], w[[OLD]]
; CHECK-NEXT: cmp w[[OLD_EXT]], w0, sxtb
; CHECK-NEXT: csel w[[NEW:[0-9]+]], w[[OLD]], w0, gt

; CHECK-NEXT: stlxrb [[STATUS:w[0-9]+]], w[[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

; CHECK: mov {{[xw]}}0, {{[xw]}}[[OLD_EXT]]
   ret i8 %old
}

define i16 @test_atomic_load_max_i16(i16 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_max_i16:
   %old = atomicrmw max ptr addrspace(200) @var16, i16 %offset acquire
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldaxrh w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.

; CHECK-NEXT: sxth w[[OLD_EXT:[0-9]+]], w[[OLD]]
; CHECK-NEXT: cmp w[[OLD_EXT]], w0, sxth
; CHECK-NEXT: csel w[[NEW:[0-9]+]], w[[OLD]], w0, gt


; CHECK-NEXT: stxrh [[STATUS:w[0-9]+]], w[[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

; CHECK: mov {{[xw]}}0, {{[xw]}}[[OLD_EXT]]
   ret i16 %old
}

define i32 @test_atomic_load_max_i32(i32 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_max_i32:
   %old = atomicrmw max ptr addrspace(200) @var32, i32 %offset release
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldxr w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.

; CHECK-NEXT: cmp w[[OLD]], w0
; CHECK-NEXT: csel [[NEW:w[0-9]+]], w[[OLD]], w0, gt


; CHECK-NEXT: stlxr [[STATUS:w[0-9]+]], [[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

; CHECK: mov {{[xw]}}0, {{[xw]}}[[OLD]]
   ret i32 %old
}

define i64 @test_atomic_load_max_i64(i64 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_max_i64:
   %old = atomicrmw max ptr addrspace(200) @var64, i64 %offset monotonic
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldxr x[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; x0 below is a reasonable guess but could change: it certainly comes into the
  ; function there.

; CHECK-NEXT: cmp x[[OLD]], x{{.*}}
; CHECK-NEXT: csel [[NEW:x[0-9]+]], x[[OLD]], x{{.*}}, gt


; CHECK-NEXT: stxr [[STATUS:w[0-9]+]], [[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

   ret i64 %old
}

define i8 @test_atomic_load_umin_i8(i8 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_umin_i8:
   %old = atomicrmw umin ptr addrspace(200) @var8, i8 %offset monotonic
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK:      ldxrb w0, [c[[ADDR1]]]
; CHECK-NEXT: cmp w0, w8
; CHECK-NEXT: csel w[[NEW:[0-9]+]], w0, w8,  ls

; CHECK-NEXT: stxrb [[STATUS:w[0-9]+]], w[[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb
   ret i8 %old
}

define i16 @test_atomic_load_umin_i16(i16 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_umin_i16:
   %old = atomicrmw umin ptr addrspace(200) @var16, i16 %offset acquire
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldaxrh w0, [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.

; CHECK-NEXT: cmp w0, w8
; CHECK-NEXT: csel w[[NEW:[0-9]+]], w0, w8, ls

; CHECK-NEXT: stxrh [[STATUS:w[0-9]+]], w[[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

   ret i16 %old
}

define i32 @test_atomic_load_umin_i32(i32 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_umin_i32:
   %old = atomicrmw umin ptr addrspace(200) @var32, i32 %offset seq_cst
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldaxr w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.

; CHECK-NEXT: cmp w[[OLD]], w0
; CHECK-NEXT: csel [[NEW:w[0-9]+]], w[[OLD]], w0, ls


; CHECK-NEXT: stlxr [[STATUS:w[0-9]+]], [[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

; CHECK: mov {{[xw]}}0, {{[xw]}}[[OLD]]
   ret i32 %old
}

define i64 @test_atomic_load_umin_i64(i64 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_umin_i64:
   %old = atomicrmw umin ptr addrspace(200) @var64, i64 %offset acq_rel
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldaxr x[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; x0 below is a reasonable guess but could change: it certainly comes into the
  ; function there.

; CHECK-NEXT: cmp x[[OLD]], x{{.*}}
; CHECK-NEXT: csel [[NEW:x[0-9]+]], x[[OLD]], x{{.*}}, ls


; CHECK-NEXT: stlxr [[STATUS:w[0-9]+]], [[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

   ret i64 %old
}

define i8 @test_atomic_load_umax_i8(i8 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_umax_i8:
   %old = atomicrmw umax ptr addrspace(200) @var8, i8 %offset acq_rel
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldaxrb w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.

; CHECK-NEXT: cmp w0, w8
; CHECK-NEXT: csel w[[NEW:[0-9]+]], w0, w8, hi

; CHECK-NEXT: stlxrb [[STATUS:w[0-9]+]], w[[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

   ret i8 %old
}

define i16 @test_atomic_load_umax_i16(i16 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_umax_i16:
   %old = atomicrmw umax ptr addrspace(200) @var16, i16 %offset monotonic
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldxrh w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.

; CHECK-NEXT: cmp w0, w8
; CHECK-NEXT: csel w[[NEW:[0-9]+]], w0, w8, hi

; CHECK-NEXT: stxrh [[STATUS:w[0-9]+]], w[[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

   ret i16 %old
}

define i32 @test_atomic_load_umax_i32(i32 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_umax_i32:
   %old = atomicrmw umax ptr addrspace(200) @var32, i32 %offset seq_cst
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldaxr w[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.

; CHECK-NEXT: cmp w[[OLD]], w0
; CHECK-NEXT: csel [[NEW:w[0-9]+]], w[[OLD]], w0, hi


; CHECK-NEXT: stlxr [[STATUS:w[0-9]+]], [[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

; CHECK: mov {{[xw]}}0, {{[xw]}}[[OLD]]
   ret i32 %old
}

define i64 @test_atomic_load_umax_i64(i64 %offset) nounwind {
; CHECK-LABEL: test_atomic_load_umax_i64:
   %old = atomicrmw umax ptr addrspace(200) @var64, i64 %offset release
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: .LBB{{[0-9]+}}_1:
; CHECK: ldxr x[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; x0 below is a reasonable guess but could change: it certainly comes into the
  ; function there.

; CHECK-NEXT: cmp x[[OLD]], x{{.*}}
; CHECK-NEXT: csel [[NEW:x[0-9]+]], x[[OLD]], x{{.*}}, hi


; CHECK-NEXT: stlxr [[STATUS:w[0-9]+]], [[NEW]], [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], .LBB{{[0-9]+}}_1
; CHECK-NOT: dmb

   ret i64 %old
}

define i8 @test_atomic_cmpxchg_i8(i8 %wanted, i8 %new) nounwind {
; CHECK-LABEL: test_atomic_cmpxchg_i8:
   %pair = cmpxchg ptr addrspace(200) @var8, i8 %wanted, i8 %new acquire acquire
   %old = extractvalue { i8, i1 } %pair, 0

; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: [[STARTAGAIN:.LBB[0-9]+_[0-9]+]]:
; CHECK: ldaxrb w0, [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.
; CHECK-NEXT: cmp w0, w8
; CHECK-NEXT: b.ne [[GET_OUT:.LBB[0-9]+_[0-9]+]]
; CHECK: stxrb [[STATUS:w[0-9]+]], w1, [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], [[STARTAGAIN]]
; CHECK: [[GET_OUT]]:
; CHECK: clrex
; CHECK-NOT: dmb

   ret i8 %old
}

define i16 @test_atomic_cmpxchg_i16(i16 %wanted, i16 %new) nounwind {
; CHECK-LABEL: test_atomic_cmpxchg_i16:
   %pair = cmpxchg ptr addrspace(200) @var16, i16 %wanted, i16 %new seq_cst seq_cst
   %old = extractvalue { i16, i1 } %pair, 0

; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: [[STARTAGAIN:.LBB[0-9]+_[0-9]+]]:
; CHECK: ldaxrh w0, [c[[ADDR1]]]
; CHECK-NEXT: cmp w0, w8
; CHECK-NEXT: b.ne [[GET_OUT:.LBB[0-9]+_[0-9]+]]
; CHECK: stlxrh [[STATUS:w[0-9]+]], w1, [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], [[STARTAGAIN]]
; CHECK: [[GET_OUT]]:
; CHECK: clrex
; CHECK-NOT: dmb

   ret i16 %old
}

define i32 @test_atomic_cmpxchg_i32(i32 %wanted, i32 %new) nounwind {
; CHECK-LABEL: test_atomic_cmpxchg_i32:
   %pair = cmpxchg ptr addrspace(200) @var32, i32 %wanted, i32 %new release monotonic
   %old = extractvalue { i32, i1 } %pair, 0

; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: [[STARTAGAIN:.LBB[0-9]+_[0-9]+]]:
; CHECK: ldxr w0, [c[[ADDR1]]]
; CHECK-NEXT: cmp w0, w8
; CHECK-NEXT: b.ne [[GET_OUT:.LBB[0-9]+_[0-9]+]]
; CHECK: stlxr [[STATUS:w[0-9]+]], {{w[0-9]+}}, [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], [[STARTAGAIN]]
; CHECK: [[GET_OUT]]:
; CHECK: clrex
; CHECK-NOT: dmb
   ret i32 %old
}

define void @test_atomic_cmpxchg_i64(i64 %wanted, i64 %new) nounwind {
; CHECK-LABEL: test_atomic_cmpxchg_i64:
   %pair = cmpxchg ptr addrspace(200) @var64, i64 %wanted, i64 %new monotonic monotonic
   %old = extractvalue { i64, i1 } %pair, 0

; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: [[STARTAGAIN:.LBB[0-9]+_[0-9]+]]:
; CHECK: ldxr x[[OLD:[0-9]+]], [c[[ADDR1]]]
  ; w0 below is a reasonable guess but could change: it certainly comes into the
  ;  function there.
; CHECK-NEXT: cmp x[[OLD]], x0
; CHECK-NEXT: b.ne [[GET_OUT:.LBB[0-9]+_[0-9]+]]
  ; As above, w1 is a reasonable guess.
; CHECK: stxr [[STATUS:w[0-9]+]], x1, [c[[ADDR1]]]
; CHECK-NEXT: cbnz [[STATUS]], [[STARTAGAIN]]
; CHECK: [[GET_OUT]]:
; CHECK: clrex
; CHECK-NOT: dmb

; CHECK: str x[[OLD]],
   store i64 %old, ptr addrspace(200) @var64
   ret void
}

define i8 @test_atomic_load_monotonic_i8() nounwind {
; CHECK-LABEL: test_atomic_load_monotonic_i8:
  %val = load atomic i8, ptr addrspace(200) @var8 monotonic, align 1
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]

; CHECK: ldrb   w0
; CHECK-NOT: dmb

  ret i8 %val
}

define i8 @test_atomic_load_monotonic_regoff_i8(i64 %base, i64 %off) nounwind {
; CHECK-LABEL: test_atomic_load_monotonic_regoff_i8:
  %addr_int = add i64 %base, %off
  %addr = inttoptr i64 %addr_int to ptr addrspace(200)

  %val = load atomic i8, ptr addrspace(200) %addr monotonic, align 1
; CHECK-NOT: dmb

; CHECK: add x[[ADDR:[0-9]+]], x0, x1

; CHECK: ldrb w0,
; CHECK-NOT: dmb

  ret i8 %val
}

define i8 @test_atomic_load_acquire_i8() nounwind {
; CHECK-LABEL: test_atomic_load_acquire_i8:
  %val = load atomic i8, ptr addrspace(200) @var8 acquire, align 1
; CHECK-NOT: dmb
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NOT: dmb
; CHECK-NEXT: ldr c[[ADDR:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]
; CHECK-NOT: dmb
; CHECK: ldarb w0, [c[[ADDR]]]
; CHECK-NOT: dmb
  ret i8 %val
}

define i8 @test_atomic_load_seq_cst_i8() nounwind {
; CHECK-LABEL: test_atomic_load_seq_cst_i8:
  %val = load atomic i8, ptr addrspace(200) @var8 seq_cst, align 1
; CHECK-NOT: dmb
; CHECK: adrp c[[HIADDR:[0-9]+]]
; CHECK-NOT: dmb
; CHECK-NOT: dmb
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[HIADDR]], {{#?}}:lo12:{{.*}}]
; CHECK: ldarb w0, [c[[ADDR1]]]
; CHECK-NOT: dmb
  ret i8 %val
}

define i16 @test_atomic_load_monotonic_i16() nounwind {
; CHECK-LABEL: test_atomic_load_monotonic_i16:
  %val = load atomic i16, ptr addrspace(200) @var16 monotonic, align 2
; CHECK-NOT: dmb
; CHECK: adrp c[[HIADDR:[0-9]+]]
; CHECK-NOT: dmb
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[HIADDR]], {{#?}}:lo12:{{.*}}]
; CHECK: ldrh w0, [c[[ADDR1]]]
; CHECK-NOT: dmb

  ret i16 %val
}

define i32 @test_atomic_load_monotonic_regoff_i32(ptr addrspace(200) %base, i64 %off) nounwind {
; CHECK-LABEL: test_atomic_load_monotonic_regoff_i32:
  %addr = getelementptr i8, ptr addrspace(200) %base, i64 %off

  %val = load atomic i32, ptr addrspace(200) %addr monotonic, align 4
; CHECK-NOT: dmb
; CHECK: ldr w0, [c0, x1]
; CHECK-NOT: dmb

  ret i32 %val
}

define i64 @test_atomic_load_seq_cst_i64() nounwind {
; CHECK-LABEL: test_atomic_load_seq_cst_i64:
  %val = load atomic i64, ptr addrspace(200) @var64 seq_cst, align 8
; CHECK-NOT: dmb
; CHECK: adrp c[[HIADDR:[0-9]+]]
; CHECK-NOT: dmb
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[HIADDR]], {{#?}}:lo12:{{.*}}]
; CHECK: ldar x0, [c[[ADDR1]]]
; CHECK-NOT: dmb
  ret i64 %val
}

define void @test_atomic_store_monotonic_i8(i8 %val) nounwind {
; CHECK-LABEL: test_atomic_store_monotonic_i8:
  store atomic i8 %val, ptr addrspace(200) @var8 monotonic, align 1
; CHECK: adrp c[[HIADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[HIADDR]], {{#?}}:lo12:{{.*}}]
; CHECK: strb w0, [c[[ADDR1]]]

  ret void
}

define void @test_atomic_store_monotonic_regoff_i8(ptr addrspace(200) %base, i64 %off, i8 %val) nounwind {
; CHECK-LABEL: test_atomic_store_monotonic_regoff_i8:
  %addr = getelementptr i8, ptr addrspace(200) %base, i64 %off

  store atomic i8 %val, ptr addrspace(200) %addr monotonic, align 1
; CHECK: strb w2, [c[[ADDR]], x1]

  ret void
}
define void @test_atomic_store_release_i8(i8 %val) nounwind {
; CHECK-LABEL: test_atomic_store_release_i8:
  store atomic i8 %val, ptr addrspace(200) @var8 release, align 1
; CHECK-NOT: dmb
; CHECK: adrp c[[HIADDR:[0-9]+]] 
; CHECK-NOT: dmb
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[HIADDR]], {{#?}}:lo12:{{.*}}]
; CHECK: stlrb w0, [c[[ADDR1]]]
; CHECK-NOT: dmb
  ret void
}

define void @test_atomic_store_seq_cst_i8(i8 %val) nounwind {
; CHECK-LABEL: test_atomic_store_seq_cst_i8:
  store atomic i8 %val, ptr addrspace(200) @var8 seq_cst, align 1
; CHECK-NOT: dmb
; CHECK: adrp c[[HIADDR:[0-9]+]]
; CHECK-NOT: dmb
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[HIADDR]], {{#?}}:lo12:{{.*}}]
; CHECK: stlrb w0, [c[[ADDR1]]]
; CHECK-NOT: dmb

  ret void
}

define void @test_atomic_store_monotonic_i16(i16 %val) nounwind {
; CHECK-LABEL: test_atomic_store_monotonic_i16:
  store atomic i16 %val, ptr addrspace(200) @var16 monotonic, align 2
; CHECK-NOT: dmb
; CHECK: adrp c[[HIADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[HIADDR]], {{#?}}:lo12:{{.*}}]
; CHECK: strh w0, [c[[ADDR1]]]
; CHECK-NOT: dmb
  ret void
}

define void @test_atomic_store_monotonic_regoff_i32(ptr addrspace(200) %base, i64 %off, i32 %val) nounwind {
; CHECK-LABEL: test_atomic_store_monotonic_regoff_i32:
  %addr = getelementptr i8, ptr addrspace(200) %base, i64 %off

  store atomic i32 %val, ptr addrspace(200) %addr monotonic, align 4
; CHECK-NOT: dmb
; CHECK: str w2, [c0, x1]
; CHECK-NOT: dmb

  ret void
}

define void @test_atomic_store_release_i64(i64 %val) nounwind {
; CHECK-LABEL: test_atomic_store_release_i64:
  store atomic i64 %val, ptr addrspace(200) @var64 release, align 8
; CHECK-NOT: dmb
; CHECK: adrp c[[HIADDR:[0-9]+]]
; CHECK-NOT: dmb
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[HIADDR]], {{#?}}:lo12:{{.*}}]
; CHECK: stlr x0, [c[[ADDR1]]]
; CHECK-NOT: dmb
  ret void
}

define ptr addrspace(200) @test_atomic_load_acquire_fatptr() nounwind {
; CHECK-LABEL: test_atomic_load_acquire_fatptr:
  %val = load atomic ptr addrspace(200), ptr addrspace(200) @varfatptr acquire, align 16
; CHECK: adrp c[[TMPADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR:[0-9]+]], [c[[TMPADDR]], {{#?}}:lo12:{{.*}}]
; CHECK-NEXT: ldar c0, [c[[ADDR]]]
  ret ptr addrspace(200) %val
}

define void @test_atomic_store_release_fatptr(ptr addrspace(200) %val) nounwind {
; CHECK-LABEL: test_atomic_store_release_fatptr:
  store atomic ptr addrspace(200) %val, ptr addrspace(200) @varfatptr release, align 16
; CHECK: adrp c[[HIADDR:[0-9]+]]
; CHECK-NEXT: ldr c[[ADDR1:[0-9]+]], [c[[HIADDR]], {{#?}}:lo12:{{.*}}]
; CHECK-NEXT: stlr c0, [c[[ADDR1]]]
  ret void
}

define ptr addrspace(200) @test_atomic_monotoic_cap_load(ptr addrspace(200) %val) nounwind {
; CHECK-LABEL: test_atomic_monotoic_cap_load:
; CHECK: ldur c0, [c0, #-16]
 %adr = getelementptr ptr addrspace(200), ptr addrspace(200) %val, i32 -1
 %ret = load atomic ptr addrspace(200), ptr addrspace(200) %adr monotonic, align 16
 ret ptr addrspace(200) %ret
}

define ptr addrspace(200) @test_atomic_monotoic_32idx_cap_load(ptr addrspace(200) %val, i32 %idx) nounwind {
; CHECK-LABEL: test_atomic_monotoic_32idx_cap_load:
; CHECK: ldr c0, [c0, w1, sxtw #4]
 %adr = getelementptr ptr addrspace(200), ptr addrspace(200) %val, i32 %idx
 %ret = load atomic ptr addrspace(200), ptr addrspace(200) %adr monotonic, align 16
 ret ptr addrspace(200) %ret
}

define ptr addrspace(200) @test_atomic_monotoic_64idx_cap_load(ptr addrspace(200) %val, i64 %idx) nounwind {
; CHECK-LABEL: test_atomic_monotoic_64idx_cap_load:
; CHECK: ldr c0, [c0, x1, lsl #4]
 %adr = getelementptr ptr addrspace(200), ptr addrspace(200) %val, i64 %idx
 %ret = load atomic ptr addrspace(200), ptr addrspace(200) %adr monotonic, align 16
 ret ptr addrspace(200) %ret
}

define void @test_atomic_monotoic_cap_store(ptr addrspace(200) %val, ptr addrspace(200) %st) nounwind {
; CHECK-LABEL: test_atomic_monotoic_cap_store:
; CHECK: stur c1, [c0, #-16]
 %adr = getelementptr ptr addrspace(200), ptr addrspace(200) %val, i32 -1
 store atomic ptr addrspace(200) %st, ptr addrspace(200) %adr monotonic, align 16
 ret void
}

define void @test_atomic_monotoic_32idx_cap_store(ptr addrspace(200) %val, i32 %idx, ptr addrspace(200) %st) nounwind {
; CHECK-LABEL: test_atomic_monotoic_32idx_cap_store:
; CHECK: str c2, [c0, w1, sxtw #4]
 %adr = getelementptr ptr addrspace(200), ptr addrspace(200) %val, i32 %idx
 store atomic ptr addrspace(200) %st, ptr addrspace(200) %adr monotonic, align 16
 ret void
}

define void @test_atomic_monotoic_64idx_cap_store(ptr addrspace(200) %val, i64 %idx, ptr addrspace(200) %st) nounwind {
; CHECK-LABEL: test_atomic_monotoic_64idx_cap_store:
; CHECK: str c2, [c0, x1, lsl #4]
 %adr = getelementptr ptr addrspace(200), ptr addrspace(200) %val, i64 %idx
 store atomic ptr addrspace(200) %st, ptr addrspace(200) %adr monotonic, align 16
 ret void
}
