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
