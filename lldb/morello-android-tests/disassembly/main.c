__attribute__((naked)) void func_in_same_exec() {
  // This doesn't need to make sense or do anything useful, anything goes as
  // long as it contains some capabilities and doesn't trigger any faults.
  asm volatile(
    "\tsub csp, csp, #0x10\n"
    "\tadd c1, csp, #0xc\n"
    "\tscbnds c1, c1, #0x4\n"
    "\tadd csp, csp, #0x10\n"
    "\tret c30\n"
  );
}

int main() {
  func_in_same_exec(); // Break here
  return 0;
}
