//===- llvm/Support/SymbolSignature.h - Encoding function signatures --*- C++ //
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains a representation that encodes function signatures usable
// at runtime by the compartmentalising dynamic linker (c18n).
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_SUPPORT_SYMBOLSIGNATURE_H
#define LLVM_SUPPORT_SYMBOLSIGNATURE_H

#include <algorithm>

namespace llvm {

struct SymbolSignature {
  // The number of return values is encoded as follows:
  // enum {
  //   TWO,
  //   ONE,
  //   NONE,
  //   INDIRECT
  // };
  unsigned char ret_args : 2;
  unsigned char mem_args : 1;
  unsigned char reg_args : 4;
  unsigned char valid : 1;

  uint8_t toInt() const {
    return (valid << 7) | (reg_args << 3) | (mem_args << 2) | ret_args;
  }
  // For all signatures A and B, A <= B iff it is safe to cast a function with
  // signature A to a function with signature B. More preciesly, A takes equal
  // or fewer arguments than B and A returns equal or more values than B. A
  // signature with an indirect return value cannot be cast to one without, nor
  // vice versa. An invalid signature cannot be cast to any valid signature.
  bool leq(const SymbolSignature &other) const {
    if (!other.valid)
      return true;
    return valid &&
        reg_args <= other.reg_args &&
        mem_args <= other.mem_args &&
        (other.ret_args == 0b11 ?
            ret_args == 0b11 :
            ret_args <= other.ret_args);
  }
  // Compute the infimum with the other signature.
  bool meet(const SymbolSignature &other) {
    if (!valid)
      *this = other;
    else if (other.valid) {
      if ((ret_args == 0b11 && other.ret_args != 0b11) ||
          (ret_args != 0b11 && other.ret_args == 0b11))
        return false;
      ret_args = std::min(ret_args, other.ret_args);
      mem_args = std::min(mem_args, other.mem_args);
      reg_args = std::min(reg_args, other.reg_args);
    }
    return true;
  }
};

} // End llvm namespace

#endif
