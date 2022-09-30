#pragma once

#include <sanitizer/cheriseed_interface.h>
#include <stdbool.h>

// -----------------------------------------------------------------------------
// Helper macros to make the tests look a little bit better.

#ifndef NOINLINE
#  define NOINLINE __attribute__((noinline))
#endif

#ifndef NORETURN
#  define NORETURN __attribute__((noreturn))
#endif

#define TEST_MAIN() NOINLINE void test_main(void)

#undef TEST_USED
#define TEST_USED(__expr) \
  { volatile typeof(__expr) __v = (__expr); }

// -----------------------------------------------------------------------------
// Test asserts
// Do not use standard 'assert()'.
// If targeting pure-capability ABI the stringified representation of the
// expression tested will be passed onto some 'printf()' or similar. They
// are in fact be given a pointer to a capability, which may or may not result
// in a crash, but will certainly print nonsense.

#undef TEST_ASSERT_WITH_CODE
#define TEST_ASSERT_WITH_CODE(__expr, __exit_code) \
  {                                                \
    if (!(__expr))                                 \
      exit(__exit_code);                           \
  }

#undef TEST_ASSERT
#define TEST_ASSERT(__expr) TEST_ASSERT_WITH_CODE(__expr, 1)

// -----------------------------------------------------------------------------
// Main

__attribute__((constructor)) void pre_main(void) {
  __cheriseed_static_init(0);
  __cheriseed_relocate(0, 0);
  // Make sure violations don't trigger the call of a signal handler.
  __cheriseed_control_invoke_signal_handlers(CHERISEED_DISABLE);
}

void test_main(void);

int main(void) {
  test_main();
  return 0;
}

// -----------------------------------------------------------------------------
// External dependencies

#ifdef __cplusplus
extern "C" {
#endif

NORETURN void exit(int);

// CHERIseed RT has some libshim dependencies.
bool __shim_is_pure_capability(void) {
#ifdef __CHERI_PURE_CAPABILITY__
  return true;
#else
  return false;
#endif
}

bool __shim_supports_cancellation_points() { return false; }

void *__shim_syscall(long nr, ...) {
  (void)nr;
  return (void *)-1;
}

#ifdef __cplusplus
}
#endif
