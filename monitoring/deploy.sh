#!/usr/bin/env bash
# monitoring/deploy.sh — 把 monitoring 套件的系統檔冪等部署到本機。
# 在「目標機器」上執行（需 sudo）。這是 stow 管不到的系統層（/etc、/usr/local）的部署橋。
#
# 用法（在目標機的 dotfiles clone 裡）：
#   sudo ./monitoring/deploy.sh
#
# 冪等：重跑不會壞。只安裝可複用的告警基礎件（notifier + alert@ handler + topic 佔位）。
# 「哪些 service 要被監控」由你自己加 OnFailure（見 README），deploy 不替你決定。
set -Eeuo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

install -Dm755 "$HERE/bin/notify-failure"      /usr/local/bin/notify-failure
install -Dm644 "$HERE/system/alert@.service"   /etc/systemd/system/alert@.service

# topic 是私密值：只在不存在時放佔位，不覆蓋已填好的真值
if [[ ! -f /etc/svc-alert-topic ]]; then
  install -Dm600 "$HERE/svc-alert-topic.example" /etc/svc-alert-topic
  echo "[deploy] /etc/svc-alert-topic 建了佔位，記得填真正的 topic：echo '<topic>' | sudo tee /etc/svc-alert-topic"
fi

systemctl daemon-reload
echo "[deploy] done：notify-failure + alert@.service 已就緒"
echo "[deploy] 要監控某個 service，加一行 OnFailure=alert@%n.service（見 monitoring/README.md）"
