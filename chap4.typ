#import "@preview/scripst:1.1.1": *

= The Memory Hierarchy

存储层次结构 = 用“快但小”和“慢但大”的存储器组合，假装给程序一个“又快又大”的内存。

CPU 并不是直接“友好地”面对 DRAM 的。现实是：
- 寄存器：极快、极小、极贵
- 缓存（Cache）：快、小
- 主存（DRAM）：慢、大
- 磁盘 / SSD：更慢、更大
但程序员写代码时，只看到一个*统一的内存抽象*（memory abstraction）。

== The memory abstraction

*Recall: Writing & Reading Memory*
- 从程序员视角：
  - 内存是一个 巨大、线性的字节数组
  - 地址从 0 开始
  - 每个地址对应一个字节
  ```c
  *(long *)(A) = y;   // store
  x = *(long *)(A);   // load
  ```
- 在汇编里对应：
  - Store（写内存）
    ```asm
    movq %rax, A
    movq %rax, 8(%rsp)
    ```
  - Load（读内存）
    ```asm
    movq A, %rax
    movq 8(%rsp), %rax
    ```
*Modern Connection between CPU and Memory —— Bus*
- A bus is a collection of parallel wires that carry address, data, and control signals.
  - 地址线（Address Bus）：我要哪个地址？
  - 数据线（Data Bus）：我要/给的数据
  - 控制线（Control Bus）：读还是写？准备好了没？
- Buses are typically shared by multiple devices. Bus 是共享的
  - CPU、内存、I/O 设备都挂在同一条或多条总线上
  - 所以访问内存是一个受限、慢、需要协议的过程

#figure(
  image("pic/memory.pdf", page: 1, width: 80%),
  numbering: none,
)

*Memory Read Transaction（读内存）*
- CPU 把地址 A 放到 bus 上
  ```
  Address bus ← A
  Control bus ← Read
  ```
- 主存看到 A
  - 从 DRAM 中取出 word x
  - 把 x 放到 data bus 上
  ```
  Data bus ← x
  ```
- CPU 从 bus 读数据
  - 把 x 复制进寄存器 `%rax`
- 对应汇编：
  ```asm
  movq A, %rax
  ```
#figure(
  image("pic/memory.pdf", page: 2, width: 80%),
  numbering: none,
)

*Memory Write Transaction（写内存）*
- CPU 把地址 A 放到 bus 上
  ```
  Address bus ← A
  Control bus ← Write
  ```
- CPU 再把数据 y 放到 data bus 上
  ```
  Data bus ← y
  ```
- 主存读数据并写入地址 A
- 对应汇编：
  ```asm
  movq %rax, A
  ```
- 注意：
  - 写内存是两次总线动作
  - 读地址 + 读数据是分开的

#figure(
  image("pic/memory.pdf", page: 3, width: 80%),
  numbering: none,
)

*Memory Hierarchy*
- 真实的延迟数量级
  #three-line-table[
    | 存储层级     | 典型延迟        |
    | -------- | ----------- |
    | Register | $~$1 cycle    |
    | L1 Cache | $~$4 cycles   |
    | L2 Cache | $~$10 cycles  |
    | L3 Cache | $~$40 cycles  |
    | DRAM     | $~$200 cycles |
    | SSD      | $~$10⁵ cycles |
    | HDD      | $~$10⁷ cycles |
  ]
  如果 CPU 每次 load 都等 DRAM，那 CPU 90% 时间都在等内存
- 局部性原理（Locality）
  - 时间局部性（Temporal Locality）：最近用过的数据，很可能马上还会用
  - 空间局部性（Spatial Locality）：用了某个地址，很可能用附近的地址
- 分层结构（从快到慢）
  ```
  CPU
   ↓
  Registers
   ↓
  L1 Cache
   ↓
  L2 Cache
   ↓
  L3 Cache
   ↓
  Main Memory (DRAM)
   ↓
  Disk / SSD
  ```

== Storage technologies and trends

=== RAM

*Random-Access Memory (RAM)*
- Random-Access 的真正含义是：
  - 访问任意地址的时间基本相同
  - 不像磁盘那样要“转到某个位置”
  - 这也是 CPU 能高效工作的前提
- RAM 的基本特征（Key features）
  - RAM is traditionally packaged as a chip RAM 通常是独立的芯片
    - DRAM 条（内存条）
    - SRAM 芯片（早期 cache）
  - or embedded as part of processor chip RAM也可以直接嵌在CPU里
    - L1 / L2 / L3 cache = SRAM，它们和 CPU 在同一块硅片上
    - 这就是 cache 为什么“又快又贵”的根本原因
  - Basic storage unit is normally a cell (one bit per cell)
    - RAM 的最小存储单元是 bit，一个 cell 存 0 或 1
    - 一个 long（8 bytes） = 64 个 cell，内存不是“按变量”存，而是按 bit 存
  - Multiple RAM chips form a memory
    - 单个芯片容量有限
    - 多个芯片组合 → 主存（Main Memory）

*RAM 的两大类型*
- DRAM（Dynamic RAM）
  - DRAM 的物理结构：1 Transistor + 1 capacitor / bit
    - 每一位 = 1 个晶体管（开关）+ 1 个电容（存电荷）
    - 电容：有电 → 1，没电 → 0
  - Capacitor oriented vertically
    - 电容不是平放的，而是 竖着往硅片里“挖深”
    - 因为：芯片面积有限，只能向“深度”要容量
  - DRAM 的致命问题：要刷新（refresh）
    - 电容会漏电，即使不访问，电荷也会慢慢消失
    - 所以：DRAM每隔几十毫秒，必须统一刷新整片内存
    - 占用时间、增加复杂度、降低性能
  - DRAM 的定位
    - 单 bit 成本低，密度高，容量大
    - 唯一适合做主存（Main Memory）
- SRAM（Static RAM）
  - SRAM 的物理结构：6 transistors / bit
    - 每一位 = 6 个晶体管
    - 构成一个稳定的双稳态电路
    - 不靠电容存电荷，靠电路状态存 0 / 1
  - Holds state indefinitely (but still lose data on power loss)
    - 只要不断电，数据就能一直保持，不需要 refresh
    - SRAM 仍然是易失性，断电照样清空
  - SRAM 的代价
    - 晶体管数量多、面积大、功耗高、成本极高
- SRAM vs DRAM 对比表
  #three-line-table[
    | 项目                  | SRAM           | DRAM        |
    | ------------------- | -------------- | ----------- |
    | Transistors per bit | 6 或 8          | 1           |
    | Access time         | *1x（快）*      | *10x（慢）*  |
    | Needs refresh?      | ❌ No           | ✅ Yes       |
    | EDC?                | Maybe          | Yes         |
    | Cost                | *100x*       | *1x*      |
    | Applications        | Cache memories | Main memory |
  ]
  EDC（Error Detection and Correction）
  - DRAM：电容小，易受噪声、辐射影响，bit 翻转概率高；主存必须配 ECC 内存
  - SRAM：位数少，更稳定，有时不需要

*Trends*
- SRAM scales with semiconductor technology SRAM 受益于工艺缩小
  - 功耗、泄漏、面积都开始成为瓶颈
  - 已经接近极限
- DRAM scaling limited by minimum capacitance DRAM 的问题更严重
  - 电容不能无限变小，太小就存不住电
  - Aspect ratio limits how deep can make capacitor
    - 电容靠“向下挖”，但挖太深：制造困难，成本暴涨，可靠性下降

*Conventional DRAM Organization*
- $d times w$ DRAM：共有 $d$ 个 supercell，每个 supercell 有 $w$ bits
  - DRAM 不是一个“平面数组”，而是一个二维结构
  - 每个 `(row, col)` 位置存的不是 1 bit，而是 w bits，就叫一个 supercell
- supercell (i, j) = 第 i 行、第 j 列 = 一组并行的 bits
  - 16 × 8 DRAM chip，16 = 行数 × 列数，8 = 每个 supercell 的位宽（8 bits）

#figure(
  image("pic/memory.pdf", page: 4, width: 80%),
  numbering: none,
)
- Rows / Cols
  - DRAM 是一个二维阵列
  - 行选择 + 列选择
- Internal Row Buffer（行缓冲）
  - DRAM 里最重要的结构
  - 一次只能激活一整行
- Address 线复用*地址复用（address multiplexing）*
  - 只有少量地址线
  - 行地址和列地址分两次送
  - 先送 row，再送 col
- Data bus
  - 一次传一个 supercell（w bits）

*Reading DRAM Supercell (2,1)*
#figure(
  image("pic/memory.pdf", page: 5, width: 80%),
  numbering: none,
)
- Step 1：RAS（*Row Access Strobe*）
  - Step 1(a)：RAS = 2
    - Memory controller 把：row = 2放到地址线上，同时拉高 RAS 信号
  - Step 1(b)：整行复制到 Row Buffer
    - 把第 2 行的所有列，一次性复制到 row buffer
    - 一次 RAS = 激活整行
- Step 2：CAS（*Column Access Strobe*）
  - Step 2(a)：CAS = 1
    - Memory controller 再把：col = 1 放到同一组地址线，拉高 CAS 信号
  - Step 2(b)：supercell (2,1) 输出
    - 从 row buffer 中：取出第 1 列，即 supercell (2,1)，放到 data bus，传回 CPU
    - DRAM array → row buffer → data bus → CPU
- Step 3：写回（Refresh）
  - 读操作本身会 破坏电容里的电荷
  - 所以：DRAM 会把 row buffer 中的数据，写回原来的那一整行
  - 顺便完成 refresh
- DRAM 读比 SRAM 慢，每次访问代价都很大
- *同一行内的多次访问，非常快*
  - 第一次访问：RAS + CAS（慢）
  - 后续访问：只需要 CAS（快）
  - 不用重新激活行
  - 这就是 DRAM 级别的 spatial locality
- *一次 DRAM 读 = 激活一整行（RAS）→ 选一列（CAS）→ 从 row buffer 返回 supercell → 写回刷新*

*Memory Modules（内存模块）*

#figure(
  image("pic/memory.pdf", page: 6, width: 80%),
  numbering: none,
)
- 多个 DRAM 芯片
- 8 个 8Mx8 DRAM = 64-bit word
  - 每个芯片：提供 8 bits
  - 并行工作：8 × 8 = 64 bits
- 地址是“广播”的
  - 同一个 (row i, col j)
  - 同时送到：DRAM 0、DRAM 1、…、DRAM 7
  - 每个 DRAM：输出自己的 supercell (i,j) 的 8 bits 占据 64-bit word 的一部分

=== Disk

*Storage Technologies* 磁盘 vs 非易失存储
- Magnetic Disks（磁盘）
  - Magnetic medium：数据存成磁化方向（0 / 1）
  - Electromechanical access：有机械臂移动
    - 磁盘慢，不是因为“电子慢”，而是因为“机械慢”
  - Nonvolatile：断电不丢数据
- Nonvolatile (Flash) Memory（闪存）
  - persistent charge：用电荷存数据
  - 3D 结构，100+ 层
  - 每 cell 存 3–4 bits（TLC / QLC）
  - 比 DRAM 慢，但比磁盘快几个数量级，没有机械运动

*What’s Inside a Disk Drive*

#figure(
  image("pic/memory.pdf", page: 7, width: 80%),
  numbering: none,
)
- Platters（盘片）
  - 真正存数据的地方
  - 表面有磁性涂层
  - 通常多个盘片叠在一起
- Spindle（主轴）
  - 带着所有盘片一起转
  - 转速固定（如 7200 RPM）
- Arm（机械臂）
  - 带着读写头
  - 只能做径向运动（里 ↔ 外）
- Actuator（执行器）
  - 控制 arm 的精密电机
  - 决定 seek time（寻道时间）
- Electronics（电子系统）
  - 磁盘里 有处理器 + 内存
  - 负责：
    - 请求调度
    - 缓存
    - 错误纠正
  - 磁盘 ≈ 一个小型嵌入式系统

*Disk Geometry*
#figure(
  image("pic/memory.pdf", page: 8, width: 80%),
  numbering: none,
)
- Platters → Surfaces
  - 每个盘片正反两面
  - 每一面都能存数据
- Tracks（磁道）
  - 一圈一圈的同心圆
- Sectors（扇区）
  - 每条 track 被切成很多小块
  - 每块是*最小读写单位*
  - 常见：512B 或 4KB
- Gaps（间隙）
  - 扇区之间的空隙
  - 用于：
    - 同步
    - 容错
    - 控制信息

*Disk Capacity（磁盘容量）*
#figure(
  image("pic/memory.pdf", page: 9, width: 80%),
  numbering: none,
)
Capacity: maximum number of bits that can be stored.
- 厂商的 GB / TB
  - 1 GB = 10⁹ Bytes, 1 TB = 10¹² Bytes
  - 不是 2³⁰ / 2⁴⁰ Bytes
- 决定容量的三个密度
  #three-line-table[
    | 名称                | 含义                 |
    | ----------------- | ------------------ |
    | Recording density (bits/in) | 每英寸 track 能存多少 bit |
    | Track density (tracks/in) | 每英寸半径能有多少条 track   |
    | Areal density (bits/in2) | 上面两者的乘积            |
  ]
  磁盘容量增长，靠的是“挤得更密”，不是盘变大
- 单盘视角
  - 两个基本运动
    - 盘片一直在转：固定转速（如 7200 RPM）
    - arm 做径向移动：定位到某一条 track
  - 读写头的“悬浮” flies over the disk surface on a thin cushion of air
    - 读写头不接触盘面，距离：纳米级，一旦碰到 → 磁头撞击（head crash）
- 多盘视角
  - Cylinder（柱面）
    - 多个盘片
    - 同一半径位置的 track
    - 组成一个 cylinder
  - 重要结论：
    - 所有读写头是一起移动的
    - 一次 seek = 移动到一个 cylinder
    - 但可以在不同盘面读数据

*Disk Access 的三大时间组成*
#figure(
  image("pic/memory.pdf", page: 10, width: 80%),
  numbering: none,
)
- 一次磁盘访问 ≠ 一步，而是三步：
  $
    T_"access" = T_"avg seek" + T_"avg rotation" + T_"avg transfer"
  $
  - Seek time（寻道时间）
    - 把 arm 移到目标 cylinder
    - 机械运动
    - 最慢、最不可预测
    - 典型
      $
        T_"avg seek" approx 4 tilde 9 "ms"
      $
  - Rotational latency（旋转延迟）
    - 等目标 sector 转到磁头下方
    - *平均要等半圈*
      $
        T_"avg roatation" = 1/2 times 1/"RPMs" times (60 "sec")/(1 "min")
      $
    - Typical rotational rate = $7200 "RPM"$
  - Transfer time（传输时间）
    - 真正“读数据”的时间
    - 非常非常小
      $
        T_"avg transfer" & = "time for one rotation (in minutes)" times "fraction of a rotation to be read" times (60 "sec")/(1 "min") \
        & = 1/"RPM" times 1/("avg # section/track") times (60 "sec")/(1 "min")
      $
- Disk Access Time 计算示例
  - Given:
    - Rotational rate = 7200 RPM
    - 平均 seek = 9 ms
    - 400 sectors / track
  - Derived:
    $
      T_"avg rotation" = 1/2 times 1/7200 times 60 times 1000 approx 4 "ms"\
      T_"avg transfer" = 1/7200 times 1/400 times 60 times 1000 approx 0.02 "ms"
    $
    $
      T_"access" = 9 + 4 + 0.02 approx 13.02 "ms"
    $
- Important points
  - Access time dominated by seek + rotation
    - 数据本身几乎不要时间
  - First bit is expensive, rest are free
    - 连续读非常划算
  - Disk vs Memory 速度鸿沟巨大
  #three-line-table[
    | 存储   | 延迟     |
    | ---- | ------ |
    | SRAM | $~$4 ns  |
    | DRAM | $~$60 ns |
    | Disk | $~$10 ms |
  ]
  比 SRAM 慢 40,000×，比 DRAM 慢 2,500×

=== I/O Bus

#figure(
  image("pic/memory.pdf", page: 11, width: 80%),
  numbering: none,
)
注：此为通用概念图，用于说明磁盘访问过程。实际机器中磁盘与CPU的连接方式存在差异。

三条总线 + 一个桥：
```
CPU
 ├─ System bus ── I/O bridge ── I/O bus ── Disk controller ── Disk
 └─ Memory bus ── Main memory
```
- System bus（系统总线）
  - CPU ↔ I/O bridge
  - 承载：地址，控制，少量数据
- Memory bus（内存总线）
  - I/O bridge ↔ Main memory
  - 高带宽、低延迟
  - 专门为 DRAM 优化
- I/O bus（I/O 总线）
  - 接慢设备
    - Disk controller
    - USB controller
    - Graphics adapter
  - 特点：共享，慢，可扩展（插槽）
- 关键思想：
  - CPU 不直接管这些慢设备
  - 而是通过 I/O bridge + controller
  - Disk controller 不是“哑设备”，本身是一个小计算机
    - 它负责：理解命令，调度磁盘，错误纠正，DMA 传输

*Reading a Disk Sector*

- CPU通过向与磁盘控制器关联的端口（地址）写入命令、逻辑块号和目标内存地址来启动磁盘读取操作
  - CPU 写的不是“数据”，而是控制信息：
    - command（读）
    - logical block number（逻辑块号）
    - destination memory address（内存地址）
  - 写到Disk controller 对应的端口（port / address）
  #figure(
    image("pic/memory.pdf", page: 12, width: 80%),
    numbering: none,
  )
  - 注意：
    - 这是一次 普通的 store 指令
    - 写的是 I/O 地址空间
    - 不是磁盘本身
    - 这一步非常快（ns 级）
- 磁盘控制器读取扇区并执行直接内存访问（DMA）传输至主内存
  - 磁盘控制器自己去操作磁盘
    - 寻道
    - 等旋转
    - 读扇区
  - 直接把数据写进主存
    - 不经过 CPU
    - 不占用寄存器
    - 不一字一字拷贝
  - 这就叫 DMA（Direct Memory Access）
  #figure(
    image("pic/memory.pdf", page: 13, width: 80%),
    numbering: none,
  )
  DMA 的本质：把“慢而多的数据搬运”从 CPU 手里拿走
- 当DMA传输完成时，磁盘控制器通过中断通知CPU（即拉低CPU上的特殊“中断”引脚）
  - Disk controller：拉高 CPU 的 interrupt pin
  - CPU：暂停当前执行，进入中断处理程序（ISR）
  #figure(
    image("pic/memory.pdf", page: 14, width: 80%),
    numbering: none,
  )
  CPU 下命令 → 控制器慢慢干活 → DMA 把数据放进内存 → 中断通知 CPU

*磁盘小结*
- 第一个字节最贵，其余几乎免费
  - 访问一个磁盘扇区中512个字节的时间主要是寻道时间和旋转延迟。访问扇区中的第一个字节用了很长时间，但是访问剩下的字节几乎不用时间。
  - 寻道 + 旋转 ≫ 传输
  - 一旦对齐：连续读几百字节 ≈ 不额外花时间
  - 顺序 I/O 极其重要
- SRAM / DRAM / Disk 的数量级对比
  - 对存储在SRAM中的双字（64bits）的访问时间大约是4ns，对DRAM的访问时间是60ns。因此， 从存储器中读一个512个字节（512*8 bits）扇区大小的块的时间对SRAM来说大约是256ns，对DRAM 来说大约是4000ns。
- 访问单字差距更恐怖
  - 磁盘访问时间，大约10ms，比SRAM大约大40000倍，比DRAM 大约大2500倍。如果我们比较访问一个单字的时间，这些访问时间的差别会更大。

#exercise[
  计算这样一个磁盘的容量，它有2个盘片，10000个柱面，每条磁道平均有400个扇区，而每个扇区有512个字节。(1G=$10^9$)。

  每个盘片有 2 个表面（surface）
  $
    "Capacity" = 2 times 2 times 10000 times 400 times 512 "bytes" = 8.192 times 10^9 "bytes" = 8.192 "GB"
  $
]

#exercise[
  已知参数
  #three-line-table[
    | 参数                     | 数值         |
    | ---------------------- | ---------- |
    | 转速                     | 15 000 RPM |
    | 平均寻道时间 ($T_"avg seek"$) | 8 ms       |
    | 平均扇区数/磁道               | 500        |
  ]
  则访问此磁盘上的一个扇区的访问时间为多少？
  $
    T_"access" = T_"avg seek" + T_"avg rotation" + T_"avg transfer"
  $
  平均旋转延迟
  $
    T_"avg rotation" = 1/2 times 1/15000 times 60 times 1000 = 2 "ms"
  $
  平均传输时间
  $
    T_"avg transfer" = 1/15000 times 1/500 times 60 times 1000 = 0.008 "ms"
  $
  总访问时间为
  $
    T_"access" = 8 + 2 + 0.008 = 10.008 "ms"
  $
]

=== Solid State Disks

*Nonvolatile Memories（非易失存储）*
- 易失 vs 非易失
  - SRAM / DRAM
    - 易失，断电 = 数据消失
  - Nonvolatile Memory
    - 断电 = 数据还在
- 常见非易失存储类型
  - ROM
    - 出厂写死
    - 固件（BIOS）
  - EEPROM
    - 可电擦除
    - byte 级
    - 慢、贵
  - Flash memory（最重要）
    - EEPROM 的一种
    - 只能 block 级擦除
    - 写入前必须先擦除
    - 有磨损寿命
  - 3D XPoint / 新型 NVM
    - Intel Optane（已停产，但概念重要）
    - 目标：接近 DRAM 的速度，保留非易失特性
- 非易失存储的典型用途
  - 固件（BIOS、控制器）
  - SSD
  - 磁盘缓存（disk cache）

*Solid State Disks (SSDs)*

#figure(
  image("pic/memory.pdf", page: 15, width: 80%),
  numbering: none,
)
- *Flash memory*（真正存数据的地方）
  - 不是 byte-addressable
  - 有 page 和 block 两级结构
- *Flash Translation Layer（FTL）*
  - SSD 的“灵魂”
  - 操作系统看到的逻辑块号
  - 映射到实际的 flash page / block
  - 相当于 SSD 内部的“文件系统 + wear leveling 管理员”
- *DRAM Buffer*（SSD 内部缓存）
  - 缓存映射表
  - 合并写请求
  - 提升随机写性能
- *I/O bus 接口*
  - 对 CPU 来说：SSD ≈ 一个“更快的磁盘”
  - 访问方式：仍然是 block I/O，DMA + interrupt

*SSD 的基本物理组织*
- Page & Block
  - Page：4KB（也有更大）
  - Block：32–128 pages → 一个 block ≈ 128–512 KB
- 三条“反直觉”的规则
  - 规则 1：读/写单位是 page，不能只写一个 byte
  - 规则 2：写 page 前必须先擦 block，不能原地覆盖
  - 规则 3：block 有寿命，大约 10,000 次写
  - 这三条，决定了 SSD 随机写很麻烦

*SSD Performance Characteristics*
- Sequential read/write >> Random single-thread
- DQ（Deep Queue）同时发很多 I/O 请求
  - SSD 内部可以并行：多 channel，多 flash die
  - 当队列够深：吞吐量暴涨，隐藏单次访问延迟
  - 操作系统 & NVMe 的关键优化点
- 随机写仍然麻烦
  - 擦除 block ≈ 1 ms
  - 修改一个 page：要把整个 block 复制到新 block
  - 解决方案：
    - 预擦除 block 池
    - DRAM write cache
    - 延迟合并写入
  - 全靠 FTL + DRAM buffer

*SSD vs 旋转磁盘*
- SSD 优势
  - 没有机械部件
  - 快
  - 低功耗
  - 抗震
- SSD 劣势
  - 会磨损
  - 单位容量更贵
  - 需要复杂控制逻辑
  - 约 1.67× 磁盘价格 / 字节（1TB 级）
- Wear leveling（磨损均衡）
  - FTL 自动迁移数据
  - 防止某些 block 被写爆
  - 对程序员完全透明
- 磁盘还在哪用？
  - 大规模冷数据
  - 视频
  - 超大数据库
  - 成本敏感场景

*Summary*
- 速度鸿沟继续扩大
  - CPU ≫ DRAM ≫ SSD ≫ HDD
- 好程序 = 有 locality
  - 时间局部性
  - 空间局部性
- Memory Hierarchy 的本质
  - 用 cache + 分层结构，“又快又大”
- Flash 进步最快
  - 3D 堆叠
  - 密度持续提升
  - 正在吞噬磁盘市场

*Enhanced DRAMs（增强型 DRAM）*
- DRAM 核心没变
  - 1T + 1C
  - 自 1970 年 Intel 商业化以来
  - 基本原理没变
- 提升靠的是“接口”
  - SDRAM
    - 同步时钟
    - 替代早期异步 DRAM
  - DDR SDRAM（你必须认识）
    - *双沿传输*
    - 一个周期传两次数据
    #three-line-table[
      | 类型   | Prefetch |
      | ---- | -------- |
      | DDR  | 2 bits   |
      | DDR2 | 4 bits   |
      | DDR3 | 8 bits   |
      | DDR4 | 16 bits  |
      | DDR5 | 更大       |
    ]

== Locality of reference

*The CPU-Memory Gap*
- CPU 变快的速度 > DRAM > SSD > Disk
- 到 2015 年左右：
  - CPU：< 1 ns
  - DRAM：几十 ns
  - SSD：$~$100 µs
  - Disk：$~$ms
- CPU 每跑一步，都可能要等内存几百到几万步，这就是 CPU–Memory Gap。
- *Locality to the Rescue（局部性来救场）*
  - Locality 是弥合 CPU–Memory Gap 的关键
  - 不是靠“更快的内存”，而是靠程序行为的统计规律

*Principle of Locality（局部性原理）*
- 程序倾向于反复访问“最近用过的、附近的”数据和指令
- Temporal Locality（时间局部性）
  - 刚用过的，很快还会再用
  - 例子：
    - 循环变量
    - 累加变量 `sum`
    - 指令循环执行
- Spatial Locality（空间局部性）
  - 用到一个地址，很可能马上用到附近地址
  - 例子：
    - 顺序访问数组
    - 顺序执行指令

*Locality 的最经典例子*
```c
sum = 0;
for (i = 0; i < n; i++)
    sum += a[i];
return sum;
```
#three-line-table[
  | 引用对象   | 属于哪种局部性                    |
  | ------ | -------------------------- |
  | `sum`  | *Temporal*（每次循环都用）       |
  | `a[i]` | *Spatial*（stride-1 顺序访问） |
  | 循环指令   | *Temporal + Spatial*     |
]
- 这段代码局部性极好
- Cache、DRAM 行缓冲、SSD 顺序读

*Qualitative Estimates of Locality*
- 能“看代码判断局部性”，是专业程序员的核心能力
- 行优先（Row-major），在 C 里：
  ```c
  int a[M][N];
  ```
  内存布局是：
  ```
  a[0][0], a[0][1], ..., a[0][N-1],
  a[1][0], a[1][1], ..., a[1][N-1],
  ...
  ```
- *二维数组：好 vs 坏的对比*
  - 行优先遍历（好局部性）
    ```c
    int sum_array_rows(int a[M][N]) {
        int i, j, sum = 0;
        for (i = 0; i < M; i++)
            for (j = 0; j < N; j++)
                sum += a[i][j];
        return sum;
    }
    ```
    内层 j 变化，地址连续，`stride = 1`，强空间局部性
    - Cache 命中率高
    - DRAM 行缓冲命中
    - SSD 顺序读友好
  - 列优先遍历（差局部性）
    ```c
    int sum_array_cols(int a[M][N]) {
        int i, j, sum = 0;
        for (j = 0; j < N; j++)
            for (i = 0; i < M; i++)
                sum += a[i][j];
        return sum;
    }
    ```
    内层 i 变化，每次跳 N 个元素，`stride = N`，空间局部性差
    - 如果 M 很小，会不会好？为什么？
      - 如果 M 小到一行能装进 一个 cache block
      - 那仍然可能命中 cache
      - 局部性是“相对于 cache 大小”的
- *三维数组：能不能“换循环顺序救回来”*
  - 原始代码（差局部性）
    ```c
    int sum_array_3d(int a[M][N][N]) {
        int i, j, k, sum = 0;
        for (i = 0; i < N; i++)
            for (j = 0; j < N; j++)
                for (k = 0; k < M; k++)
                    sum += a[k][i][j];
        return sum;
    }
    ```
    - C 是行优先
    - k 在最里层，但 k 对应的是 最高维
    - 地址跳得最远
  - 让 j 成为最内层循环
    ```c
    for (k = 0; k < M; k++)
        for (i = 0; i < N; i++)
            for (j = 0; j < N; j++)
                sum += a[k][i][j];

    ```
*把 Locality 和整个 Memory Hierarchy 串起来*
- #three-line-table[
    | 层级    | 喜欢什么         |
    | ----- | ------------ |
    | Cache | 时间 + 空间局部性   |
    | DRAM  | 行缓冲（同一行多次访问） |
    | SSD   | 顺序读、深队列      |
    | Disk  | 连续扇区         |
  ]


#exercise[
  ```c
  typedef struct {
      int vel[3];
      int acc[3];
  } point;

  point p[N];
  ```
  clear1 vs clear2
  ```c
  void clear1(point *p, int n) {
      int i, j;
      for (i = 0; i < n; i++) {
          for (j = 0; j < 3; j++)
              p[i].vel[j] = 0;
          for (j = 0; j < 3; j++)
              p[i].acc[j] = 0;
      }
  }
  void clear2(point *p, int n) {
      int i, j;
      for (i = 0; i < n; i++) {
          for (j = 0; j < 3; j++) {
              p[i].vel[j] = 0;
              p[i].acc[j] = 0;
          }
      }
  }
  void clear3(point *p, int n) {
      int i, j;
      for (j = 0; j < 3; j++) {
          for (i = 0; i < n; i++)
              p[i].vel[j] = 0;
          for (i = 0; i < n; i++)
              p[i].acc[j] = 0;
      }
  }
  ```
  哪个版本的局部性更好？为什么？

  事实上在内存中
  ```
  p[0].vel[0], p[0].vel[1], p[0].vel[2],
  p[0].acc[0], p[0].acc[1], p[0].acc[2],
  p[1].vel[0], p[1].vel[1], p[1].vel[2],
  p[1].acc[0], p[1].acc[1], p[1].acc[2],
  ...
  ```
  同一个 `p[i]` 的 `vel` 和 `acc` 是连续存放的。

  局部性：clear1 > clear2 > clear3
]

== The memory hierarchy

=== The memory hierarchy

*Memory Hierarchy（存储层次结构）*
- 硬件和软件的一些基本且持久的特性：
  - 快速存储技术每字节成本更高，容量更小，且需要更多电力（发热量更大！）
  - CPU与主内存速度之间的差距正在扩大
  - 编写良好的程序往往具有良好的局部性
- 这些特性在许多类型的程序中能很好地相互补充
- 提出了一种组织存储器和存储系统的方案，称为存储器分层结构

#figure(
  image("pic/memory.pdf", page: 16, width: 80%),
  numbering: none,
)

#figure(
  three-line-table[
    | 层级 | 名称                 | 事实   |
    | -- | ------------------ | ---------- |
    | L0 | Registers          | 极快、极小、最贵   |
    | L1 | L1 cache (SRAM)    | 几 ns，容量 KB |
    | L2 | L2 cache (SRAM)    | 稍慢，容量 MB   |
    | L3 | L3 cache (SRAM)    | 更慢，容量更大    |
    | L4 | Main memory (DRAM) | ~60ns，GB 级 |
    | L5 | Local disks / SSD  | µs–ms，TB 级 |
    | L6 | Remote storage     | 网络级，最慢     |
  ],
  numbering: none,
)
- 越往上：更小，更快，更贵（每字节），功耗更高
- 越往下：更大，更慢，更便宜，更“远”
- 每一层“缓存”下一层
  - 每一层都缓存（cache）它下面那一层的数据
  - 这就是为什么 cache 不是 CPU 独有的概念
- 程序只在小范围内频繁活动
  - 只把“热数据”放在快的地方
  - “冷数据”放在慢但便宜的地方
  - 不用让整个内存都快

*在多维度中寻找平衡*
- 寄存器访问速度最快，但存储容量最小，且价格最贵。
- 高速缓存（ cache memory）访问速度较快，容量稍大，价格较贵。
- 主存储器（main memory）访问速度一般，容量一般，价格也一般。
- 磁盘访问容量最大，价格也便宜，但是速度慢。

=== Caches

*Cache*
- Cache: A smaller, faster storage device that acts as a staging area for a subset of the data in a larger, slower device.
  - Cache 是一个更小、更快的存储，用来缓存更大、更慢存储的一部分数据
- “按块”而不是“按字节”
  - 内存被划分为 blocks
  - cache 里存的是 cache lines（= blocks）
  - 一次 miss → 整个 block 被拷贝进 cache
  - 空间局部性
- Fundamental Idea：层层缓存
  - For each level k, level k caches level k+1
  - Cache 是一个“递归概念”
    - CPU cache 只是最靠近 CPU 的那一层
- 为什么 Cache 一定“能工作”
  - Locality
  - 程序更常访问 level k 的数据，而不是 level k+1
  - 程序的 working set 很小，热数据反复被访问，Cache 只要装下 working set → 命中率就高
- Big Idea（理想状态）
  - 用便宜的大存储的成本，提供接近昂贵快存储的速度
  - 价格像磁盘，速度像 cache

*General Cache Concepts（通用缓存概念）*

#figure(
  image("pic/memory.pdf", page: 17, width: 80%),
  numbering: none,
)

#figure(
  image("pic/memory.pdf", page: 18, width: 80%),
  numbering: none,
)

- Hit（命中）
  - 请求的 block 已经在 cache
  - 直接返回
  - 延迟 = cache latency（几个 cycle）
- 发生 miss 时，系统要做三件事：
  - Fetch：从下一级取 block
  - Placement：放到 cache 的哪个位置？
  - Replacement：要不要踢掉一个旧 block？
  - miss 的代价 = miss penalty

*3 种 Cache Miss*
- *Cold Miss（Compulsory Miss）*
  - 冷缺失发生是因为缓存初始为空，且这是对该块的首次引用
  - 第一次访问某个 block，一定 miss
    - cache 一开始是空的
    - 无法避免
    - 但只发生一次
  - 优化手段：
    - 预取（prefetch）
    - 大 block
- *Capacity Miss（容量未命中）*
  - 当活动缓存块集（工作集）大于缓存时发生
  - working set > cache 容量
    - cache 装不下当前活跃数据
    - 即使映射不冲突也会 miss
  - 解决办法：
    - 更大的 cache
    - 更好的算法（减小 working set）
- *Conflict Miss（冲突未命中）*
  - cache 够大，但映射限制导致冲突
  - 大多数缓存将k+1层的区块限制为k层区块位置的一个小子集（有时为单元素集合）
  - 当级别k的缓存足够大时，若多个数据对象均映射到同一个级别k的块，则会发生冲突遗漏
    - 第k+1层的第i块必须放置在第k层的第(i mod 4)块位置
    - 引用块 0, 8, 0, 8, 0, 8, ... 每次都会失败

*Examples of Caching：Cache 无处不在*
- “Cache”不是 CPU 专属，而是一种普遍的系统设计模式
  #three-line-table[
    | Cache 类型      | 缓存什么 | 谁管理 |
    | ------------- | ---- | --- |
    | Registers     | 变量   | 编译器 |
    | TLB           | 地址翻译 | 硬件  |
    | L1/L2/L3      | 内存块  | 硬件  |
    | Page cache    | 磁盘页  | OS  |
    | Disk cache    | 扇区   | 固件  |
    | Browser cache | 网页   | 浏览器 |
  ]

*Storage Trends & CPU Clock Rates（为什么 Cache 越来越重要）*
- 存储趋势
  - DRAM：变便宜、容量暴涨、速度提升慢
  - Disk：容量暴涨、延迟几乎不变
  - SRAM：快，但贵、受限
- CPU Clock Rates 的“拐点”
  - 2004 年前：频率暴涨 Power Wall
  - 2004 年后：频率停滞
    - 单核频率不再暴涨
    - 转向：
      - 多核
      - cache 更复杂
      - 并行
    - Cache 成为 CPU 性能的生命线

*总结*
- 实际上，存储器系统（memory system）是一个具有不同容量、成本和访问时间的存储设备的层次结构
  - CPU寄存器保存着最常用的数据
  - 靠近CPU的小的、快速的高速缓存存储器 (cache memory）作为一部分存储在相对慢速的主存储器（main memory，简称主存）中的数据和 指令的缓冲区域
  - 主存暂时存放存储在容量较大的、慢速磁盘上的数据
  - 而这些磁盘常常又作为存储在通过网络连接的其他机器的磁盘或磁带上的数据的缓冲区域
- 作为一个程序员，你需要理解存储器层次结构，因为它对应用程序的性能有着巨大的影响

= Cache Memories

== Cache memory organization and operation

== Performance impact of caches
=== The memory mountain
=== Rearranging loops to improve spatial locality
=== Using blocking to improve temporal locality
