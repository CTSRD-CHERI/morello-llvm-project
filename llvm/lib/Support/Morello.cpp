//===- Morello.cpp - Morello-specific utility functions for capabilities --===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "llvm/Support/MathExtras.h"
#include "llvm/Support/Morello.h"

using namespace llvm;

namespace llvm {

uint64_t getMorelloRequiredAlignment(uint64_t length) {
  // FIXME: In the specification l is a 65-bit value to permit the encoding
  // of 2^64. We don't have a case where length can be 2^64 at the moment.
  // Using formula E = 50 - CountLeadingZeros(length[64:15])
  uint64_t E = 0;
  if (length >> 15)
    // Add 1 to account for our length being 64-bit not 65-bit
    E = 50 - (countLeadingZeros(length) + 1);
  // Ie = 0 if E == 0 and Length[14] == 0; 1 otherwise
  if (E == 0 && ((length & 0x4000) == 0))
    // InternalExponent Ie = 0 no additional alignment requirements
    return 1;
  // Rounding up the length may carry into the next bit and require a one
  // higher exponent, so iterate once. This is guaranteed to converge.
  length = alignTo(length, uint64_t(1) << (E + 3));
  if (length >> 15)
      E = 50 - (countLeadingZeros(length) + 1);
  // InternalExponent Ie = 1 Alignment Requirement is 2 ^ E+3
  return uint64_t(1) << (E + 3);
}

} // namespace llvm
