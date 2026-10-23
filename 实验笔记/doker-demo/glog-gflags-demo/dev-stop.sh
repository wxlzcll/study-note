#!/bin/bash
# 停下开发容器，不删除。对应关掉工作间，下次 ./dev-start.sh 还是原来那个。
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
docker compose -f docker-compose.dev.yml stop
echo "glog-dev 已停止。容器还在，下次 ./dev-start.sh 或 ./dev-into.sh 会把它拉起来。"
