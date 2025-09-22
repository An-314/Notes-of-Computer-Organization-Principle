#import "@preview/scripst:1.1.1": *

= Bits, Bytes, and Integers

== Representing information as bits

=== Byte and Word Oriented Memory Organizations

*二进制表示*
- 0和1
*字节(Byte)的编码方式*
- byte = 8 bits
- 二进制(binary)
  - $00000000_2 tilde 11111111_2$
- 十进制(decimal)
  - $0 tilde 255_(10)$
- 十六进制(hexadecimal)
  - $00 tilde F F_(16)$
  - 在C语言中，十六进制以`0x`开头表示
    - `0xFA1D37B`, `0xfa1d37b`
*字节寻址的内存组织*(Byte-Oriented Memory Organization)
```
Address  |  000...0 |  000...1 |  000...2 |  000...3 |  ...  |  FFF...F |
-------------------------------------------------------------------------
Content  |  ....... |  ....... |  ....... |  ....... |  ...  |  ....... |
```
- 程序使用虚拟地址(Virtual Addresses)
  - 概念上：内存就像一个“超大的一维字节数组”，每个字节都有唯一编号(地址)
  - 实际上：计算机不是单一大内存，而是分层存储结构
    - 寄存器(registers)，高速缓存(cache)，主存(RAM)，硬盘/SSD(swap, file system)
  - 虚拟内存的意义：
    - 每个进程(process)都有自己独立的虚拟地址空间
    - 程序只看到自己的一片“连续内存”，而不会和其他程序直接冲突
    - 硬件和操作系统负责把虚拟地址映射到物理地址
- 编译器 + 运行时系统(Compiler + Run-Time System)
  - 决定不同对象存放在内存的哪个区域；典型的划分(虚拟地址空间布局)：
    - 代码段(text segment)：存放指令(只读)
    - 数据段(data segment)：存放已初始化的全局变量、静态变量
    - BSS 段：存放未初始化的全局变量
    - 堆(heap)：程序运行时动态分配的内存(`malloc`/`new`)
    - 栈(stack)：函数调用时自动分配局部变量、返回地址
  - 所有这些内存区域都在同一个虚拟地址空间里，分配和回收由编译器和运行时系统控制
*机器字(Machine Word)*
- 机器字：处理器能一次自然处理的整数数据大小，也包括地址(pointers/address)
  - 32 位机器 → word = 32 bits = 4 bytes
  - 64 位机器 → word = 64 bits = 8 bytes
- 32 位机器的地址宽度是 32 bit，最大可寻址空间是 $2^32 = 4$GB
- 64 位机器的地址宽度是 64 bit，最大可寻址空间是 $2^64 = 18$EB
  - x86-64 架构 实际只使用 48 位地址：最大可寻址空间是 $2^48 = 256$TB
- 一台机器支持多种数据大小
  - 分数或倍数个机器字
  - 整数个字节
*以字为导向的内存组织*(Word-Oriented Memory Organization)
```
32-bit Words |Addr = 0000|Addr = 0004|Addr = 0008|Addr = 000C|  ...  |
64-bit Words |       Addr = 0000     |      Addr = 0008      |  ...  |
----------------------------------------------------------------------
Bytes        |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  ...  |
Addr.        |00|00|00|00|00|00|00|00|00|00|00|00|00|00|00|00|  ...  |
             |00|01|02|03|04|05|06|07|08|09|0A|0B|0C|0D|0E|0F|  ...  |
```
- 字中第一个字节的地址
- 连续字的地址相差相差 4（32 位）或 8（64 位）

#note(subname: [Data Representations])[
  #three-line-table[
    | C Data Type | Typical 32-bit | Intel IA32 | x86-64 |
    |-------------|----------------|------------|--------|
    | char        | 1 byte         | 1 byte     | 1 byte |
    | short       | 2 bytes        | 2 bytes    | 2 bytes|
    | int         | 4 bytes        | 4 bytes    | 4 bytes|
    | long        | 4 bytes        | 4 bytes    | 8 bytes|
    | long long   | 8 bytes        | 8 bytes    | 8 bytes|
    | float       | 4 bytes        | 4 bytes    | 4 bytes|
    | double      | 8 bytes        | 8 bytes    | 8 bytes|
    | long double | 8 bytes        | 10/12 bytes| 10/16 bytes|
    | pointer     | 4 bytes        | 4 bytes    | 8 bytes|
  ]
]

#note(subname: [关于字节和地址的几点注意])[
  - 大多数计算机使用8位的块（或者*字节*byte）作为*最小的可寻址的存储单位*，而不是在存储器中访问单独的位。
  - 存储器的每个字节都有一个唯一的数字来标识，成为它的*地址*。
  - 一个指针的值（无论指向一个整数或者其它对象）都是某个存储块的第一个字节的虚拟地址。
  - 每台计算机都有一个*字长*（word size），指明整数和指针数据的标称大小（nominal size）。
  - 因为虚拟地址是以这样的一个字来表示的，所以字长决定的最重要的系统参数就是*虚拟地址空间*的大小。
]

=== Byte Ordering

*字节序*(Byte Ordering / Endianness)
- Big Endian
  - 高位字节（Most Significant Byte, MSB）存放在高地址；低位字节（Least Significant Byte, LSB）存放在低地址
  - 常见于：Sun SPARC、PowerPC（早期 Mac）、网络协议（TCP/IP 等）
  - 内存从小到大看起来是：最高位 → 最低位
- Little Endian
  - 高位字节（Most Significant Byte, MSB）存放在低地址；低位字节（Least Significant Byte, LSB）存放在高地址
  - 常见于：Intel x86、x86-64 架构
  - 内存从小到大看起来是：最低位 → 最高位
- 例子：设一个 4 字节整数 `x = 0x01234567`，地址 `&x = 0x100`。
  ```
  Address       | 0x100 | 0x101 | 0x102 | 0x103 |
  -----------------------------------------------
  Big Endian    |  01   |  23   |  45   |  67   |
  Little Endian |  67   |  45   |  23   |  01   |
  ```
*反汇编代码中的“字节倒序(byte-reversed)数值”*
- 反汇编(Disassembly)
  - 反汇编：就是把机器码（二进制指令）转换成可读的汇编语言表示
  - 每条指令在内存中以字节形式存储，反汇编程序会读出这些字节并显示为对应的汇编指令
  - 因为 x86 是 Little Endian 架构，数值在内存中是*低位字节在前，高位字节在后*，所以在反汇编结果里会看到“倒过来”的字节顺序
- 反汇编片段解读
  ```
  Address    Instruction Code        Assembly Rendition
  8048365:   5b                      pop %ebx
  8048366:   81 c3 ab 12 00 00       add $0x12ab,%ebx
  804836c:   83 bb 28 00 00 00 00    cmpl $0x0,0x28(%ebx)
  ```
  - `b5`：`pop %ebx`，从栈顶弹出一个字，存入寄存器`%ebx`
  - `81 c3 ab 12 00 00`：`add $0x12ab, %ebx`
    - `81 c3`：`add`指令操作码 + 寄存器编码
    - `ab 12 00 00`：立即数`0x000012ab`，在内存中是`ab 12 00 00`，反汇编时显示为`0x12ab`
  - `83 bb 28 00 00 00 00`：`cmpl $0x0, 0x28(%ebx)`
    - `83 bb`：`cmpl`指令操作码 + 寄存器编码
    - `28 00 00 00`：偏移量`0x00000028`，在内存中是`28 00 00 00`，反汇编时显示为`0x28`
    - 检查：`*((int *)(ebx + 0x28)) == 0 ?
`
*逐字节查看任意数据的内存表示`show_bytes`*
- `show_bytes` 可以把一段数据的字节级别表示打印出来
  ```c
  typedef unsigned char *pointer;
  void show_bytes(pointer start, int len){
    int i;
    for (i = 0; i < len; i++)
      printf("%p\t0x%.2x\n",start+i, start[i]);
    printf("\n");
  }
  ```
- 例子
  ```c
  int x = 15213;
  show_bytes((pointer)&x, sizeof(int));
  ```
  Little Endian (x86)
  ```
  0x11ffffcb8 0x6d
  0x11ffffcb9 0x3b
  0x11ffffcba 0x00
  0x11ffffcbb 0x00
  ```
*整数表示*
- 十进制：15213
- 二进制：0011 1011 0110 1101
- 十六进制：0x3b6d
- 内存表示（Little Endian）：
  ```
  int A = 15213;
  IA32, x86-64 | 6D | 3B | 00 | 00 |
  Sun          | 00 | 00 | 3B | 6D |
  int B = -15213;
  IA32, x86-64 | 93 | C4 | FF | FF |
  Sun          | FF | FF | C4 | 93 |
  long int C = 15213;
  IA32         | 6D | 3B | 00 | 00 |
  x86-64       | 6D | 3B | 00 | 00 | 00 | 00 | 00 | 00 |
  Sun          | 00 | 00 | 3B | 6D |
  ```

#note(subname: [`show_bytes`作用在`char*`上])[
  ```c
  void show_bytes(byte_pointer start, int len) {
    for (int i = 0; i < len; i++)
    printf(" %.2x", start[i]);
  }
  char *s= "abcd";
  show_bytes((byte_pointer) s, strlen(s));
  ```
  无论是Little Endian还是Big Endian，输出都是：
  ```
  61 62 63 64
  ```
]
#newpara()
*字符串表示*
- 字符串 = 字符数组（array of characters），每个字符存储在一个字节中
- 字符编码：ASCII
  - ASCII 是一种 7 位编码（0-127），常见字符都在里面
  - `"0"` $->$ `0x30`
- 在 C 里，字符串必须以空字符(null-terminated) `'\0'`（值 = `0`）结尾
- 例子
  ```
  char s[6] = "18243";
  Linux/Alpha | 31 | 38 | 32 | 34 | 33 | 00 |
  Sun         | 31 | 38 | 32 | 34 | 33 | 00 |
  ```

== Bit-level manipulations

=== Boolean Algebra

*布尔代数*
- George Boole（布尔，19 世纪）提出了布尔代数
  - 逻辑运算可以像代数一样用符号和公式表示
  - `True` = `1`，`False` = `0`
- 基本运算符
  - 与(AND)：`x & y`
  - 或(OR)：`x | y`
  - 非(NOT)：`~x`
  - 异或(XOR)：`x ^ y`
*布尔代数的应用*
- Claude Shannon 在MIT硕士论文里提出：可以用布尔代数来描述和分析继电器电路
- `A & ~B | ~A & B  ≡  A ^ B`
*一般的布尔代数*
- 按位操作（bitwise operations）：对每一对对应的比特独立应用布尔运算
- 所有性质（结合律、交换律、分配律）在按位运算中依然成立
*表示和操作集合*——位掩码
- 用比特向量表示集合
  - `w`维的比特向量可以表示`{0, 1, ..., w-1}`的子集
  - `a[j] = 1 if j ∈ A else 0`
- 运算
  - 并集（union）：`A ∪ B = A | B`
  - 交集（intersection）：`A ∩ B = A & B`
  - 补集（complement）：`A^c = ~A`
  - 差集（difference）：`A - B = A & ~B`

*C语言中的位操作*
- 它们可以作用于任何整型类型：`char`、`short`、`int`、`long`，包括`unsigned`版本
- 这些操作数视为比特向量，逐位应用运算规则
- 例子
  - `~0x41 = 0xBE`
  - `~0xFF = 0x00`
  - `0x0F & 0xF0 = 0x00`
#caution(subname: [逻辑算符])[
  逻辑运算符（`&&, ||, !`）和位运算符（`&, |, ~, ^`）完全不同
  - 逻辑运算符的操作数被视为单个布尔值（`0`或非`0`）
  - 返回值也是`0`或`1`
  - 短路求值（short-circuit evaluation）
    - `x && y`：如果`x`为假（`0`），则不计算`y`
    - `x || y`：如果`x`为真（非`0`），则不计算`y`
  - 例子
    - `!0x41 = 0x00`
    - `!0x00 = 0x01`
    - `!!0x41 = 0x01`
    - `0x69 && 0x55 = 0x01`
    - `0x69 || 0x55 = 0x01`
  - 实际应用：空指针检查
    ```c
    p && *p
    ```
]
*位移运算（Shift Operations）*
- 左移（Left Shift: `x << y`）
  - 把二进制数`x`向左移动`y`位。
  - 左边溢出的位会被丢弃，右边空出来的位置补`0`
- 右移（Right Shift: `x >> y`）
  - 逻辑右移 (Logical Shift)
    - 把二进制数`x`向右移动`y`位
    - 右边溢出的位会被丢弃，左边空出来的位置补`0`
    - 适用于无符号数（`unsigned`）
  - 算术右移 (Arithmetic Shift)
    - 把二进制数`x`向右移动`y`位
    - 右边溢出的位会被丢弃，左边空出来的位置补符号位（最高位）
    - 适用于有符号数（`int`、`long`）
- 未定义行为 (Undefined Behavior)
  - 在 C 中，如果移位量 < 0 或者 ≥ word size（比如 32 位机上移 32 或更大），结果是未定义
- 例子
  ```
  x          |   01100010
  << 3       |   00010000
  Log.  >> 2 |   00001100
  Arith.>> 2 |   00011000

  x          |   10100010
  << 3       |   00010000
  Log.  >> 2 |   00101000
  Arith.>> 2 |   11101000
  ```
  - 算数右移的做法看上去有点奇特，但对有符号整数的运算非常有用
  - C语言标准并没有明确定义应该使用哪种类型的右移
    - 对于无符号数据（也就是以限定词unsigned声明的整型对象），右移必须是逻辑的
    - 而对于有符号数据（默认的声明的整型对象），算术的或者逻辑的右移都可以

== Integers

=== Representation: unsigned and signed

*整数的编码*
- 无符号整数（Unsigned Integers）
  $
    "B2U"(X) = sum_(i=0)^(w-1) x_i 2^i
  $
- 有符号整数（Signed Integers）
  $
    "B2T"(X) = -x_(w-1) 2^(w-1) + sum_(i=0)^(w-2) x_i 2^i
  $
- 符号位 (Sign Bit)
  - 在补码 (two’s complement)表示法中
    - 最高位 (MSB) = 符号位 ： 0 = 非负数，1 = 负数
  - 正数和负数在内存里的区别只在于最高位
- 例如
  ```
  short int x = 15213;
  short int y = -15213;
  -----------------------------
  x | 3B 6D | 00111011 01101101
  y | C4 93 | 11000100 10010011
  ```
*整数的取值范围*
- 无符号整数（Unsigned Integers）
  - $"U"_min = 0$
    - 000...0
  - $"U"_max = 2^w - 1$
    - 111...1
- 有符号整数（Two’s Complement Integers）
  - $"T"_min = -2^(w-1)$
    - 100...0
  - $"T"_max = 2^(w-1) - 1$
    - 011...1
- 不同字长 (word size) 的整数取值范围
  - $abs(T_min) = T_max + 1$
  - $U_max = 2 times T_max + 1$
- 在 C 语言里的获取方式
  - `sizeof(type)`：返回类型`type`的字节数
  - `<limits.h>`：定义了各种整数类型的取值范围
    - `CHAR_BIT`：每个字节的位数（通常是8）
    - `INT_MIN`, `INT_MAX`：`int`类型的最小值和最大值
    - `LONG_MIN`, `LONG_MAX`：`long`类型的最小值和最大值
    - `UINT_MAX`, `ULONG_MAX`：无符号类型的最大值
  - 这些值是平台相关的，取决于机器字长
- 共同点
  - 在二进制补码里，所有非负数的编码与无符号整数是一致的
- 唯一性
  - 每一个比特模式都对应一个唯一的整数值。
  - 每一个可表示的整数都有一个唯一的比特模式。
- 可逆映射
  - Unsigned $<->$ Bits：
    $
      "U2B"(x) = "B2U"^(-1)(x), "T2B"(x) = "B2T"^(-1)(x)
    $

=== Conversion, casting

*有符号整数 (two's complement) 和无符号整数 (unsigned) 之间的转换*
- 基本思想：保持位模式不变
  - 强制类型转换的结果保持位值不变，只是改变了解释这些位的方式
  - 对大多数C语言的实现而言，处理同样字长的有符号数和无符号数之间相互转换的一般规则是：数值可能会改变，但是位模式不变
  $
    "T2U"(x) = "B2U"("T2B"(x)), "U2T"(x) = "B2T"("U2B"(x))
  $
该双射表达式如下
$
  "T2U"(x) = cases(x & "if" 0 ≤ x ≤ T_max, x + 2^(w) & "if" T_min ≤ x < 0)\
  "U2T"(x) = cases(x & "if" 0 ≤ x ≤ T_max, x - 2^w& "if" T_max < x ≤ U_max)
$

*C语言里signed和unsigned的转换*
- 整数常量 (Constants)
  - 在 C 中，如果写一个字面值，默认是signed int
  - 如果要声明为无符号整数，必须加后缀 `U`
    ```c
    10      // signed int
    10U     // unsigned int
    ```
- 显式类型转换 (Casting)
  - 当你用 `(int)` 或 `(unsigned)` 转换时，效果就是 U2T / T2U 映射
    ```c
    int x = -1;
    unsigned u = (unsigned) x; // u = 2^32 - 1
    int y = (int) u;           // y = -1
    ```
- 隐式类型转换 (Implicit casting)
  - 在 C 里很多时候转换是自动发生的
  - 这种隐式转换可能会带来“负数变成大数”的问题(Casting Surprise)

=== Expanding, truncating

*符号扩展（Sign Extension）*
- 把一个$w$位的有符号整数（补码）扩展为$w+k$位，且数值不变
- 具体做法是：将符号位（最高位）复制到新扩展的位中
  $
    X' = underbrace(x_(w-1) x_(w-1) ... x_(w-1), k "times") x_(w-1) x_(w-2) ... x_0
  $
- 例子
  ```
  short int x = -15213v; // 16 bits
  int y = (int) x;      // 32 bits
  -----------------------------------------------------
  x |       C4 93 |                   11000100 10010011
  y | FF FF C4 93 | 11111111 11111111 11000100 10010011
  ```
*扩展（Expanding）的通用规则*
- Unsigned（无符号）扩展：高位补 0（零扩展，zero extension）。
  - 例：`(unsigned short)0xABCD → (unsigned int)0x0000ABCD`
- Signed（有符号）扩展：高位补符号位（符号扩展，sign extension）。
  - 例：`(short)0xC493 → (int)0xFFFFC493`（值不变：-15213）
*截断（Truncating）的通用规则*
$
  "trunc"_w (x) = x mod 2^w = x \& (2^w - 1)
$

=== Addition, negation, multiplication, shifting

*取负*(Negation) = Complement & Increment
$
  - x = ~x + 1
$
- `~x` 是逐位取反（one's complement，一补数）
- `~x + 1` 就是所谓二补数（two's complement）
$
  ~x + x = 111...1 = -1
$
#newpara()
*无符号加法 (Unsigned Addition)*
- 在硬件里，加法器对两个$w$位的无符号整数执行加法，结果是一个$w$位的无符号整数，丢弃任何溢出的位
  $
    "UAdd"_w (u,v) = (u + v) mod 2^w = cases(u + v & "if" u + v < 2^w, u + v - 2^w & "if" u + v ≥ 2^w)
  $
  #note(subname: [无符号加法构成Able群])[
    这是一个封闭的、交换的、有单位元(0)和逆元(-u mod $2^w$)的群$(ZZ\/2^w ZZ,+)$
  ]
#newpara()
*有符号加法 (Two's Complement Addition)*
- 无符号加法 (UAdd) 和有符号加法 (TAdd) 在位级运算上是完全一样的：
  - 两个$w$位的补码整数相加，结果是一个$w$位的补码整数，丢弃任何溢出的位
  $
    "TAdd"_w (x,y) = (x + y) mod 2^w = cases(x + y & "if" T_min ≤ x + y ≤ T_max, x + y - 2^w & "if" x + y < T_min, x + y + 2^w & "if" x + y > T_max)
  $
  ```c
  int t = u + v;
  int s = (int)((unsigned)u + (unsigned)v);
  ```
  一定有 `t == s`
- 溢出 (Overflow) 的产生
  - 无符号加法
    - 按$2^w$取模，结果总是正确的
    - 溢出只是自然的“绕圈”
    - C 标准也定义良好
  - 有符号加法
    - 补码溢出 = 当结果超出区间 $[-2^(w-1), 2^(w-1)-1]$
    - 同号相加得到异号结果
    - 在硬件里结果依旧是低 $w$ 位，但在数学意义上它已不再是正确值
    - C 标准里有符号溢出是未定义行为（但在硬件 x86/ARM 上通常就是截断后的比特）
- 与无符号加法的关系
  $
    "TAdd"_w (x,y) = "U2T"("UAdd"_w ("T2U"(x), "T2U"(y)))
  $
*乘法 (Multiplication)*
- 精确乘积的需求
  - 如果两个操作数都是$w$位整数，那么乘积可能需要$2w$位来表示
  - 硬件里只能保留低$w$位，高位会被截断
  - 如果要完整保存结果，需要扩展字长或者使用大整数库(arbitrary precision arithmetic)
- 范围
  - 无符号乘法
    - $0 ≤ u, v ≤ 2^w - 1$
    - $0 ≤ u times v ≤ (2^w - 1)^2 < 2^(2w)$
  - 有符号乘法
    - $-2^(w-1) ≤ x, y ≤ 2^(w-1) - 1$
    - $(2^(w-1) - 1)(- 2^(w-1)) ≤ x times y ≤ (-2^(w-1))^2 = 2^(2w-2)$
*C 语言里的无符号乘法 (Unsigned Multiplication)*
- 硬件行为
  - 两个$w$位的无符号整数相乘，结果是一个$w$位的无符号整数，丢弃任何溢出的位
  $
    "UMult"_w (u,v) = (u times v) mod 2^w
  $
*C 语言里的有符号整数乘法 (Signed Multiplication)*
- 硬件行为
  - 两个$w$位的补码整数相乘，结果是一个$w$位的补码整数，丢弃任何溢出的位
  - 这和无符号乘法的定义形式一样，只是解释结果时不同
  $
    "TMult"_w (x,y) = (x times y) mod 2^w
  $
*2的幂次乘法 (Power-of-2 Multiply with Shift)*
- 基本规则
  - 对任意整数（signed 或 unsigned），左移相当于乘以 2 的幂：
    $
      u << k = u times 2^k
    $
- 硬件效率
  - 在很多机器上，移位和加法比乘法更快
    - 虽然现代 CPU 里差距不大，但编译器仍常做这种优化
  #note(subname: [编译器如何优化乘法])[
    ```c
    int mul12(int x) {
        return x * 12;
    }
    ```
    编译器会想办法把这个分解成移位 + 加法，因为移位和加法指令比乘法指令更简单/更快，编译器生成的代码（AT&T 语法）：
    ```
    leal  (%eax,%eax,2), %eax   # eax = x + x*2 = 3x
    sall  $2, %eax              # eax = eax << 2 = 3x * 4 = 12x
    ```
  ]
*2的幂次除法 (Power-of-2 Divide with Shift)*
- 基本规则
  - 对无符号整数，逻辑右移（左侧补 0），C 中对 `unsigned` 的 >> 就是逻辑右移。
    $
      u >> k = floor(u / 2^k)
    $
  #note(subname: [无符号整数除以 2 的幂次在机器代码里的实现])[
    ```c
    unsigned udiv8(unsigned x) {
      return x / 8;
    }

    ```
    编译器生成的汇编
    ```
    shrl $3, %eax    # eax = eax >> 3 (逻辑右移)
    ```
  ]
  - 对有符号整数，算术右移（左侧补符号位），C 中对 `int` 的 >> 通常是算术右移。
    $
      x >> k = cases(floor(x / 2^k) & "if" x ≥ 0, ceil(x / 2^k) = floor((x + (2^k - 1))/2^k) & "if" x < 0)
    $
    - 对负数，结果向零取整（truncation toward zero）
      - `(x + (1<<k)-1) >> k`
  #note(subname: [有符号整数除以 2 的幂次在机器代码里的实现])[
    ```c
    int idiv8(int x) {
      return x / 8;
    }
    ```
    编译器生成的汇编
    ```
      testl %eax, %eax         # 测试 x 是否为负
      js   Lneg                # 若 x<0 跳到负数路径
    Lpos:
      sarl $3, %eax            # 正数：算术右移 3 位，等价 /8 向 0 取整
      ret
    Lneg:
      addl $7, %eax            # 负数：先加偏置 2^3-1 = 7
      jmp  Lpos                # 然后统一算术右移
    ```
  ]

#exercise()[
  For the following C expression on a 32-bit machine, please give each of the result for all values of x and y is 1 or 0.
  - `(x & 7) != 7 || (x << 29 < 0)`
    - 后3位都是1 或者 bit2移到符号位为1
  - `x * x >= 0 == 0`
  - `x > 0 || -x >= 0 == 0`
    - `-T_min = T_min`
]

=== Summary

- 计算机执行的“整数”运算实际上是一种模运算形式
  - 表示数字的有限字长限制了可能的值的取值范围，结果运算可能溢出。
- 补码表示提供了一种既能表示负数也能表示正数的灵活方法，同时使用了与执行无符号算术相同的位级实现
  - 这些运算包括加法、减法、乘法，甚至除法，无论运算数是以无符号形式还是以补码形式表示的，都有完全一样或者非常类似的位级行为
- C语言中的某些规定可能会产生令人意想不到的结果，而这些可能是难以察觉和理解的缺陷的源头
  - unsigned数据类型，虽然它概念上很简单，但可能导致即使是资深程序员都意想不到的行为。比如，当书写整数常数和当调用库函数时
`unsigned` 类型的使用
- 不要因为“值非负”就用 `unsigned`
  - 倒序循环
    ```c
    unsigned i;
    for (i = cnt-2; i >= 0; i--)   // 错误
        a[i] += a[i+1];
    ```
  - 带偏移量的循环
    ```c
    #define DELTA sizeof(int)
    int i;
    for (i = CNT; i - DELTA >= 0; i -= DELTA)
        ...
    ```
- 模运算 / 多精度运算
- 位集表示

*信息 = 位 + 上下文*
