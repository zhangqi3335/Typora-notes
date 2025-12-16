# Ubuntu 22.04

### 这个版本的的优势

#### 1️⃣ 交叉编译工具链最稳

嵌入式离不开：

- `arm-none-eabi-gcc`
- `openocd`
- `cmake`
- `make`
- `gdb-multiarch`

在 Ubuntu 22.04：

```
sudo apt install gcc-arm-none-eabi openocd cmake gdb-multiarch
```

 ✔ 版本成熟
 ✔ 文档多
 ✔ 博客 / CSDN / 官方教程 **默认 22.04**

#### 2️⃣ 厂商官方文档基本都默认 22.04

| 厂商 / 工具             | 官方推荐             |
| ----------------------- | -------------------- |
| ST（STM32CubeMX / CLI） | Ubuntu 20.04 / 22.04 |
| OpenOCD                 | 22.04                |
| Yocto                   | 22.04                |
| NXP SDK                 | 22.04                |
| 正点原子 / 野火         | 20.04 / 22.04        |

#### 3️⃣ USB / 串口 / 权限问题最少

- 用 USB-TTL
- 用 ST-Link
- 用 `/dev/ttyUSBx`
- 用 `/dev/ttyACMx`

22.04：

- `udev` 规则成熟
- `dialout` 组稳定
- 博客解决方案全

```
sudo usermod -aG dialout $USER
```

### 预装虚拟机镜像

```
//这类镜像的特点是系统已经装好了
.ova
.ovf
.vmdk
```

### Docker

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



### 常用命令行操作

##### 切换用户权限

```
sudo -i //切换为root

```

##### 查看系统版本

方法一：

```
lsb_release -a
```

输出：

```
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 22.04.5 LTS
Release:	22.04
Codename:	jammy
```

方法二：

```
cat /etc/os-release
```

输出：

方法三：

```
uname -a
```

输出：

```
Linux xiaozai-virtual-machine 6.8.0-90-generic #91~22.04.1-Ubuntu SMP PREEMPT_DYNAMIC Thu Nov 20 15:20:45 UTC 2 x86_64 x86_64 x86_64 GNU/Linux
```



##### 让虚拟机和物理机进行复制黏贴

打开终端（快捷键：ctrl+Alt+T）：

```
sudo apt update //可以不输入
sudo apt install -y open-vm-tools open-vm-tools-desktop //这个是重点
```

安装完成后：

```
reboot
```

开机检查是否成功

```
vmware-toolbox-cmd -v 
//能输出版本号就成功
```

