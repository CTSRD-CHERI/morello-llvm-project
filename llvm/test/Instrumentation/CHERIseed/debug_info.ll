; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------
; Preserve DISubprogram metadata node

; CHECK: @di_subprogram{{.*}} !dbg !2
define void @di_subprogram(i8* %p) !dbg !2 {
  ret void
}

; ------------------------------------------------------------------------------
; Preserve DILocation metadata node

; CHECK-LABEL: @di_location
define void @di_location(i8* %p) {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca
; CHECK-NEXT:  %a {{.*}} !dbg !11
  %a = bitcast i8* %p to i32*, !dbg !11
; CHECK-NEXT:  %2 {{.*}} !dbg !12
; CHECK-NEXT:  %3 {{.*}} !dbg !12
; CHECK-NEXT:  %b {{.*}} !dbg !12
  %b = addrspacecast i8* %p to i8 addrspace(200)*, !dbg !12
; CHECK-NEXT:  ret void, !dbg !13
  ret void, !dbg !13
}

; ------------------------------------------------------------------------------
; Make up missing DebugLoc!.

; CHECK: @debugloc_missing{{.*}} !dbg !14
define void @debugloc_missing() !dbg !14 {
; CHECK-NEXT:  %1 = call i8* @memcpy(i8* null, i8* null, i64 0), !dbg !15
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* null, i8* null, i64 0, i1 false)
; CHECK-NEXT:  ret void
  ret void
}

declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly,
  i8* noalias nocapture readonly, i64, i1 immarg)

; ------------------------------------------------------------------------------
; Metadata section

!llvm.module.flags = !{!0, !1}
!0 = !{i32 7, !"Dwarf Version", i32 4}
!1 = !{i32 2, !"Debug Info Version", i32 3}

; Note: not testing DI metadata because the module pass doesn't yet change them.
!2 = distinct !DISubprogram(name: "", scope: !3, file: !3, line: 1,
    type: !4, scopeLine: 1, flags: DIFlagPrototyped | DIFlagAllCallsDescribed,
    spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !8, retainedNodes: !9)
!3 = !DIFile(filename: "f", directory: "d")
!4 = !DISubroutineType(types: !5)
!5 = !{null, !6}
!6 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: !7, size: 64)
!7 = !DIBasicType(name: "", size: 8, encoding: DW_ATE_signed_char)
!8 = distinct !DICompileUnit(language: DW_LANG_C99, file: !3, isOptimized: true,
    runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false,
    nameTableKind: None)
!9 = !{!10}
!10 = !DILocalVariable(name: "", arg: 1, scope: !2, file: !3, line: 1, type: !6)
!11 = !DILocation(line: 0, column: 0, scope: !2)
!12 = !DILocation(line: 1, column: 0, scope: !2)
!13 = !DILocation(line: 2, column: 0, scope: !2)
!14 = distinct !DISubprogram(name: "", scope: !3, file: !3, line: 1,
    type: !4, scopeLine: 1, flags: DIFlagPrototyped | DIFlagAllCallsDescribed,
    spFlags: DISPFlagDefinition | DISPFlagOptimized, unit: !8, retainedNodes: !9)

; CHECK: !15 = !DILocation(line: 0, scope: !14)

; ------------------------------------------------------------------------------
