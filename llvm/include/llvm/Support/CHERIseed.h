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
  CHK_TAG = (1UL << 32),
  // Bit of checks mask representing bounds
  CHK_BOUNDS = (1UL << 33),
  // Bit of checks mask representing alignment
  CHK_ALIGNMENT = (1UL << 34),
  // All checks
  CHK_ALL = CHK_ALIGNMENT | CHK_BOUNDS | CHK_TAG | CHK_PERMS,
}; // enum Check

static_assert(static_cast<CheckType>(Check::CHK_PERMS) < (1UL << 32),
              "LLVM permissions are out-of-range.");

// These flags helps selecting options while iterating.
enum CheckOptionFlags : int {
  // Options which are being used
  IN_USE_OPTION = (1 << 1),
  // Not used selectively for compile-time
  NO_COMPILE_TIME_OPTION = (1 << 2),
  // Help option
  HELP_OPTION = (1 << 3),
};

// Representation of a configurable option.
struct AvailableCheckOption final {
  constexpr AvailableCheckOption(const char *const name, unsigned long length,
                                 abi::CheckType value,
                                 const char *const description, int flags)
      : name(name), length(length), value(value), description(description),
        flags(flags) {}

  const char *const name;
  unsigned long length;
  abi::CheckType value;
  const char *const description;
  int flags;
}; // struct AvailableCheckOption

// clang-format off
#define INSERT_OPTION(__name, __value, __desc, __flags) { #__name, sizeof(#__name) - 1, __value, #__desc, __flags }

// All available configurable options.
static constexpr AvailableCheckOption AvailableCheckOptions[] = {
  INSERT_OPTION(ALL,       Check::CHK_ALL,         Enable all checks,                      CheckOptionFlags::IN_USE_OPTION),
  INSERT_OPTION(TAG,       Check::CHK_TAG,         Enable tag checks,                      CheckOptionFlags::IN_USE_OPTION),
  INSERT_OPTION(BOUNDS,    Check::CHK_BOUNDS,      Enable bounds checks,                   CheckOptionFlags::IN_USE_OPTION),
  INSERT_OPTION(PERMS,     Check::CHK_PERMS,       Enable permission checks,               CheckOptionFlags::IN_USE_OPTION),
  INSERT_OPTION(ALIGNMENT, Check::CHK_ALIGNMENT,   Enable alignment checks,                CheckOptionFlags::IN_USE_OPTION | CheckOptionFlags::NO_COMPILE_TIME_OPTION),
  INSERT_OPTION(LOAD,      Permissions::LOAD,      Enable checks for LOAD permission,      CheckOptionFlags::IN_USE_OPTION),
  INSERT_OPTION(STORE,     Permissions::STORE,     Enable checks for STORE permission,     CheckOptionFlags::IN_USE_OPTION),
  INSERT_OPTION(LOAD_CAP,  Permissions::LOAD_CAP,  Enable checks for LOAD_CAP permission,  CheckOptionFlags::IN_USE_OPTION),
  INSERT_OPTION(STORE_CAP, Permissions::STORE_CAP, Enable checks for STORE_CAP permission, CheckOptionFlags::IN_USE_OPTION),
  INSERT_OPTION(EXECUTE,   Permissions::EXECUTE,   Enable checks for EXECUTE permission,   CheckOptionFlags::IN_USE_OPTION),
  INSERT_OPTION(HELP,      0,                      Displays this help message and exits,   CheckOptionFlags::HELP_OPTION),
  INSERT_OPTION(help,      0,                      Same as (HELP),                         CheckOptionFlags::HELP_OPTION),
};

#undef INSERT_OPTION
// clang-format on

} // namespace abi

// Utility to parse check strings.
namespace parser {

// String operations required for the parser.
struct StringOperations final {
#ifdef __CORRECT_ISO_CPP_STRING_H_PROTO
  const char *(*strchrnul)(const char *s, int c);
#else
  char *(*strchrnul)(const char *s, int c);
#endif
  int (*strncmp)(const char *s1, const char *s2, unsigned long n);
}; // struct StringOperations

// Results returned by the parser.
enum class ParseResult {
  VALID_OPTION,
  HELP_OPTION,
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

// Calls 'op' for each and every available option if doesn't have excluded
// flags.
template <typename T>
static void ForeachOption(T &&op, const int flags_to_exclude) {
  for (unsigned long index = 0; index < (sizeof(abi::AvailableCheckOptions) /
                                         sizeof(abi::AvailableCheckOptions[0]));
       ++index)
    if (!(llvm::__cheriseed::abi::AvailableCheckOptions[index].flags &
          flags_to_exclude))
      op(llvm::__cheriseed::abi::AvailableCheckOptions[index]);
}

// Prints a help message to 'output'.
template <typename T> static void Help(T &output, const int flags_to_exclude) {
  unsigned long max_option_width = 0;
  ForeachOption(
      [&](const abi::AvailableCheckOption &option) {
        max_option_width =
            max_option_width < option.length ? option.length : max_option_width;
      },
      flags_to_exclude);

  output << " Available options are:\n";
  ForeachOption(
      [&](const abi::AvailableCheckOption &option) {
        output << "  " << option.name;
        for (unsigned long idx = option.length; idx < max_option_width; ++idx)
          output << " ";
        output << "  " << option.description << "\n";
      },
      flags_to_exclude);

  output << "Above options can be prefixed with \'-\' to disable specific "
            "checks."
         << "\n"
         << "All checks are on by default."
         << "\n";
}

// Process the comma separated list of options.
__attribute__((used)) static const char *Parse(const char *str,
                                               const StringOperations &ops,
                                               ParsedOption &parsed_option,
                                               const int flags_to_exclude) {
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

  ForeachOption(
      [&](const abi::AvailableCheckOption &candidate_option) {
        // Check if the currently processed option matches a candidate option.
        if (0 !=
            ops.strncmp(candidate_option.name, option, candidate_option.length))
          return;
        // There is a match, however, it has to be checked that the next
        // character is a delimiter or a terminating '\0'.
        if ((option[candidate_option.length] != '\0') &&
            (option[candidate_option.length] != ','))
          return;
        // There is an exact match.
        if (candidate_option.flags & abi::CheckOptionFlags::HELP_OPTION) {
          parsed_option = ParsedOption(ParseResult::HELP_OPTION, data);
        } else {
          parsed_option = ParsedOption(data, candidate_option.value);
        }
      },
      flags_to_exclude);

  if ((parsed_option.Result() == ParseResult::VALID_OPTION) ||
      (parsed_option.Result() == ParseResult::HELP_OPTION))
    return str;

  // Unfortunately, the current option is not recognized.
  parsed_option = ParsedOption(ParseResult::UNKNOWN_OPTION, data);
  return nullptr;
}

} // namespace parser
} // namespace __cheriseed
} // namespace llvm

#endif // LLVM_SUPPORT_CHERISEED_H
