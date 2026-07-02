#!/usr/bin/env bash
# caelestia/deploy.sh — 部署 caelestia 的自管 config（copy，非 stow）。以一般使用者執行、不 sudo。
#
# 為什麼不用 stow：caelestia 用 atomic write 改寫 shell.json、會把 stow symlink 換成實檔；
# 且 stow --adopt 會把 caelestia 改寫過的內容 clobber 回 repo。所以這類「app 自己管理」的
# config 走 copy 部署、repo 當唯一真實來源。
#
# 規則：持久設定改 repo 的 caelestia/.config/caelestia/ 再跑這個 deploy，
# 不要用 caelestia GUI（nexus 設定）改——那會寫進 live 檔、下次部署被覆蓋。
set -Eeuo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/.config/caelestia"
DST="$HOME/.config/caelestia"
mkdir -p "$DST"

for f in shell.json cli.json hypr-user.lua; do
  [ -f "$SRC/$f" ] || continue
  install -m644 "$SRC/$f" "$DST/$f"
  echo "[deploy] caelestia/$f"
done

echo "[deploy] 完成；caelestia 會熱重載 config（要保險就 caelestia shell -k && caelestia shell -d）"
