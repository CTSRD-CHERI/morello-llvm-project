; RUN: llc -mtriple=arm64 -mattr=+morello -o - %s | FileCheck %s

; CHECK-LABEL: fun
; CHECK: ldursh w{{[0-9+]}}, [c0, #0]
; CHECK: ldursh w{{[0-9+]}}, [c0, #2]

define <2 x i32> @fun(<2 x i16> addrspace(200)* %in) {
entry:
  br i1 undef, label %if.end, label %if.then

if.then:                                          ; preds = %entry
  %0 = load <2 x i16>, <2 x i16> addrspace(200)* %in, align 2
  %1 = sext <2 x i16> %0 to <2 x i32>
  %2 = sub nsw <2 x i32> zeroinitializer, %1
  %3 = extractelement <2 x i32> %2, i32 0
  %4 = extractelement <2 x i32> %2, i32 1
  %mul = mul nsw i32 %4, %3
  %neg = sub i32 0, %mul
  %5 = select i1 undef, i32 %mul, i32 %neg
  br label %if.end

if.end:
  %RecArea.0 = phi i32 [ %5, %if.then ], [ 0, %entry ]
  %newphi = phi <2 x i32> [%1, %if.then], [<i32 0, i32 0>, %entry]
  ret <2 x i32> %newphi
}
