#import "@preview/scripst:1.1.1": *

#show: scripst.with(
  title: [计算机组成原理],
  info: [第一次作业],
  author: "Anzrew",
  time: "2025/9/23",
)

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
  ```
]

#problem(subname: [2.81])[
  编写C表达式产生如下位模式，其中$a^k$表示符号$a$重复$k$次。假设一个$w$位的数据类型。代码可以包含对参数$j$和$k$的引用，它们分别表示$j$和$k$的值，但是不能使用表示$w$的参数。
  + $1^(w-k) 0^k$
  + $0^(w-k-j) 1^k 0^j$
]

#solution[
  - 对于模式 `1^(w-k) 0^k`，可以通过以下表达式生成：
    ```c
    (unsigned)-1 >> k << k
    ```
    这里，`(unsigned)-1` 生成全为 `1` 的位模式，右移 `k` 位后左移 `k` 位，将最低的 `k` 位清零，得到所需的模式。

  - 对于模式 `0^(w-k-j) 1^k 0^j`，可以使用以下表达式：
    ```c
    ((1U << k) - 1) << j
    ```
    这里，`(1U << k) - 1` 生成 `k` 个连续的 `1`，然后左移 `j` 位，将其放置在正确的位置上。
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
