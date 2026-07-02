#!/usr/bin/env bash
# Arch 套件安裝層 — 只負責「這個 stage 在 Arch 上裝哪些套件」。
# 環境組裝（stow / zsh 框架 / Claude Code）在 install.sh 共通層，不在這裡。
# 用法：install-arch.sh [base|terminal|desktop]（後層自動涵蓋前層；預設 desktop = 全裝）
set -Eeuo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STAGE="${1:-desktop}"

install_list() {
    local f="$DOTFILES_DIR/packages/$1"
    [[ -f "$f" ]] || { echo "skip: $1 (not found)"; return 0; }
    # 剝掉行內/整行註解（# 之後）+ trim 空白 + 濾空行，其餘當套件名
    local -a pkgs
    mapfile -t pkgs < <(sed -E 's/#.*//; s/^[[:space:]]+//; s/[[:space:]]+$//' "$f" | grep -vE '^$')
    if [[ ${#pkgs[@]} -gt 0 ]]; then
        # --noconfirm：非 TTY（SSH 指令、無人值守）下 [Y/n] 沒人回答會 exit 1
        sudo pacman -S --needed --noconfirm "${pkgs[@]}"
    fi
}

install_list arch-base.txt
[[ "$STAGE" == "base" ]] && exit 0

install_list arch-terminal.txt
[[ "$STAGE" == "terminal" ]] && exit 0

install_list arch-desktop.txt
