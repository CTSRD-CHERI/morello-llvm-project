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

void __cheriseed_relocate(u64 init_start, u64 init_stop) {
  if ((init_start == 0) && (init_stop == 0)) {
#if defined(__aarch64__)
    asm volatile(
        ".weak __start___cheriseed_initializers\n"
        ".hidden __start___cheriseed_initializers\n"
        "adrp %0, __start___cheriseed_initializers\n"
        "add  %0, %0, :lo12:__start___cheriseed_initializers\n"
        : "=r"(init_start));
    asm volatile(
        ".weak __stop___cheriseed_initializers\n"
        ".hidden __stop___cheriseed_initializers\n"
        "adrp %0, __stop___cheriseed_initializers\n"
        "add  %0, %0, :lo12:__stop___cheriseed_initializers\n"
        : "=r"(init_stop));
#elif defined(__x86_64__)
    asm volatile(
        ".weak __start___cheriseed_initializers\n"
        ".hidden __start___cheriseed_initializers\n"
        "lea __start___cheriseed_initializers(%%rip),%0\n"
        : "=r"(init_start));
    asm volatile(
        ".weak __stop___cheriseed_initializers\n"
        ".hidden __stop___cheriseed_initializers\n"
        "lea __stop___cheriseed_initializers(%%rip),%0\n"
        : "=r"(init_stop));
#else
#error "Unsupported architecture"
#endif
  }

  if (!init_start)
    return;

  if (((init_stop - init_start) % sizeof(__cheriseed_initializer_t)) != 0)
    __builtin_trap();

  __cheriseed_initializer_t *glo_init_start =
      reinterpret_cast<__cheriseed_initializer_t *>(init_start);
  __cheriseed_initializer_t *glo_init_stop =
      reinterpret_cast<__cheriseed_initializer_t *>(init_stop);

  for (ssize idx = 0; idx < glo_init_stop - glo_init_start; ++idx) {
    if (!glo_init_start[idx].cap)
      continue;

    __cheriseed_generic_cap_init(
        glo_init_start[idx].cap, glo_init_start[idx].address,
        glo_init_start[idx].size, glo_init_start[idx].clear_perms);
  }

  for (ssize idx = 0; idx < glo_init_stop - glo_init_start; ++idx)
    if (glo_init_start[idx].init)
      glo_init_start[idx].init();
}
