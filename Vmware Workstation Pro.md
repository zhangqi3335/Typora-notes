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

### 常用相关软件使用

#### Putty

作为对于没有桌面系统的server镜像来说非常好用

先在虚拟机中输入 

```
 ip a  
 //在ens33 或者 ens0 可以看见inet 后面跟着的就是虚拟机的ip地址
```

- putty中用鼠标右键就直接可以黏贴
- 然后在putty中进行复制操作，就可以把拉动鼠标，光标圈住的内容直接就在复制框中，Ctrl+V就可以直接进行复制

#### Winscp

作为物理机和虚拟机之间的文件传输十分好用

只需要先在虚拟机中输入 

```
 ip a  
 //在ens33 或者 ens0 可以看见inet 后面跟着的就是虚拟机的ip地址
```

输入ip，用户名以及密码就可以直接进行文件传输了，记得保存可以保存用户名的密码，避免下次还要重新输入

**传递文件时权限不够：**

![image-20251226210526043](C:\Users\17820\AppData\Roaming\Typora\typora-user-images\image-20251226210526043.png)

```bash
//使用时R必须大写
sudo chmod -R 777 /usr/具体文件   
```

**`chmod`是用于更改文件或目录权限的命令。`-R`选项表示递归操作，即对目录及其所有子目录和文件都应用相同的权限更改。`777`代表所有用户（所有者、所属组和其他用户）对该文件夹都具有读、写和执行权限。**



### 常用命令行操作

##### 切换用户权限

```bash
sudo -i //切换为root
```

##### 查看系统版本

方法一：

```
lsb_release -a
```

输出：

```bash
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 22.04.5 LTS
Release:	22.04
Codename:	jammy
```

方法二：

```bash
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



##### 查看虚拟机的IP地址

**ip a    (ip addr)**：

![image-20251226205844584](C:\Users\17820\AppData\Roaming\Typora\typora-user-images\image-20251226205844584.png)

如果只想查看某个特定网络接口（如 `eth0` 或 `ens33` ）的 IP 地址，可以使用 `ip addr show dev <interface - name>` 。例如，要查看 `ens33` 接口的 IP 地址，输入 `ip addr show dev ens33` 。

![image-20251226205945460](C:\Users\17820\AppData\Roaming\Typora\typora-user-images\image-20251226205945460.png)

**hostname -I**：

该命令会显示当前主机的所有 IP 地址，简单直接。在终端输入 `hostname -I` ，输出结果类似 `192.168.1.100 127.0.0.1` ，会列出所有网络接口的 IP 地址。

![image-20251226210111091](C:\Users\17820\AppData\Roaming\Typora\typora-user-images\image-20251226210111091.png)



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



##### 开启ubuntu虚拟机的SSH服务

```
# 1. 更新软件源（确保安装最新版本，可选但建议执行）
sudo apt update -y

# 2. 安装openssh-server（核心依赖）
sudo apt install -y openssh-server

# 3. 启动SSH服务
sudo systemctl start ssh

# 4. 设置开机自启（避免重启虚拟机后服务失效）
sudo systemctl enable ssh

# 5. 关闭防火墙（实验环境推荐，避免拦截22端口）
sudo ufw disable

# 6. 检查SSH服务状态（确认运行）
sudo systemctl status ssh
```

- 执行后若输出 `active (running)`，说明 SSH 服务正常启动（按Q退出）；
- 若提示 `ufw: command not found`，说明未安装防火墙，可忽略该命令。

如果虚拟机版本为14.04及以下

##### 低版本 Ubuntu（14.04/12.04）管理 SSH 服务的命令

1. 安装 openssh-server（核心步骤不变）

```bash
sudo apt update -y
sudo apt install -y openssh-server
```

2. 启动 SSH 服务（替换 systemctl）

```bash
sudo service ssh start
```

3. 设置开机自启（避免重启虚拟机后服务失效）

```bash
sudo update-rc.d ssh defaults
```

4. 检查 SSH 服务状态（确认运行）

```bash
sudo service ssh status
```

- 正常输出示例：`ssh start/running, process 1234`（显示 start/running 即启动成功）。

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

