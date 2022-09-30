//===-- cheriseed_check_global_inits.cpp ------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// Unit tests to check __cheriseed_static_init functionalities.
//
//===----------------------------------------------------------------------===//

#include "cheriseed_test_utils.h"

using namespace utils;

#define INSERT_INTO_SECTION(_cap, _addr, _size, _masks, _initFunc)       \
  {                                                                      \
    static __cheriseed::__cheriseed_initializer_t data                   \
        __attribute__((section("__cheriseed_initializers"))) = {         \
            reinterpret_cast<__cheriseed::__cheriseed_cap_t *>(_cap),    \
            (u64)_addr, (u64)_size, (u32)_masks, (void (*)())_initFunc}; \
  }

// Test helpers
static int a;
static void func_1() {}  // Do Nothing
static void func_2() { a += 1; }

TEST(CheckGlobalInits, ShadowCapInit) {
  static __cheriseed_cap_t cap;
  utils::InitCap(&cap, 0, 0);
  INSERT_INTO_SECTION(&cap, &a, 0, 0, &func_1);

  ASSERT_CAPABILITY_VALUE_EQ(&cap, 0);
  __cheriseed_static_init(0);
  __cheriseed_relocate(0, 0);
  ASSERT_CAPABILITY_VALUE_EQ(&cap, &a);
}

TEST(CheckGlobalInits, InitializerFuncCall) {
  a = 1;
  INSERT_INTO_SECTION(0, 0, 0, 0, &func_2);

  ASSERT_EQ(a, 1);
  __cheriseed_static_init(0);
  __cheriseed_relocate(0, 0);
  ASSERT_EQ(a, 2);
}

TEST(CheckGlobalInits, Bounds) {
  static int t;
  static __cheriseed_cap_t cap;
  utils::InitCap(&cap, 0, 0);
  INSERT_INTO_SECTION(&cap, &t, sizeof(int), 0, &func_1);

  __cheriseed_static_init(0);
  __cheriseed_relocate(0, 0);
  ASSERT_EQ(__cheriseed_length_get(&cap), sizeof(int));
}

TEST(CheckGlobalInits, Perms) {
  static int t;
  static __cheriseed_cap_t cap;
  utils::InitCap(&cap, 0, 0);
  INSERT_INTO_SECTION(&cap, &t, 0, __cheriseed::abi::Permissions::STORE,
                      &func_1);

  __cheriseed_static_init(0);
  __cheriseed_relocate(0, 0);
  ASSERT_EQ(__cheriseed_perms_get(&cap),
            ccl::permissions::ALL & ~ccl::permissions::STORE);
}
