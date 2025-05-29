; RUN: llc -march=arm64 -mattr=+c64,+morello -target-abi purecap --relocation-model=pic -o - %s | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "aarch64-unknown-freebsd"

%class.a = type { i8 }
%class.c = type { i8 }

@d = addrspace(200) global i32 0, align 4
@_ZN1a1bE = external addrspace(200) global %class.a, align 1

; Function Attrs: noinline optnone
define void @_Z3fn1v() addrspace(200) #0 personality ptr addrspace(200) @__gxx_personality_v0 {
entry:
  %agg.tmp = alloca %class.a, align 1, addrspace(200)
  %exn.slot = alloca ptr addrspace(200), addrspace(200)
  %ehselector.slot = alloca i32, addrspace(200)
  %call = call ptr addrspace(200) @_Znwm(i64 1) #4
  %0 = load i8, ptr addrspace(200) %agg.tmp, align 1
  invoke void @_ZN1cC1EU3capPi1a(ptr addrspace(200) %call, ptr addrspace(200) @d, i8 %0)
          to label %invoke.cont unwind label %lpad

invoke.cont:                                      ; preds = %entry
  ret void

lpad:                                             ; preds = %entry
  %1 = landingpad { ptr addrspace(200), i32 }
          cleanup
  %2 = extractvalue { ptr addrspace(200), i32 } %1, 0
  store ptr addrspace(200) %2, ptr addrspace(200) %exn.slot, align 16
  %3 = extractvalue { ptr addrspace(200), i32 } %1, 1
  store i32 %3, ptr addrspace(200) %ehselector.slot, align 4
  call void @_ZdlU3capPv(ptr addrspace(200) %call) #5
  br label %eh.resume

eh.resume:                                        ; preds = %lpad
  %exn = load ptr addrspace(200), ptr addrspace(200) %exn.slot, align 16
  %sel = load i32, ptr addrspace(200) %ehselector.slot, align 4
  %lpad.val = insertvalue { ptr addrspace(200), i32 } undef, ptr addrspace(200) %exn, 0
  %lpad.val1 = insertvalue { ptr addrspace(200), i32 } %lpad.val, i32 %sel, 1
  resume { ptr addrspace(200), i32 } %lpad.val1
}

; Function Attrs: nobuiltin
declare noalias ptr addrspace(200) @_Znwm(i64) addrspace(200) #1

declare void @_ZN1cC1EU3capPi1a(ptr addrspace(200), ptr addrspace(200), i8) unnamed_addr addrspace(200) #2

declare i32 @__gxx_personality_v0(...) addrspace(200)

; Function Attrs: nobuiltin nounwind
declare void @_ZdlU3capPv(ptr addrspace(200)) addrspace(200) #3

attributes #0 = { noinline optnone "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { nobuiltin "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #3 = { nobuiltin nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #4 = { builtin }
attributes #5 = { builtin nounwind }

!llvm.module.flags = !{!0}

!0 = !{i32 1, !"wchar_size", i32 4}

; CHECK: DW.ref.__gxx_personality_v0:
; CHECK-NEXT: .chericap __gxx_personality_v0
