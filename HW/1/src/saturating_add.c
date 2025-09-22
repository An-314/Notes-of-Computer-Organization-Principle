#include "saturating_add.h"
#include <limits.h>

int saturating_add(int x, int y) {
  int s = x + y;

  // 取符号
  int sx = x >> 31;
  int sy = y >> 31;
  int ss = s >> 31;

  // 判断溢出
  int pos_over = (~sx) & (~sy) & ss;
  int neg_over = sx & sy & (~ss);

  // 选择结果
  if (pos_over) {
    return INT_MAX;
  } else if (neg_over) {
    return INT_MIN;
  } else {
    return s;
  }
}
