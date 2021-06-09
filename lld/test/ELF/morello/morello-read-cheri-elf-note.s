// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap %s -o %t.o
// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap -cheri-cap-table-abi=pcrel %s -o %t1.o
// RUN: llvm-mc -filetype=obj -triple aarch64 -target-abi purecap -cheri-cap-table-abi=fn-desc %s -o %t2.o

// RUN: ld.lld %t.o %t.o -o %t 2>&1 | FileCheck %s --check-prefix=NOWARN --allow-empty
// RUN: llvm-readobj -h --notes %t | FileCheck %s --check-prefix=EFLAGS --check-prefix=NT_PCREL
// RUN: ld.lld %t1.o %t1.o -o %t 2>&1 | FileCheck %s --check-prefix=NOWARN --allow-empty
// RUN: llvm-readobj -h --notes %t | FileCheck %s --check-prefix=EFLAGS --check-prefix=NT_PCREL
// RUN: ld.lld %t2.o %t2.o -o %t 2>&1 | FileCheck %s --check-prefix=NOWARN --allow-empty
// RUN: llvm-readobj -h --notes %t | FileCheck %s --check-prefix=EFLAGS --check-prefix=NT_FDESC
// RUN: ld.lld %t.o %t1.o -o %t 2>&1 | FileCheck %s --check-prefix=NOWARN --allow-empty
// RUN: llvm-readobj -h --notes %t | FileCheck %s --check-prefix=EFLAGS --check-prefix=NT_PCREL
// RUN: ld.lld %t.o %t2.o -o %t 2>&1 | FileCheck %s --check-prefix=WARN
// RUN: llvm-readobj -h --notes %t | FileCheck %s --check-prefix=EFLAGS --check-prefix=NT_PCREL
// RUN: ld.lld %t1.o %t2.o -o %t 2>&1 | FileCheck %s --check-prefix=WARN
// RUN: llvm-readobj -h --notes %t | FileCheck %s --check-prefix=EFLAGS --check-prefix=NT_PCREL

// RUN: ld.lld %t1.o %t2.o -o %t --strip-note-cheri -o - | \
// RUN: llvm-readobj --notes | FileCheck %s --check-prefix=NT_NONE

// WARN: warning: {{.*}} CHERI ABI variant mismatch. Defaulting to Purecap ABI.
// NOWARN-NOT: warning: {{.*}} CHERI ABI variant mismatch. Defaulting to Purecap ABI.
// EFLAGS: Flags [ (0x10000)


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

// NT_NONE:      Notes [
// NT_NONE-NEXT: ]
