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

#define CHERISEED_UNIT_TESTING

#include "cheriseed_test_utils.h"

using namespace utils;
using namespace __cheriseed;

#define INSERT_INTO_SECTION(_cap, _addr, _size, _masks, _initFunc)        \
  {                                                                       \
    if (_cap)                                                             \
      LocalCap{NoOptionsEnabled{}, reinterpret_cast<u64>(_addr),          \
               __cheriseed::abi::CompressInitSizeAndPerms(_size, _masks)} \
          .Store(_cap);                                                   \
    static __cheriseed_initializer_t data                                 \
        __attribute__((section("__cheriseed_initializers"))) = {0, 0};    \
    data.cap = _cap;                                                      \
    data.init_fn = (void (*)())_initFunc;                                 \
  }

static constexpr __cheriseed::abi::Permissions NoPermsToClear =
    static_cast<__cheriseed::abi::Permissions>(0);

// Test helpers
static int a;
static void func_1() {}  // Do Nothing
static void func_2() { a += 1; }

TEST(CheckGlobalInits, ShadowCapInit) {
  static __cheriseed_cap_t cap;
  INSERT_INTO_SECTION(&cap, &a, sizeof(a), NoPermsToClear, &func_1);

  __cheriseed_static_init(0);
  __cheriseed_relocate();
  ASSERT_CAPABILITY_VALUE_EQ(&cap, &a);
  ASSERT_TAGGED(&cap);
}

TEST(CheckGlobalInits, InitializerFuncCall) {
  a = 1;
  INSERT_INTO_SECTION(0, nullptr, 0, NoPermsToClear, &func_2);

  ASSERT_EQ(a, 1);
  __cheriseed_static_init(0);
  __cheriseed_relocate();
  ASSERT_EQ(a, 2);
}

TEST(CheckGlobalInits, Bounds) {
  static int t;
  static __cheriseed_cap_t cap;
  INSERT_INTO_SECTION(&cap, &t, sizeof(t), NoPermsToClear, &func_1);

  __cheriseed_static_init(0);
  __cheriseed_relocate();
  ASSERT_EQ(__cheriseed_length_get(&cap), sizeof(t));
  ASSERT_TAGGED(&cap);
}

TEST(CheckGlobalInits, Perms) {
  static int t;
  static __cheriseed_cap_t cap;
  INSERT_INTO_SECTION(&cap, &t, 0, __cheriseed::abi::Permissions::STORE,
                      &func_1);

  __cheriseed_static_init(0);
  __cheriseed_relocate();
  ASSERT_EQ(__cheriseed_perms_get(&cap),
            __cheriseed::abi::Permissions::ALL &
                ~__cheriseed::abi::Permissions::STORE);
  ASSERT_TAGGED(&cap);
}
