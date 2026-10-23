# Docker + glog + gflags 学习项目

学习如何在 Docker 环境里使用两个 C++ 基础库：

- **[glog](https://github.com/google/glog)**：Google 出品的 C++ 日志库（分级日志、条件日志、断言、日志写文件）
- **[gflags](https://github.com/gflags/gflags)**：命令行参数解析库（`--name=Bob` 这种参数，自动生成 `--help`）

项目包含**两种安装方式**的完整例子：

| 方式 | 文件 | 优点 | 缺点 |
|------|------|------|------|
| ① apt 包管理器安装 | `Dockerfile.apt` | 简单、快、一条命令 | 版本由发行版仓库决定（Ubuntu 24.04 自带 glog 0.6，较老） |
| ② 源码编译安装 | `Dockerfile.source` | 最新版本（glog v0.7.1）、可自定义编译选项 | 构建慢，要装编译工具链 |

两种方式均已在本机实际构建、运行验证通过。

---

## 目录

1. [安装 Docker（超详细教程）](#1-安装-docker超详细教程)
2. [构建和运行示例](#2-构建和运行示例)
3. [玩一玩 gflags：命令行参数](#3-玩一玩-gflags命令行参数)
4. [玩一玩 glog：日志](#4-玩一玩-glog日志)
5. [两种安装方式的原理对比](#5-两种安装方式的原理对比)
6. [编译示例程序的两种写法](#6-编译示例程序的两种写法)
7. [API 速查表](#7-api-速查表)
8. [常见问题](#8-常见问题)
9. [容器内外与 Compose 概念问答](#9-容器内外与-compose-概念问答)
10. [Docker 核心概念与实战避坑指南：挂载、打包与镜像分层](#10-docker-核心概念与实战避坑指南挂载打包与镜像分层)

---

## 1. 安装 Docker（超详细教程）

> 安装只是手段，重点是理解每一步在做什么、为什么。每步都配了讲解，踩过的坑都标了 ⚠️。

### 1.0 先搞懂 Docker 是什么

Docker 是一个容器引擎。装 Docker 本质是装三样东西：

```
你敲的命令 ──► 后台服务 ──► 底层运行时
docker CLI     dockerd       containerd
(客户端)       (守护进程)      (真正跑容器)
```

两个核心概念（后面会反复用到）：

- **镜像（image）**：打包好的只读"文件系统快照"。比如 `ubuntu:24.04` 就是一个装了 Ubuntu 完整文件系统的包。
- **容器（container）**：镜像**运行起来**的实例，在镜像上加了可写层。

两个最有用的类比：

| 类比 | 关系 |
|------|------|
| 镜像 : 容器 = 程序 : 进程 | 镜像是静态的安装包，容器是它运行时的实体 |
| 容器 vs 虚拟机 | 虚拟机要模拟整套硬件+操作系统；容器共享宿主机内核，只隔离文件系统/进程/网络，所以秒级启动、体积小得多 |

### 1.1 安装方式的选择（先看环境）

```bash
cat /etc/os-release | head -2     # 本机: Ubuntu 22.04
```

国内网络的现实情况（本机 2026-10 实测）：

| 地址 | 用途 | 本机能否直连 |
|------|------|:---:|
| `download.docker.com` | Docker 官方安装源 | ❌ 超时 |
| `registry-1.docker.io` | Docker Hub（拉镜像） | ❌ 超时 |
| 阿里云 Ubuntu 源 / github.com | apt 装软件 / 拉源码 | ✅ 正常 |

结论：官方安装源连不上 → 改用 **Ubuntu 自带源里的 docker 包**；Docker Hub 连不上 → **配置国内镜像加速**（1.2 第 3 步）。

### 1.2 安装步骤 + 每一步的讲解

**第 1 步：更新软件源索引**

```bash
sudo apt-get update
```

讲解：`update` 不安装任何东西，只是把软件源里的"软件清单"刷新到最新。仓库有更新才能装到新版本，所以装任何软件前都先 update。

**第 2 步：安装 Docker 引擎 + compose 插件**

```bash
sudo apt-get install -y docker.io docker-compose-v2
```

讲解：
- `docker.io` 是 Ubuntu 源的打包方式，**一个包**就包含 CLI + dockerd + containerd 全套（官方仓库则拆成 docker-ce / docker-ce-cli / containerd.io 三个包）
- `docker-compose-v2` 是 compose 插件，装完才有 `docker compose`（v2 语法）命令
- `-y` = 安装过程中的所有询问自动回答 yes（非交互安装）

**第 3 步：配置镜像加速（国内必做）**

```bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<'EOF'
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://docker.1panel.live"
  ]
}
EOF
```

讲解：
- `daemon.json` 是 dockerd 守护进程的配置文件，固定位置 `/etc/docker/daemon.json`
- `registry-mirrors` 把"拉镜像"的请求转发给镜像站（DaoCloud、1panel 是国内提供 Docker Hub 镜像的公共服务）。不配它，`docker pull` 直连 Docker Hub → 超时
- `tee` 的用法：因为 `sudo echo > 文件` 里重定向不归 sudo 管（还是普通用户权限写），所以用 `sudo tee` 来写需要 root 权限的文件

⚠️ **本机踩坑实录**：写完 daemon.json 没重启就拉镜像，报错：

```
failed to resolve reference "docker.io/library/hello-world:latest":
failed to do request: Head "https://registry-1.docker.io/v2/...": dial tcp ...: i/o timeout
```

原因：dockerd **只在启动时读一次配置**。改配置必须重启服务（下一步）。

**第 4 步：启动服务 + 重启加载配置**

```bash
sudo systemctl enable --now docker   # 启动 + 设为开机自启
sudo systemctl restart docker        # ⚠️ 再重启一次，让 daemon.json 生效
```

讲解：
- dockerd 是后台常驻服务，Linux 上由 systemd 统一管理，`systemctl` 就是操作 systemd 的命令
- `enable` = 开机自动启动；`--now` = 现在顺便启动。等价于 `systemctl enable docker && systemctl start docker`
- `systemctl status docker` 可随时查看状态，看到 `active (running)` 就是正常
- 验证镜像加速已生效：`docker info` 输出里应有 `Registry Mirrors` 两行

**第 5 步：不用 sudo 就能跑 docker**

```bash
sudo usermod -aG docker $USER
```

讲解：
- dockerd 通过 `/var/run/docker.sock`（socket 文件）提供服务，这个文件只允许 root 和 docker 组成员访问——所以普通用户直接跑 `docker` 会报 `permission denied`
- `-aG docker` = 把用户**追加(-a)**进 docker 组。⚠️ **-a 绝对不能漏**：不带 -a 的 `-G` 是"替换成只属于这些组"，会把你从 sudo、adm 等组里踢出去
- 组权限在登录时确定，所以要**退出重新登录**（或 `newgrp docker`）才生效

### 1.3 验证清单（每一步应该看到什么）

```bash
# ① CLI 版本
docker --version        # → Docker version 29.1.3, build ...（本机实测）
docker compose version  # → Docker Compose version 2.40.3（本机实测）

# ② 守护进程是否正常（能看到 Server Version = CLI ↔ daemon 通信正常）
docker info
#   重点看: Registry Mirrors: ["https://docker.m.daocloud.io/", ...]
#          Storage Driver: overlayfs

# ③ 端到端验证：拉镜像 + 建容器 + 运行 + 自动清理
docker run --rm hello-world
# → 输出 "Hello from Docker!" = 全链路正常
```

### 1.4 本机安装实录（真实时间线，含报错）

1. 跑安装脚本：软件装好、服务启动 ✅
2. 第一次 `docker run hello-world`：**拉取超时** ❌（daemon.json 写了但没重启，配置没生效）
3. `sudo systemctl restart docker` 后再跑：✅ Hello from Docker!
4. `usermod -aG docker wxl` 后重新登录：`docker ps` 不再报 permission denied ✅

教训浓缩成一句话：**改完 `/etc/docker/daemon.json` 必须 `sudo systemctl restart docker`**。

### 1.5 卸载 Docker（备用知识）

```bash
sudo apt-get remove -y docker.io docker-compose-v2   # 卸载软件
sudo rm -rf /var/lib/docker                          # 删除所有镜像/容器数据
```

### 附：网络正常的机器用官方仓库安装（版本更新、组件更细）

```bash
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

讲解：先加 Docker 官方 GPG 签名密钥（防止装到被篡改的包），再加官方源，然后安装。五个包里 buildx 是多架构构建工具，官方仓库版还自带镜像加速配置外的新特性，但日常使用和 Ubuntu 源的版本没区别。

---

## 2. 构建和运行示例

### 2.1 项目结构

```
glog-gflags-demo/
├── app/
│   ├── main.cc          # 示例程序：glog 日志 + gflags 参数（逐段中文注释）
│   └── CMakeLists.txt   # CMake 方式编译（源码版镜像用它）
├── Dockerfile.apt       # 方式一：apt 安装
├── Dockerfile.source    # 方式二：源码编译安装
├── docker-compose.yml   # 一键构建/运行两个例子（跑完就退出）
├── docker-compose.dev.yml  # 长期开发容器（一直 Up）
├── dev-start.sh         # 后台启动工作间（已在跑则不重建）
├── dev-into.sh          # 进入，提示符 wxl@in-dev-docker:/docker$
├── dev-stop.sh          # 停下工作间，不删除容器
├── install-docker.sh    # 本机 Docker 安装脚本（国内网络版）
└── README.md
```

### 2.2 一键构建 + 运行（compose）

```bash
cd glog-gflags-demo
docker compose up --build        # 构建并运行两个容器
```

### 2.3 单独构建某个镜像

```bash
# apt 版（1 分钟左右）
docker build -f Dockerfile.apt    -t glog-demo:apt    .

# 源码版（要下载编译 glog/gflags，5~10 分钟，耐心等）
docker build -f Dockerfile.source -t glog-demo:source .
```

### 2.4 运行

```bash
docker run --rm glog-demo:apt      # 默认参数跑一遍
docker run --rm glog-demo:source

# compose 方式（compose build 之后）
docker compose run --rm apt-version
docker compose run --rm source-version
```

### 2.4.1 镜像、容器，以及 compose 的两条命令

`glog-demo:apt` 是镜像名，不是容器名。三者的关系：

| 名字 | 是什么 |
|---|---|
| `Dockerfile.apt` | 制作说明书 |
| `glog-demo:apt` | `docker build -t glog-demo:apt` 按说明书做出来的镜像 |
| 容器 | `docker run glog-demo:apt` 拿这个镜像新开的一份运行实例 |

容器名要自己用 `--name` 指定。不指定的话 Docker 随机起名，例如 `focused_mcclintock`。`docker run --rm` 跑完会删掉这个容器，镜像还在；不加 `--rm` 时，程序退出后容器还在，`docker ps -a` 能看到，状态是 `Exited`。

`docker-compose.yml` 把「用哪个 Dockerfile、镜像叫什么、启动参数是什么」按服务写好了。这里有两个服务：`apt-version` 和 `source-version`。

`docker compose up --build` 对文件里的每个服务做一遍 build 再 run：

- `apt-version` → 构建 `glog-demo:apt`，再启动它的容器，参数是 `--name=APT安装版 --count=3 --alsologtostderr`
- `source-version` → 构建 `glog-demo:source`，再启动它的容器

这两个容器会留下来。示例程序跑完后容器处于退出状态，下次还可以再启动。它和手写的 `docker run glog-demo:apt` 还有一处差别：裸的 `docker run` 用程序默认参数（`name=world`，`count=3`，日志只写文件）；`up` 用的是 yml 里那一组参数。

`docker compose run apt-version` 不是 `up` 的第二步。它只针对 `apt-version` 这一个服务，另外再开一个新容器来跑，用的是 yml 里已经写好的镜像和参数。相当于：

```bash
docker run glog-demo:apt --name=APT安装版 --count=3 --alsologtostderr
```

已经执行过 `up` 的话，不必再执行 `run`。想再跑一遍 apt 这一种、或者临时换成别的命令时，才用 `run`。

### 2.4.2 `--name` 有两个，别写串位置

Docker 的容器名和程序里的 `name` 参数都叫 `--name`，位置不同：

```bash
docker run --name wxl glog-demo:apt --name=Bob --alsologtostderr
#          ^^^^^^^^ Docker 的选项，必须写在镜像名前面
#                                  ^^^^^^^^^ 镜像名后面的全部交给 /app/demo
```

镜像名后面的参数会进容器里的程序。本机实测：

```bash
docker run glog-demo:apt --name wxl
docker ps -a
# COMMAND 是 "/app/demo --name wxl"
# NAMES   仍是 Docker 随机起的 silly_shaw
```

要让 `docker ps` 的名字是 `wxl`，`--name` 写在镜像名前面：

```bash
docker run --name wxl glog-demo:apt
```

程序里的问候名是 gflags 的参数，写在镜像名后面，日志里才会出现 `Hello, Bob!`：

```bash
docker run --name wxl glog-demo:apt --name=Bob --count=3 --alsologtostderr
```

`docker-compose.yml` 里的 `command: ["--name=APT安装版", ...]` 属于后面这一种，传给 `/app/demo`。所以 `docker compose up --build` 之后：

- 日志是 `Hello, APT安装版!`、`Hello, 源码编译版!`
- `docker ps` 的 NAMES 仍是 Compose 自动起的 `glog-gflags-demo-apt-version-1`、`glog-gflags-demo-source-version-1`（目录名 + 服务名 + 序号）

要改 NAMES 那一列，在服务下面加 `container_name`，和 `command` 分开：

```yaml
apt-version:
  image: glog-demo:apt
  container_name: apt-work
  command: ["--name=APT安装版", "--count=3", "--alsologtostderr"]
```

这样容器名是 `apt-work`，程序输出仍是 `Hello, APT安装版!`。

### 2.4.3 项目目录里看不到容器里的文件

在 `glog-gflags-demo` 里 `ls`，看到的是本机源码：`app/`、`Dockerfile.apt`、`docker-compose.yml`。构建时 `COPY app/ /app/` 把代码拷进镜像，这份文件在镜像的 `/app`，本机不会多出一个 Docker 目录。

这个例子的 Dockerfile 和 compose 都没有把本机目录挂进容器。Apollo 一般会把代码目录挂到容器里的 `/apollo`，所以两边看到的是同一份文件；这里改本机的 `main.cc`，已经建好的镜像不会跟着变，要重新 `docker build` 才会拷进去。

看镜像里面：

```bash
docker run -it --entrypoint bash glog-demo:apt
# 提示符变成 root@容器ID:/#
ls /app /usr/include/glog
```

`--entrypoint bash` 把入口从 `/app/demo` 换成 shell。不加它的话，容器一启动就跑完示例程序并退出。

### 2.4.4 和 Apollo 的差别：终端提示符什么时候会变

Apollo 的脚本维持一个一直开着的开发容器。`dev_start.sh` 在后台把它留住，并把本机代码挂进容器；`dev_into.sh` 用 `docker exec` 打开容器里的 bash。当前这个终端就进到容器里了，提示符前面变成容器的主机名（常见是 `in-dev-docker`），工作目录是 `/apollo`。

这个示例的入口是 `/app/demo`，跑完就退出，容器变成 `Exited`。`docker run glog-demo:apt` 期间，你的终端还是本机 zsh，提示符不会变。

| | 这个示例 | Apollo |
|---|---|---|
| 容器活多久 | 程序跑完就退出 | 一个开发容器留在后台 |
| 你的终端 | 还在本机，提示符不变 | `dev_into.sh` 进容器 bash，提示符换成容器里的 |
| 代码在哪 | 构建时 `COPY` 进镜像 | 本机目录挂到容器里 |
| 再进去 | 再 `docker run` 会新开一个容器 | 还是进同一个容器 |

镜像可以随时再开一个容器。Apollo 平时只维持一个开发容器，脚本是进去，不是每次新开一个跑完就停的容器。本项目按同样的方式做了一套，见 2.6，进去后的提示符是 `wxl@in-dev-docker:/docker$`。

### 2.5 本机实测输出（apt 版，传了 --name=Bob --count=3 --alsologtostderr）

```
I20261014 05:08:58.795008     1 main.cc:37] Hello, Bob! (1/3)
I20261014 05:08:58.795233     1 main.cc:37] Hello, Bob! (2/3)
I20261014 05:08:58.795238     1 main.cc:37] Hello, Bob! (3/3)
I20261014 05:08:58.795243     1 main.cc:44] INFO: 普通信息
W20261014 05:08:58.795245     1 main.cc:45] WARNING: 警告
E20261014 05:08:58.795306     1 main.cc:46] ERROR: 错误
I20261014 05:08:58.795362     1 main.cc:61] 每 3 次输出一次: 0
I20261014 05:08:58.795367     1 main.cc:61] 每 3 次输出一次: 3
I20261014 05:08:58.795370     1 main.cc:61] 每 3 次输出一次: 6
I20261014 05:08:58.795373     1 main.cc:61] 每 3 次输出一次: 9
I20261014 05:08:58.795378     1 main.cc:65] Release 编译（-DNDEBUG）时看不到我
[stdout] 剩下的普通参数个数: 0
```

输出格式解读：`I20261014 05:08:58.795008  1  main.cc:37` = 级别(I/W/E/F) + 日期时间 + 线程号 + 文件:行号。

源码版传 `--v=1` 后多出 VLOG 那行（本机实测）：

```
I20261014 05:40:47.829855 129282984603200 main.cc:50] 这条只有 --v=1 或 --v=2 时才显示
```

确认源码版链接的是 `/usr/local` 下自己编译的库（本机实测）：

```bash
docker run --rm --entrypoint sh glog-demo:source -c "ldd /app/demo" | grep -E 'glog|gflags'
#   libglog.so.2 => /usr/local/lib/libglog.so.2
#   libgflags.so.2.2 => /usr/local/lib/libgflags.so.2.2
```

（apt 版同一个命令会显示 `/usr/lib/x86_64-linux-gnu/` 路径，可以自己对比一下）

### 2.6 长期开发容器（按 Apollo 的流程）

2.2 的 `docker compose up --build` 是跑完就退出的示例。这一节是另一个容器：长期开着的工作间，用来反复进去改代码、编译、运行。流程和 Apollo 一样，分三步：启动、进入、在里面干活。Apollo 挂的是 `/apollo`，这里挂的是本机目录 `/home/wxl/docker`，容器里叫 `/docker`。

**1. 启动（对应 Apollo 的 `dev_start.sh`）**

```bash
cd glog-gflags-demo
./dev-start.sh
```

容器名是 `glog-dev`，主进程是 `sleep infinity`，所以它不会自己结束，`docker ps` 里状态是 `Up`。已经在跑时再执行，不会重建；停过之后再执行，拉起的是原来那个容器。

**2. 进入（对应 Apollo 的 `dev_into.sh`）**

```bash
./dev-into.sh
```

当前终端换成容器里的 bash，提示符是：

```text
wxl@in-dev-docker:/docker$
```

| 片段 | 值 | 从哪来 |
|---|---|---|
| `wxl` | 用户名 | `docker exec -u wxl`。镜像自带用户 `ubuntu`（uid 1000，和本机相同），启动脚本用 `usermod` 改名为 `wxl`。普通用户的提示符末尾是 `$` |
| `in-dev-docker` | 主机名 | `docker-compose.dev.yml` 的 `hostname` |
| `/docker` | 当前目录 | 本机 `/home/wxl/docker` 挂到这里。`ls` 能看到 `glog-gflags-demo/` |

`exit` 只离开 bash，容器继续在后台。再执行 `./dev-into.sh` 还是进同一个容器。

**3. 在里面编译运行挂载的源码**

镜像里的 `/app/demo` 是构建镜像时拷进去的那一份，改本机的 `main.cc` 它不会变。工作间里要编译的是挂载目录里的源码：

```bash
cd /docker/glog-gflags-demo/app
g++ main.cc -o /tmp/demo -lglog -lgflags -lpthread
/tmp/demo --name=wxl --count=2 --alsologtostderr
```

这个容器用的是 apt 版镜像，所以 `g++`、头文件和库都已经在里面。改完本机的 `main.cc`，回到容器里重新执行上面两行即可，不用重新 `docker build`。

**停和关机**

```bash
./dev-stop.sh
```

这只是停下，容器还在。关机之后它也会变成 `Exited`，本机 `/home/wxl/docker` 里的文件不受影响。下次 `./dev-into.sh` 发现没在跑，会先启动再进去。

要连容器一起删掉、镜像留下：

```bash
docker compose -f docker-compose.dev.yml down
```

---

## 3. 玩一玩 gflags：命令行参数

示例程序在 `app/main.cc` 顶部定义了 3 个参数：`--name`、`--count`、`--verbose`。

```bash
# 查看自动生成的帮助（gflags 免费送的）
docker run --rm glog-demo:apt --help
```

`--help` 里能看到（本机实测）：

```
  Flags from /app/main.cc:
    -count (问候次数) type: int32 default: 3
    -name (被问候的名字) type: string default: "world"
    -verbose (是否输出更多细节) type: bool default: false
```

传参玩法：

```bash
# 两种传参写法都可以（= 号 或 空格）
docker run --rm glog-demo:apt --name=Bob --count=5
docker run --rm glog-demo:source --name Alice --count 2

# bool 类型：写 --verbose 就是 true
docker run --rm glog-demo:apt --verbose

# 非 flag 的普通参数会留在 argv 里（程序会打印剩余个数）
docker run --rm glog-demo:apt --count=1 hello.txt extra.txt
```

---

## 4. 玩一玩 glog：日志

### 4.1 日志默认写到文件（不是屏幕！）

glog 最重要的特点：**默认把日志写文件**，文件名格式：

```
/tmp/<程序名>.<主机名>.<用户名>.log.<级别>.<时间戳>
```

本示例还调用了 `SetLogDestination`，把 INFO 写到 `/tmp/demo_info_*`。

实测容器内 `/tmp` 的文件（本机验证）：

```
demo_info_20261014-050923.1        ← SetLogDestination 指定的 INFO 文件
demo.a409be...root.log.WARNING.xxx  ← 默认格式的 WARNING 文件
demo.a409be...root.log.ERROR.xxx    ← 默认格式的 ERROR 文件
demo.INFO / demo.WARNING / demo.ERROR  ← 指向"最新一个"的符号链接
```

### 4.2 三个控制输出的 flag（glog 自带）

| flag | 作用 |
|------|------|
| `--logtostderr` | 日志只打屏幕，不写文件 |
| `--alsologtostderr` | 文件照写，同时打屏幕（示例 compose 里用的这个） |
| `--v=N` | 打开 N 级及以下的 VLOG 详细日志 |

```bash
docker run --rm glog-demo:apt --alsologtostderr   # 边跑边看
docker run --rm glog-demo:source --v=1 --alsologtostderr   # 打开 VLOG
```

### 4.3 查看容器里的日志文件

示例程序瞬间跑完就退出，所以用 `docker cp` 从停止的容器里取文件：

```bash
docker run --name demo-log glog-demo:apt --count=2
docker cp demo-log:/tmp/. ./demo-logs/     # 把容器 /tmp 拷出来
cat ./demo-logs/demo_info_*                # 看日志内容
docker rm demo-log
```

---

## 5. 两种安装方式的原理对比

### 5.1 方式一：apt 安装（Dockerfile.apt）

```dockerfile
RUN apt-get install -y libgoogle-glog-dev libgflags-dev
```

- 头文件装到 `/usr/include/glog/`、`/usr/include/gflags/`
- 库文件装到 `/usr/lib/x86_64-linux-gnu/`（系统默认搜索路径，**不需要** ldconfig）
- 编译时 `-lglog -lgflags` 直接能找到
- `dev` 包 = 头文件 + 库文件；不带 dev 的包只有运行库

### 5.2 方式二：源码安装（Dockerfile.source）

```bash
git clone --branch v0.7.1 https://github.com/google/glog.git
cmake -S glog -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
cmake --install build          # 装到 /usr/local
```

- 头文件装到 `/usr/local/include/`，库装到 `/usr/local/lib/`
- 因为不在系统默认搜索路径，装完要 `ldconfig` 刷新动态库缓存
- 学习价值：这就是 CMake 项目的标准安装三件套（configure → build → install）
- Dockerfile 里用 `--branch v2.2.2` / `--branch v0.7.1` 钉住版本，保证构建可复现

---

## 6. 编译示例程序的两种写法

**写法 A：g++ 手动链接**（`Dockerfile.apt` 里用的，最直观）

```bash
g++ main.cc -o demo -lglog -lgflags -lpthread
```

**写法 B：CMake**（`Dockerfile.source` 里用的，真实项目的标准做法）

```cmake
find_package(glog REQUIRED)
find_package(gflags REQUIRED)
target_link_libraries(demo PRIVATE glog::glog gflags)
```

两种方式装的库都自带 cmake 配置文件，所以 `find_package` 都能找到。

---

## 7. API 速查表

### glog

| 用法 | 说明 |
|------|------|
| `LOG(INFO)` / `LOG(WARNING)` / `LOG(ERROR)` / `LOG(FATAL)` | 四级日志，FATAL 输出后程序退出 |
| `VLOG(n)` | 详细日志，`--v=n` 控制显示 |
| `LOG_IF(INFO, cond)` | 条件成立才输出 |
| `LOG_EVERY_N(INFO, n)` | 每 n 次输出一次 |
| `CHECK(cond)` / `CHECK_EQ` / `CHECK_GT` | 断言，失败报错退出（Release 也生效） |
| `DLOG(INFO)` | 只在 Debug 编译（未定义 NDEBUG）下生效 |
| `google::InitGoogleLogging(argv[0])` | 初始化（写日志前必须调用） |
| `google::SetLogDestination(google::INFO, "/tmp/xxx_")` | 指定日志文件前缀 |
| `google::ShutdownGoogleLogging()` | 退出前清理 |

### gflags

| 用法 | 说明 |
|------|------|
| `DEFINE_string` / `DEFINE_int32` / `DEFINE_bool(名字, 默认值, "帮助")` | 定义参数，得到 `FLAGS_名字` |
| `gflags::ParseCommandLineFlags(&argc, &argv, true)` | 解析命令行（true = 把 flag 从 argv 移除） |
| `./demo --help` | 自动生成帮助 |
| `./demo --name=Bob` 或 `--name Bob` | 两种传参写法 |

---

## 8. 常见问题

- **`docker run` 报 permission denied？** 用户还没加入 docker 组，或加了没重新登录。执行 `sudo usermod -aG docker $USER` 后退出重新登录（或 `newgrp docker`）。
- **容器里 `git clone` 报 `server certificate verification failed. CAfile: none`？** 基础镜像是最小系统，不带 CA 证书包，`apt-get install ca-certificates` 即可（`Dockerfile.source` 已修复，本机实际踩过的坑）。
- **源码编译 glog 时链接报 `recompile with -fPIC`？** gflags 默认只编静态库且不带位置无关代码（-fPIC），glog 编译动态库时链接它会报错。gflags 配置时加 `-DBUILD_SHARED_LIBS=ON -DCMAKE_POSITION_INDEPENDENT_CODE=ON`（`Dockerfile.source` 已修复，本机实际踩过的坑）。
- **改了 daemon.json 但镜像加速不生效？** 必须 `sudo systemctl restart docker`，只改配置不重启等于没改（本机实际踩过的坑）。
- **拉镜像超时 `dial tcp ... i/o timeout`？** Docker Hub 被墙，检查 `docker info` 里的 Registry Mirrors 是否已配置国内镜像站。
- **为什么链接还要加 `-lpthread`？** glog 内部用到了 pthread。新版 glibc 已合并线程库，不加也能过，但写上最保险。
- **源码安装后编译报找不到库？** 先 `ldconfig`；或编译时加 `-L/usr/local/lib`、CMake 加 `-DCMAKE_PREFIX_PATH=/usr/local`。
- **日志文件找不到？** 默认在 `/tmp` 下，文件名包含主机名和用户名；加了 `--logtostderr` 就不会写文件。
- **想要最新版 glog？** apt 仓库更新慢，用源码方式并改 `Dockerfile.source` 里的 `--branch` 版本号即可。

---

## 9. 容器内外与 Compose 概念问答

### 9.1 为什么在容器里跑 `./dev-stop.sh` 会报 `docker: command not found`

先看提示符，这是判断"我在哪"的第一线索：

```
⚡➜ glog-gflags-demo ./dev-into.sh     ← 宿主机上的 zsh 提示符
wxl@in-dev-docker:/docker$             ← 已经进到容器里了！
```

`in-dev-docker` 是容器的 hostname（`docker-compose.dev.yml` 里 `hostname:` 设的）。`dev-into.sh` 最后一行是 `docker exec -it ... glog-dev bash`——它把终端**送进了容器里面**。

而 `dev-stop.sh` 要执行的是 `docker compose ... stop`。docker 命令是用来**从外面操控容器**的，只装在宿主机上；容器镜像是用 `Dockerfile.apt` 构建的，里面只装了 glog/gflags 开发环境，**没有装 docker**。在容器里跑它，就相当于让容器自己用 docker 停自己——它根本没有 docker 这个命令。

整条依赖链：

```
宿主机
 ├─ docker 命令（CLI）            ← dev-*.sh 调的就是它
 │    ├─ docker build / run / exec / stop        ← 直接子命令
 │    └─ docker compose（插件 docker-compose-v2）← 读 YAML，再翻译成上面的命令
 └─ dockerd（守护进程，真正干活的）

容器里：docker、docker compose 都不存在
```

**规则：三个 dev 脚本（start / into / stop）都在宿主机终端跑，容器里只做开发**（编译、跑 demo）。在容器里误跑了停止脚本，`exit` 退出来，在宿主机上重新跑即可。

顺带解释一个容易困惑的点：为什么容器里 `ls` 能看到这些脚本？因为 `docker-compose.dev.yml` 把宿主机 `/home/wxl/docker` 挂载到了容器的 `/docker`——看到的是**同一个目录**（bind mount），不是容器里的副本，所以改文件两边同步。

### 9.2 Dockerfile 和 compose 文件的分工

| | Dockerfile（`Dockerfile.apt` / `Dockerfile.source`） | compose 文件（`docker-compose.yml` / `docker-compose.dev.yml`） |
|---|---|---|
| 作用 | 构建**镜像**的菜谱：基础镜像、装什么包、怎么编译 | 编排**容器**怎么跑：用哪个镜像、容器名、挂载、入口命令 |
| 产物 | 镜像（`glog-demo:apt`、`glog-demo:source`） | 运行中的容器（`glog-dev`） |
| 用法 | 被 compose 引用（`dockerfile:` 字段），或 `docker build` | `docker compose -f xxx.yml up/stop` |

打个比方：**Dockerfile 是菜谱（怎么做菜），compose 文件是点菜单（哪些菜、怎么上）**。

项目里的两对文件其实是两个维度的变体：

- **两个 Dockerfile** = 同一道菜两种做法：`Dockerfile.apt` 用 `apt install` 装 glog/gflags，`Dockerfile.source` 从源码编译（`docker-compose.dev.yml` 的 `dockerfile:` 就指定了用 apt 版构建开发容器）。
- **两个 compose 文件** = 两种使用场景：`docker-compose.yml` 的两个示例服务**跑完 demo 就退出**，用来验证镜像；`docker-compose.dev.yml` 的长期开发容器主进程是 `sleep infinity` 不会退出，挂载了代码目录，日常开发用。

### 9.3 compose = 把 docker 命令的参数写进 YAML

以 `docker-compose.dev.yml` 为例，`docker compose up -d --build` 展开来就等价于这两条：

```bash
# 1. build 阶段：根据 Dockerfile 构建镜像
docker build -f Dockerfile.apt -t glog-demo:apt .

# 2. run 阶段：用一堆参数启动容器
docker run -d --name glog-dev --hostname in-dev-docker \
  -w /docker -v /home/wxl/docker:/docker \
  --entrypoint sleep glog-demo:apt infinity
```

compose 做的就是：把 `-v`、`--name`、`--hostname`、`--entrypoint` 这些参数**写进 YAML 声明出来**，而不是每次手敲一大串。`docker compose stop` 同理——它记得当初的配置，不用记容器名。

另外注意，`docker compose` **不是独立的程序，是 docker 命令的子命令**（装的 `docker-compose-v2` 是插件，挂在 docker CLI 下面）。所以容器里报错是 `docker: command not found`——连 `docker` 都没有，`docker compose` 自然也不存在。

**总结**：compose 不是"另一个东西"，就是"docker 命令的 YAML 化快捷方式"，但执行入口仍是宿主机上的 `docker` CLI。

### 9.4 常用 compose 命令速查

大部分是 docker 原生命令的"项目版"：

| 命令 | 作用 | 对应原生 docker |
|---|---|---|
| `docker compose up` | 创建（需要的话）+ 启动所有服务，`-d` 后台、`--build` 强制重新构建镜像 | `docker build` + `docker run` |
| `docker compose stop` | 停止容器，**容器保留**（下次 `start` 恢复） | `docker stop` |
| `docker compose start` | 启动已存在但停着的容器 | `docker start` |
| `docker compose down` | 停止**并删除**容器和网络（`-v` 连数据卷一起删） | `docker stop` + `docker rm` |
| `docker compose ps` | 查看本项目的容器状态 | `docker ps` |
| `docker compose logs` | 看容器输出日志，`-f` 实时跟踪 | `docker logs` |
| `docker compose build` | 只构建镜像，不启动 | `docker build` |
| `docker compose exec` | **进入已在跑的容器**里执行命令 | `docker exec` |
| `docker compose run` | **新起一个一次性容器**执行命令，用完即弃 | `docker run` |
| `docker compose config` | 打印合并后的最终配置——学习/排错神器 | 无 |

### 9.5 容易混的三个点

**1. `exec` vs `run`**（新手经典坑）：

```bash
docker compose exec dev bash   # 进"现有"的 glog-dev 容器（类比 dev-into.sh）
docker compose run dev bash    # 按配置"另起"一个新容器进去，跑完退出就没了
```

`dev-into.sh` 用的是 `docker exec`（原生版），所以每次进去都是**同一个** glog-dev，改的文件都在。用 `run` 的话每次都是全新容器，文件就丢了。

**2. `up` vs `start`**：

- `up` = 容器不存在就**创建**，存在就启动（幂等）
- `start` = 只启动**已存在**的容器，不存在会报错

`dev-start.sh` 就在手动区分这两种情况：容器存在但停了 → `docker start`；不存在 → `docker compose up -d --build`。如果无脑用 `up`，配置文件改过（比如改了挂载路径）会重建容器丢状态，所以脚本里才写分支。

**3. `-f` 参数别漏**：

compose 默认只认当前目录下的 `docker-compose.yml`（或 `compose.yml`）。`docker-compose.dev.yml` 不是默认名，所以 `dev-stop.sh` 里必须写：

```bash
docker compose -f docker-compose.dev.yml stop
```

漏了 `-f` 的话 compose 会去找默认文件——那停的就是两个示例服务，而不是 glog-dev 了。

---

## 10. Docker 核心概念与实战避坑指南：挂载、打包与镜像分层

在使用 Docker 进行项目开发与交付时，厘清 **Host（宿主机）**、**容器（Container）** 和 **镜像（Image）** 之间的文件与存储关系是至关重要的。以下是核心知识点总结。

---

### 10.1 什么是“Host 目录”与“挂载（Bind Mount）”？

- **Host（宿主机）**：运行 Docker 引擎的真实物理机或云服务器（例如你自己的个人电脑）。
- **Host 目录**：宿主机硬盘上的某个真实文件夹。

默认情况下，Docker 容器内部是完全隔离的。为了让容器能读取宿主机的代码，或将产生的数据保存在宿主机上，我们使用 **Bind Mount（绑定挂载）** 技术。

- **机制**：在启动容器时（如通过 `docker run -v /host/dir:/container/dir`），在容器内部开一扇“任意门”，直接映射到宿主机的硬盘目录。

#### 📌 视觉错觉 vs 物理真相

- **视觉错觉**：“Host 里有一份代码，Docker 内部也有一份代码，两边会自动双向同步。”
- **物理真相**：**硬盘上从头到尾只有 1 份物理数据。** 容器内部根本没有为这些文件分配存储空间，它只是通过内核挂载技术，直接读取和修改 Host 硬盘上的文件。因此，“一边改了另一边立刻生效”的本质是因为大家看的是同一个物理文件。

#### 🌟 经典应用：百度 Apollo 开发模式

- **代码在 Host**：开发者在宿主机上用顺手的编辑器写代码，代码保存在宿主机。
- **环境在 Docker**：启动包含极其复杂编译环境（如特定的 C++、ROS、Bazel 环境）的容器。
- **结合方式**：将 Host 的代码目录挂载进容器。容器负责编译，开发者在外部负责写代码，完美解耦。

---

### 10.2 空间占用与代码导入方式对比

代码进入容器主要有三种方式，它们在物理空间的占用上有着本质区别：

| 方式 | 应用场景 | 物理存储占用 | 解释 |
| :--- | :--- | :--- | :--- |
| **挂载 (Bind Mount)** | **本地日常开发** | **1 份空间** | 容器不占用额外空间，直接读写 Host 硬盘上的源文件。 |
| **构建 (Dockerfile COPY)** | **正式打包交付** | **2 份空间** | Host 硬盘保留原代码；Docker 会把代码“复制”并固化进 Image 的内部存储层中。两者完全独立。 |
| **拷贝 (`docker cp`)** | **临时运行调试** | **2 份空间** | 类似于用 U 盘拷贝。把 Host 上的代码硬塞进正在运行的容器内部。两者独立，极少用于正式交付。 |

---

### 10.3 实战打法切换：开发环境 vs 交付环境

很多人在从“本地开发”过渡到“给客户发版本”时容易踩坑，核心在于两套打法的切换：

#### 1. 开发阶段（挂载模式）

- **做法**：使用 `-v` 挂载 Host 目录。
- **优势**：改完代码立刻生效，无需反复构建镜像，效率极高。

#### 2. 交付阶段（打包模式）

- **🚨 致命陷阱**：千万不要直接用 `docker commit` 把挂载状态的容器拍快照发给客户！**`docker commit` 不会把挂载的 Host 文件拍进去**，客户拿到的镜像里根本没有你的代码。
- **✅ 正确做法**：停止挂载，编写 `Dockerfile`，使用 `COPY ./code /app/code` 命令，将代码真正封装进镜像内部，然后将打好的新 Image 交付给客户。

---

### 10.4 镜像的修改与构建：Commit vs Dockerfile

当你发现现有的镜像缺少某些依赖（如 `python3`、`vim`）时，该如何处理？

#### ❌ 错误做法：黑盒操作 (`docker commit`)

进入容器 -> 手动 `apt-get install` -> 退出容器 -> `docker commit` 打包。

- **缺点**：产出的是一个“黑盒”镜像。时间一久，没人知道里面装了什么，无法重现，极难维护。

#### ✅ 推荐做法：白盒构建 (`Dockerfile`)

创建一个 `Dockerfile`：

```dockerfile
FROM ubuntu:20.04
RUN apt-get update && apt-get install -y python3 vim
COPY ./my_code /app/my_code
CMD ["python3", "/app/my_code/main.py"]
```
