int function_using_address() {
  int data = 133;
  int *an_address = &data;
  return *an_address; // Break here
}

int main() {
  function_using_address();
  return 0;
}
