; RUN: llc -mtriple=arm64 -mattr=+morello %s -o - | FileCheck %s

%struct.B = type { ptr addrspace(200) }

; CHECK-LABEL: testFun
; CHECK: ldr	c0, [x0, #0]
; CHECK: str	c0, [sp, #0]
define void @testFun(ptr nocapture readonly %b) {
entry:
  %b2 = alloca %struct.B, align 16
  call void @llvm.memcpy.p0.p0.i64(ptr nonnull %b2, ptr %b, i64 16, i32 16, i1 false)
  call void @H(ptr nonnull %b2)
  ret void
}

%struct.D = type { i32, i32, i8, [1 x i8] }
%struct.C = type { i32, i32, i32, i32, i32, i32, i8 }

; The last store should be str	c{{.*}}, [sp], #64,
; at the moment the input to the load-store optimization
; pass doesn't schedule the store to [sp, #0] next to the
; add and we end up not forming this instruction.

; CHECK-LABEL: nonMultiple1
; CHECK-DAG:    ldr	w{{.*}}, [sp, #56]
; CHECK-DAG:	ldr	x{{.*}}, [sp, #48]
; CHECK-DAG:	ldr	c{{.*}}, [sp, #32]
; CHECK-DAG:	str	w{{.*}}, [sp, #24]
; CHECK-DAG:	str	x{{.*}}, [sp, #16]
; CHECK-DAG:	str	c{{.*}}, [sp, #0]

define void @nonMultiple1(ptr %rhs) {
 entry:
   %aset = alloca %struct.C, align 16
   %bset = alloca %struct.C, align 16
   br i1 undef, label %land.lhs.true53, label %if.end66
 
 land.lhs.true53:                                  ; preds = %entry
   br label %if.end81
 
 if.end66:                                         ; preds = %entry
   %cmp74 = icmp eq i32 undef, 1
   br i1 %cmp74, label %if.then76, label %if.end81
 
 if.then76:                                        ; preds = %if.end66
   call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 16 %aset, ptr align 16 null, i64 28, i32 4, i1 false)
   ret void
 
 if.end81:                                         ; preds = %if.end66, %land.lhs.true53
   call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 16 %bset, ptr nonnull align 16 %aset, i64 28, i32 4, i1 false)
   ret void
 }

; FIXME: it should be possible to increase the alignment of the aset and bset
; stack objects in order to allow memcpy inlining.
; CHECK-LABEL: nonMultiple2
; CHECK: bl memcpy
define void @nonMultiple2(ptr %rhs) {
 entry:
   %aset = alloca %struct.C, align 4
   %bset = alloca %struct.C, align 4
   br i1 undef, label %land.lhs.true53, label %if.end66

 land.lhs.true53:                                  ; preds = %entry
   br label %if.end81

 if.end66:                                         ; preds = %entry
   %cmp74 = icmp eq i32 undef, 1
   br i1 %cmp74, label %if.then76, label %if.end81

 if.then76:                                        ; preds = %if.end66
   call void @llvm.memcpy.p0.p0.i64(ptr nonnull %aset, ptr null, i64 28, i32 4, i1 false)
   ret void

 if.end81:                                         ; preds = %if.end66, %land.lhs.true53
   call void @llvm.memcpy.p0.p0.i64(ptr nonnull %bset, ptr nonnull %aset, i64 28, i32 4, i1 false)
   ret void
 }

declare void @llvm.memcpy.p0.p0.i64(ptr nocapture writeonly, ptr nocapture readonly, i64, i32, i1)
declare void @H(ptr)
