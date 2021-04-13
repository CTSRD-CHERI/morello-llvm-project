//===-- main.cpp ------------------------------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include <cstdint>

typedef __uint128_t Capability128b;

#define CAP128(name, attributes, address)                                      \
  Capability128b name;                                                         \
  name = UINT64_C(attributes);                                                 \
  name <<= 64;                                                                 \
  name |= UINT64_C(address);

int main() {
  // Permissions tests.
  CAP128(permissions_load,          0x8000000040000000, 0x0000000000000000);
  CAP128(permissions_store,         0x4000000040000000, 0x0000000000000000);
  CAP128(permissions_execute,       0x2000000040000000, 0x0000000000000000);
  CAP128(permissions_loadcap,       0x1000000040000000, 0x0000000000000000);
  CAP128(permissions_storecap,      0x0800000040000000, 0x0000000000000000);
  CAP128(permissions_storelocalcap, 0x0400000040000000, 0x0000000000000000);
  CAP128(permissions_seal,          0x0200000040000000, 0x0000000000000000);
  CAP128(permissions_unseal,        0x0100000040000000, 0x0000000000000000);
  CAP128(permissions_system,        0x0080000040000000, 0x0000000000000000);
  CAP128(permissions_branchunseal,  0x0040000040000000, 0x0000000000000000);
  CAP128(permissions_compartmentid, 0x0020000040000000, 0x0000000000000000);
  CAP128(permissions_mutableload,   0x0010000040000000, 0x0000000000000000);
  CAP128(permissions_user3,         0x0008000040000000, 0x0000000000000000);
  CAP128(permissions_user2,         0x0004000040000000, 0x0000000000000000);
  CAP128(permissions_user1,         0x0002000040000000, 0x0000000000000000);
  CAP128(permissions_user0,         0x0001000040000000, 0x0000000000000000);
  CAP128(permissions_executive,     0x0000800040000000, 0x0000000000000000);
  CAP128(permissions_global,        0x0000400040000000, 0x0000000000000000);

  CAP128(permissions_none,          0x0000000040000000, 0x0000000000000000);
  CAP128(permissions_several,       0xa53f400040000000, 0x0000000000000000);

  // Object type tests.
  CAP128(sealed_max_otype,          0xc0007fffc0000000, 0x0000000000000000);
  CAP128(sealed_no_perms,           0x00003bee40000000, 0x0000000000000000);
  CAP128(sealed_all_perms,          0xffffc05040000000, 0x0000000000000000);

  // Address tests.
  CAP128(address_zero_flags,        0x0000000040000000, 0x00deadbeef000000);
  CAP128(address_nonzero_flags,     0x0000000040000000, 0x9d0000ffff00aaaa);

  // Bounds tests.
  // A. No internal exponent
  CAP128(bounds_noie_zero,          0x0000000040000000, 0x0000000000000000);

  // A.1. CapGetTop (and Bottom)
  //   Test that we reconstruct the top correctly, with or without the carry.
  //   These tests try really hard to exercise the CapGetBounds pseudocode path
  //   where the corrections for the base and top are both 0, but that is
  //   impossible for 'bounds_noie_carry_wrap' because in that case we want to
  //   test B3 = 11x => T3 = 00x and R3 = 110 or 101 => bHi = 0 and tHi = 1, so
  //   we're forced to correct one of them (in this case, the bottom).
  CAP128(bounds_noie_nocarry_gt,     0x000000007a54ba52, 0x000000000000c000);
  CAP128(bounds_noie_nocarry_eq,     0x0000000052841284, 0x0000000000000000);
  CAP128(bounds_noie_carry,          0x0000000046344638, 0x0000000000005000);
  CAP128(bounds_noie_carry_wrap,     0x000000006114e228, 0x0000000000000000);

  // A.2. CapGetBounds corrections
  //   Test that we perform the right corrections (1, 0 or -1) for both the
  //   bottom and the limit.
  CAP128(bounds_noie_c1,             0x0000000040040002, 0x00000000beefe000);
  CAP128(bounds_noie_c0,             0x0000000040040002, 0x00000000beef0000);
  CAP128(bounds_noie_c_1,            0x0000000040046002, 0x00000000beef2000);

  //   Test that we perform the right corrections even when that involves
  //   wrapping, either up or down. When wrapping down we also perform the final
  //   correction.
  CAP128(bounds_noie_c1_wrap,        0x0000000040040002, 0xffffffffffffe000);
  CAP128(bounds_noie_c_1_wrap,       0x0000000040046002, 0x0000000000000000);

  //   Test that we can perform the corrections individually as well. Note that
  //   bHi = 1 => correction_bottom == correction_top. So if we want to test
  //   only one correction at a time, we need testcases with bHi = 0, which
  //   means correction_bottom can only be 0 or -1 (never 1). Similarly,
  //   correction_top can only be 0 or 1 (never -1, since for that we'd need
  //   aHi = 1, which would make correction_bottom = -1 as well). The final
  //   correction can never be tested independently, since if correction_bottom
  //   and correction_top are both 0, then the top bits of base and limit are
  //   equal so there's nothing to correct.
  CAP128(bounds_noie_cb_1,           0x000000004004c00a, 0x00000000beef2000);
  CAP128(bounds_noie_ct1,            0x000000004004c00b, 0x00000000beefc000);

  // B. Internal exponent
  //   We want to go through all the scenarios above, but with various values
  //   for the exponent: zero, some intermediate value, >= 50. When testing the
  //   final correction we should also consider exponents 48 and 49.
  CAP128(bounds_ie_zero,             0x0000000000070007, 0x0000000000000000);
  CAP128(bounds_ie_mid,              0x0000000000050004, 0x0000000000000000);
  CAP128(bounds_ie_ge50,             0x0000000000000000, 0x0000000000000000);

  // B.1. CapGetTop (and Bottom)
  CAP128(bounds_ie_zero_nocarry_gt,  0x000000003a5fba57, 0x000000000000c000);
  CAP128(bounds_ie_mid_nocarry_gt,   0x000000003a5fba52, 0x0000000000180000);
  CAP128(bounds_ie_ge50_nocarry_gt,  0x000000003a593a53, 0x0000000000000000);

  CAP128(bounds_ie_zero_nocarry_eq,  0x0000000012871287, 0x0000000000000000);
  CAP128(bounds_ie_mid_nocarry_eq,   0x0000000012821285, 0x0000000000000000);
  CAP128(bounds_ie_ge50_nocarry_eq,  0x0000000012811285, 0x0000000000000000);

  CAP128(bounds_ie_zero_carry,       0x000000000637463f, 0x0000000000005000);
  CAP128(bounds_ie_mid_carry,        0x000000000634463f, 0x0000050000000000);
  CAP128(bounds_ie_ge50_carry,       0x0000000006304637, 0x0000000000000000);

  CAP128(bounds_ie_zero_carry_wrap,  0x000000002117a227, 0x0000000000000000);
  CAP128(bounds_ie_mid_carry_wrap,   0x000000002117a223, 0x0000000000000000);
  CAP128(bounds_ie_ge50_carry_wrap,  0x000000002111a223, 0x0000000000000000);

  // B.2 CapGetBounds corrections
  //   We don't do any corrections if the exponent is >= 50. The tests above
  //   should also cover enough variety in the exponent that we can use
  //   something simple here.
  CAP128(bounds_ie_c1,               0x0000000000060007, 0x000000beefe00000);
  CAP128(bounds_ie_c0,               0x0000000000060007, 0x000000beef000000);
  CAP128(bounds_ie_c_1,              0x0000000000066007, 0x000000beef200000);

  CAP128(bounds_ie_c1_wrap,          0x0000000000060007, 0xffffffffffe00000);
  CAP128(bounds_ie_c_1_wrap,         0x0000000000066007, 0x0000000000000000);

  CAP128(bounds_ie_cb_1,             0x000000000006c007, 0x000000beef200000);
  CAP128(bounds_ie_ct1,              0x000000000006c007, 0x000000beefc00000);

  //   A couple of extra tests to make sure we perform the final correction for
  //   exponents up to 48, but not for 49 and 50 (and the other corrections up
  //   to 49 inclusive).
  CAP128(bounds_ie_48_fc,            0x000000000001c007, 0x0000000000000000);
  CAP128(bounds_ie_49_fc,            0x000000000001c006, 0x0000000000000000);
  CAP128(bounds_ie_50_fc,            0x000000000001c005, 0x0000000000000000);

  // "Interference" tests. We've been using lots of zeros in the previous
  // testcases - try the opposite now. These tests should hopefully catch
  // blatant off-by-ones where we accidentally look at neighbouring bits when
  // interpreting the various fields.
  CAP128(all_ones,                   0xffffffffffffffff, 0xffffffffffffffff);
  CAP128(no_perms,                   0x00003fffffffffff, 0xffffffffffffffff);
  CAP128(no_otype,                   0xffffc0007fffffff, 0xffffffffffffffff);
  CAP128(no_address,                 0xffffffffffffffff, 0x0000000000000000);
  CAP128(no_bottom,                  0xffffffffffff0000, 0xffffffffffffffff);
  CAP128(no_top,                     0xffffffffc000ffff, 0xffffffffffffffff);

  return 0; // break here
}
