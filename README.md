***

# 📦 Utility Scripts Collection

本仓库包含三个日常开发中常用的小工具脚本，用于 **GitHub 仓库交互式同步**、**Markdown 标题自动编号** 以及 **Typora 图片工程化迁移**。
这些脚本均可独立使用，共同构成了一套高效的文档编写与仓库管理工作流。

------

## 📌 目录

- [交互式-git-同步助手](Logic.ps1)
  [交互式-git-同步助手快捷方式(.bat)](Logic.bat)
  - 功能与特性
  - 使用方法
-   [图片工程化迁移工具](Logic-Migrate-TyporaImages.ps1)
    [图片工程化迁移工具快捷方式(.bat)](Logic-Run-Migration.bat)
  - 功能
  - 核心特性
  - 配置与使用
  - 迁移日志示例
- [markdown-标题自动编号脚本](sort_md.py)
  - 功能与算法
  - 使用方法

------

# Logic.bat & Logic.ps1 — 交互式 Git 同步助手

### 🚀 功能

这是一套 **双文件架构** 的 Git 同步工具，专为 Windows 用户设计。
它解决了单纯 .ps1 脚本常见的**乱码闪退问题**，并提供了完整的交互流程（拉取、暂存、提交、推送）。
非常适合用于管理 Typora 笔记库、代码仓库等需要防止“误操作”的场景。

### ✨ 特点

- **双保险架构**：
  - Logic.bat：负责设置 UTF-8 编码并启动环境，保证窗口不闪退。
  - Logic.ps1：负责核心 Git 逻辑处理，界面美观。
- **全流程交互**：
  - **拉取检查**：推送前先检测远程更新，避免冲突。
  - **灵活暂存**：支持一键 add .，也支持调用 git add -i 进行文件手动筛选。
  - **智能备注**：支持自定义 Commit 信息，不输入则自动生成时间戳。
- **防乱码设计**：完美解决 Windows CMD 中文乱码问题。

### 📘 使用方法

1. **双击运行**：直接在文件夹中双击 **Run.bat** 即可启动。
2. **快捷方式（推荐）**：为 Logic.bat 创建快捷方式并放入 shell:programs，即可通过 Win 键搜索快速启动。

------



# Logic-Run-Migration.bat & Logic-Migrate-TyporaImages.ps1 — Typora 图片工程化迁移工具

### 🚀 功能

这是一个**工程级**的图片整理脚本，专门解决 Typora 粘贴图片后路径混乱、无法上传 Git 或在不同电脑间同步的问题。
它能自动将 Markdown 引用的本地绝对路径图片（特别是 AppData 下的临时图片）移动到项目内部，并自动修正 Markdown 中的引用链接。

### ✨ 核心特性

- **Git 友好路径**：将图片移动到 .\Image\<MD文件名>\ 目录下，并将 Markdown 中的引用修改为**相对路径**，确保推送到 GitHub 后图片依然可见。
- **工程级安全**：
  - **DryRun (预演模式)**：默认开启，仅打印计划的操作，不修改任何文件，确保无误后再执行。
  - **日志追踪**：操作记录（控制台输出与日志文件）自动保存在 .\Log\ 目录下，方便追溯。
  - **无损编码**：强制使用 UTF-8 (BOM) 处理文件，防止 Emoji 和中文乱码。
- **智能识别**：
  - 支持 Markdown 标准格式 ![]() 和 HTML 格式 <img src="">。
  - 自动处理 URL 编码（如中文路径、空格 %20 等）。
- **双文件架构**：
  - Logic-Run-Migration.bat：一键启动，解决权限与编码问题。
  - Logic-Migrate-TyporaImages.ps1：核心逻辑实现。

### ⚙️ 配置与使用

#### 1. 配置脚本 (首次使用)

右键编辑 Logic-Migrate-TyporaImages.ps1，修改顶部配置区：

```Powershell
# Markdown 库的根目录
$RootDir = "D:\资料\Typora学习库"

# Typora 默认图片存放目录 (源目录)
$SourceImageDirBase = "C:\Users\...\AppData\Roaming\Typora\typora-user-images"

# 模式开关 ($true=演示, $false=实操)
$DryRun = $true
```

#### 2. 执行迁移

1. 双击 **Logic-Run-Migration.bat**。
2. 检查控制台输出或 Log 文件夹下的日志，确认“源路径”、“目标路径”和“相对链”是否正确。
3. 确认无误后，将脚本中的 $DryRun 改为 $false，再次运行即可完成迁移。

### 📝 迁移日志示例

```text
[INFO] === 开始 Typora 图片迁移任务 ===
[INFO] 模式: 演示 (DryRun)
[INFO] 正在扫描: D:\资料\Typora学习库\Docker笔记.md
  [发现目标] image-20230522.png
    源: C:\Users\Admin\AppData\Roaming\Typora\typora-user-images\image-20230522.png
    靶: D:\资料\Typora学习库\Image\Docker笔记\image-20230522.png
    链: ../Image/Docker笔记/image-20230522.png
```

------



# sort_md.py — Markdown 标题自动编号脚本

> ⚠ **说明**
> 仓库中的 sort_md.py 已升级为 **新版算法**，旧版本中基于「# 首次出现顺序建层级」的实现 **已完全废弃**。

### 🎯 功能

sort_md.py 会自动为 Markdown 文档中的标题生成 **符合 Markdown 语义的层级编号**，支持 # 至 ###### 六级标题，并自动处理缩进与层级回退。

### 📐 算法逻辑

1. **动态基准**：文档中 **第一个出现的标题级别** 被视为逻辑一级标题（无论它是 # 还是 ###）。
2. **树形编号**：同级递增，子级追加 .1，父级回归自动清零子级计数。
3. **智能清洗**：自动移除旧的编号（如 1.1.），且不影响代码块内的 # 注释。

### ▶ 使用方法

```bash
python sort_md.py input.md
```

或指定输出文件：

```bash
python sort_md.py input.md output.md
```

#### 示例

**处理前**：

```Markdown
# 串口通信
### 并行通信
```

**处理后**：

```Markdown
# 1 串口通信
### 1.1 并行通信
```



# 📄 License

本仓库中的脚本可自由使用、修改与分发。

## ❤️ 作者

该工具集合由本人整理与开发，用于提升 Markdown 文档管理与 Git 仓库备份效率，
适合 **嵌入式学习笔记、实验报告、项目说明书、技术文档整理** 等场景。