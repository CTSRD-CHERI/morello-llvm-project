//===-- cheriseed_shadow_memory.h -------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// This file defines shadow memory support for the sanitizer.
//
//===----------------------------------------------------------------------===//

#ifndef CHERISEED_SHADOW_MEMORY_H
#define CHERISEED_SHADOW_MEMORY_H

#include "sanitizer_common/sanitizer_internal_defs.h"

using __sanitizer::u8;
using __sanitizer::usize;
using __sanitizer::vaddr;

namespace __cheriseed {

// Shadow scale for CHERIseed.
static constexpr u8 kShadowScale = 4;

// Executes shadow memory reservations.
void ShadowMemoryInit();

// Represents a memory range with the base and end address.
// Here, end address is not inclusive.
struct MemoryRange {
  constexpr MemoryRange() : base(0), end(0) {}
  constexpr MemoryRange(vaddr base, vaddr end) : base(base), end(end) {}

  vaddr GetBase() const { return base; }
  vaddr GetEnd() const { return end; }
  usize GetSize() const { return end - base; }
  bool Contains(vaddr address) const {
    return (base <= address) && (address <= end);
  }

 private:
  vaddr base, end;
};  // struct MemoryRange

// Interface for shadow memory features.
struct ShadowMemory {
  constexpr ShadowMemory() : shadow_scale(0), shadow_memory(), page_size(0) {}

  // Note: va_max is the last theoretically addressable byte.
  ShadowMemory(vaddr va_max, usize page_size, u8 shadow_scale)
      : shadow_scale(shadow_scale),
        shadow_memory(0, (va_max + 1) >> shadow_scale),
        page_size(page_size) {}

  // Sets the shadow memory range which was allocated before.
  void SetShadowMemory(MemoryRange shadow_memory) {
    this->shadow_memory = shadow_memory;
    shadow_memory_gap = {GetShadowAddressFrom(shadow_memory.GetBase()),
                         GetShadowAddressFrom(shadow_memory.GetEnd())};
    shadow_memory_low = {shadow_memory.GetBase(),
                         GetShadowGapRange().GetBase()};
    shadow_memory_high = {GetShadowGapRange().GetEnd(), shadow_memory.GetEnd()};
  };

  // Returns the minimum alignment of the shadow memory.
  usize GetAlignment() const { return page_size << shadow_scale; }

  // Returns the size of the shadow memory.
  usize GetShadowSize() const { return GetShadowMemoryRange().GetSize(); }

  // Returns the full shadow memory range.
  const MemoryRange& GetShadowMemoryRange() const { return shadow_memory; }

  // Returns the range for the lower part of the shadow memory.
  const MemoryRange& GetShadowMemoryRangeLow() const {
    return shadow_memory_low;
  }

  // Returns the range for the higher part of the shadow memory.
  const MemoryRange& GetShadowMemoryRangeHigh() const {
    return shadow_memory_high;
  }

  // Returns the shadow gap range.
  const MemoryRange& GetShadowGapRange() const { return shadow_memory_gap; }

  // Returns the shadow address associated with a virtual address.
  vaddr GetShadowAddressFrom(vaddr address) const {
    return GetShadowMemoryRange().GetBase() + (address >> kShadowScale);
  }

  template <typename... Ts>
  void IterateTagRanges(const MemoryRange& range,
                        void (*callback)(const MemoryRange&, Ts...),
                        Ts... args) const {
    callback(GetTagRange(range), args...);
  }

  template <typename... Ts>
  void ZipTagRange(const MemoryRange& range_src, const MemoryRange& range_dest,
                   void (*callback)(const MemoryRange&, const MemoryRange&,
                                    Ts...),
                   Ts... args) const {
    callback(GetTagRange(range_src), GetTagRange(range_dest), args...);
  }

 private:
  // Returns tag address range from the given memory address range.
  MemoryRange GetTagRange(const MemoryRange& range) const {
    if (UNLIKELY(GetShadowMemoryRange().Contains(range.GetBase()) ||
                 GetShadowMemoryRange().Contains(range.GetEnd()))) {
      // TODO: Incorrect case.
    }

    return MemoryRange(
        GetShadowAddressFrom(range.GetBase()),
        GetShadowAddressFrom(range.GetEnd() + (1 << shadow_scale) - 1));
  }

  // Shadow scale for the map.
  u8 shadow_scale;
  // Full shadow memory range.
  MemoryRange shadow_memory;
  // Low shadow memory range.
  MemoryRange shadow_memory_low;
  // Gap shadow memory range.
  MemoryRange shadow_memory_gap;
  // High shadow memory range.
  MemoryRange shadow_memory_high;
  // Page size.
  usize page_size;
};  // ShadowMemory

void FixedMapAccessible(const MemoryRange& mem);

}  // namespace __cheriseed
#endif  // CHERISEED_SHADOW_MEMORY_H
