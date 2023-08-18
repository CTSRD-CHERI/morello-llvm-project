// RUN: %cheri_cc1 %s -O1 -o - -emit-llvm | FileCheck %s --check-prefix=CAPS
// RUN: %clang %s -O1 -target aarch64-none-linux-gnu -march=morello -o - -emit-llvm -S -fPIC | FileCheck %s --check-prefix=CAPS-AARCH64
// RUN: %clang_cc1 %s -O1 -triple i386-unknown-freebsd -o - -emit-llvm | FileCheck %s --check-prefix=PTRS
// RUN: %clang %s -O1 -target aarch64-none-linux-gnu -o - -emit-llvm -fPIC -S | FileCheck %s --check-prefix=PTRS-AARCH64

// Remove the static from all of the function prototypes so that this really exists.
#define static
#define inline 
#include <cheri.h>

// PTRS: define dso_local i32 @cheri_length_get(ptr nocapture noundef readnone
// PTRS: ret i32 -1
// PTRS: define dso_local i32 @cheri_base_get(ptr nocapture noundef readnone
// PTRS: ret i32 -1
// PTRS: define dso_local i32 @cheri_offset_get(ptr nocapture noundef readnone
// PTRS: ret i32 -1
// PTRS: define dso_local ptr @cheri_offset_set(ptr noundef readnone returned{{( %.+)?}}, i32
// PTRS: ret ptr
// PTRS: define dso_local i32 @cheri_type_get(ptr nocapture noundef readnone
// PTRS: ret i32 0
// PTRS: define dso_local zeroext i16 @cheri_perms_get(ptr nocapture noundef readnone
// PTRS: ret i16 0
// PTRS: define dso_local ptr @cheri_perms_and(ptr noundef readnone returned{{( %.+)?}}, i16 noundef zeroext
// PTRS: ret ptr
// PTRS: define dso_local zeroext i16 @cheri_flags_get(ptr nocapture noundef readnone
// PTRS: ret i16 0
// PTRS: define dso_local ptr @cheri_flags_set(ptr noundef readnone returned{{( %.+)?}}, i16 noundef zeroext
// PTRS: ret ptr
// PTRS: define dso_local zeroext i1 @cheri_tag_get(ptr nocapture noundef readnone
// PTRS: ret i1 false
// PTRS: define dso_local zeroext i1 @cheri_sealed_get(ptr nocapture noundef readnone
// PTRS: ret i1 false
// PTRS: define dso_local ptr @cheri_offset_increment(ptr noundef readnone{{( %.+)?}}, i32
// PTRS: %[[TEMP1:[0-9a-z.]+]] = getelementptr inbounds i8, ptr{{( %.+)?}}, i32
// PTRS: ret ptr %[[TEMP1]]
// PTRS: define dso_local ptr @cheri_tag_clear(ptr noundef readnone returned
// PTRS: ret ptr
// PTRS: define dso_local ptr @cheri_seal(ptr noundef readnone returned{{( %.+)?}}, ptr nocapture noundef readnone
// PTRS: ret ptr
// PTRS: define dso_local ptr @cheri_unseal(ptr noundef readnone returned{{( %.+)?}}, ptr nocapture noundef readnone
// PTRS: ret ptr
// PTRS: define dso_local ptr @cheri_cap_from_pointer(ptr nocapture noundef readnone{{( %.+)?}}, ptr noundef readnone returned{{( %.+)?}})
// PTRS: ret ptr
// PTRS: define dso_local ptr @cheri_cap_to_pointer(ptr nocapture noundef readnone{{( %.+)?}}, ptr noundef readnone returned{{( %.+)?}})
// PTRS: ret ptr
// PTRS: define dso_local void @cheri_perms_check(ptr nocapture noundef{{( %.+)?}}, i16 noundef zeroext
// PTRS: ret void
// PTRS: define dso_local void @cheri_type_check(ptr nocapture noundef{{( %.+)?}}, ptr nocapture
// PTRS: ret void
// PTRS: define dso_local noalias ptr @cheri_global_data_get()
// PTRS: ret ptr null
// PTRS: define dso_local noalias ptr @cheri_program_counter_get()
// PTRS: ret ptr null

// PTRS-AARCH64: define i64 @cheri_length_get(i8* nocapture noundef readnone %{{.*}})
// PTRS-AARCH64: ret i64 -1
// PTRS-AARCH64: define i64 @cheri_base_get(i8* nocapture noundef readnone %{{.*}})
// PTRS-AARCH64: ret i64 -1
// PTRS-AARCH64: define i64 @cheri_offset_get(i8* nocapture noundef readnone %{{.*}})
// PTRS-AARCH64: ret i64 -1
// PTRS-AARCH64: define i8* @cheri_offset_set(i8* noundef readnone returned %{{.*}}, i64 noundef %{{.*}})
// PTRS-AARCH64: ret i8* %{{.*}}
// PTRS-AARCH64: define i32 @cheri_type_get(i8* nocapture noundef readnone %{{.*}})
// PTRS-AARCH64: ret i32 0
// PTRS-AARCH64: define i32 @cheri_perms_get(i8* nocapture noundef readnone %{{.*}})
// PTRS-AARCH64: ret i32 0
// PTRS-AARCH64: define i8* @cheri_perms_and(i8* noundef readnone returned %{{.*}}, i32 noundef %{{.*}})
// PTRS-AARCH64: ret i8* %{{.*}}
// PTRS-AARCH64: define i1 @cheri_tag_get(i8* nocapture noundef readnone %{{.*}})
// PTRS-AARCH64: ret i1 false
// PTRS-AARCH64: define i1 @cheri_sealed_get(i8* nocapture noundef readnone %{{.*}})
// PTRS-AARCH64: ret i1 false
// PTRS-AARCH64: define i8* @cheri_offset_increment(i8* noundef readnone %{{.*}}, i64 noundef %{{.*}})
// PTRS-AARCH64: %{{.*}} = getelementptr inbounds i8, i8* %{{.*}}, i64 %{{.*}}
// PTRS-AARCH64: ret i8* %{{.*}}
// PTRS-AARCH64: define i8* @cheri_tag_clear(i8* noundef readnone returned %{{.*}})
// PTRS-AARCH64: ret i8* %{{.*}}
// PTRS-AARCH64: define i8* @cheri_seal(i8* noundef readnone returned %{{.*}}, i8* nocapture noundef readnone %{{.*}})
// PTRS-AARCH64: ret i8* %{{.*}}
// PTRS-AARCH64: define i8* @cheri_unseal(i8* noundef readnone returned %{{.*}}, i8* nocapture noundef readnone %{{.*}})
// PTRS-AARCH64: ret i8* %{{.*}}
// PTRS-AARCH64: define i8* @cheri_bounds_set(i8* noundef readnone returned %{{.*}}, i64 noundef %{{.*}})
// PTRS-AARCH64: ret i8* %{{.*}}
// PTRS-AARCH64: define i8* @cheri_cap_from_pointer(i8* nocapture noundef readnone %{{.*}}, i8* noundef readnone returned %{{.*}})
// PTRS-AARCH64: ret i8*
// PTRS-AARCH64: define i8* @cheri_cap_to_pointer(i8* nocapture noundef readnone %{{.*}}, i8* noundef readnone returned %{{.*}})
// PTRS-AARCH64: ret i8*
// PTRS-AARCH64: define noalias i8* @cheri_global_data_get()
// PTRS-AARCH64: ret i8* null
// PTRS-AARCH64: define noalias i8* @cheri_program_counter_get()
// PTRS-AARCH64: ret i8* null

// CAPS: define dso_local i64 @cheri_length_get(i8 addrspace(200)* noundef readnone
// CAPS: call i64 @llvm.cheri.cap.length.get.i64(i8 addrspace(200)*
// CAPS: define dso_local i64 @cheri_base_get(i8 addrspace(200)* noundef readnone
// CAPS: call i64 @llvm.cheri.cap.base.get.i64(i8 addrspace(200)*
// CAPS: define dso_local i64 @cheri_offset_get(i8 addrspace(200)* noundef readnone
// CAPS: call i64 @llvm.cheri.cap.offset.get.i64(i8 addrspace(200)*
// CAPS: define dso_local i8 addrspace(200)* @cheri_offset_set(i8 addrspace(200)* noundef readnone{{( %.+)?}}, i64 noundef zeroext{{( %.+)?}}
// CAPS: call i8 addrspace(200)* @llvm.cheri.cap.offset.set.i64(i8 addrspace(200)*{{( %.+)?}}, i64{{( %.+)?}})
// CAPS: define dso_local signext i32 @cheri_type_get(i8 addrspace(200)*
// CAPS: call i64 @llvm.cheri.cap.type.get.i64(i8 addrspace(200)*
// CAPS: define dso_local zeroext i16 @cheri_perms_get(i8 addrspace(200)*
// CAPS: call i64 @llvm.cheri.cap.perms.get.i64(i8 addrspace(200)*
// CAPS: define dso_local i8 addrspace(200)* @cheri_perms_and(i8 addrspace(200)* noundef readnone{{( %.+)?}}, i16 noundef zeroext
// CAPS: call i8 addrspace(200)* @llvm.cheri.cap.perms.and.i64(i8 addrspace(200)*{{( %.+)?}}, i64
// CAPS: define dso_local zeroext i16 @cheri_flags_get(i8 addrspace(200)*
// CAPS: call i64 @llvm.cheri.cap.flags.get.i64(i8 addrspace(200)*
// CAPS: define dso_local i8 addrspace(200)* @cheri_flags_set(i8 addrspace(200)* noundef readnone{{( %.+)?}}, i16 noundef zeroext
// CAPS: call i8 addrspace(200)* @llvm.cheri.cap.flags.set.i64(i8 addrspace(200)*{{( %.+)?}}, i64
// CAPS: define dso_local zeroext i1 @cheri_tag_get(i8 addrspace(200)* noundef readnone
// CAPS: call i1 @llvm.cheri.cap.tag.get(i8 addrspace(200)*
// CAPS: define dso_local zeroext i1 @cheri_sealed_get(i8 addrspace(200)* noundef readnone
// CAPS: call i1 @llvm.cheri.cap.sealed.get(i8 addrspace(200)*
// CAPS: define dso_local i8 addrspace(200)* @cheri_offset_increment(i8 addrspace(200)* noundef readnone{{( %.+)?}}, i64 noundef signext
// CAPS: %__builtin_cheri_offset_increment = getelementptr i8, i8 addrspace(200)* %__cap, i64 %__offset
// CAPS: ret i8 addrspace(200)* %__builtin_cheri_offset_increment
// CAPS: define dso_local i8 addrspace(200)* @cheri_tag_clear(i8 addrspace(200)* noundef readnone
// CAPS: call i8 addrspace(200)* @llvm.cheri.cap.tag.clear(i8 addrspace(200)*
// CAPS: define dso_local i8 addrspace(200)* @cheri_seal(i8 addrspace(200)* noundef readnone{{( %.+)?}}, i8 addrspace(200)* noundef readnone
// CAPS: call i8 addrspace(200)* @llvm.cheri.cap.seal(i8 addrspace(200)*{{( %.+)?}}, i8 addrspace(200)*
// CAPS: define dso_local i8 addrspace(200)* @cheri_unseal(i8 addrspace(200)* noundef readnone{{( %.+)?}}, i8 addrspace(200)* noundef readnone
// CAPS: call i8 addrspace(200)* @llvm.cheri.cap.unseal(i8 addrspace(200)*{{( %.+)?}}, i8 addrspace(200)*
// CAPS: define dso_local i8 addrspace(200)* @cheri_cap_from_pointer(i8 addrspace(200)* noundef readnone{{( %.+)?}}, i8* noundef{{( %.+)?}})
// CAPS: call i8 addrspace(200)* @llvm.cheri.cap.from.pointer.i64(i8 addrspace(200)*{{( %.+)?}}, i64
// CAPS: define dso_local i8* @cheri_cap_to_pointer(i8 addrspace(200)* noundef{{( %.+)?}}, i8 addrspace(200)* noundef{{( %.+)?}})
// CAPS: call i64 @llvm.cheri.cap.to.pointer.i64(i8 addrspace(200)*{{( %.+)?}}, i8 addrspace(200)*
// CAPS: define dso_local void @cheri_perms_check(i8 addrspace(200)* noundef{{( %.+)?}}, i16 noundef zeroext
// CAPS: call void @llvm.cheri.cap.perms.check.i64(i8 addrspace(200)*{{( %.+)?}}, i64
// CAPS: define dso_local void @cheri_type_check(i8 addrspace(200)* noundef{{( %.+)?}}, i8 addrspace(200)*
// CAPS: call void @llvm.cheri.cap.type.check(i8 addrspace(200)*{{( %.+)?}}, i8 addrspace(200)*
// CAPS: define dso_local i8 addrspace(200)* @cheri_global_data_get()
// CAPS: call i8 addrspace(200)* @llvm.cheri.ddc.get()
// CAPS: define dso_local i8 addrspace(200)* @cheri_program_counter_get()
// CAPS: call i8 addrspace(200)* @llvm.cheri.pcc.get()

// CAPS-AARCH64: define i64 @cheri_length_get(i8 addrspace(200)* noundef readnone %{{.*}})
// CAPS-AARCH64: call i64 @llvm.cheri.cap.length.get.i64(i8 addrspace(200)* %{{.*}})
// CAPS-AARCH64: define i64 @cheri_base_get(i8 addrspace(200)* noundef readnone %{{.*}})
// CAPS-AARCH64: call i64 @llvm.cheri.cap.base.get.i64(i8 addrspace(200)* %{{.*}})
// CAPS-AARCH64: define i64 @cheri_offset_get(i8 addrspace(200)* noundef readnone %{{.*}})
// CAPS-AARCH64: call i64 @llvm.cheri.cap.offset.get.i64(i8 addrspace(200)* %{{.*}})
// CAPS-AARCH64: define i8 addrspace(200)* @cheri_offset_set(i8 addrspace(200)* noundef readnone %{{.*}}, i64 noundef %{{.*}})
// CAPS-AARCH64: call i8 addrspace(200)* @llvm.cheri.cap.offset.set.i64(i8 addrspace(200)* %{{.*}}, i64 %{{.*}})
// CAPS-AARCH64: define i32 @cheri_type_get(i8 addrspace(200)* noundef %{{.*}})
// CAPS-AARCH64: call i64 @llvm.cheri.cap.type.get.i64(i8 addrspace(200)* %{{.*}})
// CAPS-AARCH64: define i32 @cheri_perms_get(i8 addrspace(200)* noundef %{{.*}})
// CAPS-AARCH64: call i64 @llvm.cheri.cap.perms.get.i64(i8 addrspace(200)* %{{.*}})
// CAPS-AARCH64: define i8 addrspace(200)* @cheri_perms_and(i8 addrspace(200)* noundef readnone %{{.*}}, i32 noundef %{{.*}})
// CAPS-AARCH64: call i8 addrspace(200)* @llvm.cheri.cap.perms.and.i64(i8 addrspace(200)* %{{.*}}, i64
// CAPS-AARCH64: define i1 @cheri_tag_get(i8 addrspace(200)* noundef readnone %{{.*}})
// CAPS-AARCH64: call i1 @llvm.cheri.cap.tag.get(i8 addrspace(200)* %{{.*}})
// CAPS-AARCH64: define i1 @cheri_sealed_get(i8 addrspace(200)* noundef readnone %{{.*}})
// CAPS-AARCH64: call i1 @llvm.cheri.cap.sealed.get(i8 addrspace(200)* %{{.*}})
// CAPS-AARCH64: define i8 addrspace(200)* @cheri_offset_increment(i8 addrspace(200)* noundef readnone %{{.*}}, i64 noundef %{{.*}})
// CAPS-AARCH64: getelementptr i8, i8 addrspace(200)* {{.*}}, i64
// CAPS-AARCH64: define i8 addrspace(200)* @cheri_tag_clear(i8 addrspace(200)* noundef readnone %{{.*}})
// CAPS-AARCH64: call i8 addrspace(200)* @llvm.cheri.cap.tag.clear(i8 addrspace(200)* %{{.*}})
// CAPS-AARCH64: define i8 addrspace(200)* @cheri_seal(i8 addrspace(200)* noundef readnone %{{.*}}, i8 addrspace(200)* noundef readnone %{{.*}})
// CAPS-AARCH64: call i8 addrspace(200)* @llvm.cheri.cap.seal(i8 addrspace(200)* %{{.*}}, i8 addrspace(200)* %{{.*}})
// CAPS-AARCH64: define i8 addrspace(200)* @cheri_unseal(i8 addrspace(200)* noundef readnone %{{.*}}, i8 addrspace(200)* noundef readnone %{{.*}})
// CAPS-AARCH64: call i8 addrspace(200)* @llvm.cheri.cap.unseal(i8 addrspace(200)* %{{.*}}, i8 addrspace(200)* %{{.*}})
// CAPS-AARCH64: define i8 addrspace(200)* @cheri_bounds_set(i8 addrspace(200)* noundef readnone %{{.*}}, i64 noundef %{{.*}})
// CAPS-AARCH64: call i8 addrspace(200)* @llvm.cheri.cap.bounds.set.i64(i8 addrspace(200)* %{{.*}}, i64 %{{.*}})
// CAPS-AARCH64: define i64 @cheri_round_representable_length(i64 noundef %{{.*}})
// CAPS-AARCH64: call i64 @llvm.cheri.round.representable.length.i64(i64 %{{.*}})
// CAPS-AARCH64: define i64 @cheri_round_representable_mask(i64 noundef %{{.*}})
// CAPS-AARCH64: call i64 @llvm.cheri.representable.alignment.mask.i64(i64 %{{.*}})
// CAPS-AARCH64: define i64 @cheri_copy_from_high(i8 addrspace(200)* noundef readnone %{{.*}})
// CAPS-AARCH64: call i64 @llvm.cheri.cap.copy.from.high.i64(i8 addrspace(200)* %{{.*}})
// CAPS-AARCH64: define i8 addrspace(200)* @cheri_copy_to_high(i8 addrspace(200)* noundef readnone %{{.*}}, i64 noundef %{{.*}})
// CAPS-AARCH64: call i8 addrspace(200)* @llvm.cheri.cap.copy.to.high.i64(i8 addrspace(200)* %{{.*}}, i64 %{{.*}})
// CAPS-AARCH64: define i64 @cheri_equal_exact(i8 addrspace(200)* noundef %{{.*}}, i8 addrspace(200)* noundef %{{.*}})
// CAPS-AARCH64: call i1 @llvm.cheri.cap.equal.exact(i8 addrspace(200)* %{{.*}}, i8 addrspace(200)* %{{.*}})
// CAPS-AARCH64: define i64 @cheri_subset_test(i8 addrspace(200)* noundef %{{.*}}, i8 addrspace(200)* noundef %{{.*}})
// CAPS-AARCH64: call i1 @llvm.cheri.cap.subset.test(i8 addrspace(200)* %{{.*}}, i8 addrspace(200)* %{{.*}})
// CAPS-AARCH64: define i8 addrspace(200)* @cheri_cap_from_pointer(i8 addrspace(200)* noundef readnone %{{.*}}, i8* noundef %{{.*}})
// CAPS-AARCH64: call i8 addrspace(200)* @llvm.cheri.cap.from.pointer.i64(i8 addrspace(200)* %{{.*}}, i64
// CAPS-AArch64: define i64 @cheri_cap_to_pointer(i8 addrspace(200)* noundef readnone %{{.*}}, i8 addrspace(200)* noundef readnone %{{.*}})
// CAPS-AARCH64: call i64 @llvm.cheri.cap.to.pointer.i64(i8 addrspace(200)*
// CAPS-AARCH64: define i8 addrspace(200)* @cheri_global_data_get()
// CAPS-AARCH64: call i8 addrspace(200)* @llvm.cheri.ddc.get()
// CAPS-AARCH64: define i8 addrspace(200)* @cheri_program_counter_get()
// CAPS-AARCH64: call i8 addrspace(200)* @llvm.cheri.pcc.get()
