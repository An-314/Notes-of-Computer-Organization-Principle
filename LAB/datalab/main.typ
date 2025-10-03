#import "@preview/scripst:1.1.1": *

#show: scripst.with(
  template: "report",
  title: [计算机组成原理实验报告],
  info: [DataLAB],
  author: ("Anzreww",),
  time: "2025年10月",
  contents: true,
  content-depth: 3,
  matheq-depth: 3,
  lang: "zh",
)

= 实验要求

本实验为《计算机组成原理》课程的 Data Lab：位操作实验。实验的主要目标是通过完成一系列位级运算的编程题，深入理解整数和浮点数的二进制表示方式及其运算规则。

实验要求如下：
- 在提供的 `bits.c` 文件中，补全 13 个函数的实现，每个函数对应一个小的“编程谜题”。
- 整数类函数必须使用限定的运算符（`! ~ & ^ | + << >>`），且禁止使用控制结构（如 `if/while/for`）、函数调用、数组、结构体、宏定义等。
- 对于浮点数类函数，允许使用条件语句和循环，但仍然禁止使用浮点类型及浮点运算，只能通过 `unsigned int` 对浮点数的位级表示进行操作。
- 每个函数都有最大运算符数（Max ops）限制，代码必须在该限制范围内完成。
- 实验提供了自动评分工具 `btest`、`dlc` 和 `driver.pl` 用于正确性和效率检查。
在`bits.c`的文件中有更详细的说明和示例代码。

== 整数部分编码规则

可以使用的内容：
- 整数常量`0 ~ 255`（即 `0xFF`），不允许更大的常量（如`0xffffffff`）。
- 函数参数、本地变量（不能用全局变量）。
- 一元运算符：`! ~`
- 二元运算符：`& ^ | + << >>`
禁止使用的内容：
- 任何控制结构：`if, do, while, for, switch`等。
- 宏定义。
- 新增函数。
- 调用函数。
- 其他运算符：`&&, ||, -, ?:` 等。
- 类型转换(cast)。
- 除 `int` 外的其他类型。

== 浮点部分编码规则

可以使用：
- 条件和循环控制语句。
- `int` 和 `unsigned` 两种类型。
- 任意整型常量。
- 所有整型算术、逻辑、比较运算。
禁止使用：
- 宏定义。
- 新增函数。
- 调用函数。
- 类型转换 (cast)。
- 除 `int` 和 `unsigned` 外的其他类型。
- 任何浮点类型、浮点运算、浮点常量。

= 实验内容

本实验主要包括以下几个部分：
- 整数类函数
- 浮点数类函数
下面将对这两个部分的实验内容进行详细说明。

== 整数类函数

=== `int bitXor(int x, int y)`

该函数要求
#three-line-table[
  | 函数名 | 功能 | 合法运算符 | 操作数 |
  |--------|------|------------|------------|
  | `bitXor` | 计算异或 | `~ &` | $7(<14)$ |
]

利用Boolean代数：
```
  X ^ Y = (X & ~Y) | (~X & Y)
```
直接实现即可：
```c
int bitXor(int x, int y) {
    return (x & ~y) | (~x & y);
}
```

=== `int tmin(void)`

该函数要求
#three-line-table[
  | 函数名 | 功能 | 合法运算符 | 操作数 |
  |--------|------|------------|------------|
  | `tmin` | 最小的二进制补码 | `! ~ & ^ | + << >>` | $1(<4)$ |
]

最小补码是1000...0000，即1左移31位
```c
int tmin(void) {
    return 1 << 31;
}
```

=== `int isTmax(int x)`

该函数要求

#three-line-table[
  | 函数名 | 功能 | 合法运算符 | 操作数 |
  |--------|------|------------|------------|
  | `isTmax` | 判断是否为最大整数 | `! ~ & ^ | +` | $8(<10)$ |
]

本题不再允许使用移位运算，从而需要考虑$T_max = 0111...1111$的性质。事实上
$
  T_max + 1 = 1000...0000 = T_min = ~T_max
$
但满足这样的数还有一个是$-1 = 1111...1111, 1111...1111 + 1 = ~0$，排除即可
```c
int isTmax(int x) {
  return !((x + 1) ^ ~x) & !!(x + 1);
}
```
事实上判断两数`x`和`y`是否相等，可以用
```c
!(x ^ y)
```
来实现。

=== `int allOddBits(int x)`

该函数要求

#three-line-table[
  | 函数名 | 功能 | 合法运算符 | 操作数 |
  |--------|------|------------|------------|
  | `allOddBits` | 判断奇数位是否全为1 | `! ~ & ^ | + << >>` | $7(<12)$ |
]

可以用一个掩码`0xAAAAAAAA`（即10101010...）与`x`进行按位与运算，判断结果是否等于掩码。但是题目要求使用的数字范围是0~255，需要通过多次移位求和得到掩码
```c
int allOddBits(int x) {
  int mask = 0xAA + (0xAA << 8);
  mask = mask + (mask << 16); // 0xAAAAAAAA
  return !((x & mask) ^ mask);
}
```

=== `int negate(int x)`

该函数要求

#three-line-table[
  | 函数名 | 功能 | 合法运算符 | 操作数 |
  |--------|------|------------|------------|
  | `negate` | 取相反数 | `! ~ & ^ | + << >>` | $2(<4)$ |
]

在补码表示中，取反操作可以通过对原数进行按位取反，然后加1来实现。因此，`negate` 函数可以这样实现：
```c
int negate(int x) {
  return ~x + 1;
}
```

=== `int isAsciiDigit(int x)`

#three-line-table[
  | 函数名 | 功能 | 合法运算符 | 操作数 |
  | --- | --- | --- | --- |
  | `isAsciiDigit` | 判断是否为ASCII数字 | `! ~ & ^ | + << >>` | $11(<15)$ |
]

要比较两数`x`和`y`的大小关系，可以直接看
```c
x - y = x + (~y + 1)
```
的符号位即可，具体实现如下：
```c
int isAsciiDigit(int x) {
  int lower_bound = x + (~0x30 + 1); // x - 0x30
  int upper_bound = 0x39 + (~x + 1); // 0x39 - x
  return !(lower_bound >> 31) & !(upper_bound >> 31);
}
```
需要补充的是，事实上这里的`x - y`是可能发生溢出的
- `lower_bound = x - ~0x30`的结果溢出的可能是`x < T_min + 0x30`时发生
- `upper_bound = 0x39 - x`的结果溢出的可能是`x < - T_max + 0x39 = T_min + 0x38`时发生
- 当`x < T_min + 0x30`时，都溢出
  - `lower_bound`符号位为0，`upper_bound`符号位为1
  - 返回值为0，正确
- 当`T_min + 0x30 < x < T_min + 0x39`时，`lower_bound`不发生溢出，但是`upper_bound`会发生溢出
  - `lower_bound`符号位为1，`upper_bound`符号位为1
  - 返回值为0，正确
- 剩下情况不再溢出

=== `int conditional(int x, int y, int z)`

该函数要求

#three-line-table[
  | 函数名 | 功能 | 合法运算符 | 操作数 |
  |--------|------|------------|------------|
  | `conditional` | 返回`x ? y : z ` | `! ~ & ^ | + << >>` | $8(<16)$ |
]

用`x`做一个掩码，来选择`y`或`z`，`mask`为`0xFFFFFFFF(x != 0)`或`0x00000000(x == 0)`。用掩码作用在`y`和`z`上，具体实现如下：
```c
int conditional(int x, int y, int z) {
  int t = !!x;
  int mask = (t << 31) >> 31;   // 或者：int mask = -t;
  return (mask & y) | (~mask & z);
}
```

=== `int isLessOrEqual(int x, int y)`

该函数要求

#three-line-table[
  | 函数名 | 功能 | 合法运算符 | 操作数 |
  |--------|------|------------|------------|
  | `isLessOrEqual` | 判断是否小于等于 | `! ~ & ^ | + << >>` | $14(<24)$ |
]

需要考虑符号位不同和相同的情况：
- 符号位不同：如果`x`和`y`的符号位不同，则可以直接通过符号位判断大小关系。
- 符号位相同：如果`x`和`y`的符号位相同，则需要通过计算`y - x`的值来判断；此时就不会发生溢出。
```c
int isLessOrEqual(int x, int y) {
  int sign_x = (x >> 31) & 1;
  int sign_y = (y >> 31) & 1;
  int sign_diff = sign_x ^ sign_y; // 符号位不同
  int diff = y + (~x + 1); // y - x
  int sign_diff_res = sign_x & sign_diff; // x为负，y为正
  int sign_same_res = !(diff >> 31) & (!sign_diff); // 符号位相同且y - x >= 0
  return sign_diff_res | sign_same_res;
}
```

=== `int logicalNeg(int x)`

该函数要求

#three-line-table[
  | 函数名 | 功能 | 合法运算符 | 操作数 |
  |--------|------|------------|------------|
  | `logicalNeg` | 逻辑非 | `! ~ & ^ | + << >>` | $6(<12)$ |
]

利用`x | -x`的符号位为`0`当且仅当`x`为`0`时成立，因此可以用以下方式实现：
```c
int logicalNeg(int x) {
  return (((x | (~x + 1)) >> 31)^1) & 1;
}
```

=== `int howManyBits(int x)`

该函数要求

#three-line-table[
  | 函数名 | 功能 | 合法运算符 | 操作数 |
  | ---- | ---- | ---- | ---- |
  | `howManyBits` | 计算需要多少位表示 | `! ~ & ^ | + << >>` | $32(<90)$ |
]

- 正数和负数要分开处理
  - 正数：最高的 1 决定了需要多少位
  - 负数：最高的 0 决定了需要多少位
  - 先将整数调整成非负数：
    - 利用最高位的移位来做掩码：如果是负数`x >> 31 = 0xFFFFFFFF`，如果是正数`x >> 31 = 0x00000000`
    - 利用取异或操作将负数变为正数
- 32位整数利用二分法来寻找最高 1 位
  - `!!(ux >> 16)`判断最高1在是否在高16位
  - `<<4`来记录是否在高16位
  - 剩下同理
```c
int howManyBits(int x) {
  // 负数取反，正数不变
  int ux = x ^ (x >> 31);
  // 寻找最高 1 位
  int b16, b8, b4, b2, b1, b0;
  b16 = !!(ux >> 16) << 4; // 高16位
  ux = ux >> b16;
  b8 = !!(ux >> 8) << 3; // 高8位
  ux = ux >> b8;
  b4 = !!(ux >> 4) << 2; // 高4位
  ux = ux >> b4;
  b2 = !!(ux >> 2) << 1; // 高2位
  ux = ux >> b2;
  b1 = !!(ux >> 1); // 高1位
  ux = ux >> b1;
  b0 = ux; // 最低位
  return b16 + b8 + b4 + b2 + b1 + b0 + 1; // 加上符号位
}
```

== 浮点数类函数

=== `unsigned floatScale2(unsigned uf)`

该函数要求

#three-line-table[
  | 函数名 | 功能 | 合法运算符 | 操作数 |
  |--------|------|------------|------------|
  | `floatScale2` | 浮点数乘以2 | `! ~ & ^ | + << >> || && if while` | $14(<30)$ |
]

按三类情况处理：NaN/Inf、非规格化、规格化
- 先提取出`sign`、`exp`和`frac`
- 特殊值：`exp == 0xFF`
  - `frac == 0` → ±∞
  - `frac != 0` → NaN
  - 直接返回原数
- 非规格化数：`exp == 0`
  - 直接左移`frac`，并检查是否成为规格化数
  - 规格化数：第 23 位为 1
    - `exp = 1`，去掉最高位
- 规格化数：`exp != 0, exp != 0xFF`
  - 乘 2 等价于指数 +1
  - 如果加一后 exp == 0xFF，就溢出到±∞
    - `frac = 0`

```c
unsigned floatScale2(unsigned uf) {
  unsigned sign = uf & 0x80000000u;
  unsigned exp  = (uf >> 23) & 0xFFu;
  unsigned frac = uf & 0x7FFFFFu;

  if (exp == 0xFFu) {
    // NaN 或 ±Inf：原样返回
    return uf;
  }
  if (exp == 0) {
    // 非规格化数：左移frac
    frac = frac << 1;
    if (frac & 0x800000u) {
      // 成为规格化数：exp=1，去掉最高位
      exp = 1;
      frac = frac & 0x7FFFFFu;
    }
  } else {
    // 规格化数：exp+1
    exp = exp + 1;
    if (exp == 0xFFu) {
      // 变为±Inf
      frac = 0;
    }
  }
  return sign | (exp << 23) | frac;
}
```

=== `int floatFloat2Int(unsigned uf)`

该函数要求

#three-line-table[
  | 函数名 | 功能 | 合法运算符 | 操作数 |
  |--------|------|------------|------------|
  | `floatFloat2Int` | 浮点数转整数 | `! ~ & ^ | + << >>` | $16(<30)$ |
]

按三类情况处理：NaN/Inf、非规格化、规格化
- 先提取出`sign`、`exp`和`frac`
- 特殊值：`exp == 0xFF`
  - 返回`0x80000000u`
- 非规格化数：`exp == 0`
  - 返回`0`
- 规格化数：`exp != 0, exp != 0xFF`
  - 指数 `E < 0`：返回`0`
  - 溢出判断：
    - 当 `E >= 31`，肯定超出 `int32`
  - 按指数把尾数 `M` 左/右移回到整数位
```c
int floatFloat2Int(unsigned uf) {
  unsigned sign = uf >> 31;
  unsigned exp = (uf >> 23) & 0xFFu;
  unsigned frac = uf & 0x7FFFFFu;
  unsigned M = (1u << 23) | frac; // 尾数
  int val;

  // NaN 或 ±Inf
  if (exp == 0xFFu) return 0x80000000u;
  // 非规格化数，以及E<0的规格化：绝对值小于1
  if (exp < 127u) return 0;
  // E>=31超出范围
  if (exp >= 158u) return 0x80000000u;
  // E>=23时左移，否则右移
  if (exp >= 150u) val = M << (exp - 150u);  // E >= 23
  else val = M >> (150u - exp); // E < 23
  return sign ? (~val + 1u) : val;
}
```

=== `unsigned floatPower2(int x)`

该函数要求

#three-line-table[
  | 函数名 | 功能 | 合法运算符 | 操作数 |
  |--------|------|------------|------------|
  | `floatPower2` | 计算2的x次方的浮点数表示 | `! ~ & ^ | + << >>` | $9(<30)$ |
]

按三类情况处理：负数、0、正数
- 最小非规格化数都无法表示`(< -149)`
- 非规格化区间`-149 ≤ x < -126`
  - 直接返回`1 << (x + 149)`，左移得到规格化数
- 规格化区间`-126 ≤ x ≤ 127`
  - 直接返回`(x + 127) << 23`，得到规格化数
- 过大区间`x > 127`
  - 直接返回`0x7F800000u`，表示正无穷大

```c
unsigned floatPower2(int x) {
    if (x < -149) return 0; // 太小，返回0
    if (x < -126) return 1u << (x + 149); // 非规格化数
    if (x > 127) return 0x7F800000u; // 太大，返回+INF
    return (x + 127) << 23;
}
```

= 实验结果

利用测评工具进行整体测试
```bash
make
./driver.pl
```
输出如下
```log

```
只有一些编译警告，可以忽略。每个函数的功能都得到了验证。
