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

#pagebreak()

= Cache Memories

== Cache memory organization and operation

=== CPU caches

*CPU Cache Memories*
- CPU缓存存储器是基于SRAM的小型高速存储器，由硬件自动管理
  ```
  Register file ↔ Cache ↔ Bus interface ↔ Memory
  ```
  保留主内存中频繁访问的块
- CPU首先在缓存中查找数据
  #figure(
    image("pic/cache.pdf", page: 1, width: 80%),
    numbering: none,
  )
- 在芯片中
  - Cache 占据了大量芯片面积
    - 尤其是共享 L3 cache
  - 每个 core 有私有 L1 / L2
  - L3 通常是多核共享的
  - 在现代 CPU 中，cache 占用空间比算数逻辑单元还大

*Working Set, Locality, and Caches*
- Cache Memories：它们“自动工作”
  - CPU cache memories are small, fast SRAM-based memories managed automatically in hardware
    - SRAM
    - 自动（hardware-managed）
    - 程序员不能显式 load/store cache
  - CPU 访问数据的顺序
    - 每次 load / store：先查 L1 cache，L1 miss → 查 L2，L2 miss → 查 L3，L3 miss → 访问 DRAM，DRAM miss → OS / disk
    - 程序员写一条 `mov`，背后可能是 4–5 层查找
- Working Set：把 Locality“量化”
  - Working Set = 程序当前阶段正在频繁访问的数据 + 指令的集合
  - “当前”是时间窗口相关的
  - 包含：数据，指令（指令 cache）
  - 一个直观例子
    ```c
    for (i = 0; i < n; i++)
      sum += a[i];
    ```
    - Working set 包含：
      - `sum`
      - `i`
      - `a[i] `所在的若干 cache blocks
      - `loop` 的指令
  - 如果这些都能装进 cache，之后几乎全是 hit
- Locality ⇄ Working Set ⇄ Cache（三者关系）
  - Locality → Working Set 小
    - 时间局部性：反复用同一批数据
    - 空间局部性：一次带进一整块
  - Working Set 小 → Cache 命中率高
    - cache 装得下
    - 不被频繁驱逐
  - Cache 命中率高 → 程序快
    - 这就是 cache 能“救性能”的完整逻辑闭环
- Cache 是如何利用 Locality 的？
  - 利用时间局部性
    - 保存最近访问的 block
    - 下次访问同一地址 → hit
  - 利用空间局部性
    - 按 block（cache line）搬运
    - 不是只搬 1 个 word

*3 种 Cache Miss*
- Cold Miss（冷启动）
  - cache 还没被“热身”，不可避免
- Capacity Miss（容量不够）
  - Working set > cache
  - 即使映射完美也会 miss
  - 算法层面的性能瓶颈
- Conflict Miss（映射冲突）
  - cache 逻辑上够大
  - 但映射规则太死
  - 数据互相踢掉
  - cache 组织方式的问题

=== General Cache Organization (S, E, B)

==== Cache read

*通用 Cache 组织模型：S, E, B*
- Cache 的三大参数
  - S —— set 的数量
    - S = 2ˢ
    - 每个 set 是一个“小桶”
  - E —— 每个 set 里有多少行（line）
    - E = 2ᵉ
      - E=1 → Direct-mapped
      - E>1 → Set-associative
      - E→∞ → Fully associative
  - B —— 每个 cache block 的大小
    - B = 2ᵇ bytes
    - 一次 miss 搬进来的最小单位
- Cache 的总容量
  - Cache size = S × E × B（只算 data，不算 tag / valid）
- 每一条 cache line
  ```
  | valid | tag | byte 0 | byte 1 | ... | byte B-1 |
  ```
  - valid bit：这行是不是有效
  - tag：高位地址，用来区分“是不是我要的块”
  - data：真正的数据（B 字节）

#figure(
  image("pic/cache.pdf", page: 2, width: 80%),
  numbering: none,
)

*Cache Read*
- Step 1：地址拆分
  ```
  | tag (t bits) | set index (s bits) | block offset (b bits) |
  ```
  - set index：决定去哪个 set
  - tag：决定是不是我要的 block
  - offset：在 block 里的哪个字节
- Step 2：定位 set
  - 用 set index 选中 唯一一个 set
- Step 3：并行比较 tag
  - 在这个 set 的 E 条 line 中：
    - tag 匹配？
    - valid = 1？
  - 有任意一条满足 → hit，都不满足 → miss
- Step 4：命中后定位数据
  - 用 block offset
  - 找到目标 byte / int / word

*Direct-Mapped Cache（E = 1）*
- 最简单、最暴力、也最容易产生 conflict miss 的 cache
#figure(
  image("pic/cache.pdf", page: 3, width: 80%),
  numbering: none,
)
- Direct-mapped 的规则
  - 每个 set 只有 1 条 line
  - 一个内存 block：只能映射到一个固定 set
  - miss 时：直接把原来的 block 踢掉（evict）
- 地址映射
  - set index = (block number) mod S
- Direct-Mapped Cache 仿真
  - 已知条件
    - 地址空间：4-bit → 16 bytes
    - S = 4 sets → s = 2
    - E = 1（direct-mapped）
    - B = 2 bytes → b = 1
  - 地址格式：
    ```
    | tag (1 bit) | set index (2 bits) | block offset (1 bit) |
    ```
  #figure(
    image("pic/cache.pdf", page: 4, width: 80%),
    numbering: none,
  )
  - 访问序列（一次读 1 byte）
    ```
    0, 1, 7, 8, 0
    ```
    - 访问 0 → [0000]₂
      - block number = 0 / 2 = 0
      - set = 0 mod 4 = 0
      - cache 为空 → *cold miss*
      - 把 M[0–1] 放入 set 0
    - 访问 1 → [0001]₂
      - block 仍然是 0
      - set = 0
      - tag 匹配 + valid = 1
      - *hit*
    - 访问 7 → [0111]₂
      - block = 7 / 2 = 3
      - set = 3 mod 4 = 3
      - 空 → *cold miss*
      - 放入 M[6–7]
    - 访问 8 → [1000]₂
      - block = 8 / 2 = 4
      - set = 4 mod 4 = 0
      - set 0 里已有 M[0–1]
      - tag 不同 → *cold miss*
      - 直接覆盖 set 0 的 M[0–1] 为 M[8–9]
    - 再访问 0 → [0000]₂
      - block = 0
      - set = 0
      - 但 set 0 现在是 M[8–9]
      - *conflict miss*

*E-way Set Associative Cache (E = 2)*

#figure(
  image("pic/cache.pdf", page: 5, width: 80%),
  numbering: none,
)
- 地址拆分（完全不变）
  ```
  | tag (t bits) | set index (s bits) | block offset (b bits) |
  ```
- 访问流程
  - 用 set index 定位 set
  - 并行比较 set 内所有 E 条 line 的 tag
  - 只要有一条：valid=1 且 tag 匹配 → hit
    - 对比 Direct-Mapped：
      - E=1：只能比 1 条
      - E=2：可以比 2 条（并行）
  - 用 block offset 定位数据
- Miss 时：Replacement Policy
  - No match or not valid ⇒ miss
  - 常见替换策略
    - Random：随机踢一个
    - LRU（Least Recently Used）：踢“最久没用的”
    - FIFO：最早进来的先走
    - E>1 给了选择空间，从而减少冲突 miss
- 2-Way Set Associative Cache 仿真
  #figure(
    image("pic/cache.pdf", page: 6, width: 80%),
    numbering: none,
  )
  - 已知条件
    - 地址空间：4-bit → 16 bytes
    - S = 2 sets → s = 1
    - E = 2
    - B = 2 bytes → b = 1
  - 地址格式：
    ```
    | tag (2 bits) | set index (1 bit) | block offset (1 bit) |
    ```
  - 访问序列（一次读 1 byte）
    ```
    0, 1, 7, 8, 0
    ```
    - 访问 0 → [0000]₂
      - set = 0
      - cache 空 → *cold miss*
      - 把 M[0–1] 放入 set 0，line 0
    - 访问 1 → [0001]₂
      - set = 0
      - tag 匹配 + valid = 1 → *hit*
    - 访问 7 → [0111]₂
      - set = 1
      - 空 → *cold miss*
      - 放入 M[6–7]，set 1，line 0
    - 访问 8 → [1000]₂
      - set = 0
      - set 0 有 M[0–1]（tag=00）
      - tag 不同 → *cold miss*，但不需要驱逐
      - line 1 空 → 放入 M[8–9]
    - 再访问 0 → [0000]₂
      - block = 0
      - set = 0
      - set 0 有 M[0–1]（tag=00）和 M[8–9]（tag=10）
      - tag 匹配 → *hit*

==== Cache write

*Cache 的写问题*
- 因为同一份数据可能同时存在于多个地方
  - L1 cache
  - L2 cache
  - L3 cache
  - Main memory
  - Disk（更底层）
- 一旦 CPU 写了一个地址，必须回答：“哪些副本要更新？什么时候更新？”
*写命中（write hit）的两种策略*
- Write-through（直写）
  - 每次写 cache，同时立刻写主存
  - 优点
    - 实现简单
    - 主存永远是最新的
  - 缺点
    - 每次写都会触发一次慢速内存写
    - 写流量巨大
    - 常见搭配：no-write-allocate
- Write-back（回写）
  - 只写 cache，不立刻写主存
  - cache line 上新增一个 dirty bit，表示：
    - “这行数据已经被修改过，和内存不一致”
    - Dirty Bit
      - dirty = 0：cache 和 memory 一致
      - dirty = 1：cache 更新过，memory 旧了
  - 只有在：cache line 被 evict（替换）
  - 才会：整块（B 字节）写回内存
*写未命中（write miss）的两种策略*
- Write-allocate（写分配）
  - 先把 block 读进 cache，再写
    - 行为像一次 read miss + write hit
    - 利用 时间 / 空间局部性
    - 适合：之后还会多次写这个位置
- No-write-allocate（不写分配）
  - 直接写内存，不加载进 cache
  - cache 完全不参与
  - 常见于：write-through cache
- 实际系统的经典组合
  #three-line-table[
    | 写命中            | 写未命中               | 说明       |
    | -------------- | ------------------ | -------- |
    | Write-through  | No-write-allocate  | 简单，但慢    |
    | *Write-back* | *Write-allocate* | 主流，高性能 |
  ]
  #figure(
    image("pic/cache.pdf", page: 7, width: 80%),
    numbering: none,
  )

*Write-back + Write-allocate 的完整流程*
- 情况 1：写命中
  - 更新 cache block
  - 设置 dirty = 1
  - 不写内存
- 情况 2：写未命中
  - 从内存 fetch block
  - 写 cache
  - 设置 dirty = 1
- 情况 3：替换一个 dirty line
  - 将整个 block（B 字节）写回内存
  - 清除 dirty bit
  - 替换新 block

*为什么“用中间位做索引”？*
解释为什么 cache 的地址格式是：
```
| tag | set index | block offset |
```
#figure(
  image("pic/cache.pdf", page: 8, width: 80%),
  numbering: none,
)
- Middle Bits Indexing
  - 地址格式：TTSSBB
    - TT：tag bits
    - SS：set index bits
    - BB：block offset bits
  - 适配空间局部性：连续地址
    - offset 先变
    - 再变 set
    - 数据会 均匀分布到不同 sets
    - 顺序访问数组 → 冲突最少
- High Bits Indexing
  - 地址格式：SSTTBB
  - 高位决定 set
  - 连续地址：
    - 高位不变
    - 全部打到同一个 set
  - 程序空间局部性越好，冲突越严重
- 一个具体例子（PPT 的 64-byte memory）
  - 地址：6 bits
  - Cache：16 bytes
  - Block size：4 bytes → 4 sets
#figure(
  image("pic/cache.pdf", page: 9, width: 80%),
  numbering: none,
)

*Intel Core i7 Cache Hierarchy*
#figure(
  image("pic/cache.pdf", page: 10, width: 80%),
  numbering: none,
)
典型配置
#three-line-table[
  | Cache      | 容量     | 相联度    | 延迟               |
  | ---------- | ------ | ------ | ---------------- |
  | L1 i/d     | 32 KB  | 8-way  | $~$4 cycles        |
  | L2         | 256 KB | 8-way  | $~$10 cycles       |
  | L3         | 8 MB   | 16-way | 40–75 cycles     |
  | Block size |   \     |    \    | *64 bytes（统一）* |
]

#exercise[
  一缓存系统属性如下表所示，则对于12位地址的含义（从左侧开始），说法正确的是：
  #three-line-table[
    | 参数 | 值 |
    | -- | -- |
    | 寻址单位 | 字节 |
    | 地址宽度 | 12位 |
    | E | 2 (两路组相联） |
    | B | 4字节（块大小） |
    | S | 4（组数） |
  ]
  8位标记， 2位组索引， 2位块偏移
]

== Performance impact of caches

*Cache Performance Metrics*（三大性能指标）
- Miss Rate（未命中率）——最重要的指标
  - Miss rate = misses / accesses = 1 − hit rate
  - 典型数量级（经验值）：
    - L1 cache：3% – 10%
    - L2 cache：可以 < 1%（取决于大小、程序）
  - Miss rate 看起来很小，但影响巨大
- Hit Time（命中时间）
  - CPU 从 cache 中拿到数据所需时间
  - 包括：
    - 定位 set
    - tag 比较
    - 读出数据
  - 典型值：
    - L1：≈ 4 cycles
    - L2：≈ 10 cycles
  - Hit time 是 cache 越复杂越容易变大的代价
- Miss Penalty（未命中代价）
  - 因为 miss，多付出的额外时间
  - 通常包括：
    - 从下一级 cache / DRAM 取 block
    - 可能的写回（dirty line）
  - 典型值：
    - 主存：50–200 cycles
    - 而且趋势是：越来越大
  - 这是 cache 存在的根本原因

*关键直觉：Hit 和 Miss 的代价完全不对称*
- Could be 100x, if just L1 and main memory
- 假设：
  - Hit time = 1 cycle
  - Miss penalty = 100 cycles
  - 情况 A：97% hit
    ```
    AMAT = 1 + 0.03 × 100 = 4 cycles
    ```
  - 情况 B：99% hit
    ```
    AMAT = 1 + 0.01 × 100 = 2 cycles
    ```
  - 命中率只提高 2%，平均访问时间直接减半
- 在 cache 世界里，miss 是“灾难性事件”
  - 1 次 miss ≈ 几十甚至上百次 hit

*Average Memory Access Time*
$
  "AMAT" = "Hit Time" + "Miss Rate" × "Miss Penalty"
$
#newpara()
*Writing Cache-Friendly Code*
- Make the common case go fast（第一原则）
  - 让最常发生的情况跑得最快
    - 不要优化冷路径
    - 盯紧 inner loop
    - 90% 的时间花在 10% 的代码里
- 内层循环 = cache 性能的生死线
  - Minimize the misses in the inner loops
  - 内层循环访问次数最多
  - 一个 miss 会被放大成巨大的总开销

*程序层面的 cache 友好模式*
- 时间局部性（Temporal Locality）
  - 反复使用同一个变量
  - 把常用变量留在寄存器 / cache
  ```c
  for (...) {
      sum += a[i];
  }
  ```
- 空间局部性（Spatial Locality）
  - Stride-1 访问模式
- 常见 cache 杀手
  - 大 stride
  - 随机访问
  - 列优先访问行主序数组
  - 在内层循环里访问大结构体的不同字段
*Our qualitative notion of locality is quantified through our understanding of cache memories.*

=== The memory mountain

*Performance impact of caches*
- cache 命中/未命中差距巨大
- 步长（stride） 决定空间局部性
- 工作集大小（working set size） 决定是否能装进某一层 cache
- Memory Mountain 就是把这些因素一次性、可视化地量出来

*Memory Mountain*
- Read throughput (read bandwidth)
  - 每秒从内存读取的字节数（MB/s）
  - 读吞吐量（MB/s）作为工作集大小（size），访问步长（stride）的函数
- 内存山：Measured read throughput as a function of spatial and temporal locality.
  - 表征内存系统性能的紧凑方法

*Memory Mountain Test Function*
```c
long data[MAXELEMS]; /* Global array to traverse */
/* test - Iterate over first "elems" elements of
 * array "data" with stride of "stride“,
 * using 4x4 loop unrolling.
 */
int test(int elems, int stride) {
long i, sx2=stride*2, sx3=stride*3, sx4=stride*4;
long acc0 = 0, acc1 = 0, acc2 = 0, acc3 = 0;
long length = elems, limit = length - sx4;
/* Combine 4 elements at a time */
for (i = 0; i < limit; i += sx4) {
  acc0 = acc0 + data[i];
  acc1 = acc1 + data[i+stride];
  acc2 = acc2 + data[i+sx2];
  acc3 = acc3 + data[i+sx3];
}
/* Finish any remaining elements */
for (; i < length; i++) {
  acc0 = acc0 + data[i];
}
  return ((acc0 + acc1) + (acc2 + acc3));
}
```
- 本质
  - 在一个大数组 data[] 上用固定 stride 访问 elems 个元素
  - 只做“读 + 累加”（几乎不做计算）
  - 这是一个纯内存性能测试
- 4×4 循环展开
  - 减少 loop overhead
  - 提高 ILP(Instruction Level Parallelism)
  - 确保瓶颈在内存系统，而不是 CPU
- 先跑一遍 warm up，再计时第二遍，避免把冷启动 miss 混进结果

#figure(
  image("pic/2025-12-29-17-28-53.png", width: 80%),
  numbering: none,
)
*存储器山*
- 关于存储器山的几点观察
  - 有 4 条明显的 ridge
    - 垂直于size轴的是四条山脊，分别对应于工作集完全在L1高速缓存、L2高速缓存、L3高速缓存和主存内的*时间局部性*区域
    - 注意， L1山脊的最高点（6GB/s)与主存山脊的最低点（600MB/s）之间的差别有一个数量级
  - 沿 stride 方向的“下坡”（空间局部性）
    - 在 L2 / L3 / DRAM 区域：
      - stride 越大
      - 吞吐量越低
      - miss rate ≈ stride / 每块元素数
    - 在L2, L3和主存山脊上随着步长的增加有一个*空间局部性*的斜坡，空间局部性下降。
    - 注意，即使是当工作集太大，不能全都装进任何一个高速缓存时，主存山脊的最高点也比它的最低点高 7倍
  - 最“神奇”的现象：步长 1$~$2 的平坦山脊
    - stride = 1 或 2
    - 即使 size 已经进 DRAM
    - 吞吐量仍然维持在 ≈ 4.5 GB/s
    - 硬件预取（prefetching）
    - 有一条特别有趣的平坦的山脊线，对于步长1和2垂直于步长轴，此时读吞吐量相对保持不变，为4.5 GB/s。
    - 这显然是由于Core i7存储器系统中的硬件预取（prefetching）机制，它会自动地确认存储器引用模式，试图在一些块被访问之前，将他们取到高速缓存中。
    - Prefetching：硬件在猜
      - 现代 CPU 会：
        - 识别规则的访问模式
        - 在真正访问之前
        - 把后续 cache line 提前拉进 cache
      - 结果：看起来像是“从 cache 里读”，实际上是 CPU 隐藏了内存延迟
      - 只对 规则、线性访问 有效，stride 太大、模式太乱 → 预取失效
- 存储器山总结
  - 存储器系统的性能不是一个数字就能描述的。
  - 相反，它是一座时间和空间局部性的山，这座山的上升高度差别可以超过一个数量级。
  - 明智的程序员会试图构造他们的程序，使得程序运行在山峰而不是低谷。
  - 目标就是利用时间局部性，使得频繁使用的字从L1中取出，还要利用空间局部性，使得尽可能多的字从一个L1高速缓存行中访问到。

=== Rearranging loops to improve spatial locality

换一下三重循环的顺序，性能能差 10～20 倍；算力是一样的，访存模式完全不同，而缓存 + 预取机制放大了这种差异。

*几个前提*
- 数据布局（C 语言）
  - 行主序（row-major）
  - `a[i][j]` 在内存中等价于 `a[i*N + j]`
  - 一整行是连续的，一整列是跳着的
- Cache 参数（用于分析）
  - double = 8B
  - cache block = 32B ⇒ 一个 cache line = 4 个 double
  - N 很大 ⇒ 行、列都放不进 cache
  - 忽略 1/N 这种小量（≈0）
- stepping through columns in one row:
  ```c
  for (i = 0; i < N; i++)
    sum += a[0][i];
  ```
  - accesses successive elements
  - if `block size (B) > sizeof(aij)` bytes, exploit spatial locality
  - miss rate = `sizeof(aij)` / B
- Stepping through rows in one column:
  ```c
  for (i = 0; i < n; i++)
    sum += a[i][0];
  ```
  - accesses distant elements: no spatial locality!
  - miss rate = 1 (i.e. 100%)

*Matrix Multiplication Example*
- 核心方法：只看最内层循环
- Cache 行为 99% 由 inner loop 决定
- *ijk：经典写法，但 cache 很糟*
  ```c
  for (i=0; i<n; i++) {
    for (j=0; j<n; j++) {
      sum = 0.0;
      for (k=0; k<n; k++)
        sum += a[i][k] * b[k][j];
      c[i][j] = sum;
    }
  }
  ```
  inner loop（k）中的访问模式
  #three-line-table[
    | 矩阵 | 访问方式          | 局部性        | Miss rate      |
    | -- | ------------- | ---------- | -------------- |
    | A  | `a[i][k]` 行访问 | ✅ stride-1 | 1/4 = *0.25* |
    | B  | `b[k][j]` 列访问 | ❌          | *1.0*        |
    | C  | `c[i][j]` 固定  | ✅          | *0.0*        |
  ]
  2 loads, 0 stores, avg misses/iter = 1.25
- *kij：性能最好的版本*
  ```c
  for (k=0; k<n; k++) {
    for (i=0; i<n; i++) {
      r = a[i][k];
      for (j=0; j<n; j++)
        c[i][j] += r * b[k][j];
  }
  ```
  把 `a[i][k]` 提前读出来，`r` 放在 寄存器，inner loop 不再访问 A

  inner loop（j）中的访问模式
  #three-line-table[
    | 矩阵 | 访问方式          | 局部性 | Miss rate |
    | -- | ------------- | --- | --------- |
    | A  | fixed（寄存器）    | ✅   | *0.0*   |
    | B  | `b[k][j]` 行访问 | ✅   | *0.25*  |
    | C  | `c[i][j]` 行访问 | ✅   | *0.25*  |
  ]
  2 loads + 1 store, avg misses/iter = 0.5
- *jki：cache 灾难现场*
  ```c
  for (j=0; j<n; j++) {
    for (k=0; k<n; k++) {
      r = b[k][j];
      for (i=0; i<n; i++)
        c[i][j] += a[i][k] * r;
    }
  }
  ```
  inner loop（i）中的访问模式
  #three-line-table[
    | 矩阵 | 访问方式          | 局部性 | Miss rate |
    | -- | ------------- | --- | --------- |
    | A  | `a[i][k]` 列访问 | ❌   | *1.0*   |
    | B  | fixed         | ✅   | *0.0*   |
    | C  | `c[i][j]` 列访问 | ❌   | *1.0*   |
    |
  ]
  2 load + 1 store, avg misses/iter = 2.0
- 性能差距能到 20 倍
  - miss penalty 极大
    - L1 hit：$~$4 cycles
    - DRAM miss：100+ cycles
    - 哪怕 miss rate 只差 0.5 vs 2.0，实际时间是数量级差距
  - 预取器（prefetcher）放大差异
    - 对 stride = 1，硬件能提前把 cache line 拉进来
    - 对列访问 / 大 stride，预取器直接失效
    - kij 即使数据远大于 cache，也能保持平坦高性能山脊

*矩阵乘法的不同实现方式*
- 对于大的$n$值，即使每个版本都执行相同数量的浮点算术操作，最快的版本比最慢的版本运行得快几乎20倍。
- 存储器行为最糟糕的两个版本，就每次迭代的访问数量和不命中数量而言，明显地比其他四个版本运行得慢，其他四个版本有较少的不命中次数或者较少的访问次数，或者兼而有之。
- 对于较大的$n$的值，最快的一对版本（kij和ikj）的性能保持不变。虽然这个数组远大于任何SRAM高速缓存存储器，但预取硬件足够聪明，能够认出步长为1的访问模式，而且速度足够快能够跟上内循环中的存储器访问。
- 这是Intel的设计这个存储器系统的工程师所做的一项极好成就，向程序员提供了甚至更多的鼓励，鼓励他们开发出具有良好空间局部性的程序。

=== Using blocking to improve temporal locality

*普通矩阵乘法为什么慢？*
```c
for (i = 0; i < n; i++)
  for (j = 0; j < n; j++)
    for (k = 0; k < n; k++)
      c[i*n + j] += a[i*n + k] * b[k*n + j];
```
关键事实
- 计算量：$2 n^3$次浮点运算（不可避免）
- 数据量：只有$3 n^2$个 double（A、B、C）
  - 理论上：每个数据应该被重复用很多次（O(n) 次）
  - 现实中：Cache 里根本留不住它们
*为什么 locality 没被利用好？*
- 内层循环的真实访存行为（ijk）
  #three-line-table[
    | 矩阵 | 内层访问方式  | 局部性                  |
    | -- | ------- | -------------------- |
    | A  | a[i][k] | *行访问（stride-1）*   |
    | B  | b[k][j] | *列访问（stride = n）* |
    | C  | c[i][j] | 固定                   |
  ]
  瓶颈在 B：列访问 + cache 行不复用
*Cache miss 定量分析（不分块）*
- 假设
  - Matrix elements are doubles
  - Cache block = 8 doubles
  - Cache size C << n (much smaller than n)
- 每一次内层循环（k 循环）
  - A：每 8 次访问 1 次 miss → miss rate = 1/8
  - B：每次都跨 cache line → miss rate = 1
  - C：固定 → miss rate = 0
  - 平均 miss / iteration ≈ 9/8
  - 总 miss 数
    - No blocking: (9/8) · n³ misses
*核心思想：Blocking（分块）*
- 既然 cache 装不下整个矩阵，那就：一次只算一小块，让这小块的数据“多活一会儿”
- 不一次扫完整个 A、B、C，而是算 B × B 的小矩阵乘法
```c
c = (double *) calloc(sizeof(double), n*n);
/* Multiply n x n matrices a and b */
void mmm(double *a, double *b, double *c, int n) {
int i, j, k;
for (i = 0; i < n; i+=B)
  for (j = 0; j < n; j+=B)
    for (k = 0; k < n; k+=B)
    /* B x B mini matrix multiplications */
      for (i1 = i; i1 < i+B; i1++)
        for (j1 = j; j1 < j+B; j1++)
          for (k1 = k; k1 < k+B; k1++)
            c[i1*n+j1] += a[i1*n + k1]*b[k1*n + j1];
  }
```
A、B、C 的这三块，在内层循环中会被反复使用

*为什么 Blocking 有效？（定量分析）*
- 假设
  - Matrix elements are doubles
  - Cache block = 8 doubles
  - Cache size C << n (much smaller than n)
- 关键约束
  - 要让三块同时装进 cache： 3 B² × 8B ≤ Cache size
    - B ≤ sqrt(Cache size / 24)
- Cache miss 重新计算
  - 每个Block的miss为 B²/8
  - 每一层 block 计算：2n/B × B²/8 = nB/4 misses
  - 总 miss：
    - With blocking: n³/(4B) misses
- Blocking vs 不 Blocking：数量级差距

*工程结论*
- Loop interchange 解决“空间局部性”
  - kij / ikj > ijk / jik > jki
- Blocking 解决“时间局部性”
  - 数据真正被 cache 复用
  - miss 从 O(n³) 降到 O(n³ / B)
- 实际高性能库（BLAS / MKL）
  - 多级 blocking
  - L1 blocking
  - L2 blocking
  - L3 blocking
  - 向量化
  - 预取
  - 指令级并行

*Cache Summary*
- Cache memories can have significant performance impact
- You can write your programs to exploit this!
  - 只盯内循环
    - CPU 大部分时间都耗在热点代码（hot spot）上，而热点几乎总在：
      - 大循环
      - 多层嵌套循环的最内层
      - 频繁被调用的小函数
    - 所以优化策略是：让最常执行的那几行代码更少 miss、更连续访问、更少随机跳。
  - 最大化空间局部性：Stride-1
    - 空间局部性 = 访问地址连续 / 接近。
    - 因为 cache line 会一次搬一整块（比如 64B）。要是顺序读，等于“一个 miss 换来一串 hit”。
  - 最大化时间局部性：把“刚读进来的”用到榨干
    - 时间局部性 = 同一个数据很快又用到。
    - 数据从内存搬进 cache 很贵，搬进来以后再用几次几乎“免费”
- 习惯 A：调循环顺序（loop interchange）
  - 让最内层循环走连续内存方向（通常是数组最后一维）。
- 习惯 B：分块（blocking/tiling）
  - 当数据集大到 cache 放不下时，按块处理，让工作集塞进 cache。
- 习惯 C：减少不必要的内存流量
  - 能放寄存器的就别反复 load/store（比如把 sum 留在寄存器）
  - 避免在内层循环里做大量函数调用/间接访问（影响预取和流水）
