//===-- Capability.cpp ------------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "lldb/Utility/Capability.h"

// C Includes
// C++ Includes
#include <string>

// Other libraries and framework includes
#include "llvm/ADT/ArrayRef.h"
// Project includes
#include "lldb/Utility/Log.h"
#include "lldb/Utility/LLDBLog.h"
#include "lldb/Utility/RegisterValue.h"

using namespace lldb;
using namespace lldb_private;

namespace AArch64_128 {
// Return whether the capability is valid, i.e. whether the tag bit is set.
bool IsCapabilityValid(const llvm::APInt &value) {
  if (value.getBitWidth() == 128)
    // Untagged capability
    return false;

  assert(value.getBitWidth() == 129 && "Invalid size for capability");
  return value[128];
}

// Return virtual address recorded in the capability.
uint64_t GetAddress(const llvm::APInt &value) {
  return value.extractBits(64, 0).getZExtValue();
}

llvm::APInt Add(const llvm::APInt &value, int64_t offset) {
  // Simplified version that assumes adding the offset does not invalidate the
  // capability.
  return value + offset;
}

struct PermNamePair {
  uint64_t mask; // For extracting this permission from the permissions field
                 // (not from the whole capability).
  const char *name;
};

// Morello-specific capability encoding details.
struct MorelloCapabilityEncoding {
  enum MorelloAddressPerm {
    eAddressPermGlobal = 1 << 0,
    eAddressPermExecutive = 1 << 1,
    eAddressPermUser0 = 1 << 2,
    eAddressPermUser1 = 1 << 3,
    eAddressPermUser2 = 1 << 4,
    eAddressPermUser3 = 1 << 5,
    eAddressPermMutableLoad = 1 << 6,
    eAddressPermCompartmentID = 1 << 7,
    eAddressPermBranchSealedPair = 1 << 8,
    eAddressPermSystem = 1 << 9,
    eAddressPermUnseal = 1 << 10,
    eAddressPermSeal = 1 << 11,
    eAddressPermStoreLocalCap = 1 << 12,
    eAddressPermStoreCap = 1 << 13,
    eAddressPermLoadCap = 1 << 14,
    eAddressPermExecute = 1 << 15,
    eAddressPermStore = 1 << 16,
    eAddressPermLoad = 1 << 17
  };

  // Get an array of permissions that may be set for this capability.
  static llvm::ArrayRef<PermNamePair> GetPermissionNamesLLDBVerbose() {
    static const PermNamePair perm_names[] = {
        {eAddressPermGlobal, "Global"},
        {eAddressPermExecutive, "Executive"},
        {eAddressPermUser0, "User0"},
        {eAddressPermUser1, "User1"},
        {eAddressPermUser2, "User2"},
        {eAddressPermUser3, "User3"},
        {eAddressPermMutableLoad, "MutableLoad"},
        {eAddressPermCompartmentID, "CompartmentID"},
        {eAddressPermBranchSealedPair, "BranchSealedPair"},
        {eAddressPermSystem, "System"},
        {eAddressPermUnseal, "Unseal"},
        {eAddressPermSeal, "Seal"},
        {eAddressPermStoreLocalCap, "StoreLocalCap"},
        {eAddressPermStoreCap, "StoreCap"},
        {eAddressPermLoadCap, "LoadCap"},
        {eAddressPermExecute, "Execute"},
        {eAddressPermStore, "Store"},
        {eAddressPermLoad, "Load"}};

    return perm_names;
  }

  static llvm::ArrayRef<PermNamePair> GetPermissionNamesCHERISimplified() {
    static const PermNamePair perm_names[] = {
        {eAddressPermLoad, "r"},     {eAddressPermStore, "w"},
        {eAddressPermExecute, "x"},  {eAddressPermLoadCap, "R"},
        {eAddressPermStoreCap, "W"}, {eAddressPermExecutive, "E"}};

    return perm_names;
  }

  // Get the value of the Permissions field in \p value.
  static uint64_t DecodePermissions(const llvm::APInt &value) {
    return value.extractBits(CAP_PERMS_NUM_BITS, CAP_PERMS_LO_BIT)
        .getZExtValue();
  }

  // Return whether the capability is sealed.
  static bool IsCapabilitySealed(const llvm::APInt &value) {
    return DecodeCapabilityOType(value) != 0;
  }

  static bool IsCapabilitySentry(const llvm::APInt &value) {
    return DecodeCapabilityOType(value) == CAP_OTYPE_SENTRY;
  }

  // Return the object type of the capability.
  static uint64_t DecodeCapabilityOType(const llvm::APInt &value) {
    return value.extractBits(CAP_OTYPE_NUM_BITS, CAP_OTYPE_LO_BIT)
        .getZExtValue();
  }

  // Return the bounds of the capability in \p base and \p limit.
  static void DecodeCapabilityAddressRange(const llvm::APInt &value,
                                           llvm::APInt &base,
                                           llvm::APInt &limit) {
    Log *log = GetLog(LLDBLog::DataFormatters);

    int exponent = CapGetEffectiveExponent(value);
    LLDB_LOGF(log, "[DecodeCapabilityAddressRange] exponent = %" PRId32,
              exponent);

    assert(exponent >= 0 && "Exponent cannot be negative");
    assert(exponent <= CAP_MAX_EXPONENT && "Exponent too large");

    llvm::APInt bottom = CapGetBottom(value);
    llvm::APInt top = CapGetTop(value);

    assert(bottom.getBitWidth() == CAP_MW && "Invalid width for bottom");
    assert(top.getBitWidth() == CAP_MW && "Invalid width for top");

    base = llvm::APInt::getNullValue(CAP_BOUND_NUM_BITS + 1);
    limit = llvm::APInt::getNullValue(CAP_BOUND_NUM_BITS + 1);

    base.insertBits(bottom, exponent);
    limit.insertBits(top, exponent);

    llvm::APInt a(CAP_BOUND_NUM_BITS + 1, GetAddress(value));
    llvm::APInt A3 = a.extractBits(3, exponent + CAP_MW - 3);
    llvm::APInt B3 = bottom.extractBits(3, CAP_MW - 3);
    llvm::APInt T3 = top.extractBits(3, CAP_MW - 3);
    llvm::APInt R3 = B3 - 1;

    LLDB_LOGF(log, "[DecodeCapabilityAddressRange] A3 = %" PRIx64,
              A3.getZExtValue());
    LLDB_LOGF(log, "[DecodeCapabilityAddressRange] B3 = %" PRIx64,
              B3.getZExtValue());
    LLDB_LOGF(log, "[DecodeCapabilityAddressRange] T3 = %" PRIx64,
              T3.getZExtValue());
    LLDB_LOGF(log, "[DecodeCapabilityAddressRange] R3 = %" PRIx64,
              R3.getZExtValue());

    assert(A3.getBitWidth() == 3 && "Wrong number of bits");
    assert(B3.getBitWidth() == 3 && "Wrong number of bits");
    assert(T3.getBitWidth() == 3 && "Wrong number of bits");
    assert(R3.getBitWidth() == 3 && "Wrong number of bits");
    assert((R3 < B3 || (B3 == 0 && R3 == 7)) && "Invalid R3");

    int aHi = A3.ult(R3) ? 1 : 0;
    int bHi = B3.ult(R3) ? 1 : 0;
    int tHi = T3.ult(R3) ? 1 : 0;

    int correction_base = bHi - aHi;
    int correction_limit = tHi - aHi;

    LLDB_LOGF(log, "[DecodeCapabilityAddressRange] aHi = %" PRId32, aHi);
    LLDB_LOGF(log, "[DecodeCapabilityAddressRange] correction_base = %" PRId32,
              correction_base);
    LLDB_LOGF(log, "[DecodeCapabilityAddressRange] correction_limit = %" PRId32,
              correction_limit);

    if (exponent < CAP_MAX_EXPONENT) {
      llvm::APInt atop = a.extractBits(
          CAP_BOUND_NUM_BITS - CAP_MW - exponent + 1, CAP_MW + exponent);
      LLDB_LOGF(log, "[DecodeCapabilityAddressRange] atop<63:0> = %" PRIx64,
                atop.getZExtValue());
      assert(atop.getBitWidth() + CAP_MW + exponent == CAP_BOUND_NUM_BITS + 1 &&
             "Wrong width");
      base.insertBits(atop + correction_base, CAP_MW + exponent);
      limit.insertBits(atop + correction_limit, CAP_MW + exponent);
    }

    base.clearBit(64);
    int NumBits = 2;
    if (exponent < (CAP_MAX_EXPONENT - 1) &&
        (limit.extractBits(NumBits, 63) - base.extractBits(NumBits, 63))
            .ugt(1)) {
      LLDB_LOGF(log,
                "[DecodeCapabilityAddressRange] Performing final correction");
      limit.flipBit(64);
    }

    limit = limit.trunc(CAP_BOUND_NUM_BITS);
    base = base.trunc(CAP_BOUND_NUM_BITS);

    assert(limit.getBitWidth() == CAP_BOUND_NUM_BITS &&
           "Invalid width for limit");
    assert(base.getBitWidth() == CAP_BOUND_NUM_BITS &&
           "Invalid width for base");
    assert(base.isSignBitClear() && "Top bit of base should be 0");
  }

private:
  static constexpr int CAP_VALUE_NUM_BITS = 64;
  static constexpr int CAP_MW = 16;
  static constexpr int CAP_IE_BIT = 94;
  static constexpr int CAP_MAX_EXPONENT = CAP_VALUE_NUM_BITS - CAP_MW + 2;
  static constexpr int CAP_BASE_HI_BIT = 79;
  static constexpr int CAP_BASE_MANTISSA_LO_BIT = 67;
  static constexpr int CAP_BASE_EXP_HI_BIT = 66;
  static constexpr int CAP_BASE_LO_BIT = 64;
  static constexpr int CAP_LIMIT_HI_BIT = 93;
  static constexpr int CAP_LIMIT_MANTISSA_LO_BIT = 83;
  static constexpr int CAP_LIMIT_EXP_HI_BIT = 82;
  static constexpr int CAP_LIMIT_LO_BIT = 80;
  static constexpr int CAP_BOUND_NUM_BITS = 65;
  static constexpr int CAP_OTYPE_HI_BIT = 109;
  static constexpr int CAP_OTYPE_LO_BIT = 95;
  static constexpr int CAP_OTYPE_NUM_BITS =
      CAP_OTYPE_HI_BIT - CAP_OTYPE_LO_BIT + 1;
  static constexpr int CAP_PERMS_HI_BIT = 127;
  static constexpr int CAP_PERMS_LO_BIT = 110;
  static constexpr int CAP_PERMS_NUM_BITS =
      CAP_PERMS_HI_BIT - CAP_PERMS_LO_BIT + 1;
  static constexpr int CAP_OTYPE_SENTRY = 1; // Sentry object type

  static int CapGetEffectiveExponent(const llvm::APInt &value) {
    // Early return - if we don't have an internal exponent there's nothing to
    // interpret.
    if (!CapIsInternalExponent(value))
      return 0;

    Log *log = GetLog(LLDBLog::DataFormatters);

    // Read exponent - this code is inlined from CapGetExponent.
    int NumExpBitsLimit = CAP_LIMIT_EXP_HI_BIT - CAP_LIMIT_LO_BIT + 1;
    llvm::APInt nexpLimit =
        value.extractBits(NumExpBitsLimit, CAP_LIMIT_LO_BIT);
    int NumExpBitsBase = CAP_BASE_EXP_HI_BIT - CAP_BASE_LO_BIT + 1;
    llvm::APInt nexpBase = value.extractBits(NumExpBitsBase, CAP_BASE_LO_BIT);

    LLDB_LOGF(log, "[CapGetEffectiveExponent] nexpBase = 0x%" PRIx64,
              nexpBase.getZExtValue());
    LLDB_LOGF(log, "[CapGetEffectiveExponent] nexpLimit = 0x%" PRIx64,
              nexpLimit.getZExtValue());

    llvm::APInt exp =
        llvm::APInt::getNullValue(NumExpBitsBase + NumExpBitsLimit);
    exp.insertBits(nexpLimit, NumExpBitsBase);
    exp.insertBits(nexpBase, 0);
    LLDB_LOGF(log, "[CapGetEffectiveExponent] negated exponent = 0x%" PRIx64,
              exp.getZExtValue());
    exp.flipAllBits();
    LLDB_LOGF(log, "[CapGetEffectiveExponent] exponent = 0x%" PRIx64,
              exp.getZExtValue());

    // Clamp exponent.
    if (exp.uge(CAP_MAX_EXPONENT))
      return CAP_MAX_EXPONENT;
    return exp.getZExtValue();
  }

  static bool CapIsInternalExponent(const llvm::APInt &value) {
    return value[CAP_IE_BIT] == false;
  }

  static llvm::APInt CapGetBottom(const llvm::APInt &value) {
    llvm::APInt b;
    if (CapIsInternalExponent(value)) {
      b = value.extractBits(CAP_BASE_HI_BIT - CAP_BASE_LO_BIT + 1,
                            CAP_BASE_LO_BIT);
      b.clearLowBits(CAP_BASE_MANTISSA_LO_BIT - CAP_BASE_LO_BIT);
    } else {
      b = value.extractBits(CAP_BASE_HI_BIT - CAP_BASE_LO_BIT + 1,
                            CAP_BASE_LO_BIT);
    }
    assert(b.getBitWidth() == CAP_MW && "Wrong number of bits for b");
    return b;
  }

  static llvm::APInt CapGetTop(const llvm::APInt &value) {
    Log *log = GetLog(LLDBLog::DataFormatters);

    llvm::APInt b = CapGetBottom(value);
    llvm::APInt t;
    int lmsb = 0;
    if (CapIsInternalExponent(value)) {
      lmsb = 1;
      t = value.extractBits(CAP_LIMIT_HI_BIT - CAP_LIMIT_LO_BIT + 1,
                            CAP_LIMIT_LO_BIT);
      t.clearLowBits(CAP_LIMIT_MANTISSA_LO_BIT - CAP_LIMIT_LO_BIT);
    } else {
      t = value.extractBits(CAP_LIMIT_HI_BIT - CAP_LIMIT_LO_BIT + 1,
                            CAP_LIMIT_LO_BIT);
    }
    assert(t.getBitWidth() == CAP_MW - 3 + 1 && "Wrong number of bits for t");

    t = t.zext(CAP_MW);

    LLDB_LOGF(log, "[CapGetTop] b = %" PRIx64, b.getZExtValue());

    uint64_t bLow = b.extractBits(CAP_MW - 3 + 1, 0).getZExtValue();
    uint64_t tLow = t.getZExtValue();
    int lcarry = tLow < bLow ? 1 : 0;
    llvm::APInt tHi = b.extractBits(2, CAP_MW - 2) + lcarry + lmsb;

    assert(tHi.getBitWidth() == 2 && "Too many top bits");
    t.insertBits(tHi, CAP_MW - 2);

    LLDB_LOGF(log, "[CapGetTop] lmsb = %" PRId32, lmsb);
    LLDB_LOGF(log, "[CapGetTop] lcarry = %" PRId32, lcarry);
    LLDB_LOGF(log, "[CapGetTop] t = %" PRIx64, t.getZExtValue());

    assert(t.getBitWidth() == CAP_MW && "Wrong number of bits for t");
    return t;
  }
};

bool GetCFARegisterValue(const llvm::APInt &value, bool has_tag,
                         const RegisterInfo &reg_info, int64_t offset,
                         RegisterValue &reg_value, Status &error) {
  // Be strict and allow to obtain CFA only from a properly tagged capability.
  if (!has_tag) {
    error.SetErrorString(
        "a CFA register value cannot be obtained from an untagged capability");
    return false;
  }

  // Calculate a capability value adjusted by the offset and set the resulting
  // register value. Only two register types are sensible for a capability CFA:
  // * 64-bit Xn/SP -- stores the lowest 64-bit part of the CFA,
  // * Tagged 128-bit Cn/CSP -- holds the complete capability CFA value.
  llvm::APInt adjusted_value = Add(value, offset);
  if (reg_info.encoding == eEncodingUint && reg_info.byte_size == 8)
    reg_value.SetUInt64((adjusted_value & 0xffffffffffffffff).getZExtValue());
  else if (reg_info.encoding == eEncodingCapability && reg_info.byte_size == 17)
    reg_value.SetCapability128(adjusted_value);
  else {
    error.SetErrorStringWithFormat(
        "register value for %s cannot be constructed from a capability CFA",
        reg_info.name);
    return false;
  }
  return true;
}

std::string FormatPermissions(uint64_t perms,
                              llvm::ArrayRef<PermNamePair> perm_names,
                              llvm::StringRef separator) {
  std::string perms_str;

  for (const PermNamePair &p : perm_names)
    if (perms & p.mask) {
      if (!perms_str.empty())
        perms_str += separator;
      perms_str += p.name;
    }

  return perms_str;
}

std::string FormatAsLowercaseHex(const llvm::APInt &bound) {
  llvm::SmallString<32> formatted;
  bound.toString(formatted, 16, /*Signed=*/false, /*formatAsCLiteral=*/true);
  return llvm::StringRef(formatted).lower();
}

// Dump capability as:
// {tag = <tag>, address = <address>, attributes = {[<attrs>], otype = <otype>,
// range = [<base>-<top>)}
template <typename CapabilityEncoding>
void DumpLLDBVerbose(Stream &s, const llvm::APInt &value, bool has_tag) {
  // Decode capability.
  bool is_sealed = CapabilityEncoding::IsCapabilitySealed(value);
  bool is_valid = IsCapabilityValid(value);
  uint64_t perms = CapabilityEncoding::DecodePermissions(value);
  uint64_t address = GetAddress(value);
  uint64_t otype = CapabilityEncoding::DecodeCapabilityOType(value);

  llvm::APInt base, top;
  CapabilityEncoding::DecodeCapabilityAddressRange(value, base, top);

  std::string perms_str = FormatPermissions(
      perms,
      CapabilityEncoding::GetPermissionNamesLLDBVerbose(),
      " ");

  // Get a string representing the sealed flag and permissions.
  std::string attrs;
  if (is_sealed)
    attrs += "Sealed";

  if (!attrs.empty() && !perms_str.empty())
    attrs += " ";
  attrs += perms_str;

  // Output the capability.
  s.PutCString("{");
  if (has_tag)
    s.Printf("tag = %d, ", is_valid);
  s.Printf("address = 0x%016" PRIx64 ", ", address);
  s.Printf("attributes = {[%s]", attrs.c_str());

  if (is_sealed) {
    s.Printf(", otype = 0x%" PRIx64, otype);
  }

  s.Printf(", range = [%s-%s)}}", FormatAsLowercaseHex(base).c_str(),
           FormatAsLowercaseHex(top).c_str());
}

// Dump capability as:
// <address> [<permissions>,<base>-<top>] (<attr>)
// or, if it is null-derived, just as:
// <address>
template <typename CapabilityEncoding>
void DumpCHERISimplified(Stream &s, const llvm::APInt &value, bool has_tag) {
  uint64_t address = GetAddress(value);

  // Check if the capability is null-derived (i.e. contains only the address).
  if (value.isIntN(64)) {
    s.Printf("0x%016" PRIx64, address);
    return;
  }

  // Print address, permissions and range.
  uint64_t perms = CapabilityEncoding::DecodePermissions(value);

  llvm::APInt base, top;
  CapabilityEncoding::DecodeCapabilityAddressRange(value, base, top);

  std::string perms_str = FormatPermissions(
      perms,
      CapabilityEncoding::GetPermissionNamesCHERISimplified(),
      "");

  s.Printf("0x%016" PRIx64 " [%s,%s-%s]", address, perms_str.c_str(),
           FormatAsLowercaseHex(base).c_str(),
           FormatAsLowercaseHex(top).c_str());

  // Print attributes.
  bool is_sealed = CapabilityEncoding::IsCapabilitySealed(value);
  bool is_sentry = CapabilityEncoding::IsCapabilitySentry(value);
  bool is_valid = IsCapabilityValid(value);

  std::string attrs;
  if (has_tag && !is_valid)
    attrs += "invalid";

  if (is_sealed) {
    std::string seal_kind{is_sentry ? "sentry" : "sealed"};

    if (!attrs.empty())
      attrs += ",";

    attrs += seal_kind;
  }

  if (!attrs.empty())
    s.Printf(" (%s)", attrs.c_str());
}
} // namespace AArch64_128

uint32_t Capability::GetBaseByteSize(lldb::CapabilityType type) {
  switch (type) {
  case eCapabilityInvalid:
    break;
  case eCapabilityMorello_128:
  case eCapabilityMorello_128_untagged:
    return 16;
  }
  return 0;
}

Capability::Capability(CapabilityType type, const llvm::APInt &value)
    : m_type(type), m_value(value) {
  // Check that the value is sensible.
  switch (m_type) {
  case eCapabilityInvalid:
    break;
  case eCapabilityMorello_128:
    assert(m_value.getBitWidth() == 129);
    break;
  case eCapabilityMorello_128_untagged:
    assert(m_value.getBitWidth() == 128);
    break;
  }
}

addr_t Capability::GetAddress(addr_t fail_value, bool *success_ptr) const {
  switch (m_type) {
  case eCapabilityInvalid:
    break;
  case eCapabilityMorello_128:
  case eCapabilityMorello_128_untagged:
    if (success_ptr != nullptr)
      *success_ptr = true;
    return AArch64_128::GetAddress(m_value);
  }
  if (success_ptr != nullptr)
    *success_ptr = false;
  return fail_value;
}

bool Capability::GetCFARegisterValue(const RegisterInfo &reg_info,
                                     int64_t offset, RegisterValue &reg_value,
                                     Status &error) const {
  switch (m_type) {
  case eCapabilityInvalid:
    break;
  case eCapabilityMorello_128:
  case eCapabilityMorello_128_untagged:
    return AArch64_128::GetCFARegisterValue(m_value, /*has_tag=*/m_type ==
                                                         eCapabilityMorello_128,
                                            reg_info, offset, reg_value, error);
  }
  error.SetErrorString("invalid CFA capability");
  return false;
}

Capability Capability::operator+(int64_t offset) const {
  Capability result = *this;
  switch (m_type) {
  case eCapabilityInvalid:
    // Input is invalid, return the same invalid capability on the output.
    break;
  case eCapabilityMorello_128:
  case eCapabilityMorello_128_untagged:
    result.m_value = AArch64_128::Add(m_value, offset);
    break;
  }
  return result;
}

void Capability::Dump(Stream &s, lldb::CapabilityFormat format) const {
  switch (m_type) {
  case eCapabilityInvalid:
    s.PutCString("invalid capability");
    break;
  case eCapabilityMorello_128:
  case eCapabilityMorello_128_untagged:
    switch (format) {
    case eCapabilityFormatLLDBVerbose:
      AArch64_128::DumpLLDBVerbose<AArch64_128::MorelloCapabilityEncoding>(
          s, m_value, /*has_tag=*/m_type == eCapabilityMorello_128);
      break;
    case eCapabilityFormatCHERISimplified:
      AArch64_128::DumpCHERISimplified<AArch64_128::MorelloCapabilityEncoding>(
          s, m_value, /*has_tag=*/m_type == eCapabilityMorello_128);
      break;
    }
  }
}

bool Capability::operator==(const Capability &other) const {
  return m_type == other.m_type && m_value == other.m_value;
}

void llvm::format_provider<Capability>::format(const Capability &capability,
                                               raw_ostream &Stream,
                                               StringRef Style) {
  SmallString<64> str_value;
  capability.GetValue().toString(str_value, 16, /*Signed=*/false,
                                 /*formatAsCLiteral=*/true);
  Stream << "capability(" << StringRef(str_value).lower() << ")";
}
