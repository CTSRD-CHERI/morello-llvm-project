// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap %s -o %t.o
/// Check that the notes are correctly 4-byte aligned:
// RUNs: llvm-readelf --section-headers %t.o | FileCheck %s --check-prefix=OBJ-SECTIONS-ALIGN
// OBJ-SECTIONS-ALIGN: Name              Type            Address          Off    Size   ES Flg Lk Inf Al
// OBJ-SECTIONS-ALIGN: .note.cheri       NOTE            0000000000000000 000044 000030 00   A  0   0  4{{$}}

// RUN: ld.lld %t.o -o %t.exe
// RUN: llvm-readelf --section-headers --program-headers %t.exe
// RUN: llvm-readelf --section-headers --program-headers %t.exe | FileCheck %s --check-prefix=EXE-NEXT
// RUN: llvm-readobj --notes %t.exe 2>&1 | FileCheck %s --check-prefix=NOTES
/// ld.lld overaligns the .note.cheri section in morelloLinkerDefinedCapabilityAlign()
/// to ensure that the entire X/RO region can be represented precisely. Since
/// .note.cheri happens to be the first section in this region we end up
/// aligning it to 8192 bytes.
/// Important: we should not be adjust the addralign value since that breaks
/// reading of the SHT_NOTE section, so the value should still be read as 4.
// EXE-LABEL: Section Headers:
// EXE-NEXT: [Nr] Name              Type            Address          Off     Size    ES Flg Lk Inf Al
// EXE-NEXT: [ 0]                   NULL            0000000000000000 000000  000000  00      0   0  0
// EXE-NEXT: [ 1] .note.cheri       NOTE            0000000000202000 002000  000030  00   A  0   0  4{{$}}
// EXE-NEXT: [ 2] .text             PROGBITS        0000000000212030 002030  1235fd0 00  AX  0   0  4
// EXE-NEXT: [ 3] .data             PROGBITS        0000000001458000 1238000 123456b 00  WA  0   0  1

// EXE-LABEL: Program Headers:
// EXE-NEXT:   Type           Offset   VirtAddr           PhysAddr           FileSiz  MemSiz   Flg Align
// EXE-NEXT:   PHDR           0x000040 0x0000000000200040 0x0000000000200040 0x000150 0x000150 R   0x8
// EXE-NEXT:   LOAD           0x000000 0x0000000000200000 0x0000000000200000 0x002030 0x002030 R   0x10000
// EXE-NEXT:   LOAD           0x002030 0x0000000000212030 0x0000000000212030 0x1235fd0 0x1235fd0 R E 0x10000
// EXE-NEXT:   LOAD           0x1238000 0x0000000001458000 0x0000000001458000 0x123456b 0x123456b RW  0x10000
// EXE-NEXT:   GNU_STACK      0x000000 0x0000000000000000 0x0000000000000000 0x000000 0x000000 RW  0x0
// EXE-NEXT:   NOTE           0x002000 0x0000000000202000 0x0000000000202000 0x000030 0x000030 R   0x4

// NOTES:      Notes [
// NOTES-NEXT:   NoteSection {
// NOTES-NEXT:     Name: .note.cheri
// NOTES-NEXT:     Offset: 0x2000
// NOTES-NEXT:     Size: 0x30
// NOTES-NEXT:     Note {
// NOTES-NEXT:       Owner: CHERI
// NOTES-NEXT:       Data size: 0x4
// NOTES-NEXT:       Type: NT_CHERI_GLOBALS_ABI (CHERI globals ABI)
// NOTES-NEXT:       Globals ABI: CHERI_GLOBALS_ABI_PCREL (PC-relative)
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
