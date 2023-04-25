; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------
; Test @llvm.used

@char = global i8 0, align 1
@int = global i32 0, align 4
@ptr = global i8* null, align 8
@cap_before = global i8 addrspace(200)* null, align 16

define void @func() {
  ret void
}

; CHECK-LABEL: @llvm.used = appending global [6 x i8*]
@llvm.used = appending global [6 x i8*] [
; CHECK-SAME:  i8* @char
  i8* @char,
; CHECK-SAME:  i8* bitcast (i32* @int to i8*)
  i8* bitcast (i32* @int to i8*),
; CHECK-SAME:  i8* bitcast (i8** @ptr to i8*)
  i8* bitcast (i8** @ptr to i8*),
; CHECK-SAME:  i8* bitcast (%__cheriseed_cap_t* @cap_before to i8*)
  i8* bitcast (i8 addrspace(200)** @cap_before to i8*),
; CHECK-SAME:  i8* bitcast (%__cheriseed_cap_t* @cap_after to i8*)
  i8* bitcast (i8 addrspace(200)** @cap_after to i8*),
; CHECK-SAME:  i8* bitcast (void ()* @func to i8*)
  i8* bitcast (void ()* @func to i8*)
; CHECK-SAME:  section "llvm.metadata"
], section "llvm.metadata"

; Put after @llvm.used on purpose.
@cap_after = global i8 addrspace(200)* null, align 16

; ------------------------------------------------------------------------------
