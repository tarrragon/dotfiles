#!/usr/bin/env bash
# Arch 套件安裝層 — 只負責「這個 stage 在 Arch 上裝哪些套件」。
# 環境組裝（stow / zsh 框架 / Claude Code）在 install.sh 共通層，不在這裡。
# 用法：install-arch.sh [base|terminal|desktop]（後層自動涵蓋前層；預設 desktop = 全裝）
set -Eeuo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STAGE="${1:-desktop}"

# root 時不需要（也可能沒有）sudo——裸容器 / 剛裝好的機器常以 root 起手、且不含 sudo。
# 非 root 才走 sudo。這讓「以 root 直接跑」真的成立，不會卡在 sudo: command not found。
SUDO=sudo; [ "$(id -u)" -eq 0 ] && SUDO=""

# 先同步 db + 全系統升級再裝：Arch 鏡像不保留舊版檔案，裝機當下的 db
# 幾天內就會指向已被輪替掉的檔名（404 failed to retrieve）。
# 只 -Sy 不 -u 會造成 partial upgrade（新 db 裝新套件、舊系統缺新依賴），一律 -Syu。
$SUDO pacman -Syu --noconfirm

install_list() {
    local f="$DOTFILES_DIR/packages/$1"
    [[ -f "$f" ]] || { echo "skip: $1 (not found)"; return 0; }
    # 剝掉行內/整行註解（# 之後）+ trim 空白 + 濾空行，其餘當套件名
    local -a pkgs
    mapfile -t pkgs < <(sed -E 's/#.*//; s/^[[:space:]]+//; s/[[:space:]]+$//' "$f" | grep -vE '^$')
    if [[ ${#pkgs[@]} -gt 0 ]]; then
        # --noconfirm：非 TTY（SSH 指令、無人值守）下 [Y/n] 沒人回答會 exit 1
        $SUDO pacman -S --needed --noconfirm "${pkgs[@]}"
    fi
}

install_list arch-base.txt
[[ "$STAGE" == "base" ]] && exit 0

install_list arch-terminal.txt
[[ "$STAGE" == "terminal" ]] && exit 0

install_list arch-desktop.txt
