#!/usr/bin/env bash
# monitoring/demo/deploy.sh — 部署 demo health canary（監控靶子）。在目標機以 sudo 執行。
# 依賴核心監控（alert@ + notify-failure）：先跑過 monitoring/deploy.sh。
set -Eeuo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

if [[ ! -f /etc/systemd/system/alert@.service ]]; then
  echo "缺 alert@ handler，先跑 monitoring/deploy.sh" >&2
  exit 1
fi

install -Dm755 "$HERE/health-server.py"           /usr/local/lib/demo-health/health-server.py
install -Dm644 "$HERE/demo-health.service"        /etc/systemd/system/demo-health.service
install -Dm644 "$HERE/demo-health-check.service"  /etc/systemd/system/demo-health-check.service
install -Dm644 "$HERE/demo-health-check.timer"     /etc/systemd/system/demo-health-check.timer

systemctl daemon-reload
systemctl enable --now demo-health.service
systemctl enable --now demo-health-check.timer

echo "[deploy] demo-health canary 啟動（127.0.0.1:8899/health）"
echo "[deploy] health-check timer 每 2 分鐘輪詢；測試：curl /crash（進程死）或 /hang（進程活著不回應）"
