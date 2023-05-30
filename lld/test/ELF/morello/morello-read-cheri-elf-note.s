// RUN: rm -rf %t && split-file %s %t && cd %t

// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap lib.s -o lib.o
// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap app.s -o app.o
// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap -cheri-cap-table-abi=pcrel lib.s -o lib1.o
// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap -cheri-cap-table-abi=pcrel app.s -o app1.o
// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap -cheri-cap-table-abi=fn-desc lib.s -o lib2.o
// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap -cheri-cap-table-abi=fn-desc app.s -o app2.o

// RUN: ld.lld app.o lib.o -o app 2>&1 | FileCheck %s --check-prefix=NOERROR --allow-empty
// RUN: llvm-readobj -h --notes app | FileCheck %s --check-prefix=NT_PCREL
// RUN: ld.lld app1.o lib1.o -o app1 2>&1 | FileCheck %s --check-prefix=NOERROR --allow-empty
// RUN: llvm-readobj -h --notes app1 | FileCheck %s --check-prefix=NT_PCREL
// RUN: ld.lld app2.o lib2.o -o app2 2>&1 | FileCheck %s --check-prefix=NOERROR --allow-empty
// RUN: llvm-readobj -h --notes app2 | FileCheck %s --check-prefix=NT_FDESC
// RUN: ld.lld app.o lib1.o -o app3 2>&1 | FileCheck %s --check-prefix=NOERROR --allow-empty
// RUN: llvm-readobj -h --notes app3 | FileCheck %s --check-prefix=NT_PCREL
// RUN: not ld.lld app.o lib2.o -o app4 2>&1 | FileCheck %s --check-prefix=ERROR
// RUN: not ld.lld app1.o lib2.o -o app5 2>&1 | FileCheck %s --check-prefix=ERROR
// ERROR: error: {{.*}} CHERI ABI variant mismatch.
// NOERROR-NOT: error:
// NT_PCREL: NoteSection {
// NT_PCREL-NEXT:   Name: .note.cheri
// NT_PCREL-NEXT:   Offset:
// NT_PCREL-NEXT:   Size: 0x18
// NT_PCREL-NEXT:   Note {
// NT_PCREL-NEXT:     Owner: CHERI
// NT_PCREL-NEXT:     Data size: 0x4
// NT_PCREL-NEXT:     Type: Unknown (0x00000000)
// NT_PCREL-NEXT:     Description data (
// NT_PCREL-NEXT:       0000: 00000000
// NT_PCREL-NEXT:     )
// NT_PCREL-NEXT:   }
// NT_PCREL-NEXT: }
// NT_FDESC: NoteSection {
// NT_FDESC-NEXT:   Name: .note.cheri
// NT_FDESC-NEXT:   Offset:
// NT_FDESC-NEXT:   Size: 0x18
// NT_FDESC-NEXT:   Note {
// NT_FDESC-NEXT:     Owner: CHERI
// NT_FDESC-NEXT:     Data size: 0x4
// NT_FDESC-NEXT:     Type: Unknown (0x00000000)
// NT_FDESC-NEXT:     Description data (
// NT_FDESC-NEXT:       0000: 02000000
// NT_FDESC-NEXT:     )
// NT_FDESC-NEXT:   }
// NT_FDESC-NEXT: }

//--- app.s
.globl _start
_start:
  ret

//--- lib.s
.globl lib
lib:
  ret
