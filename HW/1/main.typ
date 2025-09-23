#import "@preview/scripst:1.1.1": *

#show: scripst.with(
  title: [计算机组成原理],
  info: [第一次作业],
  author: "Anzrew",
  time: "2025/9/23",
)

#note(subname: [作业要求])[
  *每个“Expr”表达式必须满足以下要求：*

  1. *只能使用的元素：*
    - 整型常量（如 `0, 1, 0xFF` 等）。
    - 函数的参数和局部变量（不能使用全局变量）。
  2. *允许的单目运算符：*
    - `!`（逻辑非，结果为 0 或 1）
    - `~`（按位取反）
  3. *允许的双目运算符：*
    - 按位操作：`&`、`^`、`|`
    - 加减法：`+`、`-`
    - 移位：`<<`、`>>`
  4. *允许的比较运算符：*
    - `==`、`!=`
    - 结果只能作为 `int` 使用（即 0 或 1）

  *严格禁止以下内容：*
  1. *任何控制结构*：`if`、`do`、`while`、`for`、`switch` 等。
  2. 定义或使用任何宏（`#define`）。
  3. 定义任何额外函数。
  4. 调用任何函数。
  5. 使用任何其它运算符，比如：逻辑与 `&&`、逻辑或 `||`、条件运算符 `?:`。
  6. 使用任何形式的强制类型转换 `(type)expr`。
  7. 使用除 `int` 之外的任何数据类型（因此不能使用数组、结构体或联合体）。

  *可以假设的机器环境：*
  1. 使用 *二进制补码*（two’s complement），整数为 *32 位*表示。
  2. 整数右移操作是 *算术右移*（保留符号位）。
  3. 如果移位数大于或等于字长（32 位），则行为不可预测。
]

#problem(subname: [2.64])[
  写出代码实现如下函数:
  ```c
  /* Return 1 when any odd bit of x equals 1; 0 otherwise.
     Assume w=32 */
  int any_odd_one(unsigned x);
  ```
  函数应该遵循位级整数编码规则,不过你可以假设数据类型 int 有 $w=32$ 位。
]

#solution[
  观察到奇数位的二进制表示为 `0xAAAAAAAA`，选择其为掩码与输入 `x` 进行按位与操作。如果结果非零，则表示 `x` 的奇数位中至少有一个为 1。
  ```c
  int any_odd_one(unsigned x) {
      return !!(x & 0xAAAAAAAA);
  }
  ```
  这里使用了两次逻辑非运算符 `!!` 来将结果转换为 0 或 1。
]

#problem(subname: [2.73])[
  写出具有如下原型的函数的代码:
  ```c
  /* Addition that saturates to TMin or TMax */
  int saturating_add(int x, int y);
  ```
  同正常的补码加法溢出的方式不同，当正溢出时，饱和加法返回TMax，负溢出时，返回TMin。饱和运算常常用在执行数字信号处理的程序中。

  你的函数应该遵循位级整数编码规则。
]

#solution[
  通过检查加法前后符号位的变化来检测溢出：

  - 如果两个正数相加结果为负数，说明发生了正溢出，返回 `INT_MAX`。
  - 如果两个负数相加结果为正数，说明发生了负溢出，返回 `INT_MIN`。
  - 否则，返回正常的加法结果。
  ```c
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
  ```
]

#problem(subname: [2.82])[
  我们在一个`int`类型值为32位的机器上运行程序。这些值以补码形式表示，而且它们都是算术右移的。`unsigned`类型的值也是32位的。

  我们产生随机数`x`和`y`，并且把它们转换成无符号数，显示如下：
  ```c
  /*Create some arbitrary values*/
  int x = random();
  int y = random();
  /*Convert to unsigned*/
  unsigned ux = (unsigned)x;
  unsigned uy = (unsigned)y;
  ```
  对于下列每个C表达式，你要指出表达式是否总是为`1`。如果它总是为`1`，那么请描述其中的数学原理。否则，列举出一个使它为`0`的参数示例。
  - `(x<y)==(-x>-y)`
  - `((x+y)<<4)+y-x == 17*y+15*x`
  - `~x+~y+1 == ~(x+y)`
  - `(ux-uy)==-(unsigned)(y-x)`
  - `((x>>2)<<2)<=x`
]

#solution[
  + `(x<y)==(-x>-y)`：不总为`1`
    - 反例：`x = TMin = -2147483648, y = 0`
    - `(x<y) == 1`
    - `-x = TMin`（溢出），`-y = 0`，所以 `(-x>-y) == 0`
  + `((x+y)<<4)+y-x == 17*y+15*x`：总为`1`
    - 展开左边：`(x+y)<<4 + y - x = 16*(x+y) + y - x = 15*x + 17*y`
    - 在$mod 2^23$的补码算术里：左移 4 位即乘以 16（截断），加减满足结合/分配律，所以两侧位级结果一致
  + `~x+~y+1 == ~(x+y)`：总为`1`
    - 由补码定义：`~x + 1 = -x`，
    - 所以 `~x + ~y + 1 = -x - y - 1 = -(x+y) - 1 = ~(x+y)`
  + `(ux-uy)==-(unsigned)(y-x)`：总为`1`
    - 展开右边：`-(unsigned)(y-x) = (unsigned)(-(y-x)) = (unsigned)(x-y) = ux - uy`（无符号数减法等价于加上补码）
    - 事实上这些运算都是位运算，结果位级相同，按照同样的位级规则进行解释，所以结果相同
  + `((x>>2)<<2)<=x`：总为`1`
    - `x>>2` 是算术右移，保留符号位
    - `((x>>2)<<2)` 相当于将 `x` 的低两位置零（即 `x & ~3`）
    - 因此 `((x>>2)<<2)` 总是小于或等于 `x`

]


#note(subname: [对代码的补充说明])[
  在作业中，编写了真实的C代码，并通过 `make` 工具进行编译和测试，以验证代码的正确性。以下是两个函数的测试用例示例：
  ```c
  /* 测试用例 */
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
  ```
  ```c
  /* 测试用例 */
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
  ```
  项目结构如下：
  ```
  .
  ├── include
  │   ├── any_odd_one.h
  │   └── saturating_add.h
  ├── src
  │   ├── any_odd_one.c
  │   └── saturating_add.c
  ├── tests
  │   ├── test_any_odd_one.c
  │   └── test_saturating_add.c
  ├── main.c
  └── makefile
  ```
  在根目录下运行 `make test` 可以编译并运行所有测试用例。

  本次作业的代码和测例可以在#link("https://github.com/An-314/Notes-of-Computer-Organization-Principle/tree/master/HW/1")[GitHub仓库]找到。
]
