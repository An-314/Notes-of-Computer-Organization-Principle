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
    "TAdd"_w (x,y) = (x + y) mod 2^w = cases(x + y & "if" T_min ≤ x + y ≤ T_max, x + y + 2^w & "if" x + y < T_min, x + y - 2^w & "if" x + y > T_max)
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

#pagebreak()

= Floating Point

== Background: Fractional binary numbers

*二进制小数*
- 如果使用表示整数的方式表示小数
  $
    sum_(k=-j)^i x_k 2^k
  $
  表示定点数 (fixed-point number)
- 这些数字只能表示有限的分数
  - 例如，`0.1` 在二进制里是无限循环小数
- 观察
  - 乘2相当于左移
  - 除2相当于右移
- 局限
  - 只能表示有限范围的数
  - 其他小数是无限循环小数

== IEEE floating point standard: Definition

*IEEE浮点数*
- IEEE Standard 754
  - 1985年确立为浮点运算的统一标准
    - 此前的格式各异
  - 获所有主流CPU支持
- 设计动机：数值计算优先
  - 对舍入（rounding）、上溢（overflow）、下溢（underflow）等问题提供了良好的规范
  - 但要在硬件里实现并做到高效，实际上很困难
  - 标准是由*数值分析*主导制定的，而不是硬件工程师
*浮点数表示*
- 数值形式：
  $
    (-1)^s times M times 2^E
  $
  - 科学记数法
  - 符号位$s$决定数是正还是负
  - 尾数$M$（也叫有效数significand）表示精度，是落在$[1,2)$范围内的数
  - 指数$E$（exponent）通过 2 的幂次对数值进行加权
- 编码方式：
  - 最高有效位（MSB）是符号位 $s$
  - exp字段用来编码指数$E$（注意，它不是$E$本身）
  - frac字段用来编码尾数$M$（注意，它不是$M$本身）
- 精度
  ```
  Single precision: 32 bits
  | s 1bit | exp 8bits | frac 23bits |
  Double precision: 64 bits
  | s 1bit | exp 11bits | frac 52bits |
  Extended precision: 80 bits (x86)
  | s 1bit | exp 15bits | frac 64bits |
  ```
*规格化数* Normalized Values
- 条件$"exp" != 000..0, 111..1$
- 指数的编码方式：偏移值 (biased value)
  $
    "E" = "exp" - "bias"
  $
  - exp：无符号整数形式的指数字段
  - bias：$2^(k-1)-1$，其中$k$为exp字段的位数
  - 单精度（32位）：bias = 127
    - $"exp" = 1 ... 254$对应$E = -126 ... 127$
  - 双精度（64位）：bias = 1023
    - $"exp" = 1 ... 2046$对应$E = -1022 ... 1023$
- 尾数的编码方式：隐含的1 (implicit leading 1)
  $
    "M" = "1.frac"
  $
  - frac：无符号整数形式的尾数字段
  - 最大值：$1.111...1 = 2 - 2^(-m)$，其中$m$为frac字段的位数
  - 最小值：$1.000...0 = 1$
- 例子
  ```
  float F = 15213.0;
  -----------------------------------------------------
  F = 11101101101101_2 = 1.1101101101101 x 2^13
  M = 1.11011011011010000000000_2
  E = 13
  frac = 1101101101101_2
  exp = E + bias = 13 + 127 = 140 = 10001100_2
  s = 0
  -----------------------------------------------------
  F | 0 10001100 11011011011010000000000
    | s  exp      frac
  ```
*非规格化数* Denormalized Values
- 条件：$"exp" = 000..0$
- 指数值：
  $
    "E" = 1 - "bias"
  $
  不再是$"exp" - "bias"$，而是一个常数
- 尾数值：
  $
    "M" = "0.frac"
  $
  - 不再隐含最高位的1，而是隐含一个0
  - 这样可以表示更接近0的数
- 几种情况
  - $"exp" = 000..0, "frac" = 000..0$：非规格化数
    - 表示0
    - 注意有两个不同的零：+0 和 –0
  - $"exp" = 000..0, "frac" != 000..0$：非规格化数
    - 表示非常接近0的数
    - 随着数越来越小，精度会下降
    - 这些数是等间距（equispaced）的
*特殊值*
- 条件：$"exp" = 111..1$
- 情况1：$"exp" = 111..1, "frac" = 000..0$
  - 表示无穷大 (∞, infinity)
  - 由溢出运算产生
  - 有正无穷和负无穷两种情况
- 情况2：$"exp" = 111..1, "frac" != 000..0$
  - 表示非数 (NaN, Not a Number)
  - 由未定义运算产生（比如0除以0）
  - 用来表示无法得到数值的情况
  - 来源举例
    - sqrt(-1.0)
    - ∞ - ∞
  - NaN 的特点：
    - 一旦产生 NaN，后续运算几乎都会继续得到 NaN（传播特性）
    - NaN 和任何数比较大小，结果都是“假”

#figure(
  image("pic/2025-09-29-10-33-32.png", width: 80%),
  numbering: none,
)

== Example and properties

为了说明浮点数的表示和运算，我们用一个非常小的浮点数系统作为例：
*一个微型浮点数示例 (Tiny Floating Point Example)*
- 格式 (8 位浮点数表示法)
  - s：1 位符号位
  - exp：4 位指数位
  - frac：3 位尾数位
- 与IEEE标准形式相同的总体结构
  - 包括：规范化数 (normalized)、非规范化数 (denormalized)
  - 特殊值：0、NaN、无穷大 (infinity)
*动态范围（只看正数情况）*
```
s exp frac |  E  | Value
------------------------
0 0000 000 | -6  | 0 (denorm)
0 0000 001 | -6  | 0.125 x 2^(-6) = 0.001953125 (denorm) closest to zero
0 0000 010 | -6  | 0.25 x 2^(-6) = 0.00390625 (denorm)
...
0 0000 110 | -6  | 0.75 x 2^(-6) = 0.01171875 (denorm)
0 0000 111 | -6  | 0.875 x 2^(-6) = 0.013671875 (denorm) largest denorm
------------------------
0 0001 000 | -6  | 1.0 x 2^(-6) = 0.015625 (norm) smallest norm
...
0 0001 111 | -6  | 1.875 x 2^(-6) = 0.029296875
0 0010 000 | -5  | 1.0 x 2^(-5) = 0.03125
...
0 0110 111 | -1  | 1.875 x 2^(-1) = 0.9375 (closest to 1 below)
0 0111 000 | 0   | 1.0 x 2^0 = 1.0
0 0111 001 | 0   | 1.125 x 2^0 = 1.125 (closest to 1 above)
0 0111 010 | 0   | 1.25 x 2^0 = 1.25
...
0 1110 110 | 7   | 1.75 x 2^7 = 224.0
0 1110 111 | 7   | 1.875 x 2^7 = 240.0 (largest norm)
------------------------
0 1111 000 | n/a   | +∞
```
这说明即使是小小的 8 位浮点数，也能表示 五个数量级以上的数。
#figure(
  image("pic/2025-09-29-10-53-17.png", width: 80%),
  caption: [6-bit IEEE floating point numbers (1 sign bit, 2 exponent bits, 3 fraction bits)的分布],
)
#figure(
  image("pic/2025-09-29-10-54-12.png", width: 80%),
  caption: [6-bit IEEE floating point numbers (1 sign bit, 2 exponent bits, 3 fraction bits)的非规格数分布],
)

#example()[
  Consider a 5-bit floating-point representation based on the IEEE floating-point format, with one sign bit, two exponent bits (k = 2), and two fraction bits (n = 2). What are the smallest positive normalized number and denormalized number?

  - 非规范化数 (exp = 00)
    - E = 0, M = 0.xx
    #three-line-table[
      | exp | frac | M(十进制) | Value(十进制) |
      | 00  | 00   | 0.00      | 0 `(0.00 x 2^0 = 0)` |
      | 00  | 01   | 0.25      | 0.25 `(0.25 x 2^0 = 0.25)` |
      | 00  | 10   | 0.50      | 0.50 `(0.50 x 2^0 = 0.50)` |
      | 00  | 11   | 0.75      | 0.75 `(0.75 x 2^0 = 0.75)` |
    ]
  - 规范化数 (exp = 01)
    - E = 1, M = 1.xx
    #three-line-table[
      | exp | frac | M(十进制) | Value(十进制) |
      | 01  | 00   | 1.00      | 1 `(1.00 x 2^(1-1) = 1)` |
      | 01  | 01   | 1.25      | 1.25 `(1.25 x 2^(1-1) = 1.25)` |
      | 01  | 10   | 1.50      | 1.50 `(1.50 x 2^(1-1) = 1.50)` |
      | 01  | 11   | 1.75      | 1.75 `(1.75 x 2^(1-1) = 1.75)` |
    ]
  - 规范化数 (exp = 10)
    - E = 2, M = 1.xx
    #three-line-table[
      | exp | frac | M(十进制) | Value(十进制) |
      | 10  | 00   | 1.00      | 2 `(1.00 x 2^(2-1) = 2)` |
      | 10  | 01   | 1.25      | 2.5 `(1.25 x 2^(2-1) = 2.5)` |
      | 10  | 10   | 1.50      | 3 `(1.50 x 2^(2-1) = 3)` |
      | 10  | 11   | 1.75      | 3.5 `(1.75 x 2^(2-1) = 3.5)` |
    ]
  - 特殊值 (exp = 11)
  从而可知最小的正规范化数是 `1.00 x 2^(1-1) = 1.0`，最小的正非规范化数是 `0.01 x 2^(1-1) = 0.25`。
]

*一些数值*
#three-line-table[
  | 描述 | exp | frac | 数值 |
  | ---- | --- | ---- | ---- |
  | 零 | 00...0 | 00...0  | 0 |
  | 最小的正非规范化数 | 00...0 | 00...1  | $2^(1-"bias") times 2^(-m)$ |
  | 最大的非规范化数 | 00...0 | 11...1  | $(1 - 2^(-m)) times 2^(1-"bias")$ |
  | 最小的正规范化数 | 00...1 | 00...0 | $1 times 2^(1-"bias")$ |
  | 最大的正规范化数 | 11...10 | 11...1 | $(2 - 2^(-m)) times 2^("bias")$ |
]

*编码的一些特殊性质 (Special Properties of Encoding)*
- 浮点数的零与整数零相同
  - 当所有比特都为 0 时 → 表示 0
- （几乎）可以用无符号整数比较
  - 但要注意以下几点：
    - 必须先比较符号位
    - 要考虑 -0 = +0
    - NaN 是个麻烦：
      - NaN 的编码值会比任何其他数都“大”
      - 问题：比较运算应该返回什么结果？
    - 其他情况基本没问题
    - 包括：
      - 非规范化数 vs. 规范化数
      - 规范化数 vs. ∞

== Rounding, addition, multiplication

*浮点运算：基本思想 (Floating Point Operations: Basic Idea)*
- $x +_f y = "Round"(x + y)$
- $x times_f y = "Round"(x times y)$
- 基本思想：
  - 首先计算精确结果
  - 然后把结果压缩到目标精度
    - 如果指数太大 → 可能发生溢出 (overflow)
    - 如果尾数装不下 → 可能需要舍入 (rounding)

=== Rounding

*舍入 (Rounding)*
- 舍入模式 (Rounding Modes) ——用“美元”例子说明：
  #three-line-table[
    | 金额     | Towards Zero（趋向 0） | Round Down (−∞) | Round Up (+∞) | Nearest Even（默认） |
    | ------ | ------------------ | --------------- | ------------- | ---------------- |
    | \$1.40  | \$1                 | \$1              | \$2            | \$1               |
    | \$1.60  | \$1                 | \$1              | \$2            | \$2               |
    | \$1.50  | \$1                 | \$1              | \$2            | \$2               |
    | \$2.50  | \$2                 | \$2              | \$3            | \$2               |
    | –\$1.50 | –\$1                | –\$2             | –\$1           | –\$2              |
  ]
- IEEE 754 提供多种舍入模式，但默认用 Nearest Even，因为它能在长期运算中最大限度减少偏差

*更深入地看 “Round-To-Even”（舍入到偶数）*
- 默认舍入模式
  - 除非使用汇编级别指令，否则很难切换成其他模式
  - 其他模式在统计上都有偏差
    - 例如：一组正数求和时，结果会持续偏大或偏小
- 应用到其他小数位 / 位位置时的规则
  - 当数值*恰好落在两个可表示数的正中间*
  - 规则：向偶数的最低有效位（least significant digit）舍入
  - 示例（四舍五入到小数点后两位）：
    - 1.2349999 → 1.23 （不到 1.235）
    - 1.2350001 → 1.24 （超过 1.235）
    - 1.2350000 → 1.24 （正好在一半 → 向偶数进）
    - 1.2450000 → 1.24 （正好在一半 → 向偶数舍）

*二进制数的舍入 (Rounding Binary Numbers)*
- 二进制小数
  - 当最后一位（最低有效位，LSB）是 0 → 认为是“偶数 (even)”
  - 当舍入位置右边的比特是 100…₂ → 表示“刚好一半 (half way)”
- 示例：舍入到最接近的 1/4（即保留二进制小数点后 2 位）
  #three-line-table[
    | 值 (Value)  | 二进制 (Binary) | 舍入后 (Rounded) | 动作 (Action)     | 最终结果 (Rounded Value) |
    | ---------- | ------------ | ------------- | --------------- | -------------------- |
    | (2 + 3/32) | (10.00011₂)  | (10.00₂)      | 小于 1/2 → 向下舍    | 2                    |
    | (2 + 3/16) | (10.00110₂)  | (10.01₂)      | 大于 1/2 → 向上舍    | 2 1/4                |
    | (2 + 7/8)  | (10.11100₂)  | (11.00₂)      | 正好一半 → 向上舍      | 3                    |
    | (2 + 5/8)  | (10.10100₂)  | (10.10₂)      | 正好一半 → 向下舍（取偶数） | 2 1/2                |
  ]

#example()[
  The following binary fractional values would be rounded to the nearest half (1 bit to the right of the binary point), according to the round-to-even rule. Which one would be rounded to 10.1?
  - 10.010
  - 10.011
  - 10.101
  - 10.110
]
#solution[
  - 10.010 → 10.0 (正好一半，向偶数舍入)
  - 10.011 → 10.1 (大于一半，向上舍入)
  - 10.101 → 10.1 (小于一半，向下舍入)
  - 10.110 → 11.0 (正好一半，向偶数舍入)
]

=== Multiplication

- 运算
  $
    (-1)^(s_1) M_1 2^E_1 times (-1)^(s_2) M_2 2^E_2
  $
- 精确结果 (Exact Result)：
  $
    (-1)^s M 2^E
  $
  - $s = s_1 xor s_2$
  - $M = M_1 times M_2$
  - $E = E_1 + E_2$
- 修正步骤 (Fixing)：
  - 如果 $M$ 不在 $[1,2)$ 范围内 → 需要调整
    - 如果 $M ≥ 2$ → $M = M / 2, E = E + 1$
    - 如果 $M < 1$ → $M = M times 2, E = E - 1$
  - 如果 $E$ 超出范围 → 可能溢出 (overflow)
  - 将 $M$ 舍入到目标精度
- 实现
  - 最大的工作量：尾数的乘法

浮点乘法的数学性质 (Mathematical Properties of FP Mult)
- 与交换环 (Commutative Ring) 对比
  - 乘法封闭性 (Closed under multiplication)?
    - 不完全：可能产生 ∞ 或 NaN
  - 交换律 (Commutative)?
    - 成立
  - 结合律 (Associative)?
    - 数学上应成立，但浮点数中会被溢出和舍入误差破坏
  - 1 是乘法单位元 (Multiplicative identity)?
    - 成立
  - 乘法对加法的分配律 (Distributive)?
    - 数学上应成立，但浮点数中会被溢出和舍入误差破坏
- 单调性 (Monotonicity)
  - 如果 $x ≥ y$，那么 $x times_f z ≥ y times_f z$
  - 除了涉及 ∞ 或 NaN 的情况，这个性质成立

=== Addition

*浮点数加法 (Floating Point Addition)*
$
  (-1)^(s_1) M_1 2^E_1 + (-1)^(s_2) M_2 2^E_2, E_1 > E_2
$
- 精确结果 (Exact Result)：
  $
    (-1)^s M 2^E
  $
  - 符号$s$，尾数$M$
    - 来自*符号对齐 + 加法*的结果
  - 指数$E = E_1$
  $
    (-1)^s_1 M_1 + (-1)^s_2 M_2 2^(E_2 - E_1) = M
  $
- 修正步骤 (Fixing)：
  - 如果$M>=2$，尾数右移，指数加 1
  - 如果$M<1$，尾数左移，指数减 1
  - 如果$E$超出范围 → 可能溢出 (overflow)
  - 将$M$舍入到目标精度
*浮点加法的数学性质 (Mathematical Properties of FP Add)*
- 与阿贝尔群 (Abelian Group) 的对比
  - 加法封闭性 (Closed under addition)?
    - 不完全：可能产生 ∞ 或 NaN
  - 交换律 (Commutative)?
    - 成立
  - 结合律 (Associative)?
    - 不总成立（溢出 & 舍入误差会破坏）
  - 0 是加法单位元 (Additive identity)?
    - 成立
  - 每个元素都有加法逆元 (Additive inverse)?
    - 对大多数数成立
    - 但 ∞ 和 NaN 没有加法逆元
- 单调性 (Monotonicity)
  - 如果 $x ≥ y$，那么 $x +_f z ≥ y +_f z$
  - 除了涉及 ∞ 或 NaN 的情况，这个性质成立

== Floating point in C

*C 语言中的浮点数 (Floating Point in C)*
- 语言保证两种浮点精度：
  - `float` → 单精度 (single precision)
  - `double` → 双精度 (double precision)
- 类型转换 / 强制转换 (Conversions / Casting)
  - 在 int、float、double 之间转换会改变二进制表示
  - `double` / `float` → `int`
    - 会截断小数部分
    - 类似于“向零舍入”
    - 如果超出整数范围，或为 NaN → 结果未定义（通常设为 Tmin，即最小整数值）
  - `int` → `float`
    - 会按照舍入模式进行舍入（默认是 round-to-even）
  - `int` → `double`
    - 只要 `int` 的位宽 ≤ 53 位，就能精确转换（因为双精度尾数有 53 位有效二进制位）；在大多数平台，`int` ≤ 32 位，所以一定能*无损转换*


#example()[
  Assume variables x, f, and d are of type int (32 bits), float, and double, respectively. For each of the following C expressions，please judge the result of which is True.
  + `x==(int)(double) x`
  + `d==(double)(float)d`
  + `d*d>=0.0`
  + `(f+d)-f==d`
]

#solution[
  + `x == (int)(double)x`
    - 过程：int → double → int
    - int → double：32 位整数最多 31 位有效数值位（符号除外），小于 double 53 位精度 → 完全精确
    - 再从 double 转回 int：不会丢信息（只要不溢出 int 范围）
    - 所以，对所有合法 int，这个成立
  + `d == (double)(float)d`
    - 过程：double → float → double
    - double → float：精度可能丢失（float 只有 24 位有效位）
    - 再转回 double：丢失的精度不会恢复
  + `d*d >= 0.0`
    - 过程：double → double
    - double → double：不会丢失信息
  + `(f+d)-f == d`
    - 期望是：加上 f 再减去 f，应该回到 d
    - 但浮点加法有 对齐指数：
      - 如果 d 很大，f 很小，f+d 直接 ≈ d
      - 再减去 f → (f+d) - f ≈ d - f ≠ d
]

== Summary

*还有很多浮点格式*
#three-line-table[
  | 格式                        | 位宽        | 指数位/尾数位                  | 数值范围            | 精度特点                 | 主要应用                             |
  | ------------------------- | --------- | ------------------------ | --------------- | -------------------- | -------------------------------- |
  | *FP8 (E5M2)*            | 8         | 5/2                      | 动态范围大           | 精度低，只有 2 位小数         | 训练/推理中的权重表示（适合大范围数值）             |
  | *FP8 (E4M3)*            | 8         | 4/3                      | 范围比 E5M2 小      | 精度比 E5M2 稍好（3 位小数）   | 激活值/梯度（需要更细精度）                   |
  | *FP8 (UE8M0)*           | 8         | 8/0                      | 仅指数             | 没有小数部分，纯数量级          | 用于极简存储，几乎不用在训练/推理核心计算            |
  | *FP16 (IEEE 半精度)*       | 16        | 5/10                     | \~1e-5 \~ 6e4     | 精度有限，容易溢出/下溢         | 早期深度学习推理                         |
  | *BF16 (BFloat16)*       | 16        | 8/7                      | 与 FP32 范围一致     | 精度较低，但范围大            | 深度学习训练/推理主流格式（Google TPU 等）      |
  | *TF32 (TensorFloat-32)* | 19 (存储32) | 8/10 (取 FP32 指数+FP16 尾数) | 范围大             | 比 FP16 稍准，兼容 FP32 指数 | NVIDIA Tensor Core 训练（Ampere 架构） |
  | *FP32 (单精度)*            | 32        | 8/23                     | \~1e-38 \~ 1e38   | 7 位十进制精度             | 通用训练，推理 fallback                 |
  | *FP64 (双精度)*            | 64        | 11/52                    | \~1e-308 \~ 1e308 | 15–16 位十进制精度         | 科学计算，仿真，金融，非深度学习主流               |
]
