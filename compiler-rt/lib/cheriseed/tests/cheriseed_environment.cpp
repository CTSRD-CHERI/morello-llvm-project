//===-- cheriseed_environment.cpp -------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// Unit tests for configuration controls
//
//===----------------------------------------------------------------------===//

#define CHERISEED_UNIT_TESTING

#include "cheriseed_test_utils.h"

using namespace __cheriseed::abi;

using __cheriseed::Environment;
using utils::OnStackArgs;

TEST(Environment, None) {
  Environment env = Environment::From(0);

  EXPECT_EQ(env.GetEnv(nullptr), nullptr);
  EXPECT_EQ(env.GetEnv(""), nullptr);
  EXPECT_EQ(env.GetEnv("Foo"), nullptr);
}

TEST(Environment, Env) {
  const char *env_var = "FOO=";
  OnStackArgs args(&env_var[0]);
  Environment env = Environment::From(args.GetAddress());

  EXPECT_EQ(env.GetEnv(nullptr), nullptr);
  EXPECT_EQ(env.GetEnv(""), nullptr);
  EXPECT_EQ(env.GetEnv("Foo"), nullptr);
  EXPECT_EQ(env.GetEnv("FOO="), nullptr);
  EXPECT_EQ(env.GetEnv("FOO"), &env_var[0]);
}
