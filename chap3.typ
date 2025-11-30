#import "@preview/scripst:1.1.1": *

= Computer Architecture

== ISA

=== Coverage

课程采用 “从 ISA 到微架构” 的方式：
- 先定义指令集（Y86-64）
  - 指令编码
  - 功能
  - 机器状态（寄存器、条件码、PC）
- 然后构建处理器微架构
  - 数据通路（Datapath）
    - ALU（算术逻辑单元）
    - 寄存器文件
    - 取指（Fetch）单元
    - 译码（Decode）单元
    - 执行（Execute）
    - 访存（Memory）
    - 写回（Writeback）
  - 控制逻辑（Control Logic）
    - 根据当前指令决定 datapath 如何流动
    - 本质上是状态机 + 布尔逻辑
  - 使用硬件描述语言（HCL）
    - CS:APP 定义了一门简单的 HDL — HCL (Hardware Control Language)，用于：
      - 描述 control 逻辑
      - 可扩展、修改
      - 可模拟运行
      - 也可以路由到 Verilog（工业标准 HDL）

*ISA：指令集体系结构是什么*？
- ISA 是程序员与硬件之间的抽象接口。它定义了：
  - *指令（instructions）*的集合与行为
  - 寄存器（register file）
  - 内存模型（addressing model）
  - 机器状态（machine state）
  - 调用规范、异常行为等
- ISA 不关心处理器内部如何执行，只规定执行的效果。例如：
  ```asm
  addq %rax, %rbx
  ```
ISA规定：
- 执行完成后，RBX = RBX + RAX
- 其它状态不变
但怎么做（pipeline? microcode? out-of-order?）属于下一层：微架构（microarchitecture）。

*为什么 CS:APP 选择 Y86-64 ISA？*
- Intel x86-64 真实 ISA 太复杂，而 Y86-64 是其简化版本。
- Y86-64 的目标：
  - 与 x86-64 行为高度相似（寄存器、指令语义）
  - 移除复杂指令和状态机制
  - 便于阅读、手工执行和硬件设计
  - 可以用来构建一个实际可运行的处理器模型

=== Instruction Set Architecture

*ISA 的定位：连接软件与硬件的关键抽象层*
- ISA（Instruction Set Architecture）是计算机系统中非常核心的抽象层，它位于：
  - 上层：程序员、编译器、操作系统
  - 下层：CPU 微架构、电路、芯片物理实现
  典型的计算机系统分层模型：
  ```
  Application Programs
          ↓
        Compiler
          ↓
          OS
          ↓
         ISA ←——— Programming interface to hardware
          ↓
      CPU Microarchitecture
          ↓
      Circuit Design (gates, transistors)
          ↓
        Chip Layout
  ```
  ISA 定义了处理器必须呈现给程序的抽象行为。ISA 不关心 CPU 如何实现这些行为（那是微架构问题）。
- *Assembly Language View（从汇编程序的视角看 ISA）*
  - *Processor State（处理器状态）* 这是程序能够观察、使用和影响的状态，包括：
    - 寄存器（Registers）
      - 通用寄存器（如 x86-64: %rax, %rbx, %rcx, …）
      - 程序计数器 PC（program counter）
      - 条件码（condition codes）
      - 栈指针（stack pointer）
    - 内存（Memory）
      - 字节可寻址
      - 指定的内存模型（如小端序）
  这些状态就是“机器对程序公开的全部信息”。
  - *Instructions（指令）*
    - ISA 定义可执行的指令集合及其行为，例如：
      - `addq`（整数加法）
      - `pushq`（入栈）
      - `call` / `ret`（过程调用）
      - `jmp` / `jle`（条件跳转）
      - `movq`（数据传送）
    - 并且 ISA 明确规定：
      - 每条指令如何改变处理器状态
      - 指令编码格式（如何用字节表示指令）
      - 异常情况下执行应如何变化
- *ISA 是一个抽象层：上看程序、下看硬件*
  - “Above”：如何编程机器（给程序员和编译器的抽象）
    - 在 ISA 之上：
    - 程序员或编译器编写指令序列
    - 假设 CPU 会按照指令定义的语义顺序执行
  - “Below”：如何构建 CPU（给硬件设计者的约束）
    - 在 ISA 之下：
    - 硬件设计者必须构造一个微架构，使其对外表现如同 ISA 定义的行为。
    - 但微架构具有极大自由度，例如：
      - 单周期（simple）
      - 多周期（sequential）
      - 流水线（pipelined）
      - 超标量（superscalar）
      - 多发射（multiple instruction issue）
      - 乱序执行（out-of-order execution）
      - 推测执行（speculative execution）
    - 也就是说：ISA 是“应该做什么”，微架构是“如何高效地实现它”。
- 为什么 ISA 如此重要？
  - ISA 是关键的“契约（contract）”，保证：
    - 程序能够跨不同微架构运行
    - 编译器不需要关心 CPU 内部细节
    - 操作系统与硬件的交互实现标准化
    - 硬件团队可以自由创新提升性能而不破坏软件

*抽象层次*
- ISA在编译器编写者和处理器设计人员之间提供了一个概念抽象层
  - 编译器编写者
    - 只需要知道允许哪些指令，以及它们是如何编码的
    - 机器代码优化
  - 处理器设计者
    - 建造出执行这些指令的处理器
    - 高效执行指令
- 这种分层的结构与互联网的层次化模型类似

=== CISC vs RISC

*CISC 指令集（Complex Instruction Set Computer）*
- 典型代表
  - IA-32（x86）
  - x86-64 是其后续版本
- *CISC 的关键特征*
  - *Stack-Oriented（栈导向）*
    - 使用栈来传递参数、保存返回地址
    - 有显式的 `push`, `pop`, `call`, `ret` 指令
    - 很多系统调用依赖栈框架（stack frame）
  - *Arithmetic instructions can access Memory（内存地址）*
    - 例如：
      ```asm
      addq %rax, 12(%rbx,%rcx,8)
      ```
    - 这条指令的行为：
      - 访问内存地址 = `%rbx + %rcx × 8 + 12`
      - 读该地址的值
      - 将其与 `%rax` 相加
      - 写回同一地址
    - 一条指令执行多步操作：
      - 地址计算
      - 内存读
      - 运算
      - 内存写
  - *复杂寻址模式*
    - base + index × scale + offset
    - 直接地址
    - 间接寻址
    - 相对寻址
  - *Condition codes（条件码）*
    - 算术指令会隐式设置：ZF（zero flag）、SF（sign flag）、CF（carry）、OF（overflow）
    - 然后由 `jz/jl/jge` 等指令使用
  - *设计哲学*
    - “让单条指令完成更复杂的工作”，例如：
      - 内存操作直接参与算术
      - 栈框架的自动维护
      - 字符串操作（rep movsb）
    - 目的是：
      - 减少指令数量
      - 让编译器更容易生成代码
      - 减少代码大小（重要于早期内存昂贵时代）
  - X86指令集中指令数量增长趋势

*RISC 指令集（Reduced Instruction Set Computer）*
- 典型代表
  - MIPS
  - ARM（现代广泛使用）
  - RISC-V（当前学术与工业强势增长）
- *RISC 的核心思想*
  - *简单、固定长度的指令*
    - MIPS 是 32-bit 定长
    - 无复杂寻址方式
  - *Register-Oriented（寄存器导向）*
    - 提供大量寄存器（典型为 32 个）
    - 几乎所有运算都在寄存器之间进行
  - *Load/Store Architecture*
    - 只有两类指令能访问内存：
      - `lw（load word）`
      - `sw（store word）`
    - 类似于 Y86 的：
      - `mrmovq`
      - `rmmovq`
    - 其余所有算术操作永远不直接访问内存。
  - *无条件码*
    - 比较指令显式把结果写入寄存器（0 或 1），如：
    ```asm
    slt $t0, $t1, $t2  # if t1 < t2 then t0 = 1 else t0 = 0
    ```
  - *简化硬件设计、提高流水线效率*
    - 少数几种指令格式，极简控制逻辑，使得：
    - 更高频率
    - 更深流水线
    - 更容易支持 superscalar、out-of-order

*MIPS示例*
- MIPS 寄存器结构
  #three-line-table[
    | 寄存器        | 用途                  |
    | ---------- | ------------------- |
    | `$0`       | 常数 0                |
    | `$at`      | assembler temporary |
    | `$v0-$v1`  | 函数返回值               |
    | `$a0-$a3`  | 函数参数                |
    | `$t0-$t7`  | Caller-save 临时      |
    | `$s0-$s7`  | Callee-save 寄存器     |
    | `$t8-$t9`  | 额外 caller-save      |
    | `$k0-$k1`  | OS 保留               |
    | `$gp`      | 全局指针                |
    | `$sp`      | 栈指针                 |
    | `$fp($s8)` | 帧指针                 |
    | `$ra`      | 返回地址                |
  ]
- MIPS 指令示例（非常规则化）
  - R-R（寄存器-寄存器）
    ```asm
    addu $3,$2,$1   # $3 = $2 + $1
    ```
    ```
    [ Op ][ Ra ][ Rb ][ Rc ][ Shamt ][ Funct ]
    ```
  - R-I（寄存器-立即数）
    ```asm
    addi $3,$2,100  # $3 = $2 + 100
    ```
    ```
    [ Op ][ Ra ][ Rb ][      Imm      ]
    ```
  - Shift
    ```asm
    sll $3,$2,4     # $3 = $2 << 4
    ```
    ```
    [ Op ][ Ra ][ Rb ][ Shamt ][ Funct ]
    ```
  - Load/Store
    ```asm
    lw $3,100($2)   # $3 = MEM[$2 + 100]
    sw $3,100($2)   # MEM[$2 + 100 = $3]
    ```
    ```
    [ Op ][ Ra ][ Rb ][     Offset      ]
    ```
  - Branch
    ```asm
    beq $2,$3,Label # if ($2 == $3) PC = Label
    ```
    ```
    [ Op ][ Ra ][ Rb ][     Offset      ]
    ```

*CISC vs. RISC ——历史争论与现代观点*
- 原始争论（1980s–1990s）
  - CISC 支持者认为：
    - 高级指令 → 更少的指令数 → 更少内存访问
    - 编译器更容易
    - 程序占用空间更小
  - RISC 支持者认为：
    - 指令简单、可流水线化 → CPU 更快
    - 优化编译器可以自动消除 CISC 的优势
    - 更易实现 superscalar / OoO
  - 双方在 80–90 年代有强烈分歧
- 现实情况（1990s–至今）
  - 结论很明确：
    - “ISA 不是性能关键，只要硬件足够强，任何 ISA 都能做快。”
  - 例如：
    - x86 内部将 CISC 指令翻译成 RISC 微指令（micro-ops）
    - 现代 x86 其实是“外CISC、内RISC”
  - 当前趋势：
    - 桌面处理器：
      - 主要使用 x86-64（兼容性最重要）
      - 内部大量采用 RISC 结构（微操作、中间表示）
    - 嵌入式与移动：
      - RISC 更强
      - ARM 占主导（廉价、低功耗、面积小）
    - 学术与新工业项目：
      - RISC-V 作为开源 ISA 正在快速发展

*Y86 的位置*：介于 CISC 与 RISC 之间
- CS:APP 的 Y86 是教学 ISA，融合两个体系的特点：
- CISC 风格：
  - 长度可变的指令编码
  - 隐式条件码（ZF/SF/OF）
  - 栈密集型过程调用（push/pop/call/ret）
- RISC 风格：
  - load/store 型内存访问
  - 少量简单指令格式
  - 规则化的编码方式
- 因此 Y86 是一个“可用来构建硬件”的简化模型，可以让学生：
  - 学习 ISA 设计
  - 自己实现处理器（SEQ, PIPE）
  - 理解 CISC/RISC 思想

=== Y86-64 Instruction Set Architecture

==== Y86-64 Processor State（处理器状态）

Y86-64 的 processor state 是程序执行过程中 CPU 必须维护的全部可见状态。

它包括：
- 寄存器文件（RF）
- 条件码（Condition Codes, CC）
- 程序计数器（PC）
- 程序状态（Stat）
- 数据内存（DMEM）
这些状态共同定义了：任意时刻机器“该是什么样子”。

- *程序寄存器（Program Registers）*
  - Y86-64 有 15 个可用寄存器，每个 64 bits：
  #three-line-table[
    | 寄存器      | 说明                   |
    | -------- | -------------------- |
    | %rax     | 返回值寄存器               |
    | %rcx     | 通用寄存器                |
    | %rdx     | 通用寄存器                |
    | %rbx     | 通用寄存器                |
    | %rsp     | 栈指针                  |
    | %rbp     | 帧指针                  |
    | %rsi     | 参数寄存器                |
    | %rdi     | 参数寄存器                |
    | %r8–%r14 | 通用寄存器                |
  ]
  Y86-64 有 15 个寄存器，对应 ID 0–14。ID 15（0xF）表示“无寄存器（no register）”。
- *Condition Codes（条件码）*
  - 由算术/逻辑指令（如 `addq, subq, xorq, andq`）设置：
    - ZF: Zero Flag 表示结果是否为 0
    - SF: Sign Flag 表示结果是否为负
    - OF: Overflow Flag 表示有无补码溢出
  - 这些条件码被跳转指令（`jXX`）与条件传送指令（`cmovXX`）使用
- *PC（Program Counter）*
  - PC 始终指向下一条即将执行的指令的地址。
  - 执行完一条指令后，PC 会根据：
    - 指令长度（顺序执行）
    - 指令类型（call, ret, jXX）
    进行更新
- *Stat（Program Status）*
  - 表示程序当前状态：
  #three-line-table[
    | 状态码     | 含义               |
    | ------- | ---------------- |
    | *AOK* | 正常执行             |
    | *HLT* | 执行 `halt` 指令     |
    | *ADR* | 无效内存地址           |
    | *INS* | 无效指令（bad opcode） |
  ]
  处理器执行检测到错误时将 Stat 改为 ADR 或 INS
- Memory（DMEM）
  - *字节可寻址（byte-addressable）*
  - 按*小端序（little-endian）*存储多字节数据
  - 程序代码与数据都存放在统一的地址空间中

==== Y86-64 Instruction Set & Format

Y86-64 的每条指令：
- 长度从 1 到 10 字节
- 编码格式简单规则
- 第一字节包含：
  - icode（高 4 bit, instruction code）
  - ifun（低 4 bit, function code）
- 第一字节能立即确定指令类型，从而读出后续部分。

*Y86-64 指令编码总览*
- 下表总结指令、编码格式、字段：
  ```
  Instruction      Byte0        Byte1      ...   Additional Bytes
  ----------------------------------------------------------------
  halt             0x00
  nop              0x10
  cmovXX rA,rB     0x2f         rA rB
  irmovq V,rB      0x30         F rB        V(8 bytes)
  rmmovq rA,D(rB)  0x40         rA rB       D(8 bytes)
  mrmovq D(rB),rA  0x50         rA rB       D(8 bytes)
  OPq rA,rB        0x6f         rA rB
  jXX Dest         0x7f         Dest(8 bytes)
  call Dest        0x80         Dest(8 bytes)
  ret              0x90
  pushq rA         0xA0         rA F
  popq rA          0xB0         rA F
  ```
  注意：
  - `F` = 0xF = no register
  - 多数字段均使用 x86-64 相同的寄存器编码
*寄存器编码（4-bit Register IDs）*
- #three-line-table[
    | Register | ID | Register | ID    |
    | -------- | -- | -------- | ----- |
    | %rax     | 0  | %r8      | 8     |
    | %rcx     | 1  | %r9      | 9     |
    | %rdx     | 2  | %r10     | A     |
    | %rbx     | 3  | %r11     | B     |
    | %rsp     | 4  | %r12     | C     |
    | %rbp     | 5  | %r13     | D     |
    | %rsi     | 6  | %r14     | E     |
    | %rdi     | 7  | no reg   | *F* |

  ]
*指令格式要点总结*
- 要点 1：第一字节决定指令类型
  ```
  icode = byte0 >> 4
  ifun  = byte0 & 0xF
  ```
- 要点 2：最多用到两个寄存器字段（1 byte）
  - 高 4 bit = rA
  - 低 4 bit = rB
- 要点 3：立即数（V）或偏移量（D）均为 8 字节 Little Endian
- 要点 4：所有内存地址采用 x86-64 相同的寄存器寻址方式：
  ```
  D(rB)
  ```
  仅提供 base + displacement；不支持 x86 的 scale/index 模式（简化）

==== Y86-64 Instruction Set

===== Arithmetic & Logical Instructions (OPq)

*通用格式（OPq）*
```
icode = 6
ifun = function code
byte0 = 0x6f
byte1 = rA rB
```
#three-line-table[
  | 指令         | ifun | 功能           |
  | ---------- | ---- | ------------ |
  | `addq rA,rB` | `0`    | rB ← rB + rA |
  | `subq rA,rB` | `1`    | rB ← rB − rA |
  | `andq rA,rB` | `2`    | rB ← rB & rA |
  | `xorq rA,rB` | `3`    | rB ← rB ⊕ rA |
]
- 示例：`addq %rax, %rsi`
  - 寄存器编码
    - `%rax = 0x0`
    - `%rsi = 0x6`
  - 编码：
    ```
    60 06
    ```
*指令语义*
- Y86-64 只允许寄存器与寄存器之间进行算术运算
- 内存不能直接参与 OPq（比 x86-64 简洁得多）
- 副作用：设置条件码 CC
  - ZF（结果是否为 0）
  - SF（符号位）
  - OF（补码溢出）

===== Move Instructions（数据传送）

*Register → Register `rrmovq rA, rB`*
```
icode=2
ifun=0
byte0 = 0x20
byte1 = rA rB
```
- 语义：rB ← rA
- 示例：
  - `rrmovq %rsp, %rbx`
  - 编码：
    ```
    20 43
    ```
*Immediate → Register `irmovq V, rB`*
```
icode=3
ifun=0
byte0 = 0x30
byte1 = F rB
V = 8 bytes
```
- 语义：rB ← V
- 示例
  - `irmovq $0xabcd, %rdx`
  - 编码：
    ```
    30 0A cd ab 00 00 00 00 00 00
    ```
  - rA = F = no register
  - V 是 8 字节立即数
*Register → Memory `rmmovq rA, D(rB)`*
```
icode=4
ifun=0
byte0 = 0x40
byte1 = rA rB
D = 8 bytes
```
- 语义：MEM[rB + D] ← rA
- 示例
  - `rmmovq %rcx, 16(%rbp)`
  - 编码：
    ```
    40 19 10 00 00 00 00 00 00 00
    ```
*Memory → Register `mrmovq D(rB), rA`*
```
icode=5
ifun=0
byte0 = 0x50
byte1 = rA rB
D = 8 bytes
```
- 语义：rA ← MEM[rB + D]
- 示例
  - `mrmovq 8(%rsp), %rdi`
  - 编码：
    ```
      50 7C 08 00 00 00 00 00 00 00
    ```

===== Conditional Move Instructions（cmovXX）

`cmovXX` 都是 `rrmovq` 的变体：

*通用格式（cmovXX）*
```
icode = 2
ifun = condition code
byte0 = 0x2f
byte1 = rA rB
```
```
2 fn rA rB
```
ifun 决定条件：
#three-line-table[
  | 指令     | ifun | 条件  | 依赖 CC |
  | ------ | ---- | --- | ----- |
  | `rrmovq` | 0    | 无条件 | 否     |
  | `cmovle` | 1    | ≤   | 是     |
  | `cmovl`  | 2    | <   | 是     |
  | `cmove`  | 3    | =   | 是     |
  | `cmovne` | 4    | ≠   | 是     |
  | `cmovge` | 5    | ≥   | 是     |
  | `cmovg`  | 6    | >   | 是     |
]
- 执行语义：
  - 如果条件成立：rB ← rA
  - 否则：不写寄存器（但指令本身不会阻塞）
- 目的：减少分支，提高流水线性能（类似 x86 cmovcc）

===== Jump Instructions（jXX）

*通用格式（jXX）*
```
icode = 7
ifun = condition code
byte0 = 0x7f
Dest = 8 bytes
```
```
7 fn Dest
```
Dest = 8-byte absolute address（比 x86-64 更简单：无 PC-relative 形式）
#three-line-table[
  | 指令  | ifun | 条件  |
  | --- | ---- | --- |
  | `jmp` | 0    | 无条件 |
  | `jle` | 1    | ≤   |
  | `jl`  | 2    | <   |
  | `je`  | 3    | =   |
  | `jne` | 4    | ≠   |
  | `jge` | 5    | ≥   |
  | `jg`  | 6    | >   |
]

===== Stack Instructions

*Y86-64 Program Stack（程序栈）*
- 与 x86-64 一致：
  - 栈顶由 `%rsp` 表示
  - 栈向*低地址方向*增长
  ```
  High addresses
        |
        v
  +--------------------+
  |   Older frames     |
  |        ...         |
  +--------------------+
  |       Top (%rsp)   |  ← push: rsp -= 8
  |       New data     |  ← pop:  value = M[rsp], rsp += 8
  +--------------------+
  Low addresses
  ```
*pushq rA*
```
icode = 0xA
ifun = 0
byte0 = 0xA0
byte1 = rA F
```
```
A 0 rA F
```
- 语义：
  - `rsp ← rsp - 8`
  - `MEM[rsp] ← rA`
- 示例：
  - `pushq %rbp`
  - 编码：
    ```
    A0 5F
    ```
*popq rA*
```
icode = 0xB
ifun = 0
byte0 = 0xB0
byte1 = rA F
```
```
B 0 rA F
```
- 语义：
  - `rA ← MEM[rsp]`
  - `rsp ← rsp + 8`
- 示例：
  - `popq %rbx`
  - 编码：
    ```
    B0 3F
    ```

===== Procedure Call & Return

*call Dest*
```
icode = 0x8
ifun = 0
byte0 = 0x80
Dest = 8 bytes
```
```
8 0 Dest
```
- 语义：
  - 将*下一条指令的地址*压栈：
    - `rsp -= 8`
    - `M[rsp] = nextPC`
  - PC ← Dest
- 示例：
  - `call 0x4005e8`
  - 编码：
    ```
    80 e8 05 40 00 00 00 00 00
    ```
*ret*
```
icode = 0x9
ifun = 0
byte0 = 0x90
```
- 语义：
  - 从栈顶弹出返回地址到 PC：
    - `nextPC = M[rsp]`
    - `rsp += 8`
  - PC ← nextPC

===== Misc Instructions

*nop (no operation)*
```
icode = 0x1
ifun = 0
byte0 = 0x10
```
- 什么都不做，仅占用一个字节

*halt*
```
icode = 0x0
ifun = 0
byte0 = 0x00
```
- 程序立即停止
- 设置 Stat = HLT
- 模拟器用它来停止程序执行
- 内存初始为全 0，可以自然触发 halt（很方便）T

===== 唯一字节编码（Unambiguous Encoding）

任意字节序列要么：
- 唯一地解析为某条有效指令
- 要么无效 → Stat = INS
这与实际 x86-64 一致，是可执行机器代码的重要属性。

为什么唯一性如此重要？
- 若 encoding 不唯一，处理器在取指阶段（Fetch）会不知道指令长度
- 无法确定接下来要读取多少字节
- 指令流将完全无法解析
- 会导致 PC 无法更新

如何保证唯一性？
- Y86-64 的 第一个字节 = icode:ifun
- 这个组合唯一决定：
  - 该指令需要哪些附加字节
  - 附加字节长度是多少
  - 附加字节含义是什么（寄存器？立即数？偏移？）

==== Y86-64 程序状态码（Stat Conditions）

处理器状态中有一个重要部分是 Stat。Stat 的作用：告诉处理器当前程序是否可以继续执行。
#three-line-table[
  | Mnemonic | Code | 含义                 |
  | -------- | ---- | ------------------ |
  | *AOK*  | 1    | 正常执行               |
  | *HLT*  | 2    | 执行了 halt 指令        |
  | *ADR*  | 3    | 无效地址（坏指令地址或坏数据地址）  |
  | *INS*  | 4    | 无效指令（无法识别的 opcode） |
]
- 执行规则
  - 如果 Stat = AOK → 继续执行
  - 否则 → 停止执行
  - 在 SEQ/PIPE 处理器的控制逻辑中，Stat 是关键入口条件

==== Y86 示例

*如何编写 Y86-64 代码（建议流程）*
- 核心建议：尽量用 C → x86-64 → Y86-64 的方式生成 Y86 程序。
- 步骤如下：
  - 用 C 写逻辑
  - `gcc -Og -S` 编译成 x86-64 汇编
  - 把 x86-64 翻译成 Y86-64 可支持的版本（transliteration）

*求数组长度（null-terminated long array）*

- 初版 C 程序
  ```c
  long len1(long a[]) {
      long len;
      for (len = 0; a[len]; len++)
          ;
      return len;
  }
  ```
  gcc 编译后：会使用 x86-64 的 scaled addressing：
  ```asm
  cmpq $0, (%rdi,%rax,8)
  ```
  问题：Y86-64 不支持 index*scale addressing；必须改写 C，使编译器生成可翻译结构。
- 第二版：显式指针运算（与 Y86 兼容）
  ```c
  long len2(long *a)
  {
      long ip = (long) a;
      long val = *(long *) ip;
      long len = 0;

      while (val) {
          ip += sizeof(long);
          len++;
          val = *(long *) ip;
      }
      return len;
  }
  ```
  gcc 会将 `ip += 8` 和 `*(long*)ip` 转换成简单的：`addq`, `mrmovq`非常适合翻译成 Y86。
- 最终 Y86 版本
  ```asm
  len:
    irmovq $1, %r8        # r8 = 1
    irmovq $8, %r9        # r9 = 8
    irmovq $0, %rax       # len = 0
    mrmovq (%rdi), %rdx   # val = *a
    andq %rdx, %rdx       # test val
    je Done               # if zero, jump
  Loop:
    addq %r8, %rax        # len++
    addq %r9, %rdi        # a++
    mrmovq (%rdi), %rdx   # val = *a
    andq %rdx, %rdx       # test val
    jne Loop              # loop if val != 0
  Done:
    ret
  ```
  寄存器用法
  #three-line-table[
    | Register | Meaning     |
    | -------- | ----------- |
    | `%rdi`     | a (pointer) |
    | `%rax`     | len         |
    | `%rdx`     | val         |
    | `%r8`      | constant 1  |
    | `%r9`      | constant 8  |
  ]

*Y86-64 程序结构*
- init 部分：设置栈指针，启动主程序
  ```asm
  init:
    irmovq Stack, %rsp   # 设置栈顶
    call Main
    halt
  ```
  程序从地址 0 开始执行。必须手动设置栈指针，因为没有操作系统自动初始化。
- 数据段：数组、常量等
  ```
  .align 8
  Array:
    .quad ...
    .quad ...
    .quad ...
    .quad ...
    .quad 0    # terminating 0
  ```
  Y86 支持伪指令 `.quad`（写入 8 字节数据）。
- Main 和其他函数
  ```asm
  Main:
      irmovq array, %rdi
      call len
      ret
  ```
  %rdi 用来传入参数（与 x86-64 ABI 类似），len 返回值存放在 %rax
- Stack 定义
  ```asm
  .pos 0x100
  Stack:
  ```
  - 栈必须放在代码与数据之外
  - 给定初始内存模型，防止访问冲突

=== SA 的现实趋势：RISC-V 时代

1. RISC-V（2016 起）
  - 完全开源
  - 模块化（RV32I, RV64I, F/D 扩展等）
  - 低功耗
  - 适合教学、芯片设计、嵌入式
  - 当前增长最快的 ISA
2. PowerPC → Linux 基金会托管（2019）
  - 架构开放化，社区驱动
3. 新生态源于新的商业模式
  - 开源 ISA → 更低成本 → 更多创新空间
  - 传统 ISA（如 x86）许可模式封闭、成本高
  - RISC-V 适用于软硬件一体化场景

== Logic Design

=== Logic Design Overview（逻辑设计概述）

要构造任何计算机系统，必须满足三类基本硬件能力：
- *Communication（通信）*
  - 如何让数据从一个硬件组件传到另一个组件？
  - 典型手段包括：
    - 单根信号线（wire）传输 0/1
    - 总线（bus）
    - 多路选择器（multiplexer）
    - 扩展器（extender）
    - 控制信号（control signals）
    通信是整个 datapath 的基础
- *Computation（计算）*
  - 硬件必须能够执行逻辑计算，包括：
    - 布尔运算（AND / OR / NOT）
    - 比较、算术运算（加法、位移等）
    - 更复杂的组合逻辑（ALU）
  - 所有这些都是由*组合逻辑电路（combinational logic）*构成，核心思想如下：
    - 输入的变化会“立即”影响输出，系统没有内部状态
    - 最终，所有计算由布尔函数实现
- *Storage（存储）*
  - 硬件必须能够保存状态，例如：
    - 寄存器（register file）
    - 存储器（memory）
    - 条件码寄存器（ZF/SF/OF）
    - 程序计数器（PC）
    - 状态寄存器（Stat）
  - 所有这些均由*时序逻辑（sequential logic）*实现，典型组件包括：
    - 触发器（flip-flop）
    - 寄存器（registers）
    - SRAM / DRAM
  - 存储能力使处理器能够执行多条指令，而不是只是组合逻辑器件
Bits Are Our Friends（比特是硬件的最小单位）
- 计算机系统的一切都可用二值（0/1）表示。
  - 这包括：
    - 指令（bit patterns）
    - 地址
    - 数据（整数、字符、浮点数）
    - 控制信号
    - 条件码
    - 状态机内部状态
  - 原因是：
    - 二值电路最稳定、最易制造、最不易出错
    - 逻辑运算的最基本单元是布尔代数
- *Communication：用 0/1 电压传输信息*
  - 在硬件电路中，“bit = 0/1” 实际上是：
    - 低电压（0V 或接近 0V）→ bit = 0
    - 高电压（例如 1V 或 1.2V）→ bit = 1
  - 通过导线（wire）即可传输信号。
  - 所有硬件通信本质上是“比特的电平传输”。
- Computation：用布尔函数实现运算
  - 例如：
    - AND：x · y
    - OR：x + y
    - XOR：x ⊕ y
    - NOT：¬x
  - 更复杂功能如算术逻辑单元（ALU）也由布尔函数构成：
    - 加法器（carry-lookahead adder）
    - 比较器
    - 多路选择器
  - 组合逻辑能实现所有纯函数计算
- *Storage：用时序逻辑保存比特*
  - 系统需要能够在周期之间保存某些值（状态）：
    - 程序计数器需要保存下一个指令地址
    - 寄存器需要保存当前变量
    - 条件码需要保存当前算术结果状态
  - 这些由触发器 / 寄存器等构建：
    - DFF（D flip-flop）
    - RS latch
    - register file
  - 存储器元件则组成：
    - cache
    - main memory

=== 组合电路

==== Digital Signals（数字信号）

数字电路并不是直接处理 0/1 数字，而是处理电压信号：
- 高电压范围 表示 bit = 1
- 低电压范围 表示 bit = 0
- 中间有 guard range，用于容忍噪声
```
Voltage
  |
1 |───── High (logic 1)
  |
  |----- Guard Range -----
  |
0 |───── Low  (logic 0)
  |
  +---------------------------------> Time
```
- 为什么数字信号可靠？
  - 高/低电平区间宽
  - 只要噪声不超过阈值，仍可正确判断 0/1
  - 所以数字电路可以：
    - 简单
    - 小
    - 快
    - 容错能力强

==== Computing with Logic Gates（使用逻辑门进行计算）

*基本门（AND / OR / NOT）*
- 逻辑门是实现布尔函数的基本单元
- 常见门：
  #three-line-table[
    | Gate | Function     |
    | ---- | ------------ |
    | AND  | out = a && b |
    | OR   | out = a \|\| b |
    | NOT  | out = !a     |
  ]
  逻辑门执行布尔函数，这些函数是整个数字系统的基础。
- 逻辑门是组合逻辑
  - 它们对输入的变化 即时响应（有小延时）：
    - Rising delay：输入从 0→1 时的延时
    - Falling delay：输入从 1→0 时的延时
  - 数字电路设计中的 timing 与同步逻辑将依赖这些延时特性（后面会讲 clocked circuits 与周期时间）。

==== Combinational Circuits（组合电路）

组合电路 = 多个逻辑门按 DAG（无环图）形式组成：
```
Inputs ---> [ Gate Network ] ---> Outputs
```
- 组合电路的三个关键性质：
  - 无环（acyclic）：否则输出会依赖自身，无法定义稳定值
  - 无内部存储：输出仅取决于当前输入
  - 延迟后稳定：输出是某个完全确定的布尔函数
- 组合逻辑是 datapath 中最重要的部分，如：
  - ALU
  - 寄存器选择器
  - 地址计算器
  - MUX
  - 比较器

*Bit Equality（位相等检测）*
- 对两个 bit，判断是否相等：
- HCL 形式：
  ```v
  bool eq = (a && b) || (!a && !b)
  ```
- 所有判断逻辑最终都分解为基本布尔运算。

*Hardware Control Language (HCL)*
- HCL 是 CS:APP 用来描述 datapath 与 control logic 的简单语言。
- 为什么使用 HCL？
  - 比 Verilog 更简洁
  - 更适合描述处理器控制逻辑（特别是 SEQ / PIPE）
  - 更容易教学和推导
  - 语法类似 C 的布尔表达式
- HCL 的强大之处：
  - 它不描述电路布局，只描述布尔逻辑函数
  - 真正的处理器实现可由工具自动从 HCL 映射到 Verilog

*Multiplexor（多路选择器）*
- MUX 是最重要的组合逻辑组件之一
- *Bit-level MUX*
  - 功能：当 s=1 输出 a，当 s=0 输出 b
  - HCL 形式：
    ```c
    bool out = (s && a) || (!s && b)
    ```
- *Word-level MUX*
  - 功能：选择两个字（word）中的一个输出
  - Select input word A or B depending on control signal s
  - HCL 形式：
    ```c
        int Out = [
        s : A;
        1 : B;
    ];
    ```
  意义：
  - 如果 s==1 → Out = A
  - 否则 → Out = B
  - 4 路 MUX 输出示例：
    ```c
    int Out4 = [
      !s1 && !s0 : D0;
      !s1        : D1;
      !s0        : D2;
      1          : D3;
    ];
    ```
    依次匹配条件，类似 switch-case 的语义
*Word Equality（64-bit 相等比较）*
- 把 64 个 bit-equal 组合为一个大电路：
  ```
  Eq = eq63 && eq62 && ... && eq0
  ```
  HCL 简写：
  ```
  bool Eq = (A == B)
  ```

==== Arithmetic Logic Unit (ALU)

*Arithmetic Logic Unit (ALU)*
- ALU 是处理器 datapath 的核心
- Y86-64 需要支持 4 个操作：
  - addq：X + Y
  - subq：X - Y
  - andq：X & Y
  - xorq：X ^ Y
- ALU 的输入：
  - X（来自寄存器 rA）
  - Y（来自寄存器 rB 或立即数）
  - 控制信号 ALUFUN（选择加减/逻辑运算）
- 输出：
  - ALUresult（64 位）
  - 条件码：ZF、SF、OF
*组合逻辑*
- 逻辑门是数字电路的基本计算单元
- 组合电路是由大量逻辑门组成的无环网络
- 组合电路不存储信息
- 组合电路输出 = 输入的确定性函数
- 组合电路对输入变化做出近乎立即的响应

=== 时序电路

时序逻辑与前面的组合逻辑（combinational logic）不同，它加入了时间的概念，电路可以存储状态。

在处理器中，所有“存储状态”的组件都属于时序逻辑，比如：
- 程序计数器（PC）
- 条件码寄存器（CC）
- 程序状态寄存器（Stat）
- 寄存器文件（register file）
- 内存（DMEM）
- 以及所有流水线寄存器
组合逻辑只能做输入 → 输出的映射，没有记忆。但处理器需要：
- 记住当前执行到哪里（PC）
- 记住临时数据（寄存器）
- 保存程序信息（内存）
所以我们需要能记住所选信号的电路：也就是 latch（锁存器）和 flip-flop（触发器）。

==== 双稳态存储元件（Bistable Element）

(Storing 1 Bit)电路特征：
- 有两个稳定点（0 和 1）
- 有一个不稳定点（metastable）
- 输入电压一旦离开临界点就会“倒向”0 或 1
这就是存储 1 bit 的最基本物理结构。

==== R–S Latch（基本锁存器）

(Storing and Accessing 1 Bit) R = Reset（让输出 = 0），S = Set（让输出 = 1）
#three-line-table[
  | R | S | 输出 Q       |
  | - | - | ---------- |
  | 1 | 0 | 0          |
  | 0 | 1 | 1          |
  | 0 | 0 | 保持原来的值（存储） |
]
当 R = S = 0 时，电路进入存储模式，能保持原值不变。

==== D-Latch（数据锁存器）

(Transparent 1-Bit Latch) 为了解决 R-S Latch 无法同时 R=S=1 的不合法状态，引入了 D（Data）锁存器。

D-Latch：
- 输入端：D
- 时钟端：C
- 当 C = 1 时，允许信号通过（透明）
- 当 C = 0 时，锁存当前值
因此 D-Latch = “透明锁存器”

缺点：当时钟为高电平时，只要 D 改变，输出 Q 会跟着变。

==== 边沿触发（Edge-Triggered）触发器

为避免透明时期产生的毛刺（glitch），采用 edge-triggered flip-flop（边沿触发触发器）。

特点：
- 仅在时钟 上升沿（rising edge）锁存数据
- 其他时间都不变（保持输出）
这是现代 CPU 中寄存器的基础

==== 寄存器（Register）

寄存器（Register）是存储一个“字(word)”的数据的硬件单元

一个寄存器由多个边沿触发器（edge-triggered latch / flip-flop） 组成，每个触发器存储 1 bit：
```
i7 ─► [DFF] ─► o7
i6 ─► [DFF] ─► o6
...
i0 ─► [DFF] ─► o0
```
- D：数据输入
- Q+：输出
- Clock：时钟输入
寄存器行为：
- #three-line-table[
    | 时刻        | 寄存器输出        | 存储值  |
    | --------- | ------------ | ---- |
    | *大部分时间* | 输出 = 上一周期存的值 | 不变   |
    | *时钟上升沿* | 输出变成输入       | 立即更新 |
  ]
这构成了处理器执行阶段与阶段之间的屏障（barrier）

*寄存器作为逻辑之间的“屏障”*
- 寄存器把电路切成了一个一个的“周期”：
  ```
  [ 组合逻辑 ] → [ 寄存器 ] → [ 组合逻辑 ] → [ 寄存器 ] → …
  ```
- 作用：
  - 阻断组合逻辑的传播
    - 没有寄存器，信号会一路传播，无法定义“步骤”。
  - 决定电路的运行节奏（周期）
  - 让电路有“状态”
- → 这才让 CPU 能在多个周期中执行指令。

*状态机实例：累加器（Accumulator）*
```
In →(MUX)→(ALU 加法)→ Register → Out
```
控制信号 Load：
- Load = 1 → 下周期寄存器加载 IN（相当于 reset）
- Load = 0 → 下周期寄存器加载 (Out + In)
运行示例：
- #three-line-table[
    | Cycle | Load | In | Out (下一周期的值) |
    | ----- | ---- | -- | ------------ |
    | 0     | 1    | x0 | x0           |
    | 1     | 0    | x1 | x0 + x1      |
    | 2     | 0    | x2 | x0 + x1 + x2 |
    | 3     | 1    | x3 | x3           |
    | 4     | 0    | x4 | x3 + x4      |
    | 5     | 0    | x5 | x3 + x4 + x5 |
  ]
- 这是典型的有限状态机 FSM，状态存储在寄存器中。
- CPU 本质上也是一个巨大的有限状态机。

==== 随机访问存储器（RAM）

RAM（包括寄存器文件 Register File）也是时序结构。

*Register File 架构*
```
Read port A → srcA → valA
Read port B → srcB → valB
Write port W ← dstW, valW
```
寄存器文件支持：
- 两个读端口
- 一个写端口
- 写在时钟上升沿更新
- 读操作“像组合逻辑”即时生效
作用
- 对特定地址的寄存器进行读写
- 一次可以读写多个字
特别注意
- 若 srcA = 0x4，读取的是 %rsp
- 若 srcA = 0xF（ID=15），表示“不读”（输出忽略）

*寄存器文件时序极其重要*
- 读（READ）
  - 当 srcA/B 改变 → valA/valB 立即改变（本质上是一个巨大的多路复用器 MUX）
- 写（WRITE）
  - 只有时钟上升沿寄存器才更新
  - 若 dstW=F → 不写
- 这才能保证 CPU 执行顺序正确。

==== HCL（Hardware Control Language）

- HCL 用来描述组合逻辑，不会描述时序电路（寄存器内部结构）。
- 我们用 HCL 来描述 CPU 控制逻辑，如 SEQ 或 PIPE 阶段。

- Data Types
  - bool: Boolean
    - `a, b, c, `…
  - int: words
    - `A, B, C, ` …
    - Does not specify word size---bytes, 64-bit words, …
- Statements
  - `bool a = bool-expression;`
  - `int A = int-expression;`
- Boolean 表达式
  - Logic operations: `&&`, `||`, `!`
  - Word comparisons: `==`, `!=`, `<`, `<=`, `>`, `>=`
  - Set membership: `A in {val1, val2, ...}`
- Word 表达式
  - Case expressions (MUX)
    ```
    int Out = [
      condition1 : value1;
      condition2 : value2;
      ...
      1          : valueN;  # default
    ];
    ```

==== 总结

*组合逻辑 + 寄存器 = 时序逻辑系统（CPU的本质）*
- 时序系统基本结构：
  ```
               +---------------------------+
               |     Combinational Logic   |
  State ----->| (ALU, control, muxes etc.) |-----> Next State
               +------------+--------------+
                            |
                            |
                         Register
                       (Clock Rising)
  ```
- Computation
  - Performed by combinational logic
  - Computes Boolean functions
  - Continuously reacts to input changes
- Storage
  - Registers
    - Hold single words
    - Loaded as clock rises
  - Random-access memories
    - Hold multiple words
    - Possible multiple read or write ports
    - Read word when address input changes
    - Write word as clock rises
- 电路分类
  - 组合电路：例如ALU、输入选择器等
  - 时序电路：随机访问存储器（包括寄存器文件、内存）、时序电路（程序计数器（PC）、条件码和程序状态）
- 寄存器
  - 在说到硬件和机器级编程时，“寄存器”有不同含义
  - 寄存器文件不是组合电路（因为有内部存储）
    - 但读数据类似组合电路
    - 写数据由时钟信号控制
- 寄存器作为电路中不同部分的组合逻辑之间的屏障
  - 不断深入理解“屏障”的意义

=== CPU 设计 —— 从指令到硬件

CPU 的所有复杂指令最终都可以归纳成少数几个硬件模块的组合：
#three-line-table[
  | 指令类别                  | 最终硬件动作                |
  | --------------------- | --------------------- |
  | mov / load / store    | 计算地址 + 读/写寄存器 + 读/写内存 |
  | add / sub / and / xor | ALU 计算                |
  | jmp / jxx             | 根据条件码决定下一条 PC         |
  | push / pop            | 特殊的内存操作 + 栈指针更新       |
  | call / ret            | 操作 PC + 栈             |
  | halt / nop            | 不做事情（但仍然走硬件管线）        |
]
硬件内部没有“指令”概念，它只有执行动作（信号 + 电路）；因此 CPU 要做的关键事是把每条指令翻译成硬件行为。

*Y86-64 指令集*
```
halt   0 0
nop    1 0
rrmovq / cmovXX  2 fn rA rB
irmovq 3 0 F rB V
rmmovq 4 0 rA rB D
mrmovq 5 0 rA rB D
OPq    6 fn rA rB
jXX    7 fn Dest
call   8 0 Dest
ret    9 0
pushq  A 0 rA F
popq   B 0 rA F
```
每条指令的第一个字节：icode:ifun，CPU 只要读取第一个字节，就知道整条指令的长度、格式、需要哪些硬件行为。

==== SEQ 硬件结构

```
             Writeback
               ↑
PC → Fetch → Decode → Execute → Memory → Writeback → (更新 PC)
```
SEQ = 顺序执行一次完成一条指令。不是流水线！
- 硬件结构按顺序执行 5 个阶段：
  - Fetch：从指令内存中读指令
  - Decode：读寄存器
  - Execute：ALU 计算
  - Memory：读/写数据内存
  - Writeback：写寄存器
  - PC Update：计算下一条指令的 PC
- 状态 State
  - Program counter register (PC) 程序计数器
  - Condition codes (ZF, SF, OF) 条件码
  - Register file 寄存器文件
  - Memory 数据内存
    - Access same memory space 访问相同内存空间
    - Data: for reading/writing program data 数据
    - Instructions: for fetching instructions 取指令
- 指令流 Instruction Flow
  - Read instruction at address specified by PC 取指令
  - Processe through stages 处理各阶段
  - Update PC to point to next instruction 更新 PC

*Fetch —— 取指令*
- 从指令内存中读出：
  - icode, ifun
  - rA, rB (如果有)
  - valC（立即数或位移）
  - valP（下一条指令地址 = PC + 指令长度）
  #three-line-table[
    | 输出名   | 含义        |
    | ----- | --------- |
    | icode | 指令类型      |
    | ifun  | 指令功能码     |
    | rA    | 源寄存器编码    |
    | rB    | 目标寄存器编码   |
    | valC  | 常数或地址     |
    | valP  | 本条指令末端的地址 |
  ]
- Fetch 阶段本质是：解析指令编码。
*Decode —— 寄存器读（通过寄存器文件）*
- 寄存器文件有：
  ```
  srcA, srcB → 读端口
  dstE, dstM → 写端口
  ```
- Decode 输出：
  #three-line-table[
    | 输出   | 含义         |
    | ---- | ---------- |
    | valA | srcA 的寄存器值 |
    | valB | srcB 的值    |
  ]
*Execute —— ALU 运算 + 条件码更新*
- ALU 有两个输入：
  ```
  aluA
  aluB
  ```
  由指令类型决定。
  - 例如：
    - addq → aluA = valA, aluB = valB
    - rmmovq → aluA = valC(位移), aluB = valB(base)
    - pushq → aluA = -8, aluB = %rsp
- Execute 输出：
  #three-line-table[
    | 输出   | 含义                    |
    | ---- | --------------------- |
    | valE | ALU 结果                |
    | Cnd  | 条件成立？（用于条件跳转或 cmovXX） |
  ]
*Memory —— 访问数据内存*
- Memory 单元做：
  - rmmovq → 写内存[mem(valE)] = valA
  - mrmovq → valM = 内存读[valE]
  - pushq → 写内存[rsp - 8]
  - popq → 读内存[rsp]
- 输出：
  #three-line-table[
    | 输出  | 含义        |
    | --- | --------- |
    | valM | 读出的内存值   |
  ]
*Writeback —— 写寄存器*
- Writeback 根据：
  ```
  dstE → 写 valE
  dstM → 写 valM
  ```
  例如：
  ```asm
  addq rA,rB → dstE = rB
  mrmovq D(rB), rA → dstM = rA
  ```
*PC Update —— 下一条指令地址*
- PC 的更新逻辑依赖指令：
  #three-line-table[
    | 指令   | 下一 PC 的来源           |
    | ---- | ------------------- |
    | 普通指令 | valP                |
    | 条件跳转 | (Cnd ? Dest : valP) |
    | call | Dest                |
    | ret  | valM（从栈中得到返回地址）     |
  ]
  这就是 CPU 如何控制指令流。

*将指令执行组织成阶段*
- 处理器无限循环，执行这些阶段。
- 执行一条指令是需要进行很多处理的。
  - 我们不仅必须执行指令所表明的操作，还必须计算地址、更新栈指针，以及确定下一条指令的地址。
  - 幸好每条指令的整个流程都比较相似。
- 降低复杂度——复用
  - 让不同的指令共享尽量多的硬件。
  - 在硬件上复制逻辑块的成本比软件中有重复代码的成本大得多。
- 我们面临的一个挑战是将每条不同指令所需要的计算放入
到上述那个通用框架中。

*小结*
- Fetch（取指令）：
  - 根据 PC（程序计数器），到指令存储器里把“下一条指令的字节”读出来。
- Decode（译码）：
  - 从这些字节中解析出：
    - 这是哪条指令（icode）
    - 具体功能/条件（ifun）
    - 可能会用到哪几个寄存器（rA, rB）
    - 有没有常数字面量（valC）
- Execute（执行）：
  - 用 ALU 做计算：
    - 算加减乘除/与或非/XOR
    - 算地址（例如 base + offset）
    - 更新条件码（ZF/SF/OF）
    - 判断条件跳转是否成立（生成 Cnd）
- Memory（访存）：
  - 和数据内存打交道：
    - `M8[valE] = valA`（写内存）
    - `valM = M8[valE]` 或 `valM = M8[valA]`（读内存）
- WriteBack（写回）：
  - 把计算结果写回寄存器文件：
    - `R[dstE] = valE`
    - `R[dstM] = valM`
- PC Update（更新 PC）：
  - 决定下一条指令的地址：
    - 一般就是下一条顺序执行的 valP
    - 对于跳转/调用/返回，用目标地址、栈里弹出的返回地址等替换 PC
```
           +---------------------+
 PC  --->  |   取指令 Fetch      | ---> icode, ifun, rA, rB, valC, valP
           +---------------------+
                            |
                            v
           +---------------------+
           |   译码 Decode       | ---> valA, valB, srcA, srcB, dstE, dstM
           +---------------------+
                            |
                            v
           +---------------------+
           |   执行 Execute      | ---> valE, Cnd, 新的 CC
           +---------------------+
                            |
                            v
           +---------------------+
           |   访存 Memory       | ---> valM
           +---------------------+
                            |
                            v
           +---------------------+
           |   写回 WriteBack    | ---> R[dstE], R[dstM]
           +---------------------+
                            |
                            v
           +---------------------+
           |   PC Update         | ---> newPC
           +---------------------+
                            |
                            v
                           PC（下一轮）
```
- 所有指令，都是沿着这一条“大管子”往前走；
- 不同指令只是在某些阶段“用多一点 / 少一点 / 不用”；
- 硬件模块尽量复用：同一套 ALU、同一块数据存储器，所有指令共用。

=== 指令格式与解码（Instruction Decoding）

*86-64 指令的字节格式*
- 第 1 字节：`icode:ifun`
  - 高 4 bit：`icode`（指令种类，例如 OPq、rmmovq、call 等）
  - 低 4 bit：`ifun`（功能码，比如加/减/与/异或，或跳转条件）
- 可选的第 2 字节：`rA:rB`
  - 高 4 bit：`rA`（寄存器 A ID）
  - 低 4 bit：`rB`（寄存器 B ID）
  - 如果某个位置不用寄存器，就用 0xF 代表“No register”。
- 可选的常数字（`valC`，8 字节）
  - 可能是立即数、偏移量、跳转目标地址等
  - 小端存储，连续 8 个字节
*解码阶段做的事*
- 在 Fetch 阶段：从指令内存读原始字节：
  - `icode:ifun ← M1[PC]`
  - 如果该指令需要寄存器字节：`rA:rB ← M1[PC+1]`
  - 如果该指令需要常数字：`valC ← M8[PC+2]`（或 `PC+1`，依指令不同）
  - `valP` = 指向下一条指令的地址（`PC` 加上本条指令长度）
- 在 Decode 阶段：根据 `icode` 决定：
  - 这条指令要从哪些寄存器读操作数（`srcA`, `srcB`）
  - 计算结果要写回到哪个寄存器（`dstE`, `dstM`）
  - 同时从寄存器堆读出：
    - `valA ← R[srcA]`
    - `valB ← R[srcB]`
*每个阶段要“算/产生”哪些中间值*
- Fetch 阶段输出：
  #three-line-table[
    | 输出名   | 含义        |
    | ----- | --------- |
    | icode | 指令类型      |
    | ifun  | 指令功能码     |
    | rA    | 源寄存器编码    |
    | rB    | 目标寄存器编码   |
    | valC  | 常数或地址（立即数/偏移/目标地址）    |
    | valP  | 本条指令末端的c地址、顺序执行时的下一条指令地址 |
  ]
- Decode 阶段输出：
  - 根据 `icode`，决定
    #three-line-table[
      | 信号名  | 含义               |
      | ---- | ---------------- |
      | srcA | 需要从哪个寄存器读操作数 A    |
      | srcB | 需要从哪个寄存器读操作数 B    |
      | dstE | ALU 结果应该写入哪个寄存器    |
      | dstM | 从内存读出的值应该写入哪个寄存器    |
    ]
  - 然后读寄存器文件，得到：
  #three-line-table[
    | 输出   | 含义         |
    | ---- | ---------- |
    | valA | srcA 的寄存器值 |
    | valB | srcB 的值    |
  ]
- Execute 阶段输出：
  #three-line-table[
    | 输出   | 含义                    |
    | ---- | --------------------- |
    | valE | ALU 结果                |
    | Cnd  | 条件成立？（用于条件跳转或 cmovXX） |
  ]
- Memory 阶段输出：
  #three-line-table[
    | 输出  | 含义        |
    | --- | --------- |
    | valM | 读出的内存值   |
  ]
  - 如果指令是 store 类（rmmovq、pushq、call 等）：
    - `M8[地址] ← 数据` 地址通常由 valE 或 valA 给出
  - 如果指令是 load 类（mrmovq、popq、ret 等）：
    - `valM ← M8[地址]`
- WriteBack 阶段
  - 如果有 ALU 结果要写回
    - `R[dstE] ← valE`
  - 如果有内存读值要写回
    - `R[dstM] ← valM`
- PC Update 阶段
  - 根据 icode 判断下一条指令 PC：
    - 普通指令：PC ← valP
    - 条件跳转：PC ← Cnd ? valC : valP
    - call：PC ← valC（目标地址）
    - ret：PC ← valM（从栈里读出的返回地址）

*算术/逻辑指令 OPq rA, rB*
```asm
OPq rA, rB     # 6 fn rA rB
```
例子：addq %rax, %rsi 编码：60 06。直观含义：
- 取出寄存器 rA 中的值，加到寄存器 rB 中的值上，结果写回 rB；
- 同时更新条件码（ZF、SF、OF）。
- Fetch：
  ```
  icode:ifun ← M1[PC]      # 读操作码和功能码（哪种 OP）
  rA:rB   ← M1[PC+1]       # 读寄存器编码
  valP    ← PC + 2         # OPq 指令长度固定 2 字节
  ```
- Decode：
  - 需要从两个寄存器读操作数：
    ```
    srcA ← rA
    srcB ← rB
    valA ← R[rA]
    valB ← R[rB]
    ```
  - 结果写回`rB`：
    ```
    dstE ← rB
    dstM ← RNONE
    ```
- Execute：
  - 由 ifun 决定具体算什么：
    - `ifun=0`：加法
    - `ifun=1`：减法
    - `ifun=2`：and
    - `ifun=3`：xor
  ```
  valE ← valB OP valA   # 注意是 valB OP valA（符合 x86 语义）
  Set CC                # 更新 ZF/SF/OF
  ```
- Memory
  - OPq 不访问内存数据段：
    ```
    [valM 未使用]
    ```
- WriteBack
  ```
  R[dstE] ← valE    # R[rB] ← valE
  ```
- PC Update
  ```
  PC ← valP         # 顺序执行下一条
  ```
- 所有算术/逻辑操作都可以看成 “从两个寄存器读 → ALU 做运算 → 写回一个寄存器”，这一套完全符合“6 阶段统一模板”。
- 注意结果写回`rB`，所以`rB`同时是源操作数和目的寄存器。

*rmmovq rA, D(rB) —— 寄存器到内存*
```asm
rmmovq rA, D(rB)    # 4 0 rA rB  D(8 字节)
```
- 含义：
  - 有点像 x86 的 movq %rA, D(%rB)：
    - 地址`= R[rB] + D`
    - 把`R[rA]`的值写到内存[address]
- Fetch：
  ```
  icode:ifun ← M1[PC]
  rA:rB     ← M1[PC+1]
  valC      ← M8[PC+2]   # D
  valP      ← PC + 10    # 1 + 1 + 8
  ```
- Decode：
  ```
  srcA ← rA          # 要写出去的值
  srcB ← rB          # 基址寄存器
  valA ← R[rA]
  valB ← R[rB]
  dstE ← RNONE       # 没有寄存器写回
  dstM ← RNONE
  ```
- Execute：
  - 用 ALU 计算有效地址：
  ```
  valE ← valB + valC   # R[rB] + D
  ```
- Memory：
  - 往内存写数据：
  ```
  M8[valE] ← valA      # 写 8 字节
  ```
- WriteBack：
  - 不写回任何寄存器
- PC Update：
  ```
  PC ← valP
  ```
- 这里可以看到 “ALU 不只是算加减，还负责地址计算”。
- 设计上就是让所有“地址 = 基址 + 偏移”这种事情都走 Execute 阶段，复用一套 ALU。
*popq rA —— 从栈顶弹出*
```
popq rA    # B 0 rA F
```
- 含义：
  - 从当前`%rsp`指向的内存地址读取 8 字节 → 写入寄存器`rA`
  - `%rsp += 8`（栈向高地址“弹”回去）
- Fetch：
  ```
  icode:ifun ← M1[PC]
  rA:rB     ← M1[PC+1]
  valP      ← PC + 2
  ```
- Decode：
  - 栈指针`%rsp`需要读两次（一个做地址，一个做基数参与加法）：
  ```
  srcA ← RSP
  srcB ← RSP
  valA ← R[%rsp]
  valB ← R[%rsp]

  dstE ← RSP     # 更新后的栈指针要写回
  dstM ← rA      # 从内存读出的数据要写到 rA
  ```
- Execute：
  - 更新栈指针：
  ```
  valE ← valB + 8   # 新的 %rsp
  ```
- Memory：
  - 从旧的栈顶地址读出值：
  ```
  valM ← M8[valA]   # 这里 valA 是旧的 %rsp
  ```
- WriteBack：
  ```
  R[%rsp] ← valE    # 更新栈顶
  R[rA]   ← valM    # 弹出值写入目标寄存器
  ```
- PC Update：
  ```
  PC ← valP
  ```
- 这里复用了 ALU 来做 “%rsp + 8” 的加法；
- 注意要同时更新两个寄存器：一个是 %rsp，一个是目标寄存器 rA。
- 所以 dstE = RSP, dstM = rA，WriteBack 阶段一次搞定。
*条件传送 cmovXX rA, rB*
```asm
cmovXX rA, rB   # 2 fn rA rB
```
含义：
- 如果条件成立：rB = rA
- 如果条件不成立：什么都不做（看起来），但在硬件里会“取消写回”。
- Fetch：
  ```
  icode:ifun ← M1[PC]
  rA:rB     ← M1[PC+1]
  valP      ← PC + 2
  ```
- Decode：
  ```
  srcA ← rA
  srcB ← RNONE
  valA ← R[rA]
  valB ← 0          # 或 RNONE，不参与
  dstE ← rB         # 目标寄存器
  dstM ← RNONE
  ```
- Execute：
  - 让 ALU 直接“透传” valA：
  ```
  valE ← valB + valA   # 这里 valB 可以是 0，相当于 valE = valA
  Cnd  ← Cond(CC, ifun)
  ```
  - 如果条件不成立，通过把 dstE 改成 RNONE 来“取消写回”：
  ```
  if !Cnd then dstE ← RNONE
  ```
- Memory：
  - 不访问数据内存。
- WriteBack：
  ```
  if dstE != RNONE:
    R[dstE] ← valE
  ```
- PC Update：
  ```
  PC ← valP
  ```
- 真正的“条件性”体现在 “要不要写回结果”。
- 这样就不需要在 ALU 或寄存器文件里加复杂逻辑，只靠一个 dstE 是否为 RNONE 来控制。
*条件跳转 jXX Dest*
```asm
jXX Dest   # 7 fn Dest(8 字节)
```
- Fetch：
  ```
  icode:ifun ← M1[PC]
  valC      ← M8[PC+1]   # 目标地址
  valP      ← PC + 9
  ```
- Decode：
  - 不用寄存器：
  ```
  srcA = srcB = dstE = dstM = RNONE
  ```
- Execute：
  - 根据条件码决定是否跳转：
  ```
  Cnd ← Cond(CC, ifun)
  ```
- Memory：
  - 不访问数据内存。
- WriteBack：
  - 无寄存器写回。
- PC Update：
  ```
  PC ← Cnd ? valC : valP
  ```
- 这里 同时计算两种可能的下一 PC：顺序的 (valP) 和跳转目标 (valC)，最后在 PC Update 阶段选一个。
- 这样的好处：逻辑统一，便于后来做流水线时猜测跳转。
*call Dest —— 调用子程序*
```asm
call Dest   # 8 0 Dest(8 字节)
```
- 含义：
  - `PC+9` 压栈（返回地址）
  - `%rsp -= 8`（栈向低地址生长）
  - `PC ← Dest`
- Fetch：
  ```
  icode:ifun ← M1[PC]
  valC      ← M8[PC+1]   # 目标地址
  valP      ← PC + 9     # 返回地址
  ```
- Decode：
  ```
  srcA = RNONE
  srcB = RSP
  valB ← R[%rsp]
  dstE = RSP
  dstM = RNONE
  ```
- Execute：
  - 计算新的栈顶：
  ```
  valE ← valB + (-8)   # %rsp - 8
  ```
- Memory：
  - 把返回地址写到新栈顶：
  ```
  M8[valE] ← valP
  ```
- WriteBack：
  ```
  R[%rsp] ← valE
  ```
- PC Update：
  ```
  PC ← valC
  ```
- 这里又是 ALU = 栈指针运算器。
- 把“返回地址”这种信息放到栈上，是为了支持嵌套调用和递归。
*ret —— 从子程序返回*
```asm
ret   # 9 0
```
- 含义：
  - 从 %rsp 指向的地址读出返回地址
  - %rsp += 8
  - PC ← 返回地址
- Fetch：
  ```
  icode:ifun ← M1[PC]
  valP      ← PC + 1
  ```
- Decode：
  ```
  srcA = RSP
  srcB = RSP
  valA ← R[%rsp]   # 当做读内存地址
  valB ← R[%rsp]   # 参与 +8 计算
  dstE = RSP
  dstM = RNONE     # 这里不写寄存器，只写 PC
  ```
- Execute：
  ```
  valE ← valB + 8   # 新的 %rsp
  ```
- Memory：
  ```
  valM ← M8[valA]   # 读返回地址
  ```
- WriteBack：
  ```
  R[%rsp] ← valE
  ```
- PC Update：
  ```
  PC ← valM
  ```
- 与 call 完全对称：call 是“把返回地址压栈 + PC ← Dest”；
- ret 是“从栈上取返回地址 + PC ← 取出的地址”。

