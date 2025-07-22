// RUN: rm -rf %t && split-file %s %t && cd %t

// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap lib.s -o lib.o
// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap app.s -o app.o
/// Check that the notes are correctly 4-byte alinged:
// RUN: llvm-readelf --section-headers app.o | FileCheck %s --check-prefix=OBJ-NOTE-ALIGN
// RUN: llvm-readelf --section-headers lib.o | FileCheck %s --check-prefix=OBJ-NOTE-ALIGN
// OBJ-NOTE-ALIGN: Name              Type            Address          Off    Size   ES Flg Lk Inf Al
// OBJ-NOTE-ALIGN: .note.cheri       NOTE            0000000000000000 000044 000048 00   A  0   0  4{{$}}
// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap -cheri-cap-table-abi=pcrel lib.s -o lib1.o
// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap -cheri-cap-table-abi=pcrel app.s -o app1.o
// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap -cheri-cap-table-abi=fn-desc lib.s -o lib2.o
// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap -cheri-cap-table-abi=fn-desc app.s -o app2.o
// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap-benchmark lib.s -o lib3.o
// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap-benchmark app.s -o app3.o

// RUN: ld.lld app.o lib.o -o app 2>&1 | FileCheck %s --check-prefix=NOERROR --allow-empty
// RUN: llvm-readelf --section-headers app
// RUN: llvm-readelf --section-headers app | FileCheck %s --check-prefix=EXE-NOTE-ALIGN
/// ld.lld overaligns the .note.cheri section in morelloLinkerDefinedCapabilityAlign()
/// to ensure that the entire X/RO region can be represented precisely. Since
/// .note.cheri happens to be the first section in this region we end up
/// aligning it to 32 bytes. But we should not be adjusting the sh_addralign member
/// since that is used for parsing the notes section.
// EXE-NOTE-ALIGN: [Nr] Name              Type            Address          Off    Size   ES Flg Lk Inf Al
// EXE-NOTE-ALIGN: [ 1] .note.cheri       NOTE            [[#]]            000160 000048 00   A  0   0 4{{$}}
// EXE-NOTE-ALIGN: [ 2] .text
// RUN: llvm-readobj -h --notes app | FileCheck %s --check-prefix=NT-PCREL
// RUN: ld.lld app1.o lib1.o -o app1 2>&1 | FileCheck %s --check-prefix=NOERROR --allow-empty
// RUN: llvm-readobj -h --notes app1 | FileCheck %s --check-prefix=NT-PCREL
// RUN: ld.lld app2.o lib2.o -o app2 2>&1 | FileCheck %s --check-prefix=NOERROR --allow-empty
// RUN: llvm-readobj -h --notes app2 | FileCheck %s --check-prefix=NT-FDESC
// RUN: ld.lld app.o lib1.o -o app3 2>&1 | FileCheck %s --check-prefix=NOERROR --allow-empty
// RUN: llvm-readobj -h --notes app3 | FileCheck %s --check-prefix=NT-PCREL
// RUN: ld.lld app3.o lib3.o -o app4 2>&1 | FileCheck %s --check-prefix=NOERROR --allow-empty
// RUN: llvm-readobj -h --notes app4 | FileCheck %s --check-prefix=NT-PCREL-BENCHMARK
// RUN: not ld.lld app.o lib2.o -o app5 2>&1 | FileCheck %s --check-prefix=ERROR
// RUN: not ld.lld app1.o lib2.o -o app6 2>&1 | FileCheck %s --check-prefix=ERROR
// RUN: not ld.lld app.o lib3.o -o app7 2>&1 | FileCheck %s --check-prefix=ERROR-BENCHMARK
// ERROR: error: {{.*}} NT_CHERI_GLOBALS_ABI variant mismatch: CHERI_GLOBALS_ABI_FDESC vs CHERI_GLOBALS_ABI_PCREL
// ERROR-BENCHMARK: error: {{.*}} NT_CHERI_MORELLO_PURECAP_BENCHMARK_ABI variant mismatch: yes vs no
// NOERROR-NOT: error:
// NT-PCREL: NoteSection {
// NT-PCREL-NEXT:   Name: .note.cheri
// NT-PCREL-NEXT:   Offset:
// NT-PCREL-NEXT:   Size: 0x48
// NT-PCREL-NEXT:   Note {
// NT-PCREL-NEXT:     Owner: CHERI
// NT-PCREL-NEXT:     Data size: 0x4
// NT-PCREL-NEXT:     Type: NT_CHERI_GLOBALS_ABI (CHERI globals ABI)
// NT-PCREL-NEXT:     Globals ABI: CHERI_GLOBALS_ABI_PCREL (PC-relative)
// NT-PCREL-NEXT:   }
// NT-PCREL-NEXT:   Note {
// NT-PCREL-NEXT:     Owner: CHERI
// NT-PCREL-NEXT:     Data size: 0x4
// NT-PCREL-NEXT:     Type: NT_CHERI_TLS_ABI (CHERI thread-local storage ABI)
// NT-PCREL-NEXT:     TLS ABI: CHERI_TLS_ABI_TRAD (traditional)
// NT-PCREL-NEXT:   }
// NT-PCREL-NEXT:   Note {
// NT-PCREL-NEXT:     Owner: CHERI
// NT-PCREL-NEXT:     Data size: 0x4
// NT-PCREL-NEXT:     Type: NT_CHERI_MORELLO_PURECAP_BENCHMARK_ABI (Morello purecap benchmark ABI)
// NT-PCREL-NEXT:     Purecap benchmark ABI enabled: 0 (no)
// NT-PCREL-NEXT:   }
// NT-PCREL-NEXT: }
// NT-FDESC: NoteSection {
// NT-FDESC-NEXT:   Name: .note.cheri
// NT-FDESC-NEXT:   Offset:
// NT-FDESC-NEXT:   Size: 0x48
// NT-FDESC-NEXT:   Note {
// NT-FDESC-NEXT:     Owner: CHERI
// NT-FDESC-NEXT:     Data size: 0x4
// NT-FDESC-NEXT:     Type: NT_CHERI_GLOBALS_ABI (CHERI globals ABI)
// NT-FDESC-NEXT:     Globals ABI: CHERI_GLOBALS_ABI_FDESC (function descriptor-based)
// NT-FDESC-NEXT:   }
// NT-FDESC-NEXT:   Note {
// NT-FDESC-NEXT:     Owner: CHERI
// NT-FDESC-NEXT:     Data size: 0x4
// NT-FDESC-NEXT:     Type: NT_CHERI_TLS_ABI (CHERI thread-local storage ABI)
// NT-FDESC-NEXT:     TLS ABI: CHERI_TLS_ABI_TRAD (traditional)
// NT-FDESC-NEXT:   }
// NT-FDESC-NEXT:   Note {
// NT-FDESC-NEXT:     Owner: CHERI
// NT-FDESC-NEXT:     Data size: 0x4
// NT-FDESC-NEXT:     Type: NT_CHERI_MORELLO_PURECAP_BENCHMARK_ABI (Morello purecap benchmark ABI)
// NT-FDESC-NEXT:     Purecap benchmark ABI enabled: 0 (no)
// NT-FDESC-NEXT:   }
// NT-FDESC-NEXT: }
// NT-PCREL-BENCHMARK:      NoteSection {
// NT-PCREL-BENCHMARK-NEXT:   Name: .note.cheri
// NT-PCREL-BENCHMARK-NEXT:   Offset:
// NT-PCREL-BENCHMARK-NEXT:   Size: 0x48
// NT-PCREL-BENCHMARK-NEXT:   Note {
// NT-PCREL-BENCHMARK-NEXT:     Owner: CHERI
// NT-PCREL-BENCHMARK-NEXT:     Data size: 0x4
// NT-PCREL-BENCHMARK-NEXT:     Type: NT_CHERI_GLOBALS_ABI (CHERI globals ABI)
// NT-PCREL-BENCHMARK-NEXT:     Globals ABI: CHERI_GLOBALS_ABI_PCREL (PC-relative)
// NT-PCREL-BENCHMARK-NEXT:   }
// NT-PCREL-BENCHMARK-NEXT:   Note {
// NT-PCREL-BENCHMARK-NEXT:     Owner: CHERI
// NT-PCREL-BENCHMARK-NEXT:     Data size: 0x4
// NT-PCREL-BENCHMARK-NEXT:     Type: NT_CHERI_TLS_ABI (CHERI thread-local storage ABI)
// NT-PCREL-BENCHMARK-NEXT:     TLS ABI: CHERI_TLS_ABI_TRAD (traditional)
// NT-PCREL-BENCHMARK-NEXT:   }
// NT-PCREL-BENCHMARK-NEXT:   Note {
// NT-PCREL-BENCHMARK-NEXT:     Owner: CHERI
// NT-PCREL-BENCHMARK-NEXT:     Data size: 0x4
// NT-PCREL-BENCHMARK-NEXT:     Type: NT_CHERI_MORELLO_PURECAP_BENCHMARK_ABI (Morello purecap benchmark ABI)
// NT-PCREL-BENCHMARK-NEXT:     Purecap benchmark ABI enabled: 1 (yes)
// NT-PCREL-BENCHMARK-NEXT:   }
// NT-PCREL-BENCHMARK-NEXT: }

//--- app.s
.globl _start
_start:
  ret

//--- lib.s
.globl lib
lib:
  ret
