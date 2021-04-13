int last(int x) {
  int y = 2;
  return x * y; // Break here
}

int second(int *x0, int x1, int x2, int x3,
    int x4, int x5, int x6, int x7, int x8) {
  int y = x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8;
  return *x0 - last(y);
}

int first(int x) {
  int y = x + 12;
  return second(&y, 1, 2, 3, 4, 5, 6, 7, 8);
}

int main() {
  return first(42);
}
