#pragma once

#include <sanitizer/cheriseed_interface.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// CHERIseed RT has some libshim dependencies.
bool __shim_is_pure_capability(void) { return true; }

void *__shim_syscall(void *p1, ...) {
  (void)p1;
  return (void *)-1;
}

#ifdef __cplusplus
}
#endif
