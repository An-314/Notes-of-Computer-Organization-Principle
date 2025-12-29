#import "@preview/scripst:1.1.1": *

#show: scripst.with(
  template: "book",
  title: [计算机组成原理（CSAPP）],
  author: ("Anzreww",),
  time: "乙巳秋冬于清华园",
  contents: true,
  content-depth: 3,
  matheq-depth: 3,
  lang: "zh",
)

#include "chap1.typ"

#pagebreak()

#include "chap2.typ"

#pagebreak()

#include "chap3.typ"

#pagebreak()

#include "chap4.typ"

#pagebreak()

#include "chap5.typ"
