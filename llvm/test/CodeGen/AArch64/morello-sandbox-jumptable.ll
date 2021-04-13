; RUN: llc -mtriple=arm64 -mattr=+c64,+morello -target-abi purecap -relocation-model=pic -o - %s | FileCheck %s
; RUN: llc -mtriple=arm64 -mattr=+c64,+morello -target-abi purecap  -o - %s | FileCheck %s

; RUN: llc -mtriple=arm64 -mattr=+c64,+morello -o - -relocation-model=pic -filetype=obj -target-abi purecap %s | \
; RUN: llvm-readobj -r | FileCheck %s --check-prefix=c64-relocs

; CHECK-LABEL: jumpfun
; CHECK: adrp c[[JT:[0-9]+]], .LJT
; CHECK: add c[[JT]], c[[JT]], :lo12:.LJT
; CHECK: adr c[[BB:[0-9]+]], .LBB0_2+1
; CHECK: ldrb w[[REG:[0-9]+]], [c[[JT]], x[[INDEX:[0-9]+]]]
; CHECK: add c[[ADDR:[0-9]+]], c[[BB]], x[[REG]], uxtx #2
; CHECK: br c[[ADDR]]

define i32 addrspace(200)* @jumpfun(i32 %a) {
entry:
  switch i32 %a, label %sw.default [
    i32 0, label %sw.bb
    i32 1, label %sw.bb.1
    i32 2, label %sw.bb.3
    i32 3, label %sw.bb.6
    i32 4, label %return
  ]

sw.bb:
  %0 = tail call i8 addrspace(200)* @llvm.cheri.cap.offset.set(i8 addrspace(200)* null, i64 3)
  %1 = bitcast i8 addrspace(200)* %0 to i32 addrspace(200)*
  br label %return

sw.bb.1:
  %2 = tail call i8 addrspace(200)* @llvm.cheri.cap.offset.set(i8 addrspace(200)* null, i64 2)
  %3 = bitcast i8 addrspace(200)* %2 to i32 addrspace(200)*
  br label %return

sw.bb.3:
  %4 = tail call i8 addrspace(200)* @llvm.cheri.cap.offset.set(i8 addrspace(200)* null, i64 16)
  %5 = bitcast i8 addrspace(200)* %4 to i32 addrspace(200)*
  br label %return

sw.bb.6:
  %6 = tail call i8 addrspace(200)* @llvm.cheri.cap.offset.set(i8 addrspace(200)* null, i64 60)
  %7 = bitcast i8 addrspace(200)* %6 to i32 addrspace(200)*
  br label %return

sw.default:
  %8 = tail call i8 addrspace(200)* @llvm.cheri.cap.offset.set(i8 addrspace(200)* null, i64 1)
  %9 = bitcast i8 addrspace(200)* %8 to i32 addrspace(200)*
  br label %return

return:
  %retval.0 = phi i32 addrspace(200)* [ %9, %sw.default ], [ %7, %sw.bb.6 ], [ %5, %sw.bb.3 ], [ %3, %sw.bb.1 ], [ %1, %sw.bb ], [ null, %entry ]
  ret i32 addrspace(200)* %retval.0
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
; CHECK: adr c[[BB:[0-9]+]], .LBB1_2+1
; CHECK: ldrh w[[REG:[0-9]+]], [c[[JT]], x[[INDEX:[0-9]+]], lsl #1]
; CHECK: add c[[ADDR:[0-9]+]], c[[BB]], x[[REG]], uxtx #2
; CHECK: br c[[ADDR]]
define i32 addrspace(200)* @half_jt(i32 %a) {
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
  %0 = tail call i8 addrspace(200)* @llvm.cheri.cap.offset.set(i8 addrspace(200)* null, i64 3)
  %1 = bitcast i8 addrspace(200)* %0 to i32 addrspace(200)*
  br label %return


sw.bb.6:
  call void asm sideeffect ".space 2048", ""()
  br label %return

sw.bb.7:
  call void asm sideeffect ".space 2048", ""()
  br label %return

sw.bb.1:
  %2 = tail call i8 addrspace(200)* @llvm.cheri.cap.offset.set(i8 addrspace(200)* null, i64 2)
  %3 = bitcast i8 addrspace(200)* %2 to i32 addrspace(200)*
  br label %return

sw.bb.3:
  %4 = tail call i8 addrspace(200)* @llvm.cheri.cap.offset.set(i8 addrspace(200)* null, i64 16)
  %5 = bitcast i8 addrspace(200)* %4 to i32 addrspace(200)*
  br label %return

sw.default:
  %6 = tail call i8 addrspace(200)* @llvm.cheri.cap.offset.set(i8 addrspace(200)* null, i64 1)
  %7 = bitcast i8 addrspace(200)* %6 to i32 addrspace(200)*
  br label %return

return:
  %retval.0 = phi i32 addrspace(200)* [ %7, %sw.default ], [ null, %sw.bb.6 ], [ null, %sw.bb.7 ], [ %5, %sw.bb.3 ], [ %3, %sw.bb.1 ], [ %1, %sw.bb ], [ null, %entry ]
  ret i32 addrspace(200)* %retval.0
}

; CHECK-LABEL: .LJTI1_0:
; CHECK-NEXT: .hword (.LBB1_2-.LBB1_2)>>2
; CHECK-NEXT: .hword (.LBB1_4-.LBB1_2)>>2
; CHECK-NEXT: .hword (.LBB1_5-.LBB1_2)>>2
; CHECK-NEXT: .hword (.LBB1_6-.LBB1_2)>>2
; CHECK-NEXT: .hword (.LBB1_8-.LBB1_2)>>2
; CHECK-NEXT: .hword (.LBB1_7-.LBB1_2)>>2

; CHECK-LABEL: word_jt
; CHECK: adrp c[[JT:[0-9]+]], .LJT
; CHECK: add c[[JT]], c[[JT]], :lo12:.LJT
; CHECK: ldrsw x[[REG:[0-9]+]], [c[[JT]], x[[INDEX:[0-9]+]], lsl #2]
; CHECK: add c[[ADDR:[0-9]+]], c[[JT]], x[[REG]], uxtx
; CHECK: br c[[ADDR]]

define i32 addrspace(200)* @word_jt(i32 %a) {
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
  %0 = tail call i8 addrspace(200)* @llvm.cheri.cap.offset.set(i8 addrspace(200)* null, i64 3)
  %1 = bitcast i8 addrspace(200)* %0 to i32 addrspace(200)*
  br label %return


sw.bb.6:
  call void asm sideeffect ".space 262144", ""()
  br label %return

sw.bb.7:
  call void asm sideeffect ".space 262144", ""()
  br label %return

sw.bb.1:
  %2 = tail call i8 addrspace(200)* @llvm.cheri.cap.offset.set(i8 addrspace(200)* null, i64 2)
  %3 = bitcast i8 addrspace(200)* %2 to i32 addrspace(200)*
  br label %return

sw.bb.3:
  %4 = tail call i8 addrspace(200)* @llvm.cheri.cap.offset.set(i8 addrspace(200)* null, i64 16)
  %5 = bitcast i8 addrspace(200)* %4 to i32 addrspace(200)*
  br label %return

sw.default:
  %6 = tail call i8 addrspace(200)* @llvm.cheri.cap.offset.set(i8 addrspace(200)* null, i64 1)
  %7 = bitcast i8 addrspace(200)* %6 to i32 addrspace(200)*
  br label %return

return:
  %retval.0 = phi i32 addrspace(200)* [ %7, %sw.default ], [ null, %sw.bb.6 ], [ null, %sw.bb.7 ], [ %5, %sw.bb.3 ], [ %3, %sw.bb.1 ], [ %1, %sw.bb ], [ null, %entry ]
  ret i32 addrspace(200)* %retval.0
}

declare i8 addrspace(200)* @llvm.cheri.cap.offset.set(i8 addrspace(200)*, i64)

; CHECK-LABEL: .LJTI2_0:
; CHECK-NEXT: .word	(.LBB2_2-.LJTI2_0)+1
; CHECK-NEXT: .word	(.LBB2_4-.LJTI2_0)+1
; CHECK-NEXT: .word	(.LBB2_5-.LJTI2_0)+1
; CHECK-NEXT: .word	(.LBB2_6-.LJTI2_0)+1
; CHECK-NEXT: .word	(.LBB2_8-.LJTI2_0)+1
; CHECK-NEXT: .word	(.LBB2_7-.LJTI2_0)+1

; c64-relocs: Relocations [
; c64-relocs-NEXT:  Section (3) .rela.text {
; c64-relocs-NEXT:   0xC R_MORELLO_ADR_PREL_PG_HI20 .rodata 0x0
; c64-relocs-NEXT:   0x10 R_AARCH64_ADD_ABS_LO12_NC .rodata 0x0
; c64-relocs-NEXT:   0x88 R_MORELLO_ADR_PREL_PG_HI20 .rodata 0x6
; c64-relocs-NEXT:   0x8C R_AARCH64_ADD_ABS_LO12_NC .rodata 0x6
; c64-relocs-NEXT:   0x10FC R_MORELLO_ADR_PREL_PG_HI20 .rodata 0x14
; c64-relocs-NEXT:   0x1100 R_AARCH64_ADD_ABS_LO12_NC .rodata 0x14
; c64-relocs-NEXT: }
; c64-relocs-NEXT: Section (5) .rela.rodata {
; c64-relocs-NEXT:   0x14 R_AARCH64_PREL32 .text 0x1111
; c64-relocs-NEXT:   0x18 R_AARCH64_PREL32 .text 0x1135
; c64-relocs-NEXT:   0x1C R_AARCH64_PREL32 .text 0x1149
; c64-relocs-NEXT:   0x20 R_AARCH64_PREL32 .text 0x115D
; c64-relocs-NEXT:   0x24 R_AARCH64_PREL32 .text 0x41169
; c64-relocs-NEXT:   0x28 R_AARCH64_PREL32 .text 0x41165
; c64-relocs-NEXT: }
; c64-relocs-NEXT: Section (8) .rela.eh_frame {
; c64-relocs-NEXT:   0x20 R_AARCH64_PREL32 .text 0x0
; c64-relocs-NEXT:   0x34 R_AARCH64_PREL32 .text 0x7C
; c64-relocs-NEXT:   0x48 R_AARCH64_PREL32 .text 0x10F0
; c64-relocs-NEXT: }
; c64-relocs-NEXT: ]
