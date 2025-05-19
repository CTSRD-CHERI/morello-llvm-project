# RUN: llvm-mc -triple=aarch64 -mattr=+morello,+c64 -target-abi purecap -cheri-tgot-tls < %s \
# RUN:     | FileCheck -check-prefix=CHECK-ASM %s
# RUN: llvm-mc -filetype=obj -triple=aarch64 -mattr=+morello,+c64 -target-abi purecap -cheri-tgot-tls < %s \
# RUN:     | llvm-objdump -d - | FileCheck -check-prefix=CHECK-OBJ %s
# RUN: llvm-mc -filetype=obj -triple=aarch64 -mattr=+morello,+c64 -target-abi purecap -cheri-tgot-tls < %s \
# RUN:     | llvm-readobj -r - | FileCheck -check-prefix=CHECK-REL %s

.global x

## Local Exec
# CHECK-ASM: mrs c0, CTPIDR_EL0
# CHECK-OBJ: mrs c0, CTPIDR_EL0
mrs c0, CTPIDR_EL0
# CHECK-ASM: ldr c0, [c0, :tgot_lo12:x]
# CHECK-OBJ: ldr c0, [c0, #0x0]
# CHECK-REL: R_MORELLO_TLSLE_LD128_TGOT_LO12 x
ldr c0, [c0, :tgot_lo12:x]

## Local Exec
# CHECK-ASM: mrs c0, CTPIDR_EL0
# CHECK-OBJ: mrs c0, CTPIDR_EL0
mrs c0, CTPIDR_EL0
# CHECK-ASM: add c0, c0, :tgot:x, lsl #12
# CHECK-OBJ: add c0, c0, #0x0, lsl #12
# CHECK-REL: R_MORELLO_TLSLE_ADD_TGOT_HI12 x
add c0, c0, #:tgot:x, lsl #12
# CHECK-ASM: ldr c0, [c0, :tgot_lo12_nc:x]
# CHECK-OBJ: ldr c0, [c0, #0x0]
# CHECK-REL: R_MORELLO_TLSLE_LD128_TGOT_LO12_NC x
ldr c0, [c0, :tgot_lo12_nc:x]

## Local Exec
# CHECK-ASM: movz x0, #:tgot_g0:x
# CHECK-OBJ: mov x0, #0x0
# CHECK-REL: R_MORELLO_TLSLE_MOVW_TGOT_G0 x
movz x0, #:tgot_g0:x
# CHECK-ASM: mrs c1, CTPIDR_EL0
# CHECK-OBJ: mrs c1, CTPIDR_EL0
mrs c1, CTPIDR_EL0
# CHECK-ASM: ldr c0, [c1, x0]
# CHECK-OBJ: ldr c0, [c1, x0]
ldr c0, [c1, x0]

## Local Exec
# CHECK-ASM: movz x0, #:tgot_g1:x
# CHECK-OBJ: movz x0, #0x0, lsl #16
# CHECK-REL: R_MORELLO_TLSLE_MOVW_TGOT_G1 x
movz x0, #:tgot_g1:x
# CHECK-ASM: movk x0, #:tgot_g0_nc:x
# CHECK-OBJ: movk x0, #0x0
# CHECK-REL: R_MORELLO_TLSLE_MOVW_TGOT_G0_NC x
movk x0, #:tgot_g0_nc:x
# CHECK-ASM: mrs c1, CTPIDR_EL0
# CHECK-OBJ: mrs c1, CTPIDR_EL0
mrs c1, CTPIDR_EL0
# CHECK-ASM: ldr c0, [c1, x0]
# CHECK-OBJ: ldr c0, [c1, x0]
ldr c0, [c1, x0]

## Initial Exec
# CHECK-ASM: adrp c0, :gottgot:x
# CHECK-OBJ: adrp c0, 0x0
# CHECK-REL: R_MORELLO_TLSIE_ADR_GOTTGOT_PAGE20 x
adrp c0, :gottgot:x
# CHECK-ASM: ldr x0, [c0, :gottgot_lo12:x]
# CHECK-OBJ: ldr x0, [c0]
# CHECK-REL: R_MORELLO_TLSIE_LD64_GOTTGOT_LO12_NC x
ldr x0, [c0, :gottgot_lo12:x]
# CHECK-ASM: mrs c1, CTPIDR_EL0
# CHECK-OBJ: mrs c1, CTPIDR_EL0
mrs c1, CTPIDR_EL0
# CHECK-ASM: ldr c0, [c1, x0]
# CHECK-OBJ: ldr c0, [c1, x0]
ldr c0, [c1, x0]

# General Dynamic
# CHECK-ASM: mrs c1, CTPIDR_EL0
# CHECK-OBJ: mrs c1, CTPIDR_EL0
mrs c1, CTPIDR_EL0
# CHECK-ASM: adrp c0, :tgot_tlsdesc:x
# CHECK-OBJ: adrp c0, 0x0
# CHECK-REL: R_MORELLO_TGOT_TLSDESC_ADR_PAGE20 x
adrp c0, :tgot_tlsdesc:x
# CHECK-ASM: ldr c2, [c0, :tgot_tlsdesc_lo12:x]
# CHECK-OBJ: ldr c2, [c0, #0x0]
# CHECK-REL: R_MORELLO_TGOT_TLSDESC_LD128_LO12 x
ldr c2, [c0, :tgot_tlsdesc_lo12:x]
# CHECK-ASM: add c0, c0, :tgot_tlsdesc_lo12:x
# CHECK-OBJ: add c0, c0, #0x0
# CHECK-REL: R_MORELLO_TGOT_TLSDESC_ADD_LO12 x
add c0, c0, #:tgot_tlsdesc_lo12:x
# CHECK-ASM: .tgot_tlsdesccall x
# CHECK-REL: R_MORELLO_TGOT_TLSDESC_CALL x
.tgot_tlsdesccall x
# CHECK-ASM: blr c2
# CHECK-OBJ: blr c2
blr c2
