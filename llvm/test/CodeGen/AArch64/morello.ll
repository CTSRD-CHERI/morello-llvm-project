; RUN: llc -mtriple=arm64 -mattr=+morello -o - %s | FileCheck %s
; RUN: llc -mtriple=arm64 -mattr=+morello,+c64 -target-abi purecap -o - %s | FileCheck %s
; CHECK-NOT:	(ignoring feature)
