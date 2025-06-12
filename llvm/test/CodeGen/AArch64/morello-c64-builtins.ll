; RUN: llc -mtriple=arm64 -mattr=+morello,+c64 -target-abi purecap -o - %s | FileCheck %s

; CHECK-LABEL: @testBuiltinsWithGPROutput
define i64 @testBuiltinsWithGPROutput(ptr addrspace(200) %foo, ptr addrspace(200) %bar) {
entry:
; CHECK-DAG: gclen	{{x[0-9]+}}, c0
  %0 = call i64 @llvm.cheri.cap.length.get(ptr addrspace(200) %foo)
; CHECK-DAG: gcperm	{{x[0-9]+}}, c0
  %1 = call i64 @llvm.cheri.cap.perms.get(ptr addrspace(200) %foo)
  %and1 = and i64 %0, %1
; CHECK-DAG: gctype	{{x[0-9]+}}, c0
  %2 = call i64 @llvm.cheri.cap.type.get(ptr addrspace(200) %foo)
  %and2 = and i64 %and1, %2
; CHECK-DAG: gctag	{{x[0-9]+}}, c0
  %3 = call i1 @llvm.cheri.cap.tag.get(ptr addrspace(200) %foo)
  %zext3 = zext i1 %3 to i64
  %and3 = and i64 %and2, %zext3
; CHECK-DAG: gcseal	{{x[0-9]+}}, c0
  %4 = call i1 @llvm.cheri.cap.sealed.get(ptr addrspace(200) %foo)
  %zext4 = zext i1 %4 to i64
  %and4 = and i64 %and3, %zext4
; CHECK-DAG: gcbase	{{x[0-9]+}}, c0
  %5 = call i64 @llvm.cheri.cap.base.get(ptr addrspace(200) %foo)
  %and7 = and i64 %and4, %5
; CHECK-DAG: gcoff	{{x[0-9]+}}, c0
  %6 = call i64 @llvm.cheri.cap.offset.get(ptr addrspace(200) %foo)
  %and8 = and i64 %and7, %6
; CHECK-DAG: rrlen	{{x[0-9]+}}, {{x[0-9]+}}
  %7 = call i64 @llvm.morello.round.representable.length.inexact.i64(i64 42)
  %and9 =  and i64 %and8, %7
; CHECK-DAG: rrmask	{{x[0-9]+}}, {{x[0-9]+}}
  %8 = call i64 @llvm.morello.representable.alignment.mask.inexact.i64(i64 42)
  %and10 =  and i64 %and9, %8
; CHECK-DAG: cfhi	{{x[0-9]+}}, c0
  %9 = call i64 @llvm.cheri.cap.copy.from.high.i64(ptr addrspace(200) %foo)
  %and11 =  and i64 %and10, %9
; CHECK-DAG: cvt       {{x[0-9]+}}, c0, c1
  %10 = call i64 @llvm.morello.convert.to.ptr(ptr addrspace(200) %foo, ptr addrspace(200) %bar)
  %and12 = and i64 %and11, %10
  ret i64 %and12
}

; CHECK-LABEL: testRepresentableLength
define i64 @testRepresentableLength(i64 %foo) {
; CHECK:      sub    [[foo_sub_1:x[0-9]+]], x0, #1
; CHECK-NEXT: rrlen  [[rrlen_foo:x[0-9]+]], x0
; CHECK-NEXT: rrlen  [[rrlen_foo_sub_1:x[0-9]+]], [[foo_sub_1]]
; CHECK-NEXT: cmp    [[rrlen_foo_sub_1]], x0
; CHECK-NEXT: csel   x0, x0, [[rrlen_foo]]
  %1 = call i64 @llvm.cheri.round.representable.length.i64(i64 %foo)
  ret i64 %1
}

; CHECK-LABEL: testRepresentableMask
define i64 @testRepresentableMask(i64 %foo) {
; CHECK:      sub    [[foo_sub_1:x[0-9]+]], x0, #1
; CHECK-NEXT: cmp    x0, #0
; CHECK-NEXT: rrlen  [[rrlen_foo_sub_1:x[0-9]+]], [[foo_sub_1]]
; CHECK-NEXT: ccmp   [[rrlen_foo_sub_1]], x0, #0, ne
; CHECK-NEXT: csel   [[selected:x[0-9]+]], [[foo_sub_1]], x0, eq
; CHECK-NEXT: rrmask x0, [[selected]]
  %1 = call i64 @llvm.cheri.representable.alignment.mask.i64(i64 %foo)
  ret i64 %1
}

; CHECK-LABEL: testEqualityCheck
define i32 @testEqualityCheck(ptr addrspace(200) %foo, ptr addrspace(200) %bar, i32 %val) {
; CHECK:      chkeq  c0, c1
; CHECK-NEXT: cset   [[reg:w[0-9]+]], eq
; CHECK-NEXT: and    {{w[0-9]+}}, [[reg]], w2
  %1 = call i1 @llvm.cheri.cap.equal.exact(ptr addrspace(200) %foo, ptr addrspace(200) %bar)
  %2 = zext i1 %1 to i32
  %3 = and i32 %2, %val
  ret i32 %3
}

; CHECK-LABEL: testSubsetCheck
define i16 @testSubsetCheck(ptr addrspace(200) %foo, ptr addrspace(200) %bar, i16 %val) {
; CHECK:      chkss  c0, c1
; CHECK-NEXT: cset   [[reg:w[0-9]+]], mi
; CHECK-NEXT: orr    {{w[0-9]+}}, [[reg]], w2
  %1 = call i1 @llvm.cheri.cap.subset.test(ptr addrspace(200) %foo, ptr addrspace(200) %bar)
  %2 = zext i1 %1 to i16
  %3 = or i16 %2, %val
  ret i16 %3
}

declare i64 @llvm.cheri.cap.length.get(ptr addrspace(200))
declare i64 @llvm.cheri.cap.perms.get(ptr addrspace(200))
declare i64 @llvm.cheri.cap.type.get(ptr addrspace(200))
declare i1 @llvm.cheri.cap.tag.get(ptr addrspace(200))
declare i1 @llvm.cheri.cap.sealed.get(ptr addrspace(200))
declare i64 @llvm.cheri.cap.base.get(ptr addrspace(200))
declare i64 @llvm.cheri.cap.offset.get(ptr addrspace(200))
declare i64 @llvm.cheri.cap.flags.get(ptr addrspace(200))
declare i64 @llvm.cheri.round.representable.length.i64(i64)
declare i64 @llvm.cheri.representable.alignment.mask.i64(i64)
declare i64 @llvm.cheri.cap.copy.from.high.i64(ptr addrspace(200))
declare i1 @llvm.cheri.cap.equal.exact(ptr addrspace(200), ptr addrspace(200))
declare i1 @llvm.cheri.cap.subset.test(ptr addrspace(200), ptr addrspace(200))
declare i64 @llvm.morello.round.representable.length.inexact.i64(i64)
declare i64 @llvm.morello.representable.alignment.mask.inexact.i64(i64)
declare i64 @llvm.morello.convert.to.ptr(ptr addrspace(200), ptr addrspace(200))

; CHECK-LABEL: @testBuiltinsWithCapabilityOutput
define ptr addrspace(200) @testBuiltinsWithCapabilityOutput(ptr addrspace(200) %foo) {
entry:
; CHECK: clrperm	[[C0:c[0-9]+]], c0, {{x[0-9]+}}
; CHECK: seal	[[C1:c[0-9]+]], c0, [[C0]]
; CHECK: unseal	[[C2:c[0-9]+]], c0, [[C1]]
; CHECK: scbnds	[[C3:c[0-9]+]], [[C2]], #42
; CHECK: clrtag	[[C4:c[0-9]+]], [[C3]]
; CHECK: scoff	[[C5:c[0-9]+]], [[C4]], {{x[0-9]+}}
; CHECK: scbnds	[[C3:c[0-9]+]], [[C2]], #11
; CHECK: cthi	[[C8:c[0-9]+]], [[C3]], {{x[0-9]+}}
; CHECK: chkssu [[C9:c[0-9]+]], [[C8]], c0
; CHECK: csel   [[C10:c[0-9]+]], [[C9]], czr, mi
; CHECK: cvtz   [[C11:c[0-9]+]], [[C10]], {{x[0-9]+}}
  %C0 = call ptr addrspace(200) @llvm.cheri.cap.perms.and(ptr addrspace(200) %foo, i64 12)
  %C1 = call ptr addrspace(200) @llvm.cheri.cap.seal(ptr addrspace(200) %foo, ptr addrspace(200) %C0)
  %C2 = call ptr addrspace(200) @llvm.cheri.cap.unseal(ptr addrspace(200) %foo, ptr addrspace(200) %C1)
  %C3 = call ptr addrspace(200) @llvm.cheri.cap.bounds.set(ptr addrspace(200) %C2, i64 42)
  %C4 = call ptr addrspace(200) @llvm.cheri.cap.tag.clear(ptr addrspace(200) %C3)
  %C5 = call ptr addrspace(200) @llvm.cheri.cap.offset.set(ptr addrspace(200) %C4, i64 22)
  %C6 = call ptr addrspace(200) @llvm.cheri.cap.bounds.set.exact(ptr addrspace(200) %C5, i64 11)
  %C7 = call ptr addrspace(200) @llvm.cheri.cap.copy.to.high.i64(ptr addrspace(200) %C6, i64 19)
  %C8 = call {ptr addrspace(200), i1} @llvm.morello.subset.test.unseal(ptr addrspace(200) %C7, ptr addrspace(200) %foo)
  %C9 = extractvalue {ptr addrspace(200), i1} %C8, 0
  %C10 = extractvalue {ptr addrspace(200), i1} %C8, 1
  %C11 = select i1 %C10, ptr addrspace(200) %C9, ptr addrspace(200) null
  %C12 = call ptr addrspace(200) @llvm.morello.convert.to.offset.null.cap.zero.semantics(ptr addrspace(200) %C11, i64 4096)
  ret ptr addrspace(200) %C12
}

declare ptr addrspace(200) @llvm.cheri.cap.perms.and(ptr addrspace(200), i64)
declare ptr addrspace(200) @llvm.cheri.cap.seal(ptr addrspace(200), ptr addrspace(200))
declare ptr addrspace(200) @llvm.cheri.cap.unseal(ptr addrspace(200), ptr addrspace(200))
declare ptr addrspace(200) @llvm.cheri.cap.bounds.set(ptr addrspace(200), i64)
declare ptr addrspace(200) @llvm.cheri.cap.bounds.set.exact(ptr addrspace(200), i64)
declare ptr addrspace(200) @llvm.cheri.bounded.stack.cap(ptr addrspace(200), i64)
declare ptr addrspace(200) @llvm.cheri.cap.tag.clear(ptr addrspace(200))
declare ptr addrspace(200) @llvm.cheri.cap.offset.set(ptr addrspace(200), i64)
declare ptr addrspace(200) @llvm.cheri.cap.flags.set(ptr addrspace(200), i64)
declare ptr addrspace(200) @llvm.cheri.cap.copy.to.high.i64(ptr addrspace(200), i64)
declare {ptr addrspace(200), i1} @llvm.morello.subset.test.unseal(ptr addrspace(200), ptr addrspace(200))
declare ptr addrspace(200) @llvm.morello.convert.to.offset.null.cap.zero.semantics(ptr addrspace(200), i64)

; CHECK-LABEL: testBoundedStackCapImm
define ptr addrspace(200) @testBoundedStackCapImm(ptr addrspace(200) %foo) {
; CHECK: scbnds c0, c0, #11
  %C = call ptr addrspace(200) @llvm.cheri.bounded.stack.cap(ptr addrspace(200) %foo, i64 11)
  ret ptr addrspace(200) %C
}

; CHECK-LABEL: testBoundedStackCapReg
define ptr addrspace(200) @testBoundedStackCapReg(ptr addrspace(200) %foo, i64 %val) {
; CHECK: scbnds c0, c0, x1
  %C = call ptr addrspace(200) @llvm.cheri.bounded.stack.cap(ptr addrspace(200) %foo, i64 %val)
  ret ptr addrspace(200) %C
}

; CHECK-LABEL: @testGetProgramCounter
define ptr addrspace(200) @testGetProgramCounter() {
entry:
; CHECK: adr	c0, #0
  %PCC = call ptr addrspace(200) @llvm.cheri.pcc.get()
  ret ptr addrspace(200) %PCC
}

declare ptr addrspace(200) @llvm.cheri.pcc.get()

; CHECK-LABEL: @testGetCapFromPointer
define ptr addrspace(200) @testGetCapFromPointer(ptr addrspace(200) %gcap, i64 %p) {
entry:
; CHECK: cvt	c0, c0, x1
  %cap = call ptr addrspace(200) @llvm.cheri.cap.from.pointer.nonnull.zero(ptr addrspace(200) %gcap, i64 %p);
  ret ptr addrspace(200) %cap
}

; CHECK-LABEL: @testGetCapFromPointerNullZero
define ptr addrspace(200) @testGetCapFromPointerNullZero(ptr addrspace(200) %gcap, i64 %p) {
entry:
; CHECK: cvtz	c0, c0, x1
  %cap = call ptr addrspace(200) @llvm.cheri.cap.from.pointer(ptr addrspace(200) %gcap, i64 %p);
  ret ptr addrspace(200) %cap
}

declare ptr addrspace(200) @llvm.cheri.cap.from.pointer(ptr addrspace(200), i64)
declare ptr addrspace(200) @llvm.cheri.cap.from.pointer.nonnull.zero(ptr addrspace(200), i64)

; CHECK-LABEL: @testGetDDC
define ptr addrspace(200) @testGetDDC() {
entry:
; CHECK: mrs c0, DDC
  %ddc = tail call ptr addrspace(200) @llvm.cheri.ddc.get()
  ret ptr addrspace(200) %ddc
}

declare ptr addrspace(200) @llvm.cheri.ddc.get()

; CHECK-LABEL: @testCapDiff
define i64 @testCapDiff(ptr addrspace(200) %a, ptr addrspace(200) %b) {
entry:
; CHECK-NOT: gcvalue
; CHECK: sub x0, {{x[0-9]+}}, {{x[0-9]+}}
  %diff = tail call i64 @llvm.cheri.cap.diff(ptr addrspace(200) %a, ptr addrspace(200) %b)
  ret i64 %diff
}

declare i64 @llvm.cheri.cap.diff(ptr addrspace(200), ptr addrspace(200))

; CHECK-LABEL: @buildcap
define ptr addrspace(200) @buildcap(ptr addrspace(200) %auth, ptr addrspace(200) %bits) {
entry:
; CHECK: build c1, c1, c0
; CHECK-NEXT: cpytype c1, c1, c0
; CHECK-NEXT: cseal c0, c1, c0
  %newcap = call ptr addrspace(200) @llvm.cheri.cap.build(ptr addrspace(200) %auth, ptr addrspace(200) %bits)
  %newcap1 = call ptr addrspace(200) @llvm.cheri.cap.type.copy(ptr addrspace(200) %newcap, ptr addrspace(200) %auth)
  %newcap2 = call ptr addrspace(200) @llvm.cheri.cap.conditional.seal(ptr addrspace(200) %newcap1, ptr addrspace(200) %auth)
  ret ptr addrspace(200) %newcap2
}

; CHECK-LABEL: setbounds_imm0
define ptr addrspace(200) @setbounds_imm0(ptr addrspace(200) %in) {
; CHECK: scbnds	c0, c0, #63
  %ret = call ptr addrspace(200) @llvm.cheri.cap.bounds.set(ptr addrspace(200) %in, i64 63)
  ret ptr addrspace(200) %ret
}

; CHECK-LABEL: setbounds_imm1
define ptr addrspace(200) @setbounds_imm1(ptr addrspace(200) %in) {
; CHECK: scbnds	c0, c0, #4, lsl #4
  %ret = call ptr addrspace(200) @llvm.cheri.cap.bounds.set(ptr addrspace(200) %in, i64 64)
  ret ptr addrspace(200) %ret
}

; CHECK-LABEL: setbounds_imm2
define ptr addrspace(200) @setbounds_imm2(ptr addrspace(200) %in) {
; CHECK: mov w[[REG:[0-9]+]], #65
; CHECK: scbnds c0, c0, x[[REG]]
  %ret = call ptr addrspace(200) @llvm.cheri.cap.bounds.set(ptr addrspace(200) %in, i64 65)
  ret ptr addrspace(200) %ret
}

; CHECK-LABEL: setbounds_imm3
define ptr addrspace(200) @setbounds_imm3(ptr addrspace(200) %in) {
; CHECK: scbnds	c0, c0, #63, lsl #4
  %ret = call ptr addrspace(200) @llvm.cheri.cap.bounds.set.exact(ptr addrspace(200) %in, i64 1008)
  ret ptr addrspace(200) %ret
}

; CHECK-LABEL: setbounds_imm4
define ptr addrspace(200) @setbounds_imm4(ptr addrspace(200) %in) {
; CHECK: mov w[[REG:[0-9]+]], #1024
; CHECK: scbnds c0, c0, x[[REG]]
  %ret = call ptr addrspace(200) @llvm.cheri.cap.bounds.set(ptr addrspace(200) %in, i64 1024)
  ret ptr addrspace(200) %ret
}

; CHECK-LABEL: setbounds_reg
define ptr addrspace(200) @setbounds_reg(ptr addrspace(200) %in, i64 %len) {
; CHECK: scbnds c0, c0, x1
  %ret = call ptr addrspace(200) @llvm.cheri.cap.bounds.set(ptr addrspace(200) %in, i64 %len)
  ret ptr addrspace(200) %ret
}

; CHECK-LABEL: setbounds_exact_reg
define ptr addrspace(200) @setbounds_exact_reg(ptr addrspace(200) %in, i64 %len) {
; CHECK: scbndse c0, c0, x1
  %ret = call ptr addrspace(200) @llvm.cheri.cap.bounds.set.exact(ptr addrspace(200) %in, i64 %len)
  ret ptr addrspace(200) %ret
}

; CHECK-LABEL: seal_entry
define ptr addrspace(200) @seal_entry(ptr addrspace(200) %in) {
; CHECK: seal c0, c0, rb
  %ret = call ptr addrspace(200) @llvm.cheri.cap.seal.entry(ptr addrspace(200) %in)
  ret ptr addrspace(200) %ret
}

; CHECK-LABEL: load_tags64
define i64 @load_tags64(ptr addrspace(200) %ptr) {
; CHECK: ldct x0, [c0]
  %ret = call i64 @llvm.cheri.cap.load.tags.i64.p200(ptr addrspace(200) %ptr)
  ret i64 %ret
}

; CHECK-LABEL: load_tags32
define i32 @load_tags32(ptr addrspace(200) %ptr) {
; CHECK: ldct x0, [c0]
  %ret = call i32 @llvm.cheri.cap.load.tags.i32.p200(ptr addrspace(200) %ptr)
  ret i32 %ret
}

; CHECK-LABEL: load_tags128
define i128 @load_tags128(ptr addrspace(200) %ptr) {
; CHECK: ldct x0, [c0]
; CHECK: mov x1, xzr
  %ret = call i128 @llvm.cheri.cap.load.tags.i128.p200(ptr addrspace(200) %ptr)
  ret i128 %ret
}

; CHECK-LABEL: load_tags16
define i16 @load_tags16(ptr addrspace(200) %ptr) {
; CHECK: ldct x0, [c0]
  %ret = call i16 @llvm.cheri.cap.load.tags.i16.p200(ptr addrspace(200) %ptr)
  ret i16 %ret
}

; CHECK-LABEL: get_flags
define i64 @get_flags(ptr addrspace(200) %ptr) {
  ; CHECK: mov x0, xzr
  ; CHECK-NEXT: ret c30
  %ret = call i64 @llvm.cheri.cap.flags.get(ptr addrspace(200) %ptr)
  ret i64 %ret
}

; CHECK-LABEL: set_flags
define ptr addrspace(200) @set_flags(i64 %val, ptr addrspace(200) %ptr) {
  ; CHECK: mov c0, c1
  ; CHECK-NEXT: ret c30
  %ret = call ptr addrspace(200) @llvm.cheri.cap.flags.set(ptr addrspace(200) %ptr, i64 %val)
  ret ptr addrspace(200) %ret
}

declare i16 @llvm.cheri.cap.load.tags.i16.p200(ptr addrspace(200))
declare i128 @llvm.cheri.cap.load.tags.i128.p200(ptr addrspace(200))
declare i32 @llvm.cheri.cap.load.tags.i32.p200(ptr addrspace(200))
declare i64 @llvm.cheri.cap.load.tags.i64.p200(ptr addrspace(200))
declare ptr addrspace(200) @llvm.cheri.cap.seal.entry(ptr addrspace(200))
declare ptr addrspace(200) @llvm.cheri.cap.build(ptr addrspace(200), ptr addrspace(200))
declare ptr addrspace(200) @llvm.cheri.cap.type.copy(ptr addrspace(200), ptr addrspace(200))
declare ptr addrspace(200) @llvm.cheri.cap.conditional.seal(ptr addrspace(200), ptr addrspace(200))
