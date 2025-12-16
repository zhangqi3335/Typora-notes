# Docker 技术概述与原理

## Docker是什么？（技术概述）

Docker 是一个基于 **容器（Container）技术**的应用打包，分发和运行平台

它能够把应用程序及其依赖统一打包成一个镜像（Image），并在任意环境中以容器的方式运行，实现：

- **一次构建，到处运行**
- **快速部署**
- **环境一致性**
- **资源占用更低（相比虚拟机）**

它为开发、测试、部署提供了极高的效率。

## 为什么需要 Docker？

### **2.1 解决“环境不一致”**

不同电脑、服务器会有不同版本的系统、库、工具，导致程序报错。
 Docker 把依赖环境完全封装，任何机器运行效果都一致。

### **2.2 部署速度慢、运维成本高**

传统方式：部署环境 = 安装大量软件，调版本冲突。
 Docker：拉镜像 → 启动容器只需几秒。

### **2.3 虚拟机开销大**

虚拟机 = 整个操作系统都启动
 Docker 容器 = 共享宿主机内核 → 启动超快、资源占用少。



## Docker 组成（架构）

### **1. Docker Client（客户端）**

Docker Client 是用户与 Docker 交互的入口。
 常见方式是命令行工具 **docker CLI**，通过执行：

```
docker run
docker pull
docker build
```

客户端会将请求发送给 Docker Daemon。

------

### **2. Docker Daemon（守护进程）**

Docker 的核心后台服务，通常是：

```
dockerd
```

它负责：

- 解析客户端命令
- 管理容器生命周期
- 管理镜像、网络、数据卷
- 与 Registry 通信（拉取/推送镜像）

------

### **3. Docker Image（镜像）**

**Docker Image** 是一种 **只读模板（Read-Only Template）**，其中包含：

- 程序
- 运行所需的依赖、库
- 环境配置
- RootFS 文件系统层

可理解为：

> **镜像就是应用程序的“运行环境快照”。**

镜像采用多层结构（UnionFS），具备高复用性及快速构建能力。

------

### **4. Docker Container（容器）**

**Docker Container 是镜像的运行实例。**

特点：

- 基于 **namespace**（隔离）
- 基于 **cgroups**（资源限制）
- 启动秒级
- 是一个“隔离的 Linux 进程”

容器使用镜像的只读层，并额外创建可写层运行。

------

### **5. Docker Registry（镜像仓库）**

用于存放和分发镜像。

常见仓库：

- Docker Hub
- 阿里云镜像仓库
- GitHub Registry
- 自建私有仓库

提供 `docker pull` 和 `docker push` 功能。

------

### **6. Docker Engine（Docker 引擎）**

Docker Engine 是 Docker 的整体核心，包含：

#### **① Docker Daemon（dockerd）**

真正负责创建、运行、管理容器的后台进程。

#### **② Docker Client（docker CLI）**

用户输入命令的接口，通过 REST API 与 Daemon 通信。

#### **③ REST API**

Docker Client 和 Docker Daemon 之间的实际通信协议。



##  Docker 的运行原理：容器是如何实现隔离的？

容器本质上 **不是轻量虚拟机**，它没有模拟硬件，也没有单独内核。

容器 = **特殊配置的 Linux 进程**

Docker 底层依靠 **Linux 内核提供的三大技术**实现隔离和限制：

### Namespace（命名空间）——提供隔离

操作系统内核级别的隔离技术

Namespace 将一个进程“装进私人空间”，让它觉得自己是独立主机。

常用 namespace：

| Namespace | 作用                                 |
| --------- | ------------------------------------ |
| PID       | 独立的进程树（容器看不见宿主机进程） |
| NET       | 独立的网络栈（IP、端口、路由）       |
| MNT       | 文件系统挂载隔离                     |
| UTS       | 主机名隔离                           |
| IPC       | 信号量、消息队列隔离                 |
| USER      | 用户 ID 隔离                         |

效果：容器里的进程以为自己是“一台独立机器”。

### Cgroups（Control Groups）——资源限制

负责限制每个容器能使用的资源：

- CPU 限制
- 内存上限
- IO 限制
- 进程数量限制

**效果：容器不会抢占宿主机所有资源。**

### UnionFS（联合文件系统）——实现镜像分层

Docker 镜像是**分层结构**，每层只包含改动。优点：

- 下载更快（多镜像可共享相同底层）
- 构建快速（修改一层即可）
- 读写分离（容器运行时额外增加可写层）

常见的 UnionFS 实现：

- AUFS
- OverlayFS（默认）
- Btrfs、ZFS

容器文件系统结构：

```
镜像层（只读）
└── 容器层（可写）
```

## Docker 的生命周期执行流程

运行一个容器的过程：

```
docker run  → 使用镜像创建容器
			→ 分配文件系统（Copy-on-write）
			→ 设置 Cgroup
			→ 分配网络 （bridge，host，none）
			→ 启动主进程
```

容器关闭后，其实只是 **容器内 PID 1 进程退出**。

## Dockerflie

Dockerfile 是一个**纯文本文件**，里面包含了一系列**指令（Instruction）**，用于告诉 Docker 如何自动构建一个自定义的 Docker 镜像。简单说，它是 “镜像的构建说明书”—— 通过编写 Dockerfile，你可以定义镜像的基础环境、安装软件、配置程序、设置启动命令等，最终让 Docker 按照这个文件的步骤，一键生成你需要的镜像。

#### Dockerfile 的核心作用

- **标准化镜像构建**：替代手动一步步配置容器再打包的方式，用代码（文本）定义镜像，确保每次构建的镜像完全一致（避免 “本地能跑、线上不行” 的环境差异）。
- **可复用 / 可版本控制**：Dockerfile 可以像代码一样存入 Git 管理，方便团队共享、修改、追溯镜像的构建历史。
- **自动化构建**：结合 Docker Compose、CI/CD 工具（如 Jenkins），可以实现镜像的自动构建、测试、部署。

#### Dockerfile 的基本结构（常用指令）

一个典型的 Dockerfile 由以下几类指令组成（按执行顺序排列）：

dockerfile

```dockerfile
# 1. 指定基础镜像（必须是第一个指令）
FROM ubuntu:20.04  # 基于 Ubuntu 20.04 作为基础环境

# 2. 维护者信息（可选）
LABEL maintainer="yourname@example.com"

# 3. 执行命令（在构建镜像时运行，如安装软件）
RUN apt update && apt install -y nginx  # 安装 Nginx

# 4. 设置工作目录（后续指令的默认目录）
WORKDIR /usr/share/nginx/html

# 5. 复制文件（从主机复制到镜像内）
COPY index.html .  # 把主机当前目录的 index.html 复制到镜像的工作目录

# 6. 暴露端口（告诉 Docker 容器运行时要监听的端口）
EXPOSE 80

# 7. 容器启动时执行的命令（一个 Dockerfile 只能有一个 CMD，若多个则最后一个生效）
CMD ["nginx", "-g", "daemon off;"]  # 启动 Nginx 并保持前台运行
```

#### Dockerfile 的构建流程

编写好 Dockerfile 后，在 Dockerfile 所在目录执行以下命令，即可构建镜像：

```bash
# docker build -t 镜像名:版本号 .
docker build -t my-nginx:v1 .
```

- `-t`：给镜像打标签（方便后续识别）；
- `.`：表示 Dockerfile 所在的当前目录。

前端使用Dockerx，后端使用Dockerkit

在代码仓库（开发阶段）

根据Dockerfile

在注册中心（交付阶段）

到Docker仓库

再到部署和维护阶段

## Ubuntu的Docker环境配置

#### 使用【阿里云】Docker官方镜像

安装依赖

```
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release
```

创建keyrings目录

```
sudo mkdir -p /etc/apt/keyrings
```

下载阿里云Dockers  GDP Key

```
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | \
sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

添加Docker阿里云软件源（22.04）

```
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://mirrors.aliyun.com/docker-ce/linux/ubuntu jammy stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

更新软件列表

```
sudo apt update
//可以看到
Get: https://mirrors.aliyun.com/docker-ce/linux/ubuntu jammy InRelease
```

安装Docker（核心）

```
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

启动并设置自启

```
sudo systemctl enable docker
sudo systemctl start docker
```

把当前用户加入Docker组

```
sudo usermod -aG docker $USER
```

然后：

```
reboot
```

查看版本：

```
docker version
```

运行测试容器

```
docker run hello-world
//看到：
Hello from Docker!
```

##### ！！！拉取镜像可能因为网络原因，无法连接到

```
dial tcp 157.240.2.50:443: connect: connection refused
```

`157.240.x.x` = **国外 Docker Hub CDN（Meta / Facebook 段）**

网络：**硬拒绝**

解决方案：

配置国内镜像加速器，配置镜像源，加速访问(默认的 Docker registry 仓库，会超时)

修改 /etc/docker/daemon.json

```
//nano即使没有这个文件也会创建出
sudo nano /etc/docker/daemon.json
```

编辑成：

```
{
	"registry-mirrors": [ "https://docker.m.daocloud.io", 							"https://docker.nju.edu.cn",
	"https://dockerproxy.com"
	],"dns" : [ "114.114.114.114", "8.8.8.8"
	]
}
```

重启docker生效并进行验证：

```
systemctl daemon-reload
systemctl restart docker
//不用 hello-world，直接拉 Ubuntu（更稳）
docker pull docker.m.daocloud.io/library/ubuntu:22.04 ubuntu:22.04
//运行容器
docker run -it ubuntu:22.04 bash
//如果你看到：
root@xxxx:/# //说明Docker已经100%可用了
```

实际用到了：

| 概念             | 你刚刚的操作     |
| ---------------- | ---------------- |
| 镜像（Image）    | `ubuntu:22.04`   |
| 仓库（Registry） | DaoCloud         |
| 拉取镜像         | `docker pull`    |
| 运行容器         | `docker run -it` |
| 交互式终端       | `bash`           |
| 容器 ID          | `add9f18884dc`   |

现在的关系位置

```
root@add9f18884dc:/# 
//现在的环境结构：
Windows
 └─ VMware
    └─ Ubuntu 22.04  ←【宿主机（Host）】
       └─ Docker
          └─ Ubuntu 22.04 容器 ←【你现在在这】
/*说明：
	你已经 进入了一个容器
	这是一个 最小 Ubuntu 用户态
	它 不包含 Docker 引擎，也不包含 docker CLI
	容器的本质就是一个进程
*/
```

使用

```
exit //退出容器
```

查看该镜像的详细信息。

```
docker inspect ubuntu
```

可以提取特定信息（如镜像架构）:

```
docker inspect --format='{{.Architecture}}' ubuntu
```

查看该镜像的构建历史。

```
docker history ubuntu
```

删除该镜像。

```
docker rmi ubuntu
```

