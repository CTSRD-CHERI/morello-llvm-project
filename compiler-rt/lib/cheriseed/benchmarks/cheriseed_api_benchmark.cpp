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
// Benchmarks of the public APIs.
//
//===----------------------------------------------------------------------===//

#define CHERISEED_BENCHMARKING

#include "benchmark/benchmark.h"
#include "cheriseed_test_common.h"

static constexpr unsigned kNumCallsPerIteration = 1000000;

struct ApiBenchmark {
  using WorkloadTy = void (*)(ApiBenchmark& bm);

  ApiBenchmark(benchmark::State& state) : state(state) {
    utils::InitCap(&cap_in, &cap_tmp1);
  }

  void Run(WorkloadTy workload) {
    for (auto _ : state) {
      for (unsigned n = 0; n < kNumCallsPerIteration; ++n) {
        workload(*this);
      }
    }

    state.SetItemsProcessed(state.iterations() * kNumCallsPerIteration);
  };

  benchmark::State& state;
  __cheriseed_cap_t cap_out;
  __cheriseed_cap_t cap_in;
  __cheriseed_cap_t cap_tmp1;
  __cheriseed_cap_t cap_tmp2;
};  // struct ApiBenchmark

#define API_BENCHMARK(__name)                     \
  static void __name##Workload(ApiBenchmark& bm); \
  static void __name(benchmark::State& state) {   \
    ApiBenchmark(state).Run(__name##Workload);    \
  }                                               \
  BENCHMARK(__name);                              \
  static void __name##Workload(ApiBenchmark& bm)

// -------------------------------------
// Mappings of CHERI intrinsics
// -------------------------------------

API_BENCHMARK(AddressGet) { __cheriseed_address_get(&bm.cap_in); }

API_BENCHMARK(AddressSet) {
  __cheriseed_address_set(&bm.cap_out, &bm.cap_in,
                          reinterpret_cast<uint64_t>(&bm.cap_tmp1));
}

API_BENCHMARK(BaseGet) { __cheriseed_base_get(&bm.cap_in); }

API_BENCHMARK(BoundsSet) {
  __cheriseed_bounds_set(&bm.cap_out, &bm.cap_in, sizeof(uint8_t));
}
API_BENCHMARK(BoundsSetExact) {
  __cheriseed_bounds_set_exact(&bm.cap_out, &bm.cap_in, sizeof(uint8_t));
}

API_BENCHMARK(CopyFromHigh) { __cheriseed_copy_from_high(&bm.cap_in); }

API_BENCHMARK(CopyToHigh) {
  __cheriseed_copy_to_high(&bm.cap_out, &bm.cap_in, 42);
}

API_BENCHMARK(Diff) { __cheriseed_diff(&bm.cap_out, &bm.cap_in); }

API_BENCHMARK(EqualExact) { __cheriseed_equal_exact(&bm.cap_out, &bm.cap_in); }

API_BENCHMARK(LengthGet) { __cheriseed_length_get(&bm.cap_in); }

API_BENCHMARK(OffsetGet) { __cheriseed_offset_get(&bm.cap_in); }

API_BENCHMARK(OffsetSet) {
  __cheriseed_offset_set(&bm.cap_out, &bm.cap_in, 42);
}

API_BENCHMARK(PermsAnd) { __cheriseed_perms_and(&bm.cap_out, &bm.cap_in, 42); }

API_BENCHMARK(PermsGet) { __cheriseed_perms_get(&bm.cap_in); }

API_BENCHMARK(SealedGet) { __cheriseed_sealed_get(&bm.cap_in); }

API_BENCHMARK(SubsetTest) { __cheriseed_subset_test(&bm.cap_out, &bm.cap_in); }

API_BENCHMARK(TagClear) { __cheriseed_tag_clear(&bm.cap_out, &bm.cap_in); }

API_BENCHMARK(TagGet) { __cheriseed_tag_get(&bm.cap_in); }

API_BENCHMARK(TypeGet) { __cheriseed_type_get(&bm.cap_in); }

API_BENCHMARK(DDCGet) { __cheriseed_ddc_get(&bm.cap_out); }

API_BENCHMARK(PCCGet) { __cheriseed_pcc_get(&bm.cap_out); }

API_BENCHMARK(RepresentableAlignmentmask) {
  __cheriseed_representable_alignment_mask(42);
}

API_BENCHMARK(RepresentableLength) {
  __cheriseed_round_representable_length(42);
}

// -------------------------------------
// APIs used by the compiler
// -------------------------------------

API_BENCHMARK(CheckAccess) { __cheriseed_check_access(&bm.cap_in, 0, 0, 0); }

API_BENCHMARK(CmpXchg) {
  __cheriseed_cmpxchg_cap(&bm.cap_in, &bm.cap_out, &bm.cap_tmp1, &bm.cap_tmp2,
                          0, 0, 0);
}

API_BENCHMARK(CopyCapWithOffset) {
  __cheriseed_copy_cap_with_offset(&bm.cap_out, &bm.cap_in, 0);
}

API_BENCHMARK(GenericCapInit) {
  __cheriseed_generic_cap_init(&bm.cap_out, 0, 0, 0);
}

API_BENCHMARK(LoadCap) { __cheriseed_load_cap(&bm.cap_in, &bm.cap_out, 0); }

API_BENCHMARK(StackCapInit) { __cheriseed_stack_cap_init(&bm.cap_out, 0, 0); }

API_BENCHMARK(StoreCap) { __cheriseed_store_cap(&bm.cap_in, &bm.cap_out, 0); }

API_BENCHMARK(ThreadPointer) { __cheriseed_thread_pointer(&bm.cap_out); }
