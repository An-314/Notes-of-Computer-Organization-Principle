#import "@preview/scripst:1.1.1": *

= Bits, Bytes, and Integers

== Representing information as bits

二进制表示
- 0和1
字节(Byte)的编码方式
- byte = 8 bits
- 二进制(binary)
  - $00000000_2 tilde 11111111_2$
- 十进制(decimal)
  - $0 tilde 255_(10)$
- 十六进制(hexadecimal)
  - $00 tilde FF_(16)$
  - 在C语言中，十六进制以`0x`开头表示
    - `0xFA1D37B`, `0xfa1d37b`
字节寻址的内存组织(Byte-Oriented Memory Organization)
- 程序使用虚拟地址(Virtual Addresses)
