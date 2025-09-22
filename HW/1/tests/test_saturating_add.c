#include "saturating_add.h"
#include <assert.h>
#include <limits.h>
#include <stdio.h>

static void run_one(int x, int y, int expect) {
  int got = saturating_add(x, y);
  if (got != expect) {
    fprintf(stderr, "FAIL: x=%d y=%d expect=%d got=%d\n", x, y, expect, got);
  }
  assert(got == expect);
}

int main(void) {
  // 无溢出
  run_one(1, 2, 3);
  run_one(-5, 3, -2);
  run_one(0, 0, 0);

  // 正溢出：TMax + 1 → TMax
  run_one(INT_MAX, 1, INT_MAX);

  // 负溢出：TMin + (-1) → TMin
  run_one(INT_MIN, -1, INT_MIN);

  // 边界附近
  run_one(INT_MAX, 0, INT_MAX);
  run_one(INT_MIN, 0, INT_MIN);

  puts("saturating_add: all tests passed.");
  return 0;
}
