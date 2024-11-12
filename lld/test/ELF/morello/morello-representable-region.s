// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap %s -o %t.o
/// Check that the notes are correctly 4-byte aligned:
// RUNs: llvm-readelf --section-headers %t.o | FileCheck %s --check-prefix=OBJ-SECTIONS-ALIGN
// OBJ-SECTIONS-ALIGN: Name              Type            Address          Off    Size   ES Flg Lk Inf Al
// OBJ-SECTIONS-ALIGN: .note.cheri       NOTE            0000000000000000 000044 000048 00   A  0   0  4{{$}}

// RUN: ld.lld %t.o -o %t.exe
// RUN: llvm-readelf --section-headers --program-headers %t.exe
// RUN: llvm-readelf --section-headers --program-headers %t.exe | FileCheck %s --check-prefix=EXE-NEXT
// RUN: llvm-readobj --notes %t.exe 2>&1 | FileCheck %s --check-prefix=NOTES
/// ld.lld used to overalign the .note.cheri section in morelloLinkerDefinedCapabilityAlign()
/// to ensure that the entire X/RO region could be represented precisely. Since
/// .note.cheri happens to be the first section in this region we ended up
/// aligning it to 32 bytes. But we should not be adjusting the sh_addralign member
/// since that is used for parsing the notes section. This test is a bit
/// redundant since it's no longer part of the PCC segment and thus we don't
/// align it, but it's kept here in case this somehow breaks again.
// EXE-LABEL: Section Headers:
// EXE-NEXT: [Nr] Name              Type            Address          Off     Size    ES Flg Lk Inf Al
// EXE-NEXT: [ 0]                   NULL            0000000000000000 000000  000000  00      0   0  0
// EXE-NEXT: [ 1] .note.cheri       NOTE            00000000002001c8 0001c8  000048  00   A  0   0  4{{$}}
// EXE-NEXT: [ 2] .text             PROGBITS        0000000000212000 002000  123456b 00  AX  0   0  8192
// EXE-NEXT: [ 3] .pad.cheri.pcc    PROGBITS        000000000144656b 123656b 001a95  00  AX  0   0  1
// EXE-NEXT: [ 4] .data             PROGBITS        0000000001458000 1238000 123456b 00  WA  0   0  1

// EXE-LABEL: Program Headers:
// EXE-NEXT:   Type           Offset   VirtAddr           PhysAddr           FileSiz  MemSiz   Flg Align
// EXE-NEXT:   PHDR           0x000040 0x0000000000200040 0x0000000000200040 0x000188 0x000188 R   0x8
// EXE-NEXT:   LOAD           0x000000 0x0000000000200000 0x0000000000200000 0x000210 0x000210 R   0x10000
// EXE-NEXT:   LOAD           0x002000 0x0000000000212000 0x0000000000212000 0x1236000 0x1236000 R E 0x10000
// EXE-NEXT:   LOAD           0x1238000 0x0000000001458000 0x0000000001458000 0x123456b 0x123456b RW  0x10000
// EXE-NEXT:   CHERI_PCC      0x002000 0x0000000000212000 0x0000000000212000 0x1236000 0x1236000 R E 0x2000
// EXE-NEXT:   GNU_STACK      0x000000 0x0000000000000000 0x0000000000000000 0x000000 0x000000 RW  0x0
// EXE-NEXT:   NOTE           0x0001c8 0x00000000002001c8 0x00000000002001c8 0x000048 0x000048 R   0x4

// NOTES:      Notes [
// NOTES-NEXT:   NoteSection {
// NOTES-NEXT:     Name: .note.cheri
// NOTES-NEXT:     Offset: 0x1C8
// NOTES-NEXT:     Size: 0x48
// NOTES-NEXT:     Note {
// NOTES-NEXT:       Owner: CHERI
// NOTES-NEXT:       Data size: 0x4
// NOTES-NEXT:       Type: NT_CHERI_GLOBALS_ABI (CHERI globals ABI)
// NOTES-NEXT:       Globals ABI: CHERI_GLOBALS_ABI_PCREL (PC-relative)
// NOTES-NEXT:     }
// NOTES-NEXT:     Note {
// NOTES-NEXT:       Owner: CHERI
// NOTES-NEXT:       Data size: 0x4
// NOTES-NEXT:       Type: NT_CHERI_TLS_ABI (CHERI thread-local storage ABI)
// NOTES-NEXT:       TLS ABI: CHERI_TLS_ABI_TRAD (traditional)
// NOTES-NEXT:     }
// NOTES-NEXT:     Note {
// NOTES-NEXT:       Owner: CHERI
// NOTES-NEXT:       Data size: 0x4
// NOTES-NEXT:       Type: NT_CHERI_MORELLO_PURECAP_BENCHMARK_ABI (Morello purecap benchmark ABI)
// NOTES-NEXT:       Purecap benchmark ABI enabled: 0 (no)
// NOTES-NEXT:     }
// NOTES-NEXT:   }
// NOTES-NEXT: ]

//--- app.s
.text
.globl _start
_start:
  ret

.space 0x1234567

.data
data:
.long 1
.space 0x1234567
