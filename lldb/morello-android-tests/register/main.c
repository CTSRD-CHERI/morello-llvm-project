#include <stdint.h>

int main() {
  uint64_t value = 0xdeaddeaddeadbeef;
  asm volatile(
      "\tscvalue c11, c11, %[VALUE]\n"
      "\tscbnds c11, c11, #4\n"
      :
      : [VALUE] "r"(value)
      : "c11"
      );
  return 0; // Break here
}
