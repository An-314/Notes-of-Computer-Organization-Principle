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

]

#problem(subname: [6.34])[
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
  - The src array starts at address 0 and the dst array starts at address 64 (decimal).
  - There is a single L1 data cache that is direct-mapped, write-through, writeallocate, with a block size of 16 bytes.
  - The cache has a total size of 32 data bytes and the cache is initially empty.
  - Accesses to the src and dst arrays are the only sources of read and write misses, respectively.
  + For each row and col, indicate whether the access to `src[row][col]` and `dst[row][col]` is a hit (h) or a miss (m). For example, reading `src[0][0]` is a miss and writing `dst[0][0]` is also a miss.
  #figure(
    three-line-table[
      | \ | scr array | < | < | < |
      | --- | --- | --- | --- | --- |
      | \ | col 0 | col 1 | col 2 | col 3 |
      | Row 0 | m | \ | \ | \ |
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
      | Row 0 | m | \ | \ | \ |
      | Row 1 | \ | \ | \ | \ |
      | Row 2 | \ | \ | \ | \ |
      | Row 3 | \ | \ | \ | \ |
    ],
    numbering: none,
  )
]

#solution[
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

]

