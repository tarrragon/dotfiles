#!/usr/bin/env bash
# monitoring/desktop/deploy.sh — 部署桌面通知訂閱（user systemd 服務）。
# 以「一般使用者」執行、不要 sudo（user service + notify-send 都在你的 session 裡）。
#
# 用法（在目標機的 dotfiles clone 裡、用你自己的帳號）：
#   ./monitoring/desktop/deploy.sh
#
# 需要：jq、libnotify（notify-send）、session 內有通知 daemon（如 mako）。
set -Eeuo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
: "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"; export XDG_RUNTIME_DIR

mkdir -p "$HOME/.local/bin" "$HOME/.config/systemd/user" "$HOME/.config/svc-alert"
install -m755 "$HERE/ntfy-desktop-sub"    "$HOME/.local/bin/ntfy-desktop-sub"
install -m644 "$HERE/ntfy-desktop.service" "$HOME/.config/systemd/user/ntfy-desktop.service"

# topic：沿用已有的；否則從 /etc（若讀得到）；否則放佔位要你手填
if [ ! -s "$HOME/.config/svc-alert/topic" ]; then
  if [ -r /etc/svc-alert-topic ]; then
    cp /etc/svc-alert-topic "$HOME/.config/svc-alert/topic"
  else
    echo "CHANGE-ME" > "$HOME/.config/svc-alert/topic"
    echo "[deploy] 填 topic：echo '<topic>' > ~/.config/svc-alert/topic 再 systemctl --user restart ntfy-desktop"
  fi
fi

systemctl --user daemon-reload
systemctl --user enable --now ntfy-desktop.service
echo "[deploy] ntfy-desktop 訂閱啟動（topic: $(cat "$HOME/.config/svc-alert/topic")）"
