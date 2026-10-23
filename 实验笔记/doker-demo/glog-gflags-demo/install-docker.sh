#!/usr/bin/env bash
# ============================================================
# 在 Ubuntu 上安装 Docker（docker.io + docker-compose-v2）
#
# 本机是国内网络环境，所以做了两件事:
#   1. 用 Ubuntu 自带源安装（download.docker.com 官方源连不上）
#   2. 配置 DaoCloud 镜像加速（Docker Hub 直接访问不了）
#
# 用法: sudo bash install-docker.sh
# ============================================================
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "请用 root 身份运行: sudo bash $0"
  exit 1
fi

echo '==> [1/5] 更新软件源'
apt-get update

echo '==> [2/5] 安装 docker.io 和 docker-compose-v2'
#   docker.io           = Docker 引擎
#   docker-compose-v2   = docker compose 子命令（新版 compose 插件）
apt-get install -y docker.io docker-compose-v2

echo '==> [3/5] 配置国内镜像加速'
# Docker Hub 在国内无法直连，拉取镜像走 DaoCloud 镜像站
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<'EOF'
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://docker.1panel.live"
  ]
}
EOF

echo '==> [4/5] 启动 Docker 服务并设为开机自启'
systemctl enable --now docker
# 关键: daemon.json 是在服务启动之后才写入的，必须重启一次配置才会生效
systemctl restart docker

echo '==> [5/5] 把用户加入 docker 组（之后不用 sudo 就能用 docker）'
REAL_USER=${SUDO_USER:-$(logname 2>/dev/null || echo '')}
if [ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ]; then
  usermod -aG docker "$REAL_USER"
  echo "已把 $REAL_USER 加入 docker 组"
  echo "注意: 需要退出登录重新登录（或执行 newgrp docker）才生效"
fi

echo '==> 安装完成，版本信息:'
docker --version
docker compose version

echo '==> 验证: 运行 hello-world（首次会从镜像站拉取，稍等）'
docker run --rm hello-world
