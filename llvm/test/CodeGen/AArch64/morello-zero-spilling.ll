; RUN: llc -march=arm64 -mattr=+c64,+morello,+use-16-cap-regs -target-abi purecap -o - %s | FileCheck %s

target datalayout = "e-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-i128:128-n32:64-S128-A200-P200-G200"
target triple = "arm64"

; We are checking here that in c64 puremode, the zero initialized spill slots
; are codegened efficiently, i.e. using czr directly.

define void @_Z4testv() local_unnamed_addr addrspace(200) #0 {
; CHECK-LABEL: @_Z4testv
; CHECK:  stp     czr, czr, [csp, #16]
entry:
  %call = tail call i1 @_Z9ext_proc1v()
  br i1 %call, label %if.then, label %if.end

if.then:
  %call1 = tail call ptr addrspace(200) @_Z9ext_proc2v()
  %call2 = tail call ptr addrspace(200) @_Z9ext_proc2v()
  %call3 = tail call ptr addrspace(200) @_Z9ext_proc2v()
  %call4 = tail call ptr addrspace(200) @_Z9ext_proc2v()
  %call5 = tail call ptr addrspace(200) @_Z9ext_proc2v()
  %call6 = tail call ptr addrspace(200) @_Z9ext_proc2v()
  %call7 = tail call ptr addrspace(200) @_Z9ext_proc2v()
  %call8 = tail call ptr addrspace(200) @_Z9ext_proc2v()
  %call9 = tail call ptr addrspace(200) @_Z9ext_proc2v()
  br label %if.end

if.end:
  %s.0 = phi ptr addrspace(200) [ %call1, %if.then ], [ null, %entry ]
  %s2.0 = phi ptr addrspace(200) [ %call2, %if.then ], [ null, %entry ]
  %s3.0 = phi ptr addrspace(200) [ %call3, %if.then ], [ null, %entry ]
  %s4.0 = phi ptr addrspace(200) [ %call4, %if.then ], [ null, %entry ]
  %s5.0 = phi ptr addrspace(200) [ %call5, %if.then ], [ null, %entry ]
  %s6.0 = phi ptr addrspace(200) [ %call6, %if.then ], [ null, %entry ]
  %s7.0 = phi ptr addrspace(200) [ %call7, %if.then ], [ null, %entry ]
  %s8.0 = phi ptr addrspace(200) [ %call8, %if.then ], [ null, %entry ]
  %s9.0 = phi ptr addrspace(200) [ %call9, %if.then ], [ null, %entry ]
  tail call void @_Z9ext_proc3QPc(ptr addrspace(200) %s.0)
  tail call void @_Z9ext_proc3QPc(ptr addrspace(200) %s2.0)
  tail call void @_Z9ext_proc3QPc(ptr addrspace(200) %s3.0)
  tail call void @_Z9ext_proc3QPc(ptr addrspace(200) %s4.0)
  tail call void @_Z9ext_proc3QPc(ptr addrspace(200) %s5.0)
  tail call void @_Z9ext_proc3QPc(ptr addrspace(200) %s6.0)
  tail call void @_Z9ext_proc3QPc(ptr addrspace(200) %s7.0)
  tail call void @_Z9ext_proc3QPc(ptr addrspace(200) %s8.0)
  tail call void @_Z9ext_proc3QPc(ptr addrspace(200) %s9.0)
  ret void
}

declare i1 @_Z9ext_proc1v() local_unnamed_addr addrspace(200)
declare ptr addrspace(200) @_Z9ext_proc2v() local_unnamed_addr addrspace(200)
declare void @_Z9ext_proc3QPc(ptr addrspace(200)) local_unnamed_addr addrspace(200)
