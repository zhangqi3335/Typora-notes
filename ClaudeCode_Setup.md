这份笔记综合了之前关于 **在 Windows 上通过 WSL (Linux 子系统) 安装 Claude Code** 的所有对话，特别针对**将系统安装在 E 盘**以节省 C 盘空间的需求，整理了一套完整的“最佳实践”流程。

您可以直接复制保存为 Markdown 文件（例如 `ClaudeCode_Setup.md`）。

***

# Windows 下部署 Claude Code 最佳实践指南 (WSL + E盘安装版)

## 📌 方案概述
本方案通过 Windows Subsystem for Linux (WSL) 运行 Claude Code，相比直接在 Windows 上运行，具有更好的兼容性和文件权限管理。
为了避免占用 C 盘空间，我们将 Ubuntu 系统文件“搬家”到 E 盘（或其他非系统盘）。

*   **目标环境**：Ubuntu 22.04 LTS
*   **安装位置**：E:\WSL\Ubuntu (可自定义)
*   **前置要求**：Windows 10 (版本 2004+) 或 Windows 11

---

## 第一阶段：启用 WSL 并获取基础镜像

**注意**：所有 `PS>` 开头的命令均需在 **PowerShell (管理员身份)** 中执行。

1.  **安装 WSL 框架与 Ubuntu**
    ```powershell
    # 这一步会启用 WSL 功能并下载 Ubuntu 22.04
    wsl --install -d Ubuntu-22.04
    ```

2.  **重启电脑**
    *   命令执行完毕后，**必须重启电脑**以完成内核安装。

3.  **初始化系统**
    *   重启后，会自动弹出一个黑色终端窗口（如果没有，搜索打开 `Ubuntu`）。
    *   等待安装初始化（Installing...）。
    *   按提示设置 **Username** (纯英文，如 `devuser`) 和 **Password** (输入时不可见)。
    *   看到绿色的 `username@hostname:~$` 提示符后，输入 `exit` 关闭窗口。

---

## 第二阶段：将 Linux 系统迁移至 E 盘 (核心步骤)

默认 WSL 安装在 C 盘，我们需要通过“打包-删除-解压”的方式将其迁移。

1.  **停止 WSL 服务**
    ```powershell
    wsl --shutdown
    ```

2.  **导出系统镜像 (备份)**
    *   将当前 C 盘的系统打包成一个 tar 文件放到 E 盘根目录。
    ```powershell
    # 耗时约 1-3 分钟
    wsl --export Ubuntu-22.04 E:\ubuntu_backup.tar
    ```

3.  **注销原系统 (释放 C 盘空间)**
    *   这一步会删除 C 盘的 Linux 文件。
    ```powershell
    wsl --unregister Ubuntu-22.04
    ```

4.  **在 E 盘重新导入系统**
    *   先创建存放文件夹：`E:\WSL\Ubuntu`
    ```powershell
    mkdir E:\WSL\Ubuntu
    # 导入命令：wsl --import <新名称> <安装路径> <备份包路径>
    wsl --import Ubuntu-22.04 E:\WSL\Ubuntu E:\ubuntu_backup.tar
    ```

5.  **恢复默认用户 (重要)**
    *   导入后的系统默认是以 root (管理员) 登录，不安全且配置麻烦。我们需要改回你在第一阶段设置的用户名。
    *   在 PowerShell 中运行：
    ```powershell
    # 请将 'devuser' 替换为你第一阶段设置的真实用户名
    wsl -d Ubuntu-22.04 -u root -e bash -c "echo -e '[user]\ndefault=devuser' >> /etc/wsl.conf"
    
    # 强制重启 WSL 使配置生效
    wsl --terminate Ubuntu-22.04
    ```

6.  **验证与清理**
    *   启动系统：`wsl -d Ubuntu-22.04` (确认现在是否为你的用户名)。
    *   删除备份包：在文件资源管理器中删除 `E:\ubuntu_backup.tar` 以节省空间。

---

## 第三阶段：配置环境与安装 Claude Code

现在你的 Linux 已经在 E 盘安家了。打开 Ubuntu 终端（或者在 PowerShell 输入 `wsl`），执行以下 **Linux 命令**。

1.  **安装 Node.js 环境 (使用 nvm 管理)**
    Claude Code 依赖 Node.js。
    ```bash
    # 1. 下载并安装 nvm (Node Version Manager)
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # 2. 让 nvm 立即生效 (或者关闭窗口重开)
    source ~/.bashrc
    
    # 3. 安装最新的 LTS (长期支持) 版本 Node.js
    nvm install --lts
    
    # 4. 验证安装
    node -v
    npm -v
    ```

2.  **安装 Claude Code**
    ```bash
    # 全局安装 Anthropic 的工具
    npm install -g @anthropic-ai/claude-code
    ```

3.  **启动与认证**
    ```bash
    # 启动命令
    claude
    ```
    *   首次运行会提示你进行认证。
    *   按回车键打开浏览器 -> 登录 Anthropic 账号 -> 授权 -> 完成。

---

## 📝 以后考虑的笔记 (FAQ & 维护)

### 1. 这个系统占用了多少空间？
*   **初始占用**：约 1.5GB - 2GB。
*   **增长机制**：它是一个虚拟磁盘文件 (`ext4.vhdx`)，位于 `E:\WSL\Ubuntu` 下。你安装的软件越多，它会自动变大。
*   **上限**：默认最大支持 256GB（或者是你 E 盘的剩余空间），按需自增。

### 2. 如何彻底删除它？
如果你想卸载 Claude Code 或整个 Linux 系统，请执行以下步骤实现**彻底、干净**的删除：

1.  **注销系统 (逻辑删除)**：
    在 PowerShell 中执行：
    ```powershell
    wsl --unregister Ubuntu-22.04
    ```
2.  **物理删除**：
    手动删除 E 盘的文件夹 `E:\WSL\Ubuntu`。
3.  **应用卸载**：
    在 Windows 设置 -> 应用中，搜索 "Ubuntu"，如果有残留的应用图标，点击卸载。

### 3. 常用的 Claude Code 指令
进入 WSL 终端后：
*   `claude` : 启动交互式界面。
*   `/bug` : 报告错误。
*   `/clear` : 清除上下文记忆（省 Token）。
*   `Ctrl + C` : 强制终止当前生成的代码。

### 4. 访问 Windows 文件
在 Ubuntu 内部，你的 Windows 硬盘挂载在 `/mnt/` 下：
*   访问 C 盘：`cd /mnt/c`
*   访问 E 盘：`cd /mnt/e`
*   *建议*：尽量把代码放在 Ubuntu 的自己的目录下（例如 `~/project`），文件读写速度比在 `/mnt/` 下快得多。

### 5. 潜在影响
*   **Hyper-V**：WSL 2 依赖 Hyper-V 虚拟化。如果你还在使用非常老旧的安卓模拟器（如旧版雷电、MuMu），可能会有冲突。解决方法是更新模拟器到最新版（大多数现代模拟器已兼容 Hyper-V）。
*   **性能**：不运行时不占用资源。运行时占用少量内存。