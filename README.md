# 清华大学软件学院计算机组成原理笔记（2025秋）

本仓库记录了本人在清华大学软件学院杨铮老师计算机组成原理课程（2025 秋季学期）的学习过程，包括：

* 课程笔记（基于 [Typst](https://typst.app/) 编写）
* 平时作业练习及相关资源

## 参考资料

* [CSAPP](https://www.cs.sfu.ca/~ashriram/Courses/CS295/assets/books/CSAPP_2016.pdf)
* [CSAPP中文版教材](https://annas-archive.org/md5/0f9b27d5b689048ee84c32a0570c28bd)
* [课后习题](https://dreamanddead.github.io/CSAPP-3e-Solutions/)
* [实验Lab](https://github.com/Exely/CSAPP-Labs)

## 项目结构

```
.
├── HW                     # 作业目录
│   └── i                 # 第 i 次作业
│        ├── main.typ     # Typst 源文件
│        ├── (makefile)   # 作业内专用 Makefile
│        └── ...          # 其他资源文件
├── pic                    # 图片资源目录
├── chapX.typ              # 笔记章节 Typst 源文件
├── main.typ               # 笔记主 Typst 源文件
├── makefile               # 顶层 Makefile，用于统一构建
├── builds                 # 编译输出目录（生成的 PDF）
├── .gitignore             # Git 忽略文件
└── README.md              # 项目说明
```

## 环境依赖

* [Typst](https://github.com/typst/typst) ：文档编译必须的工具，如果不愿意自行编译也可以在Release中下载GitHub Action编译的PDF
  * 用到了本人维护的 [scripst](https://github.com/An-314/scripst) 模板库
* 一些构建脚本使用了 POSIX shell 语法（Linux/macOS 环境原生支持；Windows 建议 WSL）

## 构建说明

### 生成所有 PDF

在项目根目录下运行：
```bash
make
```
即可在 `builds/` 目录下生成：

* `main.pdf`（完整课程笔记）
* 各次作业的 PDF 文件（`HW/i.pdf`）

### 生成单次作业

进入对应作业目录（若存在子 Makefile）：
```bash
cd HW/i
make
```
会在该作业目录下执行作业要求的逻辑

## 关于 Typst 与 scripst

* [Typst](https://typst.app/)：一种现代文档排版工具，语法接近 Markdown，功能接近 LaTeX，适合学术/技术文档。

  * 安装

    ```powershell
    # Windows
    winget install typst
    ```

    ```bash
    # archlinux
    sudo pacman -S typst
    ```

    ```bash
    # macOS
    brew install typst
    ```
  * 编译文件

    ```bash
    typst c source.typ output.pdf
    ```

* 本项目基于 [scripst](https://github.com/An-314/scripst) 模板库生成。

  * 引入

    ```typst
    #import "@preview/scripst:1.1.1": *
    ```

## 贡献 & 使用说明

* 本项目主要为**个人学习笔记与作业记录**，并不保证内容完整或无误
* 部分内容参考了AI的回答，但经过了人工校验与修改，但仍可能存在错误
* 遵守清华大学学术诚信相关规定