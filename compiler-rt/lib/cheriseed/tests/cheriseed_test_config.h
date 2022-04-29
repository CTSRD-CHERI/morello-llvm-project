//===-- cheriseed_test_config.h ---------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// Test configuration for CHERIseed unit tests.
//
//===----------------------------------------------------------------------===//

#ifndef CHERISEED_TEST_CONFIG_H
#define CHERISEED_TEST_CONFIG_H

#if !defined(CHERISEED_TEST_UTILS_H)
#error \
    "This file should not be included directly. Include 'cheriseed_test_utils.h' instead."
#endif

#include "gtest/gtest.h"

#endif  // CHERISEED_TEST_CONFIG_H
