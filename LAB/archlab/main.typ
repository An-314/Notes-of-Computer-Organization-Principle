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
