#import "@preview/scripst:1.1.1": *

#show: scripst.with(
  title: [计算机组成原理],
  info: [第四次作业],
  author: "Anzrew",
  time: "2025/12/27",
)

#problem(subname: [6.11])[
  In general, if the high-order s bits of an address are used as the set index, contiguous chunks of memory blocks are mapped to the same cache set.
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

