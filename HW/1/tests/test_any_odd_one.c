#include "any_odd_one.h"
#include <assert.h>
#include <stdio.h>

static void run_one(unsigned x, int expect) {
  int got = any_odd_one(x);
  if (got != expect) {
    fprintf(stderr, "FAIL: x=0x%08x expect=%d got=%d\n", x, expect, got);
  }
  assert(got == expect);
}

int main(void) {
  run_one(0x00000000u, 0);
  run_one(0x00000002u, 1); // bit1
  run_one(0x00000004u, 0); // bit2
  run_one(0x80000000u, 1); // bit31
  run_one(0x55555555u, 0); // 偶数位全 1
  run_one(0xAAAAAAAAu, 1); // 奇数位全 1
  puts("All tests passed.");
  return 0;
}
