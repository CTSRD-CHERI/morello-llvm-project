//===-- cheriseed_api.cpp ---------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is a part of the CHERIseed Runtime Library.
//
// Tests of the public API. These test focus on error-free operations only.
//
//===----------------------------------------------------------------------===//

#include <cstdint>
#include <limits>

#include "cheriseed_test_utils.h"

// Only for UINT* types.
using namespace utils;
using namespace __cheriseed::abi;

TEST(AddressGet, Api) {
  uint16_t a;
  __cheriseed_cap_t cap;
  utils::InitCap(&cap, &a);
  ASSERT_EQ(__cheriseed_address_get(&cap), (uint64_t)&a);
  ASSERT_EQ(__cheriseed_address_get(nullptr), (uint64_t)0);
}

TEST(AddressSet, Api) {
  __cheriseed_cap_t cap;

  uint16_t a;
  __cheriseed_cap_t *cap_ptr =
      __cheriseed_address_set(&cap, nullptr, (uint64_t)&a);
  ASSERT_EQ(cap_ptr, &cap);
  ASSERT_CAPABILITY_VALUE_EQ(&cap, &a);

  uint16_t b;
  __cheriseed_address_set(&cap, &cap, (uint64_t)&b);
  ASSERT_CAPABILITY_VALUE_EQ(&cap, &b);
}

TEST(CopyFromHigh, Api) {
  __cheriseed_cap_t cap;
  utils::InitCap(&cap, 42, 43);
  ASSERT_EQ(__cheriseed_copy_from_high(&cap), (uint64_t)43);
}

TEST(CopyToHigh, Api) {
  __cheriseed_cap_t cap;
  utils::InitCap(&cap, 42, 43);
  __cheriseed_copy_to_high(&cap, &cap, UINT64_MAX);
  ASSERT_CAPABILITY_METADATA_EQ(&cap, UINT64_MAX);
  ASSERT_UNTAGGED(&cap);
}

TEST(CopyCapWithOffset, Api) {
  uint32_t array[2] = {42, 64};
  __cheriseed_cap_t cap1, cap2;
  utils::InitCap(&cap1, &array);
  __cheriseed_cap_t *cap2_ptr =
      __cheriseed_copy_cap_with_offset(&cap2, &cap1, sizeof(uint32_t));
  ASSERT_EQ(cap2_ptr, &cap2);
  ASSERT_CAPABILITY_METADATA_EQ(&cap2, &cap1);
  ASSERT_CAPABILITY_VALUE_EQ(&cap2,
                             __cheriseed_address_get(&cap1) + sizeof(uint32_t));
}

TEST(CopyCapWithOffset, CopyNullptr) {
  __cheriseed_cap_t cap;
  __cheriseed_copy_cap_with_offset(&cap, nullptr, 42);
  ASSERT_CAPABILITY_METADATA_EQ(&cap, (uint64_t)0);
  ASSERT_CAPABILITY_VALUE_EQ(&cap, (uint64_t)42);
}

TEST(DDCGet, Address) {
  __cheriseed_cap_t ddc;
  utils::InitCap(&ddc, UINT64_TEST, 0);
  __cheriseed_ddc_get(&ddc);
  ASSERT_CAPABILITY_VALUE_EQ(&ddc, (uint64_t)0);
}

TEST(PCCGet, Address) {
  __cheriseed_cap_t pcc;
  utils::InitCap(&pcc, UINT64_TEST, 0);
  __cheriseed_pcc_get(&pcc);
  ASSERT_CAPABILITY_VALUE_NE(&pcc, 0);
  ASSERT_CAPABILITY_VALUE_NE(&pcc, UINT64_TEST);
}

TEST(DDCGet, Perms) {
  __cheriseed_cap_t ddc;
  utils::InitCap(&ddc, UINT64_TEST, 0);
  __cheriseed_ddc_get(&ddc);
  ASSERT_EQ(__cheriseed_perms_get(&ddc), ccl::permissions::ALL);
}

TEST(PCCGet, Perms) {
  __cheriseed_cap_t pcc;
  utils::InitCap(&pcc, UINT64_TEST, 0);
  __cheriseed_pcc_get(&pcc);
  ASSERT_EQ(__cheriseed_perms_get(&pcc), ccl::permissions::ALL);
}

TEST(DDCGet, Length) {
  __cheriseed_cap_t ddc;
  utils::InitCap(&ddc, UINT64_TEST, 0);
  __cheriseed_ddc_get(&ddc);
  // Max Length is 65 bits, but __cheriseed_length_get returns
  // MIN( UINT64_MAX, length );
  ASSERT_EQ(__cheriseed_length_get(&ddc), UINT64_MAX);
}

TEST(PCCGet, Length) {
  __cheriseed_cap_t pcc;
  utils::InitCap(&pcc, UINT64_TEST, 0);
  __cheriseed_pcc_get(&pcc);
  // Max Length is 65 bits, but __cheriseed_length_get returns
  // MIN( UINT64_MAX, length );
  ASSERT_EQ(__cheriseed_length_get(&pcc), UINT64_MAX);
}

TEST(DDCGet, Base) {
  __cheriseed_cap_t ddc;
  utils::InitCap(&ddc, UINT64_TEST, 0);
  __cheriseed_ddc_get(&ddc);
  ASSERT_EQ(__cheriseed_base_get(&ddc), 0u);
}

TEST(PCCGet, Base) {
  __cheriseed_cap_t pcc;
  utils::InitCap(&pcc, UINT64_TEST, 0);
  __cheriseed_pcc_get(&pcc);
  ASSERT_EQ(__cheriseed_base_get(&pcc), 0u);
}

TEST(StackCapInit, Api) {
  uint16_t a;
  __cheriseed_cap_t cap;
  __cheriseed_stack_cap_init(&cap, reinterpret_cast<uint64_t>(&a), sizeof(a));
  ASSERT_CAPABILITY_VALUE_EQ(&cap, &a);
  ASSERT_EQ(__cheriseed_perms_get(&cap),
            ccl::permissions::ALL & ~ccl::permissions::EXECUTE);
  ASSERT_EQ(__cheriseed_length_get(&cap), sizeof(a));
  ASSERT_EQ(__cheriseed_base_get(&cap), reinterpret_cast<uint64_t>(&a));
}

TEST(CmpxchgCap, SameAsExpected) {
  uint8_t a, b;
  __cheriseed_cap_t cap_to_cap, cap, exp, des, temp;

  utils::InitCap(&cap, &a);
  utils::InitCap(&exp, &a);
  utils::InitCap(&des, &b);
  utils::InitCap(&cap_to_cap, &cap);

  uint64_t cap_high = __cheriseed_copy_from_high(&cap);

  __cheriseed_cmpxchg_result_t res =
      __cheriseed_cmpxchg_cap(&cap_to_cap, &exp, &des, &temp, 0, 0, 0);
  ASSERT_CAPABILITY_VALUE_EQ(&cap, &b);
  ASSERT_CAPABILITY_METADATA_EQ(&cap, &des);
  ASSERT_TAGGED(&cap);

  ASSERT_CAPABILITY_VALUE_EQ(res.cap, &a);
  ASSERT_CAPABILITY_METADATA_EQ(res.cap, cap_high);
  ASSERT_TAGGED(res.cap);
  ASSERT_EQ(res.result, (uint8_t)1);
}

TEST(CmpxchgCap, DifferentExpected) {
  uint8_t a, b, c;
  __cheriseed_cap_t cap_to_cap, cap, exp, des, temp;

  utils::InitCap(&cap, &a);
  utils::InitCap(&exp, &b);
  utils::InitCap(&des, &c);
  utils::InitCap(&cap_to_cap, &cap);

  uint64_t cap_high = __cheriseed_copy_from_high(&cap);

  __cheriseed_cmpxchg_result_t res =
      __cheriseed_cmpxchg_cap(&cap_to_cap, &exp, &des, &temp, 0, 0, 0);
  ASSERT_CAPABILITY_VALUE_EQ(&cap, &a);
  ASSERT_CAPABILITY_METADATA_EQ(&cap, cap_high);
  ASSERT_TAGGED(&cap);

  ASSERT_CAPABILITY_VALUE_EQ(res.cap, &a);
  ASSERT_CAPABILITY_METADATA_EQ(res.cap, cap_high);
  ASSERT_TAGGED(res.cap);
  ASSERT_EQ(res.result, (uint8_t)0);
}

TEST(CmpxchgCap, NoLoadCapPerm) {
  uint8_t a, b;
  __cheriseed_cap_t cap_to_cap, cap, exp, des, temp;

  utils::InitCap(&cap, &a);
  utils::InitCap(&exp, &a);
  utils::InitCap(&des, &b);
  utils::InitCap(&cap_to_cap, &cap);
  __cheriseed_perms_and(&cap_to_cap, &cap_to_cap, ~ccl::permissions::LOAD_CAP);
  __cheriseed_cmpxchg_result_t res =
      __cheriseed_cmpxchg_cap(&cap_to_cap, &exp, &des, &temp, 0, 0, 0);
  // Original cap should be tagged.
  ASSERT_TAGGED(&cap);
  // Loaded copy should be untagged.
  ASSERT_UNTAGGED(&temp);
  ASSERT_UNTAGGED(res.cap);
}

TEST(CmpxchgCap, NoStoreCapPerm) {
  uint8_t a, b;
  __cheriseed_cap_t cap_to_cap, cap, exp, des, temp;

  utils::InitCap(&cap, &a);
  utils::InitCap(&exp, &a);
  utils::InitCap(&des, &b);
  utils::InitCap(&cap_to_cap, &cap);
  __cheriseed_tag_clear(&des, &des);
  __cheriseed_perms_and(&cap_to_cap, &cap_to_cap, ~ccl::permissions::STORE_CAP);
  __cheriseed_cmpxchg_cap(&cap_to_cap, &exp, &des, &temp, 0, 0, 0);
}

TEST(CmpxchgCapHybrid, SameAsExpected) {
  uint8_t a, b;
  __cheriseed_cap_t cap, exp, des, temp;

  utils::InitCap(&cap, &a);
  utils::InitCap(&exp, &a);
  utils::InitCap(&des, &b);

  uint64_t cap_high = __cheriseed_copy_from_high(&cap);

  __cheriseed_cmpxchg_result_t res =
      __cheriseed_cmpxchg_cap_hybrid(&cap, &exp, &des, &temp, 0, 0);
  ASSERT_CAPABILITY_VALUE_EQ(&cap, &b);
  ASSERT_CAPABILITY_METADATA_EQ(&cap, &des);
  ASSERT_TAGGED(&cap);

  ASSERT_CAPABILITY_VALUE_EQ(res.cap, &a);
  ASSERT_CAPABILITY_METADATA_EQ(res.cap, cap_high);
  ASSERT_TAGGED(res.cap);
  ASSERT_EQ(res.result, (uint8_t)1);
}

TEST(CmpxchgCapHybrid, DifferentExpected) {
  uint8_t a, b, c;
  __cheriseed_cap_t cap, exp, des, temp;

  utils::InitCap(&cap, &a);
  utils::InitCap(&exp, &b);
  utils::InitCap(&des, &c);

  uint64_t cap_high = __cheriseed_copy_from_high(&cap);

  __cheriseed_cmpxchg_result_t res =
      __cheriseed_cmpxchg_cap_hybrid(&cap, &exp, &des, &temp, 0, 0);
  ASSERT_CAPABILITY_VALUE_EQ(&cap, &a);
  ASSERT_CAPABILITY_METADATA_EQ(&cap, cap_high);
  ASSERT_TAGGED(&cap);

  ASSERT_CAPABILITY_VALUE_EQ(res.cap, &a);
  ASSERT_CAPABILITY_METADATA_EQ(res.cap, cap_high);
  ASSERT_TAGGED(res.cap);
  ASSERT_EQ(res.result, (uint8_t)0);
}

TEST(LoadStoreCap, Api) {
  __cheriseed_cap_t ones, dst, dst_cap, src, src_cap;

  utils::InitCap(&ones, 1, 1);
  utils::InitCap(&dst, UINT64_TEST, UINT64_TEST);
  utils::InitCap(&dst_cap, &dst);
  utils::InitCap(&src, UINT64_TEST, UINT64_TEST);
  utils::InitCap(&src_cap, &src);

  __cheriseed_store_cap(&dst_cap, &ones, 0);
  ASSERT_CAPABILITY_METADATA_EQ(&dst, (uint64_t)1);
  ASSERT_CAPABILITY_VALUE_EQ(&dst, (uint64_t)1);

  __cheriseed_cap_t *result_cap = __cheriseed_load_cap(&src_cap, &dst, 0);
  ASSERT_EQ(result_cap, &dst);
  ASSERT_CAPABILITY_METADATA_EQ(&dst, UINT64_TEST);
  ASSERT_CAPABILITY_VALUE_EQ(&dst, UINT64_TEST);
}

TEST(LoadCap, NoLoadCapPerm) {
  __cheriseed_cap_t target, load_from, dst;
  utils::InitCap(&load_from, &target);
  // Check missing LOAD_CAP: tag should be cleared.
  __cheriseed_perms_and(&load_from, &load_from, ~ccl::permissions::LOAD_CAP);
  __cheriseed_load_cap(&load_from, &dst, 0);
}

TEST(StoreCap, StoreNullptr) {
  __cheriseed_cap_t dst, dst_cap;
  utils::InitCap(&dst, UINT64_TEST, UINT64_TEST);
  utils::InitCap(&dst_cap, &dst);
  __cheriseed_store_cap(&dst_cap, nullptr, 0);
  ASSERT_CAPABILITY_METADATA_EQ(&dst, (uint64_t)0);
  ASSERT_CAPABILITY_VALUE_EQ(&dst, (uint64_t)0);
}

TEST(StoreCap, NoStoreCapPermission) {
  __cheriseed_cap_t target, store_to, src;
  utils::InitCap(&store_to, &target);
  utils::InitCap(&src, (char *)nullptr);
  __cheriseed_tag_clear(&src, &src);
  __cheriseed_perms_and(&store_to, &store_to, ~ccl::permissions::STORE_CAP);
  __cheriseed_store_cap(&store_to, &src, 0);
}

TEST(LoadStoreCapHybrid, Api) {
  __cheriseed_cap_t ones, dst, src;
  utils::InitCap(&ones, 1, 1);
  utils::InitCap(&dst, UINT64_TEST, UINT64_TEST);
  utils::InitCap(&src, UINT64_TEST, UINT64_TEST);

  __cheriseed_store_cap_hybrid(&dst, &ones);
  ASSERT_CAPABILITY_METADATA_EQ(&dst, (uint64_t)1);
  ASSERT_CAPABILITY_VALUE_EQ(&dst, (uint64_t)1);

  __cheriseed_cap_t *cap_ptr = __cheriseed_load_cap_hybrid(&src, &dst);
  ASSERT_EQ(cap_ptr, &dst);
  ASSERT_CAPABILITY_METADATA_EQ(&dst, UINT64_TEST);
  ASSERT_CAPABILITY_VALUE_EQ(&dst, UINT64_TEST);
}

TEST(EqualExact, Api) {
  ASSERT_TRUE(__cheriseed_equal_exact(nullptr, nullptr));

  uint16_t a;
  __cheriseed_cap_t cap1;
  utils::InitCap(&cap1, &a);
  ASSERT_FALSE(__cheriseed_equal_exact(&cap1, nullptr));
  ASSERT_FALSE(__cheriseed_equal_exact(nullptr, &cap1));

  __cheriseed_cap_t cap2;
  utils::InitCap(&cap2, &a);
  ASSERT_TRUE(__cheriseed_equal_exact(&cap1, &cap2));

  uint16_t b;
  __cheriseed_cap_t cap3;
  utils::InitCap(&cap3, &b);
  ASSERT_FALSE(__cheriseed_equal_exact(&cap1, &cap3));
}

TEST(PermsAnd, Api) {
  // test nullptr as input capability
  __cheriseed_cap_t cap;
  __cheriseed_perms_and(&cap, nullptr, UINT64_TEST);
  ASSERT_EQ(__cheriseed_perms_get(&cap), 0u);

  // test value is preserved and perms updated
  uint16_t a;
  __cheriseed_cap_t cap_a;
  utils::InitCap(&cap_a, &a);
  __cheriseed_perms_and(&cap_a, &cap_a, ccl::permissions::LOAD);
  ASSERT_CAPABILITY_VALUE_EQ(&cap_a, &a);
  ASSERT_EQ(__cheriseed_perms_get(&cap_a), ccl::permissions::LOAD);
}

TEST(RepresentableAlignmentMask, Api) {
  ASSERT_EQ(__cheriseed_representable_alignment_mask(0), UINT64_MAX);
  ASSERT_EQ(__cheriseed_representable_alignment_mask(sizeof(uint64_t)),
            UINT64_MAX);
  ASSERT_LE(__cheriseed_representable_alignment_mask(UINT64_TEST), UINT64_MAX);
}

TEST(RoundRepresentableLength, Api) {
  ASSERT_EQ(__cheriseed_round_representable_length(0), 0u);
  ASSERT_EQ(__cheriseed_round_representable_length(sizeof(uint64_t)),
            sizeof(uint64_t));
  ASSERT_GE(__cheriseed_round_representable_length(UINT64_TEST), UINT64_TEST);
}

TEST(BoundsSet, BoundsSet) {
  uint16_t a;
  __cheriseed_cap_t cap, cap_a;
  utils::InitCap(&cap, &a);
  // This length is small enough to not require rounding
  __cheriseed_bounds_set(&cap_a, &cap, sizeof(uint16_t));
  // Assert that cap_out has been updated to the expected values
  ASSERT_EQ(__cheriseed_base_get(&cap_a), __cheriseed_address_get(&cap));
  ASSERT_EQ(__cheriseed_length_get(&cap_a), sizeof(uint16_t));
  ASSERT_EQ(__cheriseed_perms_get(&cap_a), __cheriseed_perms_get(&cap));
  // Assert that cap_in is unchanged
  ASSERT_EQ(__cheriseed_base_get(&cap), 0u);
  ASSERT_EQ(__cheriseed_length_get(&cap), UINT64_MAX);
}

TEST(BoundsSet, SameOutIn) {
  uint16_t a;
  __cheriseed_cap_t cap_a;
  utils::InitCap(&cap_a, &a);

  // Pass the same pointer as cap_in and cap_out;
  __cheriseed_bounds_set(&cap_a, &cap_a, sizeof(uint16_t));

  ASSERT_EQ(__cheriseed_base_get(&cap_a), reinterpret_cast<uint64_t>(&a));
  ASSERT_EQ(__cheriseed_length_get(&cap_a), sizeof(uint16_t));
}

TEST(BoundsSet, NullptrIn) {
  uint16_t a;
  __cheriseed_cap_t cap_a;
  utils::InitCap(&cap_a, &a);

  // Pass the same pointer as cap_in and cap_out;
  __cheriseed_bounds_set(&cap_a, nullptr, sizeof(uint16_t));

  ASSERT_EQ(__cheriseed_base_get(&cap_a), 0u);
  ASSERT_EQ(__cheriseed_length_get(&cap_a), sizeof(uint16_t));
}

TEST(BoundsSet, Round) {
  uint16_t a;
  constexpr uint64_t length = UINT16_TEST;
  __cheriseed_cap_t cap_a;
  utils::InitCap(&cap_a, &a);

  // This length will require rounding
  __cheriseed_bounds_set(&cap_a, nullptr, length);

  ASSERT_NE(UINT64_MAX, __cheriseed_representable_alignment_mask(length) &
                            __cheriseed_address_get(&cap_a));
  ASSERT_EQ(__cheriseed_base_get(&cap_a),
            __cheriseed_address_get(&cap_a) &
                __cheriseed_representable_alignment_mask(length));
  ASSERT_NE(__cheriseed_round_representable_length(length), length);
  ASSERT_EQ(__cheriseed_length_get(&cap_a),
            __cheriseed_round_representable_length(length));
}

TEST(BoundsSetExact, Api) {
  uint16_t a;
  __cheriseed_cap_t cap, cap_a;
  utils::InitCap(&cap, &a);

  // This length is small enough to not require rounding
  __cheriseed_bounds_set_exact(&cap_a, &cap, sizeof(uint16_t));

  // Assert that cap_out has been updated to the expected values
  ASSERT_EQ(__cheriseed_base_get(&cap_a), __cheriseed_address_get(&cap));
  ASSERT_EQ(__cheriseed_length_get(&cap_a), sizeof(uint16_t));
  ASSERT_EQ(__cheriseed_perms_get(&cap_a), __cheriseed_perms_get(&cap));
  // Assert that cap_in is unchanged
  ASSERT_EQ(__cheriseed_base_get(&cap), 0u);
  ASSERT_EQ(__cheriseed_length_get(&cap), UINT64_MAX);
}

TEST(BoundsSetExact_SameOutIn, SameOutIn) {
  uint16_t a;
  __cheriseed_cap_t cap_a;
  utils::InitCap(&cap_a, &a);

  // Pass the same pointer as cap_in and cap_out;
  __cheriseed_bounds_set_exact(&cap_a, &cap_a, sizeof(uint16_t));

  ASSERT_EQ(__cheriseed_base_get(&cap_a), reinterpret_cast<uint64_t>(&a));
  ASSERT_EQ(__cheriseed_length_get(&cap_a), sizeof(uint16_t));
}

TEST(BoundsSetExact, NullptrIn) {
  uint16_t a;
  __cheriseed_cap_t cap_a;
  utils::InitCap(&cap_a, &a);

  // Pass nullptr as cap_in, which should be interpreted as the null
  // capability
  __cheriseed_bounds_set_exact(&cap_a, nullptr, sizeof(uint16_t));

  ASSERT_EQ(__cheriseed_base_get(&cap_a), 0u);
  ASSERT_EQ(__cheriseed_length_get(&cap_a), sizeof(uint16_t));
}

TEST(OffsetSet, Api) {
  uint32_t a[2] = {42, 64};
  __cheriseed_cap_t cap, new_cap;
  utils::InitCap(&cap, &a);
  // base of cap is zero from ddc capability, offset is new cursor
  __cheriseed_offset_set(&new_cap, &cap, reinterpret_cast<uint64_t>(&(a[1])));
  // value of output cap should be requested address
  ASSERT_CAPABILITY_VALUE_EQ(&new_cap, &(a[1]));

  // assert that offset is retrievable
  ASSERT_EQ(__cheriseed_offset_get(&new_cap),
            reinterpret_cast<uint64_t>(&a[1]));
}

TEST(OffsetSet, NullptrIn) {
  uint32_t a[2] = {42, 64};
  __cheriseed_cap_t cap_out;
  // base of cap is zero from ddc capability, offset is new cursor
  __cheriseed_offset_set(&cap_out, nullptr,
                         reinterpret_cast<uint64_t>(&(a[1])));
  // value of output cap should be requested address
  ASSERT_CAPABILITY_VALUE_EQ(&cap_out, &(a[1]));
  // The property of cursor = base + offset should still hold
  ASSERT_CAPABILITY_VALUE_EQ(&cap_out, __cheriseed_base_get(&cap_out) +
                                           __cheriseed_offset_get(&cap_out));
  // This capability is derived from the Null capability, meaning the
  // perms should be zero and length should be max
  ASSERT_EQ(__cheriseed_perms_get(&cap_out), 0u);
  ASSERT_EQ(__cheriseed_length_get(&cap_out), UINT64_MAX);
}

TEST(OffsetSet, FromBase) {
  uint32_t a[2] = {42, 64};
  __cheriseed_cap_t cap_a, cap_a1;
  utils::InitCap(&cap_a, &a);
  // Tighten bounds
  __cheriseed_bounds_set(&cap_a1, &cap_a, 2 * sizeof(uint32_t));
  // base and value of cap_a1 are now equal to &a (offset 0)
  ASSERT_CAPABILITY_VALUE_EQ(&cap_a1, __cheriseed_base_get(&cap_a1));
  // This value is within bounds and representable
  __cheriseed_offset_set(&cap_a1, &cap_a1, sizeof(uint32_t));
  // offset value is correctly retrievable
  ASSERT_EQ(__cheriseed_offset_get(&cap_a1), sizeof(uint32_t));

  // Definition of cursor value still holds
  ASSERT_CAPABILITY_VALUE_EQ(
      &cap_a1, __cheriseed_base_get(&cap_a1) + __cheriseed_offset_get(&cap_a1));
  // cap_a base/length should be unchanged since __cheriseed_bounds_set call
  ASSERT_CAPABILITY_VALUE_EQ(&cap_a, __cheriseed_base_get(&cap_a1));
  ASSERT_EQ(__cheriseed_length_get(&cap_a1), 2 * sizeof(uint32_t));

  // Expectation of how this function would be used
  ASSERT_CAPABILITY_VALUE_EQ(&cap_a1, &(a[1]));
}

TEST(OffsetSet, AboveTop) {
  uint32_t a[2] = {42, 64};
  __cheriseed_cap_t cap_a, cap_a1;
  utils::InitCap(&cap_a, &a);
  // Tighten bounds of cap_a1
  __cheriseed_bounds_set(&cap_a1, &cap_a, 2 * sizeof(uint32_t));
  // base and value of cap_a1 are now equal to &a (offset 0)
  ASSERT_CAPABILITY_VALUE_EQ(&cap_a1, __cheriseed_base_get(&cap_a1));

  // This value is out-of-bounds, but still representable
  __cheriseed_offset_set(&cap_a1, &cap_a1, 3 * sizeof(uint32_t));
  // offset value is correctly retrievable
  ASSERT_EQ(__cheriseed_offset_get(&cap_a1), 3 * sizeof(uint32_t));
  // Definition of cursor value still holds
  ASSERT_CAPABILITY_VALUE_EQ(
      &cap_a1, __cheriseed_base_get(&cap_a1) + __cheriseed_offset_get(&cap_a1));
  // cap_a base/length should be unchanged since __cheriseed_bounds_set call
  ASSERT_CAPABILITY_VALUE_EQ(&cap_a, __cheriseed_base_get(&cap_a1));
  ASSERT_EQ(__cheriseed_length_get(&cap_a1), 2 * sizeof(uint32_t));
  // TODO cap_a should still be valid
}

TEST(OffsetSet, Round) {
  uint32_t a;
  __cheriseed_cap_t cap_a, cap_b;
  utils::InitCap(&cap_a, &a);
  // Tighten bounds of cap_b
  __cheriseed_bounds_set(&cap_b, &cap_a, sizeof(uint32_t));
  // base and value of cap_b are now equal to &a (offset is 0)
  ASSERT_CAPABILITY_VALUE_EQ(&cap_b, __cheriseed_base_get(&cap_b));
  // This value is out-of-bounds and not representable.
  __cheriseed_offset_set(&cap_b, &cap_b, UINT64_TEST);

  // The output cursor should still be input cursor + requested offset.
  // This behaviour is useful for debugging, instead of preserving the offset
  // from a base that has been altered by rounding.
  ASSERT_CAPABILITY_VALUE_EQ(&cap_b,
                             __cheriseed_address_get(&cap_a) + UINT64_TEST);
  // The property of cursor = base + offset should still hold
  ASSERT_CAPABILITY_VALUE_EQ(
      &cap_b, __cheriseed_base_get(&cap_b) + __cheriseed_offset_get(&cap_b));
  ASSERT_EQ(__cheriseed_length_get(&cap_b), sizeof(uint32_t));

  // Since the selected offset is not representable:
  // TODO cap_b should have been invalidated

  // Before compression the base should also be set to zero, and the offset set
  // to the expected cursor. However, this value may not be representable after
  // compression, so the base may not be zero in the output capability
}

TEST(BaseGet, Api) { ASSERT_EQ(__cheriseed_base_get(nullptr), 0u); }

TEST(ALengthGetPI, Api) {
  ASSERT_EQ(__cheriseed_length_get(nullptr), UINT64_MAX);
}

TEST(OffsetGet, Api) {
  ASSERT_EQ(__cheriseed_offset_get(nullptr), 0u);

  uint16_t a;
  __cheriseed_cap_t cap;
  utils::InitCap(&cap, &a);
  // By default, InitCap creates ddc metadata, so a base of 0. The offset should
  // therefore be the same as the capability value.
  ASSERT_EQ(__cheriseed_offset_get(&cap), reinterpret_cast<uint64_t>(&a));
}

TEST(Diff, Api) {
  uint8_t a[2];
  __cheriseed_cap_t cap_a, cap_b;
  utils::InitCap(&cap_a, &a[1]);
  utils::InitCap(&cap_b, &a[0]);
  ASSERT_EQ(__cheriseed_diff(&cap_a, &cap_a), 0);
  ASSERT_EQ(__cheriseed_diff(&cap_a, &cap_b), 1);
  ASSERT_EQ(__cheriseed_diff(&cap_b, &cap_a), -1);
  ASSERT_EQ(__cheriseed_diff(&cap_a, nullptr),
            reinterpret_cast<uint64_t>(&a[1]));
  ASSERT_EQ(__cheriseed_diff(nullptr, &cap_b),
            -reinterpret_cast<uint64_t>(&a[0]));
  ASSERT_EQ(__cheriseed_diff(nullptr, nullptr), 0);
}

TEST(SubsetTest, Api) {
  //      a:        [42][64]
  //    cap: |- ... -------- ... -| rwxRW
  //  a_cap:        |------|        r
  // a0_cap:        |--|            r
  // a1_cap:            |--|        r
  // np_cap:        |------|

  uint16_t a[2] = {42, 64};
  __cheriseed_cap_t cap;
  utils::InitCap(&cap, &a);

  // All fields equal
  ASSERT_TRUE(__cheriseed_subset_test(&cap, &cap));

  // All fields narrower
  __cheriseed_cap_t a_cap;
  __cheriseed_bounds_set(&a_cap, &cap, 2 * sizeof(uint16_t));
  __cheriseed_perms_and(&a_cap, &a_cap, ccl::permissions::LOAD);
  ASSERT_TRUE(__cheriseed_subset_test(&a_cap, &cap));

  // Top wider
  __cheriseed_cap_t a0_cap;
  __cheriseed_bounds_set(&a0_cap, &a_cap, sizeof(uint16_t));
  ASSERT_FALSE(__cheriseed_subset_test(&a_cap, &a0_cap));

  // Base wider
  __cheriseed_cap_t a1_cap;
  __cheriseed_address_set(&a1_cap, &a_cap, reinterpret_cast<uint64_t>(&a[1]));
  __cheriseed_bounds_set(&a1_cap, &a1_cap, sizeof(uint16_t));
  ASSERT_FALSE(__cheriseed_subset_test(&a_cap, &a1_cap));

  // Perms wider
  __cheriseed_cap_t np_cap;
  __cheriseed_perms_and(&np_cap, &a_cap, 0);
  ASSERT_FALSE(__cheriseed_subset_test(&a_cap, &np_cap));

  // All fields wider
  ASSERT_FALSE(__cheriseed_subset_test(&cap, &a_cap));
}

TEST(TagClear, Api) {
  uint8_t a;
  __cheriseed_cap_t cap;
  utils::InitCap(&cap, &a);
  __cheriseed_tag_clear(&cap, &cap);
  ASSERT_EQ(__cheriseed_tag_get(&cap), 0);
}

TEST(TagGet, Api) {
  uint8_t a;
  __cheriseed_cap_t cap;
  utils::InitCap(&cap, &a);
  ASSERT_EQ(__cheriseed_tag_get(&cap), 1);
}

TEST(GenericCapInit, Api) {
  uint16_t a;
  __cheriseed_cap_t cap;
  __cheriseed_generic_cap_init(&cap, reinterpret_cast<uint64_t>(&a), sizeof(a),
                               Permissions::EXECUTE);
  ASSERT_CAPABILITY_VALUE_EQ(&cap, &a);
  ASSERT_EQ(__cheriseed_base_get(&cap), reinterpret_cast<uint64_t>(&a));
  ASSERT_EQ(__cheriseed_length_get(&cap), sizeof(a));
  ASSERT_NE(__cheriseed_perms_get(&cap) & ccl::permissions::LOAD, 0);
  ASSERT_EQ(__cheriseed_perms_get(&cap) & ccl::permissions::EXECUTE, 0);
  ASSERT_TAGGED(&cap);
}

TEST(ClearAllTags, Api) {
  uint8_t a;
  __cheriseed_cap_t cap[20];
  // Initialize all capabilities.
  for (size_t idx = 0; idx < (sizeof(cap) / sizeof(cap[0])); ++idx) {
    utils::InitCap(&cap[idx], &a);
    ASSERT_EQ(__cheriseed_tag_get(&cap[idx]), 1);
  }
  __cheriseed_cap_t cap_all;
  utils::InitCap(&cap_all, cap);
  // Call API.
  __cheriseed_clear_all_tags(&cap_all, sizeof(cap));
  // Check if all tags are cleared.
  ASSERT_EQ(__cheriseed_tag_get(&cap_all), 1);
  for (size_t idx = 0; idx < (sizeof(cap) / sizeof(cap[0])); ++idx) {
    ASSERT_EQ(__cheriseed_tag_get(&cap[idx]), 0);
  }
}

TEST(LockAndCopyAllTags, Api) {
  constexpr uint8_t test_pattern_interval = 3;  // Arbitary value.
  uint8_t a;
  __cheriseed_cap_t cap_src[20], cap_dest[20];

  // Initialize caps in a pattern and check if tags of caps are as expected.
  for (size_t idx = 0; idx < (sizeof(cap_src) / sizeof(cap_src[0])); ++idx) {
    if (idx % test_pattern_interval == 0) {
      utils::InitCap(&cap_src[idx], &a);
      ASSERT_EQ(__cheriseed_tag_get(&cap_src[idx]), 1);
    } else {
      ASSERT_EQ(__cheriseed_tag_get(&cap_src[idx]), 0);
    }
    ASSERT_EQ(__cheriseed_tag_get(&cap_dest[idx]), 0);
  }

  // Initialize src and dest caps.
  __cheriseed_cap_t cap_all_src, cap_all_dest;
  utils::InitCap(&cap_all_src, cap_src);
  utils::InitCap(&cap_all_dest, cap_dest);

  // Call api
  __cheriseed_lock_and_copy_all_tags(&cap_all_dest, &cap_all_src,
                                     sizeof(cap_src));

  ASSERT_EQ(__cheriseed_tag_get(&cap_all_src), 1);
  ASSERT_EQ(__cheriseed_tag_get(&cap_all_dest), 1);
  for (size_t idx = 0; idx < (sizeof(cap_dest) / sizeof(cap_dest[0])); ++idx) {
    // Check if tags are copied correctly.
    if (idx % test_pattern_interval == 0)
      ASSERT_EQ(__cheriseed_tag_get(&cap_dest[idx]), 1);
    else
      ASSERT_EQ(__cheriseed_tag_get(&cap_dest[idx]), 0);
  }
}

TEST(CopyAllTags, Api) {
  constexpr uint8_t test_pattern_interval = 3;  // Arbitary value.
  uint8_t a;
  __cheriseed_cap_t cap_src[20], cap_dest[20];

  // Initialize caps in a pattern and check if tags of caps are as expected.
  for (size_t idx = 0; idx < (sizeof(cap_src) / sizeof(cap_src[0])); ++idx) {
    if (idx % test_pattern_interval == 0) {
      utils::InitCap(&cap_src[idx], &a);
      ASSERT_EQ(__cheriseed_tag_get(&cap_src[idx]), 1);
    } else {
      ASSERT_EQ(__cheriseed_tag_get(&cap_src[idx]), 0);
    }
    ASSERT_EQ(__cheriseed_tag_get(&cap_dest[idx]), 0);
  }

  // Initialize src and dest caps.
  __cheriseed_cap_t cap_all_src, cap_all_dest;
  utils::InitCap(&cap_all_src, cap_src);
  utils::InitCap(&cap_all_dest, cap_dest);

  // Call api
  __cheriseed_copy_all_tags(&cap_all_dest, &cap_all_src, sizeof(cap_src));

  ASSERT_EQ(__cheriseed_tag_get(&cap_all_src), 1);
  ASSERT_EQ(__cheriseed_tag_get(&cap_all_dest), 1);
  for (size_t idx = 0; idx < (sizeof(cap_dest) / sizeof(cap_dest[0])); ++idx) {
    // Check if tags are copied correctly.
    ASSERT_EQ(__cheriseed_tag_get(&cap_dest[idx]),
              __cheriseed_tag_get(&cap_src[idx]));
  }
}

TEST(CheckAccess, PermsHasExactly) {
  uint32_t a;
  __cheriseed_cap_t cap;
  utils::InitCap(&cap, &a);
  __cheriseed_perms_and(&cap, &cap,
                        (ccl::permissions::LOAD | ccl::permissions::STORE));
  __cheriseed_check_access(&cap, 0, (Permissions::LOAD | Permissions::STORE),
                           0);
}

TEST(CheckAccess, PermsHasMore) {
  uint32_t a;
  __cheriseed_cap_t cap;
  utils::InitCap(&cap, &a);
  __cheriseed_perms_and(&cap, &cap,
                        (ccl::permissions::LOAD | ccl::permissions::STORE));
  __cheriseed_check_access(&cap, 0, Permissions::LOAD, 0);
}

TEST(CheckAccess, BoundsInside) {
  uint16_t a;
  __cheriseed_cap_t cap;
  utils::InitCap(&cap, &a);
  __cheriseed_check_access(&cap, sizeof(uint16_t), 0, 0);
}
