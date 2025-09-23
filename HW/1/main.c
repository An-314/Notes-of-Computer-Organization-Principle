#include "any_odd_one.h"
#include "saturating_add.h"
#include <stdio.h>

int main(void) {
  unsigned x = 0x2;
  printf("any_odd_one(0x%x) = %d\n", x, any_odd_one(x));

  int a = 1000000000;
  int b = 2000000000;
  printf("saturating_add(%d, %d) = %d\n", a, b, saturating_add(a, b));
  return 0;
}
