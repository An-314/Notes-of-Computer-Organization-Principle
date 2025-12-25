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
- *Memory（DMEM）*
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
  | `cmovl`  | 2    | \<   | 是     |
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
每条指令的第一个字节：`icode:ifun`，CPU 只要读取第一个字节，就知道整条指令的长度、格式、需要哪些硬件行为。

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
- 我们面临的一个挑战是将每条不同指令所需要的计算放入到上述那个通用框架中。

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
    | valP  | 本条指令末端的地址、顺序执行时的下一条指令地址 |
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

== Sequential Implementation

前面我们了解了 CPU 的时序结构，以及 SEQ 处理器的各个阶段和指令解码细节。

#figure(
  three-line-table[
    | Roadmap  | CSAPP                                              |
    | -------- | -------------------------------------------------- |
    | 基础电路     | 组合逻辑 + 时序逻辑                                        |
    | 指令集      | Y86-64 ISA                                         |
    | 划分阶段     | Fetch / Decode / Execute / Memory / Writeback / PC |
    | *顺序执行* | *SEQ 处理器（现在）*                                    |
    | HCL 语言   | 用来写“控制逻辑”                                          |
    | 流水线      | 下一章                                                |
  ],
  numbering: none,
)

*SEQ Hardware Structure*

- *Sequential 的核心思想*
  - 顺序处理器 = 一条指令，在一个时钟周期内，完整走完所有阶段

#grid(columns: (1fr,) * 2)[
  #newpara()
  *State*
  - Program counter register (PC)
  - Condition code register (CC)
  - Register File
  - Memories
    - Access same memory space
    - Data: for reading/writing program data
    - Instruction: for reading instructions
  *Instruction Flow*
  - Read instruction at address
  *specified by PC*
  - Process through stages
  - Update program counter
][
  #figure(
    image("pic/seq-imp.pdf", width: 100%),
    numbering: none,
  )
]


*硬件控制语言 Hardware Control Language*

- HCL 用来描述组合逻辑，不会描述时序电路（寄存器内部结构）
- HCL
  - Data Types
    - bool: Boolean
      - `a, b, c, …`
    - int: words
      - `A, B, C, …`
      - Does not specify word size---bytes, 32-bit words, …
  - Statements
    - `bool a = bool-expression;`
    - `int A = int-expression;`
- HCL Operations
  - Boolean Expressions
    - Logic Operations
      - `&&`, `||`, `!`
    - Word Comparisons
      - `==`, `!=`, `<`, `<=`, `>`, `>=`
    - Set Membership
      - `A in {val1, val2, …}`
  - Word Expressions = MUX
    - Case expressions
      - `[condition1 : value1; condition2 : value2; … ];`
      - Evaluate test expressions `a, b, c, …` in sequence
      - Return word expression `A, B, C, …` for first successful test
- *SEQ Hardware*
  - 我们用 HCL 来描述 CPU 控制逻辑，如 SEQ 或 PIPE 阶段
  - 蓝色模块：
    - 已经存在的硬件
    - ALU、寄存器文件、内存、PC
  - 灰色模块：
    - 控制逻辑
      - ALU 做加法还是减法？
      - 读哪个寄存器？
      - 写哪个寄存器？
      - PC 该怎么更新？
    - 这些不是“数据计算”，而是“选择 / 决策”
    - 将这些决策用 HCL 写出来
#figure(
  three-line-table[
    | 元素   | 含义           |
    | ---- | ------------ |
    | 蓝色框  | 已有硬件模块       |
    | 灰色框  | 控制逻辑（HCL 定义） |
    | 白色椭圆 | 信号名          |
    | 粗线   | 64-bit 数据    |
    | 细线   | 小位宽信号        |
    | 虚线   | 1-bit 控制信号   |
  ],
  numbering: none,
)
#figure(
  image("pic/2025-12-23-14-04-37.png", width: 80%),
  numbering: none,
)

#note(subname: [回顾])[
  - Fetch 阶段（取指）
    - 输入：`PC`
    - 输出：`icode, ifun, rA, rB, valC, valP`
    - 硬件：Instruction Memory, PC Incrementer
    - HCL 控制的点：
      - 指令长度 → valP 怎么算？
  - Decode 阶段（读寄存器）
    - 输入：`rA / rB, icode`
    - 输出：`srcA / srcB, dstE / dstM, valA / valB`
    - 硬件：Register File
    - HCL 决定：
      - 读哪个寄存器？
      - 写哪个寄存器？
  - Execute 阶段（算）
    - 输入：`valA, valB, valC`
    - 输出：`valE, Cnd, CC（条件码）`
    - 硬件：ALU, CC 寄存器
    - HCL 决定：
      - ALU 做什么？
      - A、B 端口接什么？
  - Memory 阶段（访存）
    - 输入：`valE, valA / valP`
    - 输出：`valM`
    - 硬件：Data Memory
    - HCL 决定：
      - 读还是写？
      - 地址是什么？
      - 写入数据是什么？
  - Writeback 阶段
    - 输入：`valE, valM`
    - 输出：写回寄存器
    - HCL 决定：
      - 写哪个寄存器？
      - 写 valE 还是 valM？
  - PC Update（灵魂）
    - 输入：`valP, valC, valM, Cnd`
    - 输出：`newPC`
    - HCL 决定：
      - 顺序执行？
      - 跳转？
      - call / ret？
]

=== Fetch Logic

Fetch 是第一步，它解决 3 个根本问题：
- 从哪里读指令？ → PC
- 指令是什么？ → icode / ifun / rA / rB / valC
- 下一条指令地址是多少？ → valP

#figure(
  image("pic/seq-fetch.pdf", width: 80%),
  numbering: none,
)
数据流：
```
PC
 ↓
Instruction Memory (最多读 10 字节)
 ↓
Split（拆出 icode / ifun）
 ↓
Align（对齐 rA rB valC）
 ↓
生成：
  icode, ifun, rA, rB, valC, valP
```
#newpara()
*Predefined Blocks*
- PC（程序计数器）
  - 类型：寄存器（时序逻辑）
  - 作用：保存“当前要取的指令地址”
    ```
    PC → Instruction memory
    ```
  - 在 Fetch 阶段：
    - PC 只读
    - 新 PC 要到 PC Update 阶段才写回
- Instruction Memory（指令存储器）
  - 功能：从 PC 开始连续读 10 个字节
    ```
    M1[PC], M1[PC+1], ..., M1[PC+9]
    ```
  - 为什么是 10 字节？Y86-64 指令最长是：
    #three-line-table[
      | 组成                  | 字节数    |
      | ------------------- | ------ |
      | opcode (icode:ifun) | 1      |
      | regids (rA:rB)      | 1      |
      | valC                | 8      |
    ]
  - `imem_error` 信号
    - 若 PC 或 PC+9 超出内存范围：
    - `imem_error = 1`
    - 后果：指令无效、后续用 NOP 替代
- Split：拆 instruction byte
  - 输入
    ```
    Byte 0 = instruction byte
    ```
  - 输出
    ```
    icode = 高 4 位
    ifun  = 低 4 位
    ```
  - Split 是纯组合逻辑
- Align：对齐 rA / rB / valC
  - 为什么需要 Align？
    - 有些指令 没有 reg byte
    - 有些指令 没有 valC
    - valC 必须是 8 字节对齐的整数
  - Align 的工作是：在固定的 10 字节窗口中，把字段“对齐取出来”
    #three-line-table[
      | 信号   | 含义              |
      | ---- | --------------- |
      | rA   | 源寄存器 A          |
      | rB   | 源 / 目的寄存器 B     |
      | valC | 立即数 / 位移 / 目标地址 |
    ]
- PC increment（PC 增量逻辑）
  - 输入：PC, Need regids, Need valC
  - 输出：valP（fall-through PC）
  - 计算规则
    ```
    valP = PC + 1
      + (Need regids ? 1 : 0)
      + (Need valC ? 8 : 0)
    ```
    - 举例：
      #three-line-table[
        | 指令     | Need regids | Need valC | valP  |
        | ------ | ----------- | --------- | ----- |
        | OPq    | ✓           | ✗         | PC+2  |
        | irmovq | ✓           | ✓         | PC+10 |
        | ret    | ✗           | ✗         | PC+1  |
      ]
  - valP 是“如果不跳转，下一条指令地址”
*Control Logic*
- `Instr_valid`：指令是否合法？
  - 它检查：
    - icode 是否在合法集合中
    - 指令格式是否匹配
  ```hcl
  bool instr_valid = icode in {
      IHALT, INOP, IRRMOVQ, IIRMOVQ,
      IRMMOVQ, IMRMOVQ, IOPQ,
      IJXX, ICALL, IRET,
      IPUSHQ, IPOPQ
  };
  ```
  非法 → 程序状态 = INS
- Need regids：是否需要寄存器字节？
  - 决定是否读取 rA:rB
  ```hcl
  bool need_regids =
    icode in { IRRMOVQ, IOPQ, IPUSHQ, IPOPQ,
               IIRMOVQ, IRMMOVQ, IMRMOVQ };

  ```
- Need valC：是否需要立即数？
  - 决定是否读取 valC
  ```hcl
  bool need_valC =
    icode in { IIRMOVQ, IRMMOVQ, IMRMOVQ,
               IJXX, ICALL };
  ```
*异常保护逻辑*
- icode 的生成
  ```hcl
  int icode = [
      imem_error: INOP;
      1: imem_icode;
  ];
  ```
  - 如果取指越界：不执行真实指令、强制当成 nop
  - 否则：使用内存读出的真实 icode
  - 这是一个 硬件级“异常降级”设计
- ifun 的生成
  ```hcl
  int ifun = [
      imem_error: FNONE;
      1: imem_ifun;
  ];
  ```
  - 若地址错误：function code = FNONE
  - 防止后续逻辑误用垃圾值
#exercise[
  For PC value $p$, need_regids value $r$, and need_valC value $i$ , what is the value of the signal valP?
  - $p+r+8i+1$
]

=== Decode Logic

Decode 阶段的任务是：
- 根据 icode，决定要读哪些寄存器（srcA, srcB）
- 根据 icode，决定要写哪些寄存器（dstE, dstM）
- 从寄存器文件读出操作数（valA, valB）

#figure(
  image("pic/seq-decode.pdf", width: 80%),
  numbering: none,
)
数据流：
```
rA, rB, icode
 ↓
Decode Logic
 ↓
生成：
  srcA, srcB, dstE, dstM
  ↓
Register File
  ↓
生成：
  valA, valB
```

*Register File 的真实接口*
- 寄存器文件端口：
  - Read ports A, B
  - Write ports E, M
  - 地址 = 寄存器 ID（0–14）或 0xF（RNONE）
    - 如果地址是 RNONE = 0xF，硬件“什么都不做”
- 所以 Decode 的核心任务就是：
  - 给这四个信号赋值：
    - `srcA`：读端口 A 的寄存器 ID
    - `srcB`：读端口 B 的寄存器 ID
    - `dstE`：写端口 E 的寄存器 ID
    - `dstM`：写端口 M 的寄存器 ID
*Signals*
- Cnd: Indicate whether or not to perform conditional move
  - Cnd 是 Execute 阶段生成的
  - Cnd 控制条件传送和条件跳转
*Control Logic*
- srcA 的生成
  ```hcl
  int srcA = [
    icode in { IRRMOVQ, IRMMOVQ, IOPQ, IPUSHQ } : rA;
    icode in { IPOPQ, IRET } : RRSP;
    1 : RNONE;
  ];
  ```
  Decode阶段所有指令的 srcA 选择逻辑
  #three-line-table[
    | 指令         | 选择 | 解释 |
    | :--- | ---- | ---- |
    | OPq rA rB  | `valA ← R[rA]` | 算术/逻辑操作数 A 来自 rA |
    | cmovXX rA rB | `valA ← R[rA]` | 条件传送的值来自 rA |
    | rmmovq rA,D(rB) | `valA ← R[rA]` | 要写到内存的数据来自 rA |
    | pushq rA   | `valA ← R[rA]` | 要压栈的数据来自 rA |
    | popq rA    | `valA ← R[%rsp]` | 弹出数据来自栈顶（%rsp） |
    | ret        | `valA ← R[%rsp]` | 返回地址来自栈顶（%rsp） |
    | 其他指令      | RNONE | 不读寄存器 |
  ]
- srcB 的生成
  ```hcl
  int srcB = [
    icode in { IOPQ, IRMMOVQ, IMRMOVQ } : rB;
    icode in { IPUSHQ, IPOPQ, ICALL, IRET } : RRSP;
    1 : RNONE;
  ];
  ```
  Decode阶段所有指令的 srcB 选择逻辑
  #three-line-table[
    | 指令           | 选择 | 解释 |
    | :--- | ---- | ---- |
    | OPq rA rB    | `valB ← R[rB]` | 算术/逻辑操作数 B 来自 rB |
    | rmmovq rA,D(rB) | `valB ← R[rB]` | 基址寄存器来自 rB |
    | mrmovq D(rB),rA | `valB ← R[rB]` | 基址寄存器来自 rB |
    | pushq rA     | `valB ← R[%rsp]` | 更新栈顶需要用到 %rsp |
    | popq rA      | `valB ← R[%rsp]` | 更新栈顶需要用到 %rsp |
    | call Dest    | `valB ← R[%rsp]` | 更新栈顶需要用到 %rsp |
    | ret          | `valB ← R[%rsp]` | 更新栈顶需要用到 %rsp |
    | 其他指令        | RNONE | 不读寄存器 |
  ]
- dstE 的生成
  ```hcl
  int dstE = [
    icode in { IRRMOVQ } && Cnd : rB;
    icode in { IIRMOVQ, IOPQ} : rB;
    icode in { IPUSHQ, IPOPQ, ICALL, IRET } : RRSP;
    1 : RNONE; # Don't write any register
  ];
  ```
  Decode阶段所有指令的 dstE 选择逻辑
  #three-line-table[
    | 指令           | 选择 | 解释 |
    | :--- | ---- | ---- |
    | cmovXX rA rB  | `R[rB] ← valE` if Cnd | 条件传送，条件成立时写回 rB |
    | irmovq V,rB   | `R[rB] ← valE` | 立即数写入 rB |
    | OPq rA rB    | `R[rB] ← valE` | 算术/逻辑结果写回 rB |
    | pushq rA     | `R[%rsp] ← valE` | 更新栈顶指针 |
    | popq rA      | `R[%rsp] ← valE` | 更新栈顶指针 |
    | call Dest    | `R[%rsp] ← valE` | 更新栈顶指针 |
    | ret          | `R[%rsp] ← valE` | 更新栈顶指针 |
    | 其他指令        | RNONE | 不写寄存器 |
  ]
- dstM 的生成
  ```hcl
  int dstM = [
    icode in { IMRMOVQ } : rA;
    icode in { IPOPQ } : rA;
    1 : RNONE; # Don't write any register
  ];
  ```
  Decode阶段所有指令的 dstM 选择逻辑
  #three-line-table[
    | 指令         | 选择 | 解释 |
    | :--- | ---- | ---- |
    | mrmovq D(rB),rA | `R[rA] ← valM` | 从内存读值写回 rA |
    | popq rA      | `R[rA] ← valM` | 弹出值写回 rA |
    | 其他指令      | RNONE | 不写寄存器 |
  ]

=== Execute Logic

Execute 阶段的任务是：
- 根据 icode / ifun，决定 ALU 做什么运算
- 根据 icode，决定 ALU A、B 端口接什么值
- 算术、地址、栈指针变化，以及条件是否成立
  - 算一个结果 valE（通过 ALU）
  - 决定是否更新条件码 CC
  - 根据 CC + ifun 计算条件 Cnd
  - 为后续 Memory / Write-back / PC Update 提供输入

#figure(
  image("pic/seq-execute.pdf", width: 80%),
  numbering: none,
)

数据流：
```
valA, valB, valC, icode, ifun
 ↓
Execute Logic
 ↓
生成：
  ALU A, ALU B, ALU operation
  ↓
ALU
  ↓
生成：
  valE, Cnd
```
#newpara()
*Execute 阶段的 3 个硬件单元（Units）*
- LU（算术逻辑单元）
  - ALU 是组合逻辑
  - 它要支持 Y86-64 需要的 4 个运算：
    #three-line-table[
      | alufun | 操作 |
      | ------ | -- |
      | ALUADD | 加  |
      | ALUSUB | 减  |
      | ALUAND | 与  |
      | ALUXOR | 异或 |
    ]
    对应 OPq 指令的 ifun
  - 同时 ALU 还会产生：
    - ZF（Zero）
    - SF（Sign）
    - OF（Overflow）
*CC（Condition Codes，条件码寄存器）*
- 这是一个寄存器（有状态），保存 3 个 bit：
  #three-line-table[
    | 位  | 含义      |
    | -- | ------- |
    | ZF | 结果是否为 0 |
    | SF | 结果是否为负  |
    | OF | 是否溢出    |
  ]
  只有部分指令会更新 CC（例如 `OPq`）
- *cond（条件判断单元）*
  - `cond` 是纯组合逻辑，它的作用是：根据 `(ifun, CC)` → 计算 `Cnd`
    #three-line-table[
      | 指令     | ifun  | 条件               |
      | ------ | ----- | ---------------- |
      | cmovle | FN_LE | (SF ⊕ OF) ∨ ZF   |
      | jg     | FN_G  | ¬(SF ⊕ OF) ∧ ¬ZF |
    ]
  cond 的输出 Cnd 会被：
  - cmovXX 用来决定是否写寄存器
  - jXX 用来决定是否跳转
*Execute 阶段的控制逻辑（Control Logic）*
- 同一个 ALU，要为不同指令服务所以我们要用 HCL 决定：
  - ALU 的输入 A 是什么？
  - ALU 的输入 B 是什么？
  - ALU 做什么运算？
  - 要不要写 CC？
- ALU A 的选择
  ```hcl
  int aluA = [
    icode in { IRRMOVQ, IOPQ } : valA;
    icode in { IIRMOVQ, IRMMOVQ, IMRMOVQ } : valC;
    icode in { ICALL, IPUSHQ }: -8;
    icode in { IRET, IPOPQ } : 8;
    # Other instructions don't need ALU
  ];
  ```
  - 解释：
    #three-line-table[
      | 指令           | aluA 选择 | 解释 |
      | :--- | ---- | ---- |
      | OPq rA rB    | valA | `valE ← valB OP valA` |
      | cmovXX rA rB | valA | `valE ← 0 + valA` |
      | rmmovq rA,D(rB) | valC | 计算地址：`valE ← valB + valC` |
      | mrmovq D(rB),rA | valC | 计算地址：`valE ← valB + valC` |
      | irmovq V,rB   | valC | 立即数：`valE ← 0 + valC` |
      | call Dest    | -8   | 栈指针变化：`valE ← valB - 8` |
      | ret          | 8    | 栈指针变化：`valE ← valB + 8` |
      | pushq rA     | -8   | 栈指针变化：`valE ← valB - 8` |
      | popq rA      | 8    | 栈指针变化：`valE ← valB + 8` |
      | 其他指令        | 未使用   |  \    |
    ]
- ALU B 的来源
  ```hcl
  int aluB = [
    icode in { IRMMOVQ, IMRMOVQ, IOPQ, ICALL, IPUSHQ, IRET, IPOPQ } : valB;
    icode in { IRRMOVQ, IIRMOVQ } : 0;
  ];
  ```
  - 涉及寄存器或栈指针 → 用 valB
  - 只是搬运 / 立即数 → 用 0
- ALU 运算类型（alufun）
  ```hcl
  int alufun = [
    icode == IOPQ : ifun;
    1 : ALUADD;
  ];
  ```
  - OPq 指令
    - ifun 指定：addq / subq / andq / xorq
    - 所以直接交给 ALU
  - 其他所有指令
    - 统一用加法
    - 地址计算、栈指针更新，本质都是加法
- Set CC：什么时候更新条件码
  ```hcl
  bool set_cc = icode == IOPQ;
  ```

=== Memory Logic

Memory 阶段的任务是：
- 如果这条指令需要访问数据内存，就在这里访问；否则什么都不做。
- 根据 icode，决定是否访问数据内存

#figure(
  image("pic/seq-memory.pdf", width: 80%),
  numbering: none,
)

数据流：
```
valE, valA, valP, icode
 ↓
Memory Logic
 ↓
生成：
  mem_addr, mem_data, mem_read, mem_write
  ↓
Data Memory
  ↓
生成：
  valM
```
#newpara()
*Data memory 模块*
- 输入
  - Addr：访问地址
  - data in：要写入的数据
  - read / write：控制信号
- 输出
  - data out → valM
- 在 HCL 里我们抽象成：
  ```
  valM ← M8[mem_addr]
  M8[mem_addr] ← mem_data
  ```
*Memory 阶段的控制逻辑（Control Logic）*
- stat：指令状态（是否终止）
  ```hcl
  int Stat = [
    imem_error || dmem_error : SADR;
    !instr_valid             : SINS;
    icode == IHALT            : SHLT;
    1                         : SAOK;
  ];
  ```
  #three-line-table[
    | 条件               | 含义      |
    | ---------------- | ------- |
    | `imem_error`     | 取指越界    |
    | `dmem_error`     | 数据访存越界  |
    | `!instr_valid`   | 非法指令    |
    | `icode == IHALT` | halt 指令 |
    | 默认               | 正常执行    |
  ]
  一旦不是`SAOK`，CPU 停止。
- mem_read：这条指令要不要读内存？
  ```hcl
  bool mem_read = icode in { IMRMOVQ, IPOPQ, IRET };
  ```
  #three-line-table[
    | 指令       | 为什么要读内存  |
    | -------- | -------- |
    | `mrmovq` | 从内存读到寄存器 |
    | `popq`   | 从栈顶读值    |
    | `ret`    | 从栈顶读返回地址 |
  ]
  读出来的结果统一叫`valM`
- mem_write：这条指令要不要写内存？
  ```hcl
  bool mem_write = icode in { IRMMOVQ, IPUSHQ, ICALL };
  ```
  #three-line-table[
    | 指令        | 为什么要写内存     |
    | --------- | ------------ |
    | `rmmovq`  | 把寄存器值写到内存   |
    | `pushq`   | 把寄存器值压栈     |
    | `call`    | 把返回地址压栈     |
  ]
- mem_addr：访问哪个地址？
  ```hcl
  int mem_addr = [
    icode in { IRMMOVQ, IPUSHQ, ICALL, IMRMOVQ } : valE;
    icode in { IPOPQ, IRET }                    : valA;
  ];
  ```
  #three-line-table[
    | 指令           | 地址来源 | 解释 |
    | :--- | ---- | ---- |
    | rmmovq rA,D(rB) | valE | 计算出的内存地址 |
    | mrmovq D(rB),rA | valE | 计算出的内存地址 |
    | pushq rA     | valE | 新栈顶地址 |
    | popq rA      | valA | 旧栈顶地址 |
    | call Dest    | valE | 新栈顶地址 |
    | ret          | valA | 旧栈顶地址 |
  ]
- mem_data：写入什么数据？
  ```hcl
  int mem_data = [
    icode in { IRMMOVQ, IPUSHQ } : valA;
    icode == ICALL              : valP;
  ];
  ```
  #three-line-table[
    | 指令           | 数据来源 | 解释 |
    | :--- | ---- | ---- |
    | rmmovq rA,D(rB) | valA | 要写入内存的数据 |
    | pushq rA     | valA | 要压栈的数据 |
    | call Dest    | valP | 返回地址 |
  ]

=== PC Update Logic

PC Update 阶段的任务是：
- 计算下一条指令的地址，更新 PC
- 根据 icode 和条件码 Cnd，决定下一 PC
- 不同指令类型，PC 更新规则不同
- 主要分三类：
  - 顺序执行指令：PC = valP
  - 条件跳转指令：PC = Cnd ? valC : valP
  - call / ret 指令：PC = valC / valM

#figure(
  image("pic/seq-pc.pdf", width: 80%),
  numbering: none,
)

数据流：
```
valP, valC, valM, icode, Cnd
 ↓
PC Update Logic
  ↓
生成：
  new PC
```
#newpara()

*PC Update 阶段的控制逻辑（Control Logic）*
```hcl
int new_pc = [
  icode == ICALL : valC;
  icode == IJXX && Cnd : valC;
  icode == IRET : valM;
  1 : valP;
];
```
- call Dest
  ```hcl
  icode == ICALL : valC;
  ```
  - valC = 指令里直接编码的目标地址
  - call 本质：无条件跳转
- jXX Dest 且条件成立
  ```hcl
  icode == IJXX && Cnd : valC;
  ```
  - Cnd 来自 Execute 阶段
  - 已经判断了条件码（ZF/SF/OF）
    - 成功跳转：PC = Dest
    - 否则：落到默认 valP
- ret
  ```hcl
  icode == IRET : valM;
  ```
  - valM = 从内存读出的返回地址
  - ret 的语义就是：“PC ← pop 出来的值”
- 默认情况
  ```hcl
  1 : valP;
  ```
  - 顺序执行：PC 指向下一条指令
    #three-line-table[
      | 指令     | 下一条     |
      | ------ | ------- |
      | OPq    | PC + 2  |
      | rmmovq | PC + 10 |
      | popq   | PC + 2  |
      | …      | …       |
    ]
- 为什么 PC Update 一定放在最后？
  - PC 的更新依赖于前面所有阶段的计算结果
    #three-line-table[
      | PC 更新来源 | 来自哪个阶段  |
      | ------- | ------- |
      | valC    | Fetch   |
      | valP    | Fetch   |
      | valM    | Memory  |
      | Cnd     | Execute |
    ]

=== SEQ Operation

#figure(
  image("pic/seq-operation.pdf", width: 80%),
  numbering: none,
)

*时钟—状态—组合逻辑*
- 状态（State）只在时钟上升沿更新
  - State 包括：
    - PC
    - 寄存器文件（Register file）
    - 条件码 CC
    - 数据内存（Data memory）
  - 只有在 clock ↑ 的那一瞬间，状态才会改变
  - 其他时间，状态是“冻结的”
- 组合逻辑（Combinational logic）一直在“算”
  - 组合逻辑包括：
    - ALU
    - 控制逻辑（HCL 写的那些）
    - 所有“读端口”（寄存器读、内存读、指令存储器）
  - 只要 state 一变，组合逻辑立刻重新计算
  - 不等时钟，不存结果，只“反应”
- 一个 Cycle =上一条指令的 state 生效 + 下一条指令的组合计算

#figure(
  image("pic/seq-example.pdf", width: 80%),
  numbering: none,
)

+ 时钟上升沿刚刚过去
  - 根据第二个irmovq指令设置的状态集
  - 组合逻辑开始响应状态变化
+ 下一个上升沿前
  - 根据第二个irmovq指令设置的状态集
  - 组合逻辑生成结果用于addq指令
+ 下一个上升沿到来
  - 根据addq指令设置的状态集
  - 组合逻辑开始响应状态变化
+ 再下一个上升沿前
  - 根据addq指令设置的状态集
  - 组合逻辑生成结果用于下一条指令

=== 小结

*SEQ（Sequential）*
- SEQ 用一个时钟，让一条指令在一个周期内完整走完 Fetch → Decode → Execute → Memory → Write back → PC update。
- 通过将执行每条不同指令所需的步骤组织成一个统一的流程，就可以用很少量的各种硬件单元以及一个时钟来控制计算的顺序，从而实现整个处理器。

*SEQ 的核心设计思想（非常重要）*
- 把“指令执行”拆解成统一流程
  - 所有指令，本质上都可以表达为同一套阶段，只是每个阶段“有没有事做、算什么”不同。
- 复用硬件，而不是为每条指令造一套电路
  - 在硬件中，复制逻辑的成本比软件高得多
  - 降低复杂度
- 时钟是分界线
  - 组合逻辑一直在“算可能发生什么”，但只有在时钟上升沿，状态才真正改变。

*设计思想总结（这几句话值得背下来）*
- 复用程度不断加深
- 以空间换时间（但 SEQ 还没做到）
  - SEQ 做的是：以空间省 → 时间浪费
  - 而后面的章节（Pipeline）会反过来：增加空间（寄存器、通路），换取时间（更快时钟 & 并行）

*SEQ 最大的问题：慢（而且是结构性地慢）*
- 在 一个时钟周期内，信号必须走完：
  ```
  PC
  → Instruction memory
  → Register file
  → ALU
  → Data memory
  → Register file
  → PC
  ```
  - 时钟必须非常慢
  - ALU、内存、寄存器大部分时间在“等”
  - 硬件利用率极低

#exercise[
  以下关于指令执行的描述中哪个是不正确的？
  - 指令是最小的执行单元
  - 指令执行是原子操作
  - 指令是顺序执行的
  - 不同的指令是由不同功能的电路执行的
]

#solution[
  - 「指令是最小的执行单元」 ❌
    - 在 SEQ 实现里：
      - 真正被硬件执行的是：Fetch / Decode / Execute / Memory / Write-back
      - 一条指令被拆成多个阶段
      - 每个阶段内部还有：ALU 运算、寄存器读写、内存访问
    - 最小执行单元是：硬件微操作（micro-ops / 信号级计算）
  - 指令执行是原子操作」 ❌
    - 时钟上升沿才提交状态
    - 指令的“效果”来自：
      - 多个组合逻辑计算
      - 多个寄存器/内存更新
    - 指令执行 在时间上是分裂的
    - 只是 ISA 语义把它“包装成原子”
  - 「指令是顺序执行的」 ❌
    - 状态更新是顺序的，但组合逻辑是同时工作的
    - 状态序列是顺序的，计算是重叠的、并行的
  - 「不同的指令是由不同功能的电路执行的」 ❌
    - 这是 SEQ 设计思想的反命题。
    - 同一个 ALU 既算 addq、又算地址 valB + valC、又算 %rsp ± 8
    - 同一个 寄存器文件 所有指令共享
    - 同一个 数据内存 load / store / call / ret 全用它
    - 区别只在于：控制逻辑（HCL）如何配置数据通路
]

== Pipeline

*把指令执行拆成阶段*
- 不同指令看起来不同，但本质流程高度相似
- 降低硬件复杂度
  - 让不同的指令共享尽量多的硬件
  - 在硬件上复制逻辑块的成本比软件中有重复代码的成本大得多
- 怎么做？——阶段化（Stage Decomposition）
  - 把一条指令拆成 6 个阶段
  - 取指（IF）：
    - 从内存读指令
    - 计算 valP = PC + instr_len
  - 译码（ID）：
    - 读寄存器
    - 符号扩展立即数
  - 执行（EX）：
    - ALU 运算（算结果 / 地址 / SP）
  - 访存（MEM）：
    - 读 / 写数据内存
  - 写回（WB）：
    - 把结果写回寄存器
  - 更新 PC（PC）：
    - 选择下一条 PC（顺序 / 分支 / ret）

*流水线的总览结构*
- General Principles of Pipelining
  - Goal（目标）：提高吞吐量（单位时间完成更多指令）
  - Difficulties（困难）：数据冒险、控制冒险、结构冒险
- Creating a Pipelined Y86-64 Processor
  - Rearranging SEQ
    - 把原来“一坨组合逻辑”的 SEQ 拆成 5~6 段
  - Inserting pipeline registers
    - 在每两个阶段之间插寄存器（F/D/E/M/W）
  - Problems with hazards
    - 前后指令“互相影响”，这是流水线的代价
- 流水线不是让一条指令更快完成，而是让更多指令“同时在路上”。
  - 流水线提高的是吞吐量（Throughput）
  - 不是单条指令的延迟（Latency）

=== Pipelining Principles

*Computational Example*
- 系统参数
  - 组合逻辑总延迟：300 ps
  - 寄存器写入开销：20 ps
  - 最小时钟周期 = 300 + 20 = 320 ps
- 吞吐量
  - Throughput = 1 / Cycle time = 1 / 320 ps = 3.12  GIPS
- 总延迟
  - Delay = 320 ps

#figure(
  image("pic/pipeline-example.pdf", page: 1, width: 80%),
  numbering: none,
)

*3 级流水线：理想均匀划分*
- 划分方式
  - 组合逻辑拆成 A / B / C
  - 每段：100 ps
  - 每段后接一个寄存器：20 ps
- 单级时钟周期
  - Cycle time = 100 + 20 = 120 ps
- 吞吐量
  - Throughput = 1 / 120 ps = 8.33 GIPS
- 总延迟
  - Delay = 3 × (100 + 20) = 360 ps

#figure(
  image("pic/pipeline-example.pdf", page: 2, width: 80%),
  numbering: none,
)

- *吞吐量 vs 延迟*
  - 吞吐量
    - 每 120 ps 就可以启动一个新操作
    - 稳态下：Throughput = 8.33 GIPS
  - 延迟
    - 一条操作要经过 A → B → C → 写回
    - 总延迟：Delay = 360 ps
    - 延迟反而变大了！

*时间图：同时处理 3 个操作*

#figure(
  image("pic/pipeline-example.pdf", page: 3, width: 80%),
  numbering: none,
)

- 未流水（Unpipelined）
  - OP1 完成 → OP2 才能开始
  - 任何时刻只有 1 个操作在系统里
- 3-way 流水线
  - OP1 在 B
  - OP2 在 A
  - OP3 可能已经进来
  - 最多 3 个操作“同时在路上”

#figure(
  image("pic/pipeline-example.pdf", page: 4, width: 80%),
  numbering: none,
)

*局限*
- *非均匀划分*
  - 新划分
    - A：50 ps
    - B：150 ps
    - C：100 ps
    - 每级寄存器：20 ps
  - 时钟周期
    - Cycle time = 150 + 20 = 170 ps
    - 流水线速度被最慢阶段 B 拖死
  - 吞吐量
    - Throughput = 1 / 170 ps = 5.88 GIPS
  - 总延迟
    - Delay = 50 + 150 + 100 + 3 × 20 = 360 ps

  #figure(
    image("pic/pipeline-example.pdf", page: 5, width: 80%),
    numbering: none,
  )
- *继续加深流水线：寄存器开销开始反噬*
  - 极端情况：把逻辑切得非常细
    - 每段逻辑：50 ps
    - 每级寄存器：20 ps
  - 后果
    - 寄存器时间占比急剧上升：
      #three-line-table[
        | 流水级数 | 寄存器开销占比 |
        | ---- | ------- |
        | 1 级  | 6.25%   |
        | 3 级  | 16.67%  |
        | 6 级  | 28.57%  |
      ]
  - 寄存器成了瓶颈，而不是逻辑
  #figure(
    image("pic/pipeline-example.pdf", page: 6, width: 80%),
    numbering: none,
  )

*Data Dependency*
- Data Dependencies（数据相关）：这是“程序本身”的属性
- 每个操作依赖前一个操作的结果
  - Data dependency ≠ 流水线的问题
  - 它在 顺序执行（SEQ） 中就已经存在

#figure(
  image("pic/pipeline-example.pdf", page: 7, width: 80%),
  numbering: none,
)
- OP2 需要 OP1 的输出
- OP3 需要 OP2 的输出
- 在未流水化系统中：
  - OP1 完成 → 结果写回 → OP2 再开始
  - 一切都“来得及”
  - 数据相关本身不会导致错误
*Data Hazard*
- Data Hazards（数据冒险）：这是“流水线引入的问题”
- 结果还没来得及“走回去”，下一条指令就已经开始用了
- 在流水线中：
  - OP1 的结果：
    - 可能在 C 阶段 / WB 阶段 才真正产生
  - OP2：
    - 在 A / B 阶段（ID / EX） 就已经需要这个结果
    - 时间顺序被打乱了：指令仍然“逻辑上顺序”，但“硬件执行上重叠”
  - 于是：正确的程序，在流水线上可能算错
#figure(
  image("pic/pipeline-example.pdf", page: 8, width: 80%),
  numbering: none,
)
- 正常期望（顺序语义）
  ```
  OP1:  produce result
  OP2:            consume result
  ```
- 流水线实际发生的事
  ```
  Cycle N:   OP1 在 B
  Cycle N+1: OP1 在 C, OP2 已经在 A
  ```
  OP2 读取寄存器时，OP1 还没写回
- 这就是：Read After Write (RAW) Hazard
*Data Dependencies in Processors*
```asm
1 irmovq $50, %rax
2 addq %rax , %rbx
3 mrmovq 100( %rbx ), %rdx
```
- 指令间依赖关系
  - 指令 2 读取 %rax
    - 但 %rax 是指令 1 写的
  - 指令 3 读取 %rbx
    - 但 %rbx 是指令 2 写的
  - 两个都是 RAW（Read After Write
- 如果是 SEQ（顺序执行）：永远正确
- 如果是 Pipeline（还没加任何保护）
  - 指令 2 在 ID 阶段 就读 %rax
  - 但指令 1 可能还在 EX / MEM
  - 读到的是旧值

=== 从SEQ到Pipeline

*SEQ Hardware（顺序实现）*
- 所有阶段的组合逻辑连成一条长路径
- 一个时钟周期内，只服务一条指令
- PC → Fetch → Decode → Execute → Memory → Write back → 更新 PC 一次性全部做完

#grid(columns: (1fr,) * 2)[
  #figure(
    image("pic/2025-12-23-14-04-37.png", width: 100%),
    numbering: none,
  )
][
  #figure(
    image("pic/2025-12-24-20-42-42.png", width: 100%),
    numbering: none,
  )
]

*SEQ+ Hardware：为流水线“清路”*
- 关键变化：PC 阶段前移
  - 还是序列执行
  - PC 阶段前移
- 在 SEQ 中：
  - PC 是一个状态寄存器
  - 新 PC 在 一条指令的最后 才算出来
  - 下一条指令必须等上一条“彻底结束”
- 在 SEQ+ 中
  - 把 PC 选择逻辑挪到最前面
  - 当前指令用的 PC，来自：一条指令已经算好的信息
  - 也就是：*当前 PC = 上一条指令的“遗产”*
- PC Stage
  - PC是多路选择器的结果，比如：
    - 顺序执行：valP
    - 分支成功：valC
    - ret：valM
- Processor State 的变化
  - PC 不再是作为状态寄存器存在
  - 它可以由：pipeline register 里保存的信息，控制逻辑，执行结果共同决定
  - 这是为了下一步做铺垫：PC 也要流水化
- *为 Pipeline 做“拓扑清理”*
*Adding Pipeline Registers：真正进入 Pipeline*
- 阶段不再是“逻辑顺序”，而是“物理分段”
- Pipeline Register 的作用（一定要会一句话解释）
  - 把一个时钟周期内的计算结果，冻结下来，交给下一阶段在下一个周期使用
  - F → D → E → M → W
  - 每个箭头中间，都有一个寄存器
*Pipeline Stages（五级流水线的标准定义）*
- *Fetch（取指）*
  - 选择当前 PC
  - 从指令内存读指令
  - 计算 `valP = PC + instr_len`
- *Decode（译码）*
  - 从寄存器文件读 `valA / valB`
  - 决定：
    - `srcA / srcB`
    - `dstE / dstM`
- *Execute（执行）*
  - ALU 运算：
    - 算数
    - 地址
    - 栈指针
  - 设置条件码（CC）
- Memory（访存）
  - 读 / 写数据内存
  - 典型指令：
    - `mrmovq`
    - `rmmovq`
    - `call / ret`
- Write Back（写回）
  - 把 `valE / valM` 写回寄存器文件

#figure(
  image("pic/2025-12-24-20-59-53.png", width: 100%),
  numbering: none,
)

注意：
- PC 选择逻辑必须提前，否则无法流水
- 流水线 = 组合逻辑 + pipeline registers
- 阶段定义是功能划分，不是指令类型划分
- 一切 hazard，都是因为这些阶段“同时在工作”
为什么到了 Pipeline，PC 必须在最前面？
- Pipeline 的本质前提：同一个时钟周期内，有多条指令同时处在不同阶段
- Fetch 阶段“第一件事”是必须立刻知道 PC，才能取指
  - Fetch 在 周期一开始就要工作
  - 它不能等 Execute / Memory 算完
- 如果 PC update 还在“最后”
  - 当前周期：Fetch 阶段需要 PC
  - 但 PC 的计算：要等某条指令走到 Execute / Memory，那是 本周期后半段，甚至下周期
- Pipeline 中 PC 的真实语义已经变了
  - 在 Pipeline 中：*PC 不再是“本条指令算出来的”，而是“对未来指令的预测或修正”*
  - Fetch 用的是：predPC（预测 PC）
  - 之后某个周期：Execute / Memory 才发现预测错了，再回滚/修正 PC

=== PIPE- Hardware

Pipeline registers hold intermediate values from instruction execution
- 在 PIPE 中：每个阶段都有自己的“状态寄存器”
  - 同一时刻：F / D / E / M / W 都是不同指令
  - 所以不是“一条指令的流动”，而是：多条指令的“时间切片叠加”
- Pipeline Registers：它们到底存什么？
  - F / D / E / M / W 每一个都代表一个 pipeline register，里面存的是：“某条指令，在这个阶段结束时，算出来的一切中间结果”
- Forward (Upward) Paths
  - Values passed from one stage to next
  - Cannot jump past stages
  - 流水线里 合法的数据流只有一种：
    ```
    F → D → E → M → W
    ```
  - 例子：为什么 valC 不能“跳级”？
    - valC 是 Fetch 阶段解析出来的立即数
    - Decode，Execute，Memory都可能需要它
    - 所以它必须：
      ```
      F_valC → D_valC → E_valC → M_valC → W_valC
      ```
      即使某个阶段“不用”，也要带着走
- Signal Naming Conventions
  - 两种前缀的含义
    - `S_Field`：存储在 S 阶段 pipeline register 里的值
    - `s_Field`：在 S 阶段组合逻辑中，刚刚算出来的值
  - 为什么信号的要带上阶段的名字作为前缀
    - 在 SEQ 中，不同阶段共享一套信号
    - 在PIPE中，不同阶段执行的是不同的指令（信号名称要带上阶段区分）

#figure(
  image("pic/2025-12-24-22-46-26.png", width: 80%),
  numbering: none,
)

*Feedback Paths*

#figure(
  image("pic/2025-12-24-23-28-23.png", width: 80%),
  numbering: none,
)

- *Predicted PC（预测 PC）*
  - Guess value of next PC
  - Fetch 阶段：必须立刻有 PC，但：分支是否跳转，ret 的返回地址，都要到后面阶段才知道
  - 所以：Fetch 用 预测 PC，后面阶段发现错了 → 纠正 + flush
- *Branch information（分支信息回流）*
  - Jump taken / not-taken
  - Fall-through or target address
  - Execute 阶段：ALU + CC 才知道条件是否成立
  - 但 Fetch 已经跑了好几拍
  - 把 Cnd、valC 等信息回送，用来修正 PC
- *Return point（ret 的返回地址）*
  - Read from memory
  - 这是最麻烦的一种控制冒险：
  - ret 的返回地址：必须从内存读，在 M 阶段才知道
  - 所以：PC 要从 M_valM 回送到 Fetch
- *Register updates（写回 & forwarding）*
  - To register file write ports
  - 这部分红线既用于：正常写回（W 阶段）
  - 也用于：数据转发（forwarding）
  - 例如：E 阶段需要的操作数，可能来自：E_valE、M_valE、M_valM、W_valE、W_valM
  - 这就是为什么 Decode/Execute 周围线最多

*Predicting the PC*

#figure(
  image("pic/2025-12-25-01-45-40.png", width: 80%),
  numbering: none,
)

- 为什么必须“预测 PC”
  - Fetch 阶段结束后，立刻要开始下一次 Fetch
    - 分支是否跳转 → Execute / Memory 才知道
    - ret 的返回地址 → Memory / Write-back 才知道
  - 在当前指令完成后开始获取新指令，时间不足以可靠地确定下一条指令
  - 猜接下来会执行哪条指令，若预测错误则恢复
- Predict PC
  - `PC increment`
    - 计算：`valP = PC + instr_len`
    - 用于：普通顺序指令，分支失败时的回退地址
  - `Predict PC`
    - 这是一个组合逻辑模块，根据 f_icode 决定：用 valP？用 valC？还是“未知”（ret）
    - 它输出：`predPC`
  - `Select PC`
    - 这是 最终裁决者：
    - 它要在以下来源中选一个：
      - `predPC`（正常预测）
      - `M_valA`（分支预测失败纠错）
      - `W_valM`（ret 返回地址）
- *预测策略*
  - 不改变控制流的指令
    - `OPq / irmovq / rmmovq / mrmovq`
    - 预测：`PC = valP`
    - 永远正确
  - Call & 无条件跳转
    - `call / jmp`
    - 预测：`PC = valC`
    - 永远正确
  - 条件跳转（JXX）
    - 策略：总是预测跳转
    - 预测：`PC = valC`
    - 正确率：约 60%
      - 错了怎么办？之后纠错
      - 注意：这是 CSAPP 为了教学故意选的“简单但不完美”策略
  - Return（RET）
    - 不预测
    - 原因：返回地址在栈里，要等内存读完才知道
    - 直接暂停 Fetch（stall）
- *什么时候、怎么纠错？*
  - 分支预测失败（最常见）
    - 什么时候发现？
      - 当 JXX 指令走到 Memory 阶段
      - 已经有：M_Cnd（条件是否成立）
      - 如果：`M_icode == IJXX && !M_Cnd`
      - 说明：预测跳转 ❌ 实际不跳 ✔
    - 正确 PC 是什么？
      - `fall-through PC = valP`
      - 而这个 valP：在流水线中，被一路带到了 M_valA
      - 所以纠错用：`PC = M_valA`
  - Return 指令（最麻烦）
    - 返回地址在哪里？
      - 从栈里读
      - 直到 W 阶段才稳定
      - 所以：`PC = W_valM`
    - 在此之前：
      - Fetch 停止
      - 不乱猜
- *把策略翻译成“优先级规则”*
  - PC 选择优先级（从高到低）：
    - ret 返回地址 → `W_valM`
    - 分支预测失败纠错 → `M_valA`
    - call / jxx 的预测目标 → `f_valC`
    - 默认顺序执行 → `f_valP`
  - 纠错 > 预测 > 默认
- `f_pc`
  ```hcl
  int f_pc = [
      # 1. ret：最高优先级
      W_icode == IRET : W_valM;
      # 2. 分支预测失败纠错
      M_icode == IJXX && !M_Cnd : M_valA;
      # 3. call / jxx：预测跳转
      f_icode in {ICALL, IJXX} : f_valC;
      # 4. 默认：顺序执行
      1 : f_valP;
  ];
  ```

*NOP and Data Dependencies*
- 最简单的情况：完全无相关（demo-basic.ys）
  ```asm
  irmovq $1,%rax
  irmovq $2,%rcx
  irmovq $3,%rdx
  irmovq $4,%rbx
  halt
  ```
  - 每条指令都 互不依赖，没有分支，没有 ret，没有 load/use
  - 结果：流水线 完美填满
  - 结论 0（基线）：只要没有 hazard，PIPE ≈ 理想 1 IPC
  #figure(
    image("pic/pipeline-PIPE-.pdf", page: 1, width: 80%),
    numbering: none,
  )
- 数据相关：为什么需要 3 个 NOP（demo-h3.ys）
  ```asm
  irmovq $10,%rdx
  irmovq $3,%rax
  nop
  nop
  nop
  addq %rdx,%rax
  ```
  - 关键依赖，`addq` 需要：
    - `%rdx` ← 第 1 条
    - `%rax` ← 第 2 条
  - 但在这个 PIPE 里：
    - 寄存器只在 W 阶段才写回
    - Decode 阶段读寄存器
  - 结论 1：在“没有 forwarding、没有 stall”的流水线中，*必须手工插 nop*，等到写回完成
  #figure(
    image("pic/pipeline-PIPE-.pdf", page: 2, width: 80%),
    numbering: none,
  )
- 为什么 2 个 NOP 不够（demo-h2.ys）
  ```asm
  irmovq $10,%rdx
  irmovq $3,%rax
  nop
  nop
  addq %rdx,%rax
  ```
  - 关键错误
    - addq 在 D 阶段：
      - %rdx（已经写回）
      - %rax（还没写回）
  - 图里的 Error 就是：`valB ← R[%rax] = 0`
  - 结论 2：差一个 cycle 都不行，RAW hazard 是严格的“时序问题”，不是逻辑问题
  #figure(
    image("pic/pipeline-PIPE-.pdf", page: 3, width: 80%),
    numbering: none,
  )
- 1 个 NOP：两个操作数都错（demo-h1.ys）
  ```asm
  irmovq $10,%rdx
  irmovq $3,%rax
  nop
  addq %rdx,%rax
  ```
  - 两个操作数都读错
    - %rdx ← 还没写回
    - %rax ← 还没写回
  #figure(
    image("pic/pipeline-PIPE-.pdf", page: 4, width: 80%),
    numbering: none,
  )
- 0 个 NOP：四个操作数都错（demo-h0.ys）
  ```asm
  irmovq $10,%rdx
  irmovq $3,%rax
  addq %rdx,%rax
  ```
  - 四个操作数都读错
    - %rdx ← 还没写回
    - %rax ← 还没写回
  #figure(
    image("pic/pipeline-PIPE-.pdf", page: 5, width: 80%),
    numbering: none,
  )
- *分支预测失败*：为什么会“多执行 3 条指令”（demo-j.ys）
  ```asm
  0x000: xorq %rax,%rax
  0x002: jne t # Not taken
  0x00b: irmovq $1, %rax # Fall through
  0x015: nop
  0x016: nop
  0x017: nop
  0x018: halt
  0x019: t: irmovq $3, %rdx # Target (Should not execute)
  0x023: irmovq $4, %rcx # Should not execute
  0x02d: irmovq $5, %rdx # Should not execute
  ```
  - 预测策略回顾
    - JXX：总是预测跳转
    - Fetch 直接去 valC（target）
  - 时间线发生了什么？
    - jne 在 Execute / Memory 才知道：`M_Cnd = 0（不跳）`
    - 但这时：Target 的 3 条指令已经进入流水线，分别在 F / D / E
  - 在分支目标处错误执行3条指令
- *Return预测失败*：为什么比分支更糟（demo-ret.ys）
  ```asm
  0x000: irmovq Stack,%rsp # Intialize stack pointer
  0x00a: nop # Avoid hazard on %rsp
  0x00b: nop
  0x00c: nop
  0x00d: call p # Procedure call
  0x016: irmovq $5,%rsi # Return point
  0x020: halt
  0x020: .pos 0x20
  0x020: p: nop # procedure
  0x021: nop
  0x022: nop
  0x023: ret
  0x024: irmovq $1,%rax # Should not be executed
  0x02e: irmovq $2,%rcx # Should not be executed
  0x038: irmovq $3,%rdx # Should not be executed
  0x042: irmovq $4,%rbx # Should not be executed
  0x100: .pos 0x100
  0x100: Stack: # Initial stack pointer
  ```
  - ret 的致命问题
    - 返回地址在：
      - 栈内存
      - 直到 M / W 阶段 才知道
  - 如果“天真地继续取指”
    - 在ret指令之后错误地执行3条指令
    - ret连“预测对/错”的依据都没有
  - 正确做法（CSAPP 方案）：ret不预测，Fetch stall，等 W_valM 出来，再恢复 Fetch

*Pipeline Summary*
- Concept
  - Break instruction execution into 5 stages
    - Fetch / Decode / Execute / Memory / Write Back
  - Run instructions through in pipelined mode
    - 这是在改变“时间组织方式”
    - 流水线不是新功能，是新调度方式
- Limitations：PIPE-的弊端
  - Data dependency（数据冒险）
    - One instruction writes register, later one reads it
    - 根本原因（结构性延迟）：Decode 阶段读寄存器，Write-back 阶段才写寄存器，中间隔了 3 个周期
  - Control dependency（控制冒险）
    - 包括两类：分支预测失败、return
- Fixing the Pipeline
  - PIPE- 是正确的，但是低效的
  - 靠的是：插 nop、人工规避 hazard

#note(subname: [处理器的不同名称])[
  - SEQ：完整的、顺序执行指令的处理器
  - SEQ+：完整的、顺序执行指令的处理器，在SEQ基础上重新安排计算阶段（PC更新阶段在一个时钟周期的开始）
  - PIPE-：完整的、以流水线方式工作的处理器，在SEQ+的基础上增加流水线寄存器以及其它控制逻辑
    - 无法解决数据冲突、控制冲突
    - 或者说，只能以插入大量nop指令的方式来解决数据冲突、控制冲突
  - PIPE：完整的、高效的、以流水线方式工作的处理器，在PIPE-基础上增加数据转发（数据旁路）以及其它控制逻辑
]
