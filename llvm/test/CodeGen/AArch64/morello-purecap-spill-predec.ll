; RUN: llc -march=arm64 -mattr=+c64,+morello,+use-16-cap-regs,+legacy-morello-vararg  -target-abi purecap -frame-pointer=all -o - %s | FileCheck %s
target datalayout = "e-m:e-i64:64-i128:128-n32:64-S128-pf200:128:128:128:64-A200-P200-G200"
target triple = "aarch64-none--elf"

@c = common local_unnamed_addr addrspace(200) global i32 0, align 4
@a = common local_unnamed_addr addrspace(200) global double 0.000000e+00, align 8

; This test was previously causing us to compute a wrong callee saved area size
; by aligning CSP to 16 bytes for capability registers that we were not spilling.

; CHECK-LABEL: testPreDecSpill
define i32 @testPreDecSpill(i32 %p1) local_unnamed_addr addrspace(200) #0 {
; CHECK:  sub     csp, csp, #80
; CHECK:  str     d{{.*}}, [csp, #16]
; CHECK:  stp     c29, c30, [csp, #32]
; CHECK:  str     x{{.*}}, [csp, #64]
entry:
  %conv = sitofp i32 %p1 to double
  %call = tail call double @sqrt(double -2.500000e-01) #4
  %conv1 = fptosi double %call to i32
  %0 = load i32, ptr addrspace(200) @c, align 4
  %conv3 = sitofp i32 %0 to double
  %call4 = tail call double @copysign(double %conv3, double %conv) #5
  store double %call4, ptr addrspace(200) @a, align 8
  %div = fdiv double 0.000000e+00, %call4
  %call6 = tail call i32 (...) @CMPLX(double %div) #4
  %conv7 = sitofp i32 %call6 to double
  %tobool = icmp eq i32 %conv1, 0
  br i1 %tobool, label %if.end, label %if.then

if.then:                                          ; preds = %entry
  %mul_ac = fmul double %conv7, 2.000000e+00
  %mul_ad = fmul double %conv7, 0.000000e+00
  %mul_i = fadd double %mul_ad, 0.000000e+00
  %isnan_cmp = fcmp uno double %mul_ac, 0.000000e+00
  %isnan_cmp10 = fcmp uno double %mul_i, 0.000000e+00
  %or.cond = and i1 %isnan_cmp, %isnan_cmp10
  br i1 %or.cond, label %complex_mul_libcall, label %if.end

complex_mul_libcall:                              ; preds = %if.then
  %call11 = tail call { double, double } @__muldc3(double %conv7, double 0.000000e+00, double 2.000000e+00, double 0.000000e+00) #4
  br label %if.end

if.end:                                           ; preds = %entry, %if.then, %complex_mul_libcall
  ret i32 undef
; CHECK:  ldp     c29, c30, [csp, #32]
; CHECK:  ldr     x{{.*}}, [csp, #64]
; CHECK:  ldr     d{{.*}}, [csp, #16]
; CHECK:  add     csp, csp, #80
}

declare double @sqrt(double) addrspace(200) #0
declare double @copysign(double, double) addrspace(200) #0
declare i32 @CMPLX(...) addrspace(200) #0
declare { double, double } @__muldc3(double, double, double, double) local_unnamed_addr addrspace(200)

attributes #0 = { nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="generic" "target-features"="+morello,+c64,+neon" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #4 = { nounwind }
attributes #5 = { nounwind readnone }
