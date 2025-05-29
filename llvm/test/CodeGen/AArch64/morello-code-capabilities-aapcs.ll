; RUN: llc < %s -mtriple=aarch64-none-elf -mattr=+morello | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128"
target triple = "aarch64-none--elf"

@.str = private unnamed_addr constant [30 x i8] c"Hello from a capability call.\00", align 1

declare dso_local void @foo(ptr %str) #1

; CHECK-LABEL: .LCPI0_0
; CHECK: .chericap foo

; CHECK-LABEL: bar
define dso_local i32 @bar(i32 %argc, ptr %argv) #0 {
entry:
; CHECK: blr c
  %retval = alloca i32, align 4
  %argc.addr = alloca i32, align 4
  %argv.addr = alloca ptr, align 8
  %cfoo = alloca ptr addrspace(200), align 16
  store i32 0, ptr %retval, align 4
  store i32 %argc, ptr %argc.addr, align 4
  store ptr %argv, ptr %argv.addr, align 8
  store ptr addrspace(200) addrspacecast (ptr @foo to ptr addrspace(200)), ptr %cfoo, align 16
  %0 = load ptr addrspace(200), ptr %cfoo, align 16
  call addrspace(200) void %0(ptr @.str)
  ret i32 0
}


attributes #0 = { noinline nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="generic" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="generic" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.module.flags = !{!0}

!0 = !{i32 1, !"wchar_size", i32 4}
