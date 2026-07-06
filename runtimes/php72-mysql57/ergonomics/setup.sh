#!/usr/bin/env bash
# Layer 3：把開發 ergonomics（shell / vim / git config）帶進 runtime container，
# 又不污染 Layer 2 的 prod parity。
#
# 兩條硬規則：
#   1. 跑在「已啟動的 container」裡（docker exec 後執行），不寫進 Dockerfile。
#      ergonomics 進 image = image 不再等於 prod，parity 破功。開發舒適是你的事，
#      跟「這個 image 跟線上一不一樣」必須分層，不能混進同一個 build。
#   2. 用 package-manager detection，同一支腳本在 Debian container、Arch 主機、
#      alpine container 都能跑——這是 dotfile 哲學裡唯一綁 distro 的那一層的抽象。
#
# 用法（在主機跑）：
#   docker compose exec php bash /var/www/html/../ergonomics/setup.sh
#   或掛載 dotfiles repo 進去後 stow：docker compose exec php bash -c '...'
set -euo pipefail

if command -v apt-get &>/dev/null; then
    INSTALL="apt-get update && apt-get install -y --no-install-recommends"
elif command -v pacman &>/dev/null; then
    INSTALL="pacman -S --needed --noconfirm"
elif command -v apk &>/dev/null; then
    INSTALL="apk add --no-cache"
else
    echo "no supported package manager (apt/pacman/apk)" >&2
    exit 1
fi

eval "$INSTALL zsh git vim curl"

# 之後的 stow / symlink 部署是共通層、不分 distro——把 dotfiles repo 掛進 container，
# 在容器內跑 `stow zsh git vim` 即可。config 本身完全可攜，綁 distro 的只有上面那段裝套件。
echo "ergonomics base installed. mount dotfiles repo and run: stow zsh git vim"
