#!/usr/bin/env bash
# monitoring/deploy.sh — 把 monitoring 套件的系統檔冪等部署到本機。
# 在「目標機器」上執行（需 sudo）。這是 stow 管不到的系統層（/etc、/usr/local）的部署橋。
#
# 用法（在目標機的 dotfiles clone 裡）：
#   sudo ./monitoring/deploy.sh
#
# 冪等：重跑不會壞。安裝告警基礎件（notifier + alert@ handler + topic）並依
# hooks/units.txt 把 OnFailure 掛到指定的 service。
set -Eeuo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

# --- 告警基礎件 ---
install -Dm755 "$HERE/bin/notify-failure"      /usr/local/bin/notify-failure
install -Dm644 "$HERE/system/alert@.service"   /etc/systemd/system/alert@.service

# topic 是私密值：只在不存在時放佔位，不覆蓋已填好的真值
if [[ ! -f /etc/svc-alert-topic ]]; then
  install -Dm600 "$HERE/svc-alert-topic.example" /etc/svc-alert-topic
  echo "[deploy] /etc/svc-alert-topic 建了佔位，記得填真正的 topic：echo '<topic>' | sudo tee /etc/svc-alert-topic"
fi

# --- 依 hooks/units.txt 把 OnFailure 掛到指定 service（宣告式）---
if [[ -f "$HERE/hooks/units.txt" ]]; then
  while IFS= read -r line; do
    unit="${line%%#*}"                      # 剝行內註解
    unit="$(echo "$unit" | xargs)"          # trim 空白
    [[ -z "$unit" ]] && continue
    install -Dm644 "$HERE/hooks/onfailure.conf" "/etc/systemd/system/${unit}.d/onfailure.conf"
    echo "[deploy] hooked $unit → alert@"
  done < "$HERE/hooks/units.txt"
fi

systemctl daemon-reload
echo "[deploy] done：notify-failure + alert@.service + hooks 已就緒"
