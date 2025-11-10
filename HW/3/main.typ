#import "@preview/scripst:1.1.1": *

#show: scripst.with(
  title: [计算机组成原理],
  info: [第三次作业],
  author: "Anzrew",
  time: "2025/11/7",
)

#problem(subname: [3.1])[
  Assume the following values are stored at the indicated memory addresses and registers:
  #align(center)[#three-line-table[
    | address | value | register | value |
    |---------|-------|----------|-------|
    |`0x100`    |`0xFF`   |`%rax`      |`0x100`  |
    |`0x104`    |`0xAB`   |`%rcx`      |`0x10`  |
    |`0x108`    |`0x13`   |`%rdx`      |`0x3`  |
    |`0x10C`    |`0x11`   |    \       | \     |
  ]]
  Fill in the following table showing the values for the indicated operands:
  #align(center)[#three-line-table[
    | Operand        | Value |
    |----------------|-------|
    | `%rax` | \ |
    | `0x104` | \ |
    | `$0x108` | \ |
    | `(%rax)` | \ |
    | `4(%rax)` | \ |
    | `9(%rax,%rdx)` | \ |
    | `260(%rcx,%rdx)` | \ |
    | `0xFC(,%rcx,4)` | \ |
    | `(%rax,%rdx,4)` | \ |
  ]]
]

#solution[
  表中给出了内存、寄存器的值，约定使用 AT&T 寻址记法：`disp(base, index, scale)`，无 `$` 的数字常量作为内存地址（即 `M[disp]`），带 `$` 的是立即数。
  #three-line-table[
    | Operand          | Value   | 计算说明                                               |
    | ---------------- | ------- | -------------------------------------------------- |
    | `%rax`           | `0x100` | 寄存器内容                                              |
    | `0x104`          | `0xAB`  | 取内存 M[0x104]                                       |
    | `$0x108`         | `0x108` | 立即数                                                |
    | `(%rax)`         | `0xFF`  | M[%rax] = M[0x100]                                 |
    | `4(%rax)`        | `0xAB`  | M[0x100+4] = M[0x104]                              |
    | `9(%rax,%rdx)`   | `0x11`  | 地址 = 9 + 0x100 + 0x3 = 0x10C，取 M[0x10C]            |
    | `260(%rcx,%rdx)` | 未知  | 地址 = 260 + 0x10 + 0x3 = 279 (0x117)，题中未给出 M[0x117] |
    | `0sxFC(,%rcx,4)`  | 未知  | 地址 = 0xFC + 0x10×4 = 0x13C，题中未给出 M[0x13C]          |
    | `(%rax,%rdx,4)`  | `0x11`  | 地址 = 0x100 + 0x3×4 = 0x10C，取 M[0x10C]              |
  ]
]

#problem(subname: [3.15])[
  In the following excerpts from a disassembled binary, some of the information has been replaced by X's. Answer the following questions about these instructions.
  + What is the target of the `je` instruction below?(You do not need to know anything about the `callq` instruction here.)
    ```asm
    4003fa: 74 02           je     XXXXXX
    4003fc: ff d0           callq  *%rax
    ```
  + What is the target of the `je` instruction below?
    ```asm
    40042f: 74 f4           je     XXXXXX
    400431: 5d              pop    %rbp
    ```
  + What is the address of the `ja` and `pop` instructions?
    ```asm
    XXXXXX: 77 02           ja     400547
    XXXXXX: 5d              pop    %rbp
    ```
  + In the code that follows, the jump target is encoded in PC-relative form as a 4-byte two's-complement number. The bytes are listed from least significant to most, reflecting the little-endian byte ordering of x86-64. What is the address of the jump target?
    ```asm
    4005e8: e9 73 ff ff ff  jmpq   XXXXXX
    4005ed: 90              nop
    ```
]

#solution[
  - 形如 `je rel8`（机器码 `74 xx`）或 `ja rel8`（`77 xx`）的短跳，位移 `rel8` 是有符号 8 位数，相对于“下一条指令的地址”（也就是当前指令末尾）计算：
    ```
    目标地址 = 下一条指令地址 + sign_extend(rel8)
    ```
  - 形如 `jmp rel32（E9 xx xx xx xx）`的近跳，位移 `rel32` 是有符号 32 位数，仍旧是相对于下一条指令地址计算：
    ```
    目标地址 = 下一条指令地址 + sign_extend(rel32)
    ```
  回到题目
  + `4003fa: 74 02 je XXXXXX`
    - 下一条指令地址是 `0x4003fc`，位移 `0x02`，目标地址 `0x4003fc + 0x02 = 0x4003fe`。
  + `40042f: 74 f4 je XXXXXX`
    - 下一条指令地址是 `0x400431`，位移 `0xf4`，作为有符号数是 `-12`，目标地址 `0x400431 - 12 = 0x400425`。
  + `XXXXXX: 77 02 ja 400547`
    - 第一条是 `ja rel8`：
      - 指令长度 2 字节，所以下一条指令地址 `= XXXXXX + 2`
      - 位移 `rel8 = 0x02 (+2)`
      - 按规则：`目标地址 = (XXXXXX + 2) + 2 = XXXXXX + 4`
      - 已知目标地址 `400547`，解得 `XXXXXX = 400543`
    - 而`ja`占 2 字节，所以 pop 的地址是：
      - `400543 + 2 = 400545`
  + `4005e8: e9 73 ff ff ff jmpq XXXXXX`
    - 下一条指令地址是 `0x4005e8 + 5 = 0x4005ed`
    - 小端序立即数字节为`73 ff ff ff`，组成 32 位值 `0xFF FF FF 73`，有符号表示下是一个负数：`-0x8D = -141`
    - 目标地址 `0x4005ed - 0x8D = 0x400560`

  综上结果为
  - #three-line-table[
      | 题目 | 答案       |
      |------|------------|
      | 第一问 | `0x4003fe` |
      | 第二问 | `0x400425` |
      | 第三问 | `0x400543`（`ja`），`0x400545`（`pop`） |
      | 第四问 | `0x400560` |
    ]
]

#problem(subname: [3.35])[
  For a C function having the general structure
  ```c
  long rfun(unsigned long x){
    if(________)
      return ________;
    unsigned long nx=________;
    long rv=rfun(nx);
    return ________;
  }
  ```
  gcc generates the following assembly code:
  ```asm
  # long rfun(unsigned long x)
  # x in %rdi
  rfun:
    pushq  %rbx
    movq   %rdi, %rbx
    movl   $0, %eax
    testq  %rdi, %rdi
    je     .L2
    shrq   $2, %rdi
    call   rfun
    addq   %rbx, %rax
  .L2:
    popq   %rbx
    ret
  ```
  + What value does rfun store in the callee-save register `%rbx`?
  + Fill in the missing expressions in the C code shown above.
]

#solution[
  + `%rbx` 在函数一开始就存储了函数参数 `x` 的值（`%rdi`）
  + 按照上述含义，C 代码应为：
    ```c
    long rfun(unsigned long x){
      if (x == 0)
        return 0;
      unsigned long nx = x >> 2;
      long rv = rfun(nx);
      return x + rv;
    }
    ```
]

#problem(subname: [3.60])[
  Consider the following assembly code:
  ```asm
  # long loop(long x, int n)
  # x in %rdi, n in %esi
  loop:
    movl    %esi, %ecx
    movl    $1, %edx
    movl    $0, %eax
    jmp     .L2
  .L3:
    movq    %rdi, %r8
    andq    %rdx, %r8
    orq     %r8, %rax
    salq    %cl, %rdx
  .L2:
    testq   %rdx, %rdx
    jne     .L3
    rep; ret
  ```
  The preceding code was generated by compiling C code that had the following overall form:
  ```c
  long loop(long x, int n)
  {
    long result = ________;
    long mask;
    for (mask = ________; mask ________; mask = ________) {
      result |= ________;
    }
    return result;
  }
  ```
  Your task is to fill in the missing parts of the C code to get a program equivalent to the generated assembly code. Recall that the result of the function is returned in register `%rax`. You will find it helpful to examine the assembly code before, during, and after the loop to form a consistent mapping between the registers and the program variables.
  + Which registers hold program values `x`, `n`, `result`, and `mask`?
  + What are the initial values of `result` and `mask`?
  + What is the test condition for `mask`?
  + How does `mask` get updated?
  + How does `result` get updated?
  + Fill in all the missing parts of the C code
]

#solution[
  + 寄存器与变量的对应关系：
    - `x` 存储在 `%rdi` （在循环中拷贝到 `%r8` 作临时）
    - `n` 存储在 `%esi`，随后复制到 `%ecx`，位移用 `%cl`
    - `result` 存储在 `%rax`
    - `mask` 存储在 `%rdx`
  + 初始值：
    - `result` 初始为 `0`（`movl $0, %eax`）
    - `mask` 初始为 `1`（`movl $1, %edx`）
  + 测试条件：`mask != 0`（`testq %rdx, %rdx`）
  + 更新方式：`mask = mask << n`（`salq %cl, %rdx`）
  + 更新 `result`：`result |= (x & mask)`（`andq %rdx, %r8` 和 `orq %r8, %rax`）
  + 填充完整的 C 代码如下：
    ```c
    long loop(long x, int n)
    {
      long result = 0;
      long mask;
      for (mask = 1; mask != 0; mask = mask << n) {
        result |= (x & mask);
      }
      return result;
    }
    ```
]

#problem(subname: [3.61])[
  In Section 3.6.6, we examined the following code as a candidate for the use of conditional data transfer:
  ```c
  long cread(long *xp) {
    return (xp ? *xp : 0);
  }
  ```
  #newpara()
  We showed a trial implementation using a conditional move instruction but argued that it was not valid, since it could attempt to read from a null address.

  Write a C function `cread_alt` that has the same behavior as cread, except that it can be compiled to use conditional data transfer. When compiled, the generated code should use a conditional move instruction rather than one of the jump instructions.
]

#solution[
  先在指针层面做条件选择，把要解引用的地址先选出来，再做一次安全的解引用。这样编译器就能把选择地址的步骤用 `cmov` 来实现，而不是用跳转，也不会解引用空指针。
  ```c
  long cread_alt(long *xp) {
    long zero = 0;
    long *p = xp ? xp : &zero;
    return *p;
  }
  ```
]
