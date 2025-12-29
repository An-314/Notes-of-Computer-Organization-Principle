#import "@preview/scripst:1.1.1": *

= Program Optimization

== Overview

- 性能 ≠ 只有 Big-O
  - 同一个 O(n) 算法，性能可以差 10 倍以上
  - 在抽象层面完全等价，但在编译器生成的代码、缓存行为、指令流水上可能差很多
- 优化是“多层次”的
  - 优化不是单点行为
  #three-line-table[
    | 层次   | 举例                   |
    | ---- | -------------------- |
    | 算法   | O(n²) → O(n log n)   |
    | 数据表示 | array vs linked list |
    | 过程   | 函数调用、参数传递            |
    | 循环   | 循环不变量、访存模式           |
  ]
- 须理解“系统”才能优化
  - 编译器怎么翻译 C → 汇编
  - CPU 怎么执行指令（流水线、缓存）
  - 性能瓶颈如何测量
  - 如何在不破坏代码模块化和通用性的前提下提升性能

*Optimizing Compilers：编译器优化*
- 编译器做的优化
  - 寄存器分配
  - 指令调度（Instruction Scheduling）
  - 死代码消除
  - 局部小优化
- 编译器通常不做的事
  - 不会改变算法复杂度
    - 大 O 的优化，永远是程序员的责任
- 优化障碍（Optimization Blockers）
  - 内存别名（Aliasing）
    ```c
    void f(int *a, int *b) {
        *a = 1;
        *b = 2;
    }
    ```
    可能`a == b`，不能重排
  - 过程副作用（Side Effects）
    ```c
    x = f();
    y = g();
    ```
    `f()`可能会修改全局变量，编译器不乱动顺序

*Limitations of Optimizing Compilers*
- 编译器的根本约束
  - 绝不能改变程序语义
  - 编译器一律当作最坏情况
- 程序员知道的事 ≠ 编译器知道的事
  - `int x;  // 实际只会是 0~9`
  - 对编译器来说：`x` 是 32 位任意整数，可能溢出，可能为负，所以它不敢做激进优化
- 分析范围有限
  - 主要是函数内（intra-procedural）
  - 全程序分析（inter-procedural）太复杂，编译器通常不做
- 静态分析的天花板
  - 编译器不知道运行时输入
  - 只能基于类型和语法
- 当不确定时，编译器一定保守

== Generally Useful Optimizations

Optimizations that you or the compiler should do regardless of processor / compiler

=== Code motion/precomputation

*Code Motion（代码移动）*
- 原始代码
  ```c
  void set_row(double *a, double *b, long i, long n)
  {
    long j;
    for (j = 0; j < n; j++)
      a[n*i+j] = b[j];
  }
  ```
  `n*i` 每次循环都算，实际上是循环不变量
- 人工优化后
  ```c
  int ni = n * i;
  for (j = 0; j < n; j++)
      a[ni + j] = b[j];
  ```
  `n*i` 只算一次，循环内只剩加法
- 编译器生成的进一步优化
  ```c
  double *rowp = a + ni;
  for (j = 0; j < n; j++)
      *rowp++ = b[j];
  ```
  用指针递增替代索引，减少地址计算，提高流水线效率

Reduce frequency with which computation performed
- If it will always produce same result
- *Especially moving code out of loop*

=== Strength reduction

*Reduction in Strength（强度削弱）*

*用便宜指令替代昂贵指令*
- 经典例子
  ```c
  16 * x   →   x << 4
  ```
  - 是否值得，取决于架构
  - 在老 CPU 上很重要
    - On Intel Nehalem, integer multiply requires 3 CPU cycles
  - 在现代 CPU 上乘法也不算太慢（但仍可能影响流水）
- 循环中的乘法消除
  ```c
  for (i = 0; i < n; i++)
    for (j = 0; j < n; j++)
      a[n*i + j] = b[j];
  ```
  改成：
  ```c
  int ni = 0;
  for (i = 0; i < n; i++) {
      for (j = 0; j < n; j++)
          a[ni + j] = b[j];
      ni += n;
  }
  ```
  用加法累积，避免 `n*i` 反复计算

=== Sharing of common subexpressions

*Share Common Subexpressions（公共子表达式）*
- 原始（很常见、但慢）
  ```c
  /* Sum neighbors of i,j */
  up =val[(i-1)*n + j ];
  down = val[(i+1)*n + j ];
  left = val[i*n + j-1];
  right = val[i*n + j+1];
  sum = up + down + left + right;
  ```
  `i*n` 被算了 3 次，每次都是乘法
  ```asm
  leaq  1(%rsi), %rax  # i+1
  leaq  -1(%rsi), %r8  # i-1
  imulq %rcx, %rsi     # i*n
  imulq %rcx, %rax     # (i+1)*n
  imulq %rcx, %r8     # (i-1)*n
  addq  %rdx, %rsi     # i*n+j
  addq  %rdx, %rax     # (i+1)*n+j
  addq  %rdx, %r8      # (i-1)*n+j
  ```
  多次`imulq`，地址计算复杂
- 优化后
  ```c
  long inj = i*n + j;
  up = val[inj - n];
  down = val[inj + n];
  left = val[inj - 1];
  right = val[inj + 1];
  sum = up + down + left + right;
  ```
  只剩 1 次乘法，剩下都是加减
  ```asm
  imulq %rcx, %rsi     # i*n
  addq  %rdx, %rsi     # i*n+j
  movq  %rsi, %rax     # i*n+j
  subq  %rcx, %rax     # i*n+j-n
  leaq  (%rsi,%rcx), %rcx # i*n+j+n
  ```
  `imulq` 数量显著减少，`leaq` + `addq` 为主
- 这是程序员最容易“赢编译器”的地方

=== Removing unnecessary procedure calls

*Inline Expansion（内联展开）*
- 小函数调用开销大
  - 参数传递
  - 跳转
  - 返回
- 适合内联的函数
  - 很小（几条指令）
  - 被频繁调用
- C 语言的`inline`关键字
- 编译器自动内联
  - 基于函数大小和调用频率
  - 现代编译器通常做得很好

*编译器优化方法小结*
- 代码移动（code motion)
  - 识别要执行多次（例如在循环里）但是计算结果不会改变的计算，将其移动到代码前面不会被多次执行的部分（循环外）。
- 替代运算
  - Replace costly operation with simpler one
- 减少过程调用
  - 内联函数
- 减少存储器引用
  - 引入临时变量
- 编译器总是偏于保守；因此，为了改进代码，程序员必须经常帮助编译器显式地完成代码的优化

== Optimization Blockers

*优化阻碍（Optimization Blocker）*

=== Procedure calls

*过程调用（Procedure Calls）*
- 问题引入：字符串转小写的函数
  ```c
  void lower(char *s)
  {
      int i;
      for (i = 0; i < strlen(s); i++)
          if (s[i] >= 'A' && s[i] <= 'Z')
              s[i] -= ('A' - 'a');
  }
  ```
  直觉上：一个 for 循环，每个字符检查一次，看起来是 O(N)
  - 真实性能：O(N²)
- 关键原因：`strlen(s)` 在循环里
  ```c
  for (i = 0; i < strlen(s); i++)
  ```
  每一次循环，都要调用一次 `strlen(s)`
- 把 for 循环“还原”为 goto 形式，从语法糖退回到底层执行模型
  ```c
  int i = 0;
  if (i >= strlen(s))
      goto done;
  loop:
      if (s[i] >= 'A' && s[i] <= 'Z')
          s[i] -= ('A' - 'a');
      i++;
      if (i < strlen(s))
          goto loop;
  done:
  ```
  `strlen(s)` 在循环条件里，被执行了每一轮
- `strlen`的实现
  ```c
  size_t strlen(const char *s)
  {
      size_t length = 0;
      while (*s != '\0') {
          s++;
          length++;
      }
      return length;
  }
  ```
  每次调用都要从头遍历字符串，直到遇到 `\0`
  - 字符串长度为 N
    - 第 k 次调用 strlen：需要扫描 N - (k-1) 个字符
    - 总共扫描了 N + (N-1) + (N-2) + ... + 1 = O(N²)
- 正确的优化方式：代码移动（Code Motion）
  ```c
  void lower(char *s)
  {
      int i;
      int len = strlen(s);  // 提前计算字符串长度
      for (i = 0; i < len; i++)
          if (s[i] >= 'A' && s[i] <= 'Z')
              s[i] -= ('A' - 'a');
  }
  ```
  `strlen(s)` 只调用一次，整体变为 O(N)
- 关键问题：为什么编译器没有帮我们做这个优化？
  - 编译器无法确定 `strlen(s)` 是否有副作用
  - `s` 可能指向全局变量，`strlen` 可能被重写
  - 编译器只能假设最坏情况，不能擅自移动代码
  - *编译器把过程调用当作黑盒（black box）*
- 编译器对过程调用的“恐惧”，编译器必须假设最坏情况：
  - 函数可能有副作用（Side Effects）
    ```c
    size_t strlen(const char *s)
    {
        lencnt++;   // 修改全局变量
        ...
    }
    ```
    每次调用都会改变全局状态，移动调用位置 → 改变程序行为
  - 返回值可能不稳定
    ```c
    strlen(s)
    ```
    - 可能依赖：全局变量，多线程状态，I/O
    - 即使你知道“它不会变”
    - 编译器不能假设
  - `lower` 与 `strlen` 可能“交互”
    - 例如：
      - `lower` 改写了 `s`
      - `strlen` 依赖 `s`
      - 编译器 无法证明“安全”
- 解决办法（Remedies）
  - 方法 1：使用 inline / 编译器内联
    - GCC 在 -O2 下：
    - 会把一些小函数（如 strlen）直接展开
    - 展开后：
      - 不再是“过程调用”
      - 编译器能看到函数体
      - 就敢做代码移动
    - 不是所有函数都能 / 都会被内联
  - 方法 2：程序员手动优化（最可靠）
    - 显式做代码移动

=== Memory aliasing

*Memory Aliasing（存储器别名）*
- 问题代码：按行求和
  ```c
  /* Sum rows of n X n matrix a and store in vector b */
  void sum_rows1(double *a, double *b, long n) {
      long i, j;
      for (i = 0; i < n; i++) {
          b[i] = 0;
          for (j = 0; j < n; j++)
              b[i] += a[i*n + j];
      }
  }
  ```
  直觉上这是一个很正常的写法：外层：每一行，内层：累加该行元素，`b[i]`保存行和
- 编译器生成内层循环的汇编
  ```asm
  .L53:
      addsd   (%rcx), %xmm0     # xmm0 += a[i*n + j]
      addq    $8, %rcx          # 指针前移
      decq    %rax
      movsd   %xmm0, (%rsi,%r8,8)  # 写回 b[i]
      jne     .L53
  ```
  `movsd %xmm0, (%rsi,%r8,8)` 每一轮循环，都把部分和写回内存 `b[i]`
  - 可以用一个寄存器累加，循环结束再写一次 `b[i]`，`sum_rows2`
- 为什么编译器在 `sum_rows1` 里不敢用寄存器累加？
  - 因为 `a` 和 `b` 可能“别名”（aliasing）
  - 可能 `a` 和 `b` 指向同一块内存
  - 每次写 `b[i]` 可能会影响后续读 `a[i*n + j]`
  - 编译器无法证明“安全”
  - 例如
    ```c
    double A[9] = {
        0, 1, 2,
        4, 8, 16,
        32, 64, 128
    };
    double *B = A + 3;   // 注意！
    ```
    ```
    A: [0, 1, 2, | 4, 8, 16, | 32, 64, 128]
                  ^
                  B[0]
    ```
    调用
    ```c
    sum_rows1(A, B, 3);
    ```
    计算累加会受到`B`写入的影响
    - 如果编译器擅自优化成：
      ```c
      double val = 0;
      for (j = 0; j < n; j++)
          val += a[i*n + j];
      b[i] = val;
      ```
    - 那意味着：中间过程不再写回 `b[i]`，也就不会影响 `a` 的后续读取，程序行为会改变
- 解除这个优化阻碍，改进版本：`sum_rows2`
  ```c
  void sum_rows2(double *a, double *b, long n) {
      long i, j;
      for (i = 0; i < n; i++) {
          double val = 0;
          for (j = 0; j < n; j++)
              val += a[i*n + j];
          b[i] = val;
      }
  }
  ```
  - 引入局部变量 `val`
  - 在内层循环中：不再写 `b[i]`，只用寄存器累加
  - 循环结束：一次性写回
  汇编`sum_rows2`内层循环
  ```asm
  .L66:
      addsd   (%rcx), %xmm0   # 只做浮点加
      addq    $8, %rcx
      decq    %rax
      jne     .L66
  ```
  - 没有 `movsd` 写内存
  - 内层循环：纯寄存器计算，`cache` / `pipeline` 极其友好
- *C语言的内存别名*
  - C允许：指针算术，直接内存访问，编译器无法静态证明不别名
  - 程序员用代码结构“告诉”编译器：不会别名
    - 引入局部变量
    - 在循环中只操作局部变量
    - 循环结束再写回内存
*小结*
- 阻碍编译器优化代码的因素
  - 函数调用
  - 存储器别名使用
- 编译器总是偏于保守；因此，为了改进代码，程序员必须经常帮助编译器显式地完成代码的优化。

== Exploiting Instruction-Level Parallelism

算法不变、语义不变，只改代码结构，性能可以提升一个数量级而且——编译器往往做不到这一步

*Instruction-Level Parallelism（ILP）*
- 需要对现代处理器有基本认识
  - 现代 CPU：
    - 乱序执行
    - 多发射（superscalar）
    - 多个功能单元
      - 整数 ALU
      - 浮点加法器
      - 浮点乘法器
      - Load / Store 单元
    - 只要指令之间“没有数据依赖”，就可以并行执行
- 性能受限于「数据依赖」
  - 这是 ILP 的核心瓶颈：
    ```c
    x = x + a[i];
    ```
    下一次 `x = x + a[i+1]`，必须等上一次 `x` 算完，串行依赖，ILP = 1
- 简单变换 → 巨大性能提升
  - 但：这些变换通常违反浮点运算的结合律 / 分配律；编译器不敢擅自改
  - 所以：ILP 优化，往往只能由程序员完成

*Benchmark 示例：向量计算*
- 数据结构
  ```c
  typedef struct {
      int len;
      double *data;
  } vec;
  ```
- 访问元素的接口函数
  ```c
  double get_vec_element(vec_ptr v, int idx, double *val)
  {
      if (idx < 0 || idx >= v->len)
          return 0;
      *val = v->data[idx];
      return 1;
  }
  ```
  这是一个*安全但昂贵*的接口：边界检查，函数调用，指针间接访问
- Benchmark 计算：combine1
  ```
  ```

== Dealing with Conditionals
