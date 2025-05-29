; RUN: opt -S -loop-reduce -target-abi purecap -march=arm64 -mattr=+c64 -o -  %s | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-none--elf"

; Don't rewrite the loop exit value if the SCEV expression type
; is not a fat pointer. If we would do this, we would get an
; inttoptr.

; CHECK-LABEL:foo
; CHECK-NOT: inttoptr
define void @foo(ptr addrspace(200) %line) addrspace(200) {
entry:
  switch i64 undef, label %if.end25 [
    i64 0, label %if.then4
    i64 1, label %land.lhs.true14
  ]

if.then4:
  unreachable

land.lhs.true14:
  ret void

if.end25:
  br label %while.cond.preheader

while.cond.preheader:
  br label %while.body226

while.body226:
  switch i32 undef, label %sw.default [
    i32 1, label %while.cond227.preheader
    i32 322, label %sw.bb232
    i32 354, label %sw.bb232
    i32 2, label %sw.bb285
    i32 6, label %sw.bb291
    i32 326, label %sw.bb298
    i32 358, label %sw.bb298
    i32 5, label %while.cond358.preheader
    i32 8, label %sw.bb365
    i32 127, label %sw.bb365
    i32 4, label %sw.bb371
    i32 24, label %sw.bb397
    i32 11, label %sw.bb398
    i32 383, label %sw.bb433
    i32 324, label %sw.bb539
    i32 356, label %sw.bb539
    i32 20, label %sw.bb641
    i32 12, label %for.cond662.preheader
    i32 25, label %for.cond686.preheader
    i32 16, label %while.cond710.preheader
    i32 14, label %sw.bb790
    i32 316, label %while.cond915.preheader
    i32 318, label %sw.bb972
    i32 19, label %sw.bb973
    i32 18, label %sw.bb998
    i32 341, label %sw.bb1021
    i32 373, label %sw.bb1021
    i32 323, label %while.cond1095.preheader
    i32 355, label %while.cond1095.preheader
    i32 332, label %sw.bb1143
    i32 364, label %sw.bb1143
    i32 268, label %sw.bb1216
    i32 -1, label %while.cond223.backedge
    i32 13, label %while.cond1237.preheader
    i32 10, label %while.cond1237.preheader
    i32 15, label %while.cond1246.preheader
    i32 9, label %sw.bb1256
  ]

while.cond1246.preheader:
  unreachable

while.cond1237.preheader:
  unreachable

while.cond915.preheader:
  unreachable

for.cond686.preheader:
  unreachable

for.cond662.preheader:
  unreachable

while.cond358.preheader:
  unreachable

while.cond227.preheader:
  unreachable

while.cond1095.preheader:
  unreachable

while.cond710.preheader:
  unreachable

sw.bb232:
  br label %land.rhs

land.rhs: 
  %incdec.ptr2372955 = phi ptr addrspace(200) [ undef, %sw.bb232 ], [ %incdec.ptr237, %do.body236.backedge ]
  br label %do.body236.backedge

do.body236.backedge:
  %incdec.ptr237 = getelementptr i8, ptr addrspace(200) %incdec.ptr2372955, i64 -1
  %cmp239 = icmp ugt ptr addrspace(200) %incdec.ptr237, %line
  br i1 %cmp239, label %land.rhs, label %while.cond223.backedge.loopexit3010

sw.bb285:
  unreachable

sw.bb291:
  unreachable

sw.bb298:
  unreachable

sw.bb365:
  unreachable

sw.bb371:
  unreachable

while.cond223.backedge.loopexit3010:
  br label %while.cond223.backedge

while.cond223.backedge:
  %p.1.be = phi ptr addrspace(200) [ %line, %while.body226 ], [ %incdec.ptr237, %while.cond223.backedge.loopexit3010 ]
  unreachable

sw.bb397:
  unreachable

sw.bb398:
  unreachable

sw.bb433:
  unreachable

sw.bb539:
  unreachable

sw.bb641:
  unreachable

sw.bb790:
  unreachable

sw.bb972:
  unreachable

sw.bb973:
  unreachable

sw.bb998:
  unreachable

sw.bb1021:
  unreachable

sw.bb1143:
  unreachable

sw.bb1216:
  unreachable

sw.bb1256:
  unreachable

sw.default:
  unreachable
}
