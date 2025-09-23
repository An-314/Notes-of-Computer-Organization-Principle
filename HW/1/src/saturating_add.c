#include "saturating_add.h"

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
  int tmin = 1 << 31; // INT_MIN
  int tmax = ~tmin;   // INT_MAX
  return (pos_over & tmax) | (neg_over & tmin) | ((~(pos_over | neg_over)) & s);
}
