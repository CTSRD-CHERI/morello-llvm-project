//===-- cheriseed_relocate.cpp ----------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of CHERIseed Runtime Library.
//
// This file contains the implementation of the function(s) responsible for
// processing capability "relocations".
//
//===----------------------------------------------------------------------===//

#include "cheriseed_interface_internal.h"

using namespace __cheriseed;

// clang-format off
#if defined(__aarch64__)
#define SYM_ADDR(__sym)                           \
  ({                                              \
    u64 __addr;                                   \
    asm volatile(".weak " __sym "\n"              \
                 ".hidden " __sym "\n"            \
                 "adrp %0, " __sym "\n"           \
                 "add  %0, %0, :lo12:" __sym "\n" \
                 : "=r"(__addr));                 \
    __addr;                                       \
  })
#elif defined(__x86_64__)
#define SYM_ADDR(__sym)                      \
  ({                                         \
    u64 __addr;                              \
    asm volatile(".weak " __sym "\n"         \
                 ".hidden " __sym "\n"       \
                 "lea " __sym "(%%rip),%0\n" \
                 : "=r"(__addr));            \
    __addr;                                  \
  })
#else
#error "Unsupported architecture"
#endif
// clang-format on

void __cheriseed_relocate() {
  u64 init_start = SYM_ADDR("__start___cheriseed_initializers");
  u64 init_stop = SYM_ADDR("__stop___cheriseed_initializers");

  if (!init_start)
    return;

  if (((init_stop - init_start) % sizeof(__cheriseed_initializer_t)) != 0)
    __builtin_trap();

  auto *glo_init = reinterpret_cast<__cheriseed_initializer_t *>(init_start);
  const auto *const glo_init_end =
      reinterpret_cast<__cheriseed_initializer_t *>(init_stop);

  // First, relocate global capabilities.
  for (; glo_init < glo_init_end; ++glo_init) {
    if (!glo_init->cap)
      continue;

    if (__cheriseed_tag_get(glo_init->cap))
      continue;

    u64 address = glo_init->cap->GetValue();
    if (address == 0)
      continue;

    u64 size;
    __cheriseed::abi::Permissions clear_perms;
    __cheriseed::abi::DecompressInitSizeAndPerms(glo_init->cap->GetMetadata(),
                                                 size, clear_perms);
    __cheriseed_generic_cap_init(glo_init->cap, address, size,
                                 static_cast<u32>(clear_perms));
  }

  // Second, call the initializer functions.
  glo_init = reinterpret_cast<__cheriseed_initializer_t *>(init_start);
  for (; glo_init < glo_init_end; ++glo_init)
    if (glo_init->init_fn)
      glo_init->init_fn();
}

void __cheriseed_tls_relocate() {
  u64 init_start = SYM_ADDR("__start___cheriseed_tls_initializers");
  u64 init_stop = SYM_ADDR("__stop___cheriseed_tls_initializers");

  if (!init_start)
    return;

  if (((init_stop - init_start) % sizeof(u64)) != 0)
    __builtin_trap();

  auto *glo_init = reinterpret_cast<InitFnTy *>(init_start);
  const auto *const glo_init_end = reinterpret_cast<InitFnTy *>(init_stop);

  for (; glo_init < glo_init_end; ++glo_init) (*glo_init)();
}
