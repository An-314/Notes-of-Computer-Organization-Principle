#include "any_odd_one.h"
#include <stdio.h>

int main(void) {
  unsigned x = 0x2;
  printf("any_odd_one(0x%x) = %d\n", x, any_odd_one(x));
  return 0;
}
