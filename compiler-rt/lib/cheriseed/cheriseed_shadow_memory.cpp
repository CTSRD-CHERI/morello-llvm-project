//===-- cheriseed_shadow_memory.cpp -----------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// This file implements shadow memory support for the sanitizer.
//
//===----------------------------------------------------------------------===//

#include "cheriseed_shadow_memory.h"

#include <sys/mman.h>

#include "cheriseed_common.h"
#include "sanitizer_common/sanitizer_common.h"
#include "sanitizer_common/sanitizer_posix.h"

using __sanitizer::usize;
using __sanitizer::vaddr;

namespace __cheriseed {

// Unmaps a memory range.
static bool UnMap(const MemoryRange &mem) {
  return (__sanitizer::internal_munmap(reinterpret_cast<void *>(mem.GetBase()),
                                       mem.GetSize()) == 0);
}

// Reserves a memory range with read-write permissions.
static MemoryRange ReserveMemory(usize size, usize alignment) {
  CHECK("Cannot map shadow memory." && (0 == (size % Globals::SystemPageSize)));
  CHECK("Cannot map shadow memory." &&
        (0 == (alignment % Globals::SystemPageSize)));

  // Reserve memory, which will be larger than the requested size.
  const usize map_size = size + alignment;
  const vaddr map_start = __sanitizer::internal_mmap(
      nullptr, map_size, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE,
      -1, 0);
  CHECK("Cannot map shadow memory." && (map_start != (vaddr)MAP_FAILED));

  MemoryRange shadow_memory(
      __sanitizer::RoundUpTo(map_start, alignment),
      __sanitizer::RoundUpTo(map_start, alignment) + size);

  // Unmap unused pages at start due to alignment.
  MemoryRange unused_pages_start(map_start, shadow_memory.GetBase());
  if (unused_pages_start.GetSize())
    CHECK("Could not unmap unused page start." && UnMap(unused_pages_start));

  // Unmap unused pages at the end due to alignment.
  MemoryRange unused_pages_end(shadow_memory.GetEnd(), map_start + map_size);
  if (unused_pages_end.GetSize())
    CHECK("Could not unmap unused page end." && UnMap(unused_pages_end));

  return shadow_memory;
}

static void FixedMap(const MemoryRange &mem, int protection) {
  if (mem.GetBase() !=
      (vaddr)__sanitizer::internal_mmap(
          reinterpret_cast<void *>(mem.GetBase()), mem.GetSize(), protection,
          MAP_FIXED | MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE, -1, 0) != 0)
    CHECK("Can't map Unaccessible." && 0);
}

// Makes a memory range accessible.
void FixedMapAccessible(const MemoryRange &mem) {
  FixedMap(mem, PROT_READ | PROT_WRITE);
}

// Makes a memory range non-accessible.
static void FixedMapUnaccessible(const MemoryRange &mem) {
  FixedMap(mem, PROT_NONE);
}

void ShadowMemoryInit() {
  Globals::ShadowMap = ShadowMemory(__sanitizer::GetMaxUserVirtualAddress(),
                                    Globals::SystemPageSize, kShadowScale);
  MemoryRange shadow_memory = ReserveMemory(Globals::ShadowMap.GetShadowSize(),
                                            Globals::ShadowMap.GetAlignment());
  Globals::ShadowMap.SetShadowMemory(shadow_memory);

  FixedMapAccessible(Globals::ShadowMap.GetShadowMemoryRangeLow());
  FixedMapUnaccessible(Globals::ShadowMap.GetShadowGapRange());
  FixedMapAccessible(Globals::ShadowMap.GetShadowMemoryRangeHigh());
}

}  // namespace __cheriseed
