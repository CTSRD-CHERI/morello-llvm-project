; RUN: llc -mtriple=arm64 < %s -target-abi purecap -mattr=+c64,+morello,+use-16-cap-regs -frame-pointer=all -o - | FileCheck %s

declare dso_local i32 @gs({ i64, i8 addrspace(200)* }) local_unnamed_addr addrspace(200) #1
declare dso_local i32 @g({ i64, i8 addrspace(200)* }, { i64, i8 addrspace(200)* }, i32, { i64, i8 addrspace(200)* }, { i64, i8 addrspace(200)* }) local_unnamed_addr addrspace(200) #1
declare dso_local i32 @g1s({ i8 addrspace(200)*, i64 }) local_unnamed_addr addrspace(200) #1
declare dso_local i32 @g1({ i8 addrspace(200)*, i64 }, { i8 addrspace(200)*, i64 }, i32, { i8 addrspace(200)*, i64 }, { i8 addrspace(200)*, i64 }) local_unnamed_addr addrspace(200) #1

; CHECK-LABEL: foo:
; CHECK-NOT: ldr
; CHECK-NOT: str
define dso_local i32 @foo({ i64, i8 addrspace(200)* } %b.coerce) local_unnamed_addr addrspace(200) #0 {
entry:
  %0 = extractvalue { i64, i8 addrspace(200)* } %b.coerce, 0
  %b.sroa.4.0.extract.shift = and i64 %0, -4294967296
  %1 = extractvalue { i64, i8 addrspace(200)* } %b.coerce, 1
  %inc = add i64 %0, 1
  %b.sroa.0.0.insert.ext = and i64 %inc, 4294967295
  %b.sroa.0.0.insert.insert = or i64 %b.sroa.0.0.insert.ext, %b.sroa.4.0.extract.shift
  %.fca.0.insert = insertvalue { i64, i8 addrspace(200)* } undef, i64 %b.sroa.0.0.insert.insert, 0
  %.fca.1.insert = insertvalue { i64, i8 addrspace(200)* } %.fca.0.insert, i8 addrspace(200)* %1, 1
  %call = tail call i32 @gs({ i64, i8 addrspace(200)* } %.fca.1.insert) #2
  ret i32 %call
}

; Last argument gets spilled on the stack.
; CHECK-LABEL: bar:
; CHECK:     sub csp, csp, #96
; CHECK:     add c29, csp, #64
; CHECK:     ldr x{{.*}}, [c29, #32]
; CHECK:     ldr c1, [c29, #48]
; CHECK:     str c1, [csp, #48]
; CHECK:     str c1, [csp, #16]
; CHECK:     str x0, [csp, #32]
; CHECK:     str x0, [csp]
define dso_local i32 @bar({ i64, i8 addrspace(200)* } %a.coerce, { i64, i8 addrspace(200)* } %b.coerce, i32 %c, { i64, i8 addrspace(200)* } %d.coerce) local_unnamed_addr addrspace(200) #0 {
entry:
  %0 = extractvalue { i64, i8 addrspace(200)* } %d.coerce, 0
  %d.sroa.7.0.extract.shift = and i64 %0, -4294967296
  %1 = extractvalue { i64, i8 addrspace(200)* } %d.coerce, 1
  %inc = add i64 %0, 1
  %d.sroa.0.0.insert.ext = and i64 %inc, 4294967295
  %d.sroa.0.0.insert.insert = or i64 %d.sroa.0.0.insert.ext, %d.sroa.7.0.extract.shift
  %.fca.0.insert = insertvalue { i64, i8 addrspace(200)* } undef, i64 %d.sroa.0.0.insert.insert, 0
  %.fca.1.insert = insertvalue { i64, i8 addrspace(200)* } %.fca.0.insert, i8 addrspace(200)* %1, 1
  %call = tail call i32 @g({ i64, i8 addrspace(200)* } %.fca.1.insert, { i64, i8 addrspace(200)* } %.fca.1.insert, i32 %c, { i64, i8 addrspace(200)* } %.fca.1.insert, { i64, i8 addrspace(200)* } %.fca.1.insert) #2
  ret i32 %call
}

; CHECK-LABEL: baz:
; CHECK-NOT: ldr
; CHECK-NOT: str
define dso_local i32 @baz({ i8 addrspace(200)*, i64 } %b.coerce) local_unnamed_addr addrspace(200) #0 {
entry:
  %0 = extractvalue { i8 addrspace(200)*, i64 } %b.coerce, 1
  %b.sroa.6.16.extract.shift = and i64 %0, -4294967296
  %inc = add i64 %0, 1
  %b.sroa.2.16.insert.ext = and i64 %inc, 4294967295
  %b.sroa.2.16.insert.insert = or i64 %b.sroa.2.16.insert.ext, %b.sroa.6.16.extract.shift
  %.fca.1.insert = insertvalue { i8 addrspace(200)*, i64 } %b.coerce, i64 %b.sroa.2.16.insert.insert, 1
  %call = tail call i32 @g1s({ i8 addrspace(200)*, i64 } %.fca.1.insert) #2
  ret i32 %call
}

; CHECK-LABEL: bat:
; CHECK: sub csp, csp, #96
; CHECK: add c29, csp, #64
; CHECK: ldr x{{.*}}, [c29, #48]
; CHECK: ldr c0, [c29, #32]
; CHECK: str c0, [csp, #32]
; CHECK: str c0, [csp, #0]
; CHECK: str x1, [csp, #48]
; CHECK: str x1, [csp, #16]
define dso_local i32 @bat({ i8 addrspace(200)*, i64 } %a.coerce, { i8 addrspace(200)*, i64 } %b.coerce, i32 %c, { i8 addrspace(200)*, i64 } %d.coerce) local_unnamed_addr addrspace(200) #0 {
entry:
  %0 = extractvalue { i8 addrspace(200)*, i64 } %d.coerce, 1
  %d.sroa.12.16.extract.shift = and i64 %0, -4294967296
  %inc = add i64 %0, 1
  %d.sroa.5.16.insert.ext = and i64 %inc, 4294967295
  %d.sroa.5.16.insert.insert = or i64 %d.sroa.5.16.insert.ext, %d.sroa.12.16.extract.shift
  %.fca.1.insert = insertvalue { i8 addrspace(200)*, i64 } %d.coerce, i64 %d.sroa.5.16.insert.insert, 1
  %call = tail call i32 @g1({ i8 addrspace(200)*, i64 } %.fca.1.insert, { i8 addrspace(200)*, i64 } %.fca.1.insert, i32 %c, { i8 addrspace(200)*, i64 } %.fca.1.insert, { i8 addrspace(200)*, i64 } %.fca.1.insert) #2
  ret i32 %call
}

attributes #0 = { nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "min-legal-vector-width"="0" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="generic" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="generic" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { nounwind }
