; RUN: llc -mtriple=arm64 -verify-machineinstrs -mattr=+c64,+morello -target-abi purecap -aarch64-enable-sandbox-globals-opt=false < %s | FileCheck %s --check-prefix=C64 --check-prefix=ALL
; RUN: llc -mtriple=arm64 -verify-machineinstrs -mattr=+c64,+morello -filetype=obj -aarch64-enable-sandbox-globals-opt=false -target-abi purecap < %s | llvm-objdump --mattr=+morello --disassemble - -r | FileCheck %s --check-prefix=C64D
; RUN: llc -mtriple=arm64 -verify-machineinstrs -mattr=+c64,+morello -filetype=obj -aarch64-enable-sandbox-globals-opt=false -target-abi purecap < %s | llvm-objdump --disassemble - -r | FileCheck %s --check-prefix=C64D

; C64-LABEL: testConstantPool0
; C64-DAG: adrp {{x|c}}[[cpaddr:[0-9]+]], .LCPI0_0
; C64-DAG: ldr q0, [c[[cpaddr]], :lo12:.LCPI0_0]

; C64D-LABEL: testConstantPool0
; C64D: ldr q0, [c0]
; C64D-NEXT: R_AARCH64_LDST128_ABS_LO12_NC
define fp128 @testConstantPool0() {
entry:
  ret fp128 0xL00000000000000000000000000000000
}

declare extern_weak void @bar(i8 addrspace(200)*)
declare i8 addrspace(200)* @llvm.cheri.pcc.get()
declare i8 addrspace(200)* @llvm.cheri.cap.from.pointer(i8 addrspace(200)*, i64)
