// RUN: llvm-mc -triple aarch64-none-linux-gnu -show-encoding \
// RUN:     -mattr=+morello < %s | FileCheck --check-prefix=ASM %s

// RUN: llvm-mc -triple aarch64-none-linux-gnu -show-encoding \
// RUN:     -filetype=obj -mattr=+morello < %s -o - | \
// RUN:  llvm-objdump --mattr=+morello -d -r - | FileCheck --check-prefix=OBJ %s

somewhere:
  nop
  nop
  nop
  ldr c0, somewhere
  ldr c1, anywhere

// OBJ: ldr c0, #0
// OBJ-NEXT: R_MORELLO_LD_PREL_LO17 .text
// OBJ: ldr c1, #0
// OBJ-NEXT: R_MORELLO_LD_PREL_LO17 anywhere

// ASM:  ldr c0, somewhere           // encoding: [0bAAA00000,A,0b00AAAAAA,0x82]
// ASM-NEXT: fixup A - offset: 0, value: somewhere, kind: fixup_aarch64_ldr_pcrel_imm17_scale16
// ASM:  ldr c1, anywhere            // encoding: [0bAAA00001,A,0b00AAAAAA,0x82]
// ASM-NEXT:   fixup A - offset: 0, value: anywhere, kind: fixup_aarch64_ldr_pcrel_imm17_scale16

  ldr c0, [x1, :lo12:sym]
  str c1, [x2, :lo12:sym]
  ldr c0, [x1, :lo12:sym+1]
  str c1, [x2, :lo12:sym+1]

// OBJ:  ldr c0, [x1, #0x0]
// OBJ-NEXT: R_AARCH64_LDST128_ABS_LO12_NC sym
// OBJ:  str c1, [x2, #0x0]
// OBJ-NEXT: R_AARCH64_LDST128_ABS_LO12_NC sym
// OBJ:  ldr c0, [x1, #0x0]
// OBJ-NEXT: R_AARCH64_LDST128_ABS_LO12_NC sym+0x1
// OBJ:  str c1, [x2, #0x0]
// OBJ-NEXT: R_AARCH64_LDST128_ABS_LO12_NC sym+0x1

// ASM:  ldr c0, [x1, :lo12:sym]                // encoding: [0x20,0bAAAAAA00,0b01AAAAAA,0xc2]
// ASM-NEXT:                                    //   fixup A - offset: 0, value: :lo12:sym, kind: fixup_aarch64_ldst_imm12_scale16
// ASM:  str c1, [x2, :lo12:sym]                // encoding: [0x41,0bAAAAAA00,0b00AAAAAA,0xc2]
// ASM-NEXT:                                    //   fixup A - offset: 0, value: :lo12:sym, kind: fixup_aarch64_ldst_imm12_scale16
// ASM:  ldr c0, [x1, :lo12:sym+1]              // encoding: [0x20,0bAAAAAA00,0b01AAAAAA,0xc2]
// ASM-NEXT:                                    //   fixup A - offset: 0, value: :lo12:sym+1, kind: fixup_aarch64_ldst_imm12_scale16
// ASM:  str c1, [x2, :lo12:sym+1]              // encoding: [0x41,0bAAAAAA00,0b00AAAAAA,0xc2]
// ASM-NEXT:                                    //   fixup A - offset: 0, value: :lo12:sym+1, kind: fixup_aarch64_ldst_imm12_scale16

  ldr c0, [x1, :got_lo12:sym]
  str c1, [x2, :got_lo12:sym]
  ldr c0, [x1, :got_lo12:sym+1]
  str c1, [x2, :got_lo12:sym+1]

// OBJ:  ldr c0, [x1, #0x0]
// OBJ-NEXT: R_MORELLO_LD128_GOT_LO12_NC sym
// OBJ:  str c1, [x2, #0x0]
// OBJ-NEXT: R_MORELLO_LD128_GOT_LO12_NC sym
// OBJ:  ldr c0, [x1, #0x0]
// OBJ-NEXT: R_MORELLO_LD128_GOT_LO12_NC sym+0x1
// OBJ:  str c1, [x2, #0x0]
// OBJ-NEXT: R_MORELLO_LD128_GOT_LO12_NC sym+0x1

// ASM:  ldr c0, [x1, :got_lo12:sym]            // encoding: [0x20,0bAAAAAA00,0b01AAAAAA,0xc2]
// ASM-NEXT:                                    //   fixup A - offset: 0, value: :got_lo12:sym, kind: fixup_aarch64_ldst_imm12_scale16
// ASM:  str c1, [x2, :got_lo12:sym]            // encoding: [0x41,0bAAAAAA00,0b00AAAAAA,0xc2]
// ASM-NEXT:                                    //   fixup A - offset: 0, value: :got_lo12:sym, kind: fixup_aarch64_ldst_imm12_scale16
// ASM:  ldr c0, [x1, :got_lo12:sym+1]          // encoding: [0x20,0bAAAAAA00,0b01AAAAAA,0xc2]
// ASM-NEXT:                                    //   fixup A - offset: 0, value: :got_lo12:sym+1, kind: fixup_aarch64_ldst_imm12_scale16
// ASM:  str c1, [x2, :got_lo12:sym+1]          // encoding: [0x41,0bAAAAAA00,0b00AAAAAA,0xc2]
// ASM-NEXT:                                    //   fixup A - offset: 0, value: :got_lo12:sym+1, kind: fixup_aarch64_ldst_imm12_scale16
