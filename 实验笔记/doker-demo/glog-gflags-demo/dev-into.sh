#!/bin/bash
# 进入已经在后台的开发容器。对应 Apollo 的 dev_into.sh。
# 当前终端会换成容器里的 bash，提示符变成 wxl@in-dev-docker:/docker$
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=dev-start.sh
source ./dev-start.sh

DEV_USER="${SUDO_USER:-$USER}"

if ! docker inspect -f '{{.State.Running}}' glog-dev >/dev/null 2>&1 \
   || ! docker inspect -f '{{.State.Running}}' glog-dev | grep -qx true; then
  echo "glog-dev 还没在跑，先启动"
  start_dev
else
  ensure_dev_user
fi

exec docker exec -it -u "$DEV_USER" -w /docker glog-dev bash
