; RUN: llc -mtriple=arm64 -mattr=+morello -o - %s | FileCheck %s

define dso_local void @func(i8 addrspace(200)* nocapture readnone %bb, i8 addrspace(200)* %cc) local_unnamed_addr addrspace(200) #0 {
entry:
  call void asm sideeffect "", "~{x19},~{x20},~{x21},~{x22},~{x23},~{x24},~{x25},~{x26},~{x27},~{x28},~{d8},~{d9},~{d10},~{d11},~{d12},~{d13},~{d14},~{d15}"() nounwind
  ret void
}

; Capabilities are not callee-saved, so they don't get spilled.
; CHECK-LABEL: func
; CHECK:	stp	d15, d14, [sp, #-144]!  // 16-byte Folded Spill
; CHECK-NEXT:	stp	d13, d12, [sp, #16]     // 16-byte Folded Spill
; CHECK-NEXT:	stp	d11, d10, [sp, #32]     // 16-byte Folded Spill
; CHECK-NEXT:	stp	d9, d8, [sp, #48]       // 16-byte Folded Spill
; CHECK-NEXT:	stp	x28, x27, [sp, #64]     // 16-byte Folded Spill
; CHECK-NEXT:	stp	x26, x25, [sp, #80]     // 16-byte Folded Spill
; CHECK-NEXT:	stp	x24, x23, [sp, #96]     // 16-byte Folded Spill
; CHECK-NEXT:	stp	x22, x21, [sp, #112]    // 16-byte Folded Spill
; CHECK-NEXT:	stp	x20, x19, [sp, #128]    // 16-byte Folded Spill

; CHECK:	ldp	x20, x19, [sp, #128]    // 16-byte Folded Reload
; CHECK-NEXT:	ldp	x22, x21, [sp, #112]    // 16-byte Folded Reload
; CHECK-NEXT:	ldp	x24, x23, [sp, #96]     // 16-byte Folded Reload
; CHECK-NEXT:	ldp	x26, x25, [sp, #80]     // 16-byte Folded Reload
; CHECK-NEXT:	ldp	x28, x27, [sp, #64]     // 16-byte Folded Reload
; CHECK-NEXT:	ldp	d9, d8, [sp, #48]       // 16-byte Folded Reload
; CHECK-NEXT:	ldp	d11, d10, [sp, #32]     // 16-byte Folded Reload
; CHECK-NEXT:	ldp	d13, d12, [sp, #16]     // 16-byte Folded Reload
; CHECK-NEXT:	ldp	d15, d14, [sp], #144    // 16-byte Folded Reload


; CHECK-LABEL: frameWithCapabilityRegisters
define i32 @frameWithCapabilityRegisters(i32 %argc, i8** %argv) {
entry:
; CHECK: str x30, [sp, #-32]!
; CHECK-NEXT: stp x20, x19, [sp, #16]
; CHECK: ldp x20, x19, [sp, #16]
; CHECK: ldr x30, [sp], #32
; CHECK: ret

  %c = alloca i32, align 4
  %0 = bitcast i32* %c to i8*
  call void @llvm.lifetime.start(i64 4, i8* %0)
  %call = call i32 addrspace(200)* @foo(i32* nonnull %c)
  %1 = load i32, i32 addrspace(200)* %call, align 4
  %2 = load i8*, i8** %argv, align 8
  %call1 = call i32 @bar(i8* %2, i32 %1)
  %add = add nsw i32 %call1, %1
  call void @llvm.lifetime.end(i64 4, i8* %0)
  ret i32 %add
}

declare void @llvm.lifetime.start(i64, i8* nocapture)
declare i32 addrspace(200)* @foo(i32*)
declare i32 @bar(i8*, i32)
declare void @llvm.lifetime.end(i64, i8* nocapture)

%struct.__va_list = type { i8*, i8*, i8*, i32, i32 }

; CHECK-LABEL: frameWithBigStackAndNoExtraCSSpill
define i32 @frameWithBigStackAndNoExtraCSSpill(i8* %fmt, ...) {
entry:
; CHECK:      sub sp, sp, #384
; CHECK-NEXT: stp x29, x30, [sp, #368]
; CHECK:      ldp x29, x30, [sp, #368]
; CHECK-NEXT: add sp, sp, #384
; CHECK-NEXT: ret
  %ap = alloca %struct.__va_list, align 8
  %tmp = alloca %struct.__va_list, align 8
  %0 = bitcast %struct.__va_list* %ap to i8*
  call void @llvm.lifetime.start(i64 32, i8* %0)
  call void @llvm.va_start(i8* %0)
  %1 = bitcast %struct.__va_list* %tmp to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* %1, i8* %0, i64 32, i32 8, i1 false)
  %call = call i32 @varArgFunc(i8* %fmt, %struct.__va_list* %tmp)
  call void @llvm.va_end(i8* %0)
  call void @llvm.lifetime.end(i64 32, i8* %0)
  ret i32 %call
}

declare void @llvm.va_start(i8*)
declare void @llvm.va_end(i8*)
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* nocapture, i8* nocapture readonly, i64, i32, i1)
declare i32 @varArgFunc(i8*, %struct.__va_list*)
