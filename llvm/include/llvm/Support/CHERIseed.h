//===- CHERIseed.h --------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements utilities for CHERIseed, which are used by both the
// module pass and the runtime library.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_SUPPORT_CHERISEED_H
#define LLVM_SUPPORT_CHERISEED_H

namespace llvm {
namespace __cheriseed {
namespace abi {

using CheckType = unsigned long;

// These permissions bits are used as the arguments for the function
// __cheriseed_check_access as a platform independent representation.
enum Permissions : CheckType {
  EXECUTE = (1 << 1),
  LOAD = (1 << 2),
  STORE = (1 << 3),
  LOAD_CAP = (1 << 4),
  STORE_CAP = (1 << 5),
  // Useful values
  LAST = STORE_CAP,
  MASK = (LAST << 1) - 1,
}; // enum Permissions

enum Check : CheckType {
  // Important: bits [31:0] are reserved for permissions.
  CHK_PERMS = Permissions::MASK,
  // Bit of checks mask representing tag
  CHK_TAG = (1UL << 61),
  // Bit of checks mask representing bounds
  CHK_BOUNDS = (1UL << 62),
  // Bit of checks mask representing alignment
  CHK_ALIGNMENT = (1UL << 63),
  // All checks
  CHK_ALL = CHK_ALIGNMENT | CHK_BOUNDS | CHK_TAG | CHK_PERMS,
}; // enum Check

static_assert(static_cast<CheckType>(Check::CHK_PERMS) < (1UL << 32),
              "LLVM permissions are out-of-range.");

// Representation of a configurable option.
struct AvailableCheckOption final {
  constexpr AvailableCheckOption(const char *const name, unsigned long length,
                                 abi::CheckType value)
      : name(name), length(length), value(value) {}

  const char *const name;
  unsigned long length;
  abi::CheckType value;
}; // struct AvailableCheckOption

// All available configurable options.
static constexpr AvailableCheckOption AvailableCheckOptions[] = {
    {"ALL", sizeof("ALL") - 1, Check::CHK_ALL},
    {"TAG", sizeof("TAG") - 1, Check::CHK_TAG},
    {"BOUNDS", sizeof("BOUNDS") - 1, Check::CHK_BOUNDS},
    {"PERMS", sizeof("PERMS") - 1, Check::CHK_PERMS},
    {"ALIGNMENT", sizeof("ALIGNMENT") - 1, Check::CHK_ALIGNMENT},
    {"LOAD", sizeof("LOAD") - 1, Permissions::LOAD},
    {"STORE", sizeof("STORE") - 1, Permissions::STORE},
    {"LOAD_CAP", sizeof("LOAD_CAP") - 1, Permissions::LOAD_CAP},
    {"STORE_CAP", sizeof("STORE_CAP") - 1, Permissions::STORE_CAP},
    {"EXECUTE", sizeof("EXECUTE") - 1, Permissions::EXECUTE},
};

} // namespace abi

// Utility to parse check strings.
namespace parser {

// String operations required for the parser.
struct StringOperations final {
  char *(*strchrnul)(const char *s, int c);
  int (*strncmp)(const char *s1, const char *s2, unsigned long n);
}; // struct StringOperations

// Results returned by the parser.
enum class ParseResult {
  VALID_OPTION,
  ZERO_LENGTH_OPTION,
  UNKNOWN_OPTION,
}; // enum class ParseResult

// A parsed option returned by Parse().
struct ParsedOption final {

  ParsedOption() : result(ParseResult::UNKNOWN_OPTION), data("") {}

  ParsedOption(enum ParseResult result, const char *data)
      : ParsedOption(result, data, 0) {}

  ParsedOption(const char *data, abi::CheckType check)
      : result(ParseResult::VALID_OPTION), data(data), check(check) {}

  ParsedOption(enum ParseResult result, const char *data, abi::CheckType check)
      : result(result), data(data), check(check) {}

  enum ParseResult Result() const { return result; }
  const char *Data() const { return data; }
  bool Enabled() const { return data[0] != '-'; }
  abi::CheckType GetCheck() const { return check; }

private:
  enum ParseResult result;
  const char *data;
  abi::CheckType check;
}; // struct ParsedOption

// Process the comma separated list of options.
__attribute__((used)) static const char *Parse(const char *str,
                                               const StringOperations &ops,
                                               ParsedOption &parsed_option) {
  const char *const data = str;

  // Skip the '-' character.
  if ('-' == *str) {
    ++str;
  }

  // Find the position of the next delimiter character.
  const char *delimiter = ops.strchrnul(str, ',');
  // Calculate the length of this option.
  const unsigned long option_length =
      static_cast<unsigned long>(delimiter - str);
  // Don't process zero-length options.
  if (0 == option_length) {
    parsed_option = ParsedOption(ParseResult::ZERO_LENGTH_OPTION, data);
    return nullptr;
  }
  // Grab the current option.
  const char *const option = str;
  // Advance pointer: if there is a delimiter, skip the delimiter itself.
  str = *delimiter ? ++delimiter : delimiter;

  for (unsigned long index = 0; index < (sizeof(abi::AvailableCheckOptions) /
                                         sizeof(abi::AvailableCheckOptions[0]));
       ++index) {
    auto &candidate_option = abi::AvailableCheckOptions[index];
    // Check if the currently processed option matches a candidate option.
    if (0 !=
        ops.strncmp(candidate_option.name, option, candidate_option.length))
      continue;
    // There is a match, however, it has to be checked that the next character
    // is a delimiter or a terminating '\0'.
    if ((option[candidate_option.length] != '\0') &&
        (option[candidate_option.length] != ','))
      continue;
    // There is an exact match.
    parsed_option = ParsedOption(data, candidate_option.value);
    return str;
  }

  // Unfortunately, the current option is not recognized.
  parsed_option = ParsedOption(ParseResult::UNKNOWN_OPTION, data);
  return nullptr;
}

} // namespace parser
} // namespace __cheriseed
} // namespace llvm

#endif // LLVM_SUPPORT_CHERISEED_H
