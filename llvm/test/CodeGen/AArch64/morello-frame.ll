; RUN: llc -mtriple=arm64 -mattr=+morello -o - %s | FileCheck %s

define dso_local void @func(ptr addrspace(200) nocapture readnone %bb, ptr addrspace(200) %cc) local_unnamed_addr addrspace(200) #0 {
entry:
  call void asm sideeffect "", "~{x19},~{x20},~{x21},~{x22},~{x23},~{x24},~{x25},~{x26},~{x27},~{x28},~{d8},~{d9},~{d10},~{d11},~{d12},~{d13},~{d14},~{d15}"() nounwind
  ret void
}

; Capabilities are not callee-saved, so they don't get spilled.
; CHECK-LABEL: func
; CHECK:	stp	d15, d14, [sp, #-144]!  // 16-byte Folded Spill
; CHECK-NEXT: .cfi_def_cfa_offset 144
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
define i32 @frameWithCapabilityRegisters(i32 %argc, ptr %argv) {
entry:
; CHECK: str x30, [sp, #-32]!
; CHECK-NEXT: .cfi_def_cfa_offset 32
; CHECK-NEXT: stp x20, x19, [sp, #16]
; CHECK: ldp x20, x19, [sp, #16]
; CHECK: ldr x30, [sp], #32
; CHECK: ret

  %c = alloca i32, align 4
  call void @llvm.lifetime.start(i64 4, ptr %c)
  %call = call ptr addrspace(200) @foo(ptr nonnull %c)
  %0 = load i32, ptr addrspace(200) %call, align 4
  %1 = load ptr, ptr %argv, align 8
  %call1 = call i32 @bar(ptr %1, i32 %0)
  %add = add nsw i32 %call1, %0
  call void @llvm.lifetime.end(i64 4, ptr %c)
  ret i32 %add
}

declare void @llvm.lifetime.start(i64, ptr nocapture)
declare ptr addrspace(200) @foo(ptr)
declare i32 @bar(ptr, i32)
declare void @llvm.lifetime.end(i64, ptr nocapture)
