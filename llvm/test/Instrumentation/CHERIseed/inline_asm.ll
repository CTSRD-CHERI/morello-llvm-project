; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------

; CHECK-LABEL: @noarg
define void @noarg() {
; CHECK-NEXT:  tail call void asm sideeffect "", ""()
  tail call void asm sideeffect "", ""()
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @non_cap_arg
define void @non_cap_arg(i32 %a, i32 %b) {
; CHECK-NEXT:  tail call void asm sideeffect "", "=r,r,0"(i32 %b, i32 %a)
  tail call void asm sideeffect "", "=r,r,0"(i32 %b, i32 %a)
; CHECK-NEXT:  ret void
  ret void
}

; CHECK-LABEL: @func_ptr_arg
define void @func_ptr_arg(void ()* %a) {
; CHECK-NEXT:  tail call void asm sideeffect "", "r"(void ()* %a)
  tail call void asm sideeffect "", "r"(void ()* %a)
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
; Support simple compiler barriers

; CHECK-LABEL: @compiler_barrier
define void @compiler_barrier(i8 addrspace(200)* %a, i8 addrspace(200)* %b) {
; CHECK-NEXT:  call void asm sideeffect "   ", "r,r,~{memory}"(%__cheriseed_cap_t* %a, %__cheriseed_cap_t* %b)
  call void asm sideeffect "   ", "r,r,~{memory}"(i8 addrspace(200)* %a, i8 addrspace(200)* %b)
; CHECK-NEXT:  ret void
  ret void
}

; ------------------------------------------------------------------------------
