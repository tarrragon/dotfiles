#!/usr/bin/env bash
# Debian/Ubuntu 套件安裝層 — 只負責「這個 stage 在 apt 系統上裝哪些套件」。
# 環境組裝（stow / zsh 框架 / Claude Code）在 install.sh 共通層，不在這裡。
# 跟 install-arch.sh 平行：同一套 stage 分層，只有套件名與 package manager 不同。
# 用法：install-debian.sh [base|terminal|desktop]（後層自動涵蓋前層；預設 desktop）
#
# 注意：desktop 層（Hyprland rice）目前只在 Arch 實測過；Debian 的 Hyprland 打包
# 較新版才有，這裡的 desktop 清單標為未實測，真要在 Debian 跑桌面前先驗證套件名。
set -Eeuo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STAGE="${1:-desktop}"

# root 時不需要（也可能沒有）sudo——裸容器 / 剛裝好的機器常以 root 起手、且不含 sudo。
# 非 root 才走 sudo。這讓「以 root 直接跑」真的成立，不會卡在 sudo: command not found。
SUDO=sudo; [ "$(id -u)" -eq 0 ] && SUDO=""

# apt 的 index 跟 Arch 不同、不會因為沒 -u 就 partial upgrade，單純 update 即可。
$SUDO apt-get update

install_list() {
    local f="$DOTFILES_DIR/packages/$1"
    [[ -f "$f" ]] || { echo "skip: $1 (not found)"; return 0; }
    # 剝掉行內/整行註解（# 之後）+ trim 空白 + 濾空行，其餘當套件名
    local -a pkgs
    mapfile -t pkgs < <(sed -E 's/#.*//; s/^[[:space:]]+//; s/[[:space:]]+$//' "$f" | grep -vE '^$')
    if [[ ${#pkgs[@]} -gt 0 ]]; then
        # --no-install-recommends：對齊「裝什麼就等於什麼」，不讓 apt 自動拉一堆推薦套件
        $SUDO apt-get install -y --no-install-recommends "${pkgs[@]}"
    fi
}

install_list debian-base.txt
[[ "$STAGE" == "base" ]] && exit 0

install_list debian-terminal.txt
[[ "$STAGE" == "terminal" ]] && exit 0

install_list debian-desktop.txt
