## Archlab: 优化流水线处理器的性能 

-----

## 1 简介

在本次实验中，你将学习流水线 Y86-64 处理器的设计与实现，并通过优化处理器和一个基准程序来最大化性能。完成实验后，你将深刻理解代码和硬件之间如何相互作用并影响程序性能。

该实验分为三个部分，每个部分都需要单独提交。

  * **Part A**：你将编写一些简单的 Y86-64 程序，并熟悉 Y86-64 工具集。
  * **Part B**：你将为 SEQ 模拟器扩展一条新指令。
  * **Part C**：这是实验的核心部分，你将优化 Y86-64 基准程序和处理器设计。

## 2 准备工作

1. 下载作业文件`archlab-handout.tar`。
2. 执行命令：`tar xvf archlab-handout.tar`。这会将以下文件解压到目录中：`README`、`Makefile`、`sim.tar`、`archlab.pdf` 和 `simguide.pdf`。
3. 执行命令 `tar xvf sim.tar`。这会创建一个名为 `sim` 的目录，其中包含你将要使用的 Y86-64 工具。你所有的工作都将在这个目录内完成。
4. 切换到 `sim` 目录并构建 Y86-64 工具： 
   ```bash
   unix> cd sim
   unix> make clean; make
   ```


## 3 Part A

这部分你将在 `sim/misc` 目录下工作。

你的任务是编写并模拟三个 Y86-64 程序，这些程序的预期行为参考 `examples.c` 文件中的C函数示例定义。在实现过程中，你应该遵循x86-64关于函数参数传递、寄存器使用和栈使用的约定，包括保存和恢复任何你使用到的被调用者保存（callee-save）的寄存器。要对你的程序进行测试，你可以使用 YAS 程序汇编你的代码，然后用 YIS 指令集模拟器来运行它们。

请在每个程序的开头注释中写上你的姓名和学号。

#### `sum.ys`: 迭代求链表元素之和

编写一个Y86-64程序 `sum.ys`，用于迭代计算一个链表中所有元素的和。你的程序应该包含一些设置栈结构、调用一个函数然后停止的代码。

该函数（`sum_list`）在功能上应等同于 `examples.c` 文件中的C函数 `sum.list`。具体代码为：

```C
/* linked list element */
typedef struct ELE {
    long val;
    struct ELE *next;
} *list_ptr;

/* sum_list - Sum the elements of a linked list */
long sum_list(list_ptr ls)
{
    long val = 0;
    while (ls) {
	val += ls->val;
	ls = ls->next;
    }
    return val;
}
```

你可以在代码中使用以下三元素列表来测试你的程序： 

```nasm
# Sample linked list
.align 8
elel:
    .quad 0x00a
    .quad ele2
ele2:
    .quad 0x0b0
    .quad ele3
ele3:
    .quad 0xc00
    .quad 0
```

#### `rsum.ys`: 递归求链表元素之和

编写一个Y86-64程序 `rsum.ys`，用于递归地计算一个链表中所有元素的和。这段代码应该与 `sum.ys` 中的代码类似，但它应该使用一个名为 `rsum_list` 的函数来递归求和。该函数在功能上应等同于如下的C函数。

```C
/* rsum_list - Recursive version of sum_list */
long rsum_list(list_ptr ls)
{
    if (!ls)
	return 0;
    else {
	long val = ls->val;
	long rest = rsum_list(ls->next);
	return val + rest;
    }
}
```

使用与 `list.ys` 相同的三个元素列表来测试你的程序。

#### `copy.ys`: 复制源块到目标块

编写一个程序 (`copy.ys`)，将内存中的一个数据块从一个位置复制到另一个（不重叠的）内存区域，并计算所有被复制字的校验和（Xor）。你的程序应该包含设置栈帧、调用 `copy_block` 函数然后停止的代码。该函数在功能上应等同于如下的C函数 `copy_block`。

``` C
/* copy_block - Copy src to dest and return xor checksum of src */
long copy_block(long *src, long *dest, long len)
{
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

  使用以下的三元素源块和目标块来测试你的程序： 

```nasm
.align 8
# Source block
src:
    .quad 0x00a
    .quad 0x0b0
    .quad 0xc00
# Destination block
dest:
    .quad 0x111
    .quad 0x222
    .quad 0x333
```

## 4 Part B

这部分你将在 `sim/seq` 目录下工作。

#### 任务介绍

你的任务是扩展 SEQ 处理器以支持 `iaddq` 指令，对该指令的描述可以在 CS:APP3e 教材习题4.51和4.52中找到。为了添加这条指令，你需要修改 `seq-full.hcl` 文件，该文件实现了教材中描述的 SEQ 版本。此外，它还包含了一些你的代码中会需要的常量声明。

你还需要在你的HCL文件开头添加以下注释：

  * 你的姓名和学号。
  * 对 `iaddq` 指令所需计算过程的描述。可以参考教材图4.18中对 `irmovq` 和 `OPq` 的描述作为指导。

#### 构建和测试

完成 `seq-full.hcl` 文件的修改后，你需要基于此 HCL 文件构建一个新的 SEQ 模拟器（`ssim`）实例，然后进行测试： 

  * **构建新的模拟器**：你可以使用 `make` 来构建新的 SEQ 模拟器： 

    ```bash
    unix> make VERSION=full
    ```

    
    这会构建一个使用你在 `seq-full.hcl` 中指定控制逻辑的 `ssim` 版本。

  * **在简单的 Y86-64 程序上测试**：对于初步测试，我们建议在 TTY 模式下运行像 `asumi.yo`（测试 `iaddq`）这样的简单程序，并将结果与 ISA 模拟进行比较： 

    ```bash
    unix> ./ssim -t ../y86-code/asumi.yo
    ```

    
    如果 ISA 测试失败，你可以在 GUI 模式下单步调试你的实现： 

    ```bash
    unix> ./ssim -g ../y86-code/asumi.yo
    ```

  * **使用基准程序重新测试**：一旦你的模拟器能够正确执行小程序，你就可以在 `../y86-code` 中的 Y86-64 基准程序上自动进行测试： 

    ```bash
    unix> (cd ../y86-code; make testssim)
    ```

    
    这将在基准程序上运行 `ssim`，并通过将最终的处理器状态与高级 ISA 模拟的状态进行比较来检查正确性。**请注意，基准测试并不会测试你新增的指令，而是检查你新增的代码没有为原始指令引入错误。**

  * **执行回归测试**：当你能正确执行基准程序后，你应该运行 `../ptest` 中更广泛的回归测试集。

      * 测试除 `iaddq` 之外的所有内容： 
        ```bash
        unix> (cd ../ptest; make SIM=../seq/ssim)
        ```
        
      * 测试你对 `iaddq` 的实现： 
        ```bash
        unix> (cd ../ptest; make SIM=../seq/ssim TFLAGS=-i)
        ```
        

更多关于 SEQ 模拟器的信息，请参考实验资料《CS:APP3e Guide to Y86-64 Processor Simulators (simguide.pdf)》。

## 5 Part C

这部分你将在 `sim/pipe` 目录下工作。

#### 任务介绍

你在 Part C 的任务是修改 `ncopy.ys` 和 `pipe-full.hcl`，最终的目标是让 `ncopy.ys` 运行得尽可能快。

`ncopy` 函数将一个长度为 `len` 的整型数组 `src` 复制到不重叠的 `dst`，并返回 `src` 中正整数的数量。其C语言实现如下。

```c
/*
 * ncopy - copy src to dst, returning number of positive ints
 * contained in src array.
 */
word_t ncopy(word_t *src, word_t *dst, word_t len)
{
    word_t count = 0;
    word_t val;

    while (len > 0) {
        val = *src++;
        *dst++ = val;
        if (val > 0)
            count++;
        len--;
    }
    return count;
}
```

`ncopy.ys` 中包含该函数的基准Y86-64版本。`pipe-full.hcl` 文件包含了 PIPE 的 HCL 代码副本，以及 `IIADDQ` 的声明。

你需要提交两个文件：`pipe-full.hcl` 和 `ncopy.ys`。每个文件的开头需要包括以下注释： 

  * 你的姓名和学号。
  * 对你代码的描述。在每个文件中，描述你如何以及为何修改了代码。

#### 编码规则

你可以自由地进行任何修改，但需遵守以下限制： 

  * 你的 `ncopy.ys` 函数必须能在 YIS 上正确运行。所谓正确，是指它必须正确地复制任意大小的 `src` 块，并在 `%rax` 中返回正确的正整数数量。

    * 汇编后的 `ncopy` 文件长度不得超过1000字节。你可以使用提供的 `check-len.pl` 脚本检查嵌入了 `ncopy` 函数的程序长度： 

    ```bash
    unix> ./check-len.pl < ncopy.yo
    ```

  * 你的 `pipe-full.hcl` 实现必须通过 `../y86-code` 和 `../ptest` 中的回归测试（不带测试 `iaddq` 的 `-i` 标志）。

除此之外，如果你认为 `iaddq` 指令有帮助，你可以自由实现它。你可以对 `ncopy.ys` 函数进行任何保持语义的转换，例如重排指令、用单条指令替换多条指令、删除某些指令以及添加其他指令。阅读教材第5.8节关于循环展开的内容可能会对你有帮助。

#### 构建和运行

为了测试你的代码，你需要构建一个调用你的 `ncopy` 函数的驱动程序。我们提供了 `gen-driver.pl` 程序，它可以为任意大小的输入数组生成驱动程序。

输入： 

```bash
unix> make drivers
```


将会构建以下两个的驱动程序： 

  * `sdriver.yo`: 一个小驱动程序，用于在包含4个元素的小数组上测试 `ncopy` 函数。如果你的程序正确，该程序在复制完 `src` 数组后，会带着寄存器 `%rax` 中的值为2而暂停。
  * `ldriver.yo`: 一个大驱动程序，用于在包含63个元素的较大数组上测试 `ncopy` 函数。如果你的程序正确，该程序在复制完 `src` 数组后，会带着寄存器 `%rax` 中的值为31 (0x1f) 而暂停。

每次修改 `ncopy.ys` 程序后，你可以通过输入 `unix> make drivers` 来重新构建驱动程序。
每次修改 `pipe-full.hcl` 文件后，你可以通过输入 `unix> make psim VERSION=full` 来重新构建模拟器。

要在GUI模式下用一个4元素的小数组测试你的方案，输入： 

```bash
unix> ./psim -g sdriver.yo
```


要在GUI模式下用一个63元素的大数组测试你的方案，输入： 

```bash
unix> ./psim -g ldriver.yo
```


若你的模拟器能够在这两种块长度上正确运行你的 `ncopy.ys` ，你则可以进行以下额外测试： 

* **在ISA模拟器上测试驱动文件**。确保你的 `ncopy.ys` 函数在 YIS 上能正常工作： 

    ```bash
    unix> make drivers
    unix> ../misc/yis sdriver.yo
    ```

* **用ISA模拟器在一系列块长度上测试你的代码**。Perl 脚本 `correctness.pl` 可以生成从0到某个上限（默认为65）以及一些更大尺寸的块长度的驱动文件。它会模拟这些文件（默认使用 YIS）并检查结果，并生成一个报告，显示每个块长度的状态： 

    ```bash
    unix> ./correctness.pl
    ```

* **用流水线模拟器在一系列块长度上测试你的代码**。最后，你可以在流水线模拟器上运行与之前在 ISA 模拟器上相同的代码测试。
    ```bash
    unix> ./correctness.pl -p
    ```

* **对特定长度做调试（可选）。**如果你在某个长度K上得到不正确的结果，你可以为该长度生成一个包含检查代码且结果随机变化的驱动文件： 

  ```bash
  unix> ./gen-driver.pl -f ncopy.ys -n K -rc > driver.ys
  unix> make driver.yo
  unix> ../misc/yis driver.yo
  ```

  程序结束时，寄存器 `%rax` 会有以下值： 
    * `0xaaaa`: 所有测试通过。
    * `0xbbbb`: 计数值不正确。
    * `0xcccc`: `ncopy` 函数超过1000字节。
    * `0xdddd`: 部分源数据未被复制到目标位置。
    * `0xeeee`: 目标区域之前或之后的数据被损坏。

## 6 评估

本次实验总计100分：Part A 20分，Part B 30分，Part C 50分。

#### Part A

Part A 共20分，每个 Y86-64 程序5分。每个程序都将根据其正确性进行评估，包括对栈和寄存器的正确处理，以及与 `examples.c` 中C函数示例的功能等价性。

#### Part B

这部分实验共30分： 

  * 10分：描述 `iaddq` 指令所需的计算过程。
  * 5分：通过 `y86-code` 中的基准回归测试，以验证你的模拟器仍然能正确执行基准套件。
  * 15分：通过 `ptest` 中针对 `iaddq` 的回归测试。

#### Part C

这部分实验共50分。

  * 20分：`ncopy.ys` 和 `pipe-full.hcl` 文件中的描述与实现各占10分。
  * 30分：性能得分。

要获得性能分数，你的程序必须是正确的。也就是说，`ncopy` 必须能在 YIS 上正确运行，且 `pipe-full.hel` 必须通过 `y86-code` 和 `ptest` 中的所有测试。

我们将以**每元素周期数（Cycles Per Element, CPE）**为单位来衡量你函数的性能。如果模拟代码需要 C 个周期来复制一个 N 元素的块，那么 CPE 就是 $C/N$。PIPE 模拟器会显示完成程序所需的总周期数。

基准版本的 `ncopy` 函数在标准 PIPE 模拟器上运行一个63元素的大数组需要897个周期，其 CPE 为 $897/63 = 14.24$。我们将通过计算从1到64个元素块长度的 CPE 平均值来评估你函数的性能。你可以使用 `pipe` 目录中的 `benchmark.pl` Perl 脚本来运行你的 `ncopy.ys` 代码在一系列块长度上的模拟，并计算平均CPE。

```bash
unix> ./benchmark.pl
```

你应该能够达到至少低于9.00的平均CPE。如果你的平均CPE为c，那么你在这部分实验的分数S将是： 
$S = \begin{cases} 0, & c > 10.5 \\ 10 \cdot (10.5 - c), & 7.50 \le c \le 10.50 \\ 30, & c < 7.50 \end{cases}$ 

## 7 提交说明

  * 你需要提交三组文件： 
      * **Part A**: `sum.ys`, `rsum.ys`, `copy.ys` 
      * **Part B**: `seq-full.hcl` 
      * **Part C**: `ncopy.ys`, `pipe-full.hcl` 
  * 请确保在每个提交文件的顶部注释中包含了你的姓名和学号。
    

## 8 提示

  * `sdriver.yo` 和 `ldriver.yo` 都足够小，可以在GUI模式下进行调试。GUI模式能够让你的调试简便许多。

  * 当你以GUI模式运行 `psim` 或 `ssim` 时，“Program Code”窗口最初可能是一个关闭的图标。只需点击该图标即可展开窗口。

  * `psim` 和 `ssim` 模拟器在执行无效的Y86-64目标文件时会因分段错误而终止。

  * 若你在系统中配置了特殊的显示服务器，可能出现GUI窗口无法正确加载的问题。请确保你已经初始化了DISPLAY环境变量： 
    ```bash
    unix> setenv DISPLAY myhost.edu:0
    ```