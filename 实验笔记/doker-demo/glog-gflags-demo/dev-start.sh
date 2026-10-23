#!/bin/bash
# 后台启动长期开发容器 glog-dev。对应 Apollo 的 dev_start.sh。
# 容器已经在跑就什么都不重建；停了就 docker start；没有才创建。
# 主进程是 sleep infinity，所以 docker ps 里会一直是 Up。
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

ensure_dev_user() {
  local DEV_USER DEV_UID DEV_GID
  DEV_USER="${SUDO_USER:-$USER}"
  DEV_UID="$(id -u "$DEV_USER")"
  DEV_GID="$(id -g "$DEV_USER")"
  # Ubuntu 24.04 镜像自带用户 ubuntu，uid 正好是 1000。
  # 提示符用的是用户名，所以把这个 uid 改名为本机用户，显示出来才是 wxl。
  docker exec -u root glog-dev bash -lc "
    current=\$(getent passwd '$DEV_UID' | cut -d: -f1)
    if [ -n \"\$current\" ] && [ \"\$current\" != '$DEV_USER' ]; then
      usermod -l '$DEV_USER' -d /home/'$DEV_USER' -m \"\$current\"
    elif ! id -u '$DEV_USER' >/dev/null 2>&1; then
      if ! getent group '$DEV_GID' >/dev/null; then
        groupadd -g '$DEV_GID' '$DEV_USER'
      fi
      useradd -m -u '$DEV_UID' -g '$DEV_GID' -s /bin/bash '$DEV_USER'
    fi
  "
}

start_dev() {
  if docker inspect glog-dev >/dev/null 2>&1; then
    if docker inspect -f '{{.State.Running}}' glog-dev | grep -qx true; then
      echo "glog-dev 已在运行，不重建"
    else
      echo "glog-dev 已停止，重新启动原来的容器"
      docker start glog-dev >/dev/null
    fi
  else
    docker compose -f docker-compose.dev.yml up -d --build
  fi
  ensure_dev_user
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  start_dev
  echo
  docker ps --filter name=glog-dev
  echo
  echo "容器已在后台。进入终端: ./dev-into.sh"
fi
