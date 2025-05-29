; RUN: llc -mtriple=arm64 -mattr=+c64,+morello -target-abi purecap -relocation-model=pic -o - %s | FileCheck %s
; RUN: llc -mtriple=arm64 -mattr=+c64,+morello -target-abi purecap  -o - %s | FileCheck %s

; RUN: llc -mtriple=arm64 -mattr=+c64,+morello -o - -relocation-model=pic -filetype=obj -target-abi purecap %s | \
; RUN: llvm-readobj -r - | FileCheck %s --check-prefix=c64-relocs

; CHECK-LABEL: jumpfun
; CHECK: adrp c[[JT:[0-9]+]], .LJT
; CHECK: add c[[JT]], c[[JT]], :lo12:.LJT
; CHECK: adr c[[BB:[0-9]+]], .LBB0_2
; CHECK: ldrb w[[REG:[0-9]+]], [c[[JT]], x[[INDEX:[0-9]+]]]
; CHECK: add c[[CAP:[0-9]+]], c[[BB]], x[[REG]], uxtx #2
; CHECK: cvtp x[[ADDR:[0-9]+]], c[[CAP]]
; CHECK: br x[[ADDR]]

define ptr addrspace(200) @jumpfun(i32 %a) {
entry:
  switch i32 %a, label %sw.default [
    i32 0, label %sw.bb
    i32 1, label %sw.bb.1
    i32 2, label %sw.bb.3
    i32 3, label %sw.bb.6
    i32 4, label %return
  ]

sw.bb:
  %0 = tail call ptr addrspace(200) @llvm.cheri.cap.offset.set(ptr addrspace(200) null, i64 3)
  br label %return

sw.bb.1:
  %1 = tail call ptr addrspace(200) @llvm.cheri.cap.offset.set(ptr addrspace(200) null, i64 2)
  br label %return

sw.bb.3:
  %2 = tail call ptr addrspace(200) @llvm.cheri.cap.offset.set(ptr addrspace(200) null, i64 16)
  br label %return

sw.bb.6:
  %3 = tail call ptr addrspace(200) @llvm.cheri.cap.offset.set(ptr addrspace(200) null, i64 60)
  br label %return

sw.default:
  %4 = tail call ptr addrspace(200) @llvm.cheri.cap.offset.set(ptr addrspace(200) null, i64 1)
  br label %return

return:
  %retval.0 = phi ptr addrspace(200) [ %4, %sw.default ], [ %3, %sw.bb.6 ], [ %2, %sw.bb.3 ], [ %1, %sw.bb.1 ], [ %0, %sw.bb ], [ null, %entry ]
  ret ptr addrspace(200) %retval.0
}
; CHECK-LABEL: .LJTI0_0:
; CHECK-NEXT: .byte (.LBB0_2-.LBB0_2)>>2
; CHECK-NEXT: .byte (.LBB0_4-.LBB0_2)>>2
; CHECK-NEXT: .byte (.LBB0_5-.LBB0_2)>>2
; CHECK-NEXT: .byte (.LBB0_6-.LBB0_2)>>2
; CHECK-NEXT: .byte (.LBB0_7-.LBB0_2)>>2

; CHECK-LABEL: half_jt
; CHECK: adrp c[[JT:[0-9]+]], .LJT
; CHECK: add c[[JT]], c[[JT]], :lo12:.LJT
; CHECK: adr c[[BB:[0-9]+]], .LBB1_2
; CHECK: ldrh w[[REG:[0-9]+]], [c[[JT]], x[[INDEX:[0-9]+]], lsl #1]
; CHECK: add c[[CAP:[0-9]+]], c[[BB]], x[[REG]], uxtx #2
; CHECK: cvtp x[[ADDR:[0-9]+]], c[[CAP]]
; CHECK: br x[[ADDR]]
define ptr addrspace(200) @half_jt(i32 %a) {
entry:
  switch i32 %a, label %sw.default [
    i32 0, label %sw.bb
    i32 1, label %sw.bb.1
    i32 2, label %sw.bb.3
    i32 3, label %sw.bb.6
    i32 4, label %sw.bb.7
    i32 5, label %return
  ]

sw.bb:
  %0 = tail call ptr addrspace(200) @llvm.cheri.cap.offset.set(ptr addrspace(200) null, i64 3)
  br label %return


sw.bb.6:
  %foo = call i64 @llvm.aarch64.space(i32 2048, i64 undef)
  br label %return

sw.bb.7:
  %bat = call i64 @llvm.aarch64.space(i32 2048, i64 undef)
  br label %return

sw.bb.1:
  %1 = tail call ptr addrspace(200) @llvm.cheri.cap.offset.set(ptr addrspace(200) null, i64 2)
  br label %return

sw.bb.3:
  %2 = tail call ptr addrspace(200) @llvm.cheri.cap.offset.set(ptr addrspace(200) null, i64 16)
  br label %return

sw.default:
  %3 = tail call ptr addrspace(200) @llvm.cheri.cap.offset.set(ptr addrspace(200) null, i64 1)
  br label %return

return:
  %retval.0 = phi ptr addrspace(200) [ %3, %sw.default ], [ null, %sw.bb.6 ], [ null, %sw.bb.7 ], [ %2, %sw.bb.3 ], [ %1, %sw.bb.1 ], [ %0, %sw.bb ], [ null, %entry ]
  ret ptr addrspace(200) %retval.0
}

; CHECK-LABEL: .LJTI1_0:
; CHECK-NEXT: .hword (.LBB1_5-.LBB1_2)>>2
; CHECK-NEXT: .hword (.LBB1_6-.LBB1_2)>>2
; CHECK-NEXT: .hword (.LBB1_7-.LBB1_2)>>2
; CHECK-NEXT: .hword (.LBB1_2-.LBB1_2)>>2
; CHECK-NEXT: .hword (.LBB1_2-.LBB1_2)>>2
; CHECK-NEXT: .hword (.LBB1_3-.LBB1_2)>>2

; CHECK-LABEL: word_jt
; CHECK: adrp c[[JT:[0-9]+]], .LJT
; CHECK: add c[[JT]], c[[JT]], :lo12:.LJT
; CHECK-LABEL: .Ltmp0
; CHECK: adr c[[PC:[0-9]+]], .Ltmp0
; CHECK: ldrsw x[[REG:[0-9]+]], [c[[JT]], x[[INDEX:[0-9]+]], lsl #2]
; CHECK: add c[[CAP:[0-9]+]], c[[PC]], x[[REG]], uxtx
; CHECK: cvtp x[[ADDR:[0-9]+]], c[[CAP]]
; CHECK: br x[[ADDR]]

define ptr addrspace(200) @word_jt(i32 %a) {
entry:
  switch i32 %a, label %sw.default [
    i32 0, label %sw.bb
    i32 1, label %sw.bb.1
    i32 2, label %sw.bb.3
    i32 3, label %sw.bb.6
    i32 4, label %sw.bb.7
    i32 5, label %return
  ]

sw.bb:
  %0 = tail call ptr addrspace(200) @llvm.cheri.cap.offset.set(ptr addrspace(200) null, i64 3)
  br label %return


sw.bb.6:
  %bar = call i64 @llvm.aarch64.space(i32 262144, i64 undef)
  br label %return

sw.bb.7:
  %baz = call i64 @llvm.aarch64.space(i32 262144, i64 undef)
  br label %return

sw.bb.1:
  %1 = tail call ptr addrspace(200) @llvm.cheri.cap.offset.set(ptr addrspace(200) null, i64 2)
  br label %return

sw.bb.3:
  %2 = tail call ptr addrspace(200) @llvm.cheri.cap.offset.set(ptr addrspace(200) null, i64 16)
  br label %return

sw.default:
  %3 = tail call ptr addrspace(200) @llvm.cheri.cap.offset.set(ptr addrspace(200) null, i64 1)
  br label %return

return:
  %retval.0 = phi ptr addrspace(200) [ %3, %sw.default ], [ null, %sw.bb.6 ], [ null, %sw.bb.7 ], [ %2, %sw.bb.3 ], [ %1, %sw.bb.1 ], [ %0, %sw.bb ], [ null, %entry ]
  ret ptr addrspace(200) %retval.0
}

declare ptr addrspace(200) @llvm.cheri.cap.offset.set(ptr addrspace(200), i64)
declare i64 @llvm.aarch64.space(i32, i64)

; CHECK-LABEL: .LJTI2_0:
; CHECK-NEXT: .word .LBB2_5-.Ltmp0
; CHECK-NEXT: .word .LBB2_6-.Ltmp0
; CHECK-NEXT: .word .LBB2_7-.Ltmp0
; CHECK-NEXT: .word .LBB2_2-.Ltmp0
; CHECK-NEXT: .word .LBB2_2-.Ltmp0
; CHECK-NEXT: .word .LBB2_3-.Ltmp0

; c64-relocs: Relocations [
; c64-relocs-NEXT:  Section {{.*}} .rela.text {
; c64-relocs-NEXT:    0xC R_MORELLO_ADR_PREL_PG_HI20 .rodata 0x0
; c64-relocs-NEXT:    0x10 R_AARCH64_ADD_ABS_LO12_NC .rodata 0x0
; c64-relocs-NEXT:    0x8C R_MORELLO_ADR_PREL_PG_HI20 .rodata 0x6
; c64-relocs-NEXT:    0x90 R_AARCH64_ADD_ABS_LO12_NC .rodata 0x6
; c64-relocs-NEXT:    0xFC R_MORELLO_ADR_PREL_PG_HI20 .rodata 0x14
; c64-relocs-NEXT:    0x100 R_AARCH64_ADD_ABS_LO12_NC .rodata 0x14
; c64-relocs-NEXT:  }
; c64-relocs-NEXT:  Section {{.*}} .rela.eh_frame {
; c64-relocs-NEXT:    0x20 R_AARCH64_PREL32 .text 0x0
; c64-relocs-NEXT:    0x34 R_AARCH64_PREL32 .text 0x80
; c64-relocs-NEXT:    0x48 R_AARCH64_PREL32 .text 0xF0
; c64-relocs-NEXT:  }
; c64-relocs-NEXT: ]
