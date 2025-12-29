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

*Instruction-Level Parallelism（ILP）* 指令级并行
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
  ```c
  void combine1(vec_ptr v, data_t *dest)
  {
      long int i;
      *dest = IDENT;
      for (i = 0; i < vec_length(v); i++) {
          data_t val;
          get_vec_element(v, i, &val);
          *dest = *dest OP val;
      }
  }
  ```
  对向量元素求：和（`+ / 0`）或积（`* / 1`）
- Combine1 的真实性能
  #three-line-table[
    | 数据类型   | 操作  | CPE |
    | ------ | --- | --- |
    | int    | add | $~$29 |
    | int    | mul | $~$29 |
    | double | add | $~$27 |
    | double | mul | $~$28 |
  ]
  #three-line-table[
    | 版本           | CPE    |
    | ------------ | ------ |
    | Combine1 -O1 | $~$12–13 |
  ]
  - 原因：
    - 函数调用
    - 边界检查
    - 每轮写内存
    - 严重数据依赖
  - 基本编译器优化
    - 使用命令行选项“-O1”实现基本优化
    - 程序员不用做什么，就会显著提高程序性能
    - 养成至少使用这个级别的优化
  - Combine1 仍然慢
    - *ILP 杀手*`*dest = *dest OP val;`
    - `*dest`：在内存，每次 load，每次 store
    - 每一轮：读后写依赖（RAW），严格串行，CPU 根本无法并行执行这些指令。
*性能度量：Cycles Per Element（CPE）*
- CPE = 每处理一个元素，消耗的 CPU cycle 数
  $
    T(n) = "CPE" times n + "Overhead"
  $
  斜率 = CPE，越小越好
*Basic Optimizations：Combine4*
```c
void combine4(vec_ptr v, data_t *dest)
{
    int i;
    int length = vec_length(v);
    data_t *d = get_vec_start(v);
    data_t t = IDENT;
    for (i = 0; i < length; i++)
        t = t OP d[i];
    *dest = t;
}
```
- Code Motion
  ```c
  int length = vec_length(v);
  ```
  - 不再每轮调用函数
- 去掉 bounds check
  ```c
  data_t *d = get_vec_start(v);
  ```
  - 直接拿到底层数组
  - 编译器不再担心越界
- 用临时变量累加
  ```c
  data_t t = IDENT;
  t = t OP d[i];
  ```
  - t 在寄存器里
- Combine4 的性能（飞跃）
  #three-line-table[
    | 版本           | int add | int mul | double add | double mul |
    | ------------ | ------- | ------- | ---------- | ---------- |
    | Combine1 -O1 | 12.0    | 12.0    | 12.0       | 13.0       |
    | *Combine4* | *2.0* | *3.0* | *3.0*    | *5.0*    |
  ]
  - 程序员优化
    - 代码移动
    - 减少不必要的函数调用
    - 减少不必要的存储器引用
  - ILP 视角下：为什么 Combine4 快这么多
    - `t` 在寄存器
    - `d[i]` 是连续内存
    - 编译器可以：提前 load，overlap 执行，hide latency

*从硬件视角重新理解 ILP*
- 现代 CPU 并行
  - Superscalar（超标量）= 同一周期发射多条指令
  - 超标量处理器可在单个时钟周期内发出并执行多个指令。这些指令从顺序指令流中提取，通常采用动态调度机制。
  - 优势：无需编程工作，超标量处理器即可利用大多数程序所具备的指令级并行性。
    - 顺序取指
    - 动态调度
    - 乱序执行
    - 多功能单元并行
- 以 Nehalem 为例
  - Nehalem 每个周期理论上可以同时干这些事
    #three-line-table[
      | 单元            | 数量 |
      | ------------- | -- |
      | Load          | 1  |
      | Store         | 1  |
      | 简单整数          | 2  |
      | 复杂整数（mul/div） | 1  |
      | FP Multiply   | 1  |
      | FP Add        | 1  |
    ]
    - Latency（延迟） ≠ Issue rate（吞吐）
    - FP mul：延迟 4–5 cycles，但 每 cycle 都能再发射一个
    - 只要没有依赖，就能“流水 + 并行”
- 程序员的真正任务
  - 修改代码，增加代码的并行度，减少代码中的数据相关，才能提供现代CPU发挥的空间

*x86-64 Compilation of Combine4*
- 回顾 Combine4 内层循环
  ```c
  t = t OP d[i];
  ```
  编译后的关键指令（整数乘）：
  ```asm
  imull (%rax,%rdx,4), %ecx  # t = t * d[i]
  ```
- 这是一个完全串行的计算
  ```
  (((((((1 * d[0]) * d[1]) * d[2]) ... ) * d[7])
  ```
  依赖链：
  - 第 i 次乘法，必须等第 i−1 次完成
  - ILP = 1
  #figure(
    image("pic/program-opt.pdf", page: 1, width: 80%),
    numbering: none,
  )
- Combine4 的 CPE 由 OP 的 latency 决定
  #three-line-table[
    | 操作      | CPE | Latency Bound |
    | ------- | --- | ------------- |
    | int add | 2.0 | 1.0           |
    | int mul | 3.0 | 3.0           |
    | FP add  | 3.0 | 3.0           |
    | FP mul  | 5.0 | 5.0           |
  ]
  Combine4 = 串行计算 = latency bound

*Loop Unrolling（循环展开）：第一步打破瓶颈*
- Unroll 2×（但不改变结合方式）
  ```c
  void unroll2a_combine(vec_ptr v, data_t *dest)
  {
    int length = vec_length(v);
    int limit = length-1;
    data_t *d = get_vec_start(v);
    data_t x = IDENT;
    int i;
    /* Combine 2 elements at a time */
    for (i = 0; i < limit; i+=2) {
      x = (x OP d[i]) OP d[i+1];
    }
    /* Finish any remaining elements */
    for (; i < length; i++) {
      x = x OP d[i];
    }
    *dest = x;
  }
  ```
  ```c
  x = (x OP d[i]) OP d[i+1];
  ```
  看起来像 2 倍并行，实际上不是，依赖仍然是：
  ```
  x → (x OP d[i]) → ((x OP d[i]) OP d[i+1])
  ```
  依赖链长度没变
  #three-line-table[
    | 方法        | int mul | FP add | FP mul |
    | --------- | ------- | ------ | ------ |
    | Combine4  | 3.0     | 3.0    | 5.0    |
    | Unroll 2× | *1.5* | 3.0    | 5.0    |
  ]
  为什么只有 int mul 变快？
  - 编译器对整数乘：能做更 aggressive 的调度
  - 但 FP：受浮点语义限制

*Reassociation（重结合）：真正释放 ILP*
- Reassociation（重结合）
  ```c
  void unroll2aa_combine(vec_ptr v, data_t *dest)
  {
    int length = vec_length(v);
    int limit = length-1;
    data_t *d = get_vec_start(v);
    data_t x = IDENT;
    int i;
    /* Combine 2 elements at a time */
    for (i = 0; i < limit; i+=2) {
      x = x OP (d[i] OP d[i+1]);
    }
    /* Finish any remaining elements */
    for (; i < length; i++) {
      x = x OP d[i];
    } *
    dest = x;
  }
  ```
- 核心变化
  ```c
  x = x OP (d[i] OP d[i+1]);
  ```
  对比之前
  ```c
  x = (x OP d[i]) OP d[i+1];
  ```
- 数学上等价，执行上完全不同
  - 之前（串行）：
    ```
    x
     ↓
    * d[i]
     ↓
    * d[i+1]
    ```
  - 现在（并行）：
    ```
      d[i]   d[i+1]
        \     /
        (OP)
           \
            x OP (...)
    ```
    `d[i] OP d[i+1]`和 x 无关，可以提前算
  #figure(
    image("pic/program-opt.pdf", page: 2, width: 80%),
    numbering: none,
  )
- ILP 从哪里来？
  - 当前 `iteration` 的 `(d[i] OP d[i+1])`
  - 不依赖上一次 `x`
  - 可以与：上一次 `x OP (...)`并行执行
- 性能结果
  #three-line-table[
    | 方法                      | int mul | FP add  | FP mul  |
    | ----------------------- | ------- | ------- | ------- |
    | Combine4                | 3.0     | 3.0     | 5.0     |
    | Unroll 2×               | 1.5     | 3.0     | 5.0     |
    | *Unroll 2× + reassoc* | *1.5* | *1.5* | *3.0* |
  ]
- 理论解释
  - N 个元素
  - OP latency = D
  - 每次处理 2 个元素
    $
      T approx (N/2 + 1) D => "CPE" = D/2
    $
- 关键警告：为什么编译器不自动做？
  - 浮点运算 ≠ 结合律成立
    ```
    (a + b) + c ≠ a + (b + c)
    ```
    - 由于舍入误差
    - 编译器 不能擅自重结合
    - 即使性能会更好

*Separate Accumulators（最“干净”的并行方式）*
- Separate Accumulators
  ```c
  void unroll2a_combine(vec_ptr v, data_t *dest)
  {
    int length = vec_length(v);
    int limit = length-1;
    data_t *d = get_vec_start(v);
    data_t x0 = IDENT;
    data_t x1 = IDENT;
    int i;
    /* Combine 2 elements at a time */
    for (i = 0; i < limit; i+=2) {
      x0 = x0 OP d[i];
      x1 = x1 OP d[i+1];
    }
    /* Finish any remaining elements */
    for (; i < length; i++) {
      x0 = x0 OP d[i];
    } *
    dest = x0 OP x1;
  }
  ```
  - 两个独立累加器
    ```c
    x0 = x0 OP d[i];
    x1 = x1 OP d[i+1];
    ```
    x0 只依赖 x0，x1 只依赖 x1，两条完全独立的依赖链
  - 循环结束再合并
    ```
    *dest = x0 OP x1;
    ```
  #figure(
    image("pic/program-opt.pdf", page: 3, width: 80%),
    numbering: none,
  )
- 性能结果
  #three-line-table[
    | 方法                   | int add | int mul | FP add  | FP mul  |
    | -------------------- | ------- | ------- | ------- | ------- |
    | Combine4             | 2.0     | 3.0     | 3.0     | 5.0     |
    | Unroll 2×            | 2.0     | 1.5     | 3.0     | 5.0     |
    | Reassoc              | 2.0     | 1.5     | 1.5     | 3.0     |
    | *2× Parallel Acc*  | *1.5* | *1.5* | *1.5* | *2.5* |
    | Latency Bound        | 1.0     | 3.0     | 3.0     | 5.0     |
    | *Throughput Bound* | *1.0* | *1.0* | *1.0* | *1.0* |
  ]
  已经接近吞吐极限
  - 它“更干净”，不依赖：
    - 浮点结合律
    - 语义直观
    - 编译器更容易理解
    - 工程上更安全

*Unrolling & Accumulating：一般化思想*
- 抽象模型
  - 参数化的优化框架：
  - L = Unrolling factor（展开因子）
    - 每次循环处理 L 个元素
  - K = 累加器个数
    - 同时维护 K 个独立的部分结果
  - 约束：
    - L 必须是 K 的倍数
  - 例如：
    - L = 8，K = 4
    - 一次迭代：8 个元素 → 4 条独立依赖链
- 这件事在“物理上”意味着什么？
  - 展开（L）
    - 减少 loop 控制开销
    - 提供更多“可并行指令”
  - 多累加器（K）
    - 缩短关键路径（critical path）
    - 打破循环携带依赖
  - 两者结合 = 最大化 ILP
- 但并不是越大越好（限制）
  - 收益递减（Diminishing returns）
    - 达到吞吐上限后
    - 再增加 K / L 没有用
  - 不能超过功能单元吞吐能力
    - FP multiply：1 / cycle
    - 再多并行，也只能 1 / cycle
  - 短向量反而变慢
    - 循环展开代码多
    - prologue / epilogue 成本高
  - 尾部处理是串行的
    ```c
    for (; i < length; i++)
      ...
    ```

*案例一：Double FP Multiply*
- 硬件背景（Nehalem）
  - FP mul latency = 5 cycles
  - Throughput = 1 / cycle
  - 也就是说：
    - 串行累乘 → CPE ≥ 5
    - 理论极限 → CPE = 1
  #figure(
    image("pic/program-opt.pdf", page: 4, width: 80%),
    numbering: none,
  )
  瓶颈从 latency → throughput 的转折点，发生在 K 足够大时
*案例二：Integer Add（“最容易”的情况）*
- 硬件参数
  - Latency = 1
  - Throughput = 1
  - 天生就是“完美并行”
  #figure(
    image("pic/program-opt.pdf", page: 5, width: 80%),
    numbering: none,
  )
  #three-line-table[
    | 运算    | 本质                      |
    | ----- | ----------------------- |
    | int + | throughput-limited      |
    | FP \*  | latency-limited（除非并行足够） |
  ]

*Achievable Performance：我们到底能快多少？*
- 三种“极限”
  #three-line-table[
    | 极限               | 含义             |
    | ---------------- | -------------- |
    | Latency Bound    | 串行依赖下的最低 CPE   |
    | Throughput Bound | 功能单元饱和时的最低 CPE |
    | Scalar Optimum   | 理论上标量代码最优      |
  ]
- 核心结论
  - 最多可比“未优化代码”快 29×
  - 理解依赖，写并行友好的代码
*Using Vector Instructions（SIMD：下一层并行）*
- 到目前为止，我们做的都是：标量 ILP（instruction-level）
- SIMD
  - 一条指令
  - 同时处理多个数据元素
  - 例如：SSE：128-bit，4×int，2×double
- 理论最优性能
  #three-line-table[
    | 类型      | Scalar Opt | Vector Opt |
    | ------- | ---------- | ---------- |
    | int add | 1.00       | *0.25*   |
    | int mul | 1.00       | *0.53*   |
    | FP add  | 1.00       | *0.53*   |
    | FP mul  | 1.00       | *0.57*   |
  ]
  SIMD + ILP = 现代 CPU 的完全体

*代码级并行度*
- 循环展开（Loop Unrolling）
  - 降低 loop overhead
  - 提供更多独立指令
- 重新结合（Reassociation）
  - 减少关键路径长度
  - FP 下要注意语义变化
- 多累加器（Parallel Accumulators）
- 分支预测
  - 避免不可预测分支
  - 特别是在内层循环
- 存储器性能
  - cache-friendly 访问模式
  - 连续访问 > 随机访问

*Getting High Performance*
- 用好编译器
  - 至少 -O1
  - 默认不开优化 = 浪费生命
- 不要“做蠢事”
  - 隐式 O(N²)
  - 循环里函数调用
  - 别名内存访问
  - 内层循环写内存
- 盯住 innermost loop
  - 90% 的时间，程序在 10% 的代码里
- 为机器调代码（不是为“美观”）
  - 利用 ILP
  - 避免不可预测分支
  - 为 cache 和 SIMD 铺路

== Dealing with Conditionals

*为什么条件分支会影响性能*
- 现代 CPU 是“猜着跑的”
  - 分支预测（Branch Prediction）
  - 在条件结果出来之前就：取指，解码，执行
    - 如果预测正确：几乎没有代价
    - 如果预测失败（mispredict）：清空流水线，回滚寄存器，重新取指
  - 代价通常：10～20+ cycles（甚至更高）
*什么样的条件最“危险”*
- 不可预测的条件
  ```c
  if (rand() & 1)
    sum += a[i];
  ```
  预测器几乎没法学
- 数据相关分支
  ```c
  if (a[i] > threshold)
    sum += a[i];
  ```
  数据分布复杂，输入变化大，预测准确率低
- 高度可预测的分支（安全）
  ```c
  for (i = 0; i < n; i++) {
      ...
  }
  ```
  循环分支，几乎 100% 可预测
*分支 vs. 无分支（Branch vs. Branchless）*
- 经典例子：求正数个数
  ```
  if (x > 0)
    cnt++;
  ```
  若 x 随机，分支预测很差
- 无分支版本（推荐）
  ```
  cnt += (x > 0);
  ```
  - 条件表达式结果：0 或 1
  - 总是执行加法，无分支
  - 性能更稳定
  - 编译器生成：
    - `setcc`
    - 或条件移动 `cmov`
*条件移动（Conditional Move, CMOV）*
- 现代 x86 支持：
  ```asm
  cmovg   %r1, %r2
  ```
  含义：
  - 不跳转
  - 根据条件选择结果
- 优点
  - 没有 pipeline flush
  - 适合短、简单的条件操作
- 缺点
  - 两条路径都可能被计算
- 不适合：
  - 重计算
  - 有副作用的代码

*什么时候“消除分支”反而更慢？*
- 如果分支高度可预测
  ```
  if (x == 0)  // 99.9% 为真
    ...
  ```
  - 分支预测 ≈ 100%
  - 无分支版本：反而多做无用计算
  - 保留分支更好

*Conditionals 与 ILP 的关系（核心联系）*
- 分支的“隐藏成本”
  - 分支 = 控制依赖
  - 控制依赖：
    - 限制乱序执行
    - 阻碍 ILP
- 无分支代码：
  - 更多 straight-line code
  - CPU 更容易：
    - 重排
    - 并行执行
- 这就是为什么高性能代码偏爱无分支
