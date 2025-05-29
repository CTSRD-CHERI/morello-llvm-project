; RUN: llc < %s -mtriple=arm64-eabi -mattr=+c64,+morello -target-abi purecap | FileCheck %s

@a = common addrspace(200) global ptr addrspace(200) null, align 8

%struct.S = type { i32, i32, i32, i32, i32, i32 }

define void @test(i32 %i, i32 %j) nounwind ssp {
entry:
  ; CHECK: @test
  %j.addr = alloca %struct.S, align 4, addrspace(200)
  %j.addr1 = getelementptr inbounds i32, ptr addrspace(200) %j.addr, i64 1
  ; CHECK: prfum pldl1strm, [c{{.*}}, #4]
  call void @llvm.prefetch.p200(ptr addrspace(200) %j.addr1, i32 0, i32 0, i32 1)
  ; CHECK: prfum pldl3keep, [c{{.*}}, #4]
  call void @llvm.prefetch.p200(ptr addrspace(200) %j.addr1, i32 0, i32 1, i32 1)
  ; CHECK: prfum pldl2keep, [c{{.*}}, #4]
  call void @llvm.prefetch.p200(ptr addrspace(200) %j.addr1, i32 0, i32 2, i32 1)
  ; CHECK: prfum pldl1keep, [c{{.*}}, #4]
  call void @llvm.prefetch.p200(ptr addrspace(200) %j.addr1, i32 0, i32 3, i32 1)

  ; CHECK: prfum plil1strm, [c{{.*}}, #4]
  call void @llvm.prefetch.p200(ptr addrspace(200) %j.addr1, i32 0, i32 0, i32 0)
  ; CHECK: prfum plil3keep, [c{{.*}}, #4]
  call void @llvm.prefetch.p200(ptr addrspace(200) %j.addr1, i32 0, i32 1, i32 0)
  ; CHECK: prfum plil2keep, [c{{.*}}, #4]
  call void @llvm.prefetch.p200(ptr addrspace(200) %j.addr1, i32 0, i32 2, i32 0)
  ; CHECK: prfum plil1keep, [c{{.*}}, #4]
  call void @llvm.prefetch.p200(ptr addrspace(200) %j.addr1, i32 0, i32 3, i32 0)

  ; CHECK: prfum pstl1strm, [c{{.*}}, #4]
  call void @llvm.prefetch.p200(ptr addrspace(200) %j.addr1, i32 1, i32 0, i32 1)
  ; CHECK: prfum pstl3keep, [c{{.*}}, #4]
  call void @llvm.prefetch.p200(ptr addrspace(200) %j.addr1, i32 1, i32 1, i32 1)
  ; CHECK: prfum pstl2keep, [c{{.*}}, #4]
  call void @llvm.prefetch.p200(ptr addrspace(200) %j.addr1, i32 1, i32 2, i32 1)
  ; CHECK: prfum pstl1keep, [c{{.*}}, #4]
  call void @llvm.prefetch.p200(ptr addrspace(200) %j.addr1, i32 1, i32 3, i32 1)

  %tmp1 = load i32, ptr addrspace(200) %j.addr1, align 4, !tbaa !0
  %add = add nsw i32 %tmp1, %i
  %idxprom = sext i32 %add to i64
  %tmp2 = load ptr addrspace(200), ptr addrspace(200) @a, align 8, !tbaa !3
  %arrayidx = getelementptr inbounds i32, ptr addrspace(200) %tmp2, i64 %idxprom

  ; CHECK: prfm pldl1strm, [c{{.*}}]
  call void @llvm.prefetch.p200(ptr addrspace(200) %arrayidx, i32 0, i32 0, i32 1)
  %tmp4 = load ptr addrspace(200), ptr addrspace(200) @a, align 8, !tbaa !3
  %arrayidx3 = getelementptr inbounds i32, ptr addrspace(200) %tmp4, i64 %idxprom

  ; CHECK: prfm pldl3keep, [c{{.*}}]
  call void @llvm.prefetch.p200(ptr addrspace(200) %arrayidx3, i32 0, i32 1, i32 1)
  %tmp6 = load ptr addrspace(200), ptr addrspace(200) @a, align 8, !tbaa !3
  %arrayidx6 = getelementptr inbounds i32, ptr addrspace(200) %tmp6, i64 %idxprom

  ; CHECK: prfm pldl2keep, [c{{.*}}]
  call void @llvm.prefetch.p200(ptr addrspace(200) %arrayidx6, i32 0, i32 2, i32 1)
  %tmp8 = load ptr addrspace(200), ptr addrspace(200) @a, align 8, !tbaa !3
  %arrayidx9 = getelementptr inbounds i32, ptr addrspace(200) %tmp8, i64 %idxprom

  ; CHECK: prfm pldl1keep, [c{{.*}}]
  call void @llvm.prefetch.p200(ptr addrspace(200) %arrayidx9, i32 0, i32 3, i32 1)
  %tmp10 = load ptr addrspace(200), ptr addrspace(200) @a, align 8, !tbaa !3
  %arrayidx12 = getelementptr inbounds i32, ptr addrspace(200) %tmp10, i64 %idxprom

  ; CHECK: prfm plil1strm, [c{{.*}}]
  call void @llvm.prefetch.p200(ptr addrspace(200) %arrayidx12, i32 0, i32 0, i32 0)
  %tmp12 = load ptr addrspace(200), ptr addrspace(200) @a, align 8, !tbaa !3
  %arrayidx15 = getelementptr inbounds i32, ptr addrspace(200) %tmp12, i64 %idxprom

  ; CHECK: prfm plil3keep, [c{{.*}}]
  call void @llvm.prefetch.p200(ptr addrspace(200) %arrayidx3, i32 0, i32 1, i32 0)
  %tmp14 = load ptr addrspace(200), ptr addrspace(200) @a, align 8, !tbaa !3
  %arrayidx18 = getelementptr inbounds i32, ptr addrspace(200) %tmp14, i64 %idxprom

  ; CHECK: prfm plil2keep, [c{{.*}}]
  call void @llvm.prefetch.p200(ptr addrspace(200) %arrayidx6, i32 0, i32 2, i32 0)
  %tmp16 = load ptr addrspace(200), ptr addrspace(200) @a, align 8, !tbaa !3
  %arrayidx21 = getelementptr inbounds i32, ptr addrspace(200) %tmp16, i64 %idxprom

  ; CHECK: prfm plil1keep, [c{{.*}}]
  call void @llvm.prefetch.p200(ptr addrspace(200) %arrayidx9, i32 0, i32 3, i32 0)
  %tmp18 = load ptr addrspace(200), ptr addrspace(200) @a, align 8, !tbaa !3
  %arrayidx24 = getelementptr inbounds i32, ptr addrspace(200) %tmp18, i64 %idxprom

  ; CHECK: prfm pstl1strm, [c{{.*}}]
  call void @llvm.prefetch.p200(ptr addrspace(200) %arrayidx12, i32 1, i32 0, i32 1)
  %tmp20 = load ptr addrspace(200), ptr addrspace(200) @a, align 8, !tbaa !3
  %arrayidx27 = getelementptr inbounds i32, ptr addrspace(200) %tmp20, i64 %idxprom

  ; CHECK: prfm pstl3keep, [c{{.*}}]
  call void @llvm.prefetch.p200(ptr addrspace(200) %arrayidx15, i32 1, i32 1, i32 1)
  %tmp22 = load ptr addrspace(200), ptr addrspace(200) @a, align 8, !tbaa !3
  %arrayidx30 = getelementptr inbounds i32, ptr addrspace(200) %tmp22, i64 %idxprom

  ; CHECK: prfm pstl2keep, [c{{.*}}]
  call void @llvm.prefetch.p200(ptr addrspace(200) %arrayidx18, i32 1, i32 2, i32 1)
  %tmp24 = load ptr addrspace(200), ptr addrspace(200) @a, align 8, !tbaa !3
  %arrayidx33 = getelementptr inbounds i32, ptr addrspace(200) %tmp24, i64 %idxprom

  ; CHECK: prfm pstl1keep, [c{{.*}}]
  call void @llvm.prefetch.p200(ptr addrspace(200) %arrayidx21, i32 1, i32 3, i32 1)
  ret void
}

declare void @llvm.prefetch.p200(ptr addrspace(200) nocapture, i32, i32, i32) nounwind

!0 = !{!"int", !1}
!1 = !{!"omnipotent char", !2}
!2 = !{!"Simple C/C++ TBAA"}
!3 = !{!"any pointer", !1}
