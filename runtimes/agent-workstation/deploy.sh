#!/usr/bin/env bash
# 冪等部署：build image、scaffold .env 佔位（只在不存在時）、建 work/。
# 真值（token）不由本腳本寫入——見 README「一次性認證」手動填。
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> build agent-workstation:v1"
docker build -t agent-workstation:v1 "$DIR"

if [ ! -f "$DIR/.env" ]; then
  cp "$DIR/.env.example" "$DIR/.env"
  chmod 600 "$DIR/.env"
  echo "==> 已建 .env 佔位（600）。填入 token：見 README「一次性認證」。"
else
  echo "==> .env 已存在、不覆蓋。"
fi

mkdir -p "$DIR/work"
chmod +x "$DIR"/run-agent.sh "$DIR"/claude-shell.sh
echo "==> 完成。認證後即可用 ./claude-shell.sh 或 ./run-agent.sh。"
