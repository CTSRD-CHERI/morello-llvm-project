;; Copied from arm64-memory.s, try to keep this in sync
; RUN: llvm-mc -triple arm64-apple-darwin --mattr=+morello,+c64 -show-encoding < %s | FileCheck %s

foo:
;-----------------------------------------------------------------------------
; Indexed loads
;-----------------------------------------------------------------------------

  ldr    w5, [c4, #20]
  ldr    x4, [c3]
  ldr    c4, [c3]
  ldr    x2, [csp, #32]
  ldr    c2, [csp, #32]
  ldr    b5, [csp, #1]
  ldr    h6, [csp, #2]
  ldr    s7, [csp, #4]
  ldr    d8, [csp, #8]
  ldr    q9, [csp, #16]
  ldrb   w4, [c3]
  ldrb   w5, [c4, #20]
  ldrb	 w2, [c3, _foo@pageoff]
  ldrb   w3, [c2, "+[Test method].var"@PAGEOFF]
  ldrsb  w9, [c3]
  ldrsb  x2, [csp, #128]
  ldrh   w2, [csp, #32]
  ldrsh  w3, [csp, #32]
  ldrsh  x5, [c9, #24]
  ldrsw  x9, [csp, #512]

  prfm   #5, [csp, #32]
  prfm   #31, [csp, #32]
  prfm   pldl1keep, [c2]
  prfm   pldl1strm, [c2]
  prfm   pldl2keep, [c2]
  prfm   pldl2strm, [c2]
  prfm   pldl3keep, [c2]
  prfm   pldl3strm, [c2]
  prfm   pstl1keep, [c2]
  prfm   pstl1strm, [c2]
  prfm   pstl2keep, [c2]
  prfm   pstl2strm, [c2]
  prfm   pstl3keep, [c2]
  prfm   pstl3strm, [c2]
  prfm  pstl3strm, [c4, x5, lsl #3]

; CHECK: ldr    w5, [c4, #20]           ; encoding: [0x85,0x14,0x40,0xb9]
; CHECK-NEXT: ldr    x4, [c3]                 ; encoding: [0x64,0x00,0x40,0xf9]
; CHECK-NEXT: ldr    c4, [c3, #0]             ; encoding: [0x64,0x00,0x40,0xc2]
; CHECK-NEXT: ldr    x2, [csp, #32]           ; encoding: [0xe2,0x13,0x40,0xf9]
; CHECK-NEXT: ldr    c2, [csp, #32]           ; encoding: [0xe2,0x0b,0x40,0xc2]
; CHECK-NEXT: ldr    b5, [csp, #1]            ; encoding: [0xe5,0x07,0x40,0x3d]
; CHECK-NEXT: ldr    h6, [csp, #2]            ; encoding: [0xe6,0x07,0x40,0x7d]
; CHECK-NEXT: ldr    s7, [csp, #4]            ; encoding: [0xe7,0x07,0x40,0xbd]
; CHECK-NEXT: ldr    d8, [csp, #8]            ; encoding: [0xe8,0x07,0x40,0xfd]
; CHECK-NEXT: ldr    q9, [csp, #16]           ; encoding: [0xe9,0x07,0xc0,0x3d]
; CHECK-NEXT: ldrb   w4, [c3]                ; encoding: [0x64,0x00,0x40,0x39]
; CHECK-NEXT: ldrb   w5, [c4, #20]           ; encoding: [0x85,0x50,0x40,0x39]
; CHECK-NEXT: ldrb	w2, [c3, _foo@PAGEOFF]  ; encoding: [0x62,0bAAAAAA00,0b01AAAAAA,0x39]
; CHECK-NEXT: ; fixup A - offset: 0, value: _foo@PAGEOFF, kind: fixup_aarch64_ldst_imm12_scale1
; CHECK-NEXT: ldrb	w3, [c2, "+[Test method].var"@PAGEOFF] ; encoding: [0x43,0bAAAAAA00,0b01AAAAAA,0x39]
; CHECK-NEXT: ; fixup A - offset: 0, value: "+[Test method].var"@PAGEOFF, kind: fixup_aarch64_ldst_imm12_scale1
; CHECK-NEXT: ldrsb  w9, [c3]                ; encoding: [0x69,0x00,0xc0,0x39]
; CHECK-NEXT: ldrsb  x2, [csp, #128]          ; encoding: [0xe2,0x03,0x82,0x39]
; CHECK-NEXT: ldrh   w2, [csp, #32]           ; encoding: [0xe2,0x43,0x40,0x79]
; CHECK-NEXT: ldrsh  w3, [csp, #32]           ; encoding: [0xe3,0x43,0xc0,0x79]
; CHECK-NEXT: ldrsh  x5, [c9, #24]           ; encoding: [0x25,0x31,0x80,0x79]
; CHECK-NEXT: ldrsw  x9, [csp, #512]          ; encoding: [0xe9,0x03,0x82,0xb9]

; CHECK:      prfm   pldl3strm, [csp, #32]    ; encoding: [0xe5,0x13,0x80,0xf9]
; CHECK-NEXT: prfm	#31, [csp, #32]          ; encoding: [0xff,0x13,0x80,0xf9]
; CHECK-NEXT: prfm   pldl1keep, [c2]         ; encoding: [0x40,0x00,0x80,0xf9]
; CHECK-NEXT: prfm   pldl1strm, [c2]         ; encoding: [0x41,0x00,0x80,0xf9]
; CHECK-NEXT: prfm   pldl2keep, [c2]         ; encoding: [0x42,0x00,0x80,0xf9]
; CHECK-NEXT: prfm   pldl2strm, [c2]         ; encoding: [0x43,0x00,0x80,0xf9]
; CHECK-NEXT: prfm   pldl3keep, [c2]         ; encoding: [0x44,0x00,0x80,0xf9]
; CHECK-NEXT: prfm   pldl3strm, [c2]         ; encoding: [0x45,0x00,0x80,0xf9]
; CHECK-NEXT: prfm   pstl1keep, [c2]         ; encoding: [0x50,0x00,0x80,0xf9]
; CHECK-NEXT: prfm   pstl1strm, [c2]         ; encoding: [0x51,0x00,0x80,0xf9]
; CHECK-NEXT: prfm   pstl2keep, [c2]         ; encoding: [0x52,0x00,0x80,0xf9]
; CHECK-NEXT: prfm   pstl2strm, [c2]         ; encoding: [0x53,0x00,0x80,0xf9]
; CHECK-NEXT: prfm   pstl3keep, [c2]         ; encoding: [0x54,0x00,0x80,0xf9]
; CHECK-NEXT: prfm   pstl3strm, [c2]         ; encoding: [0x55,0x00,0x80,0xf9]
; CHECK-NEXT: prfm	pstl3strm, [c4, x5, lsl #3] ; encoding: [0x95,0x78,0xa5,0xf8]

;-----------------------------------------------------------------------------
; Indexed stores
;-----------------------------------------------------------------------------

  str   x4, [c3]
  str   c4, [c3]
  str   x2, [csp, #32]
  str   c2, [csp, #32]
  str   w5, [c4, #20]
  str   b5, [csp, #1]
  str   h6, [csp, #2]
  str   s7, [csp, #4]
  str   d8, [csp, #8]
  str   q9, [csp, #16]
  strb  w4, [c3]
  strb  w5, [c4, #20]
  strh  w2, [csp, #32]

; CHECK:      str   x4, [c3]                  ; encoding: [0x64,0x00,0x00,0xf9]
; CHECK-NEXT: str   c4, [c3, #0]              ; encoding: [0x64,0x00,0x00,0xc2]
; CHECK-NEXT: str   x2, [csp, #32]            ; encoding: [0xe2,0x13,0x00,0xf9]
; CHECK-NEXT: str   c2, [csp, #32]            ; encoding: [0xe2,0x0b,0x00,0xc2]
; CHECK-NEXT: str   w5, [c4, #20]             ; encoding: [0x85,0x14,0x00,0xb9]
; CHECK-NEXT: str   b5, [csp, #1]             ; encoding: [0xe5,0x07,0x00,0x3d]
; CHECK-NEXT: str   h6, [csp, #2]             ; encoding: [0xe6,0x07,0x00,0x7d]
; CHECK-NEXT: str   s7, [csp, #4]             ; encoding: [0xe7,0x07,0x00,0xbd]
; CHECK-NEXT: str   d8, [csp, #8]             ; encoding: [0xe8,0x07,0x00,0xfd]
; CHECK-NEXT: str   q9, [csp, #16]            ; encoding: [0xe9,0x07,0x80,0x3d]
; CHECK-NEXT: strb  w4, [c3]                  ; encoding: [0x64,0x00,0x00,0x39]
; CHECK-NEXT: strb  w5, [c4, #20]             ; encoding: [0x85,0x50,0x00,0x39]
; CHECK-NEXT: strh  w2, [csp, #32]            ; encoding: [0xe2,0x43,0x00,0x79]

;-----------------------------------------------------------------------------
; Unscaled immediate loads and stores
;-----------------------------------------------------------------------------

  ldur    w2, [c3]
  ldur    w2, [csp, #24]
  ldur    x2, [c3]
  ldur    c2, [c3]
  ldur    x2, [csp, #24]
  ldur    c2, [csp, #24]
  ldur    b5, [csp, #1]
  ldur    h6, [csp, #2]
  ldur    s7, [csp, #4]
  ldur    d8, [csp, #8]
  ldur    q9, [csp, #16]
  ldursb  w9, [c3]
  ldursb  x2, [csp, #128]
  ldursh  w3, [csp, #32]
  ldursh  x5, [c9, #24]
  ldursw  x9, [csp, #-128]

; CHECK: ldur    w2, [c3]               ; encoding: [0x62,0x00,0x40,0xb8]
; CHECK-NEXT: ldur    w2, [csp, #24]          ; encoding: [0xe2,0x83,0x41,0xb8]
; CHECK-NEXT: ldur    x2, [c3]                ; encoding: [0x62,0x00,0x40,0xf8]
; CHECK-NEXT: ldur    c2, [c3, #0]            ; encoding: [0x62,0x00,0x40,0xa2]
; CHECK-NEXT: ldur    x2, [csp, #24]          ; encoding: [0xe2,0x83,0x41,0xf8]
; CHECK-NEXT: ldur    c2, [csp, #24]          ; encoding: [0xe2,0x83,0x41,0xa2]
; CHECK-NEXT: ldur    b5, [csp, #1]           ; encoding: [0xe5,0x13,0x40,0x3c]
; CHECK-NEXT: ldur    h6, [csp, #2]           ; encoding: [0xe6,0x23,0x40,0x7c]
; CHECK-NEXT: ldur    s7, [csp, #4]           ; encoding: [0xe7,0x43,0x40,0xbc]
; CHECK-NEXT: ldur    d8, [csp, #8]           ; encoding: [0xe8,0x83,0x40,0xfc]
; CHECK-NEXT: ldur    q9, [csp, #16]          ; encoding: [0xe9,0x03,0xc1,0x3c]
; CHECK-NEXT: ldursb  w9, [c3]               ; encoding: [0x69,0x00,0xc0,0x38]
; CHECK-NEXT: ldursb  x2, [csp, #128]         ; encoding: [0xe2,0x03,0x88,0x38]
; CHECK-NEXT: ldursh  w3, [csp, #32]          ; encoding: [0xe3,0x03,0xc2,0x78]
; CHECK-NEXT: ldursh  x5, [c9, #24]          ; encoding: [0x25,0x81,0x81,0x78]
; CHECK-NEXT: ldursw  x9, [csp, #-128]        ; encoding: [0xe9,0x03,0x98,0xb8]

  stur    w4, [c3]
  stur    w2, [csp, #32]
  stur    x4, [c3]
  stur    c4, [c3]
  stur    x2, [csp, #32]
  stur    c2, [csp, #32]
  stur    w5, [c4, #20]
  stur    b5, [csp, #1]
  stur    h6, [csp, #2]
  stur    s7, [csp, #4]
  stur    d8, [csp, #8]
  stur    q9, [csp, #16]
  sturb   w4, [c3]
  sturb   w5, [c4, #20]
  sturh   w2, [csp, #32]
  prfum   #5, [csp, #32]

; CHECK: stur    w4, [c3]               ; encoding: [0x64,0x00,0x00,0xb8]
; CHECK-NEXT: stur    w2, [csp, #32]          ; encoding: [0xe2,0x03,0x02,0xb8]
; CHECK-NEXT: stur    x4, [c3]               ; encoding: [0x64,0x00,0x00,0xf8]
; CHECK-NEXT: stur    c4, [c3, #0]            ; encoding: [0x64,0x00,0x00,0xa2]
; CHECK-NEXT: stur    x2, [csp, #32]          ; encoding: [0xe2,0x03,0x02,0xf8]
; CHECK-NEXT: stur    c2, [csp, #32]          ; encoding: [0xe2,0x03,0x02,0xa2]
; CHECK-NEXT: stur    w5, [c4, #20]          ; encoding: [0x85,0x40,0x01,0xb8]
; CHECK-NEXT: stur    b5, [csp, #1]           ; encoding: [0xe5,0x13,0x00,0x3c]
; CHECK-NEXT: stur    h6, [csp, #2]           ; encoding: [0xe6,0x23,0x00,0x7c]
; CHECK-NEXT: stur    s7, [csp, #4]           ; encoding: [0xe7,0x43,0x00,0xbc]
; CHECK-NEXT: stur    d8, [csp, #8]           ; encoding: [0xe8,0x83,0x00,0xfc]
; CHECK-NEXT: stur    q9, [csp, #16]          ; encoding: [0xe9,0x03,0x81,0x3c]
; CHECK-NEXT: sturb   w4, [c3]               ; encoding: [0x64,0x00,0x00,0x38]
; CHECK-NEXT: sturb   w5, [c4, #20]          ; encoding: [0x85,0x40,0x01,0x38]
; CHECK-NEXT: sturh   w2, [csp, #32]          ; encoding: [0xe2,0x03,0x02,0x78]
; CHECK-NEXT: prfum   pldl3strm, [csp, #32]   ; encoding: [0xe5,0x03,0x82,0xf8]

;-----------------------------------------------------------------------------
; Unprivileged loads and stores
;-----------------------------------------------------------------------------

  ldtr    w3, [c4, #16]
  ldtr    x3, [c4, #16]
  ldtrb   w3, [c4, #16]
  ldtrsb  w9, [c3]
  ldtrsb  x2, [csp, #128]
  ldtrh   w3, [c4, #16]
  ldtrsh  w3, [csp, #32]
  ldtrsh  x5, [c9, #24]
  ldtrsw  x9, [csp, #-128]

; CHECK: ldtr   w3, [c4, #16]           ; encoding: [0x83,0x08,0x41,0xb8]
; CHECK-NEXT: ldtr   x3, [c4, #16]           ; encoding: [0x83,0x08,0x41,0xf8]
; CHECK-NEXT: ldtrb  w3, [c4, #16]           ; encoding: [0x83,0x08,0x41,0x38]
; CHECK-NEXT: ldtrsb w9, [c3]                ; encoding: [0x69,0x08,0xc0,0x38]
; CHECK-NEXT: ldtrsb x2, [csp, #128]          ; encoding: [0xe2,0x0b,0x88,0x38]
; CHECK-NEXT: ldtrh  w3, [c4, #16]           ; encoding: [0x83,0x08,0x41,0x78]
; CHECK-NEXT: ldtrsh w3, [csp, #32]           ; encoding: [0xe3,0x0b,0xc2,0x78]
; CHECK-NEXT: ldtrsh x5, [c9, #24]           ; encoding: [0x25,0x89,0x81,0x78]
; CHECK-NEXT: ldtrsw x9, [csp, #-128]         ; encoding: [0xe9,0x0b,0x98,0xb8]

  sttr    w5, [c4, #20]
  sttr    x4, [c3]
  sttr    x2, [csp, #32]
  sttrb   w4, [c3]
  sttrb   w5, [c4, #20]
  sttrh   w2, [csp, #32]

; CHECK: sttr   w5, [c4, #20]           ; encoding: [0x85,0x48,0x01,0xb8]
; CHECK-NEXT: sttr   x4, [c3]                ; encoding: [0x64,0x08,0x00,0xf8]
; CHECK-NEXT: sttr   x2, [csp, #32]           ; encoding: [0xe2,0x0b,0x02,0xf8]
; CHECK-NEXT: sttrb  w4, [c3]                ; encoding: [0x64,0x08,0x00,0x38]
; CHECK-NEXT: sttrb  w5, [c4, #20]           ; encoding: [0x85,0x48,0x01,0x38]
; CHECK-NEXT: sttrh  w2, [csp, #32]           ; encoding: [0xe2,0x0b,0x02,0x78]

;-----------------------------------------------------------------------------
; Pre-indexed loads and stores
;-----------------------------------------------------------------------------

  ldr   x29, [c7, #8]!
  ldr   x30, [c7, #8]!
  ldr   b5, [c0, #1]!
  ldr   h6, [c0, #2]!
  ldr   s7, [c0, #4]!
  ldr   d8, [c0, #8]!
  ldr   q9, [c0, #16]!

  str   x30, [c7, #-8]!
  str   x29, [c7, #-8]!
  str   b5, [c0, #-1]!
  str   h6, [c0, #-2]!
  str   s7, [c0, #-4]!
  str   d8, [c0, #-8]!
  str   q9, [c0, #-16]!

; CHECK: ldr  x29, [c7, #8]!             ; encoding: [0xfd,0x8c,0x40,0xf8]
; CHECK-NEXT: ldr  x30, [c7, #8]!             ; encoding: [0xfe,0x8c,0x40,0xf8]
; CHECK-NEXT: ldr  b5, [c0, #1]!             ; encoding: [0x05,0x1c,0x40,0x3c]
; CHECK-NEXT: ldr  h6, [c0, #2]!             ; encoding: [0x06,0x2c,0x40,0x7c]
; CHECK-NEXT: ldr  s7, [c0, #4]!             ; encoding: [0x07,0x4c,0x40,0xbc]
; CHECK-NEXT: ldr  d8, [c0, #8]!             ; encoding: [0x08,0x8c,0x40,0xfc]
; CHECK-NEXT: ldr  q9, [c0, #16]!            ; encoding: [0x09,0x0c,0xc1,0x3c]

; CHECK: str  x30, [c7, #-8]!            ; encoding: [0xfe,0x8c,0x1f,0xf8]
; CHECK-NEXT: str  x29, [c7, #-8]!            ; encoding: [0xfd,0x8c,0x1f,0xf8]
; CHECK-NEXT: str  b5, [c0, #-1]!            ; encoding: [0x05,0xfc,0x1f,0x3c]
; CHECK-NEXT: str  h6, [c0, #-2]!            ; encoding: [0x06,0xec,0x1f,0x7c]
; CHECK-NEXT: str  s7, [c0, #-4]!            ; encoding: [0x07,0xcc,0x1f,0xbc]
; CHECK-NEXT: str  d8, [c0, #-8]!            ; encoding: [0x08,0x8c,0x1f,0xfc]
; CHECK-NEXT: str  q9, [c0, #-16]!           ; encoding: [0x09,0x0c,0x9f,0x3c]

;-----------------------------------------------------------------------------
; post-indexed loads and stores
;-----------------------------------------------------------------------------
  str x30, [c7], #-8
  str x29, [c7], #-8
  str b5, [c0], #-1
  str h6, [c0], #-2
  str s7, [c0], #-4
  str d8, [c0], #-8
  str q9, [c0], #-16

  ldr x29, [c7], #8
  ldr x30, [c7], #8
  ldr b5, [c0], #1
  ldr h6, [c0], #2
  ldr s7, [c0], #4
  ldr d8, [c0], #8
  ldr q9, [c0], #16

; CHECK: str x30, [c7], #-8             ; encoding: [0xfe,0x84,0x1f,0xf8]
; CHECK-NEXT: str x29, [c7], #-8             ; encoding: [0xfd,0x84,0x1f,0xf8]
; CHECK-NEXT: str b5, [c0], #-1             ; encoding: [0x05,0xf4,0x1f,0x3c]
; CHECK-NEXT: str h6, [c0], #-2             ; encoding: [0x06,0xe4,0x1f,0x7c]
; CHECK-NEXT: str s7, [c0], #-4             ; encoding: [0x07,0xc4,0x1f,0xbc]
; CHECK-NEXT: str d8, [c0], #-8             ; encoding: [0x08,0x84,0x1f,0xfc]
; CHECK-NEXT: str q9, [c0], #-16            ; encoding: [0x09,0x04,0x9f,0x3c]

; CHECK: ldr x29, [c7], #8              ; encoding: [0xfd,0x84,0x40,0xf8]
; CHECK-NEXT: ldr x30, [c7], #8              ; encoding: [0xfe,0x84,0x40,0xf8]
; CHECK-NEXT: ldr b5, [c0], #1              ; encoding: [0x05,0x14,0x40,0x3c]
; CHECK-NEXT: ldr h6, [c0], #2              ; encoding: [0x06,0x24,0x40,0x7c]
; CHECK-NEXT: ldr s7, [c0], #4              ; encoding: [0x07,0x44,0x40,0xbc]
; CHECK-NEXT: ldr d8, [c0], #8              ; encoding: [0x08,0x84,0x40,0xfc]
; CHECK-NEXT: ldr q9, [c0], #16             ; encoding: [0x09,0x04,0xc1,0x3c]

;-----------------------------------------------------------------------------
; Load/Store pair (indexed, offset)
;-----------------------------------------------------------------------------

  ldp    w3, w2, [c15, #16]
  ldp    x4, x9, [csp, #-16]
  ldp    c4, c9, [csp, #-16]
  ldpsw  x2, x3, [c14, #16]
  ldpsw  x2, x3, [csp, #-16]
  ldp    s10, s1, [c2, #64]
  ldp    d10, d1, [c2]
  ldp    q2, q3, [c0, #32]

; CHECK: ldp    w3, w2, [c15, #16]      ; encoding: [0xe3,0x09,0x42,0x29]
; CHECK-NEXT: ldp    x4, x9, [csp, #-16]      ; encoding: [0xe4,0x27,0x7f,0xa9]
; CHECK-NEXT: ldp    c4, c9, [csp, #-16]      ; encoding: [0xe4,0xa7,0xff,0x42]
; CHECK-NEXT: ldpsw  x2, x3, [c14, #16]      ; encoding: [0xc2,0x0d,0x42,0x69]
; CHECK-NEXT: ldpsw  x2, x3, [csp, #-16]      ; encoding: [0xe2,0x0f,0x7e,0x69]
; CHECK-NEXT: ldp    s10, s1, [c2, #64]      ; encoding: [0x4a,0x04,0x48,0x2d]
; CHECK-NEXT: ldp    d10, d1, [c2]           ; encoding: [0x4a,0x04,0x40,0x6d]
; CHECK-NEXT: ldp    q2, q3, [c0, #32]       ; encoding: [0x02,0x0c,0x41,0xad]

  stp    w3, w2, [c15, #16]
  stp    x4, x9, [csp, #-16]
  stp    c4, c9, [csp, #-16]
  stp    s10, s1, [c2, #64]
  stp    d10, d1, [c2]
  stp    q2, q3, [c0, #32]

; CHECK: stp    w3, w2, [c15, #16]      ; encoding: [0xe3,0x09,0x02,0x29]
; CHECK-NEXT: stp    x4, x9, [csp, #-16]      ; encoding: [0xe4,0x27,0x3f,0xa9]
; CHECK-NEXT: stp    c4, c9, [csp, #-16]      ; encoding: [0xe4,0xa7,0xbf,0x42]
; CHECK-NEXT: stp    s10, s1, [c2, #64]      ; encoding: [0x4a,0x04,0x08,0x2d]
; CHECK-NEXT: stp    d10, d1, [c2]           ; encoding: [0x4a,0x04,0x00,0x6d]
; CHECK-NEXT: stp    q2, q3, [c0, #32]       ; encoding: [0x02,0x0c,0x01,0xad]

;-----------------------------------------------------------------------------
; Load/Store pair (pre-indexed)
;-----------------------------------------------------------------------------

  ldp    w3, w2, [c15, #16]!
  ldp    x4, x9, [csp, #-16]!
  ldpsw  x2, x3, [c14, #16]!
  ldpsw  x2, x3, [csp, #-16]!
  ldp    s10, s1, [c2, #64]!
  ldp    d10, d1, [c2, #16]!

; CHECK: ldp  w3, w2, [c15, #16]!       ; encoding: [0xe3,0x09,0xc2,0x29]
; CHECK-NEXT: ldp  x4, x9, [csp, #-16]!       ; encoding: [0xe4,0x27,0xff,0xa9]
; CHECK-NEXT: ldpsw	x2, x3, [c14, #16]!     ; encoding: [0xc2,0x0d,0xc2,0x69]
; CHECK-NEXT: ldpsw	x2, x3, [csp, #-16]!     ; encoding: [0xe2,0x0f,0xfe,0x69]
; CHECK-NEXT: ldp  s10, s1, [c2, #64]!       ; encoding: [0x4a,0x04,0xc8,0x2d]
; CHECK-NEXT: ldp  d10, d1, [c2, #16]!       ; encoding: [0x4a,0x04,0xc1,0x6d]

  stp    w3, w2, [c15, #16]!
  stp    x4, x9, [csp, #-16]!
  stp    s10, s1, [c2, #64]!
  stp    d10, d1, [c2, #16]!

; CHECK: stp  w3, w2, [c15, #16]!       ; encoding: [0xe3,0x09,0x82,0x29]
; CHECK-NEXT: stp  x4, x9, [csp, #-16]!       ; encoding: [0xe4,0x27,0xbf,0xa9]
; CHECK-NEXT: stp  s10, s1, [c2, #64]!       ; encoding: [0x4a,0x04,0x88,0x2d]
; CHECK-NEXT: stp  d10, d1, [c2, #16]!       ; encoding: [0x4a,0x04,0x81,0x6d]

;-----------------------------------------------------------------------------
; Load/Store pair (post-indexed)
;-----------------------------------------------------------------------------

  ldp    w3, w2, [c15], #16
  ldp    x4, x9, [csp], #-16
  ldpsw  x2, x3, [c14], #16
  ldpsw  x2, x3, [csp], #-16
  ldp    s10, s1, [c2], #64
  ldp    d10, d1, [c2], #16

; CHECK: ldp  w3, w2, [c15], #16        ; encoding: [0xe3,0x09,0xc2,0x28]
; CHECK-NEXT: ldp  x4, x9, [csp], #-16        ; encoding: [0xe4,0x27,0xff,0xa8]
; CHECK-NEXT: ldpsw	x2, x3, [c14], #16      ; encoding: [0xc2,0x0d,0xc2,0x68]
; CHECK-NEXT: ldpsw	x2, x3, [csp], #-16      ; encoding: [0xe2,0x0f,0xfe,0x68]
; CHECK-NEXT: ldp  s10, s1, [c2], #64        ; encoding: [0x4a,0x04,0xc8,0x2c]
; CHECK-NEXT: ldp  d10, d1, [c2], #16        ; encoding: [0x4a,0x04,0xc1,0x6c]

  stp    w3, w2, [c15], #16
  stp    x4, x9, [csp], #-16
  stp    s10, s1, [c2], #64
  stp    d10, d1, [c2], #16

; CHECK: stp  w3, w2, [c15], #16        ; encoding: [0xe3,0x09,0x82,0x28]
; CHECK-NEXT: stp  x4, x9, [csp], #-16        ; encoding: [0xe4,0x27,0xbf,0xa8]
; CHECK-NEXT: stp  s10, s1, [c2], #64        ; encoding: [0x4a,0x04,0x88,0x2c]
; CHECK-NEXT: stp  d10, d1, [c2], #16        ; encoding: [0x4a,0x04,0x81,0x6c]

;-----------------------------------------------------------------------------
; Load/Store pair (no-allocate)
;-----------------------------------------------------------------------------

  ldnp  w3, w2, [c15, #16]
  ldnp  x4, x9, [csp, #-16]
  ldnp  s10, s1, [c2, #64]
  ldnp  d10, d1, [c2]

; CHECK: ldnp  w3, w2, [c15, #16]       ; encoding: [0xe3,0x09,0x42,0x28]
; CHECK-NEXT: ldnp  x4, x9, [csp, #-16]       ; encoding: [0xe4,0x27,0x7f,0xa8]
; CHECK-NEXT: ldnp  s10, s1, [c2, #64]       ; encoding: [0x4a,0x04,0x48,0x2c]
; CHECK-NEXT: ldnp  d10, d1, [c2]            ; encoding: [0x4a,0x04,0x40,0x6c]

  stnp  w3, w2, [c15, #16]
  stnp  x4, x9, [csp, #-16]
  stnp  s10, s1, [c2, #64]
  stnp  d10, d1, [c2]

; CHECK: stnp  w3, w2, [c15, #16]       ; encoding: [0xe3,0x09,0x02,0x28]
; CHECK-NEXT: stnp  x4, x9, [csp, #-16]       ; encoding: [0xe4,0x27,0x3f,0xa8]
; CHECK-NEXT: stnp  s10, s1, [c2, #64]       ; encoding: [0x4a,0x04,0x08,0x2c]
; CHECK-NEXT: stnp  d10, d1, [c2]            ; encoding: [0x4a,0x04,0x00,0x6c]

;-----------------------------------------------------------------------------
; Load/Store register offset
;-----------------------------------------------------------------------------

  ldr  w0, [c0, x0]
  ldr  w0, [c0, x0, lsl #2]
  ldr  x0, [c0, x0]
  ldr  x0, [c0, x0, lsl #3]
  ldr  x0, [c0, x0, sxtx]

; CHECK: ldr  w0, [c0, x0]              ; encoding: [0x00,0x68,0x60,0xb8]
; CHECK-NEXT: ldr  w0, [c0, x0, lsl #2]      ; encoding: [0x00,0x78,0x60,0xb8]
; CHECK-NEXT: ldr  x0, [c0, x0]              ; encoding: [0x00,0x68,0x60,0xf8]
; CHECK-NEXT: ldr  x0, [c0, x0, lsl #3]      ; encoding: [0x00,0x78,0x60,0xf8]
; CHECK-NEXT: ldr  x0, [c0, x0, sxtx]        ; encoding: [0x00,0xe8,0x60,0xf8]

  ldr  b1, [c1, x2]
  ldr  b1, [c1, x2, lsl #0]
  ldr  h1, [c1, x2]
  ldr  h1, [c1, x2, lsl #1]
  ldr  s1, [c1, x2]
  ldr  s1, [c1, x2, lsl #2]
  ldr  d1, [c1, x2]
  ldr  d1, [c1, x2, lsl #3]
  ldr  q1, [c1, x2]
  ldr  q1, [c1, x2, lsl #4]

; CHECK: ldr  b1, [c1, x2]              ; encoding: [0x21,0x68,0x62,0x3c]
; CHECK-NEXT: ldr  b1, [c1, x2, lsl #0]      ; encoding: [0x21,0x78,0x62,0x3c]
; CHECK-NEXT: ldr  h1, [c1, x2]              ; encoding: [0x21,0x68,0x62,0x7c]
; CHECK-NEXT: ldr  h1, [c1, x2, lsl #1]      ; encoding: [0x21,0x78,0x62,0x7c]
; CHECK-NEXT: ldr  s1, [c1, x2]              ; encoding: [0x21,0x68,0x62,0xbc]
; CHECK-NEXT: ldr  s1, [c1, x2, lsl #2]      ; encoding: [0x21,0x78,0x62,0xbc]
; CHECK-NEXT: ldr  d1, [c1, x2]              ; encoding: [0x21,0x68,0x62,0xfc]
; CHECK-NEXT: ldr  d1, [c1, x2, lsl #3]      ; encoding: [0x21,0x78,0x62,0xfc]
; CHECK-NEXT: ldr  q1, [c1, x2]              ; encoding: [0x21,0x68,0xe2,0x3c]
; CHECK-NEXT: ldr  q1, [c1, x2, lsl #4]      ; encoding: [0x21,0x78,0xe2,0x3c]

  str  d1, [csp, x3]
  str  d1, [csp, w3, uxtw #3]
  str  q1, [csp, x3]
  str  q1, [csp, w3, uxtw #4]

; CHECK: str  d1, [csp, x3]              ; encoding: [0xe1,0x6b,0x23,0xfc]
; CHECK-NEXT: str  d1, [csp, w3, uxtw #3]     ; encoding: [0xe1,0x5b,0x23,0xfc]
; CHECK-NEXT: str  q1, [csp, x3]              ; encoding: [0xe1,0x6b,0xa3,0x3c]
; CHECK-NEXT: str  q1, [csp, w3, uxtw #4]     ; encoding: [0xe1,0x5b,0xa3,0x3c]

;-----------------------------------------------------------------------------
; Load literal
;-----------------------------------------------------------------------------

  ldr    w5, foo
  ldr    x4, foo
  ldrsw  x9, foo
  prfm   #5, foo

; CHECK: ldr    w5, foo                 ; encoding: [0bAAA00101,A,A,0x18]
; CHECK: ldr    x4, foo                 ; encoding: [0bAAA00100,A,A,0x58]
; CHECK: ldrsw  x9, foo                 ; encoding: [0bAAA01001,A,A,0x98]
; CHECK: prfm   pldl3strm, foo          ; encoding: [0bAAA00101,A,A,0xd8]

;-----------------------------------------------------------------------------
; Load/Store exclusive
;-----------------------------------------------------------------------------

  ldxr   w6, [c1]
  ldxr   x6, [c1]
  ldxrb  w6, [c1]
  ldxrh  w6, [c1]
  ldxp   w7, w3, [c9]
  ldxp   x7, x3, [c9]

; CHECK: ldxrb  w6, [c1]                ; encoding: [0x26,0x7c,0x5f,0x08]
; CHECK-NEXT: ldxrh  w6, [c1]                ; encoding: [0x26,0x7c,0x5f,0x48]
; CHECK-NEXT: ldxp   w7, w3, [c9]            ; encoding: [0x27,0x0d,0x7f,0x88]
; CHECK-NEXT: ldxp   x7, x3, [c9]            ; encoding: [0x27,0x0d,0x7f,0xc8]

  stxr   w1, x4, [c3]
  stxr   w1, w4, [c3]
  stxrb  w1, w4, [c3]
  stxrh  w1, w4, [c3]
  stxp   w1, x2, x6, [c7]
  stxp   w1, w2, w6, [c9]

; CHECK: stxr   w1, x4, [c3]            ; encoding: [0x64,0x7c,0x01,0xc8]
; CHECK-NEXT: stxr   w1, w4, [c3]            ; encoding: [0x64,0x7c,0x01,0x88]
; CHECK-NEXT: stxrb  w1, w4, [c3]            ; encoding: [0x64,0x7c,0x01,0x08]
; CHECK-NEXT: stxrh  w1, w4, [c3]            ; encoding: [0x64,0x7c,0x01,0x48]
; CHECK-NEXT: stxp   w1, x2, x6, [c7]        ; encoding: [0xe2,0x18,0x21,0xc8]
; CHECK-NEXT: stxp   w1, w2, w6, [c9]        ; encoding: [0x22,0x19,0x21,0x88]

;-----------------------------------------------------------------------------
; Load-acquire/Store-release non-exclusive
;-----------------------------------------------------------------------------

  ldar   w4, [csp]
  ldar   c4, [csp]
  ldar   x4, [csp, #0]
  ldar   c4, [csp, #0]
  ldar   c4, [sp, #0]
  ldarb  w4, [csp]
  ldarb  w4, [csp, #0]
  ldarb  w4, [sp, #0]
  ldarh  w4, [csp]
  ldarh  w4, [csp, #0]

; CHECK:      ldar   w4, [csp]                ; encoding: [0xe4,0xff,0xdf,0x88]
; CHECK-NEXT: ldar   c4, [csp]                ; encoding: [0xe4,0xff,0x5f,0x42]
; CHECK-NEXT: ldar   x4, [csp]                ; encoding: [0xe4,0xff,0xdf,0xc8]
; CHECK-NEXT: ldar   c4, [csp]                ; encoding: [0xe4,0xff,0x5f,0x42]
; CHECK-NEXT: ldar   c4, [sp]                 ; encoding: [0xe4,0x7f,0x5f,0x42]
; CHECK-NEXT: ldarb  w4, [csp]                ; encoding: [0xe4,0xff,0xdf,0x08]
; CHECK-NEXT: ldarb  w4, [csp]                ; encoding: [0xe4,0xff,0xdf,0x08]
; CHECK-NEXT: ldarb  w4, [sp]                 ; encoding: [0xe4,0x7f,0x7f,0x42]
; CHECK-NEXT: ldarh  w4, [csp]                ; encoding: [0xe4,0xff,0xdf,0x48]
; CHECK-NEXT: ldarh  w4, [csp]                ; encoding: [0xe4,0xff,0xdf,0x48]

  stlr   w3, [c6]
  stlr   x3, [c6]
  stlr   c3, [c6]
  stlrb  w3, [c6]
  stlrh  w3, [c6]

  stlr   w3, [c6, #0]
  stlr   x3, [c6, 0]
  stlr   c3, [c6, 0]
  stlr   c3, [c6, #0]
  stlr   c3, [x6, #0]
  stlrb  w3, [csp]
  stlrb  w3, [csp, #0]
  stlrb  w3, [csp, 0]
  stlrb  w3, [sp, 0]
  stlrh  w3, [csp, 0]

; CHECK: stlr   w3, [c6]                ; encoding: [0xc3,0xfc,0x9f,0x88]
; CHECK-NEXT: stlr   x3, [c6]                ; encoding: [0xc3,0xfc,0x9f,0xc8]
; CHECK-NEXT: stlr   c3, [c6]                ; encoding: [0xc3,0xfc,0x1f,0x42]
; CHECK-NEXT: stlrb  w3, [c6]                ; encoding: [0xc3,0xfc,0x9f,0x08]
; CHECK-NEXT: stlrh  w3, [c6]                ; encoding: [0xc3,0xfc,0x9f,0x48]

; CHECK: stlr   w3, [c6]                ; encoding: [0xc3,0xfc,0x9f,0x88]
; CHECK-NEXT: stlr   x3, [c6]                ; encoding: [0xc3,0xfc,0x9f,0xc8]
; CHECK-NEXT: stlr   c3, [c6]                ; encoding: [0xc3,0xfc,0x1f,0x42]
; CHECK-NEXT: stlr   c3, [c6]                ; encoding: [0xc3,0xfc,0x1f,0x42]
; CHECK-NEXT: stlr   c3, [x6]                ; encoding: [0xc3,0x7c,0x1f,0x42]
; CHECK-NEXT: stlrb  w3, [csp]                ; encoding: [0xe3,0xff,0x9f,0x08]
; CHECK-NEXT: stlrb  w3, [csp]                ; encoding: [0xe3,0xff,0x9f,0x08]
; CHECK-NEXT: stlrb  w3, [csp]                ; encoding: [0xe3,0xff,0x9f,0x08]
; CHECK-NEXT: stlrb  w3, [sp]                 ; encoding: [0xe3,0x7f,0x3f,0x42]
; CHECK-NEXT: stlrh  w3, [csp]                ; encoding: [0xe3,0xff,0x9f,0x48] 

;-----------------------------------------------------------------------------
; Load-acquire/Store-release exclusive
;-----------------------------------------------------------------------------

  ldaxr   w2, [c4]
  ldaxr   x2, [c4]
  ldaxrb  w2, [c4, #0]
  ldaxrh  w2, [c4]
  ldaxp   w2, w6, [c1]
  ldaxp   x2, x6, [c1]

; CHECK: ldaxr   w2, [c4]               ; encoding: [0x82,0xfc,0x5f,0x88]
; CHECK-NEXT: ldaxr   x2, [c4]               ; encoding: [0x82,0xfc,0x5f,0xc8]
; CHECK-NEXT: ldaxrb  w2, [c4]               ; encoding: [0x82,0xfc,0x5f,0x08]
; CHECK-NEXT: ldaxrh  w2, [c4]               ; encoding: [0x82,0xfc,0x5f,0x48]
; CHECK-NEXT: ldaxp   w2, w6, [c1]           ; encoding: [0x22,0x98,0x7f,0x88]
; CHECK-NEXT: ldaxp   x2, x6, [c1]           ; encoding: [0x22,0x98,0x7f,0xc8]

  stlxr   w8, x7, [c1]
  stlxr   w8, w7, [c1]
  stlxrb  w8, w7, [c1]
  stlxrh  w8, w7, [c1]
  stlxp   w1, x2, x6, [c7]
  stlxp   w1, w2, w6, [c9]

; CHECK: stlxr  w8, x7, [c1]            ; encoding: [0x27,0xfc,0x08,0xc8]
; CHECK-NEXT: stlxr  w8, w7, [c1]            ; encoding: [0x27,0xfc,0x08,0x88]
; CHECK-NEXT: stlxrb w8, w7, [c1]            ; encoding: [0x27,0xfc,0x08,0x08]
; CHECK-NEXT: stlxrh w8, w7, [c1]            ; encoding: [0x27,0xfc,0x08,0x48]
; CHECK-NEXT: stlxp  w1, x2, x6, [c7]        ; encoding: [0xe2,0x98,0x21,0xc8]
; CHECK-NEXT: stlxp  w1, w2, w6, [c9]        ; encoding: [0x22,0x99,0x21,0x88]


;-----------------------------------------------------------------------------
; LDUR/STUR aliases for negative and unaligned LDR/STR instructions.
;
; According to the ARM ISA documentation:
; "A programmer-friendly assembler should also generate these instructions
; in response to the standard LDR/STR mnemonics when the immediate offset is
; unambiguous, i.e. negative or unaligned."
;-----------------------------------------------------------------------------

  ldr x11, [c29, #-8]
  ldr x11, [c29, #7]
  ldr w0, [c0, #2]
  ldr w0, [c0, #-256]
  ldr b2, [c1, #-2]
  ldr h3, [c2, #3]
  ldr h3, [c3, #-4]
  ldr s3, [c4, #3]
  ldr s3, [c5, #-4]
  ldr d4, [c6, #4]
  ldr d4, [c7, #-8]
  ldr q5, [c8, #8]
  ldr q5, [c9, #-16]

; CHECK: ldur	x11, [c29, #-8]          ; encoding: [0xab,0x83,0x5f,0xf8]
; CHECK-NEXT: ldur	x11, [c29, #7]           ; encoding: [0xab,0x73,0x40,0xf8]
; CHECK-NEXT: ldur	w0, [c0, #2]            ; encoding: [0x00,0x20,0x40,0xb8]
; CHECK-NEXT: ldur	w0, [c0, #-256]         ; encoding: [0x00,0x00,0x50,0xb8]
; CHECK-NEXT: ldur	b2, [c1, #-2]           ; encoding: [0x22,0xe0,0x5f,0x3c]
; CHECK-NEXT: ldur	h3, [c2, #3]            ; encoding: [0x43,0x30,0x40,0x7c]
; CHECK-NEXT: ldur	h3, [c3, #-4]           ; encoding: [0x63,0xc0,0x5f,0x7c]
; CHECK-NEXT: ldur	s3, [c4, #3]            ; encoding: [0x83,0x30,0x40,0xbc]
; CHECK-NEXT: ldur	s3, [c5, #-4]           ; encoding: [0xa3,0xc0,0x5f,0xbc]
; CHECK-NEXT: ldur	d4, [c6, #4]            ; encoding: [0xc4,0x40,0x40,0xfc]
; CHECK-NEXT: ldur	d4, [c7, #-8]           ; encoding: [0xe4,0x80,0x5f,0xfc]
; CHECK-NEXT: ldur	q5, [c8, #8]            ; encoding: [0x05,0x81,0xc0,0x3c]
; CHECK-NEXT: ldur	q5, [c9, #-16]          ; encoding: [0x25,0x01,0xdf,0x3c]

  str x11, [c29, #-8]
  str x11, [c29, #7]
  str w0, [c0, #2]
  str w0, [c0, #-256]
  str b2, [c1, #-2]
  str h3, [c2, #3]
  str h3, [c3, #-4]
  str s3, [c4, #3]
  str s3, [c5, #-4]
  str d4, [c6, #4]
  str d4, [c7, #-8]
  str q5, [c8, #8]
  str q5, [c9, #-16]

; CHECK: stur	x11, [c29, #-8]          ; encoding: [0xab,0x83,0x1f,0xf8]
; CHECK-NEXT: stur	x11, [c29, #7]           ; encoding: [0xab,0x73,0x00,0xf8]
; CHECK-NEXT: stur	w0, [c0, #2]            ; encoding: [0x00,0x20,0x00,0xb8]
; CHECK-NEXT: stur	w0, [c0, #-256]         ; encoding: [0x00,0x00,0x10,0xb8]
; CHECK-NEXT: stur	b2, [c1, #-2]           ; encoding: [0x22,0xe0,0x1f,0x3c]
; CHECK-NEXT: stur	h3, [c2, #3]            ; encoding: [0x43,0x30,0x00,0x7c]
; CHECK-NEXT: stur	h3, [c3, #-4]           ; encoding: [0x63,0xc0,0x1f,0x7c]
; CHECK-NEXT: stur	s3, [c4, #3]            ; encoding: [0x83,0x30,0x00,0xbc]
; CHECK-NEXT: stur	s3, [c5, #-4]           ; encoding: [0xa3,0xc0,0x1f,0xbc]
; CHECK-NEXT: stur	d4, [c6, #4]            ; encoding: [0xc4,0x40,0x00,0xfc]
; CHECK-NEXT: stur	d4, [c7, #-8]           ; encoding: [0xe4,0x80,0x1f,0xfc]
; CHECK-NEXT: stur	q5, [c8, #8]            ; encoding: [0x05,0x81,0x80,0x3c]
; CHECK-NEXT: stur	q5, [c9, #-16]          ; encoding: [0x25,0x01,0x9f,0x3c]

  ldrb w3, [c1, #-1]
  ldrh w4, [c2, #1]
  ldrh w5, [c3, #-1]
  ldrsb w6, [c4, #-1]
  ldrsb x7, [c5, #-1]
  ldrsh w8, [c6, #1]
  ldrsh w9, [c7, #-1]
  ldrsh x1, [c8, #1]
  ldrsh x2, [c9, #-1]
  ldrsw x3, [c10, #10]
  ldrsw x4, [c11, #-1]

; CHECK: ldurb	w3, [c1, #-1]           ; encoding: [0x23,0xf0,0x5f,0x38]
; CHECK-NEXT: ldurh	w4, [c2, #1]            ; encoding: [0x44,0x10,0x40,0x78]
; CHECK-NEXT: ldurh	w5, [c3, #-1]           ; encoding: [0x65,0xf0,0x5f,0x78]
; CHECK-NEXT: ldursb	w6, [c4, #-1]           ; encoding: [0x86,0xf0,0xdf,0x38]
; CHECK-NEXT: ldursb	x7, [c5, #-1]           ; encoding: [0xa7,0xf0,0x9f,0x38]
; CHECK-NEXT: ldursh	w8, [c6, #1]            ; encoding: [0xc8,0x10,0xc0,0x78]
; CHECK-NEXT: ldursh	w9, [c7, #-1]           ; encoding: [0xe9,0xf0,0xdf,0x78]
; CHECK-NEXT: ldursh	x1, [c8, #1]            ; encoding: [0x01,0x11,0x80,0x78]
; CHECK-NEXT: ldursh	x2, [c9, #-1]           ; encoding: [0x22,0xf1,0x9f,0x78]
; CHECK-NEXT: ldursw	x3, [c10, #10]          ; encoding: [0x43,0xa1,0x80,0xb8]
; CHECK-NEXT: ldursw	x4, [c11, #-1]          ; encoding: [0x64,0xf1,0x9f,0xb8]

  strb w3, [c1, #-1]
  strh w4, [c2, #1]
  strh w5, [c3, #-1]

; CHECK: sturb	w3, [c1, #-1]           ; encoding: [0x23,0xf0,0x1f,0x38]
; CHECK-NEXT: sturh	w4, [c2, #1]            ; encoding: [0x44,0x10,0x00,0x78]
; CHECK-NEXT: sturh	w5, [c3, #-1]           ; encoding: [0x65,0xf0,0x1f,0x78]
