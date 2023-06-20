; CHERI-GENERIC-UTC: opt --function-signature
; RUN: opt -S -instcombine @PURECAP_HARDFLOAT_ARGS@ %s -o - | FileCheck %s
target datalayout = "@PURECAP_DATALAYOUT@"

@.str = private unnamed_addr addrspace(200) constant [16 x i8] c"foofoofoofoofoo\00", align 16
@.str.1 = private unnamed_addr addrspace(200) constant [17 x i8] c"barbarbarbarbara\00", align 16
@.str.2 = private unnamed_addr addrspace(200) constant [18 x i8] c"bazbazbazbazbazaa\00", align 16
@.str.3 = private unnamed_addr addrspace(200) constant [19 x i8] c"bifbizbifbifbifbif\00", align 16
@.str.4 = private unnamed_addr addrspace(200) constant [4 x i8] c"biz\00", align 1

define void @func(i32 noundef %s, i8 addrspace(200)* nocapture noundef writeonly %c) local_unnamed_addr addrspace(200) {
entry:
  switch i32 %s, label %sw.default [
    i32 0, label %sw.epilog
    i32 5, label %sw.bb1
    i32 8, label %sw.bb2
    i32 9, label %sw.bb3
  ]

sw.bb1:                                           ; preds = %entry
  br label %sw.epilog

sw.bb2:                                           ; preds = %entry
  br label %sw.epilog

sw.bb3:                                           ; preds = %entry
  br label %sw.epilog

sw.default:                                       ; preds = %entry
  br label %sw.epilog

sw.epilog:                                        ; preds = %entry, %sw.default, %sw.bb3, %sw.bb2, %sw.bb1
  %sz.0 = phi i64 [ 4, %sw.default ], [ 19, %sw.bb3 ], [ 18, %sw.bb2 ], [ 17, %sw.bb1 ], [ 16, %entry ]
  %str.0 = phi i8 addrspace(200)* [ getelementptr inbounds ([4 x i8], [4 x i8] addrspace(200)* @.str.4, i64 0, i64 0), %sw.default ], [ getelementptr inbounds ([19 x i8], [19 x i8] addrspace(200)* @.str.3, i64 0, i64 0), %sw.bb3 ], [ getelementptr inbounds ([18 x i8], [18 x i8] addrspace(200)* @.str.2, i64 0, i64 0), %sw.bb2 ], [ getelementptr inbounds ([17 x i8], [17 x i8] addrspace(200)* @.str.1, i64 0, i64 0), %sw.bb1 ], [ getelementptr inbounds ([16 x i8], [16 x i8] addrspace(200)* @.str, i64 0, i64 0), %entry ]
  tail call void @llvm.memcpy.p200i8.p200i8.i64(i8 addrspace(200)* noundef nonnull align 1 dereferenceable(1) %c, i8 addrspace(200)* noundef nonnull align 1 dereferenceable(1) %str.0, i64 %sz.0, i1 false)
  ret void
}

declare void @llvm.memcpy.p200i8.p200i8.i64(i8 addrspace(200)* noalias nocapture writeonly, i8 addrspace(200)* noalias nocapture readonly, i64, i1 immarg) addrspace(200)

; UTC_ARGS: --disable
; CHECK: attributes #[[ATTR2]] = { no_preserve_cheri_tags }
