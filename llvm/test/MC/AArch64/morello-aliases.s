// RUN: llvm-mc -triple=arm64 -mattr=+morello -show-encoding < %s | FileCheck %s
// RUN: llvm-mc -triple=arm64 -mattr=+morello  -filetype=obj < %s -o - | \
// RUN:     llvm-objdump --no-print-imm-hex --mattr=+morello -d - |  FileCheck %s

// Load byte, alternate
    ldurb w13, [csp]
    ldrb w22, [c3]
    ldrb w13, [csp, #-4]
    ldursb x11, [c7]
    ldrsb x21, [c5]
    ldrsb x21, [c5, #4]
    ldursb w15, [c26]
    ldrsb w18, [c27]
    ldrsb w18, [c27, #4]
// CHECK:	ldurb	w13, [csp, #0]
// CHECK:	ldurb	w22, [c3, #0]
// CHECK:	ldurb	w13, [csp, #-4]
// CHECK:	ldursb	x11, [c7, #0]
// CHECK:	ldursb	x21, [c5, #0]
// CHECK:	ldursb	x21, [c5, #4]
// CHECK:	ldursb	w15, [c26, #0]
// CHECK:	ldursb	w18, [c27, #0]
// CHECK:	ldursb	w18, [c27, #4]

// Load half, alternate
    ldurh w13, [csp]
    ldrh w22, [c3]
    ldrh w22, [c3, #4]
    ldursh x11, [c7]
    ldrsh x21, [c5]
    ldrsh x21, [c5, #4]
    ldursh w15, [c26]
    ldrsh w18, [c27]
    ldrsh w18, [c27, #4]
// CHECK:	ldurh	w13, [csp, #0]
// CHECK:	ldurh	w22, [c3, #0]
// CHECK:	ldurh	w22, [c3, #4]
// CHECK:	ldursh	x11, [c7, #0]
// CHECK:	ldursh	x21, [c5, #0]
// CHECK:	ldursh	x21, [c5, #4]
// CHECK:	ldursh	w15, [c26, #0]
// CHECK:	ldursh	w18, [c27, #0]
// CHECK:	ldursh	w18, [c27, #4]

// Load word, alternate
    ldur w16, [csp]
    ldr  w15, [csp]
    ldr  w15, [csp, #-4]
    ldursw x17, [c27]
    ldrsw x13, [c5]
    ldrsw x13, [c5, #8]
// CHECK:	ldur	w16, [csp, #0]
// CHECK:	ldur	w15, [csp, #0]
// CHECK:	ldur	w15, [csp, #-4]
// CHECK:	ldursw	x17, [c27, #0]
// CHECK:	ldursw	x13, [c5, #0]
// CHECK:	ldursw	x13, [c5, #8]

// Load double-word, alternate
    ldur x13, [c0]
    ldr x25, [c7]
    ldr x25, [c7, #-8]
// CHECK:	ldur	x13, [c0, #0]
// CHECK:	ldur	x25, [c7, #0]
// CHECK:	ldur	x25, [c7, #-8]

// Load fp, alternate
    ldur b5, [csp]
    ldr  b7, [c5]
    ldr  b9, [c6, #8]
    ldur h7, [csp]
    ldr  h9, [c2]
    ldr  h9, [c2, #8]
    ldur s5, [csp]
    ldr  s5, [csp]
    ldr  s7, [csp, #8]
    ldur d5, [c29]
    ldr  d6, [c28]
    ldr  d7, [c27, #8]
    ldur q5, [c3]
    ldr  q6, [c2]
    ldr  q7, [c1, #8]
// CHECK:	ldur	b5, [csp]
// CHECK:	ldur	b7, [c5]
// CHECK:	ldur	b9, [c6, #8]
// CHECK:	ldur	h7, [csp, #0]
// CHECK:	ldur	h9, [c2, #0]
// CHECK:	ldur	h9, [c2, #8]
// CHECK:	ldur	s5, [csp, #0]
// CHECK:	ldur	s5, [csp, #0]
// CHECK:	ldur	s7, [csp, #8]
// CHECK:	ldur	d5, [c29, #0]
// CHECK:	ldur	d6, [c28, #0]
// CHECK:	ldur	d7, [c27, #8]
// CHECK:	ldur	q5, [c3, #0]
// CHECK:	ldur	q6, [c2, #0]
// CHECK:	ldur	q7, [c1, #8]

// Load capability, alternate
    ldur c7, [c2]
    ldr  c2, [c0]
    ldr  c3, [c4, #-16]
// CHECK:	ldur	c7, [c2, #0]
// CHECK:	ldr	c2, [c0, #0]
// CHECK:	ldur	c3, [c4, #-16]

// Load capability
    ldur c2, [x0]
    ldr  c2, [x0]
    ldr  c3, [x4, #16]
    ldr  c3, [x4, #-7]
// CHECK:	ldur	c2, [x0, #0]
// CHECK:	ldr	c2, [x0, #0]
// CHECK:	ldr	c3, [x4, #16]
// CHECK:	ldur	c3, [x4, #-7]

// Store byte, alternate
    sturb w13, [csp]
    strb w22, [c3]
    strb w13, [csp, #-4]
// CHECK:	sturb	w13, [csp, #0]
// CHECK:	sturb	w22, [c3, #0]
// CHECK:	sturb	w13, [csp, #-4]

// Store half, alternate
    sturh w13, [csp]
    strh w22, [c3]
    strh w22, [c3, #4]
// CHECK:	sturh	w13, [csp, #0]
// CHECK:	sturh	w22, [c3, #0]
// CHECK:	sturh	w22, [c3, #4]

// Store word, alternate
    stur w16, [csp]
    str  w15, [csp]
    str  w15, [csp, #-4]
// CHECK:	stur	w16, [csp, #0]
// CHECK:	stur	w15, [csp, #0]
// CHECK:	stur	w15, [csp, #-4]

// Store double word, alternate
    stur x13, [c0]
    str x25, [c7]
    str x25, [c7, #-8]
// CHECK:	stur	x13, [c0, #0]
// CHECK:	stur	x25, [c7, #0]
// CHECK:	stur	x25, [c7, #-8]

// Store FP, alternate
    stur b5, [csp]
    str  b7, [c5]
    str  b9, [c6, #8]
    stur h7, [csp]
    str  h9, [c2]
    str  h9, [c2, #8]
    stur s5, [csp]
    str  s5, [csp]
    str  s7, [csp, #8]
    stur d5, [c29]
    str  d6, [c28]
    str  d7, [c27, #8]
    stur q5, [c3]
    str  q6, [c2]
    str  q7, [c1, #8]
// CHECK:	stur	b5, [csp, #0]
// CHECK:	stur	b7, [c5, #0]
// CHECK:	stur	b9, [c6, #8]
// CHECK:	stur	h7, [csp, #0]
// CHECK:	stur	h9, [c2, #0]
// CHECK:	stur	h9, [c2, #8]
// CHECK:	stur	s5, [csp, #0]
// CHECK:	stur	s5, [csp, #0]
// CHECK:	stur	s7, [csp, #8]
// CHECK:	stur	d5, [c29, #0]
// CHECK:	stur	d6, [c28, #0]
// CHECK:	stur	d7, [c27, #8]
// CHECK:	stur	q5, [c3, #0]
// CHECK:	stur	q6, [c2, #0]
// CHECK:	stur	q7, [c1, #8]

// Store capability alternate
    stur c7, [c2]
    str  c2, [c0]
    str  c3, [c4, #-16]
// CHECK:	stur	c7, [c2, #0]
// CHECK:	str	c2, [c0, #0]
// CHECK:	stur	c3, [c4, #-16]

// Store capability
    stur c2, [x0]
    str  c2, [x0]
    str  c3, [x4, #16]
    str  c3, [x4, #-7]
// CHECK:	stur	c2, [x0, #0]
// CHECK:	str	c2, [x0, #0]
// CHECK:	str	c3, [x4, #16]
// CHECK:	stur	c3, [x4, #-7]

// Various misc load/store aliases
   sttr c1, [x0]
   ldtr c1, [x0]
   stp c0, c1, [x2]
   ldp c0, c1, [x2]
// CHECK:   sttr c1, [x0, #0]
// CHECK:   ldtr c1, [x0, #0]
// CHECK:   stp c0, c1, [x2, #0]
// CHECK:   ldp c0, c1, [x2, #0]

   cmp c1, c2
   subs xzr, c1, c2
// CHECK: cmp c1, c2
// CHECK: cmp c1, c2

   retr
   rets
// CHECK: retr c30
// CHECK: rets c30
