#import "@preview/scripst:1.1.1": *

#show: scripst.with(
  title: [计算机组成原理],
  info: [第四次作业],
  author: "Anzrew",
  time: "2025/12/27",
)

#problem(subname: [6.11])[
  In general, if the high-order $s$ bits of an address are used as the set index, contiguous chunks of memory blocks are mapped to the same cache set.
  + How many blocks are in each of these contiguous array chunks?
  + Consider the following code that runs on a system with a cache of the form $(S, E, B, m) = (512, 1, 32, 32)$:
  ```c
  int array[4096];
  for (i = 0; i < 4096; i++)
    sum += array[i];
  ```
  What is the maximum number of array blocks that are stored in the cache at any point in time?
]

#solution[
  + 每个 contiguous chunk 有多少个 blocks？
    ```
    地址： | tag (t 位) | set index (s 位) | block offset (b 位) |
    ```
    - 地址总位数：$m = t + s + b$
    - 块大小$B = 2^b$ 字节
    - 组索引用的是高位 $s$ 位
    在内存里连续走的时候，地址先变的是低位。只要高位 $s$ 位不变，就一直映射到同一个 set。
    - 高位 $s$ 位固定时，剩下的位数是 $m - s$，每个 block 是 $B = 2^b$ 字节，所以这段范围里 block 数是
      $
        2^(m - s - b) = 2^t
      $
  + 代码里任意时刻 cache 最多能放多少个 array blocks？
    - 给定 cache：`(S, E, B, m) = (512, 1, 32, 32)`
    - `(s, e, b, m) = (9, 0, 5, 32)`
    - `int` 4 字节，`array[4096]` 总大小：`4096 * 4 = 16384 B= 4 KB`
      - array 占用的 block 数：`16384 / 32 = 512 blocks`
    - `512 blocks` 恰好等于 cache 的组数 `S = 512`
    - array 的这 512 个 blocks 全部映射到同一个 set
    - 由于 `E = 1`，每组只能放 1 个 block，其余都会不断被替换
]

#problem(subname: [6.23])[
  Estimate the average time (in ms) to access a sector on the following disk:
  #figure(
    three-line-table[
      | Parameter | Value |
      | --- | --- |
      | Rotational rate | 12,000 RPM |
      | $vb(T)_"avg seek"$ |	3 ms |
      | Average\# sectors/track | 500 |
    ],
    numbering: none,
  )
]

#solution[
  - T_avg_seek
    $
      T_"avg seek" = 3 "ms"
    $
  - T_avg_rotation
    $
      T_"avg rotation" = 1/2 times 1/12000 times 60 times 1000 = 2.5 "ms"
    $
  - T_transfer
    $
      T_"transfer" = 1/500 times 1/12000 times 60 times 1000 = 0.01 "ms"
    $
  从而得到平均访问时间：
  $
    T_"avg access" = T_"avg seek" + T_"avg rotation" + T_"transfer" = 3 + 2.5 + 0.01 = 5.51 "ms"
  $
]

#problem(subname: [6.34 和教材中的题目`i`,`j`互换])[
  Consider the following matrix transpose routine:
  ```c
  typedef int array[4][4];

  void transpose2(array dst, array src)
  {
    int i, j;
    for (i = 0; i < 4; i++) {
      for (j = 0; j < 4; j++) {
        dst[i][j] = src[j][i];
      }
    }
  }
  ```
  Assume this code runs on a machine with the following properties:
  - `sizeof(int) == 4`.
  - The `src` array starts at address 0 and the `dst` array starts at address 64 (decimal).
  - There is a single L1 data cache that is direct-mapped, write-through, writeallocate, with a block size of 16 bytes.
  - The cache has a total size of 32 data bytes and the cache is initially empty.
  - Accesses to the `src` and `dst` arrays are the only sources of read and write misses, respectively.
  + For each row and col, indicate whether the access to `src[row][col]` and `dst[row][col]` is a hit (`h`) or a miss (`m`). For example, reading `src[0][0]` is a miss and writing `dst[0][0]` is also a miss.
  #figure(
    three-line-table[
      | \ | scr array | < | < | < |
      | --- | --- | --- | --- | --- |
      | \ | col 0 | col 1 | col 2 | col 3 |
      | Row 0 | `m` | \ | \ | \ |
      | Row 1 | \ | \ | \ | \ |
      | Row 2 | \ | \ | \ | \ |
      | Row 3 | \ | \ | \ | \ |
    ],
    numbering: none,
  )
  #figure(
    three-line-table[
      | \ | dst array | < | < | < |
      | --- | --- | --- | --- | --- |
      | \ | col 0 | col 1 | col 2 | col 3 |
      | Row 0 | `m` | \ | \ | \ |
      | Row 1 | \ | \ | \ | \ |
      | Row 2 | \ | \ | \ | \ |
      | Row 3 | \ | \ | \ | \ |
    ],
    numbering: none,
  )
]

#solution[
  - block = 16B = 4 个 int
  - 一行正好 16B
    - `src` 的每一行各占 1 个 block：block 0,1,2,3
    - `dst` 从地址 64 开始，也是每行 1 个 block：block 4,5,6,7
  - cache 只有 2 个 set（因为总 32B / 16B = 2 行，direct-mapped）
    - set = block\# mod 2
    - 于是：
      - `src` 的 block 0,2 都去 set0；block 1,3 去 set1
      - `dst` 的 block 4,6 也去 set0；block 5,7 去 set1
      #three-line-table[
        | `src` 行 | block | set (=block mod2) | tag (=block\/\/2) |
        | ----- | ----: | ----------------: | --------------: |
        | row0  |     0 |                 0 |               0 |
        | row1  |     1 |                 1 |               0 |
        | row2  |     2 |                 0 |               1 |
        | row3  |     3 |                 1 |               1 |
      ]
      #three-line-table[
        | `dst` 行 | block | set | tag |
        | ----- | ----: | --: | --: |
        | row0  |     4 |   0 |   2 |
        | row1  |     5 |   1 |   2 |
        | row2  |     6 |   0 |   3 |
        | row3  |     7 |   1 |   3 |
      ]
  - 内层循环每次都先读 `src[j][i]`，再写 `dst[i][j]`
  - `i = 0`（写 `dst` 的第 0 行：`dst[0][j]`）
    - 内层 `j=0..3`，每次都先读 `src[j][0]` 再写 `dst[0][j]`
    - `j=0`
      - 读 `src[0][0]`：地址 `0 ⇒ block0 ⇒ set0 tag0`
      - cache 空，miss，装入 block0
      - 写 `dst[0][0]`：地址 `64 ⇒ block4 ⇒ set0 tag2`
      - set0 里是 block0 tag0，不命中，miss，装入 block4，替换掉 block0
    - `j=1`
      - 读 `src[1][0]`：地址 `16 ⇒ block1 ⇒ set1 tag0`
      - set1 空，miss，装入 block1
      - 写 `dst[0][1]`：地址 `68 ⇒ block4 ⇒ set0 tag2`
      - set0 里是 block4 tag2，命中，hit
    - `j=2`
      - 读 `src[2][0]`：地址 `32 ⇒ block2 ⇒ set0 tag1`
      - set0 里是 block4 tag2，不命中，miss，装入 block2，替换掉 block4
      - 写 `dst[0][2]`：地址 `72 ⇒ block4 ⇒ set0 tag2`
      - set0 里是 block2 tag1，不命中，miss，装入 block4，替换掉 block2
    - `j=3`
      - 读 `src[3][0]`：地址 `48 ⇒ block3 ⇒ set1 tag1`
      - set1 里是 block1 tag0，不命中，miss，装入 block3，替换掉 block1
      - 写 `dst[0][3]`：地址 `76 ⇒ block4 ⇒ set0 tag2`
      - set0 里是 block4 tag2，命中，hit
  - `i = 1`（写 `dst` 的第 1 行：`dst[1][j]`）
    - 内层 `j=0..3`，每次都先读 `src[j][1]` 再写 `dst[1][j]`
    - `j=0`
      - 读 `src[0][1]`：地址 `4 ⇒ block0 ⇒ set0 tag0`
      - set0 里是 block4 tag2，不命中，miss，装入 block0，替换掉 block4
      - 写 `dst[1][0]`：地址 `80 ⇒ block5 ⇒ set1 tag2`
      - set1 里是 block3 tag1，不命中，miss，装入 block5，替换掉 block3
    - `j=1`
      - 读 `src[1][1]`：地址 `20 ⇒ block1 ⇒ set1 tag0`
      - set1 里是 block5 tag2，不命中，miss，装入 block1，替换掉 block5
      - 写 `dst[1][1]`：地址 `84 ⇒ block5 ⇒ set1 tag2`
      - set1 里是 block1 tag0，不命中，miss，装入 block5，替换掉 block1
    - `j=2`
      - 读 `src[2][1]`：地址 `36 ⇒ block2 ⇒ set0 tag1`
      - set0 里是 block0 tag0，不命中，miss，装入 block2，替换掉 block0
      - 写 `dst[1][2]`：地址 `88 ⇒ block5 ⇒ set1 tag2`
      - set1 里是 block5 tag2，命中，hit
    - `j=3`
      - 读 `src[3][1]`：地址 `52 ⇒ block3 ⇒ set1 tag1`
      - set1 里是 block5 tag2，不命中，miss，装入 block3，替换掉 block5
      - 写 `dst[1][3]`：地址 `92 ⇒ block5 ⇒ set1 tag2`
      - set1 里是 block3 tag1，不命中，miss，装入 block5，替换掉 block3
  - `i = 2`（写 `dst` 的第 2 行：`dst[2][j]`）
    - 内层 `j=0..3`，每次都先读 `src[j][2]` 再写 `dst[2][j]`
    - `j=0`
      - 读 `src[0][2]`：地址 `8 ⇒ block0 ⇒ set0 tag0`
      - set0 里是 block2 tag1，不命中，miss，装入 block0，替换掉 block2
      - 写 `dst[2][0]`：地址 `96 ⇒ block6 ⇒ set0 tag3`
      - set0 里是 block0 tag0，不命中，miss，装入 block6，替换掉 block0
    - `j=1`
      - 读 `src[1][2]`：地址 `24 ⇒ block1 ⇒ set1 tag0`
      - set1 里是 block5 tag2，不命中，miss，装入 block1，替换掉 block5
      - 写 `dst[2][1]`：地址 `100 ⇒ block6 ⇒ set0 tag3`
      - set0 里是 block6 tag3，命中，hit
    - `j=2`
      - 读 `src[2][2]`：地址 `40 ⇒ block2 ⇒ set0 tag1`
      - set0 里是 block6 tag3，不命中，miss，装入 block2，替换掉 block6
      - 写 `dst[2][2]`：地址 `104 ⇒ block6 ⇒ set0 tag3`
      - set0 里是 block2 tag1，不命中，miss，装入 block6，替换掉 block2
    - `j=3`
      - 读 `src[3][2]`：地址 `56 ⇒ block3 ⇒ set1 tag1`
      - set1 里是 block1 tag0，不命中，miss，装入 block3，替换掉 block1
      - 写 `dst[2][3]`：地址 `108 ⇒ block6 ⇒ set0 tag3`
      - set0 里是 block6 tag3，命中，hit
  - `i = 3`（写 `dst` 的第 3 行：`dst[3][j]`）
    - 内层 `j=0..3`，每次都先读 `src[j][3]` 再写 `dst[3][j]`
    - `j=0`
      - 读 `src[0][3]`：地址 `12 ⇒ block0 ⇒ set0 tag0`
      - set0 里是 block6 tag3，不命中，miss，装入 block0，替换掉 block6
      - 写 `dst[3][0]`：地址 `112 ⇒ block7 ⇒ set1 tag3`
      - set1 里是 block3 tag1，不命中，miss，装入 block7，替换掉 block3
    - `j=1`
      - 读 `src[1][3]`：地址 `28 ⇒ block1 ⇒ set1 tag0`
      - set1 里是 block7 tag3，不命中，miss，装入 block1，替换掉 block7
      - 写 `dst[3][1]`：地址 `116 ⇒ block7 ⇒ set1 tag3`
      - set1 里是 block1 tag0，不命中，miss，装入 block7，替换掉 block1
    - `j=2`
      - 读 `src[2][3]`：地址 `44 ⇒ block2 ⇒ set0 tag1`
      - set0 里是 block0 tag0，不命中，miss，装入 block2，替换掉 block0
      - 写 `dst[3][2]`：地址 `120 ⇒ block7 ⇒ set1 tag3`
      - set1 里是 block7 tag3，命中，hit
    - `j=3`
      - 读 `src[3][3]`：地址 `60 ⇒ block3 ⇒ set1 tag1`
      - set1 里是 block7 tag3，不命中，miss，装入 block3，替换掉 block7
      - 写 `dst[3][3]`：地址 `124 ⇒ block7 ⇒ set1 tag3`
      - set1 里是 block3 tag1，不命中，miss，装入 block7，替换掉 block3
  最终结果：
  #figure(
    three-line-table[
      | \ | scr array | < | < | < |
      | --- | --- | --- | --- | --- |
      | \ | col 0 | col 1 | col 2 | col 3 |
      | Row 0 | `m` | `m` | `m` | `m` |
      | Row 1 | `m` | `m` | `m` | `m` |
      | Row 2 | `m` | `m` | `m` | `m` |
      | Row 3 | `m` | `m` | `m` | `m` |
    ],
    numbering: none,
  )
  #figure(
    three-line-table[
      | \ | dst array | < | < | < |
      | --- | --- | --- | --- | --- |
      | \ | col 0 | col 1 | col 2 | col 3 |
      | Row 0 | `m` | `h` | `m` | `h` |
      | Row 1 | `m` | `m` | `h` | `m` |
      | Row 2 | `m` | `h` | `m` | `h` |
      | Row 3 | `m` | `m` | `h` | `m` |
    ],
    numbering: none,
  )
]

#problem(subname: [6.35])[
  Repeat Problem 6.35 for a cache with a total size of 128 data bytes.
  #figure(
    three-line-table[
      | \ | scr array | < | < | < |
      | --- | --- | --- | --- | --- |
      | \ | col 0 | col 1 | col 2 | col 3 |
      | Row 0 | \ | \ | \ | \ |
      | Row 1 | \ | \ | \ | \ |
      | Row 2 | \ | \ | \ | \ |
      | Row 3 | \ | \ | \ | \ |
    ],
    numbering: none,
  )
  #figure(
    three-line-table[
      | \ | dst array | < | < | < |
      | --- | --- | --- | --- | --- |
      | \ | col 0 | col 1 | col 2 | col 3 |
      | Row 0 | \ | \ | \ | \ |
      | Row 1 | \ | \ | \ | \ |
      | Row 2 | \ | \ | \ | \ |
      | Row 3 | \ | \ | \ | \ |
    ],
    numbering: none,
  )
]

#solution[
  - block = 16B = 4 个 int
  - 一行正好 16B
    - `src` 的每一行各占 1 个 block：block 0,1,2,3
    - `dst` 从地址 64 开始，也是每行 1 个 block：block 4,5,6,7
  - cache 只有 8 个 set（因为总 128B / 16B = 8 行，direct-mapped）
    - set = block\# mod 8
    - 于是：
      - `src` 的 block 0,1,2,3 分别去 set0,1,2,3
      - `dst` 的 block 4,5,6,7 分别去 set4,5,6,7
      #three-line-table[
        | `src` 行 | block | set (=block mod8) | tag (=block\/\/8) |
        | ----- | ----: | ----------------: | --------------: |
        | row0  |     0 |                 0 |               0 |
        | row1  |     1 |                 1 |               0 |
        | row2  |     2 |                 2 |               0 |
        | row3  |     3 |                 3 |               0 |
      ]
      #three-line-table[
        | `dst` 行 | block | set | tag |
        | ----- | ----: | --: | --: |
        | row0  |     4 |   4 |   0 |
        | row1  |     5 |   5 |   0 |
        | row2  |     6 |   6 |   0 |
        | row3  |     7 |   7 |   0 |
      ]
  - 只有第一次访问每个 block 会 miss，之后都 hit
  最终结果：
  #figure(
    three-line-table[
      | \ | scr array | < | < | < |
      | --- | --- | --- | --- | --- |
      | \ | col 0 | col 1 | col 2 | col 3 |
      | Row 0 | `m` | `h` | `h` | `h` |
      | Row 1 | `m` | `h` | `h` | `h` |
      | Row 2 | `m` | `h` | `h` | `h` |
      | Row 3 | `m` | `h` | `h` | `h` |
    ],
    numbering: none,
  )
  #figure(
    three-line-table[
      | \ | dst array | < | < | < |
      | --- | --- | --- | --- | --- |
      | \ | col 0 | col 1 | col 2 | col 3 |
      | Row 0 | `m` | `h` | `h` | `h` |
      | Row 1 | `m` | `h` | `h` | `h` |
      | Row 2 | `m` | `h` | `h` | `h` |
      | Row 3 | `m` | `h` | `h` | `h` |
    ],
    numbering: none,
  )
]

