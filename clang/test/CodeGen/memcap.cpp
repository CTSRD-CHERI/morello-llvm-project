// RUN: %clang %s -O1 -target cheri-unknown-freebsd -o - -emit-llvm -S -std=c++11 | FileCheck %s --check-prefix=CAPS
// RUN: %clang %s -O1 -target aarch64-none-linux-gnu -march=morello -o - -emit-llvm -S -std=c++11 -fPIC | FileCheck %s --check-prefix=CAPS-AARCH64
// RUN: %clang %s -O1 -target aarch64-none-linux-gnu -o - -emit-llvm -S -std=c++11 -fPIC | FileCheck %s --check-prefix=PTRS-AARCH64

// Remove the static from all of the function prototypes so that this really exists.
#define static
#define inline
#include <cheri.h>

// PTRS-AARCH64: define noundef i64 @_Z16cheri_length_getPv(ptr nocapture noundef readnone %{{.*}})
// PTRS-AARCH64: ret i64 -1
// PTRS-AARCH64: define noundef i64 @_Z14cheri_base_getPv(ptr nocapture noundef readnone %{{.*}})
// PTRS-AARCH64: ret i64 -1
// PTRS-AARCH64: define noundef i64 @_Z16cheri_offset_getPv(ptr nocapture noundef readnone %{{.*}})
// PTRS-AARCH64: ret i64 -1
// PTRS-AARCH64: define noundef ptr @_Z16cheri_offset_setPvm(ptr noundef readnone returned %{{.*}}, i64  noundef %{{.*}})
// PTRS-AARCH64: ret ptr %{{.*}}
// PTRS-AARCH64: define noundef i32 @_Z14cheri_type_getPv(ptr nocapture noundef readnone %{{.*}})
// PTRS-AARCH64: ret i32 0
// PTRS-AARCH64: define noundef i32 @_Z15cheri_perms_getPv(ptr nocapture noundef readnone %{{.*}})
// PTRS-AARCH64: ret i32 0
// PTRS-AARCH64: define noundef ptr @_Z15cheri_perms_andPvj(ptr noundef readnone returned %{{.*}}, i32 noundef %{{.*}})
// PTRS-AARCH64: ret ptr %{{.*}}
// PTRS-AARCH64: define noundef i1 @_Z13cheri_tag_getPv(ptr nocapture noundef readnone %{{.*}})
// PTRS-AARCH64: ret i1 false
// PTRS-AARCH64: define noundef i1 @_Z16cheri_sealed_getPv(ptr nocapture noundef readnone %{{.*}})
// PTRS-AARCH64: ret i1 false
// PTRS-AARCH64: define noundef ptr @_Z22cheri_offset_incrementPvl(ptr noundef readnone %{{.*}}, i64 noundef %{{.*}})
// PTRS-AARCH64: %{{.*}} = getelementptr inbounds i8, ptr %{{.*}}, i64 %{{.*}}
// PTRS-AARCH64: ret ptr %{{.*}}
// PTRS-AARCH64: define noundef ptr @_Z15cheri_tag_clearPv(ptr noundef readnone returned %{{.*}})
// PTRS-AARCH64: ret ptr %{{.*}}
// PTRS-AARCH64: define noundef ptr @_Z10cheri_sealPvPKv(ptr noundef readnone returned %{{.*}}, ptr nocapture noundef readnone %{{.*}})
// PTRS-AARCH64: ret ptr %{{.*}}
// PTRS-AARCH64: define noundef ptr @_Z12cheri_unsealPvPKv(ptr noundef readnone returned %{{.*}}, ptr nocapture noundef readnone %{{.*}})
// PTRS-AARCH64: ret ptr %{{.*}}
// PTRS-AARCH64: define noundef ptr @_Z16cheri_bounds_setPvm(ptr noundef readnone returned %{{.*}}, i64 noundef %{{.*}})
// PTRS-AARCH64: ret ptr %{{.*}}
// PTRS-AARCH64: define noalias noundef ptr @_Z21cheri_global_data_getv()
// PTRS-AARCH64: ret ptr null
// PTRS-AARCH64: define noalias noundef ptr @_Z25cheri_program_counter_getv()
// PTRS-AARCH64: ret ptr null

// CAPS: define noundef i64 @_Z16cheri_length_getU12__capabilityPv(ptr addrspace(200) noundef readnone
// CAPS: call i64 @llvm.cheri.cap.length.get.i64(ptr addrspace(200)
// CAPS: define noundef i64 @_Z14cheri_base_getU12__capabilityPv(ptr addrspace(200) noundef readnone
// CAPS: call i64 @llvm.cheri.cap.base.get.i64(ptr addrspace(200)
// CAPS: define noundef i64 @_Z16cheri_offset_getU12__capabilityPv(ptr addrspace(200) noundef readnone
// CAPS: call i64 @llvm.cheri.cap.offset.get.i64(ptr addrspace(200)
// CAPS: define noundef ptr addrspace(200) @_Z16cheri_offset_setU12__capabilityPvm(ptr addrspace(200) noundef readnone{{.*}}, i64 noundef zeroext{{.*}}
// CAPS: call ptr addrspace(200) @llvm.cheri.cap.offset.set.i64(ptr addrspace(200){{.*}}, i64{{.*}})
// CAPS: define noundef signext i32 @_Z14cheri_type_getU12__capabilityPv(ptr addrspace(200)
// CAPS: call i64 @llvm.cheri.cap.type.get.i64(ptr addrspace(200)
// CAPS: define noundef zeroext i16 @_Z15cheri_perms_getU12__capabilityPv(ptr addrspace(200)
// CAPS: call i64 @llvm.cheri.cap.perms.get.i64(ptr addrspace(200)
// CAPS: define noundef ptr addrspace(200) @_Z15cheri_perms_andU12__capabilityPvt(ptr addrspace(200) noundef readnone{{.*}}, i16 noundef zeroext
// CAPS: call ptr addrspace(200) @llvm.cheri.cap.perms.and.i64(ptr addrspace(200){{.*}}, i64
// CAPS: define noundef zeroext i1 @_Z13cheri_tag_getU12__capabilityPv(ptr addrspace(200) noundef readnone
// CAPS: call i1 @llvm.cheri.cap.tag.get(ptr addrspace(200)
// CAPS: define noundef zeroext i1 @_Z16cheri_sealed_getU12__capabilityPv(ptr addrspace(200) noundef readnone
// CAPS: call i1 @llvm.cheri.cap.sealed.get(ptr addrspace(200)
// CAPS: define noundef ptr addrspace(200) @_Z22cheri_offset_incrementU12__capabilityPvl(ptr addrspace(200) noundef readnone{{.*}}, i64 noundef signext
// CAPS: getelementptr i8, ptr addrspace(200) {{.*}}, i64
// CAPS: define noundef ptr addrspace(200) @_Z15cheri_tag_clearU12__capabilityPv(ptr addrspace(200) noundef readnone
// CAPS: call ptr addrspace(200) @llvm.cheri.cap.tag.clear(ptr addrspace(200)
// CAPS: define noundef ptr addrspace(200) @_Z10cheri_sealU12__capabilityPvU12__capabilityPKv(ptr addrspace(200) noundef readnone{{.*}}, ptr addrspace(200) noundef readnone
// CAPS: call ptr addrspace(200) @llvm.cheri.cap.seal(ptr addrspace(200){{.*}}, ptr addrspace(200)
// CAPS: define noundef ptr addrspace(200) @_Z12cheri_unsealU12__capabilityPvU12__capabilityPKv(ptr addrspace(200) noundef readnone{{.*}}, ptr addrspace(200) noundef readnone
// CAPS: call ptr addrspace(200) @llvm.cheri.cap.unseal(ptr addrspace(200){{.*}}, ptr addrspace(200)
// CAPS: define noundef ptr addrspace(200) @_Z16cheri_bounds_setU12__capabilityPvm(ptr addrspace(200) noundef readnone{{.*}}, i64 noundef zeroext{{.*}}
// CAPS: call ptr addrspace(200) @llvm.cheri.cap.bounds.set.i64(ptr addrspace(200){{.*}}, i64
// CAPS: define void @_Z17cheri_perms_checkU12__capabilityPKvt(ptr addrspace(200){{.*}}, i16 noundef zeroext
// CAPS: call void @llvm.cheri.cap.perms.check.i64(ptr addrspace(200){{.*}}, i64
// CAPS: define void @_Z16cheri_type_checkU12__capabilityPKvS0_(ptr addrspace(200){{.*}}, ptr addrspace(200)
// CAPS: call void @llvm.cheri.cap.type.check(ptr addrspace(200){{.*}}, ptr addrspace(200)
// CAPS: define noundef ptr addrspace(200) @_Z21cheri_global_data_getv()
// CAPS: call ptr addrspace(200) @llvm.cheri.ddc.get()
// CAPS: define noundef ptr addrspace(200) @_Z25cheri_program_counter_getv()
// CAPS: call ptr addrspace(200) @llvm.cheri.pcc.get()

// CAPS-AARCH64: define noundef i64 @_Z16cheri_length_getU12__capabilityPv(ptr addrspace(200) noundef readnone %{{.*}})
// CAPS-AARCH64: call i64 @llvm.cheri.cap.length.get.i64(ptr addrspace(200) %{{.*}})
// CAPS-AARCH64: define noundef i64 @_Z14cheri_base_getU12__capabilityPv(ptr addrspace(200) noundef readnone %{{.*}})
// CAPS-AARCH64: call i64 @llvm.cheri.cap.base.get.i64(ptr addrspace(200) %{{.*}})
// CAPS-AARCH64: define noundef i64 @_Z16cheri_offset_getU12__capabilityPv(ptr addrspace(200) noundef readnone %{{.*}})
// CAPS-AARCH64: call i64 @llvm.cheri.cap.offset.get.i64(ptr addrspace(200) %{{.*}})
// CAPS-AARCH64: define noundef ptr addrspace(200) @_Z16cheri_offset_setU12__capabilityPvm(ptr addrspace(200) noundef readnone %{{.*}}, i64 noundef %{{.*}})
// CAPS-AARCH64: call ptr addrspace(200) @llvm.cheri.cap.offset.set.i64(ptr addrspace(200) %{{.*}}, i64 %{{.*}})
// CAPS-AARCH64: define noundef i32 @_Z14cheri_type_getU12__capabilityPv(ptr addrspace(200) noundef %{{.*}})
// CAPS-AARCH64: call i64 @llvm.cheri.cap.type.get.i64(ptr addrspace(200) %{{.*}})
// CAPS-AARCH64: define noundef i32 @_Z15cheri_perms_getU12__capabilityPv(ptr addrspace(200) noundef %{{.*}})
// CAPS-AARCH64: call i64 @llvm.cheri.cap.perms.get.i64(ptr addrspace(200) %{{.*}})
// CAPS-AARCH64: define noundef ptr addrspace(200) @_Z15cheri_perms_andU12__capabilityPvj(ptr addrspace(200) noundef readnone %{{.*}}, i32 noundef %{{.*}})
// CAPS-AARCH64: call ptr addrspace(200) @llvm.cheri.cap.perms.and.i64(ptr addrspace(200) %{{.*}}, i64
// CAPS-AARCH64: define noundef i1 @_Z13cheri_tag_getU12__capabilityPv(ptr addrspace(200) noundef readnone %{{.*}})
// CAPS-AARCH64: call i1 @llvm.cheri.cap.tag.get(ptr addrspace(200) %{{.*}})
// CAPS-AARCH64: define noundef i1 @_Z16cheri_sealed_getU12__capabilityPv(ptr addrspace(200) noundef readnone %{{.*}})
// CAPS-AARCH64: call i1 @llvm.cheri.cap.sealed.get(ptr addrspace(200) %{{.*}})
// CAPS-AARCH64: define noundef ptr addrspace(200) @_Z22cheri_offset_incrementU12__capabilityPvl(ptr addrspace(200) noundef readnone %{{.*}}, i64 noundef %{{.*}})
// CAPS-AARCH64:  getelementptr i8, ptr addrspace(200) {{.*}}, i64
// CAPS-AARCH64: define noundef ptr addrspace(200) @_Z15cheri_tag_clearU12__capabilityPv(ptr addrspace(200) noundef readnone %{{.*}})
// CAPS-AARCH64: call ptr addrspace(200) @llvm.cheri.cap.tag.clear(ptr addrspace(200) %{{.*}})
// CAPS-AARCH64: define noundef ptr addrspace(200) @_Z10cheri_sealU12__capabilityPvU12__capabilityPKv(ptr addrspace(200) noundef readnone %{{.*}}, ptr addrspace(200) noundef readnone %{{.*}})
// CAPS-AARCH64: call ptr addrspace(200) @llvm.cheri.cap.seal(ptr addrspace(200) %{{.*}}, ptr addrspace(200) %{{.*}})
// CAPS-AARCH64: define noundef ptr addrspace(200) @_Z12cheri_unsealU12__capabilityPvU12__capabilityPKv(ptr addrspace(200) noundef readnone %{{.*}}, ptr addrspace(200) noundef readnone %{{.*}})
// CAPS-AARCH64: call ptr addrspace(200) @llvm.cheri.cap.unseal(ptr addrspace(200) %{{.*}}, ptr addrspace(200) %{{.*}})
// CAPS-AARCH64: define noundef ptr addrspace(200) @_Z16cheri_bounds_setU12__capabilityPvm(ptr addrspace(200) noundef readnone %{{.*}}, i64 noundef %{{.*}})
// CAPS-AARCH64: call ptr addrspace(200) @llvm.cheri.cap.bounds.set.i64(ptr addrspace(200) %{{.*}}, i64  %{{.*}})
// CAPS-AARCH64: define noundef ptr addrspace(200) @_Z21cheri_global_data_getv()
// CAPS-AARCH64: call ptr addrspace(200) @llvm.cheri.ddc.get()
// CAPS-AARCH64: define noundef ptr addrspace(200) @_Z25cheri_program_counter_getv()
// CAPS-AARCH64: call ptr addrspace(200) @llvm.cheri.pcc.get()
