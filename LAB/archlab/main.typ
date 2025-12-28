#import "@preview/scripst:1.1.1": *

#show: scripst.with(
  template: "report",
  title: [计算机组成原理实验报告],
  info: [ArchLAB],
  author: ("Anzreww",),
  time: "2025年12月",
  contents: true,
  content-depth: 3,
  matheq-depth: 3,
  lang: "zh",
)

= 实验要求

本实验（ArchLAB）旨在通过 Y86-64 工具链与处理器模拟器，理解 程序、指令集、以及处理器实现 之间的关系。实验分为三部分：
- Part A：Y86-64 程序编写
  - 编写并运行 3 个 Y86-64 汇编程序（迭代链表求和、递归链表求和、块复制与 XOR 校验）
  - 熟悉 `yas`/`yis` 等工具
- Part B：SEQ 处理器扩展
  - 修改 SEQ 的 HCL 以支持新指令（如 iaddq）
- Part C：流水线与程序优化
  - 修改 PIPE 的 HCL 并优化基准程序，以降低 CPE 并提升性能

= 实验环境

- 操作系统：Linux（Arch 系）
- 编译器：GCC 15.2.1
- 实验目录结构（解压后`sim/`）
  ```
  sim/
  ├── misc      # Part A 使用：yas/yis 等
  ├── seq       # Part B 使用：ssim + HCL
  ├── pipe      # Part C 使用：psim + 测试脚本
  ├── y86-code  # 回归测试程序
  └── ptest     # 更严格的测试脚本
  ```

== 兼容性问题与解决

由于 handout 中部分代码较老，而本机 GCC 版本较新（10+ 默认 `-fno-common`），在编译 `yas/yis` 时出现了：
- 旧式函数原型导致的参数检查错误
- `lineno` 多重定义
为避免直接修改源码文件，选择在顶层 `Makefile` 中统一加入兼容编译选项：
- `-std=gnu11`：使用更兼容的 C 标准
- `-fcommon`：兼容旧式“头文件定义全局变量”的链接行为
最终执行 `make clean; make` 可成功编译 `yas/yis/ssim/psim`。

```make
COMPAT = -std=gnu11 -fcommon

all:
	(cd misc; make all CFLAGS="-Wall -O1 -g $(COMPAT)" LCFLAGS="-O1 $(COMPAT)")
	(cd pipe; make all GUIMODE=$(GUIMODE) TKLIBS="$(TKLIBS)" TKINC="$(TKINC)" CFLAGS="-Wall -O2 $(COMPAT)")
	(cd seq;  make all GUIMODE=$(GUIMODE) TKLIBS="$(TKLIBS)" TKINC="$(TKINC)" CFLAGS="-Wall -O2 $(COMPAT)")
	(cd y86-code; make all CFLAGS="-Wall -O2 $(COMPAT)")
```

= 实验内容

== Part A: Y86-64 程序

*通用测试方法*
- 进入 `sim/` 目录后：
  ```bash
  misc/yas PartA/xxx.ys
  misc/yis PartA/xxx.yo
  ```
- 最后写在 `.log` 文件中，便于查看输出
  ```make
  YAS:=misc/yas
  YIS:=misc/yis
  PARTA:=PartA

  parta: parta-sum parta-rsum parta-copy

  parta-sum: $(YAS) $(YIS)
    $(YAS) $(PARTA)/sum.ys
    $(YIS) $(PARTA)/sum.yo > $(PARTA)/sum.log

  parta-rsum: $(YAS) $(YIS)
    $(YAS) $(PARTA)/rsum.ys
    $(YIS) $(PARTA)/rsum.yo > $(PARTA)/rsum.log

  parta-copy: $(YAS) $(YIS)
    $(YAS) $(PARTA)/copy.ys
    $(YIS) $(PARTA)/copy.yo > $(PARTA)/copy.log

  clean-parta:
    rm -f $(PARTA)/*.yo $(PARTA)/*.log
  ```

=== `sum.ys`: 迭代求链表元素之和

*目标*
- 实现 `sum_list(list_ptr ls)` 的迭代版本，逻辑等价于：
  ```c
  typedef struct ELE {
      long val;
      struct ELE *next;
  } *list_ptr;

  long sum_list(list_ptr ls) {
      long val = 0;
      while (ls) {
          val += ls->val;
          ls = ls->next;
      }
      return val;
  }
  ```
*实现*
- 链表结点结构：`[val][next]`，每项 8 字节
- `ls` 指针放在 `%rdi`，累加器用 `%rax`
- 循环中用 `andq %rdi, %rdi` 设置条件码判断 `ls==0`
- 每轮：
  - 读取 `val = 0(%rdi)`
  - 累加到 `%rax`
  - 读取 `ls = 8(%rdi)` 更新指针
  ```asm
      .pos 0
      irmovq stack, %rsp        # init stack pointer
      irmovq ele1, %rdi         # arg1: ls = &ele1
      call sum_list
      halt                      # result should be in %rax

  # ls in %rdi, return in %rax
  sum_list:
      xorq %rax, %rax           # val = 0 (accumulator in %rax)

  loop:
      andq %rdi, %rdi           # set flags based on ls
      je done                   # if (ls == NULL) break

      mrmovq 0(%rdi), %rcx      # rcx = ls->val
      addq %rcx, %rax           # val += ls->val
      mrmovq 8(%rdi), %rdi      # ls = ls->next
      jmp loop

  done:
      ret
  ```
*测试数据*
- 三元素链表：`0x00a → 0x0b0 → 0xc00 → NULL`
- 预期和：`0x00a + 0x0b0 + 0xc00 = 0xcba`
*验证结论*
- 运行后 `%rax` 应为 `0x...0cba`，符合预期
  ```log
  Stopped in 26 steps at PC = 0x1d.  Status 'HLT', CC Z=1 S=0 O=0
  Changes to registers:
  %rax:	0x0000000000000000	0x0000000000000cba
  %rcx:	0x0000000000000000	0x0000000000000c00
  %rsp:	0x0000000000000000	0x0000000000000300

  Changes to memory:
  0x02f8:	0x0000000000000000	0x000000000000001d
  ```

=== `rsum.ys`: 递归求链表元素之和

*目标*
- 实现 `rsum_list(list_ptr ls)` 的递归版本，逻辑等价于：
  ```c
  long rsum_list(list_ptr ls) {
      if (!ls) return 0;
      long val = ls->val;
      long rest = rsum_list(ls->next);
      return val + rest;
  }
  ```
*实现*
- Base：`ls==0` 返回 0（`xorq %rax,%rax; ret`）
- Recursive
  - 取 `val = *ls`（放 `%rcx`）
  - 更新参数 `ls = ls->next`（写回 `%rdi`）
  - 为跨 `call` 保留 `val`，使用 `pushq %rcx` 保存，递归返回后 `popq %rcx`
  - 返回 `val + rest`：`addq %rcx, %rax`
  ```asm
      .pos 0
      irmovq stack, %rsp        # init stack pointer
      irmovq ele1, %rdi         # arg1: ls = &ele1
      call sum_list
      halt                      # result should be in %rax

  # ls in %rdi, return in %rax
  sum_list:
      xorq %rax, %rax           # val = 0 (accumulator in %rax)

      andq %rdi, %rdi           # set flags based on ls
      je done                   # if (ls == NULL) break

      mrmovq 0(%rdi), %rcx      # rcx = ls->val
      addq %rcx, %rax           # val += ls->val
      mrmovq 8(%rdi), %rdi      # ls = ls->next

      pushq %rax                # save val
      call sum_list             # rest = rsum_list(ls->next)
      popq %rcx                 # restore val
      addq %rcx, %rax           # return val + rest

  done:
      ret
  ```
*测试数据*
- 同上，三元素链表：`0x00a → 0x0b0 → 0xc00 → NULL`
- 预期和：`0x00a + 0x0b0 + 0xc00 = 0xcba`
*验证结论*
- 运行后 `%rax` 应为 `0x...0cba`，符合预期
  ```log
  Stopped in 41 steps at PC = 0x1d.  Status 'HLT', CC Z=0 S=0 O=0
  Changes to registers:
  %rax:	0x0000000000000000	0x0000000000000cba
  %rcx:	0x0000000000000000	0x000000000000000a
  %rsp:	0x0000000000000000	0x0000000000000300

  Changes to memory:
  0x02c8:	0x0000000000000000	0x000000000000004c
  0x02d0:	0x0000000000000000	0x0000000000000c00
  0x02d8:	0x0000000000000000	0x000000000000004c
  0x02e0:	0x0000000000000000	0x00000000000000b0
  0x02e8:	0x0000000000000000	0x000000000000004c
  0x02f0:	0x0000000000000000	0x000000000000000a
  0x02f8:	0x0000000000000000	0x000000000000001d
  ```

=== `copy.ys`: 块复制与 XOR 校验

*目标*
- 实现 `copy_block` 函数，功能为从源地址复制指定字节数到目标地址，并计算复制数据的 XOR 校验和，逻辑等价于：
  ```c
  long copy_block(long *src, long *dest, long len) {
      long result = 0;
      while (len > 0) {
          long val = *src++;
          *dest++ = val;
          result ^= val;
          len--;
      }
      return result;
  }
  ```
*实现*
- 参数与返回值约定
  - `%rdi`：源地址 `src`
  - `%rsi`：目标地址 `dest`
  - `%rdx`：字节数 `len`
  - `%rax`：返回值 `result`
- 循环逻辑
  - 检查 `len` 是否为 0（`andq %rdx, %rdx` + `je done`）
  - 读取源数据 `mrmovq 0(%rdi), %rcx`
  - 写入目标地址 `rmmovq %rcx, 0(%rsi)`
  - 更新指针 `irmovq 8, %r8; addq %r8, %rdi; addq %r8, %rsi`
  - 更新校验和 `xorq %rcx, %rax`
  - 减少长度 `irmovq 8, %r8; subq %r8, %rdx`
- Y86-64 的 `addq/subq` 不支持立即数（如 `addq $8, %rdi` 会报错），因此采用：
  - 先将立即数加载到寄存器（如 `irmovq $8, %r8`），再进行寄存器间的加减
  ```asm
      .pos 0
      irmovq stack, %rsp

      irmovq src,  %rdi         # arg1: src
      irmovq dest, %rsi         # arg2: dest
      irmovq len,  %rdx         # arg3: len
      mrmovq 0(%rdx), %rdx      # rdx = *(&len) = 3

      call copy_block
      halt                      # expect %rax = 0xCBA, and dest updated

  # long copy_block(long *src, long *dest, long len)
  # rdi=src, rsi=dest, rdx=len, return rax=result
  copy_block:
      xorq %rax, %rax           # result = 0

  loop:
      andq %rdx, %rdx           # set flags based on len
      jle done                   # if (len == 0) break

      mrmovq 0(%rdi), %rcx      # rcx = *src
      rmmovq %rcx, 0(%rsi)      # *dest = val
      xorq %rcx, %rax           # result ^= val

      irmovq $8, %r8             # increment pointers and decrement len
      addq %r8, %rdi             # src++
      addq %r8, %rsi             # dest++
      irmovq $1, %r8             # one
      subq %r8, %rdx             # len--
      jmp loop

  done:
      ret
  ```
*测试数据*
- 源块 `src`（三个 `long`）：`0x00a, 0x0b0, 0xc00`
- 目标块 dest 初始：`0x111, 0x222, 0x333`
- 预期：`dest` 最终变为 `0x00a, 0x0b0, 0xc00`，返回值 XOR：`0x00a ^ 0x0b0 ^ 0xc00 = 0xcba`
*验证结论*
- 运行后 `%rax` 应为 `0x...0cba`，`dest` 内容正确
  ```log
  Stopped in 44 steps at PC = 0x3b.  Status 'HLT', CC Z=1 S=0 O=0
  Changes to registers:
  %rax:	0x0000000000000000	0x0000000000000cba
  %rcx:	0x0000000000000000	0x0000000000000c00
  %rsp:	0x0000000000000000	0x0000000000000300
  %rsi:	0x0000000000000000	0x00000000000000b8
  %rdi:	0x0000000000000000	0x00000000000000a0
  %r8:	0x0000000000000000	0x0000000000000001

  Changes to memory:
  0x00a0:	0x0000000000000111	0x000000000000000a
  0x00a8:	0x0000000000000222	0x00000000000000b0
  0x00b0:	0x0000000000000333	0x0000000000000c00
  0x02f8:	0x0000000000000000	0x000000000000003b
  ```

== Part B: SEQ 处理器扩展

修改顺序处理器 SEQ 的控制逻辑描述文件 `seq-full.hcl` ，使处理器支持新指令 `iaddq V, rB`。该指令的语义为：
- 读取寄存器 `rB` 的旧值；
- 取指令中的 8 字节立即数 `V`；
- 执行加法并写回：`rB ← rB + V`；
- 更新条件码CC（ZF/SF/OF）以反映结果。
完成后需要编译生成新的`ssim`，并通过小程序与回归测试验证新增指令正确且不破坏原有指令行为。

=== 指令计算过程

参考教材对 irmovq（需要 valC）与 OPq（ALU 运算/写回/更新 CC）的描述，iaddq 的执行可以理解为二者的组合：
- Fetch：读取 `icode/ifun`、`rA/rB`、`valC`，并计算 `valP`
  - iaddq 需要 `regid` 字节（用于给出 `rB`）
  - iaddq 需要 `valC`（8 字节立即数）
- Decode：读取寄存器文件得到 `valB`（`rB` 的旧值）
- Execute：ALU 执行 `valE = valB + valC`，并更新 `CC`
- Memory：不读写数据存储器
- Write back：将 `valE` 写回 `rB`
- PC update：使用默认 `new_pc = valP`

=== 控制逻辑修改

为使 SEQ 正确支持 `iaddq` ，在 `seq-full.hcl` 中将 `IIADDQ` 纳入以下控制信号的选择逻辑：
- 指令合法性与取指需求
  - `instr_valid`：将 `IIADDQ` 加入合法指令集合，否则会被判为非法指令
  - `need_regids`：`IIADDQ` 需要 `regid` 字节
  - `need_valC`：`IIADDQ` 需要常数字 `valC`
- 译码阶段寄存器选择
  - srcB：`IIADDQ` 需要读取 `rB` 的旧值参与运算，故设置 `srcB = rB`
  - dstE：`IIADDQ` 的写回目标为 `rB`，故设置 `dstE = rB`
- 执行阶段 ALU 选择与条件码更新
  - aluA：对 `IIADDQ` 选择 `valC`（立即数）作为 A 输入
  - aluB：对 `IIADDQ` 选择 `valB`（`rB` 旧值）作为 B 输入
  - alufun：保持默认加法 `ALUADD`
  - set_cc：对 `IIADDQ` 设置为更新条件码

=== 构建与测试

完成 `seq-full.hcl` 修改后，修改`sim/Makefile`，添加 `partb` 目标以便快速测试：
```make
partb:
	mkdir -p $(PARTB)
	(cd seq; ./ssim -t ../y86-code/asumi.yo > ../$(PARTB)/asumi-ssim.log)
	(cd y86-code; make testssim > ../$(PARTB)/y86-testssim.log)
	(cd ptest; make SIM=../seq/ssim > ../$(PARTB)/ptest-ssim.log)
	(cd ptest; make SIM=../seq/ssim TFLAGS=-i > ../$(PARTB)/ptest-issim.log)
```
先编译生成新的 `ssim`
```bash
make clean
make VERSION=full
```
之后运行 `make partb`，通过 `asumi.yo` 小程序与回归测试验证新增指令正确性。结果如下
```log
Y86-64 Processor: seq-full.hcl
137 bytes of code read
IF: ...
32 instructions executed
Status = HLT
Condition Codes: Z=1 S=0 O=0
Changed Register State:
%rax:	0x0000000000000000	0x0000abcdabcdabcd
%rsp:	0x0000000000000000	0x0000000000000100
%rdi:	0x0000000000000000	0x0000000000000038
%r10:	0x0000000000000000	0x0000a000a000a000
Changed Memory State:
0x00f0:	0x0000000000000000	0x0000000000000055
0x00f8:	0x0000000000000000	0x0000000000000013
ISA Check Succeeds

../seq/ssim -t ...
grep "ISA Check" *.seq
asumr.seq:ISA Check Succeeds
asum.seq:ISA Check Succeeds
cjr.seq:ISA Check Succeeds
j-cc.seq:ISA Check Succeeds
poptest.seq:ISA Check Succeeds
prog1.seq:ISA Check Succeeds
prog2.seq:ISA Check Succeeds
prog3.seq:ISA Check Succeeds
prog4.seq:ISA Check Succeeds
prog5.seq:ISA Check Succeeds
prog6.seq:ISA Check Succeeds
prog7.seq:ISA Check Succeeds
prog8.seq:ISA Check Succeeds
pushquestion.seq:ISA Check Succeeds
pushtest.seq:ISA Check Succeeds
ret-hazard.seq:ISA Check Succeeds
rm ...

./optest.pl -s ../seq/ssim -i
Simulating with ../seq/ssim
  All 58 ISA Checks Succeed
./jtest.pl -s ../seq/ssim -i
Simulating with ../seq/ssim
  All 96 ISA Checks Succeed
./ctest.pl -s ../seq/ssim -i
Simulating with ../seq/ssim
  All 22 ISA Checks Succeed
./htest.pl -s ../seq/ssim -i
Simulating with ../seq/ssim
  All 756 ISA Checks Succeed

./optest.pl -s ../seq/ssim
Simulating with ../seq/ssim
  All 49 ISA Checks Succeed
./jtest.pl -s ../seq/ssim
Simulating with ../seq/ssim
  All 64 ISA Checks Succeed
./ctest.pl -s ../seq/ssim
Simulating with ../seq/ssim
  All 22 ISA Checks Succeed
./htest.pl -s ../seq/ssim
Simulating with ../seq/ssim
  All 600 ISA Checks Succeed
```
这证明新增的 `iaddq` 指令功能正确，且未破坏原有指令行为。

== Part C: 流水线优化 ncopy

=== 任务概述

Part C 的目标是同时修改：
- `ncopy.ys`：对给定的 src 数组复制到 dst，并返回 src 中 >0 的元素个数（返回值在 %rax）。
- `pipe-full.hcl`：实现/支持 IIADDQ 指令，并保证流水线控制逻辑（stall/bubble/转移）正确，通过回归测试。
性能指标为在 PIPE 模拟器上运行 `benchmark.pl` 得到的 Average CPE（1$~$64 长度取平均）。

=== `ncopy.ys` 的优化思路与实现

==== 瓶颈

基准版 ncopy 的主要开销来自：
- 循环控制开销（每处理 1 个元素就要更新 `len`、更新指针、分支回跳）
- 频繁的分支（每个元素都要 `if (val > 0)`，会产生分支代价）
- load/use hazard：`mrmovq` 后紧跟使用该寄存器（例如 `andq`）容易形成流水线停顿

==== 核心优化：8-way loop unrolling + 指令调度隐藏 load/use

- 主循环按 8 个元素展开（8-way unroll）
  - 先将 `len` 预减 8，进入主循环，每次迭代处理 8 个元素，显著减少循环控制指令与回跳次数。
- Load 与 Store/Test/Count 交织（隐藏 load/use 停顿）
  - 先连续 load 4 个元素到寄存器
  - 对这 4 个元素依次 store，并用 `andq` 设置条件码后 `jle` 判断是否计数
  - 在每次 store/test 后立刻发起下一次 load（把后 4 个元素穿插加载进来）
  - 最后对后 4 个元素执行 store/test/count
  - 这样可以用“与 load 无关的指令”填充 load→use 的间隔，减少流水线 bubble。
- 计数更新用 `iaddq $1, %rax`，不额外保留常量寄存器
  - 避免 `irmovq $1, %r8 + addq %r8,%rax` 这种固定常量寄存器长期占用（同时也少一条依赖）。
- 尾处理（remainder）按 4/2/1 分段
  - 主循环退出后，将剩余元素数恢复为 0..7，然后：
    - 若 `rem>=4` 处理 4 个
    - 若 `rem>=2` 处理 2 个
    - 若 `rem==1` 处理 1 个
  - 分段 remainder 比单元素 `while` 更少分支/更少循环开销。

==== 正确性保证

- 每个元素都严格执行：
  - `val = *src`
  - `*dst = val`
  - 若 `val > 0` 则 `count++`
- `src`/`dst` 指针与 `len` 的更新和基准语义一致，尾处理覆盖所有 `len` 取值。

=== `pipe-full.hcl` 的修改内容

目标是两件事：
- 实现 IIADDQ 指令的数据通路/控制信号
- 支持一个简单的静态分支预测策略（BTFNT）并正确处理冒险与冲刷流水线

==== `IIADDQ` 的实现点

在 HCL 中，`IIADDQ rB, V` 等价于：
- `valE = R[rB] + V`
- 写回到 `rB`
- 更新条件码（与 `OPQ` 类似）
在这些地方加入了 IIADDQ：
- `instr_valid`：把 `IIADDQ` 加入合法指令集合
- `need_regids` / `need_valC`：`IIADDQ` 需要 regid + 立即数
- Decode：
  - `d_srcB`：`IIADDQ` 读取 `rB`
  - `d_dstE`：`IIADDQ` 写回 `rB`
- Execute：
  - `aluA`：对 `IIADDQ` 选择 `E_valC`
  - `aluB`：对 `IIADDQ` 选择 `E_valB`
  - `set_cc`：对 `IIADDQ` 开启 CC 更新（并且仅在无异常状态下更新）

==== 分支预测与冲刷（BTFNT）

参考文件夹下的`pipe-btfnt.hcl`，实现一个简单的静态分支预测，策略是 Backward Taken / Forward Not Taken：
- Fetch 阶段预测：
  - 若 `IJXX` 的 `target (f_valC) < fall-through (f_valP)`，预测 taken，`f_predPC = f_valC`
  - 否则预测 not-taken，`f_predPC = f_valP`
- 在不新增 pipeline 字段的情况下判断预测是否错了：
  - 在 Decode：对 `IJXX` 强制 `d_valA = D_valP`（即 fall-through）
  - 在 Execute：对 `IJXX` ALU 计算 `valE = valC`（即 target）
  - 于是到了 M 阶段，`M_valA` 就是 fall-through，`M_valE` 就是 target
    - 只要比较 `M_valE < M_valA`，就能得到“当初 Fetch 的预测方向”，再与 `M_Cnd`（真实跳转条件）比对即可检测误预测。
- PC 重定向（`f_pc`）：
  - 误预测且真实不跳：回到 `M_valA`
  - 误预测且真实跳：转到 `M_valE`
- 冲刷流水线（`D_bubble` / `E_bubble`）：
  - 当 Execute 判定分支误预测时，对 D/E 注入 bubble，丢弃错路径指令。

=== 构建与测试

完成 `pipe-full.hcl` 修改后，修改`sim/Makefile`，添加 `partc` 目标以便快速测试：
```make
mkpipe:
	(make clean)
	(make)
	(cd pipe; make clean; make VERSION=full GUIMODE=$(GUIMODE) TKLIBS="$(TKLIBS)" TKINC="$(TKINC)" CFLAGS="-Wall -O2 $(COMPAT)")

partc:
	mkdir -p $(PARTC)
	(cd pipe; ../$(YAS) ncopy.ys 2>&1 | tee ../$(PARTC)/ncopy-yas.log)
	(cd pipe; ./check-len.pl < ncopy.yo 2>&1 | tee ../$(PARTC)/ncopy-len.log)
	(cd pipe; ../misc/yis sdriver.yo 2>&1 | tee ../$(PARTC)/sdriver-ypipe.log)
	(cd pipe; ./correctness.pl 2>&1 | tee ../$(PARTC)/pipe-correctness.log)
	(cd pipe; ./correctness.pl -p 2>&1 | tee ../$(PARTC)/pipe-pcorrectness.log)
	(cd pipe; ./benchmark.pl 2>&1 | tee ../$(PARTC)/pipe-benchmark.log)
```
先编译生成新的 `psim` 后，运行 `make partc`，通过正确性测试与性能基准测试验证修改正确性与性能提升。结果如下
```log
Simulating with instruction set simulator yis
	ncopy
0	OK
...
64	OK
128	OK
192	OK
256	OK
68/68 pass correctness test


Simulating with pipeline simulator psim
	ncopy
0	OK
...
64	OK
128	OK
192	OK
256	OK
68/68 pass correctness test

	ncopy
0	15
...
64	416	6.50
Average CPE	8.30
Score	43.9/60.0
```
可以看到，新增的 IIADDQ 指令与分支预测逻辑均正确通过了测试，且 ncopy 的 Average CPE 从基准版的 10.5 降低到 8.3，性能显著提升。可以得到22分。
