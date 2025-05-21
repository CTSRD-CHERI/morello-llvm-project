//===-- Memory.h ------------------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLDB_TARGET_MEMORY_H
#define LLDB_TARGET_MEMORY_H

#include "lldb/Utility/RangeMap.h"
#include "lldb/lldb-private.h"
#include <map>
#include <mutex>
#include <vector>

#include "llvm/Support/FormatProviders.h"

#include "lldb/Utility/RangeMap.h"
#include "lldb/lldb-private.h"

namespace lldb_private {

/// Get a name for a memory content type.
///
/// @param[in] type
///     The type of memory content.
///
/// @return
///     The human-readable name for \a type.
const char *GetMemoryContentTypeAsCString(lldb::MemoryContentType type);

/// Check if the memory content type is a tagged one.
///
/// @param[in] type
///     The type of memory content.
///
/// @return
///     Returns \b true if \a type is a tagged memory content type,
///     \b false otherwise.
bool IsTaggedMemoryContentType(lldb::MemoryContentType type);

// Queries for tagged memory.
struct TaggedMemory {
  /// Get a base (untagged) byte size for a tagged memory type.
  ///
  /// @param[in] type
  ///     The type of tagged memory.
  ///
  /// @return
  ///     The base byte size of \a type.
  static uint32_t GetBaseByteSize(lldb::MemoryContentType type);

  /// Get a tag byte size for a tagged memory type.
  ///
  /// @param[in] type
  ///     The type of tagged memory.
  ///
  /// @return
  ///     The tag byte size of \a type.
  //------------------------------------------------------------------
  static uint32_t GetTagByteSize(lldb::MemoryContentType type);

  /// Get a tagged byte size for a tagged memory type.
  ///
  /// @param[in] type
  ///     The type of tagged memory.
  ///
  /// @return
  ///     The tagged byte size of \a type.
  static uint32_t GetTaggedByteSize(lldb::MemoryContentType type);

  /// Get a tagged memory type used to store a capability.
  ///
  /// @param[in] byte_size
  ///     The size of the capability in bytes.
  ///
  /// @param[out] content_type
  ///     The tagged memory type to store the capability.
  ///
  /// @param[out] error
  ///     An error descriptor if no appropriate tagged memory type was
  ///     recognized for the capability.
  ///
  /// @return
  ///     \b true on success, \b false otherwise.
  static bool GetCapabilityType(uint32_t byte_size,
                                lldb::MemoryContentType &content_type,
                                Status &error);

  /// Transform a tagged memory data to an actual value.
  ///
  /// @param[in,out] data
  ///     A data extractor that contains the input tagged memory data.
  ///     If the function succeeds, it is updated with the value
  ///     constructed from the data.
  ///
  /// @param[in] content_type
  ///     A type of the tagged memory stored in \a data.
  ///
  /// @param[in] byte_order
  ///     A byte order used to store the value in \a data.
  ///
  /// @param[out] error
  ///     An error descriptor if a value could not be constructed from
  ///     the provided data.
  ///
  /// @return
  ///     \b true on success, \b false otherwise.
  static bool TransformDataToValue(DataExtractor &data,
                                   lldb::MemoryContentType content_type,
                                   lldb::ByteOrder byte_order, Status &error);
};

// A class to track memory that was read from a live process between
// runs.
class MemoryCache {
public:
  // Constructors and Destructors
  MemoryCache(Process &process);

  ~MemoryCache();

  void Clear(bool clear_invalid_ranges = false);

  void Flush(lldb::addr_t addr, size_t size);

  size_t Read(lldb::addr_t addr, void *dst, size_t dst_len, Status &error);

  uint32_t GetMemoryCacheLineSize() const { return m_L2_cache_line_byte_size; }

  void AddInvalidRange(lldb::addr_t base_addr, lldb::addr_t byte_size);

  bool RemoveInvalidRange(lldb::addr_t base_addr, lldb::addr_t byte_size);

  // Allow external sources to populate data into the L1 memory cache
  void AddL1CacheData(lldb::addr_t addr, const void *src, size_t src_len);

  void AddL1CacheData(lldb::addr_t addr,
                      const lldb::DataBufferSP &data_buffer_sp);

protected:
  typedef std::map<lldb::addr_t, lldb::DataBufferSP> BlockMap;
  typedef RangeVector<lldb::addr_t, lldb::addr_t, 4> InvalidRanges;
  typedef Range<lldb::addr_t, lldb::addr_t> AddrRange;
  // Classes that inherit from MemoryCache can see and modify these
  std::recursive_mutex m_mutex;
  BlockMap m_L1_cache; // A first level memory cache whose chunk sizes vary that
                       // will be used only if the memory read fits entirely in
                       // a chunk
  BlockMap m_L2_cache; // A memory cache of fixed size chinks
                       // (m_L2_cache_line_byte_size bytes in size each)
  InvalidRanges m_invalid_ranges;
  Process &m_process;
  uint32_t m_L2_cache_line_byte_size;

private:
  MemoryCache(const MemoryCache &) = delete;
  const MemoryCache &operator=(const MemoryCache &) = delete;

  lldb::DataBufferSP GetL2CacheLine(lldb::addr_t addr, Status &error);
};

    

class AllocatedBlock {
public:
  AllocatedBlock(lldb::addr_t addr, uint32_t byte_size, uint32_t permissions,
                 uint32_t chunk_size);

  ~AllocatedBlock();

  lldb::addr_t ReserveBlock(uint32_t size);

  bool FreeBlock(lldb::addr_t addr);

  lldb::addr_t GetBaseAddress() const { return m_range.GetRangeBase(); }

  uint32_t GetByteSize() const { return m_range.GetByteSize(); }

  uint32_t GetPermissions() const { return m_permissions; }

  uint32_t GetChunkSize() const { return m_chunk_size; }

  bool Contains(lldb::addr_t addr) const {
    return m_range.Contains(addr);
  }

protected:
  uint32_t TotalChunks() const { return GetByteSize() / GetChunkSize(); }

  uint32_t CalculateChunksNeededForSize(uint32_t size) const {
    return (size + m_chunk_size - 1) / m_chunk_size;
  }
  // Base address of this block of memory 4GB of chunk should be enough.
  Range<lldb::addr_t, uint32_t> m_range;
  // Permissions for this memory (logical OR of lldb::Permissions bits)
  const uint32_t m_permissions;
  // The size of chunks that the memory at m_addr is divied up into.
  const uint32_t m_chunk_size;
  // A sorted list of free address ranges.
  RangeVector<lldb::addr_t, uint32_t> m_free_blocks;
  // A sorted list of reserved address.
  RangeVector<lldb::addr_t, uint32_t> m_reserved_blocks;
};

// A class that can track allocated memory and give out allocated memory
// without us having to make an allocate/deallocate call every time we need
// some memory in a process that is being debugged.
class AllocatedMemoryCache {
public:
  // Constructors and Destructors
  AllocatedMemoryCache(Process &process);

  ~AllocatedMemoryCache();

  void Clear(bool deallocate_memory);

  lldb::addr_t AllocateMemory(size_t byte_size, uint32_t permissions,
                              Status &error);

  bool DeallocateMemory(lldb::addr_t ptr);

protected:
  typedef std::shared_ptr<AllocatedBlock> AllocatedBlockSP;

  AllocatedBlockSP AllocatePage(uint32_t byte_size, uint32_t permissions,
                                uint32_t chunk_size, Status &error);

  // Classes that inherit from MemoryCache can see and modify these
  Process &m_process;
  std::recursive_mutex m_mutex;
  typedef std::multimap<uint32_t, AllocatedBlockSP> PermissionsToBlockMap;
  PermissionsToBlockMap m_memory_map;

private:
  AllocatedMemoryCache(const AllocatedMemoryCache &) = delete;
  const AllocatedMemoryCache &operator=(const AllocatedMemoryCache &) = delete;
};

} // namespace lldb_private

namespace llvm {
template <> struct format_provider<lldb::MemoryContentType> {
  static void format(const lldb::MemoryContentType &type, raw_ostream &Stream,
                     StringRef Style) {
    Stream << lldb_private::GetMemoryContentTypeAsCString(type);
  }
};
} // namespace llvm

#endif // LLDB_TARGET_MEMORY_H
