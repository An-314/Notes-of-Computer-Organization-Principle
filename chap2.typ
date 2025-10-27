#import "@preview/scripst:1.1.1": *

= Machine-Level Programming

== Basics

=== History of Intel processors and architectures

*Intel x86 处理器*
- 主导了笔记本电脑、台式机和服务器市场
- 采用“渐进式”设计思路。
  - 一直向后兼容（backwards compatible），可以追溯到 1978 年推出的 8086 处理器
  - 随着时间推移，不断增加新功能
    - 如今的官方文档分为 3 卷，总共约 5000 页
- x86 属于复杂指令集计算机 Complex Instruction Set Computer (CISC)
- 对比：精简指令集计算机 Reduced Instruction Set Computer (RISC)
  - RISC：指令数量很少，每条指令的模式也非常简单
  - RISC 计算机通常运行速度很快（不过英特尔在速度上仍占优势）
  - 当前正出现“RISC 复兴”（例如 ARM、RISC-V），尤其在低功耗领域

#note[
  指令集（Instruction Set Architecture, ISA）：指令集（Instruction Set）是处理器能理解和执行的全部命令集合

  #three-line-table[
    | 层级                    | 示例                  | 说明               |
    | :-------------------- | :------------------ | :--------------- |
    | *高级语言*              | C, C++, Python      | 程序员编写的源代码        |
    | *编译器*               | gcc, clang          | 把高级语言翻译成汇编代码     |
    | *汇编语言*              | `mov`, `add`, `jmp` | 是指令集的“人类可读”形式    |
    | *机器码（Machine Code）* | `10110000 00000001` | 真正被 CPU 执行的二进制指令 |
    | *硬件（CPU）*           | Intel, ARM, RISC-V  | 按照指令集定义执行操作      |
  ]
  ISA 是软件与硬件之间的接口。上层（编译器、程序）依据 ISA 生成代码；下层（硬件c）按照 ISA 执行这些代码。

  一个完整的 ISA 通常定义以下部分：
  - 指令集（Instruction Set）
    - 比如算术指令（`add`、`sub`）、逻辑指令（`and`、`or`）、跳转（`jmp`）、加载/存储（`mov`、`load`）等
  - 寄存器集合（Registers）
    - CPU 内部的高速存储单元，如 x86 的 `eax, ebx, rsp` 等
  - 寻址模式（Addressing Modes）
    - 指令如何访问内存，如立即数、寄存器间接寻址、基址加偏移等
  - 数据类型（Data Types）
    - CPU 支持的操作数据类型，如字节（8-bit）、字（16-bit）、双字（32-bit）、浮点数等
  - 控制流机制
    - 如何进行条件跳转、函数调用、异常处理等
  - 存储模型
    - 栈的结构、调用约定（calling convention）、内存对齐规则等
]

#newpara()

*x86 的“克隆者”：AMD（高级微设备公司）*
- 历史阶段
  - AMD 在早期一直紧随 Intel 的步伐
  - 性能略慢，但价格便宜得多
- 后来
  - 从数字设备公司（DEC）以及其他当时走下坡路的公司中招募了一批顶级芯片设计师
  - AMD 推出了 Opteron 处理器——成为 Intel Pentium 4 的强劲对手
  - AMD 自行开发了 *x86-64*（也称为 AMD64）——将 x86 架构扩展到 64 位
- 最近几年
  - Intel 后来重整旗鼓，恢复了竞争力
    - 从 1995 到 2011 年，Intel 是全球最领先的半导体制造厂（fab）
  - 在 2018–2023 年间，Intel 与三星在半导体营收第一的位置上互相交替
    - 在性能方面，Intel 与 AMD 之间也轮流领先
  - 而在更广泛的“计算市场”中，非 x86 架构的 GPU（图形处理器）——尤其是 Nvidia——已经成为主导力量

*一些说明*
- 处理器的性能远超存储器，通常不再是瓶颈
- 处理器的性能遇到瓶颈
  - 主频率（clock rate）提升缓慢

=== C, assembly, machine code

*C 语言、汇编语言与机器代码*
- 程序源代码保存在文件 `p1.c` 和 `p2.c` 中
- 使用命令编译：
  ```bash
  gcc -Og p1.c p2.c -o p
  ```
  - `-O` 选项启用优化
  - `-g` 选项启用调试信息
  - `-o` 选项指定输出文件名
  - 生成的可执行文件 `p` 包含机器代码
- 编译过程分为多个阶段
  ```
  C 源程序 (p1.c, p2.c)
  ↓  编译器 (gcc -Og -S)
  汇编程序 (p1.s, p2.s)
  ↓  汇编器 (as 或 gcc -c)
  目标文件 (p1.o, p2.o)
  ↓  链接器 (ld 或 gcc)
  可执行文件 (p)
  ```
  还可以链接 静态库 (`.a`)，例如标准 C 库或自己写的函数库
- 整体流程总结
  #three-line-table[
    | 阶段                  | 输入         | 输出     | 工具              | 说明                      |
    | :------------------ | :--------- | :----- | :-------------- | :---------------------- |
    | 预处理 (Preprocessing) | `.c`       | `.i`   | `gcc -E`        | 展开 `#include`、`#define` |
    | 编译 (Compilation)    | `.i`       | `.s`   | `gcc -S`        | C → 汇编                  |
    | 汇编 (Assembly)       | `.s`       | `.o`   | `gcc -c` 或 `as` | 汇编 → 机器码                |
    | 链接 (Linking)        | `.o`, `.a` | 可执行文件  | `ld` 或 `gcc`    | 合并、地址绑定                 |
    | 执行 (Execution)      | 可执行文件      | 运行中的进程 | 操作系统            | CPU 执行机器指令              |
  ]
  #three-line-table[
    | 文件类型  | 扩展名          | 内容          | 是否可读 |
    | :---- | :----------- | :---------- | :--- |
    | 源代码   | `.c`         | C 语言程序      | ✅    |
    | 汇编代码  | `.s`         | 汇编程序        | ✅    |
    | 目标文件  | `.o`         | 二进制机器码，未链接  | ❌    |
    | 静态库   | `.a`         | 多个 `.o` 的打包 | ❌    |
    | 可执行文件 | 无扩展名或 `.out` | 可直接运行       | ❌    |
  ]

*编译为汇编代码*
- C 源程序（`sum.c`）
  ```c
  long plus(long x, long y);

  void sumstore(long x, long y, long *dest) {
      long t = plus(x, y);
      *dest = t;
  }
  ```
- 生成的 x86-64 汇编代码（由编译器生成）
  ```asm
  sumstore:
      pushq   %rbx
      movq    %rdx, %rbx
      call    plus
      movq    %rax, (%rbx)
      popq    %rbx
      ret
  ```
  #three-line-table[
    | 汇编指令                | 含义                            | 解释                                     |
    | :------------------ | :---------------------------- | :------------------------------------- |
    | `sumstore:`         | 标签（函数名）                       | 表示函数的入口地址                              |
    | `pushq %rbx`        | 把寄存器 `rbx` 压入栈                | 保存调用者寄存器（callee-saved register）        |
    | `movq %rdx, %rbx`   | 把第三个参数（`dest`）复制到 `rbx`       | 因为稍后 `rdx` 可能被覆盖，先保存起来                 |
    | `call plus`         | 调用函数 `plus`                   | 参数已在寄存器中传递（`x` → `%rdi`, `y` → `%rsi`） |
    | `movq %rax, (%rbx)` | 把函数返回值 `%rax` 存入内存地址 `(%rbx)` | 即 `*dest = t;`                         |
    | `popq %rbx`         | 恢复之前保存的寄存器                    | 对称于 `pushq`                            |
    | `ret`               | 返回                            | 函数执行结束，返回调用者                           |
  ]
  - 参数与寄存器对应关系（System V AMD64 ABI）在 Linux x86-64 系统中，函数参数通过寄存器传递（而不是栈）：
    #three-line-table[
      | 参数顺序      | 寄存器                  | 示例（`sumstore(x, y, dest)`） |
      | :-------- | :------------------- | :------------------------- |
      | 第 1 个参数   | `%rdi`               | x                          |
      | 第 2 个参数   | `%rsi`               | y                          |
      | 第 3 个参数   | `%rdx`               | dest                       |
      | 第 4–6 个参数 | `%rcx`, `%r8`, `%r9` | —                          |
      | 返回值       | `%rax`               | `plus()` 的结果               |
    ]
  - 调用过程可视化
    ```asm
    sumstore(x, y, dest):
      [寄存器状态]
      x -> %rdi
      y -> %rsi
      dest -> %rdx

      pushq %rbx        ; 保存 rbx
      movq %rdx, %rbx   ; 备份 dest
      call plus         ; 调用 plus(x, y)
      movq %rax, (%rbx) ; *dest = plus(x, y)
      popq %rbx
      ret
    ```
- 如何生成这份汇编文件
  ```bash
  gcc -Og -S sum.c -o sum.s
  ```
- 注意事项：不同平台上的汇编结果可能差异很大（例如 Andrew Linux、MacOS、Shark 机器），因为不同版本的 `gcc`、不同操作系统、不同编译选项都会影响汇编生成。
- 真实的汇编代码通常比手写的更复杂
  ```asm
      .globl sumstore
      .type sumstore, @function
  sumstore:
  .LFB35:
      .cfi_startproc
      pushq  %rbx
      .cfi_def_cfa_offset 16
      .cfi_offset 3, -16
      movq   %rdx, %rbx
      call   plus
      movq   %rax, (%rbx)
      popq   %rbx
      .cfi_def_cfa_offset 8
      ret
  .cfi_endproc
  .LFE35:
      .size sumstore, .-sumstore
  ```
  - 以点 `.` 开头的多为汇编指示（assembler directives）
    - 这些是给汇编器/链接器/调试器看的元数据或布局信息，不是CPU 执行的指令
    - `.globl sumstore` 声明 sumstore 为全局可见符号（导出给链接器，其他目标文件可以引用）
    - `.type sumstore, @function` 指定符号类型为函数（便于链接器、调试器识别，影响符号表/重定位）
    - `.size sumstore, .-sumstore` 声明该函数的大小：从标签 `sumstore` 到当前位置的字节数（`. - sumstore` 是地址差）
    - `.cfi_*` 一组（Call Frame Information）给异常栈回溯/调试器/栈展开器（DWARF CFA/CFI）使用的元信息，告诉它们“栈在哪里”“寄存器被保存在栈的哪个偏移”
    - `.LFB35:`、`.LFE35:` 以 `.L` 开头的本地临时标签（local labels），链接后通常不导出。`FB`/`FE` 可理解为 Function Begin/End 的内部标记，供 CFI/调试信息引用
*目标代码*
- *Assembler（汇编器）*
  - 汇编器负责把 `.s` 文件（汇编代码）翻译成 `.o` 文件（目标代码）
  - 每个指令是二进制编码的
  - 几乎是完成的可执行文件，但还缺少链接
  ```
  0x0400595:  0x53
      0x48
      0x89
      0xd3
      0xe8
      0xf2
      0xff
      0xff
      0xff
      0x48
      0x89
      0x03
      0x5b
      0xc3
  ```
  - 共有 14 条指令
  - 每条指令由 1 到多字节组成
  - 起始地址为 `0x0400595`
    ```asm
    pushq %rbx       → 0x53
    movq %rdx, %rbx  → 0x48 0x89 0xd3
    call plus        → 0xe8 0xf2 0xff 0xff 0xff
    movq %rax,(%rbx) → 0x48 0x89 0x03
    popq %rbx        → 0x5b
    ret              → 0xc3
    ```
- *Linker（链接器）*
  - 解决跨文件引用（symbol resolution）
    - 比如这里的 `call plus`：
      - 在 `.o` 文件中，它只是“有个叫 `plus` 的函数要调用”；链接器需要在别的 `.o` 或库文件中找到它的真正地址
  - 合并多个目标文件
    - 把 `sumstore.o`、`plus.o` 和库文件（如标准库 `.a`）拼接成一个完整可执行文件
  - 添加运行时依赖
    - 比如静态链接的函数（`malloc`、`printf` 等）；
    - 或者动态链接的库（`.so` 文件），这些在程序运行时由操作系统加载
- *执行阶段*
  - 最终生成的可执行程序在磁盘上是完整的“映像”（image），包含 `.text`（代码段）、`.data`（数据段）、`.rodata`（常量）、`.bss` 等部分
  - 当执行程序时，操作系统把它加载到内存，然后从入口地址（如 `0x0400595`）开始运行
*机器指令的例子*
- C Code
  ```c
  *dest = t;
  ```
  把变量 `t` 的值存到指针 `dest` 指向的内存位置
- Assembly Code
  ```asm
  movq %rax, (%rbx)
  ```
  把 `%rax` 的内容写入内存地址 `M[%rbx]`
  #note[
    术语解释
    - `movq` 中的 q 表示 quad-word（四字，即 8 字节 = 64 位）；
    - `movl` 表示移动 4 字节；
    - `movw` 表示移动 2 字节；
    - `movb` 表示移动 1 字节；
    #three-line-table[
      | 名称                  | 字节数 | 位数 | 示例指令 |
      | :------------------ | :-- | :- | :--- |
      | byte                | 1   | 8  | movb |
      | word                | 2   | 16 | movw |
      | double word (dword) | 4   | 32 | movl |
      | quad word (qword)   | 8   | 64 | movq |
    ]
  ]
- Machine Code (Hex)
  ```
  0x40059e:  48 89 03
  ```
  #three-line-table[
    | 字节   | 含义                                            |
    | :--- | :-------------------------------------------- |
    | `48` | 前缀，表示使用 64 位寄存器（REX prefix）                   |
    | `89` | 操作码（opcode），表示“从寄存器移动到内存” (`mov r→m`)         |
    | `03` | 操作数编码（ModR/M 字节），指定目标内存 `(%rbx)` 与源寄存器 `%rax` |
  ]
*反汇编——把机器码还原成汇编指令*
- `objdump -d sum` 或 `gdb` 的 `disassemble`
  ```
  0000000000400595 <sumstore>:
      400595: 53                         push   %rbx
      400596: 48 89 d3                   mov    %rdx,%rbx
      400599: e8 f2 ff ff ff             callq  400590 <plus>
      40059e: 48 89 03                   mov    %rax,(%rbx)
      4005a1: 5b                         pop    %rbx
      4005a2: c3                         retq
  ```

=== Assembly Basics: Registers, operands, move

==== 汇编基础：寄存器、操作数与数据移动

*抽象层次*
#three-line-table[
  | 层次                      | 谁       | 关注点                       | 示例                                  |
  | :---------------------- | :------ | :------------------------ | :---------------------------------- |
  | *C programmer*        | 高级语言程序员 | 写清晰的算法与逻辑，不管底层寄存器或指令      | `for` 循环、函数、变量 (`int i, n = 10 …`)  |
  | *Assembly programmer* | 汇编程序员   | 直接操作寄存器、内存地址，用指令表达控制与数据流  | `movq %rax,(%rbx)`、`addq %rdi,%rsi` |
  | *Computer Designer*   | 硬件设计者   | 晶体管、电路、时钟、门级逻辑，实现汇编层看到的指令 | 加法器、寄存器文件、控制信号等                     |
]

#note(subname: [汇编层的核心：寄存器 + 操作数 + mov])[
  - 寄存器 (registers)：CPU 内部的小型高速存储单元。

    在 x86-64 里主要有 16 个通用寄存器：`%rax, %rbx, %rcx, %rdx, %rsi, %rdi, %rbp, %rsp, %r8 … %r15`
    - `%rax` 常作返回值寄存器
    - `%rdi/%rsi/%rdx/%rcx/%r8/%r9` 依次传前 6 个参数
    - `%rsp` 是栈顶指针
  - 操作数 (operands)：指令的输入与输出对象。
    - 立即数 (immediate)：常数，如 `$10` 或 `$0xFF`
    - 寄存器 (register)：如 `%rax`
    - 内存 (memory)：如 `(%rbx)` 或 `8(%rbp)`
  - 数据移动指令 mov
    - 基本格式：movq src, dest
    - 例子：
      - `movq %rax, %rbx`：把 `%rax` 的值复制到 `%rbx`
      - `movq $10, %rax`：把立即数 `10` 复制到 `%rax`
      - `movq (%rbx), %rax`：把 `%rbx` 指向的内存内容复制到 `%rax`
      - `movq %rax, (%rbx)`：把 `%rax` 的值复制到 `%rbx` 指向的内存
  ```
  C 代码          →  汇编 (指令、寄存器)     →  硬件执行
  -----------------------------------------------------------------
  t1 = t2;        →  movl %edx, %ecx         →  控制信号驱动寄存器写入
  nxt = t1 + t2;  →  addl %ecx, %edx         →  加法器计算并存结果
  if (...) {...}  →  cmp/jle/jmp             →  比较器 + 分支控制
  ```
]

#newpara()

*定义*
- *Architecture（体系结构）*又称 ISA：Instruction Set Architecture，指令集体系结构
  - 为了编写汇编或机器代码而必须了解的处理器设计部分
  - 例子包括：
    - 指令集规范（Instruction set specification）
    - 寄存器集合（Registers）
    #three-line-table[
      | 层面     | 示例                             |
      | :----- | :----------------------------- |
      | 支持的指令  | `add`, `mov`, `jmp`, `call`    |
      | 寄存器    | `%rax`, `%rbx`, `%rsp`, `%rip` |
      | 存储模型   | 栈结构、内存寻址模式                     |
      | 数据类型   | 8、16、32、64 位整数与浮点数             |
      | ABI 规则 | 参数传递、返回值方式                     |
    ]
    无论底层 CPU 如何实现，只要遵守 ISA，汇编程序都能正确运行
- *Microarchitecture（微架构）*
  - 处理器的具体实现方式
  - 例子包括：
    - 核心频率（core frequency）
    - 管线（pipelining）
    - 超标量（superscalar）执行
    - 分支预测（branch prediction）
    - 缓存层次结构（cache hierarchy）
  - 不同的微架构可以实现相同的 ISA
    - 例如 Intel 和 AMD 都实现了 x86-64 ISA，但它们的微架构不同
- *Code Forms（代码形式）*
  #three-line-table[
    | 形式                      | 定义                 | 示例                |
    | :---------------------- | :----------------- | :---------------- |
    | *Machine Code（机器码）*   | CPU 实际执行的字节序列（0/1） | `48 89 d3`        |
    | *Assembly Code（汇编代码）* | 机器码的文本表示形式，人类可读    | `movq %rdx, %rbx` |
  ]
- *Example ISAs（常见的指令集体系结构）*
  #three-line-table[
    | 厂商 / 架构                                | 特点                | 应用领域           |
    | :------------------------------------- | :---------------- | :------------- |
    | *Intel: x86, IA-32, Itanium, x86-64* | CISC 架构，功能丰富，兼容性强 | PC、服务器         |
    | *ARM*                                | RISC 架构，低功耗，高能效   | 手机、嵌入式、苹果 M 系列 |
    | *RISC-V*                             | 开源 RISC 架构，可自由扩展  | 教学、芯片研发、AI 芯片  |
  ]
  ```
    ┌─────────────────────────────┐
    │      Machine Code           │ ← CPU 真正执行
    ├─────────────────────────────┤
    │      Assembly Code          │ ← 汇编语言程序员编写
    ├─────────────────────────────┤
    │      ISA / Architecture     │ ← 指令集定义 (x86, ARM…)
    ├─────────────────────────────┤
    │      Microarchitecture       │ ← 实际硬件实现 (Cache, ALU)
    └─────────────────────────────┘
  ```

*汇编/机器码视角*
```
┌────────────────────┐
│               CPU                   │
│ ┌───────────────┐     │
│ │  Registers    │ ← 处理数据  │
│ │  Condition    │ ← 标志位    │
│ │  PC (RIP)     │ ← 下一条指令│
│ └───────────────┘      │
│                                      │
└────────────┬───────┘
                │
                ▼
         ┌──────────────┐
         │   Memory      │
         │ Code  (text)  │ ← 指令区
         │ Data  (heap)  │ ← 全局变量、堆
         │ Stack         │ ← 调用栈、局部变量
         └──────────────┘
```
*程序员可见状态*：这是汇编程序员在编写代码时能直接操作或间接感知的 CPU 状态部分。主要包括 PC（程序计数器）、寄存器文件（register file）、以及条件码（condition codes）
- *PC — 程序计数器（Program Counter）*
  - 存放下一条要执行指令的地址
  - 在 x86-64 中，它叫 RIP（Register Instruction Pointer）
  - 当 CPU 执行一条指令后：
    - 顺序执行时：RIP 自动 + 指令长度
    - 分支跳转时：RIP 被修改为新的目标地址
- *Register File — 寄存器文件*
  - 一组高速的存储单元，保存当前正在使用的数据
  - 访问速度远高于内存（通常纳秒级别）
    #three-line-table[
      | 名称                                           | 用途（常见）                  |
      | :------------------------------------------- | :---------------------- |
      | `%rax`                                       | 返回值寄存器                  |
      | `%rdi`, `%rsi`, `%rdx`, `%rcx`, `%r8`, `%r9` | 前 6 个函数参数               |
      | `%rbx`, `%rbp`, `%r12–%r15`                  | 被调用者保存寄存器（callee-saved） |
      | `%rsp`                                       | 栈指针（stack pointer）      |
      | `%rip`                                       | 程序计数器（program counter）  |
    ]
- *Condition Codes — 条件码（标志位）*
  - 保存最近一次算术或逻辑运算的结果状态
  - 它们不是通用寄存器，而是 CPU 状态寄存器中的若干位
    #three-line-table[
      | 名称                     | 含义        | 由哪些操作更新              |
      | :--------------------- | :-------- | :------------------- |
      | *ZF (Zero Flag)*     | 结果是否为 0   | `cmp`, `sub`, `test` |
      | *SF (Sign Flag)*     | 结果是否为负    | 同上                   |
      | *OF (Overflow Flag)* | 是否有溢出     | `add`, `sub`         |
      | *CF (Carry Flag)*    | 是否产生进位/借位 | 加减运算                 |
    ]
    #three-line-table[
      | 条件跳转指令        | 检查的标志        | 意义        |
      | :------------ | :----------- | :-------- |
      | `je` / `jz`   | ZF=1         | 相等 / 结果为零 |
      | `jne` / `jnz` | ZF=0         | 不相等       |
      | `jl` / `js`   | SF≠OF        | 小于（有符号）   |
      | `jg`          | ZF=0 且 SF=OF | 大于（有符号）   |
      | `jc` / `jnc`  | CF=1 / CF=0  | 有进位 / 无进位 |
    ]
  汇编程序中的 `if`、`while`、`for` 等控制流结构，全都是基于这些标志实现的
- *Memory — 内存*
  - 从汇编角度看，内存是一个字节地址空间，每个字节都有编号（地址）
  - 主要逻辑区域：
    #three-line-table[
      | 区域                              | 说明                 |
      | :------------------------------ | :----------------- |
      | *Code Segment (.text)*        | 存放指令               |
      | *Data Segment (.data / .bss)* | 存放全局变量、静态变量        |
      | *Heap*                        | 动态分配内存（malloc/new） |
      | *Stack*                       | 函数调用、局部变量、返回地址     |
    ]

*汇编中的数据类型*
#three-line-table[
  | 数据类别                         | 说明                    |   大小（字节）   | 示例                                 |
  | :--------------------------- | :-------------------- | :--------: | :--------------------------------- |
  | *整数 (Integer)*             | 整型数值或地址（指针）           |   1、2、4、8  | `char`, `short`, `int`, `long`     |
  | *浮点数 (Floating Point)*     | 实数，遵循 IEEE-754 格式     |   4、8、10   | `float`, `double`, `long double`   |
  | *SIMD 向量数据 (Vector types)* | 同时处理多个数据的寄存器值（用于并行计算） | 8、16、32、64 | SSE/AVX 寄存器 `%xmm`, `%ymm`, `%zmm` |
  | *代码 (Code)*                | 指令序列的字节表示             |     不定     | 可执行机器码                             |
  | *聚合类型 (Aggregate)*         | 🚫 不存在于汇编语义中          |     ——     | C 语言中的数组/结构体只是连续字节                 |
]
- *整数数据的四种常见大小*
  #three-line-table[
    | 名称          |  大小 | x86-64 汇编指令后缀 | 示例     |
    | :---------- | :-: | :-----------: | :----- |
    | byte        |  1  |      `b`      | `movb` |
    | word        |  2  |      `w`      | `movw` |
    | double word |  4  |   `l` (long)  | `movl` |
    | quad word   |  8  |      `q`      | `movq` |
  ]
  ```asm
  movb %al, (%rbx)   # 1 字节
  movw %ax, (%rbx)   # 2 字节
  movl %eax, (%rbx)  # 4 字节
  movq %rax, (%rbx)  # 8 字节
  ```
- 浮点与 SIMD 数据
  - 现代 x86-64 支持两类浮点/向量计算单元：
    #three-line-table[
      | 类型              | 位宽       | 寄存器                    | 指令集             |
      | :-------------- | :------- | :--------------------- | :-------------- |
      | 浮点寄存器 (x87 FPU) | 80 位     | `%st(0)`–`%st(7)`      | 旧式浮点            |
      | SIMD 寄存器        | 64–512 位 | `%xmm`, `%ymm`, `%zmm` | SSE/AVX/AVX-512 |
    ]
  - 这些寄存器用于浮点和向量运算，例如：
    ```asm
    addss %xmm1, %xmm0   # 单精度浮点相加
    addps %xmm1, %xmm0   # 单精度向量加法
    ```
- 代码段 (Code) 也是“数据”
  - 汇编视角下，指令本身也是一串字节（机器码）
    ```
    48 89 d3
    ```
    在汇编中代表 `movq %rdx, %rbx`，在内存中就是 3 个字节
  - CPU 通过 `%rip` 从内存取出这些字节并执行
- 寄存器名字与操作大小对应
  ```
  addq %rbx, %rax
  ```

*x86-64 架构的通用寄存器（general-purpose registers）体系*
- x86-64 的 16 个通用寄存器
  - 在 x86-64 中，有 16 个通用整数寄存器（GPR, General-Purpose Registers），每个都是 64 位（8 字节）宽
  #three-line-table[
    | 64-bit | 32-bit (低 4 字节) | 说明                    |
    | :----- | :-------------- | :-------------------- |
    | %rax   | %eax            | 主累加器（常用于返回值）          |
    | %rbx   | %ebx            | 通用寄存器（callee-saved）   |
    | %rcx   | %ecx            | 计数器（循环、移位）            |
    | %rdx   | %edx            | 数据寄存器（第二参数）           |
    | %rsi   | %esi            | 源指针寄存器                |
    | %rdi   | %edi            | 目的指针寄存器               |
    | %rbp   | %ebp            | 基址指针（栈帧指针）            |
    | %rsp   | %esp            | 栈顶指针                  |
    | %r8    | %r8d            | 新增通用寄存器（caller-saved） |
    | %r9    | %r9d            | 新增通用寄存器               |
    | %r10   | %r10d           | 新增通用寄存器               |
    | %r11   | %r11d           | 新增通用寄存器               |
    | %r12   | %r12d           | 通用寄存器（callee-saved）   |
    | %r13   | %r13d           | 通用寄存器                 |
    | %r14   | %r14d           | 通用寄存器                 |
    | %r15   | %r15d           | 通用寄存器                 |
  ]
  *x86-64 = IA-32 + 8 新寄存器 + 64 位扩展*
- 寄存器的“分层命名”——按位宽访问
  - 每个寄存器的低位部分可以单独访问
  #three-line-table[
    | 位宽    | 访问名（以 %rax 为例） | 说明         |
    | :---- | :------------- | :--------- |
    | 64 位  | `%rax`         | 整个 64 位寄存器 |
    | 32 位  | `%eax`         | 低 32 位     |
    | 16 位  | `%ax`          | 低 16 位     |
    | 8 位高半 | `%ah`          | 第 8–15 位   |
    | 8 位低半 | `%al`          | 第 0–7 位    |
  ]
  ```asm
  movb $1, %al   # 只改最低8位
  movw $2, %ax   # 改低16位
  movl $3, %eax  # 改低32位；高32位自动清零
  movq $4, %rax  # 改整个64位
  ```
- 寄存器不在内存中
  - 寄存器是 CPU 内部的专用存储单元，不在内存中，也不在缓存中
  - 访问寄存器是纳秒级别的极快操作；访问内存则慢几个数量级
  - 因此编译器会尽可能把频繁使用的变量放在寄存器里
- 历史回顾：IA-32 (32-bit) 寄存器体系
  - 在 32 位时代（IA-32 架构，约 1985–2000），只有 8 个通用寄存器
  #three-line-table[
    | 32 位寄存器 | 16 位 | 高 8 位 | 低 8 位 | 历史名称（用途）                 |
    | :------ | :--- | :---- | :---- | :----------------------- |
    | %eax    | %ax  | %ah   | %al   | 累加器 (accumulator)        |
    | %ebx    | %bx  | %bh   | %bl   | 基址 (base)                |
    | %ecx    | %cx  | %ch   | %cl   | 计数器 (counter)            |
    | %edx    | %dx  | %dh   | %dl   | 数据寄存器 (data)             |
    | %esi    | %si  | —     | —     | 源索引 (source index)       |
    | %edi    | %di  | —     | —     | 目的索引 (destination index) |
    | %ebp    | %bp  | —     | —     | 基址指针 (base pointer)      |
    | %esp    | %sp  | —     | —     | 栈顶指针 (stack pointer)     |
  ]

==== 汇编中的基本操作

#three-line-table[
  | 操作类型                             | 作用                   | 示例                                |
  | :------------------------------- | :------------------- | :-------------------------------- |
  | *数据传送（Data Transfer）*        | 在寄存器 ↔ 内存 ↔ 常数之间移动数据 | `movq`, `leaq`                    |
  | *算术逻辑运算（Arithmetic / Logic）* | 执行算术、位运算或比较操作        | `addq`, `subq`, `andq`, `cmpq`    |
  | *控制转移（Control Transfer）*     | 改变程序执行顺序（跳转、调用、返回）   | `jmp`, `call`, `ret`, `je`, `jne` |
]
- 数据传送 (Transfer Data)
  - 它们让寄存器与内存之间搬运数据（CPU 无法直接算内存中的数，必须先加载到寄存器）
  #three-line-table[
    | 指令               | 含义                 | 示例                                       |
    | :--------------- | :----------------- | :--------------------------------------- |
    | `movq Src, Dest` | 复制 8 字节（quad word） | `movq %rax, (%rbx)` → 把寄存器 rax 的值存入内存    |
    | `movl Src, Dest` | 复制 4 字节（32 位）      | `movl (%rcx), %edx` → 从内存读 4 字节到寄存器      |
    | `leaq Src, Dest` | 把地址（而不是值）加载进寄存器    | `leaq 8(%rbp), %rax` → `%rax = %rbp + 8` |
  ]
- 算术与逻辑操作 (Arithmetic / Logic)
  - 执行算术、位运算、比较等。
  - 操作对象可以是：
    - 寄存器与寄存器；寄存器与内存；寄存器与立即数。
  #three-line-table[
    | 指令           | 含义             | 示例                                        |
    | :----------- | :------------- | :---------------------------------------- |
    | `addq S, D`  | 加法：`D = D + S` | `addq %rbx, %rax`                         |
    | `subq S, D`  | 减法：`D = D - S` | `subq $8, %rsp`                           |
    | `imulq S, D` | 乘法（有符号）        | `imulq %rcx, %rdx`                        |
    | `xorq S, D`  | 异或             | 清零技巧：`xorq %rax, %rax`                    |
    | `andq S, D`  | 按位与            | 掩码操作                                      |
    | `orq S, D`   | 按位或            | 组合标志                                      |
    | `cmpq S, D`  | 比较（设置条件码）      | `cmpq %rbx, %rax`（相当于 `rax - rbx`，但不保存结果） |
    | `testq S, D` | 按位与后更新条件码      | 判断是否为 0                                   |
  ]
- 控制转移 (Transfer Control)
  - 无条件跳转 (Unconditional jump)
    #three-line-table[
      | 指令          | 含义                 |
      | :---------- | :----------------- |
      | `jmp Label` | 无条件跳转到标签位置（改变 RIP） |
    ]
  - 条件跳转 (Conditional branch)
    #three-line-table[
      | 指令            | 含义（条件成立时跳转）         |
      | :------------ | :------------------ |
      | `je` / `jz`   | equal / zero → 相等   |
      | `jne` / `jnz` | not equal / nonzero |
      | `jl`          | less (有符号)          |
      | `jle`         | less or equal       |
      | `jg`          | greater (有符号)       |
      | `ja`          | above (无符号)         |
      | `jb`          | below (无符号)         |
    ]
  - 过程调用 (Procedure calls)
    #three-line-table[
      | 指令           | 功能              |
      | :----------- | :-------------- |
      | `call Label` | 调用函数（压入返回地址，跳转） |
      | `ret`        | 从函数返回（弹出返回地址）   |
    ]

===== 数据传送指令

*核心指令：*
```asm
movq Source, Dest
```
把源操作数（Source）复制到目标操作数（Dest），后缀 q 表示操作 8 字节（quad word）数据，也就是 64 位
- 三种操作数类型 (Operand Types)
  #three-line-table[
    | 类型                   | 示例                | 含义                      |
    | :------------------- | :---------------- | :---------------------- |
    | *Immediate（立即数）* | `$0x400`, `$-533` | 常量值（不是内存地址），1、2、4字节编码             |
    | *Register（寄存器）*  | `%rax`, `%r13`    | 寄存器的当前值，`%rsp`通常不用于普通运算；它是栈顶指针，自动由 `push、pop、call、ret` 等指令维护              |
    | *Memory（内存地址）*   | `(%rax)`          | 取内存中“地址 = %rax”处的 8 个字节 |
  ]
*`movq` 操作数组合*
```asm
movq Source, Des
```
- 合法的组合
  #three-line-table[
    | Source                     | Dest      | 示例                   | 类似的 C 代码         | 说明                     |
    | :------------------------- | :-------- | :------------------- | :--------------- | :--------------------- |
    | *Immediate → Register* | 常量 → 寄存器  | `movq $0x4, %rax`    | `temp = 0x4;`    | 把立即数常量加载到寄存器           |
    | *Immediate → Memory*   | 常量 → 内存   | `movq $-147, (%rax)` | `*p = -147;`     | 把常量写到内存（地址由 `%rax` 给出） |
    | *Register → Register*  | 寄存器 → 寄存器 | `movq %rax, %rdx`    | `temp2 = temp1;` | 在寄存器之间复制               |
    | *Register → Memory*    | 寄存器 → 内存  | `movq %rax, (%rdx)`  | `*p = temp;`     | 把寄存器值写入内存              |
    | *Memory → Register*    | 内存 → 寄存器  | `movq (%rax), %rdx`  | `temp = *p;`     | 从内存加载到寄存器              |
  ]
- 非法的组合：内存到内存 (Memory → Memory)
  - CPU 没有指令能直接从一个内存位置读出数据再直接写入另一个内存位置
  - 所有数据传输都必须经过寄存器中转
  - 一条指令解码时，只有一个有效地址生成器（address generator），同时读两个内存地址意味着要两次地址计算和两次访问

*内存寻址模式*
- *Normal* `(R)` `Mem[Reg[R]]`
  - 直接使用寄存器值作为内存地址
  - 例子：`movq (%rax), %rbx` 读取 `%rax` 指向的内存
- *Displacement* `D(R)` `Mem[Reg[R] + D]`
  - 在寄存器值基础上加上一个常数偏移
  - 例子：`movq 8(%rbp), %rax` 读取 `%rbp + 8` 处的内存
- *最一般形式* `D(Rb, Ri, S)` `Mem[Reg[Rb] + S*Reg[Ri] + D]`
  - 基址寄存器 `Rb` + 索引寄存器 `Ri` $times$ 比例因子 `S` + 偏移 `D`
    - `D`：常数偏移（displacement），1、2、4 字节
    - `Rb`：基址寄存器（base register）16 字节整数寄存器
    - `Ri`：索引寄存器（index register）16 字节整数寄存器
    - `S`：比例因子（scale factor），只能是 1、2、4、8，对应数据类型大小
  - 例子：`movq 0x100(%rbx, %rcx, 4), %rax` 读取 `0x100 + %rbx + 4*%rcx` 处的内存

*`swap`例子*
- C代码
  ```c
  void swap(long *xp, long *yp) {
      long t0 = *xp;
      long t1 = *yp;
      *xp = t1;
      *yp = t0;
  }
  ```
  - System V AMD64 调用约定（Linux/macOS）下，前两个参数放在寄存器里：
    - `xp` → `%rdi`
    - `yp` → `%rsi`
- 编译生成的核心汇编（AT&T 语法）：
  ```asm
  swap:
      movq    (%rdi), %rax   # t0 = *xp
      movq    (%rsi), %rdx   # t1 = *yp
      movq    %rdx, (%rdi)   # *xp = t1
      movq    %rax, (%rsi)   # *yp = t0
      ret
  ```
#note[
  编译器选择寄存器是有“规则”的：
  - 在 x86-64（System V AMD64 ABI）中，所有通用寄存器并不是“完全平等”的，它们有不同的职责类别
    #three-line-table[
      | 类别                       | 寄存器                                                | 意义           |
      | :----------------------- | :------------------------------------------------- | :----------- |
      | *参数寄存器*                | `%rdi`, `%rsi`, `%rdx`, `%rcx`, `%r8`, `%r9`       | 前 6 个函数参数    |
      | *返回值寄存器*               | `%rax`                                             | 函数返回值        |
      | *调用者保存（caller-saved）*  | `%rax`, `%rcx`, `%rdx`, `%rsi`, `%rdi`, `%r8-%r11` | 调用函数前必须自行保存  |
      | *被调用者保存（callee-saved）* | `%rbx`, `%rbp`, `%r12-%r15`                        | 被调用函数必须保存并恢复 |
      | *栈指针*                  | `%rsp`                                             | 管理栈顶位置（不能乱用） |
    ]
    - `%rax` 是默认的返回寄存器
      - 编译器往往把临时值放在 `%rax`，因为它已经会在调用结束时被修改
      - 即使之后函数 `ret`，`%rax` 的内容可能被用作返回值（虽然这里是 void，也不会出错）
    - `%rdx` 是 caller-saved 且常用于第二操作数
      - `%rdx` 常在短函数中作为第二个通用暂存寄存器使用
      - 它和 `%rax` 一起，是算术、比较、内存访问中常见的寄存器对
    - 不用 `%rbx` / `%rcx`
      - `%rbx` 是 callee-saved，编译器不喜欢用它来存临时值，因为要保存/恢复；如果使用，函数必须在开头 `push %rbx` 并在返回前 pop %rbx 以恢复原值 → 多余操作降低性能
      - `%rcx` 是 caller-saved，但常被用作计数器（如 `rep movsb`），编译器也不常用它；但它在参数传递中常被用作第 4 个参数寄存器，编译器通常避免抢占它以防函数嵌套调用时冲突
]

=== Arithmetic & logical operations

算术与逻辑运算

*地址生成指令 `leaq`*
- `leaq`（Load Effective Address）指令
  - 计算内存地址，但不访问内存
  - 用于获取复杂地址的值，常用于指针运算
  - 语法：`leaq Source, Dest`
    - `Source` 是内存寻址模式（如 `D(Rb, Ri, S)`）
    - `Dest` 是寄存器
  - 直觉理解：`leaq` ≈ “算地址的 `mov`”
- 主要用途
  - 计算变量地址（指针取地址）计算变量地址（指针取地址）
    - C代码`p = &x[i];` → 汇编`leaq (%rbx,%rcx,8), %rax    # rax = &x[i]`
  - 做简单算术运算（不涉及内存）
    - 高效计算形如 `x + k*y` 的表达式
    - #three-line-table[
        | C 表达式              | 汇编                          | 计算                         |
        | :----------------- | :-------------------------- | :------------------------- |
        | `t = x + y;`       | `leaq (%rdi,%rsi), %rax`    | `%rax = %rdi + %rsi`       |
        | `t = x + 2*y;`     | `leaq (%rdi,%rsi,2), %rax`  | `%rax = %rdi + 2*%rsi`     |
        | `t = x + 8*y + 4;` | `leaq 4(%rdi,%rsi,8), %rax` | `%rax = %rdi + 8*%rsi + 4` |
      ]
    - 例如`long m12(long x) { return x * 12; }`
      ```asm
      leaq (%rdi,%rdi,2), %rax    # rax = x + 2*x = 3x
      salq $2, %rax               # rax = 3x << 2 = 12x
      ```
*基本算术指令*
- Two-Operand（双操作数）指令
  ```asm
  op Src, Dest
  ```
  AT&T 语法（Linux gcc 默认）是 Src, Dest，而 Intel 文档是相反顺序；我们使用 AT&T 语法
  - `Src`：源操作数，可以是寄存器、内存或立即数
  - `Dest`：目标操作数，必须是寄存器或内存
  - 计算结果存回 `Dest`
  #three-line-table[
    | 指令                       | 计算                   | 说明               |
    | :----------------------- | :------------------- | :--------------- |
    | `addq Src,Dest`          | `Dest = Dest + Src`  | 加法               |
    | `subq Src,Dest`          | `Dest = Dest - Src`  | 减法               |
    | `imulq Src,Dest`         | `Dest = Dest * Src`  | 乘法（低 64 位）       |
    | `salq Src,Dest` / `shlq` | `Dest = Dest << Src` | 算术左移，相当于乘以 2^Src |
    | `sarq Src,Dest`          | `Dest = Dest >> Src` | 算术右移（保留符号位）      |
    | `shrq Src,Dest`          | `Dest = Dest >> Src` | 逻辑右移（高位补 0）      |
    | `xorq Src,Dest`          | `Dest = Dest ^ Src`  | 按位异或             |
    | `andq Src,Dest`          | `Dest = Dest & Src`  | 按位与              |
    | `orq Src,Dest`           | `Dest = Dest | Src`   | 按位或              |
  ]
  - 关于符号
    - 这些指令都不区分有符号 / 无符号，因为：
      - 底层只做二进制加减乘移
      - 符号差异只在解释结果和条件跳转时体现（通过条件码区分）
- One-Operand（单操作数）指令
  #three-line-table[
    | 指令          | 计算                | 说明         |
    | :---------- | :---------------- | :--------- |
    | `incq Dest` | `Dest = Dest + 1` | 自增         |
    | `decq Dest` | `Dest = Dest - 1` | 自减         |
    | `negq Dest` | `Dest = -Dest`    | 取相反数（补码求负） |
    | `notq Dest` | `Dest = ~Dest`    | 按位取反       |
  ]


=== 机器编程基础总结

- History of Intel Processors and Architectures
  - Intel 的处理器体系是渐进式设计（evolutionary design），一直在保持向后兼容
  - 从 1978 年的 8086 一路发展到今天的 x86-64，增加了大量特性，也留下许多“历史遗留”的怪异设计（quirks & artifacts）
  - x86 是典型的 CISC（复杂指令集计算机），而现代芯片也吸收了很多 RISC（精简指令集）的思想
- C → Assembly → Machine Code
  - 编译器必须把高级语言（C）的语句、表达式、函数，转换成低级指令序列
  - 程序可见状态（visible state）包括：
    - 程序计数器（Program Counter, RIP）
    - 寄存器（Registers）
    - 内存（Memory）
  - 代码生成过程：
    ```
    C 源码  →  汇编代码  →  目标文件（.o） →  可执行文件
    ```
  - 汇编和机器码之间是一一对应的
- Assembly Basics: Registers, Operands, Move
  - x86-64 的寄存器：16 个通用整数寄存器，每个 64 位
  - movq 指令非常强大，可以在 寄存器 ↔ 内存 ↔ 常量 之间自由搬运数据
  - 内存寻址模式非常灵活（支持基址 + 索引 × 比例 + 偏移）
- Arithmetic Operations（算术运算）
  - 编译器会自动选择最佳指令组合（`addq`、`leaq`、`salq`、`imulq` 等）实现算术
  - `leaq` 用来高效计算线性组合（例如 `x + k*y + d`）。
  - `salq` 用位移代替乘法（例如 `x << 4` 相当于 `x * 16`）
  - 这些指令同时更新条件码，为后续分支、比较等操作做准备
特别说明
- 指令集多种多样，指令集的实现更是千差万别
  - 指令集
    - IBM PC ASM （Intel ASM）与ARM ASM等
  - 汇编语言风格
    - AT&T 与 Intel，我们使用的是 AT&T 风格
  - 汇编器
    - GNU ASM 与 MASM等

== Arithmetic & Control

=== Control: Condition codes

*控制流*
```c
extern void op1(void);
extern void op2(void);

void decision(int x) {
    if (x) {
        op1();
    } else {
        op2();
    }
}
```
```
decision(x)
 ├── if (x != 0)
 │     └── op1();
 └── else
       └── op2();
```
汇编实现（x86-64, AT&T 语法）
```asm
decision:
    subq    $8, %rsp        # 分配栈空间（栈向下）
    testl   %edi, %edi      # 设置条件码：检查 x 是否为 0
    je      .L2             # 如果 x == 0，跳到 else 分支
    call    op1             # 调用 op1()
    jmp     .L1             # 跳过 else，去结尾
.L2:
    call    op2             # 调用 op2()
.L1:
    addq    $8, %rsp        # 释放栈空间
    ret                     # 返回
```
事实上和高级语言中的GOTO比较相似

*Processor State（处理器状态）*

在任何时刻，CPU 需要保存“程序执行的当前状态”，包括：
#three-line-table[
  | 类型         | 寄存器 / 状态                      | 用途                 |
  | :--------- | :---------------------------- | :----------------- |
  | *通用寄存器*  | `%rax`、`%rbx`、`%rcx`、… `%r15` | 存放临时数据、函数参数、返回值等   |
  | *栈指针*    | `%rsp`                        | 指向栈顶（当前栈帧顶端）       |
  | *基址指针*   | `%rbp`                        | （可选）指向当前栈帧底部       |
  | *指令指针*   | `%rip`                        | 指向*下一条要执行的指令地址*  |
  | *条件码寄存器* | `CF`、`ZF`、`SF`、`OF`           | 存放最近一次算术/逻辑运算结果的状态 |
]
前面的各种寄存器在64位架构中为64位的，而条件码寄存器只需要1bit。这四个“条件码”是 CPU 判断的基础，它们不是显式寄存器，而是存储在 CPU 的 EFLAGS（状态寄存器） 中的几个比特位。

*Condition Codes（条件码）*
#three-line-table[
  | 名称                     | 含义            | 适用情况         |
  | :--------------------- | :------------ | :----------- |
  | *CF (Carry Flag)*    | 无符号运算中最高位产生进位 | 无符号加/减法      |
  | *ZF (Zero Flag)*     | 结果是否为 0       | 所有算术逻辑运算     |
  | *SF (Sign Flag)*     | 结果的最高位（符号位）   | 有符号数判断正/负    |
  | *OF (Overflow Flag)* | 有符号溢出         | 两个同号数相加后符号变化 |
]
- 示例：`addq Src, Dest`
  ```asm
  addq %rbx, %rax   # rax = rax + rbx
  ```
  隐含过程：
  ```
  t = a + b
  ```
  #three-line-table[
    | 条件码 | 触发条件               | 含义             |
    | :-- | :----------------- | :------------- |
    | CF  | 如果结果在无符号运算中“进位”    | 无符号溢出（超过 2^64） |
    | ZF  | 如果结果为 0            | 检测相等  `t == 0`  |
    | SF  | 如果结果为负（最高位 = 1）    | 判断符号（有符号） `t < 0` |
    | OF  | 如果正数+正数得负，或负数+负数得正 | 有符号溢出  `(a>0 && b>0 && t<0) || (a<0 && b<0 && t>=0)`   |
  ]
- 条件码的来源
  - 条件码是隐式设置（Implicitly Set）的：
    - 加减法（`add, sub`）
    - 比较（`cmp, test`）
    - 逻辑运算（`and, or, xor`）
    - 但有些指令不会修改条件码，比如`leaq`：它只是做整数计算，不影响条件码（这也是它非常受编译器喜欢的原因之一）。
- *Zero Flag (ZF)* ZF 置位（=1）当且仅当结果为零：
  ```
  00000000000000000000000000000000
  ↑所有位都是 0
  ```
  举例：
  ```asm
  subq %rax, %rax   # 0
  # → ZF = 1 （因为结果为0）
  ```
  在 C 里相当于：
  ```c
  if (x == 0)
  ```
- *Sign Flag (SF)* SF 置位（=1）当结果为负（最高位 = 1）：
  ```
  1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  ↑符号位为1 → 负数
  ```
  举例：
  ```asm
  movq $-5, %rax  # 结果为负 → SF = 1
  ```
- *Carry Flag (CF)* CF：在无符号算术中，判断是否有“进位”或“借位”。
  - 加法：最高位产生进位 → CF = 1
    ```
      1xxxxxxxxxxxx...
    + 1xxxxxxxxxxxx...
    -----------------
     1xxxxxxxxxxxx...
     ↑最高位进位 → CF = 1
    ```
  - 减法：需要借位 → CF = 1
    ```
     10xxxxxxxxxxxx...
    - 1xxxxxxxxxxxx...
    = 1xxxxxxxxxxxx...
      ↑需要借位 → CF = 1
    ```
  - 对无符号数，CF 表示溢出（overflow）；对有符号数，CF 没有意义
- *Overflow Flag (OF)* OF：在有符号算术中，结果超出可表示范围时置位。与 CF 不同，它关注的是“符号错误”，不是进位。
  - 正溢出 (Positive Overflow)
    ```
    (a>0 && b>0 && t<0) || (a<0 && b<0 && t>=0)
    ```
  - 负溢出 (Negative Overflow)
    ```
    (a>0 && b<0 && t<0) || (a<0 && b>0 && t>0)
    ```

*显式设置条件码*
- `cmp` 指令 —— 比较（Compare）
  ```
  cmp a, b
  ```
  - 执行逻辑：`t = b - a`
  - 然后根据 t 的结果设置条件码（ZF, SF, OF, CF）
  - `sub`会改变寄存器内容（保存结果）；`cmp`不改变寄存器，只更新标志位
  - 示例：判断 `if (a < b)`
    ```asm
    cmpq %rsi, %rdi      # 计算 rdi - rsi
    jl   LESS            # 如果结果 < 0（有符号），跳转
    ```
- `test` 指令 —— 测试（Test）
  ```
  test a, b
  ```
  - 执行逻辑：`t = b & a`
  - 然后根据结果设置 ZF 和 SF（不设置 CF、OF）
  - 同样不修改任何寄存器，只更新标志位
  - 常见用途
    - 判断寄存器是否为零
      ```asm
      test %rdi, %rdi
      je   ELSE          # 如果结果为0，跳转
      ```
      等价于`if (x == 0)`
    - 检查两个寄存器是否有公共置位
      ```asm
      test %rsi, %rdi
      jne  FOUND
      ```
      等价于`if (x & y)  // 有共同置位`

#note(subname: [小结])[
  条件码的构成、设置、访问
  - 四个标识：CF，ZF，SF，OF
  - 两种设置方法
    - 显式：CMP与TEST
    - 隐式：算数运算
  - 两种访问方法
    - 显式： SET指令
    - 隐式：条件跳转、条件赋值（条件传送）
]

=== Conditional branches

*跳转（Jumping）*
- 在汇编语言中，程序的执行顺序不是固定的线性执行
  - 如果条件满足 → 跳到某个标签执行别的代码
  - 否则 → 继续顺序执行
- 跳转是对CPU不友好的
- jX 指令概览
  ```asm
  jX LABEL
  ```
  #three-line-table[
    | 指令            | 条件（逻辑表达式）          | 说明            | 比较类型          |
    | :------------ | :----------------- | :------------ | :------------ |
    | *jmp*       | 恒为真（1）             | 无条件跳转         | —             |
    | *je / jz*   | ZF = 1             | 相等 / 零        | 通用            |
    | *jne / jnz* | ZF = 0             | 不相等 / 非零      | 通用            |
    | *js*        | SF = 1             | 结果为负          | 有符号           |
    | *jns*       | SF = 0             | 结果非负          | 有符号           |
    | *jg*        | `~(SF ^ OF) & ~ZF` | 大于 (signed)   | 有符号           |
    | *jge*       | `~(SF ^ OF)`       | 大于等于 (signed) | 有符号           |
    | *jl*        | `(SF ^ OF)`        | 小于 (signed)   | 有符号           |
    | *jle*       | `(SF ^ OF) | ZF`           | 小于等于 (signed) | 有符号 |
    | *ja*        | `~CF & ~ZF`        | 大于 (unsigned) | 无符号           |
    | *jb*        | `CF`               | 小于 (unsigned) | 无符号           |
  ]
- 两类比较：有符号 vs 无符号

  在 C 语言中：
  ```c
  if ((unsigned)a < (unsigned)b) ...
  if ((int)a < (int)b) ...
  ```
  编译器会根据类型选择不同的跳转指令
  #three-line-table[
    | 比较类型               | 小于   | 小于等于  | 大于   | 大于等于  |
    | :----------------- | :--- | :---- | :--- | :---- |
    | *有符号 (signed)*   | `jl` | `jle` | `jg` | `jge` |
    | *无符号 (unsigned)* | `jb` | `jbe` | `ja` | `jae` |
  ]
  区别在于判断依据：
  - 有符号 → 用 SF 与 OF（符号与溢出标志）
  - 无符号 → 用 CF（进位标志）
- 示例
  - 判断相等 / 不等
    ```asm
    cmpq %rsi, %rdi      # 比较 rdi - rsi
    je   EQUAL           # 如果相等 (ZF=1)
    jne  NOTEQUAL        # 如果不相等 (ZF=0)
    ```
    ```c
    if (a == b) { ... }
    else { ... }
    ```
  - 判断有符号大小
    ```asm
    cmpq %rsi, %rdi     # 比较 rdi - rsi
    jl   LESS            # 如果 a < b (signed)
    jge  GREATER_EQUAL   # 如果 a >= b
    ```
    C 对应：
    ```c
    if (a < b) { ... }
    ```
  - 判断无符号大小
    ```asm
    cmpq %rsi, %rdi
    jb   BELOW           # if (a < b) unsigned
    jae  ABOVE_EQUAL     # if (a >= b)
    ```
    C 对应：
    ```c
    if ((unsigned)a < (unsigned)b)
    ```
*条件置位指令（Conditional Set Instructions）*
- 根据条件码（Condition Codes），把目标寄存器的最低字节（low-order byte） 设置为 0 或 1
  - 只修改目标寄存器的*最低 8 位*`%al, %r8b`
  - 不会影响其他 7 个字节
  - 通常用于把逻辑判断结果保存成一个布尔值
- SetX 指令
  ```
  setX   Dest
  ```
- 常用 SetX 指令表
  #three-line-table[
    | 指令        | 条件码逻辑              | 含义（C语言等价）            | 比较类型                 |
    | :-------- | :----------------- | :------------------- | :------------------- |
    | *sete*  | `ZF`               | 相等 (`==`)            | 通用                   |
    | *setne* | `~ZF`              | 不相等 (`!=`)           | 通用                   |
    | *sets*  | `SF`               | 结果为负                 | 有符号                  |
    | *setns* | `~SF`              | 结果为非负                | 有符号                  |
    | *setg*  | `~(SF ^ OF) & ~ZF` | 大于 (signed) (`>`)    | 有符号                  |
    | *setge* | `~(SF ^ OF)`       | 大于等于 (signed) (`>=`) | 有符号                  |
    | *setl*  | `(SF ^ OF)`        | 小于 (signed) (`<`)    | 有符号                  |
    | *setle* | `(SF ^ OF) | ZF`                  | 小于等于 (signed) (`<=`) | 有符号 |
    | *seta*  | `~CF & ~ZF`        | 高于 (unsigned) (`>`)  | 无符号                  |
    | *setb*  | `CF`               | 低于 (unsigned) (`<`)  | 无符号                  |
  ]
- `SetX + movzbl` 在实际函数返回布尔值时的用法
  - *32 位寄存器写操作会自动清零高 32 位*
  - C语言代码
    ```c
    int gt(long x, long y) {
        return x > y;
    }
    ```
    目标是返回一个 int 值：若 `x > y` → 返回 `1`，否则 → 返回 `0`
  - 对应的汇编
    ```
    gt:
        cmpq   %rsi, %rdi       # 比较 x - y
        setg   %al              # 若 x > y，则 %al = 1，否则 0
        movzbl %al, %eax        # 零扩展 1 字节 → 32 位寄存器 %eax
        ret
    ```
    把 `%al`（低 8 位）零扩展为 32 位寄存器 `%eax`
    - `%eax = 0x00000000` 或 `0x00000001`
    - 并且，写入 `%eax` 时会自动清零高 32 位，所以 `%rax = 0x00000000_00000000` 或 `0x00000000_00000001`。
  - 注意事项：`movzbl` 的“怪异之处”
    - 把 1 字节寄存器的值复制到 32 位寄存器中，并用 0 填充高位（零扩展）

*条件分支的传统实现方式*
- 通过条件跳转（`jle`、`jmp` 等）来实现 `if/else` 控制流
- 源代码
  ```c
  long absdiff(long x, long y) {
        long result;
        if (x > y)
            result = x - y;
        else
            result = y - x;
        return result;
    }
  ```
- 编译得到的汇编
  ```
  absdiff:
      cmpq   %rsi, %rdi     # 比较 x 和 y
      jle    .L4            # 如果 x <= y，跳转到 else 分支
      movq   %rdi, %rax     # x 拷贝到返回寄存器 rax
      subq   %rsi, %rax     # result = x - y
      ret                   # 返回
  .L4:                      # else 分支
      movq   %rsi, %rax     # y 拷贝到返回寄存器
      subq   %rdi, %rax     # result = y - x
      ret
  ```
  寄存器说明
  #three-line-table[
    | 寄存器    | 用途          |
    | :----- | :---------- |
    | `%rdi` | 参数 x        |
    | `%rsi` | 参数 y        |
    | `%rax` | 返回值（result） |
  ]
- C 中等价的 “goto” 版本
  - 编译器实际上会把 if-else 转换为带标签的跳转逻辑
  - ```c
    long absdiff_j(long x, long y) {
        long result;
        int ntest = (x <= y);
        if (ntest) goto Else;   // 条件跳转
        result = x - y;
        goto Done;              // 无条件跳转到结尾
    Else:
        result = y - x;
    Done:
        return result;
    }
    ```

  #note(subname: [关于goto的讨论])[
    原函数：
    ```c
    long absdiff(long x, long y) {
        long result;
        if (x > y)
            result = x - y;
        else
            result = y - x;
        return result;
    }
    ```
    可以变成两种goto版本
    ```c
    long absdiff_goto(long x, long y) {
        long result;
        int ntest = (x <= y);
        if (ntest) goto Else;   // 条件跳转
        result = x - y;
        goto Done;              // 无条件跳转到结尾
    Else:
        result = y - x;
    Done:
        return result;
    }
    ```
    ```c
    long absdiff_goto_alt(long x, long y) {
        long result;
        int t = (x > y);
        if (t) goto True;       // if 成立：跳到 then 部分
        result = y - x;         // else-statement 放在前面
        goto Done;
    True:
        result = x - y;         // then-statement 放在 true: 之后
    Done:
        return result;
    }
    ```
    - 规则 1
      - 先放 then 块
      - `if (!t) goto Else; … jmp Done; … Else: …`
      - 适合 then 为常见路径、希望 fall-through 直行、不额外跳转
    - 规则 2
      - 先放 else 块
      - `if (t) goto True; … goto Done; … True: then …`
      - 适合 else 为常见路径，同理让常见路径自然落空直行
    选择依据：
    - 哪条分支更常走：把更常走的分支安排为 fall-through（顺序路径），减少一次跳转，提高指令流水 & 分支预测命中率
    - 是否有 else：如果没有 else，原来那种“`if (!t) goto Done; then; Done:`”更简洁（只有一次条件跳转，无需额外 goto）
    - 代码布局/可读性：有时希望把“结果路径”放在结尾，减少多处 ret 或合并清理代码
    - 寄存器/活跃范围：不同布局会影响变量活跃区间与寄存器压力；把常用路径放顺序区往往更友好
  ]

*Conditional Moves*
- C源码
  ```c
  val = Test ? Then_Expr : Else_Expr;
  ```
  GOTO版本
  ```c
        ntest = !Test;
        if (ntest) goto Else;
        val = Then_Expr;
    goto Done;
  Else:
    val = Else_Expr;
  Done:
  ```
  - `val = x>y ? x-y : y-x;`汇编为（System V: `x→%rdi, y→%rsi`）
    - ```asm
      cmpq  %rsi, %rdi        # x ? y
      jle   .Lelse            # if (x <= y) goto else
      movq  %rdi, %rax
      subq  %rsi, %rax        # rax = x - y
      jmp   .Ldone
      .Lelse:
      movq  %rsi, %rax
      subq  %rdi, %rax        # rax = y - x
      .Ldone:
      ret
      ```
  - 只会执行被选中的那条路径；但有分支跳转，可能引发分支预测失误，打断流水线。
- 条件传送Conditional Moves（`cmov`）
  - 先把两个结果都算好，再根据条件把其中一个搬进目的寄存器，从而不跳转
  - `cmov`
    ```asm
    cmovX src dest
    ```
    - `X` 是条件码，比如 `le`（小于等于）、`ge`（大于等于）等；条件与 jX 同名同义：`cmove/cmovne/cmovl/cmovg/cmovle/cmovge/cmova/cmovb/cmovs/cmovns/...`
    - 目的必须是寄存器；来源可寄存器/内存
    - 语义：`if (cond) Dest ← Src`（不改条件码）
  - 汇编为`x→%rdi, y→%rsi`
    ```asm
    # 先算 then = x - y 到 %rax
    movq  %rdi, %rax
    subq  %rsi, %rax
    # 再算 else = y - x 到 %rcx
    movq  %rsi, %rcx
    subq  %rdi, %rcx
    # 用 cmp 设置条件码
    cmpq  %rsi, %rdi        # x ? y
    # 若 x <= y，则把 else 搬到 %rax；否则保留 then
    cmovle %rcx, %rax       # if (x <= y) rax = rcx
    ret
    ```
- 编译器“何时用 cmov 而不是分支”的三条准则
  - 语义安全
    - 三目运算在 C 里只会求值一边。用 `cmov` 时通常要把两边都先算出来：
    - 如果任一边可能有副作用（写内存、I/O、++）、可能产生异常/陷阱（如越界解引用、除零）、或volatile 访问 —— 编译器不能用 `cmov`
    - 只有当两边都是“纯表达式”（无副作用、不会 fault）时，`cmov` 才是安全的
  - 性能模型
    - 难以预测/随机数据导致分支经常失误 → `cmov` 通常更快（无控制转移）
    - 高度可预测的分支（比如几乎总是 true） → 传统分支往往更快（只执行一边；`cmov` 要算两边，白做一半的工）
    - 两边的计算成本差距大时：分支可能更好（避免做“贵的那边”）；`cmov` 会把两边都做了
  - 标志依赖与调度
    - `cmov` 依赖刚刚设置的条件码；中间不能插入会修改标志位的指令（`add/sub/and/...`）
    - 编译器会尽量把 `cmp/test` 和 `cmov` 挨得很近，避免 flags 被污染
  - 分支版 vs cmov 版
    #three-line-table[
      | 方案     | 优点                 | 缺点              | 适用场景              |
      | ------ | ------------------ | --------------- | ----------------- |
      | 分支（jX） | 只执行一边；便于跳过昂贵路径     | 可能分支预测失败，流水线被冲掉 | 条件高可预测；或某边昂贵/有副作用 |
      | cmov   | 无跳转，流水线友好；适合不可预测数据 | 两边都要算；要求纯表达式且安全 | 数据依赖难预测、代价相近、无副作用 |
    ]
- 示例
  - 计算很昂贵（Expensive Computations）— 性能差
    ```c
    val = Test(x) ? Hard1(x) : Hard2(x);
    ```
  - 存在“危险计算”（Risky Computations）— 可能崩掉或产生不良后果
    ```c
    val = p ? *p : 0;
    ```
    若用 `cmov` 思路，通常会 先执行 `*p` 的内存读取，即使 `p == NULL`，也会触发缺页/段错；而 C 的 `?:` 语义是 只求值一边：当 `p==NULL` 时不会去解引用。
  - 有副作用（side effects）— 语义错误，甚至非法
    ```c
    val = x > 0 ? x *= 7 : x += 3;
    ```
=== Loops

*Do-While循环*
- 语义与 goto 版（do–while）
  - C源码
    ```c
    long pcount_do(unsigned long x) {
        long result = 0;
        do {
            result += x & 0x1;
            x >>= 1;
        } while (x);
        return result;
    }
    ```
  - 等价 goto：
    ```c
    long pcount_goto(unsigned long x) {
        long result = 0;
    loop:
        result += x & 1;
        x >>= 1;
        if (x) goto loop;   // do–while：先执行一次，再判断
        return result;
    }
    ```
    - 统计 1 比特
    - 要点：循环体至少执行 1 次；条件检查在末尾
- 汇编逐行对应（AT&T，System V：`x→%rdi，result→%rax`）
  ```asm
      movl  $0, %eax        # result = 0   (写 %eax 也会清 %rax 的高 32 位)
  .L2:                   # loop:
      movq  %rdi, %rdx      #   t = x
      andl  $1, %edx        #   t = x & 1   (只保留最低位；结果放 %edx/%rdx)
      addq  %rdx, %rax      #   result += t
      shrq  %rdi            #   x >>= 1     (逻辑右移 1 位)
      jne   .L2             #   if (x != 0) goto loop
      rep; ret              # return result
  ```
- *通用 do–while 翻译模板*
  - C
    ```c
    do {
        Body;            // S1; S2; ... Sn;
    } while (Test);
    ```
  - GOTO
    ```c
    loop:
        Body;            // S1; S2; ... Sn;
        if (Test) goto loop;
    ```

*While循环*
- Jump-to-Middle（跳到中间）
  - 在 `-Og`（调试友好）常见
  - while 版
    ```c
    while (Test) {
        Body;            // S1; S2; ... Sn;
    }
    ```
  - GOTO
    ```c
        goto test;      // 先跳到测试点
    loop:
        Body
    test:
        if (Test) goto loop;
    done: ;
    ```
    - 入口一开始 goto test，先检测条件，再决定是否进入 Body
    - 形状：入口 → test → (true? 回 loop 执行 Body : 退出)
    - 便于把“判断”与“回跳”放在一起，debug 时更直观；但多了一个初始无条件跳转
- Do-while Conversion（转成 do-while）
  - 在 `-O1`（优化）常见
  - while 版
    ```c
    while (Test) {
        Body;            // S1; S2; ... Sn;
    }
    ```
  - 转成 do-while 版
    ```c
    if (!Test) goto done;   // 入口守卫：不满足则直接退出
    do {
        Body
    } while (Test);
    done: ;
    ```
  - goto 等价
    ```c
        if (!Test) goto done;   // 入口守卫
    loop:
        Body
        if (Test) goto loop;
    done: ;
    ```
    - 入口先做一次守卫判断（guard），不满足就立即退出（无初始 jmp）
    - 满足时进入一个 do-while 形状 的循环：Body 在前，测试+回跳在后
    - 这在汇编上通常少一次跳转，布局也利于指令流水（test 与回跳相邻）
#three-line-table[
  | 维度      | Jump-to-Middle (-Og) | Do-while Conversion (-O1) |
  | ------- | -------------------- | ------------------------- |
  | 入口路径    | 先无条件跳到测试点            | 入口即条件守卫（可能直接退出）           |
  | 跳转数量    | 多一个初始 `jmp`          | 一般更少                      |
  | 可读/可调试性 | 判断点集中，结构直观           | 结构更像 do-while             |
  | 性能取向    | 便于保留源结构，调试友好         | 更紧凑、预测好，常更高效              |
  | 布局      | Body 与回跳测试分离         | Body 后紧跟测试与回跳             |
]

*for 循环*
- 语义
  - C源码
    ```c
    for (Init; Test; Update) {
        Body;            // S1; S2; ... Sn;
    }
    ```
  - 等价 do-while 版
    ```c
    Init;
    if (!Test) goto done;   // 入口守卫
    do {
        Body;            // S1; S2; ... Sn;
        Update;
    } while (Test);
    done: ;
    ```
  - goto 版
    ```c
      if (!Test)
        goto done;
    loop:
      Body
      Update
      if (Test)
        goto loop;
    done:
    ```
    - 把“测试 + 回跳”放在循环体末尾，正好对上机器级的“设置条件码 → 条件跳转”
- 初始测试可优化掉
  - 在很多 for 循环里，第一次进入循环前的 Test 必定为真，所以编译器能把入口守卫去掉，直接落入循环体
    - 常量边界且非空：
      - 典型如 `for (i=0; i<WSIZE; i++)`，若编译器知道 `WSIZE > 0`（编译期常量，如 `64`），
      - 则初次判断 `0 < WSIZE` 恒真 → 入口 `if (!Test) goto done;` 可删
    - 已由前置检查/类型保证：
      - 上下文或类型约束能保证第一次迭代必进
    - 循环展开/向量化前的规范化：
      - 编译器重排后把首轮工作合并进主循环，也常使入口守卫冗余
  - 何时不能去掉初始测试
    - `WSIZE` 可能为 0（或运行时变量，编译器不能证明 >0）
    - 循环起始并非 `i=0`，或 `Test` 不是显然恒真的（如 `i<=N` 且 N 可能为负、溢出边界等）
    - `Body` 在第一次就可能 fault 或有 副作用，而语义要求当 `Test` 不成立时完全不执行

=== Switch Statements

- C 语言层面的语义回顾
  ```c
  switch (x) {
    case 0: f0(); break;
    case 1: f1(); break;
    case 2:
    case 3: f23(); break;
    default: fdefault(); break;
  }
  ```
  等价逻辑（用 if-else 表示）：
  ```c
  if (x == 0)
    f0();
  else if (x == 1)
    f1();
  else if (x == 2 || x == 3)
    f23();
  else
    fdefault();
  ```
  但编译器通常不会真的翻成一堆 cmp+je，它会根据 case 的分布和稠密程度选择不同策略
- 编译器的三种主要翻译策略
  - 直接链式比较（if-else chain）
    - case 数量少，或离散、稀疏
    ```asm
    cmp   $0, %edi
    je    .L0
    cmp   $1, %edi
    je    .L1
    cmp   $2, %edi
    je    .L2
    jmp   .Ldefault
    ```
  - 跳转表（jump table）
    - case 密集（例如 0–5 连续）
    - 编译器创建一个表格，其中每项存储一个跳转目标地址
    ```c
    goto *jt[x];  // x 在 0..5 内，否则跳 default
    ```
    汇编结构
    ```asm
    cmp    $5, %edi
    ja     .Ldefault          # if x > 5 -> default
    jmp    *.LJTable(,%rdi,8) # 根据索引跳
    .LJTable:
        .quad .L0, .L1, .L2, .L3, .L4, .L5
    ```
    - 是跳转表（每个表项是 8 字节地址）
    - `jmp *addr` 是间接跳转（indirect jump）
    - 优点：时间复杂度 O(1)，无需逐一比较
- 二分查找（binary search jump）
  - case 较多但不连续，例如 `case 1, 10, 20, 100, 200`
  - 编译器生成一串比较指令，通过范围拆分实现二分跳转：
    ```asm
    cmp   $20, %edi
    jl    .Llow
    cmp   $100, %edi
    jl    .Lmid
    ...
    ```
  - 优点：时间复杂度 O(log n)，比链式比较更快
- 汇编层面的核心机制：间接跳转
  ```asm
  jmp *addr      # 跳转到内存中的地址（64 位）
  jmp *(table,%reg,8)  # 跳到“table + reg×8”指定位置的地址
  ```
- Switch 到汇编的示意例子
  ```c
  int select(int x) {
    switch (x) {
      case 0: return 10;
      case 1: return 20;
      case 2: return 30;
      default: return -1;
    }
  }
  ```
  GCC -O1 生成的汇编会类似：
  ```asm
  select:
      cmp    $2, %edi
      ja     .Ldefault
      jmp    *.LJTable(,%rdi,8)
  .LJTable:
      .quad  .L0
      .quad  .L1
      .quad  .L2

  .L0:  mov $10, %eax; ret
  .L1:  mov $20, %eax; ret
  .L2:  mov $30, %eax; ret
  .Ldefault:
      mov $-1, %eax
      ret
  ```

#note(subname: [控制流总结])[
  - C 控制结构 ↔ 汇编控制结构
    #three-line-table[
      | C语言结构           | 对应汇编控制机制                   | 实现方式                                      |
      | --------------- | -------------------------- | ----------------------------------------- |
      | `if / else`     | *条件跳转（conditional jump）* | `cmp` / `test` + `jX`（如 `je`, `jl`, `jg`） |
      | `?:` (条件表达式)    | *条件传送（conditional move）* | `setX` + `movzbl` 或 `cmovX`               |
      | `do-while`      | *循环 + 条件跳转*              | 循环体后判断条件再跳                                |
      | `while` / `for` | *前测试循环*                  | 跳转到中间 或 转换为 do-while 形式                   |
      | `switch`        | *间接跳转（indirect jump）*    | 跳转表（jump table）或 比较链（二叉树）                 |
    ]
  - 条件码（Condition Codes）
    - 四个核心标志位
      #three-line-table[
        | 标志位    | 含义                 | 用于哪类比较             |
        | ------ | ------------------ | ------------------ |
        | *CF* | Carry Flag，进位标志    | 无符号溢出（加法进位 / 减法借位） |
        | *ZF* | Zero Flag，零标志      | 结果是否为 0            |
        | *SF* | Sign Flag，符号标志     | 结果是否为负数（最高位 1）     |
        | *OF* | Overflow Flag，溢出标志 | 有符号溢出（正+正→负，负+负→正） |
      ]
    - 条件码的两种设置方式
      #three-line-table[
        | 类型       | 指令                   | 作用               |
        | -------- | -------------------- | ---------------- |
        | *显式访问* | `setX %rB`           | 将条件结果写入寄存器（0或1）  |
        | *隐式访问* | `jX Label` / `cmovX` | 通过条件跳转或条件传送使用标志位 |
      ]
    - 条件码的两种访问方式
      #three-line-table[
        | 类型       | 指令                   | 作用               |
        | -------- | -------------------- | ---------------- |
        | *显式访问* | `setX %rB`           | 将条件结果写入寄存器（0或1）  |
        | *隐式访问* | `jX Label` / `cmovX` | 通过条件跳转或条件传送使用标志位 |
      ]
]

== Procedures

=== Mechanisms

*Procedure（过程）的三大机制*

在 C 语言里，一个过程（函数）就是：
- 有入口（函数名）
- 有参数（输入数据）
- 有返回值（输出结果）
- 执行期间可能需要局部存储（局部变量、数组等）
机器要支持函数调用，必须实现以下三个机制：
#three-line-table[
  | 机制                 | 含义                 | 在汇编中体现             |
  | ------------------ | ------------------ | ------------------ |
  | *控制传递 (Control)* | 从调用者跳到被调用函数，再返回原处  | `call` / `ret` 指令  |
  | *数据传递 (Data)*    | 把参数传给函数，取回返回值      | 寄存器传参 + `%rax` 返回  |
  | *内存管理 (Memory)*  | 给局部变量分配栈空间，函数结束后释放 | 栈指针 `%rsp` 上移 / 下移 |
]

例子：过程调用逻辑
```c
P(...) {
    ...
    y = Q(x);
    print(y);
    ...
}
int Q(int i) {
    int t = 3 * i;
    int v[10];
    ...
    return v[t];
}
```
我们看到过程间关系：
- P 调用 Q（通过 `call`）
- Q 运行自己的代码并返回（通过 `ret`）
- Q 有：
  - 参数传入 (`i`)
  - 局部变量 (`t, v[10]`)
  - 返回值 (`v[t]`)

*三个机制的实现方式*
- Passing Control — *控制传递*
  - 使用机器指令：
    - `call Label`
      - 将 下一条指令地址 压栈（保存返回点）
      - 跳转到函数入口处执行
    - `ret`
      - 从栈顶弹出返回地址
      - 跳回调用点
  - 这保证了函数能调用、返回，不丢失程序执行位置
- Passing Data — 数据传递
  - 在 x86-64 的 System V ABI（Linux / macOS 通用标准）中：
    - 前 6 个整型或指针参数放入寄存器：
      #three-line-table[
        | 参数 | 寄存器 |
        | --- | ---- |
        | 1   | `%rdi` |
        | 2   | `%rsi` |
        | 3   | `%rdx` |
        | 4   | `%rcx` |
        | 5   | `%r8`  |
        | 6   | `%r9`  |
      ]
    - 其余参数通过栈传递
    - 返回值存放在 `%rax`
  - Windows 使用另一套 ABI（第1–4参数用 `%rcx`, `%rdx`, `%r8`, `%r9`）
- Memory Management — 内存管理（栈帧）
  - 每次函数调用都会创建一个栈帧（stack frame）：
    #three-line-table[
      | 内容                     | 作用                     |
      | ---------------------- | ---------------------- |
      | *Return address*     | `call` 自动压栈，`ret` 用于返回 |
      | *Saved registers*    | 保存调用前的寄存器状态            |
      | *Local variables*    | 在栈上开辟空间存储局部数据          |
      | *Arguments beyond 6* | 额外参数通过栈传入              |
    ]
  - 栈帧的顶端由 `%rsp` 指向，函数内部可能还用 `%rbp`（base pointer）作为帧基准
- *ABI（Application Binary Interface）*
  - ABI 规定了函数在机器层面的行为约定；
  - 包括：
    - 参数如何传递（哪些寄存器、顺序）
    - 返回值放哪
    - 哪些寄存器由调用者保存、哪些由被调函数保存
    - 栈的结构和对齐方式

=== Stack Structure

*x86-64 Stack*

在 x86-64 体系中，栈是一块受“栈式纪律”管理的内存区域，专门用于：
- 存放局部变量
- 保存函数调用信息（返回地址、寄存器等）
- 临时保存数据（比如调用参数或溢出的寄存器）
- 栈由系统在程序运行时自动维护，每个线程都有自己的栈

*栈的内存方向*
- 栈从高地址向低地址增长（top → bottom）
- 栈顶（Top）：由寄存器 `%rsp` 指向
- 栈底（Bottom）：调用链最开始的栈帧（程序启动时的位置）
```
高地址
│
│        ← 栈向下增长（push 时地址变小）
│
│   [上一层函数帧]
│   ----------------
│   [当前函数的局部变量]
│   [保存的寄存器值]
│   [返回地址 ← call自动压入]
│
└── %rsp（栈顶，最低地址）
低地址
```
`%rsp`（Stack Pointer Register）永远指向当前栈顶（最新压入数据的地址）

*push / pop 的本质*

栈操作由两条基本指令维护：
#three-line-table[
  | 指令          | 功能             | 栈方向变化             |
  | ----------- | -------------- | ----------------- |
  | `pushq Src` | 把 Src 压栈（保存数据） | `%rsp -= 8`（向下增长） |
  | `popq Dest` | 从栈顶弹出到 Dest    | `%rsp += 8`（向上回收） |
]

- `push Reg`：将寄存器 Reg 的值压入栈顶
  - `%rsp` 减少 8（64 位系统，每次压入 8 字节）
  - 把 Reg 的值存到 `%rsp` 指向的位置
- `pop Reg`：从栈顶弹出数据到寄存器 Reg
  - 把 `%rsp` 指向的值读入 Reg
  - `%rsp` 增加 8（弹出后栈顶上移）

*栈帧（Stack Frame）*
- 每次函数调用会形成一个新的栈帧，保存该函数执行所需的一切状态
- 典型结构：
  ```
  ↑ 高地址
  │
  │  调用者的帧（Caller）
  │  -------------------------
  │  返回地址 (Return Addr) ← call 自动压入
  │  保存的寄存器值（callee-saved）
  │  局部变量 / 临时数据
  │
  └── %rsp （当前函数的栈顶）
    %rbp（可选，帧基址指针 Frame Pointer）
  ↓ 低地址
  ```
  栈帧操作例子：
  ```asm
  pushq %rbp        # 保存旧帧基址
  movq  %rsp, %rbp  # 建立当前帧基址
  subq  $32, %rsp   # 给局部变量留 32 字节空间

  ...                # 函数主体代码 ...

  leave              # 等价于 mov %rbp,%rsp + pop %rbp
  ret                # 弹出返回地址并跳回
  ```

=== Calling Conventions

==== Passing control

一个函数是如何通过机器指令来调用另一个函数，并在结束后正确返回的。

例子
```c
void multstore(long x, long y, long *dest) {
    long t = mult2(x, y);
    *dest = t;
}
long mult2(long a, long b) {
    long s = a * b;
    return s;
}
```
机器必须完成：
- 跳转到被调用函数`mult2`
- 执行完后返回调用点（即`call`之后）
- 确保返回地址、寄存器状态、参数都正确
```asm
0000000000400540 <multstore>:
  400540: push %rbx        # 保存 %rbx，防止被覆盖
  400541: mov  %rdx,%rbx   # 保存 dest 指针到 %rbx
  400544: call 400550 <mult2>  # 调用 mult2(x, y)
  400549: mov  %rax,(%rbx) # 将 mult2 的返回值写入 *dest
  40054c: pop  %rbx        # 恢复寄存器
  40054d: ret              # 返回调用者

0000000000400550 <mult2>:
  400550: mov  %rdi,%rax   # s = a
  400553: imul %rsi,%rax   # s *= b  (即 s = a*b)
  400557: ret              # 返回
```
#newpara()

*函数调用控制机制（Control Flow）*
- *`call` 指令*
  ```asm
  call Label
  ```
  - *压栈返回地址*（return address）：
    - 即下一条指令（`call`后的那条）所在地址
  - *跳转*到被调函数的起始地址
  - 举例：
    ```asm
    400544: call 400550 <mult2>
    400549: mov  %rax,(%rbx)
    ```
    这意味着：
    - 把返回地址 `0x400549` 压入栈
    - 跳转到地址 `0x400550` 执行 `mult2`
- *`ret` 指令*
  ```asm
  ret
  ```
  - *弹出栈顶地址*（刚才被 `call` 压入的返回地址）
  - *跳转*回该地址（继续执行主调函数）
  - 举例：
    ```asm
    400557: ret
    ```
    这意味着：
    - 从栈顶弹出返回地址（`0x400549`）
    - 跳转回 `0x400549` 继续执行 `multstore` 中的下一条指令
    ```asm
    RIP = *RSP;
    RSP = RSP + 8;
    ```

栈的状态变化（控制流图）
```
Before CALL (in multstore):

%rsp → [ ... old stack ... ]
        ↑
        | (push return addr)
        |
After CALL:
%rsp → [ 0x400549 (return address) ]
        ↑
        |-- %rsp points to this (top)
        ↓
        低地址
        ------------------------------
        mult2 function code executes
        ------------------------------
        ↑
        RET pops this value → jumps to 0x400549
```
假设
```c
multstore(3, 5, &res);
```
- 函数调用前
  - #three-line-table[
      | 寄存器    | 含义        | 值（示例）                      |
      | ------ | --------- | -------------------------- |
      | `%rdi` | 第1参数 x    | `3`                        |
      | `%rsi` | 第2参数 y    | `5`                        |
      | `%rdx` | 第3参数 dest | 地址 `0x7fffffffdc00`        |
      | `%rsp` | 栈顶指针      | `0x7fffffffdbe0`           |
      | `%rip` | 指令地址      | 指向 `400544` (`call mult2`) |
      | `%rbx` | 通用寄存器     | 保存旧值（未定）                   |
    ]
- 执行 `call 400550 <mult2>` 的内部过程
  - 执行 `call` 指令
    - 压栈返回地址
      - `return address = 0x400549`（call 下一条指令地址）
      - `rsp -= 8`
      - `[rsp] = 0x400549`
    - 跳转到函数 `mult2` 的入口地址
      - `%rip = 0x400550`
    - 并且寄存器变化如下：
      #three-line-table[
        | 寄存器    | 调用前                        | 调用后                                   |
        | ------ | -------------------------- | ------------------------------------- |
        | `%rsp` | `0x7fffffffdbe0`           | `0x7fffffffdbe0 - 8 = 0x7fffffffdbe8` |
        | `%rip` | `0x400544`                 | `0x400550`（跳转到 mult2 开头）              |
        | `%rdi` | `3`                        | `3`（保持参数 x）                           |
        | `%rsi` | `5`                        | `5`（保持参数 y）                           |
        | `%rbx` | 指向 dest (`0x7fffffffdc00`) | 保持（caller-saved）                      |
      ]
  - 在 mult2 内部执行
    ```asm
    400550: mov  %rdi,%rax   # rax = rdi = 3
    400553: imul %rsi,%rax   # rax = rax * rsi = 3 * 5 = 15
    400557: ret              # 返回
    ```
    - `%rax ← 15`
    - `%rip = 0x400557`
    - `栈顶 [rsp] = 0x400549`
  - 执行 ret 指令
    - ret 自动完成：
      - 从栈顶读取返回地址：`ret_addr = [rsp] = 0x400549`
      - 弹栈：`rsp = rsp + 8`
      - 跳转回返回地址：`rip = ret_addr = 0x400549`
    - 同时：
      - `%rip = 0x400549`
      - 程序返回到`mov %rax,(%rbx)`（在`multstore`中）
#three-line-table[
  | 阶段       | 指令            | %rsp 变化            | %rip 变化       | 栈内容                | 备注           |
  | -------- | ------------- | ------------------ | ------------- | ------------------ | ------------ |
  | 调用前      | (call 前)      | `0x7fffffffdbe0`   | `0x400544`    | 空闲                 | 准备调用         |
  | 执行 call  | `call 400550` | → `0x7fffffffdbe8` | → `0x400550`  | `[rsp] = 0x400549` | 压栈返回地址并跳转    |
  | 执行 mult2 | …             | 保持不变               | 跑到 `0x400557` | 栈内容不变              | mult2 内执行    |
  | 执行 ret   | `ret`         | → `0x7fffffffdbe0` | → `0x400549`  | 弹出返回地址             | 返回 multstore |
]

==== Passing data

在过程调用中，除了控制转移（上一节的`call/ret`）之外，编译器还必须解决：
- 如何把参数传递给被调函数（arguments）
- 如何返回结果（return value）
- 何时需要借助栈来传递数据

*寄存器参数传递规则（x86-64 System V ABI）*
- 在 x86-64 Linux / macOS ABI 中：
  #three-line-table[
    | 参数顺序  | 使用寄存器  | 说明                  |
    | ----- | ------ | ------------------- |
    | 第1个参数 | `%rdi` | (Destination Index) |
    | 第2个参数 | `%rsi` | (Source Index)      |
    | 第3个参数 | `%rdx` | (Data)              |
    | 第4个参数 | `%rcx` | (Counter)           |
    | 第5个参数 | `%r8`  |       \              |
    | 第6个参数 | `%r9`  |        \             |
    | 其余参数  | 栈上传递   | 超过 6 个参数时，继续往栈上压    |
  ]
- 返回值放在 `%rax` 寄存器中
  - 函数返回值 → `%rax`
  - 若返回结构体（多个值），则特殊规则（暂略）
*multstore / mult2 数据流分析*
```
Caller: multstore(x=3, y=5, dest=&res)
-------------------------------------------------------
%rdi = 3       (x)
%rsi = 5       (y)
%rdx = &res    (dest)
call mult2
  ↓
Callee: mult2(a=3, b=5)
-------------------------------------------------------
%rdi = 3       (a)
%rsi = 5       (b)
mov %rdi,%rax  → %rax = 3
imul %rsi,%rax → %rax = 15
ret → %rax = 15, 返回到 multstore
  ↓
Back to multstore
-------------------------------------------------------
%rax = 15
mov %rax,(%rbx) → *dest = 15
```
multstore 调用 mult2 的完整数据流
- 函数入口（multstore）
  ```asm
  400540: push %rbx        # 保存 %rbx（被调者保存寄存器）
  400541: mov  %rdx,%rbx   # 把 dest（在 %rdx）保存到 %rbx
  400544: call 400550 <mult2>  # 调用 mult2(x,y)
  ```
  #three-line-table[
    | 寄存器    | 含义       | 值              |
    | ------ | -------- | -------------- |
    | `%rdi` | x        | 3              |
    | `%rsi` | y        | 5              |
    | `%rdx` | dest     | 0x7fffffffdc00 |
    | `%rbx` | dest（复制） | 0x7fffffffdc00 |
  ]
- 调用 mult2
  ```asm
  400550: mov  %rdi,%rax    # rax = a = 3
  400553: imul %rsi,%rax    # rax = rax * b = 3*5=15
  400557: ret               # 返回，结果在 %rax
  ```
  `%rax = 15`
- multstore 接收返回值
  ```asm
  400549: mov  %rax,(%rbx)  # *dest = rax (即 *dest = 15)
  40054c: pop  %rbx
  40054d: ret
  ```
  #three-line-table[
    | 寄存器      | 含义      | 值              |
    | -------- | ------- | -------------- |
    | `%rbx`   | dest 地址 | 0x7fffffffdc00 |
    | `%rax`   | 返回值（t）  | 15             |
    | `(%rbx)` | \*dest   | 15（写入内存）       |
  ]

==== Managing local data

*管理局部数据 / 栈帧机制*

*为什么要有栈帧（Stack Frame）*
- 在支持*递归*的语言（如 C、Pascal、Java）中，
  - 同一个函数可以多次被调用、并且每次调用都要有独立的数据副本。
  - 因此，程序需要一种机制来：
    - 保存函数调用的上下文状态（arguments、locals、return address）
    - 能够在函数返回后恢复上一级状态
    - 确保函数是 reentrant（可重入的）
  - 这就是——栈帧（Stack Frame）
- 栈帧（Stack Frame）的职责
  - 每次调用函数，系统会在栈上创建一个新的“帧（frame）”，
它是该函数调用的局部工作区。
- 一个栈帧典型包含：
  #three-line-table[
    | 区域        | 内容                     | 说明                     |
    | --------- | ---------------------- | ---------------------- |
    | *返回地址*  | 调用者下一条指令的地址            | `call` 自动压栈            |
    | *旧帧指针*  | 上一函数的 `%rbp`           | 用于恢复调用者的栈环境            |
    | *局部变量*  | 函数内部定义的变量              | 通常存放在 `%rsp` 以下        |
    | *临时空间*  | 计算或寄存器溢出值              | 临时保存中间结果               |
    | *保存寄存器* | 需要保护的 callee-saved 寄存器 | 例如 `%rbx`, `%r12–%r15` |
  ]
*栈帧的建立与释放过程*
- 栈帧的生成与销毁由两部分组成：
  - 函数入口（prologue，进入函数）
    ```asm
    push %rbp          # 保存旧帧指针
    mov  %rsp, %rbp    # 建立新的帧指针
    sub  $N, %rsp      # 为局部变量分配空间
    ```
  - 函数退出（epilogue，离开函数）
    ```asm
    leave              # 等价于 mov %rbp, %rsp; pop %rbp
    ret                # 弹出返回地址并跳转
    ```
举例：函数嵌套调用（Call Chain）
```c
void yoo() {
    who();
}
void who() {
    amI();
}
void amI() {
    amI();
}
```
调用链：
```
yoo() → who() → amI() → amI() → ...
```
每进入一次函数，就会建立一个新的 栈帧，形成“栈帧链”：
```
高地址 ↑
│
│ yoo() Frame
│--------------------
│ who() Frame
│--------------------
│ amI() Frame (第1次)
│--------------------
│ amI() Frame (第2次)
│--------------------
│ amI() Frame (第3次)
│-------------------- ← 栈顶 (%rsp)
低地址 ↓
```

#newpara()

*x86-64 / Linux（SysV ABI） 的栈帧结构*
- 一张“从上到下”的栈帧速览（当前函数）
  ```
  ...                    ← 更高地址（调用者更老的帧）
  ┌───────────────────────────────┐
  │ 参数 7+（给“将要调用”的函数） │  ← Argument build area（仅当要放栈参数时）
  ├───────────────────────────────┤
  │ 返回地址（call 自动压入）      │  ← 属于调用者帧的顶部
  ├───────────────────────────────┤
  │ 旧 %rbp（可选）                │  ← 建帧指针风格才有
  ├───────────────────────────────┤
  │ Saved Registers（被调者保存寄存器） │  ← 如 %rbx, %r12–%r15
  │ Local Variables / Temporaries │  ← 函数局部变量、临时存储区
  ├───────────────────────────────┤
  │ Argument build area（可选）   │  ← 给“将要调用”的函数放参数用
  └───────────────────────────────┘
  ...                    ← 更低地址（栈顶向下）
  ```
  - `%rsp` 指向当前栈顶
  - 如使用帧指针，`%rbp` 指向“旧 `%rbp`”之上，作为当前帧的基准
- *调用协定*：谁保存什么（寄存器）
  - 调用者保存 (caller-saved)：`%rdi` `%rsi` `%rdx` `%rcx` `%r8` `%r9` `%r10` `%r11`（要跨调用保留就自己先保存）
  - 被调者保存 (callee-saved)：`%rbx` `%rbp` `%r12` `%r13` `%r14` `%r15`（被调函数若用到，进函数时保存、返回前恢复）
  - 返回值：`%rax`
  - 前 6 个整数/指针参数：`%rdi` `%rsi` `%rdx` `%rcx` `%r8` `%r9`；第 7 个起放在调用者栈的 argument-build 区。
- *栈对齐与“构建参数区”*
  - 对齐规则：在执行 `call` 之前，要求 `%rsp 16` 字节对齐。`call` 会再压 8 字节返回地址，使被调函数入口处 `%rsp ≡ 8 (mod 16)`（ABI 规定）
  - 因此调用前，调用者常会在栈上预留/调整若干字节：
    - 放第 7 个及以后的参数
    - 凑齐对齐（即使没有多余参数也可能 `sub $8,%rsp` 之类）
  - Linux SysV 无“home space”（不像 Windows x64 固定为寄存器形参留 32B 影子空间）
- *可选/特殊区域*
  - 旧 `%rbp`（帧指针）：优化编译常用 frame-pointer-omission（省略 `%rbp`），直接用 `%rsp`+偏移访问局部变量，此时没有“旧 `%rbp`”槽。
  - Red Zone（红区）：在 SysV/Linux，`%rsp` 下方 128 字节可供叶子函数（不调用别的函数）临时使用，无需 `sub` 栈空间；内核/中断不会破坏它（信号处理栈切换也保证安全）。但调用别的函数就不能依赖红区
  - 可变参数函数 (variadic)：被调者通常在自己的栈帧里建立寄存器保存区，把到达的寄存器实参溢出到栈，供 `va_arg` 使用

例子
```c
long incr(long *p, long val) {
    long x = *p;
    long y = x + val;
    *p = y;
    return x;
}

long call_incr() {
    long v1 = 15213;
    long v2 = incr(&v1, 3000);
    return v1 + v2;
}
```
对应的汇编（GCC -O0）：
```asm
call_incr:
    subq  $16, %rsp
    movq  $15213, 8(%rsp)
    movl  $3000, %esi
    leaq  8(%rsp), %rdi
    call  incr
    addq  8(%rsp), %rax
    addq  $16, %rsp
    ret

incr:
    movq  (%rdi), %rax
    addq  %rax, %rsi
    movq  %rsi, (%rdi)
    ret
```
逐步状态
- 进入 `call_incr`（尚未执行函数体）
  ```
  地址高 ↑
  [S+?]   …（更早的帧）
  [S]     返回到 caller 的地址   ← %rsp = S
  地址低 ↓
  ```
- `subq $16, %rsp` —— 为本函数局部留 16B
  ```
  地址高 ↑
  [S]     返回地址（属于 caller 帧）
  [S-8]   （未用）             ← %rsp+8
  [S-16]  （未用）             ← %rsp = S-16
  地址低 ↓
  ```
  这 16 字节是 `call_incr` 的当前帧。`8(%rsp)` 用来放 `v1`，`(%rsp)` 这 8 字节暂时不用。
- `movq $15213, 8(%rsp)` —— 写入 `v1`
  ```
  [S]     返回地址
  [S-8]   15213 (= v1)         ← %rsp+8
  [S-16]  （未用）             ← %rsp
  ```
- `movl $3000, %esi` （参数2：`val`）
  - 对 32 位寄存器 `%esi` 的写入会自动把 `%rsi` 的高 32 位清零。现在：`%rsi = 3000`
- `leaq 8(%rsp), %rdi` （参数1：`&v1`）
  - 只是地址计算，不访问内存。现在：`%rdi = S-8`（指向 `v1`）
- `call incr` —— 调用 `incr`
  - 压栈返回地址，跳转到 `incr`，建立 `incr` 的栈帧（无局部变量，无保存寄存器）
    - 调用瞬间的栈变化（仅在 `incr` 执行期间存在的返回槽）：
    ```
    地址高 ↑
    [S]      返回到 caller
    [S-8]    15213 (= v1)
    [S-16]   （未用）
    [S-24]   返回到 call_incr 内的地址（call 下一条）  ← %rsp = S-24（进入 incr）
    地址低 ↓
    ```
- 在 `incr` 内部
  - `movq (%rdi), %rax` —— 取 `x = *p`
    - 从地址 `S-8` 读 `15213` 到 `%rax`
    - 此时：`%rax = 15213`（这就是将来要返回的 `v2`）
  - `addq %rax, %rsi` —— `y = x + val`
    - `%rsi = 3000 + 15213 = 18213`
  - `movq %rsi, (%rdi)` —— `*p = y`
    - 把 `18213` 写回地址 `S-8`（更新 `v1`）
    - 此刻，`call_incr` 的栈槽里 `v1` 已经变成 `18213`
  - `ret` —— 返回 `call_incr`
    - 从栈顶弹出返回地址 S-24 处的 8 字节到 `%rip`，跳回 `call_incr` 的 call 下一条
    - 同时 `%rsp` 恢复为 S-16
    - 返回值在 `%rax`，仍是 `15213`（旧的 `x`）
  - `ret` 后栈恢复为：
    ```
    地址高 ↑
    [S]     返回到 caller
    [S-8]   18213 (= v1 已更新)
    [S-16]  （未用）             ← %rsp
    地址低 ↓
    ```
- `addq 8(%rsp), %rax` —— 计算 `v1 + v2`
  - 读取 `8(%rsp)`（即 S-8）现在是 `18213`
  - `%rax` 里是 `v2 = 15213`
  - 相加后 `%rax = 15213 + 18213 = 33426`
- `addq $16, %rsp` —— 释放栈空间
  - `%rsp` 恢复为 S
- `ret` —— 返回 caller
  - 弹出 S 处的返回地址到 `%rip`，回到 `call_incr` 的调用者
  - 返回值在 `%rax`，是 `33426`

*寄存器保存约定（Register Saving Conventions）*
- 寄存器保存约定（Register Saving Conventions），是过程调用（Procedure Call）最重要的“协议之一”，即 谁负责保存寄存器内容
- 问题背景：寄存器会被谁改？
  ```asm
  yoo:
      movq $15213, %rdx   # yoo 想暂存在 %rdx
      call who
      addq %rdx, %rax
      ret

  who:
      subq $18213, %rdx   # who 也用 %rdx 做临时计算
      ret
  ```
  问题：`who`（被调者）修改了 `%rdx`，返回后 `yoo` 继续用 `%rdx`，但值已经变了 → 出错！
  - 我们需要约定（Conventions）来协调双方：
    - 哪些寄存器由调用者在调用前保存；
    - 哪些寄存器由被调者在使用前保存。
- 两类寄存器保存约定
  #three-line-table[
    | 名称               | 又称                    | 谁来保存                       | 用法举例        | 常见寄存器                                        |
    | ---------------- | --------------------- | -------------------------- | ----------- | -------------------------------------------- |
    | *Caller-saved* | call-clobbered（调用者负责） | 调用者调用前若想保留值，先自己 `push` 到栈上 | 临时寄存器、参数寄存器 | `%rax %rcx %rdx %rsi %rdi %r8 %r9 %r10 %r11` |
    | *Callee-saved* | call-preserved（被调者负责） | 被调者如果想改，就先保存旧值、用完再恢复       | 需在多个函数间保持   | `%rbx %rbp %r12 %r13 %r14 %r15`              |
  ]

*x86-64 Linux 寄存器使用规范（Register Usage Convention）*
- x86-64 一共有 16 个通用寄存器：
  ```
  %rax %rbx %rcx %rdx %rsi %rdi
  %rbp %rsp
  %r8  %r9  %r10 %r11 %r12 %r13 %r14 %r15
  ```
  但它们在 函数调用 里职责不同：
  - 有的用于*传参*
  - 有的保存*返回值*
  - 有的用作*临时寄存器*
  - 有的要在*调用间保持不变*
- Caller-saved 区
  #three-line-table[
    | 寄存器                                  | 功能             | 特性           |
    | ------------------------------------ | -------------- | ------------ |
    | *%rax*                             | 返回值；中间计算结果     | Caller-saved |
    | *%rdi, %rsi, %rdx, %rcx, %r8, %r9* | 前 6 个参数        | Caller-saved |
    | *%r10, %r11*                       | 临时使用寄存器（中间计算用） | Caller-saved |
  ]
- Callee-saved 区（x86-64 Linux）
  #three-line-table[
    | 寄存器             | 功能               | 特性              |
    | --------------- | ---------------- | --------------- |
    | *%rbx*        | 常用临时保存寄存器        | Callee-saved    |
    | *%r12 – %r15* | 临时保存寄存器（函数可自由使用） | Callee-saved    |
    | *%rbp*        | 传统帧指针（有时省略）      | Callee-saved    |
    | *%rsp*        | 栈指针（必须恢复原值）      | 特殊 Callee-saved |
  ]

```
───────────────────────────────
Caller-saved (volatile)
───────────────────────────────
%rax   Return value
%rdi   Arg1
%rsi   Arg2
%rdx   Arg3
%rcx   Arg4
%r8    Arg5
%r9    Arg6
%r10   Temporary
%r11   Temporary
───────────────────────────────
Callee-saved (non-volatile)
───────────────────────────────
%rbx   Must restore
%rbp   Must restore (frame ptr)
%r12   Must restore
%r13   Must restore
%r14   Must restore
%r15   Must restore
%rsp   Must restore to original
───────────────────────────────
```

#note(subname: [小结：寄存器使用惯例])[
  - 程序寄存器组是唯一能被所有过程共享的资源。
    - 虽然在给定时刻只能有一个过程是活动的， 但是我们必须保证当一个过程（调用者）调用另一个过程（被调用者）时，被调用者不会覆盖某个调用者稍后会使用的寄存器的值。
  - X86-64采用了一组统一的寄存器使用惯例，所有的过程都必须遵守，包括程序库中的过程。
    - 根据惯例，寄存器％rbx, %rbp和％r12-%r15被划分为被调用者保存寄存器。当过程P调用过程Q时，Q必须保存这些寄存器的值，保证它们的值在Q返回到P时与Q被调用时是一样的。
    - 所有其他的寄存器，除了栈指针%rsp，都分类为调用者保存寄存器。这就意味着任何函数都能修改它们。
]

=== Illustration of Recursion

*举例*：递归 popcount的 C 代码如何映射到 x86-64 汇编
```c
long pcount_r(unsigned long x) {
    if (x == 0) return 0;
    else return (x & 1) + pcount_r(x >> 1);
}
```
汇编（System V；x→%rdi，返回值→%rax）：
```asm
pcount_r:
    movl  $0, %eax        # 先把返回寄存器清零（32 位写会清 %rax 高 32 位）
    testq %rdi, %rdi      # x == 0 ?
    je    .L6             # 是的话跳到返回

    pushq %rbx            # 保存 callee-saved，下面要用 %rbx
    movq  %rdi, %rbx      # %rbx = x
    andl  $1, %ebx        # %rbx = x & 1  （低位比特）
    shrq  %rdi            # %rdi = x >> 1 （递归实参）
    call  pcount_r        # 递归调用，返回值在 %rax
    addq  %rbx, %rax      # %rax += (x & 1)
    popq  %rbx            # 恢复 callee-saved
.L6:
    rep;  ret             # 返回（rep 前缀是性能/预测小技巧）
```
- 终止条件（Terminal Case）
  #three-line-table[
    | 寄存器 | 使用 | 类型 |
    | ---- | ---- | -- |
    | `%rdi` | `x` | Argument |
    | `%rax` | 返回值 | Return Value |
  ]
- 寄存器保存（Register Save）
  #three-line-table[
    | 寄存器 | 使用       | 类型            |
    | ---- | -------- | ------------- |
    | `%rdi` | `x`       | Argument      |
  ]
- 递归调用前的准备（Call Setup）
  #three-line-table[
    | 寄存器 | 使用       | 类型            |
    | ---- | -------- | ------------- |
    | `%rdi` | `x >> 1`  | Argument      |
    | `%rbx` | `x & 1`   | Temporary, Callee-saved     |
  ]
- 递归调用（Call），合并结果（Result Combine）
  #three-line-table[
    | 寄存器 | 使用       | 类型            |
    | ---- | -------- | ------------- |
    | `%rbx` | `x & 1`   | Temporary, Callee-saved     |
    | `%rax` | 返回值     | Return Value  |
  ]
- 完成返回（Completion）
  #three-line-table[
    | 寄存器 | 使用   | 类型          |
    | ---- | ---- | ----------- |
    | `%rax` | 返回值 | Return Value |
  ]

*递归在汇编层面的核心特点*
- 在机器层面，递归调用与普通函数调用没有任何“特别的机制”。它完全依赖以下三样东西实现：
  - 栈帧 (stack frame) ：每次调用分配独立的一块内存区域，用于保存局部变量、参数、返回地址
  - 寄存器保存约定 (register saving conventions) ：保证不同函数实例互不干扰
  - 栈的 LIFO 结构 ：后调用的函数先返回，完美契合递归调用顺序
- 栈帧的作用
  - 每一次调用都有独立的：
    - 返回地址（由 call 自动 push）
    - 保存的寄存器（如 %rbx、%rbp）
    - 局部变量或临时值
  - 这就是为什么递归可以安全进行多层嵌套而互不干扰。每一层的“函数状态”都被保存在独立的帧上。
- Register Saving Conventions 的保障作用
  - 调用约定要求：
    - caller-saved 寄存器：调用者必须在 call 前自己保存
    - callee-saved 寄存器：被调者必须在用之前 push，用完 pop 恢复
  - 因此：
    - 每一层 pcount_r 都可以安全使用 `%rbx` 保存
    - 不会破坏上层的 `%rbx` 值。
  #three-line-table[
    | 特性            | 机制                          | 作用            |
    | ------------- | --------------------------- | ------------- |
    | *每次调用独立栈帧*  | `call` + `%rsp` 调整          | 隔离局部状态        |
    | *寄存器保存规则*   | caller-saved / callee-saved | 避免破坏其他调用的寄存器值 |
    | *返回地址入栈*    | `call` 指令自动 `push`          | 保证函数返回正确      |
    | *栈 LIFO 模式* | `push` / `pop`              | 实现递归自然的回退顺序   |
    | *互相递归也安全*   | 各自维护返回指针                    | 可自由调用         |
  ]
