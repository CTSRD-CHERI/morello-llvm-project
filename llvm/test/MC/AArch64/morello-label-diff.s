// RUN: llvm-mc -triple=aarch64-linux-gnu -mattr=+morello,+c64 \
// RUN:         -filetype=obj -o - %s| llvm-readobj -r - | \
// RUN: FileCheck %s

.type	foo,@function
.type	bar,@function
foo:
	br	c0
.Ltmp0:
.LBB0_1:
	mov	w0, #1
	ret	c30
.Ltmp1:
bar:
	mov	w0, #2
	ret	c30
.Lfunc_end0:
foo.labels:
	.chericap foo+((.Ltmp0+1)-foo)
	.chericap foo+((.Ltmp1+1)-foo)
	.chericap foo+(foo-(.Ltmp0+1))
	.chericap foo+(bar-foo)

// CHECK: Relocations [
// CHECK-NEXT:  Section (3) .rela.text {
// CHECK-NEXT:    0x20 R_MORELLO_CAPINIT foo 0x4
// CHECK-NEXT:    0x30 R_MORELLO_CAPINIT foo 0xC
// CHECK-NEXT:    0x40 R_MORELLO_CAPINIT foo 0xFFFFFFFFFFFFFFFC
// CHECK-NEXT:    0x50 R_MORELLO_CAPINIT foo 0xC
// CHECK-NEXT:  }
// CHECK-NEXT: ]
