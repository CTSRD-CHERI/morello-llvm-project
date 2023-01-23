; RUN: opt @PURECAP_HARDFLOAT_ARGS@ %s -cheri-cap-to-int -S -o - | FileCheck %s

target datalayout = "@PURECAP_DATALAYOUT@"

define i1 @load_ptr(i32 addrspace(200)* addrspace(200)* nocapture readonly %a) {
entry:
  %0 = load i32 addrspace(200)*, i32 addrspace(200)* addrspace(200)* %a, align @CAP_BYTES@
  %cmp = icmp eq i32 addrspace(200)* %0, null
  ret i1 %cmp
}

define i1 @gep(i32 addrspace(200)* addrspace(200)* nocapture readonly %aptr, i32 addrspace(200) *addrspace(200)* nocapture readonly %bptr) {
entry:
  %a = load i32 addrspace(200)*, i32 addrspace(200)* addrspace(200)* %aptr, align @CAP_BYTES@
  %b = load i32 addrspace(200)*, i32 addrspace(200)* addrspace(200)* %bptr, align @CAP_BYTES@
  %arrayidx = getelementptr inbounds i32, i32 addrspace(200)* %a, i64 2
  %cmp = icmp eq i32 addrspace(200)* %arrayidx, %b
  ret i1 %cmp
}

define i1 @bitcast(i8 addrspace(200)* addrspace(200)* nocapture readonly %aptr, i32 addrspace(200) *addrspace(200)* nocapture readonly %bptr) {
entry:
  %a = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %aptr, align @CAP_BYTES@
  %b = load i32 addrspace(200)*, i32 addrspace(200)* addrspace(200)* %bptr, align @CAP_BYTES@
  %arrayidx = getelementptr inbounds i8, i8 addrspace(200)* %a, i64 2
  %0 = bitcast i8 addrspace(200)*  %arrayidx to i32 addrspace(200)*
  %cmp = icmp eq i32 addrspace(200)* %0, %b
  ret i1 %cmp
}

define i1 @freeze(i8 addrspace(200)* addrspace(200)* nocapture readonly %aptr, i32 addrspace(200)* addrspace(200)* %bptr) {
entry:
  %a = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %aptr, align @CAP_BYTES@
  %b = load i32 addrspace(200)*, i32 addrspace(200)* addrspace(200)* %bptr, align @CAP_BYTES@
  %arrayidx = getelementptr inbounds i8, i8 addrspace(200)* %a, i64 2
  %0 = bitcast i8 addrspace(200)* %arrayidx to i32 addrspace(200)*
  %fr = freeze i32 addrspace(200)* %0
  %cmp = icmp eq i32 addrspace(200)* %0, %b
  ret i1 %cmp
}

define i1 @sel(i32 %q, i8 addrspace(200)* addrspace(200)* nocapture readonly %aptr, i8 addrspace(200)* addrspace(200)* nocapture readonly %bptr) {
entry:
  %a = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %aptr, align @CAP_BYTES@
  %b = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %bptr, align @CAP_BYTES@
  %tobool.not = icmp eq i32 %q, 0
  %b.a = select i1 %tobool.not, i8 addrspace(200)* %b, i8 addrspace(200)* %a
  %cmp = icmp eq i8 addrspace(200)* %b.a, null
  ret i1 %cmp
}

define i1 @testphi(i32 addrspace(200)* addrspace(200)* %aptr) {
entry:
  %a = load i32 addrspace(200)*, i32 addrspace(200)* addrspace(200)* %aptr, align @CAP_BYTES@
  br label %while.cond

while.cond:                                       ; preds = %while.cond, %entry
  %a.addr.0 = phi i32 addrspace(200)* [ %a, %entry ], [ %add.ptr, %while.cond ]
  %0 = bitcast i32 addrspace(200)* %a.addr.0 to i8 addrspace(200)*
  %1 = tail call iCAPRANGE @llvm.cheri.cap.address.get.iCAPRANGE(i8 addrspace(200)* %0)
  %call = tail call i32 @cond(iCAPRANGE %1)
  %tobool.not = icmp eq i32 %call, 0
  %add.ptr = getelementptr inbounds i32, i32 addrspace(200)* %a.addr.0, i64 4
  br i1 %tobool.not, label %while.end, label %while.cond

while.end:                                        ; preds = %while.cond
  %cmp = icmp eq i32 addrspace(200)*  %a.addr.0 , null
  ret i1 %cmp
}

declare i32 @cond(iCAPRANGE)

declare iCAPRANGE @llvm.cheri.cap.address.get.iCAPRANGE(i8 addrspace(200)*)

define i1 @addrset(i8 addrspace(200)* addrspace(200)* nocapture readonly %c, iCAPRANGE %val) {
entry:
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %c, align @CAP_BYTES@
  %1 = tail call i8 addrspace(200)* @llvm.cheri.cap.address.set.iCAPRANGE(i8 addrspace(200)* %0, iCAPRANGE %val)
  %cmp = icmp eq i8 addrspace(200)*  %1 , null
  ret i1 %cmp
}

declare i8 addrspace(200)* @llvm.cheri.cap.address.set.iCAPRANGE(i8 addrspace(200)*, iCAPRANGE)

define i1 @permsand(i8 addrspace(200)* addrspace(200)* nocapture readonly %c, iCAPRANGE %val) {
entry:
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %c, align @CAP_BYTES@
  %1 = tail call i8 addrspace(200)* @llvm.cheri.cap.perms.and.i64(i8 addrspace(200)* %0, iCAPRANGE %val)
  %cmp = icmp eq i8 addrspace(200)*  %1 , null
  ret i1 %cmp
}

declare i8 addrspace(200)* @llvm.cheri.cap.perms.and.iCAPRANGE(i8 addrspace(200)*, iCAPRANGE)

define i1 @boundsset(i8 addrspace(200)* addrspace(200)* nocapture readonly %c, iCAPRANGE %val) {
entry:
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %c, align @CAP_BYTES@
  %1 = tail call i8 addrspace(200)* @llvm.cheri.cap.bounds.set.iCAPRANGE(i8 addrspace(200)* %0, iCAPRANGE %val)
  %cmp = icmp eq i8 addrspace(200)*  %1 , null
  ret i1 %cmp
}

declare i8 addrspace(200)* @llvm.cheri.cap.bounds.set.iCAPRANGE(i8 addrspace(200)*, iCAPRANGE)

define i1 @boundssetexact(i8 addrspace(200)* addrspace(200)* nocapture readonly %c, iCAPRANGE %val) {
entry:
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %c, align @CAP_BYTES@
  %1 = tail call i8 addrspace(200)* @llvm.cheri.cap.bounds.set.exact.iCAPRANGE(i8 addrspace(200)* %0, iCAPRANGE %val)
  %cmp = icmp eq i8 addrspace(200)*  %1 , null
  ret i1 %cmp
}

declare i8 addrspace(200)* @llvm.cheri.cap.bounds.set.exact.iCAPRANGE(i8 addrspace(200)*, iCAPRANGE)

define i1 @capcmp(i8 addrspace(200)* addrspace(200)* nocapture readonly %a, i8 addrspace(200)* addrspace(200)* nocapture readonly %b) {
entry:
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %a, align @CAP_BYTES@
  %1 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %b, align @CAP_BYTES@
  %2 = icmp eq i8 addrspace(200)* %0, %1
  ret i1 %2
}

define iCAPRANGE @addrget(i8 addrspace(200)* addrspace(200)* nocapture readonly %a) {
entry:
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %a, align @CAP_BYTES@
  %1 = tail call iCAPRANGE @llvm.cheri.cap.address.get.iCAPRANGE(i8 addrspace(200)* %0)
  ret iCAPRANGE %1
}

define iCAPRANGE @capdiff(i8 addrspace(200)* addrspace(200)* nocapture readonly %a, i8 addrspace(200)* addrspace(200)* nocapture readonly %b) {
entry:
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %a, align @CAP_BYTES@
  %1 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %b, align @CAP_BYTES@
  %2 = tail call iCAPRANGE @llvm.cheri.cap.diff.iCAPRANGE(i8 addrspace(200)* %0, i8 addrspace(200)* %1)
  ret iCAPRANGE %2
}

declare iCAPRANGE @llvm.cheri.cap.diff.iCAPRANGE(i8 addrspace(200)*, i8 addrspace(200)*)

declare i32 @bar()

define i32 @foo(i8 addrspace(200)* addrspace(200)* nocapture readonly %a) {
entry:
  %0 = load i8 addrspace(200)*, i8 addrspace(200)* addrspace(200)* %a, align @CAP_BYTES@
  %cmp3 = icmp slt i8 addrspace(200)* %0, getelementptr (i8, i8 addrspace(200)* null, i64 22)
  br i1 %cmp3, label %while.body.preheader, label %while.end

while.body.preheader:                             ; preds = %entry
  br label %while.body

while.body:                                       ; preds = %while.body.preheader, %while.body
  %b.04 = phi i8 addrspace(200)* [ %3, %while.body ], [ %0, %while.body.preheader ]
  %call = tail call i32 @bar()
  %1 = tail call iCAPRANGE @llvm.cheri.cap.address.get.iCAPRANGE(i8 addrspace(200)* %b.04)
  %add = add nsw iCAPRANGE %1, 6
  %2 = getelementptr i8, i8 addrspace(200)* %b.04, i64 6
  %and = and iCAPRANGE %add, 45055
  %3 = tail call i8 addrspace(200)* @llvm.cheri.cap.address.set.iCAPRANGE(i8 addrspace(200)* %2, iCAPRANGE %and)
  %cmp = icmp slt i8 addrspace(200)* %3, getelementptr (i8, i8 addrspace(200)* null, i64 22)
  br i1 %cmp, label %while.body, label %while.end.loopexit

while.end.loopexit:                               ; preds = %while.body
  br label %while.end

while.end:                                        ; preds = %while.end.loopexit, %entry
  ret i32 0
}
