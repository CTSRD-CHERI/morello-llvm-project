; RUN: llc -mtriple=arm64 -mattr=+morello %s -o - | FileCheck %s

%struct.B = type { i8 addrspace(200)* }

; CHECK-LABEL: testFun
; CHECK: ldr	c0, [x0, #0]
; CHECK: str	c0, [sp, #0]
define void @testFun(%struct.B* nocapture readonly %b) {
entry:
  %b2 = alloca %struct.B, align 16
  %0 = bitcast %struct.B* %b2 to i8*
  %1 = bitcast %struct.B* %b to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* nonnull %0, i8* %1, i64 16, i32 16, i1 false)
  call void @H(%struct.B* nonnull %b2)
  ret void
}

%struct.D = type { i32, i32, i8, [1 x i8] }
%struct.C = type { i32, i32, i32, i32, i32, i32, i8 }

; The last store should be str	c{{.*}}, [sp], #64,
; at the moment the input to the load-store optimization
; pass doesn't schedule the store to [sp, #0] next to the
; add and we end up not forming this instruction.

; CHECK-LABEL: nonMultiple
; CHECK-DAG:    ldr	w{{.*}}, [sp, #56]
; CHECK-DAG:	ldr	x{{.*}}, [sp, #48]
; CHECK-DAG:	ldr	c{{.*}}, [sp, #32]
; CHECK-DAG:	str	w{{.*}}, [sp, #24]
; CHECK-DAG:	str	x{{.*}}, [sp, #16]
; CHECK-DAG:	str	c{{.*}}, [sp, #0]

define void @nonMultiple(%struct.D* %rhs) {
 entry:
   %aset = alloca %struct.C, align 4
   %bset = alloca %struct.C, align 4
   %0 = bitcast %struct.C* %aset to i8*
   %1 = bitcast %struct.C* %bset to i8*
   br i1 undef, label %land.lhs.true53, label %if.end66
 
 land.lhs.true53:                                  ; preds = %entry
   %digits60 = getelementptr inbounds %struct.D, %struct.D* %rhs, i64 0, i32 0
   br label %if.end81
 
 if.end66:                                         ; preds = %entry
   %cmp74 = icmp eq i32 undef, 1
   br i1 %cmp74, label %if.then76, label %if.end81
 
 if.then76:                                        ; preds = %if.end66
   call void @llvm.memcpy.p0i8.p0i8.i64(i8* nonnull %0, i8* null, i64 28, i32 4, i1 false)
   unreachable
 
 if.end81:                                         ; preds = %if.end66, %land.lhs.true53
   call void @llvm.memcpy.p0i8.p0i8.i64(i8* nonnull %1, i8* nonnull %0, i64 28, i32 4, i1 false)
   ret void
 }

declare void @llvm.memcpy.p0i8.p0i8.i64(i8* nocapture writeonly, i8* nocapture readonly, i64, i32, i1)
declare void @H(%struct.B*)
